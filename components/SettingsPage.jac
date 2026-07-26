"""Simple account and privacy settings for the BillBacked prototype."""

import from "@jac/runtime" { jacLogout, useNavigate }
import from ".ui.button" { Button }


def:pub SettingsPage() -> JsxElement {
    nav = useNavigate();

    def sign_out() {
        jacLogout();
        nav("/login");
    }

    return <div className="flex flex-1 justify-center px-4 py-10 sm:px-8 sm:py-14">
        <div className="w-full max-w-3xl">
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
