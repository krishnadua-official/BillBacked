"""BillBacked sign-up screen."""

import from "@jac/runtime" { Link, Navigate, jacIsLoggedIn, jacLogin, jacSignup, useNavigate }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" { Loading03Icon }
import from ".BillAuditPage" { ProductHeader }
import from ".ui.button" { Button }
import from ".ui.card" {
    Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle
}
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

    return <div className="min-h-svh bg-background text-foreground">
        <ProductHeader action_label="Back to BillBacked" action_href="/" />
        <main className="mx-auto flex w-full max-w-6xl justify-center px-4 py-12 sm:px-6 sm:py-20">
            <div className="w-full max-w-md">
                <div className="mb-8">
                    <p className="text-sm font-medium text-muted-foreground">
                        Medicare bill advocate
                    </p>
                    <h1 className="mt-3 text-3xl font-semibold tracking-[-0.04em]">
                        Create your account
                    </h1>
                    <p className="mt-3 text-base leading-6 text-muted-foreground">
                        Keep your audits private and return when provider replies arrive.
                    </p>
                </div>
                <Card className="w-full rounded-xl shadow-[0_2px_2px_rgba(0,0,0,0.04)]">
                    <CardHeader>
                        <CardTitle>Get started</CardTitle>
                        <CardDescription>Create an account with email and password.</CardDescription>
                    </CardHeader>
                    <CardContent>
                        <form className="flex flex-col gap-5" onSubmit={handle_submit}>
                            <Field>
                                <FieldLabel htmlFor="email">Email</FieldLabel>
                                <Input
                                    id="email"
                                    type="email"
                                    autoComplete="email"
                                    placeholder="you@example.com"
                                    value={email}
                                    onChange={handle_email}
                                    className="h-10 rounded-md"
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
                                    className="h-10 rounded-md"
                                />
                            </Field>
                            {if error {
                                <p
                                    key="signup-error"
                                    className="rounded-md border border-destructive/20 bg-destructive/5 p-3 text-sm text-destructive"
                                    role="alert"
                                >
                                    {error}
                                </p>
                            }}
                            <Button
                                type="submit"
                                className="h-10 w-full rounded-md"
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
                    </CardContent>
                    <CardFooter>
                        <p className="w-full text-center text-sm text-muted-foreground">
                            Already have an account?{" "}
                            <Link
                                to="/login"
                                className="rounded-sm font-medium text-foreground underline-offset-4 hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                            >
                                Sign in
                            </Link>
                        </p>
                    </CardFooter>
                </Card>
                <p className="mt-6 text-center text-xs leading-5 text-muted-foreground">
                    Your bill remains yours. Outreach always requires approval.
                </p>
            </div>
        </main>
    </div>;
}
