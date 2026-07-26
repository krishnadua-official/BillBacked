"""Agent 1 -- the Extractor. Raw bill bytes -> structured line items.

Stage A/B (mechanical, no LLM) is lib/extract_text.py: PyMuPDF/pdfplumber for
text-layer PDFs, Tesseract OCR for scans, producing plain raw_text. This file
is Stage C: an LLM reads that raw_text and returns a typed StructuredDocument.

Why an LLM here and not regex: real Medicare Summary Notices, EOBs, and
provider bills disagree wildly on layout -- "Patient: CHEN, MARGARET" vs "MARGARET CHEN" vs
"Jackson, Daniel", dotted-leader totals ("Balance Due .......... $553.00"),
and column semantics that only make sense once you've read the header row
("Medicare Approved | Medigap Paid | You Owe"). The LLM reads the document
the way a person would instead of pattern-matching one layout at a time.
"""

import from lib.extract_text { extract_from_bytes, raw_text as _concat_raw_text }
import from base64 { b64decode }
import from datetime { datetime, timezone }
import from uuid { uuid4 }


glob _MIME_BY_EXT: dict[str, str] = {
    ".pdf": "application/pdf", ".jpg": "image/jpeg", ".jpeg": "image/jpeg",
    ".png": "image/png", ".tif": "image/tiff", ".tiff": "image/tiff", ".webp": "image/webp",
};


def _guess_mime(filename: str) -> str {
    ext: str = "." + filename.rsplit(".", 1)[-1].lower() if "." in filename else "";
    return _MIME_BY_EXT.get(ext, "application/pdf");
}


"""A short, unique reference for one uploaded document -- e.g. 'BB-20260726-7F3A2C'.
Stable across the email thread an agent later opens with the provider, so the
patient, the provider, and any agent reading the subject line all know which
upload they're discussing without persistence or a database lookup."""
def _generate_case_id() -> str {
    date_part: str = datetime.now(timezone.utc).strftime("%Y%m%d");
    suffix: str = uuid4().hex[:6].upper();
    return f"BB-{date_part}-{suffix}";
}


enum DocumentType: str {
    MSN = "MSN",
    EOB = "EOB",
    PROVIDER_BILL = "PROVIDER_BILL",
    PAYMENT_RECEIPT = "PAYMENT_RECEIPT",
    NOT_APPLICABLE = "NOT_APPLICABLE",
    UNKNOWN = "UNKNOWN",
}
sem DocumentType.MSN = "Medicare Summary Notice -- title banner says 'Medicare Summary Notice' near the top. A passing mention of an MSN later in an EOB does not count.";
sem DocumentType.EOB = "Insurance Explanation of Benefits / Explanation of Payment from a commercial or Medigap payer -- not government Medicare.";
sem DocumentType.PROVIDER_BILL = "An itemized bill, invoice, or statement from the hospital/clinic/provider showing charges owed.";
sem DocumentType.PAYMENT_RECEIPT = "Proof that a payment was made (or a note that none was made yet) -- receipts, payment postings, copay confirmations.";
sem DocumentType.NOT_APPLICABLE = "A placeholder page saying this document type doesn't apply (e.g. patient not enrolled in Medicare, empty file, wrong screenshot uploaded) rather than real bill content.";
sem DocumentType.UNKNOWN = "None of the above fit, or the document is unreadable/garbled.";


obj LineItem {
    has description: str = "";
    has service_date: str = "";
    has code: str = "";
    has billed_amount: float | None = None;
    has allowed_amount: float | None = None;
    has paid_amount: float | None = None;
    has patient_owed: float | None = None;
}
sem LineItem.description = "What the charge was for, with reference numbers/dates/dollar amounts stripped out.";
sem LineItem.service_date = "Date of service for this line, as printed (e.g. 02/18/2025).";
sem LineItem.code = "CPT/HCPCS/revenue code for this line if one is printed, else empty string.";
sem LineItem.billed_amount = "The provider's full charge for this line before any adjustment, if shown.";
sem LineItem.allowed_amount = "The insurer-approved/allowed amount for this line (may be labeled Approved, Allowed, or Plan Allowed).";
sem LineItem.paid_amount = "What the insurer (or patient, on a receipt) actually paid for this line.";
sem LineItem.patient_owed = "What the patient owes/owed for this line (labeled Owe, Responsibility, Copay, or similar).";


obj StructuredDocument {
    has case_id: str = "";
    has document_type: DocumentType = DocumentType.UNKNOWN;
    has care_type: str = "UNKNOWN";
    has patient_name: str = "";
    has provider_name: str = "";
    has claim_number: str = "";
    has service_date_from: str = "";
    has service_date_to: str = "";
    has total_billed: float | None = None;
    has total_patient_owed: float | None = None;
    has total_paid: float | None = None;
    has line_items: list[LineItem] = [];
    has review_flags: list[str] = [];
}
sem StructuredDocument.case_id = "Always leave as empty string -- assigned by the system after extraction, never printed on the document itself.";
sem StructuredDocument.care_type = "One or two words for the kind of care (office visit, emergency room, imaging, surgery, physical therapy, pharmacy, hospital, ...), or UNKNOWN if not evident.";
sem StructuredDocument.patient_name = "The patient's full name, normalized to 'Last, First' (or 'Last, First M') form regardless of how it was printed. Empty string if truly absent.";
sem StructuredDocument.provider_name = "The billing provider/facility name (not the insurer), e.g. 'Stanford Hospital'.";
sem StructuredDocument.claim_number = "The insurance claim number if printed, else empty string.";
sem StructuredDocument.service_date_from = "Earliest date of service covered by this document (MM/DD/YYYY as printed).";
sem StructuredDocument.service_date_to = "Latest date of service covered by this document (MM/DD/YYYY as printed).";
sem StructuredDocument.total_billed = "The document's own stated total charge, if any (e.g. 'Total Charges', 'Total Hospital Charges'). Do not compute it yourself from line items.";
sem StructuredDocument.total_patient_owed = "The document's own stated balance due / patient responsibility total, if any. Do not compute it yourself.";
sem StructuredDocument.total_paid = "The document's own stated amount actually paid (by insurer or patient), if any. Do not compute it yourself.";
sem StructuredDocument.line_items = "Every itemized charge row found. Skip summary/total rows (Total, Balance Due, Patient Responsibility, Payments Received, Contractual Adjustments) -- those belong in the total_* fields, not here.";
sem StructuredDocument.review_flags = "Short machine-readable flags for a human reviewer, e.g. 'patient_name_not_found', 'smudged_account_number', 'amounts_do_not_reconcile'. Empty list if nothing stood out.";


def structure_document(raw_text: str, filename: str) -> StructuredDocument by llm();
sem structure_document = "Read one page of a patient's medical billing paperwork (a Medicare Summary Notice, insurance EOB, provider bill, or payment receipt) and extract it into a StructuredDocument. These are real-world documents with inconsistent layouts: names appear as 'Patient: CHEN, MARGARET', 'MARGARET CHEN' with no label, or 'Jackson, Daniel' in a table cell; totals may use dotted leaders ('Balance Due .......... $553.00') instead of a colon; dollar columns are only meaningful once you've read that table's own header row (order varies by insurer). Extract only what is actually printed -- never invent a value, and use empty string / None / UNKNOWN when something isn't present.";
sem structure_document.raw_text = "The page's raw extracted text, in reading order, from OCR or a PDF text layer.";
sem structure_document.filename = "Original filename, as a hint about document type (e.g. 'eob.pdf') -- content should override a misleading filename.";


"""Full pipeline for one uploaded document: mechanical extraction (Stage
A/B, no LLM) followed by LLM structuring (Stage C). Callers with several
files for one patient should call this once per file and merge the results
client-side -- there is no persistence here yet (see components/InvoiceData.cl.jac,
the seam this will eventually replace)."""
def:protect extract_and_structure(file_bytes: bytes, mime: str, filename: str) -> StructuredDocument {
    raw: dict[str, any] = extract_from_bytes(file_bytes, mime);
    text: str = _concat_raw_text(raw);
    doc: StructuredDocument = structure_document(text, filename);
    doc.case_id = _generate_case_id();
    return doc;
}


"""The actual upload endpoint the client calls: base64-encoded file content
in (not multipart -- the installed Jac server's request parser only accepts
JSON bodies), StructuredDocument out. :protect -- JWT required, same
per-user privacy model as the rest of this app."""
def:protect upload_bill(file_b64: str, mime: str, filename: str) -> StructuredDocument {
    data: bytes = b64decode(file_b64);
    use_mime: str = mime if mime else _guess_mime(filename);
    return extract_and_structure(data, use_mime, filename);
}
