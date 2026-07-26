"""Minimal public footer for the BillBacked landing page."""

import from "@jac/runtime" { Link }


def:pub SiteFooter() -> JsxElement {
    return <footer className="border-t border-border/70 bg-background px-4 py-8 sm:px-6">
        <div className="mx-auto flex w-full max-w-6xl flex-col gap-5 sm:flex-row sm:items-center sm:justify-between">
            <div>
                <Link
                    to="/"
                    className="inline-flex rounded-md text-base font-semibold tracking-[-0.03em] text-gray-1000 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-700"
                >
                    BillBacked<span className="text-blue-700">.</span>
                </Link>
                <p className="mt-1 text-sm text-gray-900">
                    Medicare bill audits, with you in control.
                </p>
            </div>
            <nav
                className="flex flex-wrap items-center gap-x-5 gap-y-3 text-sm font-medium"
                aria-label="Footer"
            >
                <Link
                    to="/login"
                    className="rounded-md text-gray-900 underline-offset-4 hover:text-gray-1000 hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-700"
                >
                    Sign in
                </Link>
                <Link
                    to="/signup"
                    className="rounded-md text-blue-700 underline-offset-4 hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-700"
                >
                    Create account
                </Link>
                <Link
                    to="/privacy"
                    className="rounded-md text-gray-900 underline-offset-4 hover:text-gray-1000 hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-700"
                >
                    Privacy
                </Link>
                <Link
                    to="/terms"
                    className="rounded-md text-gray-900 underline-offset-4 hover:text-gray-1000 hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-700"
                >
                    Terms
                </Link>
            </nav>
        </div>
    </footer>;
}
