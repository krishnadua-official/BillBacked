# BillBacked

![BillBacked landing page](assets/readme/billbacked-landing-page.png)

BillBacked is a Jac hackathon prototype for auditing Medicare medical bills.
The public landing page explains the product; authenticated users upload a bill,
follow the audit process, review past negotiated invoices, and manage account
settings.

The current audit is intentionally a UI prototype. Files stay in the browser
session, and the agent steps and invoice history are fixtures. The code is
organized so those fixtures can later be replaced by persisted Jac models
without rewriting the dashboard components.

The ElevenLabs/Twilio boundary is reserved for the final outreach stage. The
standalone self-call screen has been removed: an audit must finish reading,
organizing, pricing, and approval before the agent may contact a provider by
email or phone.

## Run locally

```bash
cp .env.example .env.local
set -a
source .env.local
set +a
jac install
jac start --dev main.jac
```

Open <http://localhost:8000>. Client files hot-reload while the server is
running. The app works without the ElevenLabs variables; they are only needed
when the final provider-call integration is enabled. Source `.env.local` again
when starting from a new terminal session.

## Routes

`main.jac` is the single client route table:

- `/` — public landing page with a sign-in-gated upload prompt
- `/login` and `/signup` — runtime-backed authentication with required Terms
  and Privacy consent before account creation
- `/privacy` and `/terms` — public prototype legal notices
- `/dashboard` — protected new-audit workspace
- `/dashboard/audit` — protected live agent-process prototype
- `/dashboard/invoices/:invoice_id` — protected completed invoice detail
- `/dashboard/settings` — protected settings page

The nested dashboard routes share `DashboardLayout`, which owns the sidebar,
responsive header, account actions, and full-size content outlet. Removed or
unknown dashboard paths redirect to the new-audit workspace.

## Architecture

```text
main.jac
components/
  LandingPage.jac          public product page
  LoginPage.jac            sign-in flow
  SignupPage.jac           account creation flow
  SignupConsentStep.jac    required legal-consent step before signup
  LegalPages.jac           shared legal-page layout, Privacy, and Terms
  SiteFooter.jac           public navigation including legal links
  DashboardLayout.jac      authenticated app shell
  AppSidebar.jac           navigation and invoice-history list
  AccountMenu.jac          shared header/sidebar account-menu composition
  BillAuditPage.jac        bill upload workspace
  AuditProcessPage.jac     active and completed audit views
  NegotiationCallControl.jac compact final-step ElevenLabs call action
  InvoiceData.cl.jac       typed prototype invoice source and query boundary
  SettingsPage.jac         account settings
  ui/                      shared jac-shadcn primitives
styles/global.css          design tokens and global styles
services/
  negotiation.sv.jac      fictional case, call guardrails, ElevenLabs boundary
```

Keep invoice fixture values in `InvoiceData.cl.jac`; UI components should query
that module instead of defining their own copies. `AccountMenu` supports both
header and sidebar variants so account actions remain one composition.

`services/pricing.sv.jac` provides the Medicare pricing endpoints and uses the
CMS datasets under `pricing/`. The prototype audit UI is not wired to those
endpoints yet. Jac also supplies the authentication runtime used by `jacLogin`,
`jacSignup`, `jacLogout`, and `AuthGuard`.

### ElevenLabs and Twilio setup for final outreach

1. Buy or claim a Twilio number with voice capability. A Twilio trial can call
   only verified destination numbers and adds its trial announcement.
2. In ElevenLabs, import that Twilio number with its Account SID and Auth Token.
3. Create a conversational agent for provider outreach. In its Security
   settings, allow overrides for the system prompt and first message; the
   server supplies both for every fictional call.
4. Create a restricted ElevenLabs API key that can use Conversational AI.
5. Put the API key, agent ID, and imported ElevenLabs phone-number ID in the
   ignored `.env.local`, then restart `jac start`. The backend
   boundary remains available for the approved final stage, but no standalone
   test-call route is exposed in the product UI.

The `TWILIO_*` values in `.env.local` document the native-integration setup but
are not read by the BillBacked server. Twilio's temporary Try Out Voice number
cannot be imported into ElevenLabs because it is not an API-manageable number;
an active Twilio voice number is required to obtain
`ELEVENLABS_PHONE_NUMBER_ID`.

Twilio and ElevenLabs can both charge for usage. Trial restrictions and
included quotas change over time, so confirm them in both dashboards before
placing calls.

## Validation

Before committing Jac changes:

```bash
jac check components/InvoiceData.cl.jac
jac check components/AccountMenu.jac
jac check components/AppSidebar.jac
jac check components/AuditProcessPage.jac
jac check components/NegotiationCallControl.jac
jac check services/negotiation.sv.jac
jac test services/negotiation.test.jac
jac check main.jac
git diff --check
```

Use the Jac MCP/reference guides before changing Jac syntax. Start with
`jac-core-cheatsheet`, then load the task-specific client, routing, styling, or
type guide.
