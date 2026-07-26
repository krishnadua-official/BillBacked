"""Shared Billbacked mark and wordmark lockup."""


def ensure_head_link(
    rel: str,
    href: str,
    sizes: str = "",
    media_type: str = ""
) -> None {
    selector = "link[rel='" + rel + "'][href='" + href + "']";
    if document.querySelector(selector) {
        return;
    }

    # Jac's current DOM stubs omit link/head mutation methods.
    head_link: any = document.createElement("link");
    head_link.setAttribute("rel", rel);
    head_link.setAttribute("href", href);
    if sizes {
        head_link.setAttribute("sizes", sizes);
    }
    if media_type {
        head_link.setAttribute("type", media_type);
    }
    document_head: any = document.head;
    document_head.appendChild(head_link);
}


def:pub BrandHead() -> JsxElement {
    can with entry {
        document.title = "Billbacked";
        ensure_head_link(
            "icon",
            "/assets/brand/favicon.ico",
            "",
            "image/x-icon"
        );
        ensure_head_link(
            "icon",
            "/assets/brand/favicon-32x32.png",
            "32x32",
            "image/png"
        );
        ensure_head_link(
            "icon",
            "/assets/brand/favicon-16x16.png",
            "16x16",
            "image/png"
        );
        ensure_head_link(
            "apple-touch-icon",
            "/assets/brand/apple-touch-icon.png",
            "180x180",
            "image/png"
        );
        ensure_head_link(
            "manifest",
            "/assets/brand/site-manifest.json"
        );
    }

    return <></>;
}


def:pub BrandMark(size_class: str = "size-5") -> JsxElement {
    return <img
        src="/assets/brand/billbacked-mark-64.png"
        srcSet="/assets/brand/billbacked-mark-64.png 1x, /assets/brand/billbacked-mark-128.png 2x"
        width={64}
        height={64}
        alt=""
        aria-hidden="true"
        decoding="async"
        className={size_class + " shrink-0"}
    />;
}


def:pub BrandLockup(mark_size_class: str = "size-5") -> JsxElement {
    return <span className="inline-flex items-center gap-2">
        <BrandMark size_class={mark_size_class} />
        <span>Billbacked</span>
    </span>;
}
