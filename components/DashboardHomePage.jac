"""Authenticated overview of completed BillBacked negotiations."""

import from "@jac/runtime" { useNavigate }
import from ".InvoiceData" {
    dashboard_hours_saved, dashboard_invoice_count, dashboard_money_saved,
    dashboard_patterns_learned, invoice_completed_on, invoice_file_name,
    invoice_final_cost, invoice_ids, invoice_provider, invoice_result,
    invoice_route, invoice_savings
}
import from ".ui.badge" { Badge }
import from ".ui.card" { Card, CardContent }
import from ".ui.table" {
    Table, TableBody, TableCell, TableHead, TableHeader, TableRow
}


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


def:pub InvoiceDashboardRow(invoice_id: str) -> JsxElement {
    nav = useNavigate();
    route: str = invoice_route(invoice_id) as str;
    provider: str = invoice_provider(invoice_id) as str;

    def open_invoice {
        nav(route);
    }

    def handle_click {
        open_invoice();
    }

    def handle_key(e: KeyboardEvent) {
        if e.key == "Enter" or e.key == " " {
            e.preventDefault();
            open_invoice();
        }
    }

    return <TableRow
        tabIndex={0}
        role="link"
        aria-label={"Open " + provider + " invoice"}
        onClick={handle_click}
        onKeyDown={handle_key}
        className="cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-blue-700"
    >
        <TableCell className="pl-3 pr-4">
            <span className="font-medium text-gray-1000">{provider}</span>
        </TableCell>
        <TableCell className="hidden max-w-56 truncate px-4 text-gray-900 md:table-cell">
            {invoice_file_name(invoice_id) as str}
        </TableCell>
        <TableCell className="hidden px-4 text-gray-900 lg:table-cell">
            {invoice_completed_on(invoice_id) as str}
        </TableCell>
        <TableCell className="px-4 text-right tabular-nums text-gray-900">
            {invoice_final_cost(invoice_id) as str}
        </TableCell>
        <TableCell className="hidden px-4 text-right tabular-nums font-medium text-gray-1000 sm:table-cell">
            {invoice_savings(invoice_id) as str}
        </TableCell>
        <TableCell className="pl-4 pr-3 text-right">
            <Badge
                variant="outline"
                className="h-6 border-success-border bg-success-background px-2.5 text-success"
            >
                {invoice_result(invoice_id) as str}
            </Badge>
        </TableCell>
    </TableRow>;
}


def:pub DashboardHomePage() -> JsxElement {
    history_ids: list[str] = invoice_ids() as list[str];

    return <main className="mx-auto flex w-full max-w-7xl flex-1 flex-col gap-10 px-4 py-10 text-gray-1000 sm:px-8 sm:py-12">
        <section aria-label="Negotiation metrics">
            <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
                <DashboardMetric
                    label="Invoices processed"
                    value={dashboard_invoice_count() as str}
                    detail="Completed bill negotiations"
                />
                <DashboardMetric
                    label="Money saved"
                    value={dashboard_money_saved() as str}
                    detail="Across all negotiated invoices"
                />
                <DashboardMetric
                    label="Hours saved"
                    value={dashboard_hours_saved() as str}
                    detail="Estimated administrative time"
                />
                <DashboardMetric
                    label="Patterns learned"
                    value={dashboard_patterns_learned() as str}
                    detail="Reusable provider and charge signals"
                />
            </div>
        </section>

        <section aria-label="Latest invoices">
            <Table aria-label="Latest negotiated invoices">
                <TableHeader>
                    <TableRow>
                        <TableHead className="pl-3 pr-4">Provider</TableHead>
                        <TableHead className="hidden px-4 md:table-cell">
                            Invoice
                        </TableHead>
                        <TableHead className="hidden px-4 lg:table-cell">
                            Completed
                        </TableHead>
                        <TableHead className="px-4 text-right">
                            Final bill
                        </TableHead>
                        <TableHead className="hidden px-4 text-right sm:table-cell">
                            Saved
                        </TableHead>
                        <TableHead className="pl-4 pr-3 text-right">
                            Result
                        </TableHead>
                    </TableRow>
                </TableHeader>
                <TableBody>
                    {for invoice_id in history_ids {
                        <InvoiceDashboardRow
                            key={invoice_id}
                            invoice_id={invoice_id}
                        />
                    }}
                </TableBody>
            </Table>
        </section>
    </main>;
}
