"""Authenticated BillBacked navigation and invoice history."""

import from "@jac/runtime" { Link }
import from ".ui.avatar" { Avatar, AvatarFallback }
import from ".ui.dropdown_menu" {
    DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuLabel,
    DropdownMenuSeparator, DropdownMenuTrigger
}
import from ".ui.sidebar" {
    Sidebar, SidebarContent, SidebarFooter, SidebarGroup, SidebarGroupContent,
    SidebarGroupLabel, SidebarHeader, SidebarMenu, SidebarMenuItem
}
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    AddInvoiceIcon, Invoice01Icon, Logout01Icon, Settings01Icon
}


def:pub InvoiceHistoryLink(
    href: str,
    provider: str,
    detail: str,
    active: bool
) -> JsxElement {
    link_state = (
        "bg-sidebar-accent text-sidebar-accent-foreground"
        if active
        else "hover:bg-sidebar-accent hover:text-sidebar-accent-foreground"
    );

    return <SidebarMenuItem>
        <Link
            to={href}
            aria-current={"page" if active else None}
            className={"flex min-h-14 w-full items-start gap-2 rounded-xl px-2 py-2.5 text-left transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-700 " + link_state}
        >
            <HugeiconsIcon
                icon={Invoice01Icon}
                strokeWidth={2}
                className="mt-0.5 size-4 shrink-0 text-gray-900"
            />
            <span className="flex min-w-0 flex-col gap-0.5">
                <span className="truncate text-sm font-medium">{provider}</span>
                <span className="truncate text-xs font-normal text-gray-700">
                    {detail}
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
    def handle_logout(_: any) {
        onLogout();
    }

    def handle_settings(_: any) {
        if onSettings {
            onSettings();
        }
    }

    new_audit_active = (
        active_path == "/dashboard" or active_path == "/dashboard/audit"
    );
    new_audit_state = (
        "bg-sidebar-accent text-sidebar-accent-foreground"
        if new_audit_active
        else "hover:bg-sidebar-accent hover:text-sidebar-accent-foreground"
    );
    settings_state = (
        "bg-sidebar-accent text-sidebar-accent-foreground"
        if active_path == "/dashboard/settings"
        else "hover:bg-sidebar-accent hover:text-sidebar-accent-foreground"
    );

    return <Sidebar collapsible="offcanvas">
        <SidebarHeader>
            <div className="px-1 pt-2">
                <Link
                    to="/dashboard"
                    className="flex h-10 items-center gap-2 rounded-lg px-2 text-base font-semibold tracking-[-0.03em] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-700"
                >
                    BillBacked<span className="text-blue-700">.</span>
                </Link>
            </div>
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
                                        <HugeiconsIcon icon={AddInvoiceIcon} strokeWidth={2} />
                                        <span>New audit</span>
                                    </Link>
                                </SidebarMenuItem>
                                <SidebarMenuItem>
                                    <Link
                                        to="/dashboard/settings"
                                        aria-current={"page" if active_path == "/dashboard/settings" else None}
                                        className={"flex min-h-11 w-full items-center gap-2 rounded-xl px-2 text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-700 " + settings_state}
                                    >
                                        <HugeiconsIcon icon={Settings01Icon} strokeWidth={2} />
                                        <span>Settings</span>
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
                                    <InvoiceHistoryLink
                                        href="/dashboard/invoices/st-joseph"
                                        provider="St. Joseph Medical Center"
                                        detail="Negotiated · $1,240 saved"
                                        active={active_path == "/dashboard/invoices/st-joseph"}
                                    />
                                    <InvoiceHistoryLink
                                        href="/dashboard/invoices/mercy-general"
                                        provider="Mercy General Hospital"
                                        detail="Negotiated · $860 saved"
                                        active={active_path == "/dashboard/invoices/mercy-general"}
                                    />
                                    <InvoiceHistoryLink
                                        href="/dashboard/invoices/northside-imaging"
                                        provider="Northside Imaging"
                                        detail="Negotiated · $475 saved"
                                        active={active_path == "/dashboard/invoices/northside-imaging"}
                                    />
                                    <InvoiceHistoryLink
                                        href="/dashboard/invoices/lakeshore-cardio"
                                        provider="Lakeshore Cardiology"
                                        detail="Negotiated · $690 saved"
                                        active={active_path == "/dashboard/invoices/lakeshore-cardio"}
                                    />
                                </SidebarMenu>
                            </div>
                        </SidebarGroupContent>
                    </SidebarGroup>
                </div>
            </div>
        </SidebarContent>

        <SidebarFooter>
            <div className="p-1">
                <DropdownMenu>
                    <DropdownMenuTrigger asChild={True}>
                        <button
                            type="button"
                            aria-label="Open account menu"
                            className="flex min-h-12 w-full items-center gap-3 overflow-hidden rounded-xl p-2 text-left transition-colors hover:bg-sidebar-accent focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-700"
                        >
                            <Avatar className="size-8 rounded-full">
                                <AvatarFallback className="rounded-full">B</AvatarFallback>
                            </Avatar>
                            <span className="flex min-w-0 flex-col">
                                <span className="truncate text-sm font-medium">{name}</span>
                                <span className="truncate text-xs text-gray-700">
                                    {email if email else "Private Medicare workspace"}
                                </span>
                            </span>
                        </button>
                    </DropdownMenuTrigger>
                    <DropdownMenuContent side="right" align="end" className="w-60">
                        <DropdownMenuLabel>
                            <div className="flex flex-col">
                                <span className="text-sm font-medium">{name}</span>
                                <span className="text-xs font-normal text-muted-foreground">
                                    {email if email else "BillBacked account"}
                                </span>
                            </div>
                        </DropdownMenuLabel>
                        <DropdownMenuSeparator />
                        {if onSettings {
                            <DropdownMenuItem
                                key="settings"
                                onSelect={handle_settings}
                                className="cursor-pointer"
                            >
                                <HugeiconsIcon icon={Settings01Icon} strokeWidth={2} />
                                Settings
                            </DropdownMenuItem>
                        }}
                        <DropdownMenuItem onSelect={handle_logout} className="cursor-pointer">
                            <HugeiconsIcon icon={Logout01Icon} strokeWidth={2} />
                            Sign out
                        </DropdownMenuItem>
                    </DropdownMenuContent>
                </DropdownMenu>
            </div>
        </SidebarFooter>
    </Sidebar>;
}
