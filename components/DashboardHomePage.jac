"""Authenticated overview of BillBacked bill audits."""

import from "@jac/runtime" { useNavigate }
import from ".ui.badge" { Badge }
import from ".ui.card" { Card, CardContent }
import from ".ui.table" {
    Table, TableBody, TableCell, TableHead, TableHeader, TableRow
}
sv import from ..services.bill { BillView, my_bills }


def:pub DashboardMetric(
    label: str,
    value: str,
    detail: str
) -> JsxElement {
    return <Card className="gap-0 border-0 bg-background-200 py-0 ring-0">
        <CardContent className="flex min-h-36 flex-col justify-between gap-6 p-6">
            <p className="text-sm text-gray-900">{label}</p>
            <div>
                <p className="tabular-nums text-3xl font-medium tracking-[-0.04em] text-gray-1000">
                    {value}
                </p>
                <p className="mt-1 text-xs leading-5 text-gray-900">
                    {detail}
                </p>
            </div>
        </CardContent>
    </Card>;
}


def:pub InvoiceDashboardRow(bill: BillView) -> JsxElement {
    nav = useNavigate();
    route: str = "/dashboard/invoices/" + bill.id;
    provider: str = bill.provider_name if bill.provider_name else "Unknown provider";
    billed_label: str = f"${bill.total_billed:.2f}" if bill.total_billed is not None else "--";
    is_resolved: bool = bill.negotiation_status == "completed";
    status_label: str = (
        "Resolved" if is_resolved
        else "Needs review" if len(bill.review_flags) > 0
        else "Extracted"
    );
    date_label: str = bill.created_at[:10] if bill.created_at else "";

    def open_bill {
        nav(route);
    }

    def handle_click {
        open_bill();
    }

    def handle_key(e: KeyboardEvent) {
        if e.key == "Enter" or e.key == " " {
            e.preventDefault();
            open_bill();
        }
    }

    return <TableRow
        tabIndex={0}
        role="link"
        aria-label={"Open " + provider + " bill"}
        onClick={handle_click}
        onKeyDown={handle_key}
        className="cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-blue-700"
    >
        <TableCell className="pl-3 pr-4">
            <span className="font-medium text-gray-1000">{provider}</span>
        </TableCell>
        <TableCell className="hidden max-w-56 truncate px-4 text-gray-900 md:table-cell">
            {str(bill.document_type)}
        </TableCell>
        <TableCell className="hidden px-4 text-gray-900 lg:table-cell">
            {date_label}
        </TableCell>
        <TableCell className="px-4 text-right tabular-nums text-gray-900">
            {billed_label}
        </TableCell>
        <TableCell className="pl-4 pr-3 text-right">
            <Badge
                variant="outline"
                className={
                    "h-6 border-success-border bg-success-background px-2.5 text-success"
                    if is_resolved or len(bill.review_flags) == 0
                    else "h-6 px-2.5 border-destructive/30 bg-destructive/5 text-destructive"
                }
            >
                {status_label}
            </Badge>
        </TableCell>
    </TableRow>;
}


def:pub DashboardHomePage() -> JsxElement {
    has bills: list[BillView] = [];

    async can with entry {
        bills = await my_bills();
    }

    total_billed: float = sum([b.total_billed if b.total_billed is not None else 0.0 for b in bills]);
    flagged_count: int = len([b for b in bills if len(b.review_flags) > 0]);
    latest_upload: str = bills[0].created_at[:10] if len(bills) > 0 and bills[0].created_at else "None yet";

    return <main className="mx-auto flex w-full max-w-7xl flex-1 flex-col gap-10 px-4 py-10 text-gray-1000 sm:px-8 sm:py-12">
        <section aria-label="Bill metrics">
            <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
                <DashboardMetric
                    label="Bills processed"
                    value={str(len(bills))}
                    detail="Total audits run"
                />
                <DashboardMetric
                    label="Total billed"
                    value={f"${total_billed:.2f}"}
                    detail="Across all uploaded bills"
                />
                <DashboardMetric
                    label="Flagged for review"
                    value={str(flagged_count)}
                    detail="Bills with review flags"
                />
                <DashboardMetric
                    label="Latest upload"
                    value={latest_upload}
                    detail="Most recent audit"
                />
            </div>
        </section>

        <section aria-label="Recent bills">
            {if len(bills) == 0 {
                <p key="no-bills" className="rounded-2xl bg-background-200 p-6 text-sm text-gray-900">
                    No bills uploaded yet. Start a new audit to see it here.
                </p>
            } else {
                <Table key="bills-table" aria-label="Recently uploaded bills">
                    <TableHeader>
                        <TableRow>
                            <TableHead className="pl-3 pr-4">Provider</TableHead>
                            <TableHead className="hidden px-4 md:table-cell">
                                Document type
                            </TableHead>
                            <TableHead className="hidden px-4 lg:table-cell">
                                Uploaded
                            </TableHead>
                            <TableHead className="px-4 text-right">
                                Billed
                            </TableHead>
                            <TableHead className="pl-4 pr-3 text-right">
                                Status
                            </TableHead>
                        </TableRow>
                    </TableHeader>
                    <TableBody>
                        {for bill in bills {
                            <InvoiceDashboardRow key={bill.id} bill={bill} />
                        }}
                    </TableBody>
                </Table>
            }}
        </section>
    </main>;
}
