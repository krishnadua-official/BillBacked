"""Sign-in screen."""

import from "@jac/runtime" { Link, Navigate, jacIsLoggedIn, jacLogin, useNavigate }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" { Loading03Icon, SparklesIcon }
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

    return <div className="flex min-h-svh items-center justify-center pt-12 pb-12 pl-4 pr-4">
        <div className="flex w-full max-w-sm flex-col gap-6">
            <div className="flex items-center justify-center gap-2">
                <div className="flex size-8 items-center justify-center rounded-lg bg-primary text-primary-foreground">
                    <HugeiconsIcon icon={SparklesIcon} strokeWidth={2} className="size-4" />
                </div>
                <span className="text-lg font-semibold tracking-tight">Notebook</span>
            </div>
            <Card className="w-full">
                <CardHeader>
                    <CardTitle className="text-2xl">Welcome back</CardTitle>
                    <CardDescription>Sign in to reach your notes.</CardDescription>
                </CardHeader>
                <CardContent>
                    <form className="flex flex-col gap-6" onSubmit={handle_submit}>
                        <Field>
                            <FieldLabel htmlFor="email">Email</FieldLabel>
                            <Input
                                id="email"
                                type="email"
                                autoComplete="email"
                                placeholder="you@example.com"
                                value={email}
                                onChange={handle_email}
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
                            />
                        </Field>
                        {if error {
                            <p className="text-sm text-destructive" role="alert">{error}</p>
                        }}
                        <Button type="submit" className="w-full" disabled={busy}>
                            {if busy {
                                <HugeiconsIcon
                                    icon={Loading03Icon}
                                    strokeWidth={2}
                                    className="size-4 animate-spin"
                                />
                            }}
                            {"Signing in..." if busy else "Sign in"}
                        </Button>
                    </form>
                </CardContent>
                <CardFooter>
                    <p className="w-full text-center text-sm text-muted-foreground">
                        {"Don't have an account?"}{" "}
                        <Link
                            to="/signup"
                            className="text-foreground underline-offset-4 hover:underline"
                        >
                            Sign up
                        </Link>
                    </p>
                </CardFooter>
            </Card>
        </div>
    </div>;
}
