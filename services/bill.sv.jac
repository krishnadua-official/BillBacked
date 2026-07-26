"""Persisted storage for Agent 1's extracted bills.

services/extractor.sv.jac's upload_bills() returns list[StructuredDocument]
as plain in-memory objects; nothing wrote them anywhere, so an extracted
bill only existed for the lifetime of the browser session that uploaded it.
This is where they land instead: one Bill node per extracted document,
attached to the calling user's own root (the same per-user isolation model
services/patient.sv.jac and services/email_negotiation.sv.jac use), with
its line items as child BillLineItem nodes.

Unlike Patient (get-or-create, one profile per user), this always creates
fresh nodes: a new audit is a new bill, not an update to a previous one --
the same one-record-per-event model services/email_negotiation.sv.jac uses
for Case.
"""

import from datetime { datetime, timezone }
import from services.extractor { StructuredDocument, LineItem, DocumentType }


def _now() -> str {
    return datetime.now(timezone.utc).isoformat();
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
    has line_items: list[BillLineItemView];
}


"""Every bill the calling user has ever uploaded, most recent first."""
def my_bills() -> list[BillView] {
    bills = [b for b in [root -->][?:Bill]];
    bills = sorted(bills, key=lambda (b: Bill) -> str : b.created_at, reverse=True);
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
nodes under the calling user's root -- one Bill per extracted document
(a multi-file upload becomes multiple Bill nodes, same grouping
upload_bills already returns), each owning its own line items."""
walker SaveExtractedBills {
    has documents: list[StructuredDocument] = [];
    has reports: list[BillView] = [];

    can save with Root entry {
        now = _now();
        for doc in self.documents {
            new_bill = Bill(
                case_id=doc.case_id,
                document_type=doc.document_type,
                care_type=doc.care_type,
                patient_name=doc.patient_name,
                provider_name=doc.provider_name,
                claim_number=doc.claim_number,
                service_date_from=doc.service_date_from,
                service_date_to=doc.service_date_to,
                total_billed=doc.total_billed,
                total_patient_owed=doc.total_patient_owed,
                total_paid=doc.total_paid,
                review_flags=doc.review_flags,
                created_at=now,
            );
            here ++> new_bill;

            for item in doc.line_items {
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
