"""Agent 4 -- Composer & Negotiator backend.

Owns everything past the analyzed-bill handoff:
  * Case / LineItem / Message graph model.
  * `_load_mock_case_bundle` -- the seam with Agents 1-3. When teammates land the
    real extractor / discrepancy / strategist chain they replace this function's
    body; the rest of this file never has to change.
  * Three static drafters (`_compose_dispute_email`, `_compose_provider_pushback`,
    `_compose_counter_response`). No LLM. Deterministic output that reads the
    case data and produces a professional email/reply.
  * `_send_email` -- outbound HTTP to Resend, silent-fail on any error so a demo
    with a missing key still shows the drafted message in the UI.
  * Four endpoints -- `list_cases`, `get_case` (reads, cached), `StartNegotiation`,
    `SimulateProviderReply` (writes, invalidate the cache).

Underscore-prefixed helpers stay off the API (`_send_email`, `_load_mock_case_bundle`,
`_compose_*`, `_now`, `_case_summary`). See `services/notes.sv.jac` for the same convention.

Walker naming: don't call an ability `drop` -- see the note in notes.sv.jac. This
file uses `run` and `reply`.
"""

import os;
import re;
import requests;
import from datetime { datetime, timezone }
import from http { HTTPMethod }
import from fastapi.responses { HTMLResponse }
import from services.discrepancy { BillAudit, LineDiscrepancy }


# Demo-only knob. In the real product this comes from the parsed bill; for the
# hackathon we send every negotiation to the team's shared test inbox.
glob TEST_RECIPIENT: str = "georgeceja08@gmail.com";


# ---------------------------------------------------------------------------
# GRAPH MODEL
# ---------------------------------------------------------------------------

node Case {
    has provider_name: str = "";
    has provider_email: str = "";
    has patient_name: str = "";
    has status: str = "open";
    has original_total: float = 0.0;
    has disputed_total: float = 0.0;
    has strategist_angle: str = "";
    has created_at: str = "";
    has updated_at: str = "";
    # Root anchor id of the user who created this case. Stamped at StartNegotiation
    # so the anonymous webhook (and any logging) can tell which user owns a reply.
    has owner_root: str = "";
    # Inbound messages arrive via the anonymous /webhook/resend-inbound endpoint,
    # which cannot own graph edges under the case's per-user root. Stored as
    # dicts directly on the case (mutation allowed by grant(case, WritePerm))
    # so the owner sees them alongside outbound Message edges.
    has inbound_messages: list[dict[str, any]] = [];

    def to_view -> CaseView {
        return CaseView(
            id=jid(self),
            provider_name=self.provider_name,
            provider_email=self.provider_email,
            patient_name=self.patient_name,
            status=self.status,
            original_total=self.original_total,
            disputed_total=self.disputed_total,
            message_count=len([self -->][?:Message]) + len(self.inbound_messages),
            owner_root=self.owner_root,
            created_at=self.created_at,
            updated_at=self.updated_at
        );
    }

    def to_detail_view -> CaseDetailView {
        items = [i.to_view() for i in [self -->][?:LineItem]];
        msgs = [m.to_view() for m in [self -->][?:Message]];
        for entry in self.inbound_messages {
            msgs.append(MessageView(
                id=str(entry.get("id","")),
                direction=str(entry.get("direction","INBOUND")),
                subject=str(entry.get("subject","")),
                body=str(entry.get("body","")),
                to_addr=str(entry.get("to_addr","")),
                from_addr=str(entry.get("from_addr","")),
                sent_ok=bool(entry.get("sent_ok", True)),
                created_at=str(entry.get("created_at",""))
            ));
        }
        msgs.sort(key=lambda (m: MessageView) { m.created_at; });
        return CaseDetailView(
            id=jid(self),
            provider_name=self.provider_name,
            provider_email=self.provider_email,
            patient_name=self.patient_name,
            status=self.status,
            original_total=self.original_total,
            disputed_total=self.disputed_total,
            strategist_angle=self.strategist_angle,
            owner_root=self.owner_root,
            created_at=self.created_at,
            updated_at=self.updated_at,
            line_items=items,
            messages=msgs
        );
    }
}


node LineItem {
    has code: str = "";
    has description: str = "";
    has charged_amount: float = 0.0;
    has medicare_rate: float = 0.0;
    has discrepancy_type: str = "none";
    has discrepancy_amount: float = 0.0;

    def to_view -> LineItemView {
        return LineItemView(
            id=jid(self),
            code=self.code,
            description=self.description,
            charged_amount=self.charged_amount,
            medicare_rate=self.medicare_rate,
            discrepancy_type=self.discrepancy_type,
            discrepancy_amount=self.discrepancy_amount
        );
    }
}


node Message {
    has direction: str = "OUTBOUND";
    has subject: str = "";
    has body: str = "";
    has to_addr: str = "";
    has from_addr: str = "";
    has sent_ok: bool = False;
    has created_at: str = "";

    def to_view -> MessageView {
        return MessageView(
            id=jid(self),
            direction=self.direction,
            subject=self.subject,
            body=self.body,
            to_addr=self.to_addr,
            from_addr=self.from_addr,
            sent_ok=self.sent_ok,
            created_at=self.created_at
        );
    }
}


# ---------------------------------------------------------------------------
# WIRE VIEWS
# ---------------------------------------------------------------------------

obj CaseView {
    has id: str;
    has provider_name: str;
    has provider_email: str;
    has patient_name: str;
    has status: str;
    has original_total: float;
    has disputed_total: float;
    has message_count: int;
    has owner_root: str;
    has created_at: str;
    has updated_at: str;
}


obj LineItemView {
    has id: str;
    has code: str;
    has description: str;
    has charged_amount: float;
    has medicare_rate: float;
    has discrepancy_type: str;
    has discrepancy_amount: float;
}


obj MessageView {
    has id: str;
    has direction: str;
    has subject: str;
    has body: str;
    has to_addr: str;
    has from_addr: str;
    has sent_ok: bool;
    has created_at: str;
}


obj CaseDetailView {
    has id: str;
    has provider_name: str;
    has provider_email: str;
    has patient_name: str;
    has status: str;
    has original_total: float;
    has disputed_total: float;
    has strategist_angle: str;
    has owner_root: str;
    has created_at: str;
    has updated_at: str;
    has line_items: list[LineItemView];
    has messages: list[MessageView];
}


# ---------------------------------------------------------------------------
# THE SEAM WITH AGENTS 1-3
#
# `CaseBundle` is the shape Agent 4 consumes. Teammates producing real analyzed
# bills either replace `_load_mock_case_bundle`'s body or add their own producer
# that returns the same obj -- either way Agent 4's code below never changes.
# ---------------------------------------------------------------------------

obj LineItemBundle {
    has code: str;
    has description: str;
    has charged_amount: float;
    has medicare_rate: float;
    has discrepancy_type: str;
    has discrepancy_amount: float;
}


obj CaseBundle {
    has provider_name: str;
    has provider_email: str;
    has patient_name: str;
    has strategist_angle: str;
    has items: list[LineItemBundle];
}


def _load_mock_case_bundle -> CaseBundle {
    items = [
        LineItemBundle(
            code="99213", description="Office visit, established patient (level 3)",
            charged_amount=340.00, medicare_rate=87.05,
            discrepancy_type="overcharge", discrepancy_amount=252.95
        ),
        LineItemBundle(
            code="80053", description="Comprehensive metabolic panel",
            charged_amount=145.00, medicare_rate=14.51,
            discrepancy_type="overcharge", discrepancy_amount=130.49
        ),
        LineItemBundle(
            code="85025", description="Complete blood count with differential",
            charged_amount=89.00, medicare_rate=10.55,
            discrepancy_type="overcharge", discrepancy_amount=78.45
        ),
        LineItemBundle(
            code="71046", description="Chest X-ray, two views",
            charged_amount=220.00, medicare_rate=32.19,
            discrepancy_type="overcharge", discrepancy_amount=187.81
        ),
        LineItemBundle(
            code="36415", description="Routine venipuncture (blood draw)",
            charged_amount=32.00, medicare_rate=3.00,
            discrepancy_type="overcharge", discrepancy_amount=29.00
        )
    ];
    return CaseBundle(
        provider_name="Sunrise Regional Medical Center",
        provider_email="billing@sunriseregional.example.com",
        patient_name="Margaret Chen",
        strategist_angle="Every line item is priced 5-10x the Medicare-approved rate with no documented modifiers or complexity justification. Lead with the aggregate delta and demand adjustment to Medicare Physician Fee Schedule rates for all listed CPT codes.",
        items=items
    );
}


"""Which category a discrepancy falls into for the negotiation email's
line-item table. Priority order matters when a line trips more than one
flag: duplicate billing and code mismatches are provable independent of
any pricing argument, so they lead; a plain overcharge needs a resolved
benchmark to be citable; anything left unresolved is the weakest claim.
"""
def _discrepancy_type_for(d: LineDiscrepancy) -> str {
    if d.is_duplicate {
        return "duplicate";
    }
    if d.code_mismatch {
        return "mismatched_code";
    }
    if d.benchmark_amount is None {
        return "unresolved";
    }
    if d.flagged {
        return "overcharge";
    }
    return "none";
}


"""Pick the strongest single line item to lead the dispute email with, now
that there is no Agent 3 (Strategist) to make that call. Deterministic
placeholder: the flagged discrepancy with the largest dollar overcharge,
same ranking analyze_bill's own callers used before Agent 3 was removed.
"""
def _lead_argument_for(audit: BillAudit) -> str {
    best: LineDiscrepancy | None = None;
    best_impact: float = 0.0;
    for d in audit.discrepancies {
        if not d.flagged {
            continue;
        }
        impact: float = d.overcharge_amount if d.overcharge_amount is not None else 0.0;
        if best is None or impact > best_impact {
            best = d;
            best_impact = impact;
        }
    }
    if best is not None and (best as LineDiscrepancy).flag_reason {
        return (best as LineDiscrepancy).flag_reason;
    }
    return f"This bill was reviewed against Medicare-approved rates; {audit.flagged_count} of {len(audit.discrepancies)} line items were flagged for discrepancies totaling ${audit.total_overcharge:,.2f}.";
}


"""The real counterpart to _load_mock_case_bundle -- builds a CaseBundle
from Agent 2's actual BillAudit instead of the hardcoded demo data. Added
alongside the mock rather than replacing it, so the existing
StartNegotiation walker (and whatever a teammate has already wired to it)
keeps working unchanged; see StartNegotiationFromAudit below for the real
counterpart to StartNegotiation.
"""
def _build_case_bundle_from_audit(provider_name: str, patient_name: str, audit: BillAudit) -> CaseBundle {
    items: list[LineItemBundle] = [
        LineItemBundle(
            code=d.hcpcs,
            description=d.description,
            charged_amount=d.billed_amount,
            medicare_rate=d.benchmark_amount if d.benchmark_amount is not None else 0.0,
            discrepancy_type=_discrepancy_type_for(d),
            discrepancy_amount=d.overcharge_amount if d.overcharge_amount is not None else 0.0,
        ) for d in audit.discrepancies
    ];
    return CaseBundle(
        provider_name=provider_name,
        provider_email="",
        patient_name=patient_name,
        strategist_angle=_lead_argument_for(audit),
        items=items,
    );
}


# ---------------------------------------------------------------------------
# EMAIL DRAFT SHAPE
# ---------------------------------------------------------------------------

obj EmailDraft {
    has subject: str;
    has body: str;
}


# ---------------------------------------------------------------------------
# HTTP EMAIL SEND
#
# Silent-fail by contract: a missing key or a Resend outage returns False and
# the walker still persists the Message. The UI shows the draft either way.
# The demo doesn't crash because email plumbing was flaky.
# ---------------------------------------------------------------------------

def _send_email(to_addr: str, subject: str, body: str, case_id: str = "") -> bool {
    api_key = os.environ.get("RESEND_API_KEY", "");
    if not api_key {
        print("[negotiation] RESEND_API_KEY not set -- skipping actual send.");
        return False;
    }
    tagged_body = body;
    if case_id {
        tagged_body = (
            body
            + "\n\n---\n"
            + f"[Case Reference: {case_id}] -- please keep this line in your reply so we can route your response to the correct case."
        );
    }
    payload: dict[str, any] = {
        "from": "BillBacked <onboarding@resend.dev>",
        "to": [to_addr],
        "subject": subject,
        "text": tagged_body
    };
    if case_id {
        # Plus-addressed reply_to routes provider responses back through Resend Inbound
        # to /webhook/resend-inbound (once the domain is verified). X-header carries the
        # same id for providers that preserve custom headers.
        payload["reply_to"] = f"cases+{case_id}@onboarding.resend.dev";
        payload["headers"] = {"X-BillBacked-Case-Id": case_id};
    }
    try {
        r = requests.post(
            "https://api.resend.com/emails",
            headers={
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json"
            },
            json=payload,
            timeout=15
        );
        ok = r.status_code == 200;
        if not ok {
            print(f"[negotiation] Resend send failed: {r.status_code} {r.text}");
        }
        return ok;
    } except Exception as e {
        print(f"[negotiation] Resend send exception: {str(e)}");
        return False;
    }
}


# ---------------------------------------------------------------------------
# HELPERS
# ---------------------------------------------------------------------------

def _now -> str {
    return datetime.now(timezone.utc).isoformat();
}


def _msg_id -> str {
    import from uuid { uuid4 }
    return uuid4().hex;
}


def _compose_dispute_email(bundle: CaseBundle) -> EmailDraft {
    original_total = 0.0;
    disputed_total = 0.0;
    for it in bundle.items {
        original_total += it.charged_amount;
        disputed_total += it.medicare_rate;
    }
    savings = original_total - disputed_total;
    lines = [
        "To the Patient Financial Services team,",
        "",
        f"I am writing on behalf of {bundle.patient_name} regarding recent charges from {bundle.provider_name}.",
        "A line-by-line review against the CMS Physician Fee Schedule shows the following overcharges:",
        ""
    ];
    for it in bundle.items {
        if it.discrepancy_type != "none" {
            lines.append(
                f"  - CPT {it.code} ({it.description}): charged ${it.charged_amount:.2f}, Medicare-approved rate ${it.medicare_rate:.2f} -- overcharge of ${it.discrepancy_amount:.2f}."
            );
        }
    }
    lines.append("");
    lines.append(f"Original charged total: ${original_total:.2f}.");
    lines.append(f"Requested adjusted total (Medicare-approved): ${disputed_total:.2f}.");
    lines.append(f"Requested adjustment: ${savings:.2f}.");
    lines.append("");
    lines.append(bundle.strategist_angle);
    lines.append("");
    lines.append("Please issue a revised invoice reflecting the Medicare-approved rates listed above within 30 days.");
    lines.append("");
    lines.append("Regards,");
    lines.append("BillBacked, acting on behalf of the patient");
    return EmailDraft(
        subject=f"Billing review request -- {bundle.patient_name}",
        body="\n".join(lines)
    );
}


def _compose_provider_pushback(case_summary: str) -> str {
    return (
        "Thank you for your inquiry regarding the above account.\n\n"
        "We reviewed the disputed items. As a good-faith gesture, we can offer a 25% reduction "
        "on the office visit and the chest X-ray line items. The laboratory panels, however, "
        "reflect our contracted pricing and are not adjustable to Medicare-only rates.\n\n"
        "If this is acceptable, please confirm and we will issue a revised statement.\n\n"
        "Patient Financial Services"
    );
}


def _compose_counter_response(case_summary: str, provider_reply: str) -> EmailDraft {
    return EmailDraft(
        subject="RE: Billing review -- Medicare-approved rates apply to all listed CPT codes",
        body=(
            "Thank you for the partial concession on the office visit and imaging line.\n\n"
            "The Medicare Physician Fee Schedule, however, applies uniformly to every CPT code on this bill -- "
            "including CPT 80053, 85025, and 36415. These are not discretionary contract items when the "
            "patient is entitled to the Medicare-approved rate, and the schedule is a national benchmark, "
            "not a floor to negotiate above.\n\n"
            "We are requesting the full adjustment to Medicare-approved rates for every disputed line item, "
            "as originally requested. Please issue the revised invoice within 15 days.\n\n"
            "Regards,\n"
            "BillBacked, acting on behalf of the patient"
        )
    );
}


def _case_summary(c: Case) -> str {
    lines = [
        f"Provider: {c.provider_name}",
        f"Patient: {c.patient_name}",
        f"Original charged total: ${c.original_total:.2f}",
        f"Requested adjusted total (Medicare-approved): ${c.disputed_total:.2f}",
        f"Disputed savings: ${c.original_total - c.disputed_total:.2f}",
        "",
        "Disputed line items:"
    ];
    for it in [c -->][?:LineItem] {
        if it.discrepancy_type != "none" {
            lines.append(
                f"  - CPT {it.code} ({it.description}): charged ${it.charged_amount:.2f}, Medicare ${it.medicare_rate:.2f}, delta ${it.discrepancy_amount:.2f}"
            );
        }
    }
    return "\n".join(lines);
}


# ---------------------------------------------------------------------------
# READ ENDPOINTS -- plain `def`, client-cached 60s.
# ---------------------------------------------------------------------------

"""Every case attached to the calling user's root, newest first."""
def list_cases -> list[CaseView] {
    views = [c.to_view() for c in [root -->][?:Case]];
    views.sort(key=lambda (v: CaseView) { v.updated_at; }, reverse=True);
    return views;
}


"""Return one case (with line items and messages) or None. Root-scoped lookup."""
def get_case(case_id: str) -> CaseDetailView | None {
    for c in [root -->][?:Case] {
        if jid(c) == case_id {
            return c.to_detail_view();
        }
    }
    return None;
}


"""REST alias: GET /cases/{case_id}. Returns the same CaseDetailView, scoped
to the caller's own root -- another user's case_id yields None, not 403, so
we don't leak whether that id exists."""
@restspec(method=HTTPMethod.GET, path="/cases/{case_id}")
def get_case_by_id(case_id: str) -> CaseDetailView | None {
    for c in [root -->][?:Case] {
        if jid(c) == case_id {
            return c.to_detail_view();
        }
    }
    return None;
}


# ---------------------------------------------------------------------------
# WRITE ENDPOINTS -- walkers, invalidate cached reads.
# ---------------------------------------------------------------------------

"""Kick off Agent 4. Loads the mock case bundle (stubbed producer for Agents 1-3),
persists Case + LineItems, composes the first dispute email from the case data,
sends it to the demo test inbox, and reports the CaseDetailView the UI needs to render."""
walker StartNegotiation {
    has reports: list[CaseDetailView] = [];

    can run with Root entry {
        bundle = _load_mock_case_bundle();

        original_total = 0.0;
        disputed_total = 0.0;
        for it in bundle.items {
            original_total += it.charged_amount;
            disputed_total += it.medicare_rate;
        }

        now = _now();
        new_case = Case(
            provider_name=bundle.provider_name,
            provider_email=bundle.provider_email,
            patient_name=bundle.patient_name,
            status="drafting",
            original_total=original_total,
            disputed_total=disputed_total,
            strategist_angle=bundle.strategist_angle,
            owner_root=jid(here),
            created_at=now,
            updated_at=now
        );
        here ++> new_case;

        for it in bundle.items {
            new_case ++> LineItem(
                code=it.code, description=it.description,
                charged_amount=it.charged_amount, medicare_rate=it.medicare_rate,
                discrepancy_type=it.discrepancy_type, discrepancy_amount=it.discrepancy_amount
            );
        }

        # Expose this specific case for the anonymous inbound webhook. Case ids
        # are unguessable 128-bit random UUIDs (capability-url pattern). Add Svix
        # signature verification before shipping.
        grant(new_case, level=WritePerm);

        draft = _compose_dispute_email(bundle);
        sent_ok = _send_email(TEST_RECIPIENT, draft.subject, draft.body, jid(new_case));

        new_case ++> Message(
            direction="OUTBOUND",
            subject=draft.subject,
            body=draft.body,
            to_addr=TEST_RECIPIENT,
            from_addr="BillBacked <onboarding@resend.dev>",
            sent_ok=sent_ok,
            created_at=_now()
        );

        new_case.status = "sent";
        new_case.updated_at = _now();

        self.reports.append(new_case.to_detail_view());
        report new_case.to_detail_view();
    }
}


"""Real counterpart to StartNegotiation: same persistence and email-draft
logic, but built from Agent 2's actual BillAudit instead of the hardcoded
demo case. This is the seam _load_mock_case_bundle's docstring described --
the frontend calls upload_bills (Agent 1) then analyze_bill (Agent 2)
itself and hands the resulting BillAudit straight in here, so there is no
separate persisted extraction step to wire up first.
"""
walker StartNegotiationFromAudit {
    has provider_name: str;
    has patient_name: str;
    has audit: BillAudit;
    has reports: list[CaseDetailView] = [];

    can run with Root entry {
        bundle = _build_case_bundle_from_audit(self.provider_name, self.patient_name, self.audit);

        now = _now();
        new_case = Case(
            provider_name=bundle.provider_name,
            provider_email=bundle.provider_email,
            patient_name=bundle.patient_name,
            status="drafting",
            original_total=self.audit.total_billed,
            disputed_total=self.audit.total_benchmark,
            strategist_angle=bundle.strategist_angle,
            owner_root=jid(here),
            created_at=now,
            updated_at=now
        );
        here ++> new_case;

        for it in bundle.items {
            new_case ++> LineItem(
                code=it.code, description=it.description,
                charged_amount=it.charged_amount, medicare_rate=it.medicare_rate,
                discrepancy_type=it.discrepancy_type, discrepancy_amount=it.discrepancy_amount
            );
        }

        # Expose this specific case for the anonymous inbound webhook, same as
        # StartNegotiation -- see the note there on the capability-url pattern.
        grant(new_case, level=WritePerm);

        draft = _compose_dispute_email(bundle);
        sent_ok = _send_email(TEST_RECIPIENT, draft.subject, draft.body, jid(new_case));

        new_case ++> Message(
            direction="OUTBOUND",
            subject=draft.subject,
            body=draft.body,
            to_addr=TEST_RECIPIENT,
            from_addr="BillBacked <onboarding@resend.dev>",
            sent_ok=sent_ok,
            created_at=_now()
        );

        new_case.status = "sent";
        new_case.updated_at = _now();

        self.reports.append(new_case.to_detail_view());
        report new_case.to_detail_view();
    }
}


"""Dev-only. Fabricate a plausible provider pushback, persist it as an inbound
message, then compose and send a counter-response."""
walker SimulateProviderReply {
    has case_id: str = "";
    has reports: list[CaseDetailView] = [];

    can reply with Root entry {
        target: Case | None = None;
        for c in [here -->][?:Case] {
            if jid(c) == self.case_id {
                target = c;
                break;
            }
        }
        if target is None {
            return;
        }

        summary = _case_summary(target);

        pushback = _compose_provider_pushback(summary);
        target ++> Message(
            direction="INBOUND",
            subject=f"RE: Billing review request -- {target.patient_name}",
            body=pushback,
            to_addr="BillBacked <onboarding@resend.dev>",
            from_addr=target.provider_email or "billing@provider.example.com",
            sent_ok=True,
            created_at=_now()
        );

        counter = _compose_counter_response(summary, pushback);
        sent_ok = _send_email(TEST_RECIPIENT, counter.subject, counter.body, jid(target));
        target ++> Message(
            direction="OUTBOUND",
            subject=counter.subject,
            body=counter.body,
            to_addr=TEST_RECIPIENT,
            from_addr="BillBacked <onboarding@resend.dev>",
            sent_ok=sent_ok,
            created_at=_now()
        );

        target.status = "negotiating";
        target.updated_at = _now();

        self.reports.append(target.to_detail_view());
        report target.to_detail_view();
    }
}


# ---------------------------------------------------------------------------
# TEST ENDPOINT -- POST /send-email
#
# Fixed-payload smoke test for the email send path. Builds a dispute-style
# body with a handful of line items (charged vs Medicare-approved) plus a
# CMS Physician Fee Schedule link per CPT code, then fires _send_email.
# ---------------------------------------------------------------------------

obj TestLineItem {
    has code: str;
    has description: str;
    has charged: float;
    has medicare: float;
}


obj SendEmailResult {
    has sent_ok: bool;
    has to_addr: str;
    has subject: str;
    has body: str;
    has line_items_included: int;
}


def _cms_link(code: str) -> str {
    return f"https://www.cms.gov/medicare/physician-fee-schedule/search?Y=2025&HT=0&H1={code}&M=5";
}


def _compose_test_email(bundle: CaseBundle) -> EmailDraft {
    billed_total = 0.0;
    expected_total = 0.0;
    for it in bundle.items {
        billed_total += it.charged_amount;
        expected_total += it.medicare_rate;
    }
    savings = billed_total - expected_total;

    lines = [
        "To the Patient Financial Services team,",
        "",
        f"We reviewed the recent invoice from {bundle.provider_name} for {bundle.patient_name} against Medicare-approved rates and identified the following overcharges:",
        ""
    ];
    for it in bundle.items {
        lines.append(f"- CPT {it.code} ({it.description})");
        lines.append(f"    Charged:            ${it.charged_amount:.2f}");
        lines.append(f"    Medicare-approved:  ${it.medicare_rate:.2f}");
        lines.append(f"    Overcharge:         ${it.charged_amount - it.medicare_rate:.2f}");
        lines.append(f"    Pricing reference:  {_cms_link(it.code)}");
        lines.append("");
    }
    lines.append(f"Total billed:                ${billed_total:.2f}");
    lines.append(f"Total Medicare-approved:     ${expected_total:.2f}");
    lines.append(f"Requested adjustment:        ${savings:.2f}");
    lines.append("");
    lines.append("Please review and issue a revised invoice reflecting the Medicare-approved rates above.");
    lines.append("");
    lines.append("Regards,");
    lines.append("BillBacked");

    return EmailDraft(
        subject=f"Bill review request -- {bundle.patient_name}",
        body="\n".join(lines)
    );
}


@restspec(method=HTTPMethod.POST, path="/send-email")
def:pub send_email_test(bundle: CaseBundle | None = None) -> SendEmailResult {
    active_bundle: CaseBundle = bundle if isinstance(bundle, CaseBundle) else _load_mock_case_bundle();
    draft = _compose_test_email(active_bundle);
    ok = _send_email(TEST_RECIPIENT, draft.subject, draft.body);
    return SendEmailResult(
        sent_ok=ok,
        to_addr=TEST_RECIPIENT,
        subject=draft.subject,
        body=draft.body,
        line_items_included=len(active_bundle.items)
    );
}


glob SEND_EMAIL_PAGE_HTML: str = """<!doctype html>
<html>
<head>
    <meta charset="utf-8">
    <title>BillBacked -- Send Test Email</title>
    <style>
        body { font-family: -apple-system, system-ui, sans-serif; max-width: 900px; margin: 40px auto; padding: 0 20px; color: #111; }
        h1 { margin: 0 0 4px; }
        p.muted { color: #666; margin-top: 0; }
        textarea { width: 100%; font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: 12px; padding: 12px; border: 1px solid #ccc; border-radius: 4px; box-sizing: border-box; }
        button { font-size: 14px; padding: 8px 16px; border: 1px solid #333; background: #111; color: #fff; border-radius: 4px; cursor: pointer; margin-top: 8px; }
        button:disabled { opacity: 0.5; cursor: wait; }
        pre { background: #f4f4f4; padding: 12px; border-radius: 4px; overflow: auto; font-size: 12px; white-space: pre-wrap; }
        h2 { margin-top: 32px; }
        .row { display: flex; gap: 16px; }
        .col { flex: 1; }
        code { background: #f4f4f4; padding: 2px 4px; border-radius: 3px; font-size: 12px; }
    </style>
</head>
<body>
    <h1>Send test email</h1>
    <p class="muted">
        Edit the case bundle JSON below and click Send. The backend composes a dispute email with charged vs Medicare rates and a CMS pricing link per CPT code, then delivers it via Resend to
        <code>georgeceja08@gmail.com</code>. Without <code>RESEND_API_KEY</code> set, the draft still returns for inspection but no email is delivered (<code>sent_ok=false</code>).
    </p>
    <h2>Case bundle</h2>
    <textarea id="bundle" rows="22"></textarea>
    <button id="send">Send</button>
    <h2>Response</h2>
    <div class="row">
        <div class="col">
            <h3>Meta</h3>
            <pre id="meta">(none yet)</pre>
        </div>
        <div class="col">
            <h3>Composed body</h3>
            <pre id="body">(none yet)</pre>
        </div>
    </div>
    <script>
        const DEFAULT_BUNDLE = {
            provider_name: "Sunrise Regional Medical Center",
            provider_email: "billing@sunriseregional.example.com",
            patient_name: "Margaret Chen",
            strategist_angle: "Every line item is priced 5-10x the Medicare-approved rate with no documented modifiers. Lead with the aggregate delta.",
            items: [
                { code: "99213", description: "Office visit, established patient (level 3)", charged_amount: 340.00, medicare_rate: 87.05, discrepancy_type: "overcharge", discrepancy_amount: 252.95 },
                { code: "80053", description: "Comprehensive metabolic panel", charged_amount: 145.00, medicare_rate: 14.51, discrepancy_type: "overcharge", discrepancy_amount: 130.49 },
                { code: "71046", description: "Chest X-ray, two views", charged_amount: 220.00, medicare_rate: 32.19, discrepancy_type: "overcharge", discrepancy_amount: 187.81 }
            ]
        };
        const ta = document.getElementById("bundle");
        ta.value = JSON.stringify(DEFAULT_BUNDLE, null, 2);
        const btn = document.getElementById("send");
        const metaEl = document.getElementById("meta");
        const bodyEl = document.getElementById("body");
        btn.addEventListener("click", async () => {
            let bundle;
            try { bundle = JSON.parse(ta.value); }
            catch (e) { metaEl.textContent = "Invalid JSON: " + e.message; return; }
            btn.disabled = true;
            btn.textContent = "Sending...";
            try {
                const res = await fetch("/send-email", {
                    method: "POST",
                    headers: {"Content-Type": "application/json"},
                    body: JSON.stringify({ bundle })
                });
                const data = await res.json();
                const result = (data && data.data && data.data.result) || {};
                metaEl.textContent = JSON.stringify({
                    http_status: res.status,
                    ok: data.ok,
                    sent_ok: result.sent_ok,
                    to_addr: result.to_addr,
                    subject: result.subject,
                    line_items_included: result.line_items_included,
                    error: data.error
                }, null, 2);
                bodyEl.textContent = result.body || "(no body)";
            } catch (e) {
                metaEl.textContent = "Fetch failed: " + e.message;
            }
            btn.disabled = false;
            btn.textContent = "Send";
        });
    </script>
</body>
</html>""";


@restspec(method=HTTPMethod.GET, path="/send-email")
def:pub send_email_page -> str {
    return SEND_EMAIL_PAGE_HTML;
}


# ---------------------------------------------------------------------------
# INBOUND WEBHOOK -- POST /webhook/resend-inbound
#
# Resend Inbound Email delivery (docs.resend.com/dashboard/webhooks/introduction)
# POSTs an "email.received" event to this endpoint when a provider replies to a
# message we sent. We recover the case_id from (in priority order):
#   1. The X-BillBacked-Case-Id custom header (preserved by well-behaved providers)
#   2. The plus-addressed To: `cases+<case_id>@onboarding.resend.dev`
#   3. A `[Case Reference: <case_id>]` marker at the bottom of the reply body
# then jobj-look-up the Case (bypasses per-user root scoping since the webhook
# is anonymous) and attach an INBOUND Message.
#
# Signature verification: Resend signs webhook payloads via Svix. Not implemented
# here for the hackathon -- set RESEND_WEBHOOK_SECRET and verify svix headers in
# production. TODO.
# ---------------------------------------------------------------------------

obj WebhookResult {
    has received: bool;
    has case_id: str;
    has message_id: str;
    has status: str;   # "stored" | "unmatched" | "not_found" | "ignored"
    has note: str;
}


def _extract_case_id(data: dict[str, any]) -> str {
    # Priority 1 -- custom header (Resend delivers headers as a list of {name, value})
    hdrs = data.get("headers");
    if isinstance(hdrs, list) {
        for h in hdrs {
            if isinstance(h, dict) {
                name = str(h.get("name","")).lower();
                if name == "x-billbacked-case-id" {
                    return str(h.get("value",""));
                }
            }
        }
    } elif isinstance(hdrs, dict) {
        val = hdrs.get("X-BillBacked-Case-Id") or hdrs.get("x-billbacked-case-id");
        if val {
            return str(val);
        }
    }
    # Priority 2 -- plus-addressed To
    tos = data.get("to");
    to_list: list = tos if isinstance(tos, list) else [tos];
    for addr in to_list {
        candidate = "";
        if isinstance(addr, str) {
            candidate = addr;
        } elif isinstance(addr, dict) {
            candidate = str(addr.get("email",""));
        }
        m = re.search(r"cases\+([A-Za-z0-9_\-]+)@", candidate);
        if m {
            return m.group(1);
        }
    }
    # Priority 3 -- body marker
    text = data.get("text") or data.get("html") or data.get("body") or "";
    if isinstance(text, str) {
        m = re.search(r"\[Case Reference:\s*([A-Za-z0-9_\-]+)\s*\]", text);
        if m {
            return m.group(1);
        }
    }
    return "";
}


def _addr_str(field: any) -> str {
    if isinstance(field, str) {
        return field;
    }
    if isinstance(field, dict) {
        return str(field.get("email",""));
    }
    if isinstance(field, list) and len(field) > 0 {
        return _addr_str(field[0]);
    }
    return "";
}


@restspec(method=HTTPMethod.POST, path="/webhook/resend-inbound")
def:pub resend_inbound_webhook(
    type: str = "",
    data: dict[str, any] | None = None,
    created_at: str = ""
) -> WebhookResult {
    payload: dict[str, any] = data if isinstance(data, dict) else {};

    if type and type != "email.received" and type != "email.inbound" {
        return WebhookResult(
            received=True, case_id="", message_id="",
            status="ignored", note=f"event type {type} not handled"
        );
    }

    case_id = _extract_case_id(payload);
    if not case_id {
        print("[negotiation] Inbound webhook: no case reference found in payload");
        return WebhookResult(
            received=True, case_id="", message_id="",
            status="unmatched", note="No case reference in headers, to-address, or body"
        );
    }

    target = jobj(case_id);
    if not isinstance(target, Case) {
        print(f"[negotiation] Inbound webhook: case {case_id} not found");
        return WebhookResult(
            received=True, case_id=case_id, message_id="",
            status="not_found", note="Case id resolved but not a Case node"
        );
    }

    entry: dict[str, any] = {
        "id": _msg_id(),
        "direction": "INBOUND",
        "subject": str(payload.get("subject","(no subject)")),
        "body": str(payload.get("text") or payload.get("html") or ""),
        "to_addr": _addr_str(payload.get("to")),
        "from_addr": _addr_str(payload.get("from")),
        "sent_ok": True,
        "created_at": _now()
    };
    # List reassignment (not .append) so the anchor's dirty tracker persists it.
    target.inbound_messages = target.inbound_messages + [entry];
    target.status = "negotiating";
    target.updated_at = _now();

    print(f"[negotiation] Inbound webhook: stored reply on case {case_id} owned by root {target.owner_root} (msg {entry['id']})");
    return WebhookResult(
        received=True, case_id=case_id, message_id=str(entry["id"]),
        status="stored", note="Inbound reply attached to case"
    );
}
