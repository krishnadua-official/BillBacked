"""The first BillBacked product surface.

This is intentionally a front-end prototype. A Medicare bill can be selected
locally and the interface demonstrates the audit workflow without pretending
that real analysis or negotiation has happened.
"""

import from ".ui.button" { Button }
import from "..lib.utils" { cn }
import from "@jac/runtime" { Link }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    ArrowRight01Icon, CheckmarkCircle01Icon, Clock01Icon,
    File01Icon, Mail01Icon, Upload01Icon
}


def:pub ProductHeader(
    action_label: str = "Sign in",
    action_href: str = "/login"
) -> JsxElement {
    return <header className="border-b border-border/70 bg-background">
        <div className="mx-auto flex h-20 w-full max-w-7xl items-center justify-between px-4 sm:px-6">
            <Link
                to="/"
                className="rounded-lg text-base font-semibold tracking-[-0.03em] text-gray-1000 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-700 focus-visible:ring-offset-2"
            >
                BillBacked<span className="text-blue-700">.</span>
            </Link>
            <div className="flex items-center gap-4">
                <span className="hidden text-sm text-gray-700 sm:inline">
                    Medicare bill advocate
                </span>
                <Link
                    to={action_href}
                    className="rounded-full px-3 py-2 text-sm font-medium text-blue-700 transition-colors hover:bg-blue-100 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-700 focus-visible:ring-offset-2"
                >
                    {action_label}
                </Link>
            </div>
        </div>
    </header>;
}


def:pub WorkflowItem(
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


def:pub AuditStep(
    step: int,
    current_step: int,
    title: str,
    description: str,
    is_last: bool = False
) -> JsxElement {
    is_complete = step < current_step;
    is_current = step == current_step;

    return <li
        className="relative grid grid-cols-[40px_1fr] gap-4 pb-7 last:pb-0"
        aria-current={"step" if is_current else None}
    >
        {if not is_last {
            <span
                key="connector"
                className={cn(
                    "absolute left-[19px] top-10 h-[calc(100%-40px)] w-px",
                    "bg-blue-700" if is_complete else "bg-border"
                )}
                aria-hidden="true"
            />
        }}
        <span
            className={cn(
                "relative z-10 flex size-10 items-center justify-center rounded-full text-sm font-medium transition-colors duration-150",
                "bg-background-200 text-gray-700",
                "bg-blue-700 text-white" if is_complete or is_current else "",
                "ring-4 ring-blue-100" if is_current else ""
            )}
            aria-hidden="true"
        >
            {if is_complete {
                <HugeiconsIcon
                    key="complete-icon"
                    icon={CheckmarkCircle01Icon}
                    strokeWidth={2}
                    className="size-5"
                />
            } else {
                step;
            }}
        </span>
        <div className="pt-0.5">
            <p className={cn(
                "text-sm font-medium",
                "text-gray-1000" if is_complete or is_current else "text-gray-700"
            )}>
                {title}
            </p>
            <p className={cn(
                "mt-1 text-sm leading-5",
                "text-gray-900" if is_complete or is_current else "text-gray-700"
            )}>
                {description}
            </p>
        </div>
    </li>;
}


def:pub BillAuditPage() -> JsxElement {
    has file_name: str = "",
        current_step: int = 0;

    def begin_audit(file: any) -> None {
        file_name = file.name;
        current_step = 1;
        setTimeout(lambda -> None { current_step = 2; }, 900);
        setTimeout(lambda -> None { current_step = 3; }, 1900);
        setTimeout(lambda -> None { current_step = 4; }, 3100);
    }

    def handle_file(e: ChangeEvent) -> None {
        if e.target.files {
            begin_audit(e.target.files[0]);
        }
    }

    def reset_audit() -> None {
        file_name = "";
        current_step = 0;
    }

    status_title = "Reading your bill";
    status_copy = "Extracting charge lines and provider information.";
    if current_step == 2 {
        status_title = "Organizing your charges";
        status_copy = "Classifying each item by service, provider, location, and Medicare context.";
    } elif current_step == 3 {
        status_title = "Calculating the true cost";
        status_copy = "Comparing each charge with historical rates for the same Medicare service.";
    } elif current_step == 4 {
        status_title = "Your audit is ready";
        status_copy = "You will approve the true-cost bill before any provider outreach begins.";
    }

    if file_name {
        return <div className="min-h-svh bg-background text-gray-1000">
            <ProductHeader />
            <main className="mx-auto grid w-full max-w-7xl gap-10 px-4 py-10 sm:px-6 sm:py-14 lg:grid-cols-[minmax(280px,0.76fr)_minmax(0,1.24fr)] lg:gap-14">
                <div className="flex min-w-0 flex-col gap-10">
                    <section
                        className="py-2"
                        aria-labelledby="audit-status-title"
                        aria-live="polite"
                    >
                        <div className="flex items-center gap-2 text-sm text-gray-700">
                            <HugeiconsIcon
                                icon={Clock01Icon}
                                strokeWidth={2}
                                className="size-4"
                            />
                            {"Complete" if current_step == 4 else "Audit in progress"}
                        </div>
                        <h1
                            id="audit-status-title"
                            className="mt-8 text-3xl font-medium tracking-[-0.05em] sm:text-4xl"
                        >
                            {status_title}
                        </h1>
                        <p className="mt-4 max-w-md text-base leading-7 text-gray-900">
                            {status_copy}
                        </p>
                    </section>

                    <section className="rounded-[20px] bg-background-200 p-6 sm:p-7">
                        <h2 className="text-sm font-medium text-gray-700">Uploaded bill</h2>
                        <div className="mt-6 flex items-center gap-4 rounded-2xl bg-background-200 p-4">
                            <HugeiconsIcon
                                icon={File01Icon}
                                strokeWidth={2}
                                className="size-5 shrink-0 text-blue-700"
                            />
                            <div className="min-w-0">
                                <p className="truncate text-sm font-medium text-gray-1000">
                                    {file_name}
                                </p>
                                <p className="mt-1 text-xs text-gray-700">
                                    Medicare bill · PDF or image
                                </p>
                            </div>
                        </div>
                        <p className="mt-5 text-sm leading-6 text-gray-900">
                            Nothing is sent to the provider until you approve the final number.
                        </p>
                        {if current_step == 4 {
                            <Button
                                key="upload-another"
                                className="mt-6 h-10 rounded-full px-5"
                                onClick={reset_audit}
                            >
                                Upload another bill
                            </Button>
                        }}
                    </section>
                </div>

                <section
                    className="min-w-0 border-t border-border pt-10 lg:border-l lg:border-t-0 lg:pl-14 lg:pt-2"
                    aria-labelledby="audit-progress-title"
                >
                    <div>
                        <p className="text-sm text-gray-700">Live agent activity</p>
                        <h2
                            id="audit-progress-title"
                            className="mt-2 text-2xl font-medium tracking-[-0.04em]"
                        >
                            Audit progress
                        </h2>
                    </div>

                    <ol className="mt-10">
                        <AuditStep
                            step={1}
                            current_step={current_step}
                            title="Read the bill"
                            description="Extract charge lines, codes, dates, and provider details."
                        />
                        <AuditStep
                            step={2}
                            current_step={current_step}
                            title="Organize the charges"
                            description="Categorize items using service, location, provider, age, and Medicare context."
                        />
                        <AuditStep
                            step={3}
                            current_step={current_step}
                            title="Calculate the true cost"
                            description="Compare each item with historic charges for the same Medicare service."
                        />
                        <AuditStep
                            step={4}
                            current_step={current_step}
                            title="Prepare the negotiation"
                            description="Draft the true-cost bill and provider email for your approval."
                            is_last={True}
                        />
                    </ol>

                    {if current_step == 4 {
                        <div
                            key="approval-note"
                            className="mt-10 flex items-start gap-4 rounded-2xl bg-blue-100 p-5"
                        >
                            <HugeiconsIcon
                                icon={Mail01Icon}
                                strokeWidth={2}
                                className="mt-0.5 size-5 shrink-0 text-blue-700"
                            />
                            <div>
                                <p className="text-sm font-medium text-gray-1000">
                                    Ready for your approval
                                </p>
                                <p className="mt-1 text-sm leading-6 text-gray-900">
                                    No provider message has been sent. Review and negotiation come next.
                                </p>
                            </div>
                        </div>
                    }}
                </section>
            </main>
        </div>;
    }

    return <div className="min-h-svh bg-background text-gray-1000">
        <ProductHeader />
        <main className="mx-auto grid w-full max-w-7xl gap-10 px-4 sm:px-6 lg:grid-cols-[minmax(0,1.08fr)_minmax(360px,0.92fr)] lg:gap-16">
            <section className="flex flex-col justify-center py-14 sm:py-20 lg:min-h-[520px] lg:py-24">
                <p className="text-sm text-gray-700">Medicare bill advocate</p>
                <div className="my-10">
                    <h1 className="max-w-2xl text-4xl font-medium tracking-[-0.06em] sm:text-5xl sm:leading-[1.02] lg:text-6xl">
                        Find what your medical bill should cost.
                    </h1>
                    <p className="mt-6 max-w-xl text-lg leading-7 text-gray-900">
                        Upload a Medicare bill. BillBacked reads every charge, compares historical pricing, and prepares the dispute for you.
                    </p>
                </div>
                <p className="text-sm font-medium text-blue-700">
                    You approve every provider message.
                </p>
            </section>

            <section className="my-10 rounded-[20px] bg-canvas p-6 sm:my-14 sm:p-8 lg:my-16">
                <div>
                    <h2 className="text-2xl font-medium tracking-[-0.04em]">
                        Upload your bill
                    </h2>
                    <p className="mt-2 text-sm leading-6 text-gray-900">
                        Use a PDF or clear photo. You will see the agent work step by step.
                    </p>
                </div>
                <label
                    htmlFor="bill-upload"
                    className="group mt-8 flex min-h-64 cursor-pointer flex-col items-center justify-center rounded-2xl bg-background p-6 text-center transition-colors hover:bg-blue-100 focus-within:ring-2 focus-within:ring-blue-700 focus-within:ring-offset-4"
                >
                    <input
                        id="bill-upload"
                        type="file"
                        accept=".pdf,image/*"
                        className="sr-only"
                        onChange={handle_file}
                    />
                    <HugeiconsIcon
                        icon={Upload01Icon}
                        strokeWidth={2}
                        className="size-7 text-blue-700"
                    />
                    <span className="mt-6 text-base font-medium">Choose a Medicare bill</span>
                    <span className="mt-2 text-sm text-gray-700">PDF, PNG, or JPG</span>
                    <span className="mt-6 inline-flex h-11 items-center gap-2 rounded-full bg-primary px-5 text-sm font-medium text-primary-foreground transition-transform group-hover:translate-y-[-1px]">
                        Upload bill
                        <HugeiconsIcon
                            icon={ArrowRight01Icon}
                            strokeWidth={2}
                            className="size-4"
                        />
                    </span>
                </label>
                <p className="mt-5 text-sm leading-6 text-gray-700">
                    Prototype only. Your file stays in this browser session.
                </p>
            </section>

            <section className="border-t border-border py-12 sm:py-16 lg:col-span-2">
                <div className="grid gap-10 sm:grid-cols-[0.55fr_1fr_1fr_1fr] sm:gap-8">
                    <div>
                        <p className="text-sm text-gray-700">How it works</p>
                        <h2 className="mt-2 text-2xl font-medium tracking-[-0.04em]">
                            From bill to fair price.
                        </h2>
                    </div>
                    <WorkflowItem
                        number="01"
                        title="Read"
                        description="Extract every charge, code, provider, and date."
                    />
                    <WorkflowItem
                        number="02"
                        title="Calculate"
                        description="Compare each item and estimate the true Medicare cost."
                    />
                    <WorkflowItem
                        number="03"
                        title="Negotiate"
                        description="Prepare provider outreach and wait for your approval."
                    />
                </div>
            </section>
        </main>
    </div>;
}
