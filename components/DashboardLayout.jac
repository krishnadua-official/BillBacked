"""Persistent authenticated shell for audits, invoice history, and settings."""

import from "@jac/runtime" {
    Outlet, jacLogout, useLocation, useNavigate
}
import from ".AppSidebar" { AppSidebar }
import from ".ui.sidebar" {
    SidebarInset, SidebarProvider, SidebarTrigger
}
sv import from ..services.patient { PatientView, my_patient }


async def _registered_account_identity() -> str {
    token = localStorage.getItem("jac_token");
    if not token {
        return "";
    }

    response: any = None;
    body_text: str = "";
    try {
        response = await fetch(
            "/user/me",
            {"headers": {"Authorization": "Bearer " + str(token)}}
        );
        if not response.ok {
            return "";
        }
        body_text = await response.text();
        payload: any = JSON.parse(body_text);
        data = payload["data"];
        if data and data["identities"] {
            for identity in data["identities"] {
                if identity["type"] == "email" and identity["value"] {
                    return str(identity["value"]);
                }
            }
            first_identity = data["identities"][0];
            if first_identity["value"] {
                return str(first_identity["value"]);
            }
        }
        return "";
    } except Exception {
        return "";
    }
}


def:pub DashboardLayout() -> JsxElement {
    has account_name: str = "Account",
        account_email: str = "";

    location = useLocation();
    nav = useNavigate();
    active_path = str(location["pathname"]);

    async can with entry {
        patient: PatientView | None = None;
        registered_identity: str = "";
        patient = await my_patient();
        registered_identity = await _registered_account_identity();

        if patient is not None and (patient as PatientView).name.strip() {
            account_name = (patient as PatientView).name.strip();
            account_email = registered_identity;
        } elif registered_identity {
            account_name = registered_identity;
        }
    }

    def sign_out() {
        jacLogout();
        nav("/login");
    }

    def open_settings() {
        nav("/dashboard/settings");
    }

    page_title = "Invoice audit";
    if active_path == "/dashboard" {
        page_title = "Dashboard";
    } elif active_path == "/dashboard/new" {
        page_title = "New audit";
    } elif active_path == "/dashboard/settings" {
        page_title = "Settings";
    }

    return <SidebarProvider>
        <AppSidebar
            name={account_name}
            email={account_email}
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
