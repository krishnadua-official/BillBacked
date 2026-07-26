"""Case-aware outbound negotiation calls through ElevenLabs and Twilio.

The service is the single boundary that converts an approved audit into the
minimum structured context needed for a call. Original uploaded files never
leave BillBacked through this integration.
"""

import json;
import os;
import from urllib.error { HTTPError, URLError }
import from urllib.request { Request, urlopen }
import from services.discrepancy { BillAudit, LineDiscrepancy }
import from services.extractor { StructuredDocument }


glob ELEVENLABS_OUTBOUND_CALL_URL: str = (
    "https://api.elevenlabs.io/v1/convai/twilio/outbound-call"
);
glob ELEVENLABS_CONVERSATION_URL: str = (
    "https://api.elevenlabs.io/v1/convai/conversations"
);


obj NegotiationCase {
    has is_demo: bool = True;
    has case_id: str = "";
    has user_name: str = "";
    has patient_name: str = "";
    has provider_name: str = "";
    has invoice_number: str = "";
    has original_balance: float = 0.0;
    has reference_amount: float = 0.0;
    has target_amount: float = 0.0;
    has maximum_authorized_amount: float = 0.0;
    has disputed_items: list[str] = [];
}


obj NegotiationCallResult {
    has success: bool = False;
    has status: str = "";
    has message: str = "";
    has conversation_id: str = "";
    has provider_call_id: str = "";
}


def:protect get_demo_negotiation_case() -> NegotiationCase {
    return NegotiationCase(
        case_id="demo-bb-1042",
        user_name="Alex Morgan",
        patient_name="Alex Morgan",
        provider_name="Example General Hospital",
        invoice_number="BB-1042",
        original_balance=8400.0,
        reference_amount=3100.0,
        target_amount=3500.0,
        maximum_authorized_amount=4200.0,
        disputed_items=[
            "$1,500 facility fee",
            "$850 suspected duplicate imaging charge",
        ]
    );
}


def _disputed_item_summary(discrepancy: LineDiscrepancy) -> str {
    identity: str = " ".join([
        value for value in [
            discrepancy.hcpcs.strip(),
            discrepancy.description.strip()
        ] if value
    ]);
    summary: str = identity if identity else "Unlabeled charge";
    summary = (
        summary
        + f": billed {_format_amount(discrepancy.billed_amount)}"
    );
    if discrepancy.benchmark_amount is not None {
        summary = (
            summary
            + " vs Medicare reference "
            + _format_amount(discrepancy.benchmark_amount as float)
        );
    }
    if discrepancy.flag_reason {
        summary = summary + ". " + discrepancy.flag_reason.strip();
    }
    return summary;
}


def _build_case_from_audit(
    user_name: str,
    documents: list[StructuredDocument],
    audit: BillAudit
) -> NegotiationCase {
    case_id: str = "";
    patient_name: str = "";
    provider_name: str = "";
    invoice_number: str = "";
    for document in documents {
        if not case_id and document.case_id {
            case_id = document.case_id.strip();
        }
        if not patient_name and document.patient_name {
            patient_name = document.patient_name.strip();
        }
        if not provider_name and document.provider_name {
            provider_name = document.provider_name.strip();
        }
        if not invoice_number and document.claim_number {
            invoice_number = document.claim_number.strip();
        }
    }
    resolved_user_name: str = user_name.strip() or patient_name;
    if not invoice_number {
        invoice_number = case_id;
    }
    disputed_items: list[str] = [
        _disputed_item_summary(discrepancy)
        for discrepancy in audit.discrepancies
        if discrepancy.flagged
    ];
    return NegotiationCase(
        is_demo=False,
        case_id=case_id,
        user_name=resolved_user_name,
        patient_name=patient_name or resolved_user_name,
        provider_name=provider_name,
        invoice_number=invoice_number,
        original_balance=audit.total_billed,
        reference_amount=audit.total_benchmark,
        target_amount=audit.total_benchmark,
        maximum_authorized_amount=audit.total_benchmark,
        disputed_items=disputed_items
    );
}


def _normalize_destination_number(value: str) -> str {
    normalized: str = value.strip();
    normalized = normalized.replace(" ", "");
    normalized = normalized.replace("-", "");
    normalized = normalized.replace("(", "");
    normalized = normalized.replace(")", "");
    normalized = normalized.replace(".", "");
    if not normalized.startswith("+") {
        raise ValueError("Use international E.164 format, for example +34600111222.");
    }
    digits: str = normalized[1:];
    if not digits.isdigit() or len(digits) < 8 or len(digits) > 15 {
        raise ValueError("Enter a valid international phone number.");
    }
    return normalized;
}


def _format_amount(value: float) -> str {
    return f"${value:,.2f}";
}


def _build_negotiation_prompt(case_data: NegotiationCase) -> str {
    disputes: str = "; ".join(case_data.disputed_items);
    call_context: str = (
        "This is a role-play call using fictional data. The person who answers "
        "is pretending to be the provider's billing representative."
        if case_data.is_demo
        else (
            "This is provider outreach for a reviewed BillBacked audit. "
            "Use only the approved case facts below."
        )
    );
    truthfulness_rule: str = (
        "- Never claim this fictional case is a real patient account."
        if case_data.is_demo
        else (
            "- Never claim to be the patient, the provider, an attorney, "
            "or a government representative."
        )
    );
    return f"""
You are BillBacked's calm and precise AI bill-negotiation assistant. Use the
name, voice, language, and opening greeting configured in ElevenLabs.
{call_context}

Immediately disclose that you are an AI assistant calling for BillBacked and
that the call may be processed by service providers.

CASE
- BillBacked member: {case_data.user_name}
- Patient: {case_data.patient_name}
- Provider: {case_data.provider_name}
- Invoice: {case_data.invoice_number}
- Original balance: {_format_amount(case_data.original_balance)}
- Reference amount: {_format_amount(case_data.reference_amount)}
- Target resolution: {_format_amount(case_data.target_amount)}
- Maximum authorized amount: {_format_amount(case_data.maximum_authorized_amount)}
- Disputed items: {disputes}

GOAL
Confirm the invoice, ask for explanations of the disputed items, request that
unsupported or duplicated charges be removed, and negotiate toward the target.
You may accept a final amount at or below the maximum authorized amount only
after repeating the amount and all material conditions. Reject offers above the
maximum and request escalation or a callback instead.

GUARDRAILS
{truthfulness_rule}
- Never invent facts, codes, authorizations, laws, or supporting documents.
- Do not provide payment-card, bank, Social Security, or medical information.
- Do not threaten, misrepresent legal authority, or imply the reference amount
  legally binds the provider.
- If asked for information not listed above, say it is unavailable in the test.
- Keep spoken responses concise and allow interruptions.
- End politely after an agreement, an impasse, or a request to stop.
""".strip();
}


def _build_conversation_initiation_data(
    case_data: NegotiationCase
) -> dict[str, any] {
    return {
        "type": "conversation_initiation_client_data",
        "conversation_config_override": {
            "agent": {
                "prompt": {
                    "prompt": _build_negotiation_prompt(case_data)
                }
            }
        },
        "dynamic_variables": {
            "is_demo": case_data.is_demo,
            "case_id": case_data.case_id,
            "user_name": case_data.user_name,
            "patient_name": case_data.patient_name,
            "provider_name": case_data.provider_name,
            "invoice_number": case_data.invoice_number,
            "original_balance": case_data.original_balance,
            "original_balance_display": (
                _format_amount(case_data.original_balance)
            ),
            "reference_amount": case_data.reference_amount,
            "reference_amount_display": (
                _format_amount(case_data.reference_amount)
            ),
            "target_amount": case_data.target_amount,
            "target_amount_display": _format_amount(case_data.target_amount),
            "maximum_authorized_amount": case_data.maximum_authorized_amount,
            "maximum_authorized_amount_display": (
                _format_amount(case_data.maximum_authorized_amount)
            ),
            "disputed_items_summary": "; ".join(case_data.disputed_items),
        },
        "user_id": "billbacked-audit",
    };
}


def _post_outbound_call(
    api_key: str,
    agent_id: str,
    phone_number_id: str,
    destination: str,
    case_data: NegotiationCase
) -> dict[str, any] {
    payload: dict[str, any] = {
        "agent_id": agent_id,
        "agent_phone_number_id": phone_number_id,
        "to_number": destination,
        "call_recording_enabled": False,
        "conversation_initiation_client_data": (
            _build_conversation_initiation_data(case_data)
        ),
    };
    request_body: bytes = json.dumps(payload).encode("utf-8");
    request = Request(
        ELEVENLABS_OUTBOUND_CALL_URL,
        data=request_body,
        headers={
            "Content-Type": "application/json",
            "xi-api-key": api_key,
        },
        method="POST"
    );
    response = urlopen(request, timeout=20);
    response_body: bytes = response.read();
    response.close();
    parsed = json.loads(response_body.decode("utf-8"));
    return parsed as dict[str, any];
}


def _get_conversation(
    api_key: str,
    conversation_id: str
) -> dict[str, any] {
    request = Request(
        f"{ELEVENLABS_CONVERSATION_URL}/{conversation_id}",
        headers={"xi-api-key": api_key},
        method="GET"
    );
    response = urlopen(request, timeout=10);
    response_body: bytes = response.read();
    response.close();
    parsed = json.loads(response_body.decode("utf-8"));
    return parsed as dict[str, any];
}


def _call_status_result(
    conversation_id: str,
    provider_status: str
) -> NegotiationCallResult {
    if provider_status == "initiated" {
        return NegotiationCallResult(
            success=True,
            status="calling",
            message="Calling the provider now…",
            conversation_id=conversation_id
        );
    }
    if provider_status == "in-progress" {
        return NegotiationCallResult(
            success=True,
            status="in_progress",
            message="The agent is negotiating with the provider.",
            conversation_id=conversation_id
        );
    }
    if provider_status == "processing" {
        return NegotiationCallResult(
            success=True,
            status="processing",
            message="The call ended. Preparing the negotiation result…",
            conversation_id=conversation_id
        );
    }
    if provider_status == "done" {
        return NegotiationCallResult(
            success=True,
            status="completed",
            message="The negotiation call finished.",
            conversation_id=conversation_id
        );
    }
    if provider_status == "failed" {
        return NegotiationCallResult(
            status="failed",
            message="The negotiation call failed. You can try again.",
            conversation_id=conversation_id
        );
    }
    return NegotiationCallResult(
        status="provider_error",
        message="ElevenLabs returned an unknown call status.",
        conversation_id=conversation_id
    );
}


def _case_validation_error(case_data: NegotiationCase) -> str {
    missing: list[str] = [];
    if not case_data.user_name {
        missing.append("user name");
    }
    if not case_data.patient_name {
        missing.append("patient name");
    }
    if not case_data.provider_name {
        missing.append("provider name");
    }
    if not case_data.invoice_number {
        missing.append("invoice or claim number");
    }
    if not case_data.disputed_items {
        missing.append("disputed items");
    }
    if missing {
        return "The audit is missing: " + ", ".join(missing) + ".";
    }
    if (
        case_data.original_balance <= 0.0
        or case_data.reference_amount <= 0.0
        or case_data.target_amount <= 0.0
        or case_data.maximum_authorized_amount <= 0.0
    ) {
        return "The audit must include positive bill and negotiation amounts.";
    }
    if case_data.target_amount > case_data.maximum_authorized_amount {
        return "The negotiation target cannot exceed the authorized maximum.";
    }
    return "";
}


def _start_negotiation_call(
    case_data: NegotiationCase
) -> NegotiationCallResult {
    case_error: str = _case_validation_error(case_data);
    if case_error {
        return NegotiationCallResult(
            status="invalid_case",
            message=case_error
        );
    }

    api_key: str | None = os.getenv("ELEVENLABS_API_KEY");
    agent_id: str | None = os.getenv("ELEVENLABS_AGENT_ID");
    phone_number_id: str | None = os.getenv("ELEVENLABS_PHONE_NUMBER_ID");
    destination_value: str | None = os.getenv(
        "TWILIO_VERIFIED_DESTINATION_NUMBER"
    );
    missing: list[str] = [];
    if not api_key {
        missing.append("ELEVENLABS_API_KEY");
    }
    if not agent_id {
        missing.append("ELEVENLABS_AGENT_ID");
    }
    if not phone_number_id {
        missing.append("ELEVENLABS_PHONE_NUMBER_ID");
    }
    if not destination_value {
        missing.append("TWILIO_VERIFIED_DESTINATION_NUMBER");
    }
    if missing {
        return NegotiationCallResult(
            status="configuration_required",
            message="Missing server configuration: " + ", ".join(missing)
        );
    }

    try {
        destination: str = _normalize_destination_number(
            destination_value as str
        );
    } except ValueError as e {
        return NegotiationCallResult(
            status="configuration_required",
            message=(
                "Invalid server configuration for "
                f"TWILIO_VERIFIED_DESTINATION_NUMBER: {str(e)}"
            )
        );
    }

    try {
        response: dict[str, any] = _post_outbound_call(
            api_key as str,
            agent_id as str,
            phone_number_id as str,
            destination,
            case_data
        );
    } except HTTPError as e {
        return NegotiationCallResult(
            status="provider_error",
            message=f"ElevenLabs rejected the call request (HTTP {e.code})."
        );
    } except URLError {
        return NegotiationCallResult(
            status="provider_unavailable",
            message="ElevenLabs could not be reached. Please try again."
        );
    } except Exception {
        return NegotiationCallResult(
            status="provider_error",
            message="The outbound call could not be started."
        );
    }

    success: bool = bool(response.get("success", False));
    provider_message = response.get("message", "");
    conversation_value = response.get("conversation_id", "");
    call_value = response.get("callSid", "");
    return NegotiationCallResult(
        success=success,
        status="calling" if success else "provider_error",
        message=(
            "Calling the provider now…"
            if success
            else (
                str(provider_message)
                if provider_message
                else "ElevenLabs did not start the call."
            )
        ),
        conversation_id=str(conversation_value) if conversation_value else "",
        provider_call_id=str(call_value) if call_value else ""
    );
}


def:protect start_demo_negotiation_call() -> NegotiationCallResult {
    return _start_negotiation_call(get_demo_negotiation_case());
}


def:protect start_audit_negotiation_call(
    user_name: str,
    documents: list[StructuredDocument],
    audit: BillAudit
) -> NegotiationCallResult {
    return _start_negotiation_call(
        _build_case_from_audit(user_name, documents, audit)
    );
}


def:protect get_negotiation_call_status(
    conversation_id: str
) -> NegotiationCallResult {
    if (
        not conversation_id.startswith("conv_")
        or not conversation_id[5:]
        or not conversation_id[5:].isalnum()
    ) {
        return NegotiationCallResult(
            status="invalid_conversation",
            message="The call reference is invalid."
        );
    }

    api_key: str | None = os.getenv("ELEVENLABS_API_KEY");
    if not api_key {
        return NegotiationCallResult(
            status="configuration_required",
            message="Missing server configuration: ELEVENLABS_API_KEY",
            conversation_id=conversation_id
        );
    }

    try {
        response: dict[str, any] = _get_conversation(
            api_key as str,
            conversation_id
        );
    } except HTTPError as e {
        return NegotiationCallResult(
            status="provider_error",
            message=f"ElevenLabs rejected the status request (HTTP {e.code}).",
            conversation_id=conversation_id
        );
    } except URLError {
        return NegotiationCallResult(
            status="provider_unavailable",
            message="The live call status is temporarily unavailable.",
            conversation_id=conversation_id
        );
    } except Exception {
        return NegotiationCallResult(
            status="provider_error",
            message="The live call status could not be loaded.",
            conversation_id=conversation_id
        );
    }

    provider_status_value = response.get("status", "");
    return _call_status_result(
        conversation_id,
        str(provider_status_value) if provider_status_value else ""
    );
}
