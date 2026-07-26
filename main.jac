"""BillBacked composition root.

The pricing import registers the Medicare pricing endpoints. The client root
loads global styles and declares every public and authenticated route.
"""

import from services.pricing {
    PriceResult, LocalityInfo, LabPriceResult,
    get_price, list_localities, get_lab_price
}
import from services.extractor { StructuredDocument, LineItem, DocumentType, upload_bill }
import from services.negotiation {
    NegotiationCase, NegotiationCallResult,
    get_demo_negotiation_case, start_demo_negotiation_call
}

cl {
    import ".styles.global.css";
    import from "@jac/runtime" { Router, Routes, Route, AuthGuard }
    import from .components.AuditProcessPage { AuditProcessPage }
    import from .components.BillAuditPage { BillAuditPage }
    import from .components.DashboardLayout { DashboardLayout }
    import from .components.LandingPage { LandingPage }
    import from .components.LegalPages { PrivacyPage, TermsPage }
    import from .components.LoginPage { LoginPage }
    import from .components.NegotiationCallPage { NegotiationCallPage }
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
                        <Route
                            path="call-test"
                            element={<NegotiationCallPage />}
                        />
                    </Route>
                </Route>
                <Route path="/login" element={<LoginPage />} />
                <Route path="/signup" element={<SignupPage />} />
                <Route path="/privacy" element={<PrivacyPage />} />
                <Route path="/terms" element={<TermsPage />} />
            </Routes>
        </Router>;
    }
}
