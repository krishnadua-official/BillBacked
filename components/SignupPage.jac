"""BillBacked sign-up screen."""

import from "@jac/runtime" { Link, Navigate, jacIsLoggedIn, jacLogin, jacSignup, useNavigate }
import from ".AppHeader" { PublicHeader }
import from ".SignupConsentStep" { SignupConsentStep }
import from ".ui.button" { Button }
import from ".ui.field" { Field, FieldLabel }
import from ".ui.input" { Input }
sv import from ..services.patient { CoverageType, SavePatientProfile }


def:pub SignupPage() -> JsxElement {
    has email: str = "",
        password: str = "",
        error: str = "",
        busy: bool = False,
        reviewing_consent: bool = False;

    nav = useNavigate();

    def review_consent -> None {
        error = "";
        if not email or not password {
            error = "Enter your email and choose a password.";
            return;
        }
        if len(password) < 8 {
            error = "Use at least 8 characters for your password.";
            return;
        }
        reviewing_consent = True;
    }

    async def create_account(
        accepted_terms: bool,
        acknowledged_privacy: bool,
        state: str,
        coverage_type: str
    ) -> None {
        signup_result: dict | None = None;
        login_ok: bool = False;

        error = "";
        if not accepted_terms or not acknowledged_privacy {
            error = "Accept the Terms of Service and acknowledge the Privacy Policy to continue.";
            return;
        }

        busy = True;
        try {
            signup_result = await jacSignup(email, password);
            if not signup_result["success"] {
                error = "Could not create that account. The email may already be registered.";
                busy = False;
                return;
            }
            login_ok = await jacLogin(email, password);
            if not login_ok {
                error = "Account created, but sign-in failed. Try signing in.";
                busy = False;
                return;
            }
        } except Exception {
            error = "Something went wrong. Try again.";
            busy = False;
            return;
        }

        try {
            root spawn SavePatientProfile(
                name="",
                state=state,
                coverage_type=coverage_type as CoverageType,
                county=None,
                locality=None,
            );
        } except Exception {
            # Best-effort: the account exists and is logged in either way --
            # a profile save failure shouldn't strand the user on this page.
            # They can fill it in again from settings.
        }

        busy = False;
        nav("/dashboard");
    }

    def handle_submit(e: FormEvent) {
        e.preventDefault();
        review_consent();
    }

    def handle_email(e: ChangeEvent) { email = e.target.value; }

    def handle_password(e: ChangeEvent) { password = e.target.value; }

    def handle_back -> None {
        reviewing_consent = False;
        error = "";
    }

    if jacIsLoggedIn() {
        return <Navigate to="/dashboard" replace={True} />;
    }

    if reviewing_consent {
        return <div className="min-h-svh bg-background text-gray-1000">
            <PublicHeader action_label="Home" action_href="/" />
            <main className="mx-auto flex min-h-[calc(100svh-3rem)] w-full max-w-7xl items-center justify-center px-4 py-12 sm:px-6 sm:py-16">
                <SignupConsentStep
                    email={email}
                    busy={busy}
                    error={error}
                    on_back={handle_back}
                    on_create={create_account}
                />
            </main>
        </div>;
    }

    return <div className="min-h-svh bg-background text-gray-1000">
        <PublicHeader action_label="Home" action_href="/" />
        <main className="mx-auto flex min-h-[calc(100svh-3rem)] w-full max-w-7xl items-center justify-center px-4 py-12 sm:px-6 sm:py-16">
            <section
                className="w-full max-w-md"
                aria-labelledby="signup-title"
            >
                <div>
                    <p className="text-sm text-gray-700">Create your account</p>
                    <h1
                        id="signup-title"
                        className="mt-3 text-3xl font-medium tracking-[-0.05em] sm:text-4xl"
                    >
                        Keep your audit private.
                    </h1>
                    <p className="mt-4 text-base leading-7 text-gray-900">
                        Return to your true-cost bill when provider replies arrive.
                    </p>
                </div>

                <form className="mt-9 flex flex-col gap-5" onSubmit={handle_submit}>
                    <Field>
                        <FieldLabel htmlFor="email">Email</FieldLabel>
                        <Input
                            id="email"
                            type="email"
                            autoComplete="email"
                            placeholder="you@example.com"
                            value={email}
                            onChange={handle_email}
                            className="h-11 rounded-[14px] bg-background-200 px-4 shadow-none"
                        />
                    </Field>
                    <Field>
                        <FieldLabel htmlFor="password">Password</FieldLabel>
                        <Input
                            id="password"
                            type="password"
                            autoComplete="new-password"
                            placeholder="At least 8 characters"
                            value={password}
                            onChange={handle_password}
                            className="h-11 rounded-[14px] bg-background-200 px-4 shadow-none"
                        />
                    </Field>
                    {if error {
                        <p
                            key="signup-error"
                            className="rounded-2xl bg-destructive/5 p-4 text-sm text-destructive"
                            role="alert"
                        >
                            {error}
                        </p>
                    }}
                    <Button
                        type="submit"
                        variant="primary"
                        size="lg"
                        className="w-full"
                        disabled={busy}
                    >
                        Continue
                    </Button>
                </form>

                <div className="mt-7 text-center">
                    <p className="text-sm text-gray-900">
                        Already have an account?{" "}
                        <Link
                            to="/login"
                            className="rounded-md font-medium text-blue-700 underline-offset-4 hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-700"
                        >
                            Sign in
                        </Link>
                    </p>
                    <p className="mt-4 text-xs leading-5 text-gray-700">
                        Your bill remains yours. Outreach always requires approval.
                    </p>
                </div>
            </section>
        </main>
    </div>;
}
