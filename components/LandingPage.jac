"""Public BillBacked marketing page.

The landing page explains the value and routes visitors into authentication.
Bill upload and audit controls intentionally live only in the protected
dashboard.
"""

import from "@jac/runtime" { Link }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    ArrowRight01Icon, CheckmarkCircle01Icon
}
import from ".AppHeader" { PublicHeader }


def:pub LandingStep(
    number: str,
    title: str,
    description: str
) -> JsxElement {
    return <li className="flex min-w-0 flex-col gap-5">
        <span className="text-3xl font-medium tracking-[-0.05em] text-blue-700">
            {number}
        </span>
        <div>
            <p className="text-base font-medium text-gray-1000">{title}</p>
            <p className="mt-2 max-w-xs text-sm leading-6 text-gray-900">
                {description}
            </p>
        </div>
    </li>;
}


def:pub DashboardPreviewStep(
    title: str,
    description: str
) -> JsxElement {
    return <li className="grid grid-cols-[40px_1fr] gap-4">
        <span className="flex size-10 items-center justify-center rounded-full bg-blue-700 text-white">
            <HugeiconsIcon
                icon={CheckmarkCircle01Icon}
                strokeWidth={2}
                className="size-5"
            />
        </span>
        <div className="pt-0.5">
            <p className="text-sm font-medium text-gray-1000">{title}</p>
            <p className="mt-1 text-sm leading-6 text-gray-900">{description}</p>
        </div>
    </li>;
}


def:pub LandingPage() -> JsxElement {
    return <div className="min-h-svh bg-background text-gray-1000">
        <PublicHeader />
        <main>
            <section className="mx-auto grid w-full max-w-7xl gap-12 px-4 py-16 sm:px-6 sm:py-20 lg:grid-cols-[minmax(0,1.08fr)_minmax(360px,0.92fr)] lg:items-center lg:gap-16 lg:py-24">
                <div>
                    <p className="text-sm text-gray-700">Built for Medicare bills</p>
                    <h1 className="mt-8 max-w-3xl text-4xl font-medium tracking-[-0.06em] sm:text-5xl sm:leading-[1.02] lg:text-6xl">
                        Understand your bill before you pay it.
                    </h1>
                    <p className="mt-6 max-w-2xl text-lg leading-8 text-gray-900">
                        BillBacked audits every charge, estimates the fair Medicare cost, and prepares provider outreach for your approval.
                    </p>
                    <div className="mt-9 flex flex-wrap items-center gap-4">
                        <Link
                            to="/signup"
                            className="inline-flex h-11 items-center gap-2 rounded-full bg-primary px-5 text-sm font-medium text-primary-foreground transition-colors hover:bg-primary/85 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-700 focus-visible:ring-offset-2"
                        >
                            Create an account
                            <HugeiconsIcon
                                icon={ArrowRight01Icon}
                                strokeWidth={2}
                                className="size-4"
                            />
                        </Link>
                        <Link
                            to="/login"
                            className="rounded-full px-3 py-2 text-sm font-medium text-blue-700 hover:bg-blue-100 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-700 focus-visible:ring-offset-2"
                        >
                            Sign in
                        </Link>
                    </div>
                    <p className="mt-6 text-sm text-gray-700">
                        Your dashboard stays private. No provider message is sent without your approval.
                    </p>
                </div>

                <section
                    className="rounded-[20px] bg-background-200 p-7 sm:p-8"
                    aria-labelledby="dashboard-preview-title"
                >
                    <p className="text-sm text-gray-700">Inside your dashboard</p>
                    <h2
                        id="dashboard-preview-title"
                        className="mt-2 text-2xl font-medium tracking-[-0.04em]"
                    >
                        Follow the audit from upload to approval.
                    </h2>
                    <ol className="mt-8 flex flex-col gap-7">
                        <DashboardPreviewStep
                            title="Upload your bill"
                            description="Add a PDF or clear photo after you sign in."
                        />
                        <DashboardPreviewStep
                            title="See the agent work"
                            description="Follow reading, organization, and price comparison in one place."
                        />
                        <DashboardPreviewStep
                            title="Approve the next step"
                            description="Review the true-cost bill before negotiation begins."
                        />
                    </ol>
                </section>
            </section>

            <section className="mx-auto w-full max-w-7xl border-t border-border px-4 py-14 sm:px-6 sm:py-16">
                <div className="grid gap-10 sm:grid-cols-[0.7fr_1fr_1fr_1fr] sm:gap-8">
                    <div>
                        <p className="text-sm text-gray-700">How it works</p>
                        <h2 className="mt-2 text-2xl font-medium tracking-[-0.04em]">
                            From bill to fair price.
                        </h2>
                    </div>
                    <LandingStep
                        number="01"
                        title="Read"
                        description="Extract every charge, code, provider, and date."
                    />
                    <LandingStep
                        number="02"
                        title="Calculate"
                        description="Compare each item and estimate the true Medicare cost."
                    />
                    <LandingStep
                        number="03"
                        title="Negotiate"
                        description="Prepare provider outreach and wait for your approval."
                    />
                </div>
            </section>
        </main>
    </div>;
}
