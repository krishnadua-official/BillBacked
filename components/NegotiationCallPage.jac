"""Fictional self-call sandbox for the ElevenLabs negotiation agent."""

import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    CallOutgoing01Icon, CheckmarkCircle01Icon, Loading03Icon
}
import from ".ui.button" { Button }
import from ".ui.badge" { Badge }
import from ".ui.field" { Field, FieldLabel }
import from ".ui.input" { Input }
sv import from ..services.negotiation {
    NegotiationCase, NegotiationCallResult,
    get_demo_negotiation_case, start_demo_negotiation_call
}


def _format_amount(value: float) -> str {
    return f"${value:,.0f}";
}


def:pub NegotiationCallPage() -> JsxElement {
    has case_data: NegotiationCase | None = None,
        phone_number: str = "",
        result: NegotiationCallResult | None = None,
        error_message: str = "",
        is_calling: bool = False;

    async can with entry {
        try {
            case_data = await get_demo_negotiation_case();
        } except Exception {
            error_message = "The fictional test case could not be loaded.";
        }
    }

    def handle_phone_change(e: ChangeEvent) {
        phone_number = e.target.value;
    }

    async def request_call -> None {
        error_message = "";
        result = None;
        if not phone_number {
            error_message = "Enter the phone number that should receive the test call.";
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
            error_message = "The test call could not be started. Please try again.";
        }
        is_calling = False;
    }

    def handle_submit(e: FormEvent) {
        e.preventDefault();
        request_call();
    }

    return <div className="mx-auto grid w-full max-w-7xl flex-1 gap-10 px-4 py-10 text-gray-1000 sm:px-8 sm:py-14 lg:grid-cols-[minmax(0,0.9fr)_minmax(340px,0.72fr)] lg:gap-14">
        <div className="min-w-0">
            <div className="flex items-center gap-2 text-sm text-blue-700">
                <HugeiconsIcon
                    icon={CallOutgoing01Icon}
                    strokeWidth={2}
                    className="size-4"
                />
                ElevenLabs outbound test
            </div>
            <h2 className="mt-5 max-w-xl text-3xl font-medium tracking-[-0.05em] sm:text-4xl">
                Let the agent call you.
            </h2>
            <p className="mt-4 max-w-xl text-base leading-7 text-gray-900">
                Answer as if you work in hospital billing. Ava will disclose that
                she is an AI and negotiate a completely fictional invoice with you.
            </p>

            <section
                className="mt-10 rounded-[20px] bg-canvas p-5 sm:p-6"
                aria-labelledby="call-destination-title"
            >
                <h3
                    id="call-destination-title"
                    className="text-base font-medium text-gray-1000"
                >
                    Where should Ava call?
                </h3>
                <p className="mt-2 text-sm leading-6 text-gray-900">
                    Use a phone verified in your Twilio trial. Include the country
                    code, such as +34 for Spain.
                </p>
                <form className="mt-6 flex flex-col gap-4" onSubmit={handle_submit}>
                    <Field>
                        <FieldLabel htmlFor="test-phone-number">
                            Your phone number
                        </FieldLabel>
                        <Input
                            id="test-phone-number"
                            type="tel"
                            inputMode="tel"
                            autoComplete="tel"
                            placeholder="+34600111222"
                            value={phone_number}
                            onChange={handle_phone_change}
                            disabled={is_calling}
                            className="h-11 rounded-[14px] bg-background px-4 shadow-none"
                        />
                    </Field>
                    {if error_message {
                        <p
                            key="call-error"
                            className="rounded-2xl bg-destructive/5 p-4 text-sm leading-6 text-destructive"
                            role="alert"
                        >
                            {error_message}
                        </p>
                    }}
                    {if result is not None and result.success {
                        <div
                            key="call-success"
                            className="flex gap-3 rounded-2xl bg-blue-100 p-4 text-sm leading-6 text-gray-1000"
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
                        size="lg"
                        disabled={is_calling or case_data is None}
                        className="w-full sm:w-fit"
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
                        {"Starting call…" if is_calling else "Call me for the test"}
                    </Button>
                </form>
            </section>

            <div className="mt-6 rounded-2xl border border-border p-5">
                <p className="text-sm font-medium text-gray-1000">
                    How to play the billing representative
                </p>
                <ol className="mt-3 list-decimal space-y-2 pl-5 text-sm leading-6 text-gray-900">
                    <li>Confirm the fictional balance when Ava asks.</li>
                    <li>Defend the facility fee, then offer a small reduction.</li>
                    <li>Make one offer above $4,200 and listen for Ava to refuse it.</li>
                    <li>Finish with an offer of $4,000 to test an authorized agreement.</li>
                </ol>
            </div>
        </div>

        <aside className="min-w-0 lg:pt-7">
            <div className="rounded-[20px] bg-background-200 p-5 sm:p-6">
                <div className="flex items-center justify-between gap-4">
                    <div>
                        <p className="text-xs font-medium uppercase tracking-[0.14em] text-blue-700">
                            Fictional case
                        </p>
                        <h3 className="mt-2 text-xl font-medium tracking-[-0.04em]">
                            {case_data.provider_name if case_data is not None else "Loading…"}
                        </h3>
                    </div>
                    <Badge variant="secondary">
                        Demo only
                    </Badge>
                </div>

                {if case_data is not None {
                    <div key="demo-case-details" className="mt-7">
                        <dl className="grid grid-cols-2 gap-x-5 gap-y-6">
                            <div>
                                <dt className="text-xs text-gray-700">Patient</dt>
                                <dd className="mt-1 text-sm font-medium">
                                    {case_data.patient_name}
                                </dd>
                            </div>
                            <div>
                                <dt className="text-xs text-gray-700">Invoice</dt>
                                <dd className="mt-1 text-sm font-medium">
                                    {case_data.invoice_number}
                                </dd>
                            </div>
                            <div>
                                <dt className="text-xs text-gray-700">Original balance</dt>
                                <dd className="mt-1 text-sm font-medium">
                                    {_format_amount(case_data.original_balance)}
                                </dd>
                            </div>
                            <div>
                                <dt className="text-xs text-gray-700">Reference amount</dt>
                                <dd className="mt-1 text-sm font-medium">
                                    {_format_amount(case_data.reference_amount)}
                                </dd>
                            </div>
                            <div>
                                <dt className="text-xs text-gray-700">Target</dt>
                                <dd className="mt-1 text-sm font-medium text-blue-700">
                                    {_format_amount(case_data.target_amount)}
                                </dd>
                            </div>
                            <div>
                                <dt className="text-xs text-gray-700">Hard ceiling</dt>
                                <dd className="mt-1 text-sm font-medium">
                                    {_format_amount(case_data.maximum_authorized_amount)}
                                </dd>
                            </div>
                        </dl>

                        <div className="mt-7 border-t border-border pt-6">
                            <p className="text-xs text-gray-700">Items to challenge</p>
                            <ul className="mt-3 space-y-2 text-sm leading-6 text-gray-900">
                                {for item in case_data.disputed_items {
                                    <li key={item} className="flex gap-2">
                                        <span className="mt-2 size-1.5 shrink-0 rounded-full bg-blue-700" />
                                        <span>{item}</span>
                                    </li>
                                }}
                            </ul>
                        </div>
                    </div>
                }}
            </div>

            <p className="mt-5 text-xs leading-5 text-gray-700">
                This sandbox never sends an uploaded bill. Call recording is off.
                ElevenLabs and Twilio still process phone and call metadata to
                connect the test.
            </p>
        </aside>
    </div>;
}
