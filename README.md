# BillBacked

BillBacked is a Jac hackathon prototype for auditing Medicare medical bills.
The public landing page explains the product; authenticated users upload a bill,
follow the audit process, review past negotiated invoices, and manage account
settings.

The current audit is intentionally a UI prototype. Files stay in the browser
session, and the agent steps and invoice history are fixtures. The code is
organized so those fixtures can later be replaced by persisted Jac models
without rewriting the dashboard components.

## Run locally

```bash
jac install
jac start --dev main.jac
```

Open <http://localhost:8000>. Client files hot-reload while the server is
running.

## Routes

`main.jac` is the single client route table:

- `/` — public landing page with a sign-in-gated upload prompt
- `/login` and `/signup` — runtime-backed authentication
- `/dashboard` — protected new-audit workspace
- `/dashboard/audit` — protected live agent-process prototype
- `/dashboard/invoices/:invoice_id` — protected completed invoice detail
- `/dashboard/settings` — protected settings page

The nested dashboard routes share `DashboardLayout`, which owns the sidebar,
responsive header, account actions, and full-size content outlet.

## Architecture

```text
main.jac
components/
  LandingPage.jac          public product page
  LoginPage.jac            sign-in flow
  SignupPage.jac           account creation flow
  DashboardLayout.jac      authenticated app shell
  AppSidebar.jac           navigation and invoice-history list
  AccountMenu.jac          shared header/sidebar account-menu composition
  BillAuditPage.jac        bill upload workspace
  AuditProcessPage.jac     active and completed audit views
  InvoiceData.cl.jac       typed prototype invoice source and query boundary
  SettingsPage.jac         account settings
  ui/                      shared jac-shadcn primitives
styles/global.css          design tokens and global styles
```

Keep invoice fixture values in `InvoiceData.cl.jac`; UI components should query
that module instead of defining their own copies. `AccountMenu` supports both
header and sidebar variants so account actions remain one composition.

`services/pricing.sv.jac` provides the Medicare pricing endpoints and uses the
CMS datasets under `pricing/`. The prototype audit UI is not wired to those
endpoints yet. Jac also supplies the authentication runtime used by `jacLogin`,
`jacSignup`, `jacLogout`, and `AuthGuard`.

## Validation

Before committing Jac changes:

```bash
jac check components/InvoiceData.cl.jac
jac check components/AccountMenu.jac
jac check components/AppSidebar.jac
jac check components/AuditProcessPage.jac
jac check main.jac
git diff --check
```

Use the Jac MCP/reference guides before changing Jac syntax. Start with
`jac-core-cheatsheet`, then load the task-specific client, routing, styling, or
type guide.
