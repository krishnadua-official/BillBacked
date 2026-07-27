"""Protected page that shows the Medicare bill agent process."""

import from "@jac/runtime" { useLocation, useNavigate, useParams }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    CheckmarkCircle01Icon, File01Icon, Mail01Icon
}
import from ".ui.button" { Button }
import from "..lib.utils" { cn }
import from ".InvoiceData" {
    invoice_completed_date, invoice_exists, invoice_file_name,
    invoice_final_cost, invoice_provider, invoice_savings
}
import from ".NegotiationCallControl" { NegotiationCallControl }
sv import from ..services.extractor { StructuredDocument, LineItem, upload_bills }
sv import from ..services.bill { SaveExtractedBills }
sv import from ..services.discrepancy { BillAudit, LineDiscrepancy, analyze_bill }
sv import from ..services.patient { PatientView, my_patient }


def _billed_vs_benchmark_line(d: LineDiscrepancy) -> str {
    code: str = d.hcpcs if d.hcpcs else "No code";
    if d.benchmark_amount is not None {
        return f"{code} -- billed ${d.billed_amount:,.2f} vs Medicare-approved ${d.benchmark_amount:,.2f}";
    }
    return f"{code} -- billed ${d.billed_amount:,.2f}";
}


def:pub AuditStep(
    step: int,
    current_step: int,
    title: str,
    description: str,
    is_last: bool = False,
    children: any = None
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
            {children}
        </div>
    </li>;
}


def:pub AuditProcessPage() -> JsxElement {
    has current_step: int = 1;
    has extracted_docs: list[StructuredDocument] = [];
    has audit: BillAudit | None = None;
    has patient_profile: PatientView | None = None;
    has needs_patient_profile: bool = False;
    has error_message: str = "";

    location = useLocation();
    nav = useNavigate();
    params = useParams();
    route_state = location["state"];
    invoice_id_value = params["invoice_id"];
    invoice_id = str(invoice_id_value) if invoice_id_value else "";
    is_history: bool = (
        (invoice_exists(invoice_id) as bool) if invoice_id else False
    );
    file_name = "Uploaded Medicare bill";
    provider_name = "Your provider";
    final_cost = "";
    savings = "";
    completed_date = "";
    file_names: list[str] = (
        list(route_state["file_names"]) if route_state and route_state["file_names"] else []
    );
    uploaded_files: list[any] = (
        list(route_state["files"]) if route_state and route_state["files"] else []
    );

    if is_history {
        file_name = invoice_file_name(invoice_id) as str;
        provider_name = invoice_provider(invoice_id) as str;
        final_cost = invoice_final_cost(invoice_id) as str;
        savings = invoice_savings(invoice_id) as str;
        completed_date = invoice_completed_date(invoice_id) as str;
    }

    # Completed invoices sit beyond the final outreach step so every stage is
    # rendered as complete. Active audits stop for approval before outreach.
    visible_step = 6 if is_history else current_step;

    async can with entry {
        if not is_history and uploaded_files {
            current_step = 2;
            try {
                file_inputs: list[dict] = [];
                for uploaded_file in uploaded_files {
                    buf = await uploaded_file.arrayBuffer();
                    byte_arr = new(Uint8Array, buf);  # jac:ignore[E1053]
                    binary: str = "";
                    for b in byte_arr {  # jac:ignore[E1021,E1022]
                        binary = binary + String.fromCharCode(b);  # jac:ignore[E1032,E1053,E1055]
                    }
                    file_b64: str = btoa(binary);  # jac:ignore[E1001]
                    mime: str = str(uploaded_file.type) if uploaded_file.type else "";
                    filename: str = str(uploaded_file.name);
                    file_inputs.append({"file_b64": file_b64, "mime": mime, "filename": filename});
                }
                docs = await upload_bills(file_inputs);
                extracted_docs = docs;
                await root spawn SaveExtractedBills(documents=docs);

                current_step = 3;
                patient: PatientView | None = await my_patient();
                if patient is not None {
                    patient_profile = patient;
                    all_items: list[LineItem] = [];
                    for doc in docs {
                        all_items.extend(doc.line_items);
                    }
                    audit = await analyze_bill(
                        all_items,
                        state=(patient as PatientView).state,
                        locality=(patient as PatientView).locality,
                        county=(patient as PatientView).county,
                    );
                } else {
                    needs_patient_profile = True;
                }
            } except Exception as e {
                error_message = str(e);
            }
            current_step = 4;
        }
    }

    def upload_another() {
        nav("/dashboard/new");
    }

    total_line_items: int = sum([len(doc.line_items) for doc in extracted_docs]);
    call_case_ready: bool = (
        not is_history
        and visible_step >= 4
        and audit is not None
        and len(extracted_docs) > 0
        and (audit as BillAudit).flagged_count > 0
    );

    status_title = "Negotiation complete" if is_history else "Reading your bills";
    status_copy = (
        provider_name + " accepted the final amount. The full audit trail remains available here."
        if is_history
        else "Extracting charge lines and provider information from every file you uploaded."
    );
    if not is_history and current_step == 2 {
        status_title = "Organizing your charges";
        status_copy = "Classifying each item by service, provider, location, and Medicare context -- and filling in anything one file was missing from the others.";
    } elif not is_history and current_step == 3 {
        status_title = "Calculating your true cost";
        status_copy = "Comparing every billed line item against Medicare-approved rates for your state.";
    } elif not is_history and current_step == 4 and error_message {
        status_title = "Something went wrong reading these bills";
        status_copy = error_message;
    } elif not is_history and current_step == 4 and needs_patient_profile {
        status_title = "We need your state to calculate savings";
        status_copy = "Charges were extracted, but we can't price them against Medicare rates without your state on file. Add it in Settings, then upload again.";
    } elif not is_history and current_step == 4 and audit is not None and (audit as BillAudit).flagged_count > 0 {
        overcharge: float = (audit as BillAudit).total_overcharge;
        status_title = f"You could save ${overcharge:,.2f}";
        status_copy = "You will approve the true-cost bill before any provider outreach begins.";
    } elif not is_history and current_step == 4 {
        status_title = "Your audit is ready";
        status_copy = "You will approve the true-cost bill before any provider outreach begins.";
    }

    return <div className="mx-auto grid w-full max-w-7xl flex-1 gap-10 px-4 py-10 text-gray-1000 sm:px-8 sm:py-14 lg:min-h-[calc(100svh-3rem)] lg:grid-cols-[minmax(280px,0.76fr)_minmax(0,1.24fr)] lg:gap-14">
            <div className="flex min-w-0 flex-col gap-10">
                <section
                    className="py-2"
                    aria-labelledby="audit-status-title"
                    aria-live="polite"
                >
                    <h1
                        id="audit-status-title"
                        className="text-3xl font-medium tracking-[-0.05em] sm:text-4xl"
                    >
                        {status_title}
                    </h1>
                    <p className="mt-4 max-w-md text-base leading-7 text-gray-900">
                        {status_copy}
                    </p>
                </section>

                <section className="border-t border-border pt-8">
                    <h2 className="text-sm font-medium text-gray-700">
                        {"Uploaded bill" if is_history else "Uploaded bills"}
                    </h2>
                    {if is_history {
                        <div
                            key="single-file"
                            className="mt-5 flex items-center gap-4 rounded-2xl bg-background-200 p-4"
                        >
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
                                    {completed_date}
                                </p>
                            </div>
                        </div>
                    } else {
                        <div key="multi-files" className="mt-5 flex flex-col gap-2">
                            {[
                                <div
                                    key={str(idx) + "-" + name}
                                    className="flex items-center gap-4 rounded-2xl bg-background-200 p-4"
                                >
                                    <HugeiconsIcon
                                        icon={File01Icon}
                                        strokeWidth={2}
                                        className="size-5 shrink-0 text-blue-700"
                                    />
                                    <p className="min-w-0 truncate text-sm font-medium text-gray-1000">
                                        {name}
                                    </p>
                                </div>
                                for (idx, name) in enumerate(file_names)
                            ]}
                        </div>
                    }}
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
                            variant="primary"
                            className="mt-6"
                            onClick={upload_another}
                        >
                            Start a new audit
                        </Button>
                    }}
                </section>

                {if not is_history and extracted_docs {
                    <section key="extracted-results" className="border-t border-border pt-8">
                        <div className="flex items-center justify-between gap-3">
                            <h2 className="text-sm font-medium text-gray-700">What we found</h2>
                            {if extracted_docs[0].case_id {
                                <span
                                    key="case-id"
                                    className="rounded-full bg-background-200 px-3 py-1 text-xs font-medium text-gray-900"
                                >
                                    Case {extracted_docs[0].case_id}
                                </span>
                            }}
                        </div>
                        {if len(extracted_docs) > 1 {
                            <p key="reconcile-note" className="mt-2 text-xs text-gray-700">
                                Anything one file was missing (like the patient or provider name) was filled in from the others.
                            </p>
                        }}
                        <div className="mt-5 flex flex-col gap-4">
                            {[
                                <div
                                    key={doc.case_id + "-" + str(idx)}
                                    className="rounded-2xl border border-border p-4"
                                >
                                    <p className="truncate text-xs font-medium text-gray-700">
                                        {file_names[idx] if idx < len(file_names) else "Uploaded file"}
                                    </p>
                                    <div className="mt-3 grid grid-cols-2 gap-3">
                                        <div className="rounded-2xl bg-background-200 p-4">
                                            <p className="text-xs text-gray-900">Patient</p>
                                            <p className="mt-2 text-sm font-medium text-gray-1000">
                                                {doc.patient_name if doc.patient_name else "Not found"}
                                            </p>
                                        </div>
                                        <div className="rounded-2xl bg-background-200 p-4">
                                            <p className="text-xs text-gray-900">Provider</p>
                                            <p className="mt-2 text-sm font-medium text-gray-1000">
                                                {doc.provider_name if doc.provider_name else "Not found"}
                                            </p>
                                        </div>
                                        <div className="rounded-2xl bg-background-200 p-4">
                                            <p className="text-xs text-gray-900">Document type</p>
                                            <p className="mt-2 text-sm font-medium text-gray-1000">
                                                {str(doc.document_type)}
                                            </p>
                                        </div>
                                        <div className="rounded-2xl bg-blue-100 p-4">
                                            <p className="text-xs text-gray-900">Line items found</p>
                                            <p className="mt-2 text-sm font-medium text-blue-700">
                                                {len(doc.line_items)}
                                            </p>
                                        </div>
                                    </div>
                                </div>
                                for (idx, doc) in enumerate(extracted_docs)
                            ]}
                        </div>
                    </section>
                }}

                {if not is_history and audit is not None {
                    <section key="true-cost" className="border-t border-border pt-8">
                        <h2 className="text-sm font-medium text-gray-700">Your true cost</h2>
                        <div className="mt-5 grid grid-cols-3 gap-3">
                            <div className="rounded-2xl bg-background-200 p-4">
                                <p className="text-xs text-gray-900">Billed total</p>
                                <p className="mt-2 text-lg font-medium tracking-[-0.04em]">
                                    {f"${(audit as BillAudit).total_billed:,.2f}"}
                                </p>
                            </div>
                            <div className="rounded-2xl bg-background-200 p-4">
                                <p className="text-xs text-gray-900">Medicare-approved</p>
                                <p className="mt-2 text-lg font-medium tracking-[-0.04em]">
                                    {f"${(audit as BillAudit).total_benchmark:,.2f}"}
                                </p>
                            </div>
                            <div className="rounded-2xl bg-blue-100 p-4">
                                <p className="text-xs text-gray-900">Potential savings</p>
                                <p className="mt-2 text-lg font-medium tracking-[-0.04em] text-blue-700">
                                    {f"${(audit as BillAudit).total_overcharge:,.2f}"}
                                </p>
                            </div>
                        </div>
                        <p className="mt-4 text-xs text-gray-700">
                            {(audit as BillAudit).flagged_count} of {len((audit as BillAudit).discrepancies)} line items flagged for review.
                        </p>
                        <div className="mt-5 flex flex-col gap-3">
                            {[
                                <div
                                    key={str(idx) + "-" + (d.hcpcs or "no-code")}
                                    className={cn(
                                        "rounded-2xl border p-4",
                                        "border-blue-200 bg-blue-100/40" if d.flagged else "border-border"
                                    )}
                                >
                                    <div className="flex items-start justify-between gap-3">
                                        <div className="min-w-0">
                                            <p className="truncate text-sm font-medium text-gray-1000">
                                                {d.description if d.description else "Unlabeled charge"}
                                            </p>
                                            <p className="mt-1 text-xs text-gray-700">
                                                {_billed_vs_benchmark_line(d)}
                                            </p>
                                        </div>
                                        {if d.flagged {
                                            <span
                                                key="flag-badge"
                                                className="shrink-0 rounded-full bg-blue-700 px-2 py-1 text-xs font-medium text-white"
                                            >
                                                Flagged
                                            </span>
                                        }}
                                    </div>
                                    {if d.flag_reason {
                                        <p key="flag-reason" className="mt-2 text-xs leading-5 text-gray-900">
                                            {d.flag_reason}
                                        </p>
                                    }}
                                </div>
                                for (idx, d) in enumerate((audit as BillAudit).discrepancies)
                            ]}
                        </div>
                    </section>
                }}
            </div>

            <section
                className="min-w-0 border-t border-border pt-10 lg:-my-14 lg:border-l lg:border-t-0 lg:py-16 lg:pl-14"
                aria-labelledby="audit-progress-title"
            >
                <div>
                    <h2
                        id="audit-progress-title"
                        className="text-2xl font-medium tracking-[-0.04em]"
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
                    >
                        {if not is_history and len(extracted_docs) > 0 {
                            <p key="step1-info" className="mt-2 text-xs text-gray-700">
                                {len(extracted_docs)} document{"s" if len(extracted_docs) != 1 else ""} processed.
                            </p>
                        }}
                    </AuditStep>
                    <AuditStep
                        step={2}
                        current_step={visible_step}
                        title="Organize the charges"
                        description="Categorize items using service, location, provider, age, and Medicare context."
                    >
                        {if not is_history and total_line_items > 0 {
                            <p key="step2-info" className="mt-2 text-xs text-gray-700">
                                {total_line_items} line item{"s" if total_line_items != 1 else ""} organized.
                            </p>
                        }}
                    </AuditStep>
                    <AuditStep
                        step={3}
                        current_step={visible_step}
                        title="Calculate the true cost"
                        description="Compare each item with historic charges for the same Medicare service."
                    >
                        {if not is_history and current_step == 3 {
                            <p key="step3-progress" className="mt-2 text-xs text-gray-700">
                                Comparing against Medicare-approved rates for your state…
                            </p>
                        }}
                        {if not is_history and audit is not None {
                            <p key="step3-savings" className="mt-2 text-xs font-medium text-blue-700">
                                {f"Potential savings: ${(audit as BillAudit).total_overcharge:,.2f}"}
                            </p>
                        }}
                        {if not is_history and needs_patient_profile {
                            <p key="step3-needs-profile" className="mt-2 text-xs text-gray-700">
                                Add your state in Settings to calculate savings.
                            </p>
                        }}
                    </AuditStep>
                    <AuditStep
                        step={4}
                        current_step={visible_step}
                        title="Review and approve"
                        description="Review the true-cost bill and approve the provider outreach."
                    />
                    <AuditStep
                        step={5}
                        current_step={visible_step}
                        title="Negotiate by email or phone"
                        description="The agent contacts the provider, follows up, and brings you the final offer."
                        is_last={True}
                    >
                        <NegotiationCallControl
                            is_available={call_case_ready}
                            user_name={
                                (patient_profile as PatientView).name
                                if patient_profile is not None
                                else ""
                            }
                            documents={extracted_docs}
                            audit={audit}
                        />
                    </AuditStep>
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
                                No email or phone call has started. Review the true-cost bill and approve outreach first.
                            </p>
                        </div>
                    </div>
                }}
            </section>
    </div>;
}
