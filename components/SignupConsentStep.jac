"""Final signup step requiring explicit legal consent."""

import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" { Loading03Icon }
import from "@jac/runtime" { Link }
import from ".ui.button" { Button }
import from ".ui.checkbox" { Checkbox }
import from ".ui.field" { Field, FieldLabel }


glob US_STATE_OPTIONS: list[tuple[str, str]] = [
    ("AL", "Alabama"), ("AK", "Alaska"), ("AZ", "Arizona"), ("AR", "Arkansas"),
    ("CA", "California"), ("CO", "Colorado"), ("CT", "Connecticut"), ("DE", "Delaware"),
    ("DC", "District of Columbia"), ("FL", "Florida"), ("GA", "Georgia"), ("HI", "Hawaii"),
    ("ID", "Idaho"), ("IL", "Illinois"), ("IN", "Indiana"), ("IA", "Iowa"), ("KS", "Kansas"),
    ("KY", "Kentucky"), ("LA", "Louisiana"), ("ME", "Maine"), ("MD", "Maryland"),
    ("MA", "Massachusetts"), ("MI", "Michigan"), ("MN", "Minnesota"), ("MS", "Mississippi"),
    ("MO", "Missouri"), ("MT", "Montana"), ("NE", "Nebraska"), ("NV", "Nevada"),
    ("NH", "New Hampshire"), ("NJ", "New Jersey"), ("NM", "New Mexico"), ("NY", "New York"),
    ("NC", "North Carolina"), ("ND", "North Dakota"), ("OH", "Ohio"), ("OK", "Oklahoma"),
    ("OR", "Oregon"), ("PA", "Pennsylvania"), ("RI", "Rhode Island"), ("SC", "South Carolina"),
    ("SD", "South Dakota"), ("TN", "Tennessee"), ("TX", "Texas"), ("UT", "Utah"),
    ("VT", "Vermont"), ("VA", "Virginia"), ("WA", "Washington"), ("WV", "West Virginia"),
    ("WI", "Wisconsin"), ("WY", "Wyoming"), ("PR", "Puerto Rico"),
];

glob COVERAGE_OPTIONS: list[tuple[str, str]] = [
    ("MEDICARE", "Medicare"),
    ("PRIVATE_INSURANCE", "Private insurance"),
    ("UNINSURED", "No insurance"),
];


def:pub SignupConsentStep(
    email: str,
    busy: bool,
    error: str,
    on_back: Callable[[], None],
    on_create: Callable[[bool, bool, str, str], None]
) -> JsxElement {
    has accepted_terms: bool = False,
        acknowledged_privacy: bool = False,
        state: str = "",
        coverage_type: str = "MEDICARE",
        validation_error: str = "";

    def handle_submit(e: FormEvent) {
        e.preventDefault();
        if not state {
            validation_error = "Select your state so we can price your bill correctly.";
            return;
        }
        validation_error = "";
        on_create(accepted_terms, acknowledged_privacy, state, coverage_type);
    }

    def handle_terms(checked: bool) { accepted_terms = checked; }

    def handle_privacy(checked: bool) { acknowledged_privacy = checked; }

    def handle_state(e: ChangeEvent) { state = e.target.value; }

    def handle_coverage(e: ChangeEvent) { coverage_type = e.target.value; }

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
            <Field>
                <FieldLabel htmlFor="signup-state">State</FieldLabel>
                <select
                    id="signup-state"
                    value={state}
                    onChange={handle_state}
                    required={True}
                    className="h-11 w-full rounded-[14px] border border-border bg-background-200 px-4 text-sm text-gray-1000 shadow-none"
                >
                    <option value="">Select your state</option>
                    {for (abbr, name) in US_STATE_OPTIONS {
                        <option key={abbr} value={abbr}>{name}</option>;
                    }}
                </select>
            </Field>

            <Field>
                <FieldLabel htmlFor="signup-coverage">Coverage</FieldLabel>
                <select
                    id="signup-coverage"
                    value={coverage_type}
                    onChange={handle_coverage}
                    className="h-11 w-full rounded-[14px] border border-border bg-background-200 px-4 text-sm text-gray-1000 shadow-none"
                >
                    {for (value, label) in COVERAGE_OPTIONS {
                        <option key={value} value={value}>{label}</option>;
                    }}
                </select>
            </Field>

            {if validation_error {
                <p
                    key="consent-validation-error"
                    className="rounded-2xl bg-destructive/5 p-4 text-sm text-destructive"
                    role="alert"
                >
                    {validation_error}
                </p>
            }}

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
