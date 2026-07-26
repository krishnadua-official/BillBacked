"""Mechanical PDF/image text extraction -- Stage A/B of the extractor pipeline.

No LLM here. This module turns raw upload bytes into a raw-data JSON blob;
`structure_document by llm(...)` (Stage C, in services/extractor.sv.jac) turns
that JSON into typed line items. Keeping this stage LLM-free means OCR never
has to be re-run just because a prompt changed.

Two paths:
  - Text PDFs: PyMuPDF reads each page's text layer; pdfplumber adds a table
    pass so MSN/EOB grids keep their column alignment instead of collapsing
    into an unreadable text dump.
  - Scans and photos: PyMuPDF renders the page to an image (or the image
    upload is used as-is), then Tesseract OCRs it.

Trimmed from the original plan for v1: one OCR engine (Tesseract) instead of
a Tesseract/EasyOCR dual-pass -- add EasyOCR back as a fallback only if
confidence on real scans turns out too low.
"""

import io
import json
from dataclasses import asdict, dataclass

import fitz  # pymupdf
import pdfplumber
import pytesseract
from PIL import Image, ImageOps

TEXT_CHARS_PER_PAGE_THRESHOLD = 20  # below this, treat the page as scanned
MAX_UPLOAD_BYTES = 20 * 1024 * 1024  # 20 MB cap, per plan

PDF_MIME = "application/pdf"
IMAGE_MIMES = {"image/jpeg", "image/png", "image/tiff", "image/webp"}


@dataclass
class PageResult:
    page: int
    text: str
    method: str  # "text_layer" | "ocr"
    ocr_confidence: float | None = None
    has_tables: bool = False


def validate_upload(data: bytes, mime: str) -> None:
    """Raise ValueError with a caller-facing message for unsupported uploads."""
    if mime not in {PDF_MIME, *IMAGE_MIMES}:
        raise ValueError(f"Unsupported file type: {mime}")
    if len(data) > MAX_UPLOAD_BYTES:
        raise ValueError(f"File exceeds {MAX_UPLOAD_BYTES // (1024 * 1024)} MB limit")


def extract_from_bytes(data: bytes, mime: str) -> dict:
    """Raw bytes + mime -> raw-data JSON dict.

    {
      "pages": [{"page": 1, "text": "...", "method": "text_layer" | "ocr",
                 "ocr_confidence": 0.92 | None, "has_tables": True}],
      "page_count": N,
      "extraction_method": "text_pdf" | "ocr" | "mixed",
    }
    """
    validate_upload(data, mime)

    if mime == PDF_MIME:
        pages = _extract_pdf(data)
    else:
        pages = [_extract_image_page(data)]

    methods = {p.method for p in pages}
    if methods == {"text_layer"}:
        extraction_method = "text_pdf"
    elif methods == {"ocr"}:
        extraction_method = "ocr"
    else:
        extraction_method = "mixed"

    return {
        "pages": [asdict(p) for p in pages],
        "page_count": len(pages),
        "extraction_method": extraction_method,
    }


def raw_text(result: dict) -> str:
    """Concatenate every page's text, in order, with page markers -- what
    gets passed to structure_document() as `raw_text`."""
    return "\n\n".join(f"[page {p['page']}]\n{p['text']}" for p in result["pages"])


def aggregate_confidence(result: dict) -> float:
    """1.0 for an all-text-layer document; mean OCR confidence otherwise."""
    ocr_scores = [p["ocr_confidence"] for p in result["pages"] if p["ocr_confidence"] is not None]
    if not ocr_scores:
        return 1.0
    return round(sum(ocr_scores) / len(ocr_scores), 3)


def to_json(result: dict) -> str:
    return json.dumps(result, indent=2)


# --- PDF path ----------------------------------------------------------------


def _extract_pdf(data: bytes) -> list[PageResult]:
    doc = fitz.open(stream=data, filetype="pdf")
    if doc.is_encrypted:
        doc.close()
        raise ValueError("Encrypted PDFs are not supported")
    if doc.page_count == 0:
        doc.close()
        raise ValueError("PDF has zero pages")

    pages: list[PageResult] = []
    with pdfplumber.open(io.BytesIO(data)) as plumber_doc:
        for i, page in enumerate(doc, start=1):
            text = page.get_text("text").strip()
            if len(text) >= TEXT_CHARS_PER_PAGE_THRESHOLD:
                table_text = _extract_tables(plumber_doc, i)
                combined = f"{text}\n\n{table_text}" if table_text else text
                pages.append(PageResult(
                    page=i, text=combined, method="text_layer", has_tables=bool(table_text),
                ))
            else:
                pix = page.get_pixmap(dpi=300)
                img = Image.open(io.BytesIO(pix.tobytes("png")))
                ocr_text, confidence = _ocr_image(img)
                pages.append(PageResult(page=i, text=ocr_text, method="ocr", ocr_confidence=confidence))
    doc.close()
    return pages


def _extract_tables(plumber_doc: "pdfplumber.PDF", page_number: int) -> str:
    """Table pass for one page -- keeps column alignment MSN/EOB claim grids
    lose in a plain text dump."""
    tables = plumber_doc.pages[page_number - 1].extract_tables()
    if not tables:
        return ""
    blocks = []
    for table in tables:
        rows = [" | ".join(cell or "" for cell in row) for row in table]
        blocks.append("\n".join(rows))
    return "\n\n".join(blocks)


# --- Image / OCR path ---------------------------------------------------------


def _extract_image_page(data: bytes) -> PageResult:
    img = Image.open(io.BytesIO(data))
    text, confidence = _ocr_image(img)
    return PageResult(page=1, text=text, method="ocr", ocr_confidence=confidence)


def _preprocess(img: Image.Image) -> Image.Image:
    return ImageOps.autocontrast(ImageOps.grayscale(img))


def _ocr_image(img: Image.Image) -> tuple[str, float]:
    processed = _preprocess(img)
    ocr_data = pytesseract.image_to_data(processed, output_type=pytesseract.Output.DICT)
    words, confidences = [], []
    for word, conf in zip(ocr_data["text"], ocr_data["conf"]):
        if word.strip():
            words.append(word)
            conf_val = float(conf)
            if conf_val >= 0:
                confidences.append(conf_val)
    text = " ".join(words)
    avg_confidence = (sum(confidences) / len(confidences) / 100.0) if confidences else 0.0
    return text, round(avg_confidence, 3)


if __name__ == "__main__":
    import sys

    if len(sys.argv) != 2:
        print("usage: python extract_text.py <file.pdf|file.jpg|...>")
        raise SystemExit(1)

    path = sys.argv[1]
    guessed_mime = {
        ".pdf": PDF_MIME, ".jpg": "image/jpeg", ".jpeg": "image/jpeg",
        ".png": "image/png", ".tif": "image/tiff", ".tiff": "image/tiff", ".webp": "image/webp",
    }.get("." + path.rsplit(".", 1)[-1].lower(), PDF_MIME)

    with open(path, "rb") as f:
        result = extract_from_bytes(f.read(), guessed_mime)

    print(to_json(result))
    print(f"\n--- aggregate_confidence: {aggregate_confidence(result)}", file=sys.stderr)
