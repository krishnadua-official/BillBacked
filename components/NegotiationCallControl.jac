"""Compact ElevenLabs call action used by the final audit step."""

import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    CallOutgoing01Icon, CheckmarkCircle01Icon, Loading03Icon
}
import from ".ui.button" { Button }
import from ".ui.field" { Field, FieldLabel }
import from ".ui.input" { Input }
sv import from ..services.negotiation {
    NegotiationCallResult, start_demo_negotiation_call
}


def:pub NegotiationCallControl(
    is_available: bool = False
) -> JsxElement {
    has phone_number: str = "",
        result: NegotiationCallResult | None = None,
        error_message: str = "",
        is_calling: bool = False;

    def handle_phone_change(e: ChangeEvent) {
        phone_number = e.target.value;
    }

    async def request_call -> None {
        error_message = "";
        result = None;
        if not phone_number {
            error_message = "Enter the phone number that should receive the call.";
            return;
        }

        is_calling = True;
        try {
            call_result: NegotiationCallResult = (
                await start_demo_negotiation_call(phone_number)
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

    def handle_submit(e: FormEvent) {
        e.preventDefault();
        if is_available {
            request_call();
        }
    }

    return <form
        className="mt-4 max-w-md rounded-2xl bg-background-200 p-4"
        onSubmit={handle_submit}
    >
        <p className="text-xs leading-5 text-gray-700">
            This prototype call uses a fictional negotiation case and never sends the uploaded bill.
        </p>
        <Field className="mt-4">
            <FieldLabel htmlFor="negotiation-phone-number">
                Phone number
            </FieldLabel>
            <Input
                id="negotiation-phone-number"
                type="tel"
                inputMode="tel"
                autoComplete="tel"
                placeholder="+34600111222"
                value={phone_number}
                onChange={handle_phone_change}
                disabled={is_calling or not is_available}
                className="h-10 rounded-xl bg-background px-3 shadow-none"
            />
        </Field>

        {if error_message {
            <p
                key="call-error"
                className="mt-3 text-xs leading-5 text-destructive"
                role="alert"
            >
                {error_message}
            </p>
        }}
        {if result is not None and result.success {
            <div
                key="call-success"
                className="mt-3 flex gap-2 text-xs leading-5 text-gray-1000"
                role="status"
            >
                <HugeiconsIcon
                    icon={CheckmarkCircle01Icon}
                    strokeWidth={2}
                    className="mt-0.5 size-4 shrink-0 text-blue-700"
                />
                <span>{result.message}</span>
            </div>
        }}

        <Button
            type="submit"
            variant="primary"
            disabled={is_calling or not is_available}
            className="mt-4 w-full sm:w-fit"
        >
            {if is_calling {
                <HugeiconsIcon
                    key="call-spinner"
                    icon={Loading03Icon}
                    strokeWidth={2}
                    className="size-4 animate-spin"
                />
            } else {
                <HugeiconsIcon
                    key="call-icon"
                    icon={CallOutgoing01Icon}
                    strokeWidth={2}
                    className="size-4"
                />
            }}
            {"Starting call…" if is_calling else "Start negotiation call"}
        </Button>
        {if not is_available {
            <p key="call-locked" className="mt-3 text-xs leading-5 text-gray-700">
                Available after the bill audit is ready for approval.
            </p>
        }}
    </form>;
}
