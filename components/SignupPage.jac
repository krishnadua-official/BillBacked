"""Sign-up screen.

Registration is a fixed three-step chain and every step must be awaited:

    1. jacSignup   -- creates the account. There is NO session yet.
    2. jacLogin    -- establishes the session.
    3. SaveProfile -- the first authenticated call, so it MUST come last.

Spawning SaveProfile before jacLogin resolves sends the request without a
token and fails with 401. It is a walker rather than a function because it
WRITES -- it upserts a Profile on the caller's own root -- and the spawn is
what invalidates the cached `my_profile` read the dashboard makes next. Note
also that every var holding an `await` result is pre-declared at the top of
`submit` -- that keeps the generated JS from scoping it tighter than the
if-checks that read it.
"""

import from "@jac/runtime" { Link, Navigate, jacIsLoggedIn, jacLogin, jacSignup, useNavigate }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" { Loading03Icon, SparklesIcon }
import from ".ui.button" { Button }
import from ".ui.card" {
    Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle
}
import from ".ui.field" { Field, FieldLabel }
import from ".ui.input" { Input }

sv import from ..services.notes { Profile, SaveProfile }


def:pub SignupPage() -> JsxElement {
    has name: str = "",
        email: str = "",
        password: str = "",
        error: str = "",
        busy: bool = False;

    nav = useNavigate();

    async def submit -> None {
        signup_result: dict | None = None;
        login_ok: bool = False;
        saved = None;

        error = "";
        if not name or not email or not password {
            error = "Fill in every field to continue.";
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
            saved = await root spawn SaveProfile(name=name, email=email);
        } except Exception {
            error = "Something went wrong. Please try again.";
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

    def handle_name(e: ChangeEvent) { name = e.target.value; }

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
                    <CardTitle className="text-2xl">Create an account</CardTitle>
                    <CardDescription>Takes about ten seconds.</CardDescription>
                </CardHeader>
                <CardContent>
                    <form className="flex flex-col gap-6" onSubmit={handle_submit}>
                        <Field>
                            <FieldLabel htmlFor="name">Name</FieldLabel>
                            <Input
                                id="name"
                                autoComplete="name"
                                placeholder="Ada Lovelace"
                                value={name}
                                onChange={handle_name}
                            />
                        </Field>
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
                                autoComplete="new-password"
                                placeholder="At least 8 characters"
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
                            {"Creating account..." if busy else "Create account"}
                        </Button>
                    </form>
                </CardContent>
                <CardFooter>
                    <p className="w-full text-center text-sm text-muted-foreground">
                        Already have an account?{" "}
                        <Link
                            to="/login"
                            className="text-foreground underline-offset-4 hover:underline"
                        >
                            Sign in
                        </Link>
                    </p>
                </CardFooter>
            </Card>
        </div>
    </div>;
}
