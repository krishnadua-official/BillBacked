"""Persistent authenticated shell for audits, invoice history, and settings."""

import from "@jac/runtime" {
    Outlet, jacLogout, useLocation, useNavigate
}
import from ".AppSidebar" { AppSidebar }
import from ".ui.sidebar" {
    SidebarInset, SidebarProvider, SidebarTrigger
}


def:pub DashboardLayout() -> JsxElement {
    location = useLocation();
    nav = useNavigate();
    active_path = str(location["pathname"]);

    def sign_out() {
        jacLogout();
        nav("/login");
    }

    def open_settings() {
        nav("/dashboard/settings");
    }

    page_title = "Invoice audit";
    if active_path == "/dashboard" {
        page_title = "New audit";
    } elif active_path == "/dashboard/settings" {
        page_title = "Settings";
    }

    return <SidebarProvider>
        <AppSidebar
            name="BillBacked member"
            email=""
            active_path={active_path}
            onLogout={sign_out}
            onSettings={open_settings}
        />
        <SidebarInset>
            <header className="sticky top-0 z-30 flex h-12 shrink-0 items-center gap-3 border-b border-border/70 bg-background/95 px-4 backdrop-blur sm:px-6">
                <SidebarTrigger className="size-9" />
                <h1 className="truncate text-sm font-medium text-gray-1000">
                    {page_title}
                </h1>
            </header>
            <Outlet />
        </SidebarInset>
    </SidebarProvider>;
}
