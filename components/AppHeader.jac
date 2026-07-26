"""Shared public and authenticated navigation."""

import from "@jac/runtime" { Link, jacLogout, useNavigate }
import from ".ui.button" { Button }


def:pub PublicHeader(
    action_label: str = "Sign in",
    action_href: str = "/login",
    overlay: bool = False,
    inverse: bool = False,
    show_home: bool = False
) -> JsxElement {
    header_class = (
        "absolute inset-x-0 top-0 z-10 bg-transparent"
        if overlay
        else "border-b border-border/70 bg-background"
    );
    brand_tone = "text-white" if inverse else "text-gray-1000";
    brand_class = "inline-flex h-11 items-center rounded-lg text-base font-semibold tracking-[-0.03em] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-700 focus-visible:ring-offset-2 " + brand_tone;
    action_variant = "primary" if inverse or show_home else "tertiary";

    return <header className={header_class}>
        <div className="mx-auto flex h-12 w-full max-w-7xl items-center justify-between px-4 sm:px-6">
            <Link
                to="/"
                className={brand_class}
            >
                BillBacked<span className={"text-white" if inverse else "text-blue-700"}>.</span>
            </Link>
            <nav
                className="flex items-center gap-2"
                aria-label="Public navigation"
            >
                {if show_home {
                    <Button variant="tertiary" asChild={True}>
                        <Link to="/">Home</Link>
                    </Button>
                }}
                <Button variant={action_variant} asChild={True}>
                    <Link to={action_href}>{action_label}</Link>
                </Button>
            </nav>
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
                <Button
                    type="button"
                    variant="tertiary"
                    onClick={sign_out}
                >
                    Sign out
                </Button>
            </div>
        </div>
    </header>;
}
