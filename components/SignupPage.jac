"""BillBacked sign-up screen."""

import from "@jac/runtime" { Link, Navigate, jacIsLoggedIn, jacLogin, jacSignup, useNavigate }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" { Loading03Icon }
import from ".BillAuditPage" { ProductHeader }
import from ".ui.button" { Button }
import from ".ui.field" { Field, FieldLabel }
import from ".ui.input" { Input }

def:pub SignupPage() -> JsxElement {
    has email: str = "",
        password: str = "",
        error: str = "",
        busy: bool = False;

    nav = useNavigate();

    async def submit -> None {
        signup_result: dict | None = None;
        login_ok: bool = False;

        error = "";
        if not email or not password {
            error = "Enter your email and choose a password.";
            return;
        }
        if len(password) < 8 {
            error = "Use at least 8 characters for your password.";
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
        busy = False;
        nav("/dashboard");
    }

    def handle_submit(e: FormEvent) {
        e.preventDefault();
        submit();
    }

    def handle_email(e: ChangeEvent) { email = e.target.value; }

    def handle_password(e: ChangeEvent) { password = e.target.value; }

    if jacIsLoggedIn() {
        return <Navigate to="/dashboard" replace={True} />;
    }

    return <div className="min-h-svh bg-background text-gray-1000">
        <ProductHeader action_label="Home" action_href="/" />
        <main className="mx-auto flex min-h-[calc(100svh-5rem)] w-full max-w-7xl items-center justify-center px-4 py-12 sm:px-6 sm:py-16">
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
                        className="h-11 w-full rounded-full"
                        disabled={busy}
                    >
                        {if busy {
                            <HugeiconsIcon
                                key="signup-spinner"
                                icon={Loading03Icon}
                                strokeWidth={2}
                                className="size-4 animate-spin"
                            />
                        }}
                        {"Creating account…" if busy else "Create account"}
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
