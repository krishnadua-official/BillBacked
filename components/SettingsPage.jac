"""Simple account and privacy settings for the BillBacked prototype."""

import from "@jac/runtime" { jacLogout, useNavigate }
import from ".ui.button" { Button }
import from ".ui.field" { Field, FieldLabel }
sv import from ..services.patient { CoverageType, PatientView, SavePatientProfile, my_patient }


glob SETTINGS_US_STATE_OPTIONS: list[tuple[str, str]] = [
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

glob SETTINGS_COVERAGE_OPTIONS: list[tuple[str, str]] = [
    ("MEDICARE", "Medicare"),
    ("PRIVATE_INSURANCE", "Private insurance"),
    ("UNINSURED", "No insurance"),
];


def:pub SettingsPage() -> JsxElement {
    has profile_state: str = "";
    has profile_coverage: str = "MEDICARE";
    has profile_loaded: bool = False;
    has saving: bool = False;
    has saved_message: str = "";

    nav = useNavigate();

    async can with entry {
        patient: PatientView | None = await my_patient();
        if patient is not None {
            profile_state = (patient as PatientView).state;
            profile_coverage = str((patient as PatientView).coverage_type);
        }
        profile_loaded = True;
    }

    def handle_state_change(e: ChangeEvent) {
        profile_state = e.target.value;
        saved_message = "";
    }

    def handle_coverage_change(e: ChangeEvent) {
        profile_coverage = e.target.value;
        saved_message = "";
    }

    async def save_profile -> None {
        if not profile_state {
            saved_message = "Select your state first.";
            return;
        }
        saving = True;
        try {
            root spawn SavePatientProfile(
                name="",
                state=profile_state,
                coverage_type=profile_coverage as CoverageType,
                county=None,
                locality=None,
            );
            saved_message = "Saved.";
        } except Exception {
            saved_message = "Could not save right now. Try again.";
        }
        saving = False;
    }

    def handle_submit(e: FormEvent) {
        e.preventDefault();
        save_profile();
    }

    def sign_out() {
        jacLogout();
        nav("/login");
    }

    return <div className="grid flex-1 grid-cols-[2.25rem_minmax(0,1fr)] gap-3 px-4 py-10 sm:px-6 sm:py-14">
        <div className="col-start-2 w-full max-w-3xl">
            <div>
                <h2 className="text-3xl font-medium tracking-[-0.05em] text-gray-1000">
                    Account and privacy
                </h2>
                <p className="mt-3 max-w-xl text-sm leading-6 text-gray-900">
                    Manage how BillBacked handles your account and Medicare bill audits.
                </p>
            </div>

            <section
                className="mt-12 grid gap-6 border-t border-border pt-8 sm:grid-cols-[minmax(0,0.75fr)_minmax(0,1.25fr)]"
                aria-labelledby="pricing-settings-title"
            >
                <div>
                    <h3
                        id="pricing-settings-title"
                        className="text-base font-medium text-gray-1000"
                    >
                        Medicare pricing
                    </h3>
                    <p className="mt-2 text-sm leading-6 text-gray-900">
                        Your state and coverage decide which Medicare rates your bills are priced against.
                    </p>
                </div>
                <form
                    className="flex flex-col gap-5 rounded-2xl bg-background-200 p-5"
                    onSubmit={handle_submit}
                >
                    <Field>
                        <FieldLabel htmlFor="settings-state">State</FieldLabel>
                        <select
                            id="settings-state"
                            value={profile_state}
                            onChange={handle_state_change}
                            className="h-11 w-full rounded-[14px] border border-border bg-background px-4 text-sm text-gray-1000 shadow-none"
                        >
                            <option value="">Select your state</option>
                            {for (abbr, label) in SETTINGS_US_STATE_OPTIONS {
                                <option key={abbr} value={abbr}>{label}</option>;
                            }}
                        </select>
                    </Field>
                    <Field>
                        <FieldLabel htmlFor="settings-coverage">Coverage</FieldLabel>
                        <select
                            id="settings-coverage"
                            value={profile_coverage}
                            onChange={handle_coverage_change}
                            className="h-11 w-full rounded-[14px] border border-border bg-background px-4 text-sm text-gray-1000 shadow-none"
                        >
                            {for (value, label) in SETTINGS_COVERAGE_OPTIONS {
                                <option key={value} value={value}>{label}</option>;
                            }}
                        </select>
                    </Field>
                    {if saved_message {
                        <p key="save-message" className="text-xs text-gray-700">
                            {saved_message}
                        </p>
                    }}
                    <Button
                        type="submit"
                        variant="primary"
                        disabled={saving or not profile_loaded}
                        className="w-fit"
                    >
                        {"Saving…" if saving else "Save"}
                    </Button>
                </form>
            </section>

            <section
                className="mt-10 grid gap-6 border-t border-border pt-8 sm:grid-cols-[minmax(0,0.75fr)_minmax(0,1.25fr)]"
                aria-labelledby="privacy-settings-title"
            >
                <div>
                    <h3
                        id="privacy-settings-title"
                        className="text-base font-medium text-gray-1000"
                    >
                        Privacy
                    </h3>
                    <p className="mt-2 text-sm leading-6 text-gray-900">
                        Controls for provider outreach.
                    </p>
                </div>
                <div className="rounded-2xl bg-background-200 p-5">
                    <p className="text-sm font-medium text-gray-1000">
                        Approval is always required
                    </p>
                    <p className="mt-2 text-sm leading-6 text-gray-900">
                        BillBacked will not email or call a provider until you approve the true-cost bill and outreach draft.
                    </p>
                </div>
            </section>

            <section
                className="mt-10 grid gap-6 border-t border-border pt-8 sm:grid-cols-[minmax(0,0.75fr)_minmax(0,1.25fr)]"
                aria-labelledby="account-settings-title"
            >
                <div>
                    <h3
                        id="account-settings-title"
                        className="text-base font-medium text-gray-1000"
                    >
                        Account
                    </h3>
                    <p className="mt-2 text-sm leading-6 text-gray-900">
                        End this browser session.
                    </p>
                </div>
                <div>
                    <p className="text-sm leading-6 text-gray-900">
                        Signing out keeps your invoice history connected to your private account.
                    </p>
                    <Button
                        type="button"
                        variant="secondary"
                        className="mt-5"
                        onClick={sign_out}
                    >
                        Sign out
                    </Button>
                </div>
            </section>
        </div>
    </div>;
}
