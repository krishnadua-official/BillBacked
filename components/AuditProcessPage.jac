"""Protected page that shows the Medicare bill agent process."""

import from "@jac/runtime" { useLocation, useNavigate, useParams }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    CheckmarkCircle01Icon, Clock01Icon, File01Icon, Mail01Icon
}
import from ".ui.button" { Button }
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
    params = useParams();
    route_state = location["state"];
    invoice_id_value = params["invoice_id"];
    invoice_id = str(invoice_id_value) if invoice_id_value else "";
    is_history = True if invoice_id else False;
    file_name = "Uploaded Medicare bill";
    provider_name = "Your provider";
    final_cost = "";
    savings = "";
    completed_date = "";
    if route_state and route_state["file_name"] {
        file_name = str(route_state["file_name"]);
    }

    if invoice_id == "st-joseph" {
        file_name = "St. Joseph medical bill.pdf";
        provider_name = "St. Joseph Medical Center";
        final_cost = "$2,160";
        savings = "$1,240";
        completed_date = "Negotiated June 18, 2026";
    } elif invoice_id == "mercy-general" {
        file_name = "Mercy General statement.pdf";
        provider_name = "Mercy General Hospital";
        final_cost = "$1,480";
        savings = "$860";
        completed_date = "Negotiated May 29, 2026";
    } elif invoice_id == "northside-imaging" {
        file_name = "Northside imaging invoice.pdf";
        provider_name = "Northside Imaging";
        final_cost = "$625";
        savings = "$475";
        completed_date = "Negotiated April 11, 2026";
    } elif invoice_id == "lakeshore-cardio" {
        file_name = "Lakeshore cardiology bill.pdf";
        provider_name = "Lakeshore Cardiology";
        final_cost = "$1,090";
        savings = "$690";
        completed_date = "Negotiated March 7, 2026";
    }

    visible_step = 5 if is_history else current_step;

    can with entry {
        if not is_history {
            setTimeout(lambda -> None { current_step = 2; }, 900);
            setTimeout(lambda -> None { current_step = 3; }, 1900);
            setTimeout(lambda -> None { current_step = 4; }, 3100);
        }
    }

    def upload_another() {
        nav("/dashboard");
    }

    status_title = "Negotiation complete" if is_history else "Reading your bill";
    status_copy = (
        provider_name + " accepted the final amount. The full audit trail remains available here."
        if is_history
        else "Extracting charge lines and provider information."
    );
    if not is_history and current_step == 2 {
        status_title = "Organizing your charges";
        status_copy = "Classifying each item by service, provider, location, and Medicare context.";
    } elif not is_history and current_step == 3 {
        status_title = "Calculating the true cost";
        status_copy = "Comparing each charge with historical rates for the same Medicare service.";
    } elif not is_history and current_step == 4 {
        status_title = "Your audit is ready";
        status_copy = "You will approve the true-cost bill before any provider outreach begins.";
    }

    return <div className="mx-auto grid w-full max-w-7xl flex-1 gap-10 px-4 py-10 text-gray-1000 sm:px-8 sm:py-14 lg:grid-cols-[minmax(280px,0.76fr)_minmax(0,1.24fr)] lg:gap-14">
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
                        {"Complete" if visible_step >= 4 else "Audit in progress"}
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

                <section className="border-t border-border pt-8">
                    <h2 className="text-sm font-medium text-gray-700">Uploaded bill</h2>
                    <div className="mt-5 flex items-center gap-4 rounded-2xl bg-background-200 p-4">
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
                                {completed_date if is_history else "Medicare bill · PDF or image"}
                            </p>
                        </div>
                    </div>
                    {if is_history {
                        <div
                            key="negotiated-result"
                            className="mt-4 grid grid-cols-2 gap-3"
                        >
                            <div className="rounded-2xl bg-background-200 p-4">
                                <p className="text-xs text-gray-900">Final bill</p>
                                <p className="mt-2 text-xl font-medium tracking-[-0.04em]">
                                    {final_cost}
                                </p>
                            </div>
                            <div className="rounded-2xl bg-blue-100 p-4">
                                <p className="text-xs text-gray-900">You saved</p>
                                <p className="mt-2 text-xl font-medium tracking-[-0.04em] text-blue-700">
                                    {savings}
                                </p>
                            </div>
                        </div>
                    } else {
                        <p
                            key="approval-copy"
                            className="mt-5 text-sm leading-6 text-gray-900"
                        >
                            Nothing is sent to the provider until you approve the final number.
                        </p>
                    }}
                    {if visible_step >= 4 {
                        <Button
                            key="upload-another"
                            className="mt-6 h-10 rounded-xl px-5"
                            onClick={upload_another}
                        >
                            Start a new audit
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
                        current_step={visible_step}
                        title="Read the bill"
                        description="Extract charge lines, codes, dates, and provider details."
                    />
                    <AuditStep
                        step={2}
                        current_step={visible_step}
                        title="Organize the charges"
                        description="Categorize items using service, location, provider, age, and Medicare context."
                    />
                    <AuditStep
                        step={3}
                        current_step={visible_step}
                        title="Calculate the true cost"
                        description="Compare each item with historic charges for the same Medicare service."
                    />
                    <AuditStep
                        step={4}
                        current_step={visible_step}
                        title="Prepare the negotiation"
                        description="Draft the true-cost bill and provider email for your approval."
                        is_last={True}
                    />
                </ol>

                {if visible_step == 4 and not is_history {
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
    </div>;
}
