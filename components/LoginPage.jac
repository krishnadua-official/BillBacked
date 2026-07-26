"""Sign-in screen."""

import from "@jac/runtime" { Link, Navigate, jacIsLoggedIn, jacLogin, useNavigate }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" { Loading03Icon }
import from ".BillAuditPage" { ProductHeader }
import from ".ui.button" { Button }
import from ".ui.card" {
    Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle
}
import from ".ui.field" { Field, FieldLabel }
import from ".ui.input" { Input }


def:pub LoginPage() -> JsxElement {
    has email: str = "",
        password: str = "",
        error: str = "",
        busy: bool = False;

    nav = useNavigate();

    async def submit -> None {
        ok: bool = False;

        error = "";
        if not email or not password {
            error = "Enter your email and password.";
            return;
        }
        busy = True;
        try {
            ok = await jacLogin(email, password);
        } except Exception {
            ok = False;
        }
        busy = False;
        if ok {
            nav("/dashboard");
        } else {
            error = "Those credentials did not match an account.";
        }
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
                        Welcome back
                    </h1>
                    <p className="mt-3 text-base leading-6 text-muted-foreground">
                        Sign in to continue your bill audit and review provider outreach.
                    </p>
                </div>
                <Card className="w-full rounded-xl shadow-[0_2px_2px_rgba(0,0,0,0.04)]">
                    <CardHeader>
                        <CardTitle>Sign in to BillBacked</CardTitle>
                        <CardDescription>Use the email linked to your account.</CardDescription>
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
                                    autoComplete="current-password"
                                    value={password}
                                    onChange={handle_password}
                                    className="h-10 rounded-md"
                                />
                            </Field>
                            {if error {
                                <p
                                    key="login-error"
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
                                        key="login-spinner"
                                        icon={Loading03Icon}
                                        strokeWidth={2}
                                        className="size-4 animate-spin"
                                    />
                                }}
                                {"Signing in…" if busy else "Sign in"}
                            </Button>
                        </form>
                    </CardContent>
                    <CardFooter>
                        <p className="w-full text-center text-sm text-muted-foreground">
                            {"New to BillBacked?"}{" "}
                            <Link
                                to="/signup"
                                className="rounded-sm font-medium text-foreground underline-offset-4 hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                            >
                                Create an account
                            </Link>
                        </p>
                    </CardFooter>
                </Card>
                <p className="mt-6 text-center text-xs leading-5 text-muted-foreground">
                    No provider message is sent without your approval.
                </p>
            </div>
        </main>
    </div>;
}
