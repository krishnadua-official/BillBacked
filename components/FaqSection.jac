"""Compact, accessible answers to common BillBacked questions."""

import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" { ArrowDown01Icon }


def:pub FaqSection() -> JsxElement {
    return <section
        className="bg-background px-4 py-20 sm:px-6 sm:py-24"
        aria-labelledby="faq-title"
    >
        <div className="mx-auto w-full max-w-6xl">
            <div className="max-w-2xl">
                <h2
                    id="faq-title"
                    className="text-balance text-3xl font-medium tracking-[-0.04em] sm:text-4xl"
                >
                    Common questions.
                </h2>
                <p className="mt-3 text-base leading-7 text-gray-900">
                    What to expect before BillBacked reviews your Medicare bill.
                </p>
            </div>

            <div className="mt-10 border-b border-border/70">
                <details className="group border-t border-border/70">
                    <summary className="flex cursor-pointer list-none items-center justify-between gap-6 py-5 text-lg font-medium tracking-[-0.02em] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-blue-700 [&::-webkit-details-marker]:hidden">
                        <span>What does BillBacked check on my bill?</span>
                        <HugeiconsIcon
                            icon={ArrowDown01Icon}
                            size={18}
                            strokeWidth={2}
                            className="shrink-0 transition-transform duration-200 group-open:rotate-180"
                            aria-hidden="true"
                        />
                    </summary>
                    <p className="max-w-3xl pb-5 pr-10 text-base leading-7 text-gray-900">
                        BillBacked reads each charge, code, provider, and date to flag duplicate items, coding issues, and prices that may not match Medicare benchmarks.
                    </p>
                </details>

                <details className="group border-t border-border/70">
                    <summary className="flex cursor-pointer list-none items-center justify-between gap-6 py-5 text-lg font-medium tracking-[-0.02em] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-blue-700 [&::-webkit-details-marker]:hidden">
                        <span>How is the true cost estimated?</span>
                        <HugeiconsIcon
                            icon={ArrowDown01Icon}
                            size={18}
                            strokeWidth={2}
                            className="shrink-0 transition-transform duration-200 group-open:rotate-180"
                            aria-hidden="true"
                        />
                    </summary>
                    <p className="max-w-3xl pb-5 pr-10 text-base leading-7 text-gray-900">
                        Each line item is compared with Medicare pricing and available historical charge data to produce a transparent estimate for you to review.
                    </p>
                </details>

                <details className="group border-t border-border/70">
                    <summary className="flex cursor-pointer list-none items-center justify-between gap-6 py-5 text-lg font-medium tracking-[-0.02em] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-blue-700 [&::-webkit-details-marker]:hidden">
                        <span>Will BillBacked contact the provider without me?</span>
                        <HugeiconsIcon
                            icon={ArrowDown01Icon}
                            size={18}
                            strokeWidth={2}
                            className="shrink-0 transition-transform duration-200 group-open:rotate-180"
                            aria-hidden="true"
                        />
                    </summary>
                    <p className="max-w-3xl pb-5 pr-10 text-base leading-7 text-gray-900">
                        No. You review and approve the adjusted bill and outreach draft before any email or call is made.
                    </p>
                </details>

                <details className="group border-t border-border/70">
                    <summary className="flex cursor-pointer list-none items-center justify-between gap-6 py-5 text-lg font-medium tracking-[-0.02em] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-blue-700 [&::-webkit-details-marker]:hidden">
                        <span>Can BillBacked guarantee a lower bill?</span>
                        <HugeiconsIcon
                            icon={ArrowDown01Icon}
                            size={18}
                            strokeWidth={2}
                            className="shrink-0 transition-transform duration-200 group-open:rotate-180"
                            aria-hidden="true"
                        />
                    </summary>
                    <p className="max-w-3xl pb-5 pr-10 text-base leading-7 text-gray-900">
                        No outcome is guaranteed. BillBacked helps identify likely errors and prepares a stronger negotiation using the evidence in your bill.
                    </p>
                </details>

                <details className="group border-t border-border/70">
                    <summary className="flex cursor-pointer list-none items-center justify-between gap-6 py-5 text-lg font-medium tracking-[-0.02em] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-blue-700 [&::-webkit-details-marker]:hidden">
                        <span>Is my Medicare bill private?</span>
                        <HugeiconsIcon
                            icon={ArrowDown01Icon}
                            size={18}
                            strokeWidth={2}
                            className="shrink-0 transition-transform duration-200 group-open:rotate-180"
                            aria-hidden="true"
                        />
                    </summary>
                    <p className="max-w-3xl pb-5 pr-10 text-base leading-7 text-gray-900">
                        Your audit is tied to your private account. In this prototype, the selected file remains in the current browser session.
                    </p>
                </details>
            </div>
        </div>
    </section>;
}
