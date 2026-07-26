"""Restore the document scroll position after client-side route changes."""

import from "@jac/runtime" { useLocation }


def:pub ScrollToTop() -> JsxElement {
    pathname = useLocation().pathname;

    can with [pathname] entry {
        window.scrollTo(0, 0);
    }

    return <></>;
}
