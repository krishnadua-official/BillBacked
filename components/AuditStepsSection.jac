"""Homepage overview of the Medicare bill audit flow."""


def:pub AuditStepsSection() -> JsxElement {
    return <section
        className="bg-canvas px-4 py-20 sm:px-6 sm:py-24 lg:py-28"
        aria-labelledby="audit-steps-title"
    >
        <div className="mx-auto w-full max-w-7xl">
            <div className="text-center">
                <h2
                    id="audit-steps-title"
                    className="text-balance text-4xl font-medium tracking-[-0.05em] sm:text-5xl"
                >
                    From bill to negotiated price.
                </h2>
                <p className="mx-auto mt-4 max-w-2xl text-balance text-lg leading-8 text-gray-900">
                    Follow the agent as it audits the charges, contacts the provider, and negotiates on your behalf.
                </p>
            </div>

            <ol className="mx-auto mt-12 grid max-w-6xl overflow-hidden rounded-[20px] border border-border/70 bg-background md:grid-cols-3 md:divide-x md:divide-border/70">
                <li className="flex min-h-[300px] flex-col justify-between border-b border-border/70 p-6 sm:p-8 md:border-b-0">
                    <span
                        className="text-5xl font-medium tracking-[-0.04em] text-gray-600"
                        aria-hidden="true"
                    >
                        1
                    </span>
                    <div>
                        <h3 className="text-xl font-medium tracking-[-0.02em]">
                            Upload your Medicare bill
                        </h3>
                        <p className="mt-3 text-sm leading-6 text-gray-900">
                            Add a PDF or clear photo. The agent reads every charge, code, provider, and service date.
                        </p>
                    </div>
                </li>
                <li className="flex min-h-[300px] flex-col justify-between border-b border-border/70 p-6 sm:p-8 md:border-b-0">
                    <span
                        className="text-5xl font-medium tracking-[-0.04em] text-gray-600"
                        aria-hidden="true"
                    >
                        2
                    </span>
                    <div>
                        <h3 className="text-xl font-medium tracking-[-0.02em]">
                            Build the negotiation case
                        </h3>
                        <p className="mt-3 text-sm leading-6 text-gray-900">
                            Each line item is checked against Medicare pricing to flag errors and calculate a fair target.
                        </p>
                    </div>
                </li>
                <li className="flex min-h-[300px] flex-col justify-between p-6 sm:p-8">
                    <span
                        className="text-5xl font-medium tracking-[-0.04em] text-gray-600"
                        aria-hidden="true"
                    >
                        3
                    </span>
                    <div>
                        <h3 className="text-xl font-medium tracking-[-0.02em]">
                            The agent negotiates. You approve.
                        </h3>
                        <p className="mt-3 text-sm leading-6 text-gray-900">
                            BillBacked emails or calls the provider, handles the back-and-forth, and brings the final offer to you.
                        </p>
                    </div>
                </li>
            </ol>
        </div>
    </section>;
}
