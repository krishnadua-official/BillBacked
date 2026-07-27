"""Protected page that shows the Medicare bill agent process."""

import from "@jac/runtime" { useLocation, useNavigate, useParams }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    CheckmarkCircle01Icon, File01Icon, Mail01Icon
}
import from ".ui.button" { Button }
import from "..lib.utils" { cn }
import from ".NegotiationCallControl" { NegotiationCallControl }
sv import from ..services.extractor { StructuredDocument, LineItem, upload_bills }
sv import from ..services.bill { BillView, SaveExtractedBills, get_bill }
sv import from ..services.discrepancy { BillAudit, analyze_bill }
sv import from ..services.patient { PatientView, my_patient }


"""Two rows count as the same real-world charge if they're from the same
service date and share at least one matching dollar amount -- an EOB's
codeless "Office visit, $340 billed" and an itemized bill's "99213, $340
billed" for the same date are the same line, just seen from two documents.
"""
def _same_charge(a: LineItem, b: LineItem) -> bool {
    if not a.service_date or not b.service_date or a.service_date != b.service_date {
        return False;
    }
    a_amounts: list[float] = [x for x in [a.billed_amount, a.allowed_amount, a.paid_amount, a.patient_owed] if x is not None];
    b_amounts: list[float] = [x for x in [b.billed_amount, b.allowed_amount, b.paid_amount, b.patient_owed] if x is not None];
    for av in a_amounts {
        for bv in b_amounts {
            if abs(av - bv) < 0.01 {
                return True;
            }
        }
    }
    return False;
}


def _merge_two_items(a: LineItem, b: LineItem) -> LineItem {
    better_description: str = a.description if len(a.description) >= len(b.description) else b.description;
    return LineItem(
        description=better_description,
        service_date=a.service_date if a.service_date else b.service_date,
        code=a.code if a.code else b.code,
        billed_amount=a.billed_amount if a.billed_amount is not None else b.billed_amount,
        allowed_amount=a.allowed_amount if a.allowed_amount is not None else b.allowed_amount,
        paid_amount=a.paid_amount if a.paid_amount is not None else b.paid_amount,
        patient_owed=a.patient_owed if a.patient_owed is not None else b.patient_owed,
    );
}


"""Collapse line items from multiple documents (an EOB and an itemized
bill for the same visit, say) into one line per real charge, instead of
auditing the same charge twice just because two documents both mention
it. See _same_charge for the matching rule.
"""
def _merge_line_items(items: list[LineItem]) -> list[LineItem] {
    n: int = len(items);
    used: list[bool] = [False for _ in range(n)];
    merged: list[LineItem] = [];
    for i in range(n) {
        if used[i] {
            continue;
        }
        current: LineItem = items[i];
        used[i] = True;
        for j in range(i + 1, n) {
            if used[j] {
                continue;
            }
            if _same_charge(current, items[j]) {
                current = _merge_two_items(current, items[j]);
                used[j] = True;
            }
        }
        merged.append(current);
    }
    return merged;
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
    has merged_items: list[LineItem] = [];
    has audit: BillAudit | None = None;
    has patient_profile: PatientView | None = None;
    has needs_patient_profile: bool = False;
    has priced_state: str = "";
    has priced_locality: str | None = None;
    has error_message: str = "";
    has resolved_bill: BillView | None = None;
    has bill_lookup_done: bool = False;

    location = useLocation();
    nav = useNavigate();
    params = useParams();
    route_state = location["state"];
    invoice_id_value = params["invoice_id"];
    invoice_id = str(invoice_id_value) if invoice_id_value else "";
    has_invoice_id: bool = invoice_id != "";
    is_history: bool = has_invoice_id and resolved_bill is not None;
    file_names: list[str] = (
        list(route_state["file_names"]) if route_state and route_state["file_names"] else []
    );
    uploaded_files: list[any] = (
        list(route_state["files"]) if route_state and route_state["files"] else []
    );

    # Completed invoices sit beyond the final outreach step so every stage is
    # rendered as complete. Active audits stop for approval before outreach.
    visible_step = 6 if is_history else current_step;

    async can with [invoice_id] entry {
        if has_invoice_id {
            resolved_bill = await get_bill(invoice_id);
            bill_lookup_done = True;
        } elif uploaded_files {
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

                raw_items: list[LineItem] = [];
                for doc in docs {
                    raw_items.extend(doc.line_items);
                }
                merged: list[LineItem] = _merge_line_items(raw_items);
                merged_items = merged;

                current_step = 3;
                patient: PatientView | None = await my_patient();
                computed_audit: BillAudit | None = None;
                if patient is not None {
                    patient_profile = patient;
                    computed_audit = await analyze_bill(
                        merged,
                        state=(patient as PatientView).state,
                        locality=(patient as PatientView).locality,
                        county=(patient as PatientView).county,
                    );
                    audit = computed_audit;
                    priced_state = (patient as PatientView).state;
                    priced_locality = (patient as PatientView).locality;
                } else {
                    needs_patient_profile = True;
                }
                await root spawn SaveExtractedBills(documents=docs, audit=computed_audit);
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
    found_patient_name: str = "";
    for doc in extracted_docs {
        if doc.patient_name {
            found_patient_name = doc.patient_name;
            break;
        }
    }
    found_provider_name: str = "";
    for doc in extracted_docs {
        if doc.provider_name {
            found_provider_name = doc.provider_name;
            break;
        }
    }

    status_title = "Bill on file" if is_history else "Reading your bills";
    status_copy = (
        (
            ((resolved_bill as BillView).provider_name or "This provider")
            + " -- reviewed "
            + ((resolved_bill as BillView).created_at[:10] if (resolved_bill as BillView).created_at else "earlier")
            + "."
        )
        if is_history
        else "Extracting charge lines and provider information from every file you uploaded."
    );
    if has_invoice_id and bill_lookup_done and resolved_bill is None {
        status_title = "Bill not found";
        status_copy = "We couldn't find that bill, or it doesn't belong to your account.";
    } elif not is_history and not has_invoice_id and current_step == 2 {
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
                                    {(resolved_bill as BillView).provider_name if (resolved_bill as BillView).provider_name else "Uploaded bill"}
                                </p>
                                <p className="mt-1 text-xs text-gray-700">
                                    {str((resolved_bill as BillView).document_type)}
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
                            key="bill-on-file-detail"
                            className="mt-4 grid grid-cols-3 gap-3"
                        >
                            <div className="rounded-2xl bg-background-200 p-4">
                                <p className="text-xs text-gray-900">Billed total</p>
                                <p className="mt-2 text-xl font-medium tracking-[-0.04em]">
                                    {
                                        f"${(resolved_bill as BillView).total_billed:,.2f}"
                                        if (resolved_bill as BillView).total_billed is not None
                                        else "Not printed"
                                    }
                                </p>
                            </div>
                            <div className="rounded-2xl bg-background-200 p-4">
                                <p className="text-xs text-gray-900">Medicare-approved</p>
                                <p className="mt-2 text-xl font-medium tracking-[-0.04em]">
                                    {
                                        f"${(resolved_bill as BillView).total_benchmark:,.2f}"
                                        if (resolved_bill as BillView).total_benchmark is not None
                                        else "Not calculated"
                                    }
                                </p>
                            </div>
                            <div className="rounded-2xl bg-blue-100 p-4">
                                <p className="text-xs text-gray-900">Potential savings</p>
                                <p className="mt-2 text-xl font-medium tracking-[-0.04em] text-blue-700">
                                    {
                                        f"${(resolved_bill as BillView).total_overcharge:,.2f}"
                                        if (resolved_bill as BillView).total_overcharge is not None
                                        else "--"
                                    }
                                </p>
                            </div>
                        </div>
                    }}
                    {if is_history and len((resolved_bill as BillView).line_items) > 0 {
                        <div key="history-line-items" className="mt-5 flex flex-col gap-2">
                            {for item in (resolved_bill as BillView).line_items {
                                <div
                                    key={item.id}
                                    className="flex items-center justify-between gap-3 rounded-2xl bg-background-200 p-4"
                                >
                                    <div className="min-w-0">
                                        <p className="truncate text-sm font-medium text-gray-1000">
                                            {item.description if item.description else "Unlabeled charge"}
                                        </p>
                                        {if item.code {
                                            <p key="code" className="mt-1 text-xs text-gray-700">
                                                {f"Code {item.code}"}
                                            </p>
                                        }}
                                    </div>
                                    <p className="shrink-0 text-sm font-medium tabular-nums text-gray-1000">
                                        {f"${item.billed_amount:,.2f}" if item.billed_amount is not None else "--"}
                                    </p>
                                </div>
                            }}
                        </div>
                    }}
                    {if not is_history and has_invoice_id and bill_lookup_done and resolved_bill is None {
                        <p
                            key="bill-not-found"
                            className="mt-5 text-sm leading-6 text-gray-900"
                        >
                            This bill may have been removed, or belongs to a different account.
                        </p>
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
                        <div className="mt-5 grid grid-cols-2 gap-3">
                            <div className="rounded-2xl bg-background-200 p-4">
                                <p className="text-xs text-gray-900">Patient</p>
                                <p className="mt-2 text-sm font-medium text-gray-1000">
                                    {found_patient_name if found_patient_name else "Not found"}
                                </p>
                            </div>
                            <div className="rounded-2xl bg-background-200 p-4">
                                <p className="text-xs text-gray-900">Provider</p>
                                <p className="mt-2 text-sm font-medium text-gray-1000">
                                    {found_provider_name if found_provider_name else "Not found"}
                                </p>
                            </div>
                        </div>
                        {if len(merged_items) > 0 {
                            <div key="charges" className="mt-5 flex flex-col gap-2">
                                {[
                                    <div
                                        key={str(idx) + "-" + (item.code or "no-code")}
                                        className="flex items-center justify-between gap-3 rounded-2xl bg-background-200 p-4"
                                    >
                                        <div className="min-w-0">
                                            <p className="truncate text-sm font-medium text-gray-1000">
                                                {item.description if item.description else "Unlabeled charge"}
                                            </p>
                                            {if item.code {
                                                <p key="code" className="mt-1 text-xs text-gray-700">
                                                    {f"Code {item.code}"}
                                                </p>
                                            }}
                                        </div>
                                        <p className="shrink-0 text-sm font-medium tabular-nums text-gray-1000">
                                            {f"${item.billed_amount:,.2f}" if item.billed_amount is not None else "--"}
                                        </p>
                                    </div>
                                    for (idx, item) in enumerate(merged_items)
                                ]}
                            </div>
                        } else {
                            <p key="no-charges" className="mt-5 text-sm text-gray-900">
                                No itemized charges were found in these documents.
                            </p>
                        }}
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
                        <p className="mt-4 text-sm leading-6 text-gray-900">
                            {
                                f"{(audit as BillAudit).flagged_count} of {len((audit as BillAudit).discrepancies)} line items were flagged for review -- charges billed above the Medicare-approved rate, missing codes, or possible duplicates."
                                if (audit as BillAudit).flagged_count > 0
                                else "Every line item matched the Medicare-approved rate. Nothing was flagged."
                            }
                        </p>
                        {if (audit as BillAudit).unresolved_count > 0 {
                            <p key="unresolved-note" className="mt-2 text-xs text-gray-700">
                                {f"{(audit as BillAudit).unresolved_count} item(s) below have no Medicare Physician Fee Schedule price (e.g. facility charges, supplies, room fees) and are excluded from the savings total."}
                            </p>
                        }}
                        <div key="breakdown" className="mt-5 flex flex-col gap-2">
                            {for disc in (audit as BillAudit).discrepancies {
                                <div
                                    key={disc.hcpcs + "-" + disc.description}
                                    className="flex items-center justify-between gap-3 rounded-2xl bg-background-200 p-4"
                                >
                                    <div className="min-w-0">
                                        <p className="truncate text-sm font-medium text-gray-1000">
                                            {disc.description if disc.description else "Unlabeled charge"}
                                        </p>
                                        {if disc.hcpcs {
                                            <p key="hcpcs" className="mt-1 text-xs text-gray-700">
                                                {f"Code {disc.hcpcs}"}
                                            </p>
                                        }}
                                        {if disc.flagged {
                                            <p key="reason" className="mt-1 text-xs text-destructive">
                                                {disc.flag_reason}
                                            </p>
                                        }}
                                    </div>
                                    <div className="shrink-0 text-right">
                                        <p className="text-sm font-medium tabular-nums text-gray-1000">
                                            {f"${disc.billed_amount:,.2f} billed"}
                                        </p>
                                        <p className="mt-1 text-xs tabular-nums text-gray-700">
                                            {
                                                f"${(disc.benchmark_amount as float):,.2f} Medicare-approved"
                                                if disc.benchmark_amount is not None
                                                else "No Medicare rate found"
                                            }
                                        </p>
                                    </div>
                                </div>
                            }}
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
                            <div key="step1-info" className="mt-2 flex flex-col gap-0.5 text-xs text-gray-700">
                                <p>
                                    {len(extracted_docs)} document{"s" if len(extracted_docs) != 1 else ""} processed.
                                </p>
                                {if found_patient_name {
                                    <p key="step1-patient">
                                        {f"Patient: {found_patient_name}"}
                                    </p>
                                }}
                                {if found_provider_name {
                                    <p key="step1-provider">
                                        {f"Provider: {found_provider_name}"}
                                    </p>
                                }}
                            </div>
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
                            <div key="step3-savings" className="mt-2 flex flex-col gap-0.5 text-xs">
                                <p className="text-gray-700">
                                    {
                                        f"Target (Medicare-approved) price: ${(audit as BillAudit).total_benchmark:,.2f} "
                                        + f"(for the {len((audit as BillAudit).discrepancies) - (audit as BillAudit).unresolved_count} of {len((audit as BillAudit).discrepancies)} items with a Medicare rate)"
                                    }
                                </p>
                                <p className="font-medium text-blue-700">
                                    {f"Potential savings: ${(audit as BillAudit).total_overcharge:,.2f}"}
                                </p>
                                {if (audit as BillAudit).unresolved_count > 0 {
                                    <p key="step3-unresolved" className="text-gray-700">
                                        {f"{(audit as BillAudit).unresolved_count} item(s) have no Medicare rate on file and are not counted above -- see the breakdown below."}
                                    </p>
                                }}
                            </div>
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
                    >
                        {if not is_history and priced_state {
                            <p key="step4-state" className="mt-2 text-xs text-gray-700">
                                {
                                    f"Priced using {priced_state}, locality {priced_locality} Medicare rates."
                                    if priced_locality
                                    else f"Priced using {priced_state} Medicare rates."
                                }
                            </p>
                        }}
                    </AuditStep>
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
