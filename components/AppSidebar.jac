"""Authenticated BillBacked navigation and invoice history."""

import from "@jac/runtime" { Link }
import from ".AccountMenu" { AccountMenu }
import from ".BrandLogo" { BrandLockup }
import from ".ui.sidebar" {
    Sidebar, SidebarContent, SidebarFooter, SidebarGroup, SidebarGroupContent,
    SidebarGroupLabel, SidebarHeader, SidebarMenu, SidebarMenuItem
}
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    AddInvoiceIcon, Home01Icon, Invoice01Icon
}
sv import from ..services.bill { BillView, my_bills }


def:pub PrimarySidebarLink(
    route: str,
    label: str,
    icon: JsxElement,
    active: bool
) -> JsxElement {
    link_state = (
        "bg-sidebar-accent text-sidebar-accent-foreground"
        if active
        else "hover:bg-sidebar-accent hover:text-sidebar-accent-foreground"
    );

    return <SidebarMenuItem>
        <Link
            to={route}
            aria-current={"page" if active else None}
            className={"flex min-h-11 w-full items-center gap-2 rounded-xl px-2 text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-700 " + link_state}
        >
            {icon}
            <span>{label}</span>
        </Link>
    </SidebarMenuItem>;
}


def:pub InvoiceHistoryLink(
    bill: BillView,
    active: bool
) -> JsxElement {
    route: str = "/dashboard/invoices/" + bill.id;
    provider: str = bill.provider_name if bill.provider_name else "Unknown provider";
    detail_label: str = (
        f"${bill.total_billed:,.2f} billed" if bill.total_billed is not None
        else "Needs review" if len(bill.review_flags) > 0
        else "Extracted"
    );
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
                    {detail_label}
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
    has bills: list[BillView] = [];

    async can with entry {
        bills = await my_bills();
    }

    home_active = active_path == "/dashboard";
    new_audit_active = (
        active_path == "/dashboard/new" or active_path == "/dashboard/audit"
    );

    return <Sidebar collapsible="offcanvas">
        <SidebarHeader className="flex h-12 shrink-0 items-center border-b border-sidebar-border/70 px-3 py-0">
            <Link
                to="/dashboard"
                className="flex h-9 items-center gap-2 rounded-lg px-2 text-sm font-semibold tracking-[-0.03em] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-700"
            >
                <BrandLockup mark_size_class="size-4" />
            </Link>
        </SidebarHeader>

        <SidebarContent>
            <div className="px-1">
                <SidebarGroup>
                    <SidebarGroupContent>
                        <div className="[&_[data-sidebar=menu]]:gap-1">
                            <SidebarMenu>
                                <PrimarySidebarLink
                                    route="/dashboard"
                                    label="Home"
                                    icon={
                                        <HugeiconsIcon
                                            icon={Home01Icon}
                                            strokeWidth={2}
                                            className="size-4 shrink-0"
                                        />
                                    }
                                    active={home_active}
                                />
                                <PrimarySidebarLink
                                    route="/dashboard/new"
                                    label="New audit"
                                    icon={
                                        <HugeiconsIcon
                                            icon={AddInvoiceIcon}
                                            strokeWidth={2}
                                            className="size-4 shrink-0"
                                        />
                                    }
                                    active={new_audit_active}
                                />
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
                                    {for bill in bills {
                                        <InvoiceHistoryLink
                                            key={bill.id}
                                            bill={bill}
                                            active={active_path == "/dashboard/invoices/" + bill.id}
                                        />
                                    }}
                                </SidebarMenu>
                            </div>
                        </SidebarGroupContent>
                    </SidebarGroup>
                </div>
            </div>
        </SidebarContent>

        <SidebarFooter className="border-t border-sidebar-border/70">
            <div className="p-1">
                <AccountMenu
                    name={name}
                    email={email}
                    variant="sidebar"
                    onLogout={onLogout}
                    onSettings={onSettings}
                />
            </div>
        </SidebarFooter>
    </Sidebar>;
}
