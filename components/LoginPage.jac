"""Sign-in screen."""

import from "@jac/runtime" { Link, Navigate, jacIsLoggedIn, jacLogin, useNavigate }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" { Loading03Icon }
import from ".AppHeader" { PublicHeader }
import from ".ui.button" { Button }
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

    return <div className="min-h-svh bg-background text-gray-1000">
        <PublicHeader action_label="Home" action_href="/" />
        <main className="mx-auto flex min-h-[calc(100svh-3rem)] w-full max-w-7xl items-center justify-center px-4 py-12 sm:px-6 sm:py-16">
            <section
                className="w-full max-w-md"
                aria-labelledby="login-title"
            >
                <div>
                    <p className="text-sm text-gray-700">Welcome back</p>
                    <h1
                        id="login-title"
                        className="mt-3 text-3xl font-medium tracking-[-0.05em] sm:text-4xl"
                    >
                        Continue your bill audit.
                    </h1>
                    <p className="mt-4 text-base leading-7 text-gray-900">
                        Sign in to review your true-cost bill and any provider outreach.
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
                            autoComplete="current-password"
                            value={password}
                            onChange={handle_password}
                            className="h-11 rounded-[14px] bg-background-200 px-4 shadow-none"
                        />
                    </Field>
                    {if error {
                        <p
                            key="login-error"
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
                                key="login-spinner"
                                icon={Loading03Icon}
                                strokeWidth={2}
                                className="size-4 animate-spin"
                            />
                        }}
                        {"Signing in…" if busy else "Sign in"}
                    </Button>
                </form>

                <div className="mt-7 text-center">
                    <p className="text-sm text-gray-900">
                        {"New to BillBacked?"}{" "}
                        <Link
                            to="/signup"
                            className="rounded-md font-medium text-blue-700 underline-offset-4 hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-700"
                        >
                            Create an account
                        </Link>
                    </p>
                    <p className="mt-4 text-xs leading-5 text-gray-700">
                        No provider message is sent without your approval.
                    </p>
                </div>
            </section>
        </main>
    </div>;
}
