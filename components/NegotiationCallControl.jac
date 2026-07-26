"""Compact ElevenLabs call action used by the final audit step."""

import from react { useEffect }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    CallOutgoing01Icon, CheckmarkCircle01Icon, Loading03Icon
}
import from ".ui.button" { Button }
sv import from ..services.negotiation {
    NegotiationCallResult, get_demo_negotiation_call_status,
    start_demo_negotiation_call
}


def:pub NegotiationCallControl(
    is_available: bool = False
) -> JsxElement {
    has result: NegotiationCallResult | None = None,
        error_message: str = "",
        is_calling: bool = False;

    conversation_id: str = (
        result.conversation_id if result is not None else ""
    );
    call_status: str = result.status if result is not None else "";
    call_is_active: bool = call_status in [
        "calling", "in_progress", "processing"
    ];
    call_is_complete: bool = call_status == "completed";
    active_status_title: str = "Calling provider";
    if call_status == "in_progress" {
        active_status_title = "Negotiation in progress";
    } elif call_status == "processing" {
        active_status_title = "Preparing negotiation result";
    }

    async def request_call -> None {
        error_message = "";
        result = None;
        is_calling = True;
        try {
            call_result: NegotiationCallResult = (
                await start_demo_negotiation_call()
            );
            result = call_result;
            if not call_result.success {
                error_message = call_result.message;
            }
        } except Exception {
            error_message = "The negotiation call could not be started. Please try again.";
        }
        is_calling = False;
    }

    async def refresh_call_status {
        if not conversation_id {
            return;
        }
        try {
            status_result: NegotiationCallResult = (
                await get_demo_negotiation_call_status(conversation_id)
            );
            result = status_result;
            if not status_result.success {
                error_message = status_result.message;
            }
        } except Exception {
            error_message = "The live negotiation status could not be refreshed.";
        }
    }

    def handle_call {
        if is_available {
            request_call();
        }
    }

    useEffect(
        lambda {
            if not call_is_active or not conversation_id {
                return lambda {};
            }
            refresh_call_status();
            poll_timer = setInterval(
                lambda { refresh_call_status(); },
                2000
            );
            return lambda { clearInterval(poll_timer); };
        },
        [conversation_id, call_status]
    );

    return <div
        className="mt-4 max-w-md rounded-2xl bg-background-200 p-4"
    >
        <p className="text-xs leading-5 text-gray-700">
            The agent will call the verified test destination with a fictional negotiation case. Your uploaded bill is never sent.
        </p>

        {if error_message {
            <p
                key="call-error"
                className="mt-3 text-xs leading-5 text-destructive"
                role="alert"
            >
                {error_message}
            </p>
        }}
        {if call_is_active and result is not None {
            <div
                key="call-active"
                className="mt-4 flex items-start gap-3 rounded-xl bg-blue-100 p-3 text-gray-1000"
                role="status"
                aria-live="polite"
            >
                <HugeiconsIcon
                    icon={Loading03Icon}
                    strokeWidth={2}
                    className="mt-0.5 size-4 shrink-0 animate-spin text-blue-700"
                />
                <div>
                    <p className="text-xs font-medium">
                        {active_status_title}
                    </p>
                    <p className="mt-1 text-xs leading-5 text-gray-900">
                        {result.message}
                    </p>
                </div>
            </div>
        } elif call_is_complete and result is not None {
            <div
                key="call-complete"
                className="mt-4 flex items-start gap-3 rounded-xl bg-blue-100 p-3 text-gray-1000"
                role="status"
                aria-live="polite"
            >
                <HugeiconsIcon
                    icon={CheckmarkCircle01Icon}
                    strokeWidth={2}
                    className="mt-0.5 size-4 shrink-0 text-blue-700"
                />
                <div>
                    <p className="text-xs font-medium">
                        Negotiation call finished
                    </p>
                    <p className="mt-1 text-xs leading-5 text-gray-900">
                        The call result is ready for the next audit step.
                    </p>
                </div>
            </div>
        }}

        <Button
            type="button"
            variant="primary"
            disabled={
                is_calling or call_is_active or call_is_complete
                or not is_available
            }
            className="mt-4 w-full sm:w-fit"
            onClick={handle_call}
        >
            {if is_calling or call_is_active {
                <HugeiconsIcon
                    key="call-spinner"
                    icon={Loading03Icon}
                    strokeWidth={2}
                    className="size-4 animate-spin"
                />
            } elif call_is_complete {
                <HugeiconsIcon
                    key="call-complete-icon"
                    icon={CheckmarkCircle01Icon}
                    strokeWidth={2}
                    className="size-4"
                />
            } else {
                <HugeiconsIcon
                    key="call-icon"
                    icon={CallOutgoing01Icon}
                    strokeWidth={2}
                    className="size-4"
                />
            }}
            {
                "Starting call…"
                if is_calling
                else (
                    active_status_title
                    if call_is_active
                    else (
                        "Call complete"
                        if call_is_complete
                        else (
                            "Try call again"
                            if result is not None and not result.success
                            else "Start negotiation call"
                        )
                    )
                )
            }
        </Button>
        {if not is_available {
            <p key="call-locked" className="mt-3 text-xs leading-5 text-gray-700">
                Available after the bill audit is ready for approval.
            </p>
        }}
    </div>;
}
