"""Compact, accessible answers to common BillBacked questions."""

import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" { ArrowDown01Icon }


def:pub FaqSection() -> JsxElement {
    return <section
        className="bg-background px-4 py-16 sm:px-6 sm:py-20"
        aria-labelledby="faq-title"
    >
        <div className="mx-auto w-full max-w-3xl">
            <h2
                id="faq-title"
                className="text-2xl font-medium tracking-[-0.03em]"
            >
                Frequently asked questions
            </h2>

            <div className="mt-8 border-b border-border/70">
                <details className="group border-t border-border/70">
                    <summary className="flex cursor-pointer list-none items-center justify-between gap-4 py-4 text-base font-medium tracking-[-0.01em] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-blue-700 [&::-webkit-details-marker]:hidden">
                        <span>What does the agent check on my bill?</span>
                        <HugeiconsIcon
                            icon={ArrowDown01Icon}
                            size={16}
                            strokeWidth={2}
                            className="shrink-0 transition-transform duration-200 group-open:rotate-180"
                            aria-hidden="true"
                        />
                    </summary>
                    <p className="max-w-2xl pb-4 pr-8 text-sm leading-6 text-gray-900">
                        It reads each charge, code, provider, and service date to find duplicate items, coding issues, and prices that may not match Medicare benchmarks.
                    </p>
                </details>

                <details className="group border-t border-border/70">
                    <summary className="flex cursor-pointer list-none items-center justify-between gap-4 py-4 text-base font-medium tracking-[-0.01em] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-blue-700 [&::-webkit-details-marker]:hidden">
                        <span>How does the negotiation work?</span>
                        <HugeiconsIcon
                            icon={ArrowDown01Icon}
                            size={16}
                            strokeWidth={2}
                            className="shrink-0 transition-transform duration-200 group-open:rotate-180"
                            aria-hidden="true"
                        />
                    </summary>
                    <p className="max-w-2xl pb-4 pr-8 text-sm leading-6 text-gray-900">
                        The agent turns the audit into an evidence-backed target, contacts the billing office, responds to counteroffers, and keeps negotiating toward a fair amount.
                    </p>
                </details>

                <details className="group border-t border-border/70">
                    <summary className="flex cursor-pointer list-none items-center justify-between gap-4 py-4 text-base font-medium tracking-[-0.01em] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-blue-700 [&::-webkit-details-marker]:hidden">
                        <span>Will the agent call the provider?</span>
                        <HugeiconsIcon
                            icon={ArrowDown01Icon}
                            size={16}
                            strokeWidth={2}
                            className="shrink-0 transition-transform duration-200 group-open:rotate-180"
                            aria-hidden="true"
                        />
                    </summary>
                    <p className="max-w-2xl pb-4 pr-8 text-sm leading-6 text-gray-900">
                        Yes. After you approve the negotiation case, BillBacked can email or call the provider and follow up on your behalf.
                    </p>
                </details>

                <details className="group border-t border-border/70">
                    <summary className="flex cursor-pointer list-none items-center justify-between gap-4 py-4 text-base font-medium tracking-[-0.01em] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-blue-700 [&::-webkit-details-marker]:hidden">
                        <span>Who approves the final amount?</span>
                        <HugeiconsIcon
                            icon={ArrowDown01Icon}
                            size={16}
                            strokeWidth={2}
                            className="shrink-0 transition-transform duration-200 group-open:rotate-180"
                            aria-hidden="true"
                        />
                    </summary>
                    <p className="max-w-2xl pb-4 pr-8 text-sm leading-6 text-gray-900">
                        You do. The agent brings the provider&apos;s final offer back to your dashboard so you can accept it or keep negotiating.
                    </p>
                </details>

                <details className="group border-t border-border/70">
                    <summary className="flex cursor-pointer list-none items-center justify-between gap-4 py-4 text-base font-medium tracking-[-0.01em] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-blue-700 [&::-webkit-details-marker]:hidden">
                        <span>Is a lower bill guaranteed?</span>
                        <HugeiconsIcon
                            icon={ArrowDown01Icon}
                            size={16}
                            strokeWidth={2}
                            className="shrink-0 transition-transform duration-200 group-open:rotate-180"
                            aria-hidden="true"
                        />
                    </summary>
                    <p className="max-w-2xl pb-4 pr-8 text-sm leading-6 text-gray-900">
                        No. Providers make the final decision, but the agent gives each negotiation a documented case, consistent follow-up, and a clear target.
                    </p>
                </details>
            </div>
        </div>
    </section>;
}
