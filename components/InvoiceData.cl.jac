"""Typed client-side prototype invoice data shared by dashboard views.

This is the single replacement seam for the future persisted Medicare invoice
model. UI components render these records; they do not own fixture data.
"""


obj InvoiceRecord {
    has id: str,
        provider: str,
        file_name: str,
        final_cost: str,
        savings: str,
        completed_date: str;

    def route -> str {
        return "/dashboard/invoices/" + self.id;
    }

    def savings_label -> str {
        return "Negotiated · " + self.savings + " saved";
    }
}


glob INVOICE_HISTORY: list[InvoiceRecord] = [
    InvoiceRecord(
        id="st-joseph",
        provider="St. Joseph Medical Center",
        file_name="St. Joseph medical bill.pdf",
        final_cost="$2,160",
        savings="$1,240",
        completed_date="Negotiated June 18, 2026"
    ),
    InvoiceRecord(
        id="mercy-general",
        provider="Mercy General Hospital",
        file_name="Mercy General statement.pdf",
        final_cost="$1,480",
        savings="$860",
        completed_date="Negotiated May 29, 2026"
    ),
    InvoiceRecord(
        id="northside-imaging",
        provider="Northside Imaging",
        file_name="Northside imaging invoice.pdf",
        final_cost="$625",
        savings="$475",
        completed_date="Negotiated April 11, 2026"
    ),
    InvoiceRecord(
        id="lakeshore-cardio",
        provider="Lakeshore Cardiology",
        file_name="Lakeshore cardiology bill.pdf",
        final_cost="$1,090",
        savings="$690",
        completed_date="Negotiated March 7, 2026"
    )
];


def _find_invoice(invoice_id: str) -> InvoiceRecord | None {
    for invoice in INVOICE_HISTORY {
        if invoice.id == invoice_id {
            return invoice;
        }
    }
    return None;
}


def:pub invoice_ids -> list[str] {
    return [invoice.id for invoice in INVOICE_HISTORY];
}


def:pub invoice_exists(invoice_id: str) -> bool {
    return _find_invoice(invoice_id) is not None;
}


def:pub invoice_route(invoice_id: str) -> str {
    invoice = _find_invoice(invoice_id);
    return invoice.route() if invoice is not None else "/dashboard";
}


def:pub invoice_provider(invoice_id: str) -> str {
    invoice = _find_invoice(invoice_id);
    return invoice.provider if invoice is not None else "";
}


def:pub invoice_savings_label(invoice_id: str) -> str {
    invoice = _find_invoice(invoice_id);
    return invoice.savings_label() if invoice is not None else "";
}


def:pub invoice_file_name(invoice_id: str) -> str {
    invoice = _find_invoice(invoice_id);
    return invoice.file_name if invoice is not None else "";
}


def:pub invoice_final_cost(invoice_id: str) -> str {
    invoice = _find_invoice(invoice_id);
    return invoice.final_cost if invoice is not None else "";
}


def:pub invoice_savings(invoice_id: str) -> str {
    invoice = _find_invoice(invoice_id);
    return invoice.savings if invoice is not None else "";
}


def:pub invoice_completed_date(invoice_id: str) -> str {
    invoice = _find_invoice(invoice_id);
    return invoice.completed_date if invoice is not None else "";
}
