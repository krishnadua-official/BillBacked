"""Persisted storage for Agent 1's extracted bills.

services/extractor.sv.jac's upload_bills() returns list[StructuredDocument]
as plain in-memory objects; nothing wrote them anywhere, so an extracted
bill only existed for the lifetime of the browser session that uploaded it.
This is where they land instead: one Bill node per case_id (one upload --
a patient can drop in an MSN, an EOB, a provider bill, and a receipt for
the same visit all at once, and extract_and_structure_many tags every
document from that batch with the same case_id), attached to the calling
user's own root (the same per-user isolation model services/patient.sv.jac
and services/email_negotiation.sv.jac use), with its deduplicated line
items as child BillLineItem nodes.

Unlike Patient (get-or-create, one profile per user), this always creates
fresh nodes: a new audit is a new bill, not an update to a previous one --
the same one-record-per-event model services/email_negotiation.sv.jac uses
for Case.
"""

import from datetime { datetime, timezone }
import from services.extractor { StructuredDocument, LineItem, DocumentType }
import from services.discrepancy { BillAudit }


def _now() -> str {
    return datetime.now(timezone.utc).isoformat();
}


"""Two line items describe the same underlying charge if they share a
service_date and at least one dollar amount in common (within a cent) --
e.g. an EOB's line with no code and an itemized bill's line with a CPT
code, both for the same visit."""
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


"""Collapse line items that describe the same charge (same service_date,
shared dollar amount) into one -- e.g. an EOB and an itemized bill for the
same visit shouldn't show up as two separate charges."""
def _merge_line_items(items: list[LineItem]) -> list[LineItem] {
    n: int = len(items);
    used: list[bool] = [False for _ in range(n)];
    merged: list[LineItem] = [];
    for i in range(n) {
        if used[i] { continue; }
        current: LineItem = items[i];
        used[i] = True;
        for j in range(i + 1, n) {
            if used[j] { continue; }
            if _same_charge(current, items[j]) {
                current = _merge_two_items(current, items[j]);
                used[j] = True;
            }
        }
        merged.append(current);
    }
    return merged;
}


glob _DOCUMENT_TYPE_PRIORITY: list[DocumentType] = [
    DocumentType.PROVIDER_BILL, DocumentType.EOB, DocumentType.MSN,
    DocumentType.PAYMENT_RECEIPT, DocumentType.NOT_APPLICABLE, DocumentType.UNKNOWN,
];


"""Pick the single most representative document_type for a case made up of
several documents -- an itemized provider bill is more informative to show
in a bills list than the payment receipt uploaded alongside it."""
def _primary_document_type(docs: list[StructuredDocument]) -> DocumentType {
    for candidate in _DOCUMENT_TYPE_PRIORITY {
        for doc in docs {
            if doc.document_type == candidate {
                return candidate;
            }
        }
    }
    return DocumentType.UNKNOWN;
}


def _first_patient_name(docs: list[StructuredDocument]) -> str {
    for doc in docs { if doc.patient_name { return doc.patient_name; } }
    return "";
}

def _first_provider_name(docs: list[StructuredDocument]) -> str {
    for doc in docs { if doc.provider_name { return doc.provider_name; } }
    return "";
}

def _first_claim_number(docs: list[StructuredDocument]) -> str {
    for doc in docs { if doc.claim_number { return doc.claim_number; } }
    return "";
}

def _first_care_type(docs: list[StructuredDocument]) -> str {
    for doc in docs { if doc.care_type and doc.care_type != "UNKNOWN" { return doc.care_type; } }
    return "UNKNOWN";
}

def _first_service_date_from(docs: list[StructuredDocument]) -> str {
    for doc in docs { if doc.service_date_from { return doc.service_date_from; } }
    return "";
}

def _first_service_date_to(docs: list[StructuredDocument]) -> str {
    for doc in docs { if doc.service_date_to { return doc.service_date_to; } }
    return "";
}


node BillLineItem {
    has description: str = "";
    has service_date: str = "";
    has code: str = "";
    has billed_amount: float | None = None;
    has allowed_amount: float | None = None;
    has paid_amount: float | None = None;
    has patient_owed: float | None = None;

    def to_view -> BillLineItemView {
        return BillLineItemView(
            id=jid(self),
            description=self.description,
            service_date=self.service_date,
            code=self.code,
            billed_amount=self.billed_amount,
            allowed_amount=self.allowed_amount,
            paid_amount=self.paid_amount,
            patient_owed=self.patient_owed,
        );
    }
}


node Bill {
    has case_id: str = "";
    has document_type: DocumentType = DocumentType.UNKNOWN;
    has care_type: str = "UNKNOWN";
    has patient_name: str = "";
    has provider_name: str = "";
    has claim_number: str = "";
    has service_date_from: str = "";
    has service_date_to: str = "";
    has total_billed: float | None = None;
    has total_patient_owed: float | None = None;
    has total_paid: float | None = None;
    has review_flags: list[str] = [];
    has created_at: str = "";
    has total_benchmark: float | None = None;
    has total_overcharge: float | None = None;
    has flagged_count: int = 0;

    def to_view -> BillView {
        return BillView(
            id=jid(self),
            case_id=self.case_id,
            document_type=self.document_type,
            care_type=self.care_type,
            patient_name=self.patient_name,
            provider_name=self.provider_name,
            claim_number=self.claim_number,
            service_date_from=self.service_date_from,
            service_date_to=self.service_date_to,
            total_billed=self.total_billed,
            total_patient_owed=self.total_patient_owed,
            total_paid=self.total_paid,
            review_flags=self.review_flags,
            created_at=self.created_at,
            total_benchmark=self.total_benchmark,
            total_overcharge=self.total_overcharge,
            flagged_count=self.flagged_count,
            line_items=[li.to_view() for li in [self -->][?:BillLineItem]],
        );
    }
}


obj BillLineItemView {
    has id: str;
    has description: str;
    has service_date: str;
    has code: str;
    has billed_amount: float | None;
    has allowed_amount: float | None;
    has paid_amount: float | None;
    has patient_owed: float | None;
}


obj BillView {
    has id: str;
    has case_id: str;
    has document_type: DocumentType;
    has care_type: str;
    has patient_name: str;
    has provider_name: str;
    has claim_number: str;
    has service_date_from: str;
    has service_date_to: str;
    has total_billed: float | None;
    has total_patient_owed: float | None;
    has total_paid: float | None;
    has review_flags: list[str];
    has created_at: str;
    has total_benchmark: float | None;
    has total_overcharge: float | None;
    has flagged_count: int;
    has line_items: list[BillLineItemView];
}


"""Every bill the calling user has ever uploaded, most recent first."""
def my_bills() -> list[BillView] {
    bills = [b for b in [root -->][?:Bill]];
    bills = sorted(
        bills,
        key=lambda (b: Bill) -> str { return b.created_at; },
        reverse=True
    );
    return [b.to_view() for b in bills];
}


"""One of the calling user's bills by id, or None if it doesn't exist / isn't theirs."""
def get_bill(bill_id: str) -> BillView | None {
    for b in [root -->][?:Bill] {
        if jid(b) == bill_id {
            return b.to_view();
        }
    }
    return None;
}


"""Persist Agent 1's extracted StructuredDocuments as Bill + BillLineItem
nodes under the calling user's root -- one Bill per case_id (every document
from the same upload shares a case_id), with each document's line items
merged into one deduplicated set so an EOB and an itemized bill describing
the same visit don't become two separate charges."""
walker SaveExtractedBills {
    has documents: list[StructuredDocument] = [];
    has audit: BillAudit | None = None;
    has reports: list[BillView] = [];

    can save with Root entry {
        now = _now();
        case_ids: list[str] = [];
        for doc in self.documents {
            if doc.case_id not in case_ids {
                case_ids.append(doc.case_id);
            }
        }

        for case_id in case_ids {
            case_docs: list[StructuredDocument] = [d for d in self.documents if d.case_id == case_id];

            raw_items: list[LineItem] = [];
            for doc in case_docs {
                raw_items.extend(doc.line_items);
            }
            merged_items = _merge_line_items(raw_items);

            billed_amounts: list[float] = [i.billed_amount for i in merged_items if i.billed_amount is not None];
            owed_amounts: list[float] = [i.patient_owed for i in merged_items if i.patient_owed is not None];
            paid_amounts: list[float] = [i.paid_amount for i in merged_items if i.paid_amount is not None];

            all_flags: list[str] = [];
            for doc in case_docs {
                for flag in doc.review_flags {
                    if flag not in all_flags {
                        all_flags.append(flag);
                    }
                }
            }

            new_bill = Bill(
                case_id=case_id,
                document_type=_primary_document_type(case_docs),
                care_type=_first_care_type(case_docs),
                patient_name=_first_patient_name(case_docs),
                provider_name=_first_provider_name(case_docs),
                claim_number=_first_claim_number(case_docs),
                service_date_from=_first_service_date_from(case_docs),
                service_date_to=_first_service_date_to(case_docs),
                total_billed=(sum(billed_amounts) if len(billed_amounts) > 0 else None),
                total_patient_owed=(sum(owed_amounts) if len(owed_amounts) > 0 else None),
                total_paid=(sum(paid_amounts) if len(paid_amounts) > 0 else None),
                review_flags=all_flags,
                created_at=now,
                total_benchmark=((self.audit as BillAudit).total_benchmark if self.audit is not None else None),
                total_overcharge=((self.audit as BillAudit).total_overcharge if self.audit is not None else None),
                flagged_count=((self.audit as BillAudit).flagged_count if self.audit is not None else 0),
            );
            here ++> new_bill;

            for item in merged_items {
                new_bill ++> BillLineItem(
                    description=item.description,
                    service_date=item.service_date,
                    code=item.code,
                    billed_amount=item.billed_amount,
                    allowed_amount=item.allowed_amount,
                    paid_amount=item.paid_amount,
                    patient_owed=item.patient_owed,
                );
            }

            self.reports.append(new_bill.to_view());
            report new_bill.to_view();
        }
    }
}
