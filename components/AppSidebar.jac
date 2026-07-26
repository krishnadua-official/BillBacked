"""Authenticated BillBacked navigation and invoice history."""

import from "@jac/runtime" { Link }
import from ".AccountMenu" { AccountMenu }
import from ".ui.sidebar" {
    Sidebar, SidebarContent, SidebarFooter, SidebarGroup, SidebarGroupContent,
    SidebarGroupLabel, SidebarHeader, SidebarMenu, SidebarMenuItem
}
import from ".InvoiceData" {
    invoice_ids, invoice_provider, invoice_route, invoice_savings_label
}
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    AddInvoiceIcon, Invoice01Icon
}


def:pub InvoiceHistoryLink(
    invoice_id: str,
    active: bool
) -> JsxElement {
    route: str = invoice_route(invoice_id) as str;
    provider: str = invoice_provider(invoice_id) as str;
    savings_label: str = invoice_savings_label(invoice_id) as str;
    link_state = (
        "bg-sidebar-accent text-sidebar-accent-foreground"
        if active
        else "hover:bg-sidebar-accent hover:text-sidebar-accent-foreground"
    );

    return <SidebarMenuItem>
        <Link
            to={route}
            aria-current={"page" if active else None}
            className={"flex min-h-14 w-full items-start gap-2 rounded-xl px-2 py-2.5 text-left transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-700 " + link_state}
        >
            <HugeiconsIcon
                icon={Invoice01Icon}
                strokeWidth={2}
                className="mt-0.5 size-4 shrink-0 text-gray-900"
            />
            <span className="flex min-w-0 flex-col gap-0.5">
                <span className="truncate text-sm font-medium">
                    {provider}
                </span>
                <span className="truncate text-xs font-normal text-gray-700">
                    {savings_label}
                </span>
            </span>
        </Link>
    </SidebarMenuItem>;
}


def:pub AppSidebar(
    name: str,
    email: str,
    onLogout: Callable[[], None],
    active_path: str = "",
    onSettings: Callable[[], None] | None = None
) -> JsxElement {
    history_ids: list[str] = invoice_ids() as list[str];
    new_audit_active = (
        active_path == "/dashboard" or active_path == "/dashboard/audit"
    );
    new_audit_state = (
        "bg-sidebar-accent text-sidebar-accent-foreground"
        if new_audit_active
        else "hover:bg-sidebar-accent hover:text-sidebar-accent-foreground"
    );

    return <Sidebar collapsible="offcanvas">
        <SidebarHeader className="flex h-12 shrink-0 items-center border-b border-sidebar-border/70 px-3 py-0">
            <Link
                to="/dashboard"
                className="flex h-9 items-center gap-2 rounded-lg px-2 text-sm font-semibold tracking-[-0.03em] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-700"
            >
                BillBacked<span className="text-blue-700">.</span>
            </Link>
        </SidebarHeader>

        <SidebarContent>
            <div className="px-1">
                <SidebarGroup>
                    <SidebarGroupContent>
                        <div className="[&_[data-sidebar=menu]]:gap-1">
                            <SidebarMenu>
                                <SidebarMenuItem>
                                    <Link
                                        to="/dashboard"
                                        aria-current={"page" if new_audit_active else None}
                                        className={"flex min-h-11 w-full items-center gap-2 rounded-xl px-2 text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-700 " + new_audit_state}
                                    >
                                        <HugeiconsIcon
                                            icon={AddInvoiceIcon}
                                            strokeWidth={2}
                                            className="size-4 shrink-0"
                                        />
                                        <span>New audit</span>
                                    </Link>
                                </SidebarMenuItem>
                            </SidebarMenu>
                        </div>
                    </SidebarGroupContent>
                </SidebarGroup>

                <div className="mt-4">
                    <SidebarGroup>
                        <SidebarGroupLabel>Past invoices</SidebarGroupLabel>
                        <SidebarGroupContent>
                            <div className="[&_[data-sidebar=menu]]:gap-1">
                                <SidebarMenu>
                                    {for invoice_id in history_ids {
                                        <InvoiceHistoryLink
                                            key={invoice_id}
                                            invoice_id={invoice_id}
                                            active={
                                                active_path
                                                == (invoice_route(invoice_id) as str)
                                            }
                                        />
                                    }}
                                </SidebarMenu>
                            </div>
                        </SidebarGroupContent>
                    </SidebarGroup>
                </div>
            </div>
        </SidebarContent>

        <SidebarFooter>
            <div className="p-1">
                <AccountMenu
                    name={name}
                    email={email}
                    description="Private Medicare workspace"
                    variant="sidebar"
                    onLogout={onLogout}
                    onSettings={onSettings}
                />
            </div>
        </SidebarFooter>
    </Sidebar>;
}
