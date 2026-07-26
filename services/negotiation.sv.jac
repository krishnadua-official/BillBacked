"""Fictional outbound-call negotiation sandbox.

This service deliberately uses a demo case rather than uploaded bill data.
Real patient information must not cross into telephony until the required
privacy, consent, retention, and vendor agreements are in place.
"""

import json;
import os;
import from urllib.error { HTTPError, URLError }
import from urllib.request { Request, urlopen }


glob ELEVENLABS_OUTBOUND_CALL_URL: str = (
    "https://api.elevenlabs.io/v1/convai/twilio/outbound-call"
);


obj NegotiationCase {
    has is_demo: bool = True;
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
    return f"""
You are Ava, BillBacked's calm and precise AI bill-negotiation assistant.
This is a role-play call using fictional data. The person who answers is
pretending to be a billing representative for {case_data.provider_name}.

Immediately disclose that you are an AI assistant, that this is a fictional
test negotiation, and that the call may be processed by service providers.

CASE
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
- Never claim this fictional case is a real patient account.
- Never invent facts, codes, authorizations, laws, or supporting documents.
- Do not provide payment-card, bank, Social Security, or medical information.
- Do not threaten, misrepresent legal authority, or imply the reference amount
  legally binds the provider.
- If asked for information not listed above, say it is unavailable in the test.
- Keep spoken responses concise and allow interruptions.
- End politely after an agreement, an impasse, or a request to stop.
""".strip();
}


def _build_first_message(case_data: NegotiationCase) -> str {
    return (
        "Hello, I’m Ava, a BillBacked AI assistant running a fictional bill "
        "negotiation test. This call may be processed by service providers. "
        f"I’m calling about test invoice {case_data.invoice_number} for "
        f"{case_data.patient_name}. Could you confirm the current balance?"
    );
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
        "conversation_initiation_client_data": {
            "type": "conversation_initiation_client_data",
            "conversation_config_override": {
                "agent": {
                    "prompt": {
                        "prompt": _build_negotiation_prompt(case_data)
                    },
                    "first_message": _build_first_message(case_data),
                    "language": "en",
                }
            },
            "dynamic_variables": {
                "is_demo": True,
                "patient_name": case_data.patient_name,
                "provider_name": case_data.provider_name,
                "invoice_number": case_data.invoice_number,
                "original_balance": case_data.original_balance,
                "reference_amount": case_data.reference_amount,
                "target_amount": case_data.target_amount,
                "maximum_authorized_amount": case_data.maximum_authorized_amount,
                "disputed_items": "; ".join(case_data.disputed_items),
            },
            "user_id": "billbacked-fictional-demo",
        },
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


def:protect start_demo_negotiation_call(to_number: str) -> NegotiationCallResult {
    try {
        destination: str = _normalize_destination_number(to_number);
    } except ValueError as e {
        return NegotiationCallResult(
            status="invalid_destination",
            message=str(e)
        );
    }

    api_key: str | None = os.getenv("ELEVENLABS_API_KEY");
    agent_id: str | None = os.getenv("ELEVENLABS_AGENT_ID");
    phone_number_id: str | None = os.getenv("ELEVENLABS_PHONE_NUMBER_ID");
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
    if missing {
        return NegotiationCallResult(
            status="configuration_required",
            message="Missing server configuration: " + ", ".join(missing)
        );
    }

    case_data: NegotiationCase = get_demo_negotiation_case();
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
            str(provider_message)
            if provider_message
            else (
                "Your phone should ring shortly."
                if success
                else "ElevenLabs did not start the call."
            )
        ),
        conversation_id=str(conversation_value) if conversation_value else "",
        provider_call_id=str(call_value) if call_value else ""
    );
}
