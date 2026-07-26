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
import requests;
import from datetime { datetime, timezone }


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

    def to_view -> CaseView {
        return CaseView(
            id=jid(self),
            provider_name=self.provider_name,
            provider_email=self.provider_email,
            patient_name=self.patient_name,
            status=self.status,
            original_total=self.original_total,
            disputed_total=self.disputed_total,
            message_count=len([self -->][?:Message]),
            created_at=self.created_at,
            updated_at=self.updated_at
        );
    }

    def to_detail_view -> CaseDetailView {
        items = [i.to_view() for i in [self -->][?:LineItem]];
        msgs = [m.to_view() for m in [self -->][?:Message]];
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

def _send_email(to_addr: str, subject: str, body: str) -> bool {
    api_key = os.environ.get("RESEND_API_KEY", "");
    if not api_key {
        print("[negotiation] RESEND_API_KEY not set -- skipping actual send.");
        return False;
    }
    payload: dict[str, any] = {
        "from": "BillBacked <onboarding@resend.dev>",
        "to": [to_addr],
        "subject": subject,
        "text": body
    };
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

        draft = _compose_dispute_email(bundle);
        sent_ok = _send_email(TEST_RECIPIENT, draft.subject, draft.body);

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
        sent_ok = _send_email(TEST_RECIPIENT, counter.subject, counter.body);
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
