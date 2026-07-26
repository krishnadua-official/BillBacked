"""BillBacked client composition root."""

import ".styles.global.css";
import from "@jac/runtime" { Router, Routes, Route }
import from .components.BillAuditPage { BillAuditPage }
import from .components.LoginPage { LoginPage }
import from .components.SignupPage { SignupPage }

def:pub app() -> JsxElement {
    return <Router>
        <Routes>
            <Route path="/" element={<BillAuditPage />} />
            <Route path="/dashboard" element={<BillAuditPage />} />
            <Route path="/login" element={<LoginPage />} />
            <Route path="/signup" element={<SignupPage />} />
        </Routes>
    </Router>;
}
