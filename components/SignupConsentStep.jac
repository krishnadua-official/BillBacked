"""Final signup step requiring explicit legal consent."""

import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" { Loading03Icon }
import from "@jac/runtime" { Link }
import from ".ui.button" { Button }
import from ".ui.checkbox" { Checkbox }


def:pub SignupConsentStep(
    email: str,
    busy: bool,
    error: str,
    on_back: Callable[[], None],
    on_create: Callable[[bool, bool], None]
) -> JsxElement {
    has accepted_terms: bool = False,
        acknowledged_privacy: bool = False;

    def handle_submit(e: FormEvent) {
        e.preventDefault();
        on_create(accepted_terms, acknowledged_privacy);
    }

    def handle_terms(checked: bool) { accepted_terms = checked; }

    def handle_privacy(checked: bool) { acknowledged_privacy = checked; }

    return <section
        className="w-full max-w-md"
        aria-labelledby="consent-title"
    >
        <div>
            <p className="text-sm text-gray-700">Step 2 of 2</p>
            <h1
                id="consent-title"
                className="mt-3 text-3xl font-medium tracking-[-0.05em] sm:text-4xl"
            >
                Review and agree.
            </h1>
            <p className="mt-4 text-base leading-7 text-gray-900">
                Confirm how BillBacked can use your information before creating your private workspace.
            </p>
        </div>

        <div className="mt-8 rounded-[16px] bg-background-200 p-5">
            <p className="text-xs font-medium uppercase tracking-[0.08em] text-gray-700">
                Your account
            </p>
            <p className="mt-2 break-all text-sm font-medium text-gray-1000">
                {email}
            </p>
            <p className="mt-3 text-sm leading-6 text-gray-900">
                BillBacked uses your bill data to audit charges, compare Medicare pricing, and prepare provider outreach for your approval.
            </p>
        </div>

        <form className="mt-6 flex flex-col gap-5" onSubmit={handle_submit}>
            <div className="flex items-center gap-3">
                <Checkbox
                    id="accept-terms"
                    checked={accepted_terms}
                    onCheckedChange={handle_terms}
                    required={True}
                    aria-label="Accept the Terms of Service"
                />
                <label
                    htmlFor="accept-terms"
                    className="text-sm leading-6 text-gray-900"
                >
                    I agree to the{" "}
                    <Link
                        to="/terms"
                        target="_blank"
                        rel="noreferrer"
                        className="rounded-md font-medium text-blue-700 underline-offset-4 hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-700"
                    >
                        Terms of Service
                    </Link>.
                </label>
            </div>

            <div className="flex items-center gap-3">
                <Checkbox
                    id="acknowledge-privacy"
                    checked={acknowledged_privacy}
                    onCheckedChange={handle_privacy}
                    required={True}
                    aria-label="Acknowledge the Privacy Policy"
                />
                <label
                    htmlFor="acknowledge-privacy"
                    className="text-sm leading-6 text-gray-900"
                >
                    I acknowledge the{" "}
                    <Link
                        to="/privacy"
                        target="_blank"
                        rel="noreferrer"
                        className="rounded-md font-medium text-blue-700 underline-offset-4 hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-700"
                    >
                        Privacy Policy
                    </Link>.
                </label>
            </div>

            {if error {
                <p
                    key="consent-error"
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
                disabled={busy or not accepted_terms or not acknowledged_privacy}
            >
                {if busy {
                    <HugeiconsIcon
                        key="consent-spinner"
                        icon={Loading03Icon}
                        strokeWidth={2}
                        className="size-4 animate-spin"
                    />
                }}
                {"Creating account…" if busy else "Create account"}
            </Button>
            <Button
                type="button"
                variant="tertiary"
                className="w-full"
                disabled={busy}
                onClick={on_back}
            >
                Back
            </Button>
        </form>
    </section>;
}
