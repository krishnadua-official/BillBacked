"""BillBacked client composition root."""

import ".styles.global.css";
import from "@jac/runtime" { Router, Routes, Route, AuthGuard }
import from .components.AuditProcessPage { AuditProcessPage }
import from .components.BillAuditPage { BillAuditPage }
import from .components.DashboardLayout { DashboardLayout }
import from .components.LandingPage { LandingPage }
import from .components.LoginPage { LoginPage }
import from .components.SettingsPage { SettingsPage }
import from .components.SignupPage { SignupPage }

def:pub app() -> JsxElement {
    return <Router>
        <Routes>
            <Route path="/" element={<LandingPage />} />
            <Route element={<AuthGuard redirect="/login" />}>
                <Route path="/dashboard" element={<DashboardLayout />}>
                    <Route index element={<BillAuditPage />} />
                    <Route path="audit" element={<AuditProcessPage />} />
                    <Route
                        path="invoices/:invoice_id"
                        element={<AuditProcessPage />}
                    />
                    <Route path="settings" element={<SettingsPage />} />
                </Route>
            </Route>
            <Route path="/login" element={<LoginPage />} />
            <Route path="/signup" element={<SignupPage />} />
        </Routes>
    </Router>;
}
