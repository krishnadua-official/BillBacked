"""Shared public and authenticated navigation."""

import from "@jac/runtime" { Link, jacLogout, useNavigate }


def:pub PublicHeader(
    action_label: str = "Sign in",
    action_href: str = "/login"
) -> JsxElement {
    return <header className="border-b border-border/70 bg-background">
        <div className="mx-auto flex h-12 w-full max-w-7xl items-center justify-between px-4 sm:px-6">
            <Link
                to="/"
                className="inline-flex h-11 items-center rounded-lg text-base font-semibold tracking-[-0.03em] text-gray-1000 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-700 focus-visible:ring-offset-2"
            >
                BillBacked<span className="text-blue-700">.</span>
            </Link>
            <div className="flex items-center gap-4">
                <Link
                    to={action_href}
                    className="inline-flex h-11 items-center rounded-full px-3 text-sm font-medium text-blue-700 transition-colors hover:bg-blue-100 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-700 focus-visible:ring-offset-2"
                >
                    {action_label}
                </Link>
            </div>
        </div>
    </header>;
}


def:pub DashboardHeader() -> JsxElement {
    nav = useNavigate();

    def sign_out() {
        jacLogout();
        nav("/");
    }

    return <header className="border-b border-border/70 bg-background">
        <div className="mx-auto flex h-12 w-full max-w-7xl items-center justify-between px-4 sm:px-6">
            <Link
                to="/dashboard"
                className="inline-flex h-11 items-center rounded-lg text-base font-semibold tracking-[-0.03em] text-gray-1000 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-700 focus-visible:ring-offset-2"
            >
                BillBacked<span className="text-blue-700">.</span>
            </Link>
            <div className="flex items-center gap-4">
                <button
                    type="button"
                    className="inline-flex h-11 items-center rounded-full px-3 text-sm font-medium text-blue-700 transition-colors hover:bg-blue-100 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-700 focus-visible:ring-offset-2"
                    onClick={sign_out}
                >
                    Sign out
                </button>
            </div>
        </div>
    </header>;
}
