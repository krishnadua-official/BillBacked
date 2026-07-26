"""Protected page that shows the Medicare bill agent process."""

import from "@jac/runtime" { useLocation, useNavigate }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    CheckmarkCircle01Icon, Clock01Icon, File01Icon, Mail01Icon
}
import from ".ui.button" { Button }
import from ".AppHeader" { DashboardHeader }
import from "..lib.utils" { cn }


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


def:pub AuditProcessPage() -> JsxElement {
    has current_step: int = 1;

    location = useLocation();
    nav = useNavigate();
    route_state = location["state"];
    file_name = "Uploaded Medicare bill";
    if route_state and route_state["file_name"] {
        file_name = str(route_state["file_name"]);
    }

    can with entry {
        setTimeout(lambda -> None { current_step = 2; }, 900);
        setTimeout(lambda -> None { current_step = 3; }, 1900);
        setTimeout(lambda -> None { current_step = 4; }, 3100);
    }

    def upload_another() {
        nav("/dashboard");
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

    return <div className="min-h-svh bg-background text-gray-1000">
        <DashboardHeader />
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
                            onClick={upload_another}
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
