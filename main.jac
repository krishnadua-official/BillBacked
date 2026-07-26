"""BillBacked composition root.

The pricing import registers the Medicare pricing endpoints. The client root
loads global styles and declares every public and authenticated route.
"""

import from services.pricing {
    PriceResult, LocalityInfo, LabPriceResult, CodeMatch,
    get_price, list_localities, get_lab_price, search_by_description
}
import from services.extractor { StructuredDocument, LineItem, DocumentType, upload_bills }
import from services.negotiation {
    NegotiationCase, NegotiationCallResult,
    get_demo_negotiation_case, start_demo_negotiation_call
}
import from services.email_negotiation {
    StartNegotiation, SimulateProviderReply, StartNegotiationFromAudit,
    get_case, get_case_by_id, list_cases,
    send_email_test, send_email_page, resend_inbound_webhook,
    CaseView, CaseDetailView, LineItemView, MessageView,
    SendEmailResult, WebhookResult
}
import from services.discrepancy {
    LineDiscrepancy, BillAudit,
    analyze_bill, audit_bill
}
import from services.patient {
    Patient, PatientView, CoverageType,
    my_patient, SavePatientProfile
}

cl {
    import ".styles.global.css";
    import from "@jac/runtime" {
        Router, Routes, Route, Navigate, AuthGuard
    }
    import from .components.AuditProcessPage { AuditProcessPage }
    import from .components.BillAuditPage { BillAuditPage }
    import from .components.BrandLogo { BrandHead }
    import from .components.DashboardLayout { DashboardLayout }
    import from .components.LandingPage { LandingPage }
    import from .components.LegalPages { PrivacyPage, TermsPage }
    import from .components.LoginPage { LoginPage }
    import from .components.ScrollToTop { ScrollToTop }
    import from .components.SettingsPage { SettingsPage }
    import from .components.SignupPage { SignupPage }

    def:pub app() -> JsxElement {
        return <Router>
            <BrandHead />
            <ScrollToTop />
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
                            path="*"
                            element={
                                <Navigate to="/dashboard" replace={True} />
                            }
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
