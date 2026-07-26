"""Composition root.

This file does three things:

  1. Imports the server module, which registers each name from
     `services/notes.sv.jac` as a REST endpoint -- functions under
     `/function/<name>`, walkers under `/walker/<Name>`. Import the walkers
     too, not just the functions: an unimported name is not an endpoint.
     (Plain `import` here -- never `sv import`, which would mean a
     separate microservice process. And no leading dot -- the path is
     absolute or it crashes at runtime.)
  2. Loads the app-wide stylesheet into the client bundle.
  3. Declares the routes. This is MANUAL routing: `base_route_app = "app"`
     in jac.toml points the client at `app()` below, which owns the
     <Router>/<Routes>/<Route> table. There is no `pages/` directory.

`/dashboard` is protected by nesting it under an <AuthGuard> layout route:
logged-in visitors fall through the guard's <Outlet/> to the page, everyone
else is redirected to /login before DashboardPage ever renders. The guard
lives in the route table, so there is exactly one place to check.
"""

import from services.notes {
    Note, NoteView, Profile, Stats,
    list_notes, my_profile, note_stats,
    AddNote, DeleteNote, SaveProfile, ToggleNote
}

import ".styles.global.css";
import from "@jac/runtime" { Router, Routes, Route, Navigate, AuthGuard, jacIsLoggedIn }
import from .components.LoginPage { LoginPage }
import from .components.SignupPage { SignupPage }
import from .components.DashboardPage { DashboardPage }

"""/ -- send visitors wherever they belong."""
def:pub IndexRedirect() -> JsxElement {
    if jacIsLoggedIn() {
        return <Navigate to="/dashboard" replace={True} />;
    }
    return <Navigate to="/login" replace={True} />;
}

def:pub app() -> JsxElement {
    return <div className="min-h-svh bg-background text-foreground antialiased">
        <Router>
            <Routes>
                <Route path="/" element={<IndexRedirect />} />
                <Route path="/login" element={<LoginPage />} />
                <Route path="/signup" element={<SignupPage />} />
                {#* AuthGuard is a LAYOUT route: when logged in it renders an
                    <Outlet/> for its child routes; when logged out it
                    redirects. Do NOT pass the page as AuthGuard's JSX child --
                    children are ignored, the Outlet renders nothing, and the
                    page goes silently blank. Nest a <Route> instead. *#}
                <Route element={<AuthGuard redirect="/login" />}>
                    <Route path="/dashboard" element={<DashboardPage />} />
                </Route>
            </Routes>
        </Router>
    </div>;
}
