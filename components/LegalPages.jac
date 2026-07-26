"""Plain-language legal notices for the BillBacked prototype.

These pages describe the behavior that exists today. The final callout makes
unresolved launch requirements visible so future contributors do not mistake
prototype copy for a completed production compliance program.
"""

import from ".AppHeader" { PublicHeader }
import from ".SiteFooter" { SiteFooter }


def:pub LegalSection(
    title: str,
    children: JsxElement | list[JsxElement] | None = None
) -> JsxElement {
    return <section>
        <h2 className="text-xl font-medium tracking-[-0.02em] text-gray-1000">
            {title}
        </h2>
        <div className="mt-3 space-y-3 text-sm leading-6 text-gray-900">
            {children}
        </div>
    </section>;
}


def:pub LaunchRequirements() -> JsxElement {
    return <aside
        className="rounded-[16px] bg-background-200 p-5 sm:p-6"
        aria-labelledby="launch-requirements-title"
    >
        <h2
            id="launch-requirements-title"
            className="text-lg font-medium tracking-[-0.02em] text-gray-1000"
        >
            Details required before production launch
        </h2>
        <p className="mt-3 text-sm leading-6 text-gray-900">
            This prototype does not yet identify a legal operator, monitored privacy contact, business address, production hosting providers, retention schedule, governing law, or dispute venue. Those facts must be selected, reviewed by qualified counsel, and published before BillBacked accepts real patient information. Until then, do not upload a real medical bill or other sensitive personal information.
        </p>
    </aside>;
}


def:pub LegalDocument(
    title: str,
    intro: str,
    children: JsxElement | list[JsxElement] | None = None
) -> JsxElement {
    return <div className="flex min-h-svh flex-col bg-background text-gray-1000">
        <PublicHeader show_home={True} />
        <main className="mx-auto w-full max-w-3xl flex-1 px-4 py-16 sm:px-6 sm:py-20">
            <article>
                <p className="text-sm text-gray-700">BillBacked prototype</p>
                <h1 className="mt-3 text-3xl font-medium tracking-[-0.05em] sm:text-4xl">
                    {title}
                </h1>
                <p className="mt-4 max-w-2xl text-base leading-7 text-gray-900">
                    {intro}
                </p>
                <p className="mt-3 text-sm text-gray-700">
                    Effective July 26, 2026
                </p>
                <div className="mt-10 space-y-10 border-t border-border/70 pt-10">
                    {children}
                </div>
            </article>
        </main>
        <SiteFooter />
    </div>;
}


def:pub PrivacyPage() -> JsxElement {
    return <LegalDocument
        title="Privacy Policy"
        intro="This Privacy Policy explains what information the BillBacked Medicare bill-audit prototype uses, why it uses it, and the choices available to you."
    >
        <LegalSection title="1. Scope and prototype status">
            <p>
                This policy applies to the BillBacked website, account flow, dashboard, and Medicare bill-audit prototype. BillBacked is currently a hackathon prototype, not a production healthcare service. The current audit workflow and invoice history include demonstration data.
            </p>
            <p>
                Do not upload a real medical bill, Medicare identifier, Social Security number, payment-card information, or other sensitive personal information while the service remains a prototype.
            </p>
        </LegalSection>

        <LegalSection title="2. Information you provide">
            <p>
                When you create an account, the authentication system processes your email address and password. When you start an audit, you may choose a PDF, PNG, or JPG from your device. A medical bill can contain highly sensitive information, including your name, address, patient or Medicare identifiers, provider details, diagnoses, procedures, service dates, charges, and payment information.
            </p>
            <p>
                BillBacked may also receive information you voluntarily provide through future support, feedback, or provider-communication features. Those features are not active in the current prototype.
            </p>
        </LegalSection>

        <LegalSection title="3. Information created during an audit">
            <p>
                The intended audit process creates structured information from a bill, such as provider, location, service date, procedure or billing code, description, quantity, and charge. It may also create Medicare price comparisons, possible-error flags, fair-cost estimates, audit status, and draft provider messages.
            </p>
            <p>
                In the current prototype, the displayed audit analysis and prior invoice results are demonstration fixtures. They should not be treated as an analysis of a file you select.
            </p>
        </LegalSection>

        <LegalSection title="4. Technical information">
            <p>
                Standard web infrastructure may process basic request information needed to deliver and protect the service, such as IP address, browser type, device type, request time, route, and error logs. The current prototype does not include advertising trackers or sell data for targeted advertising.
            </p>
            <p>
                Authentication may use browser storage or cookies needed to keep you signed in. BillBacked does not currently use those mechanisms for cross-site advertising.
            </p>
        </LegalSection>

        <LegalSection title="5. How information is used">
            <p>BillBacked uses information only as reasonably needed to:</p>
            <ul className="list-disc space-y-2 pl-5">
                <li>create and authenticate your private workspace;</li>
                <li>let you choose a bill and follow the audit workflow;</li>
                <li>extract and organize bill line items in a future production audit;</li>
                <li>compare charges with applicable Medicare pricing data;</li>
                <li>prepare an estimated true-cost bill and provider outreach for your review;</li>
                <li>maintain security, prevent abuse, troubleshoot errors, and improve the service; and</li>
                <li>comply with legal obligations that apply to the eventual operator.</li>
            </ul>
        </LegalSection>

        <LegalSection title="6. Provider outreach and your approval">
            <p>
                BillBacked is designed so that you review the estimated true cost and any draft communication before provider outreach begins. The current prototype does not send provider email or call a real provider. Email or phone outreach is shown only as the final stage after bill review and your approval. A production release must clearly identify each action that will share information and obtain the approval described in the interface.
            </p>
        </LegalSection>

        <LegalSection title="7. When information may be shared">
            <p>
                The current prototype does not publish bill data to advertisers or data brokers. A production service may need carefully selected hosting, authentication, storage, analytics, email, calling, or AI service providers to operate. Before those services process real patient information, BillBacked must identify them, limit their access by contract, document their purposes, and update this policy.
            </p>
            <p>
                Information may also need to be disclosed when required by applicable law, to protect users and the service from fraud or security threats, or as part of a business transaction. Any successor would remain responsible for the commitments in the policy that applies at the time of transfer.
            </p>
        </LegalSection>

        <LegalSection title="8. HIPAA and other health-data laws">
            <p>
                BillBacked does not currently represent that it is a HIPAA covered entity, a business associate, or a HIPAA-compliant service. HIPAA status depends on the operator, its relationship with healthcare organizations, and the work performed. Data placed in a consumer health app is not automatically protected by HIPAA.
            </p>
            <p>
                Other laws may still apply. Depending on the final product and data flows, these may include the Federal Trade Commission Act, the FTC Health Breach Notification Rule, state consumer-health privacy laws, general consumer privacy laws, and data-breach notification laws. The final operator must complete that analysis before production launch.
            </p>
        </LegalSection>

        <LegalSection title="9. Storage, retention, and deletion">
            <p>
                In the current prototype, the selected bill file remains in the browser session and is not intentionally uploaded for server-side analysis. Account authentication information may remain in the local Jac server used to run the prototype.
            </p>
            <p>
                A production release must publish specific retention periods for account information, original bills, extracted bill data, audit results, communications, backups, and security logs. It must also provide a documented process for access, correction, export, and deletion requests where required. No production retention period or deletion channel has been approved yet.
            </p>
        </LegalSection>

        <LegalSection title="10. Security">
            <p>
                No online service can guarantee absolute security. A production BillBacked service must use safeguards appropriate for medical and financial information, including data minimization, access controls, encryption in transit and at rest where appropriate, secure authentication, monitoring, tested incident response, and vendor review.
            </p>
            <p>
                Those production controls have not been independently audited for this prototype. Do not use the prototype for real patient information.
            </p>
        </LegalSection>

        <LegalSection title="11. Your choices and rights">
            <p>
                You can choose not to create an account or upload a file. You control whether to approve a draft provider communication. You can sign out from the settings page.
            </p>
            <p>
                Privacy rights vary by location and may include access, correction, deletion, portability, or the right to appeal a decision. A production service must provide a verified request process and describe applicable rights once its operator and launch jurisdictions are known.
            </p>
        </LegalSection>

        <LegalSection title="12. Children">
            <p>
                BillBacked is not directed to children under 13 and does not knowingly request information from them. A parent, guardian, or authorized representative must have legal authority before uploading another person&apos;s bill. Product eligibility rules must be finalized before production use.
            </p>
        </LegalSection>

        <LegalSection title="13. Changes to this policy">
            <p>
                This policy may change as BillBacked moves from prototype to production. Material changes should be presented clearly, with a new effective date and renewed consent when required. Continued prototype development does not replace notice or consent required by law.
            </p>
        </LegalSection>

        <LegalSection title="14. Contact and complaints">
            <p>
                No monitored privacy contact or legal operator has been configured for this prototype. Before production launch, this section must provide the operator&apos;s legal name, postal address, privacy email, security-reporting channel, and any legally required appeal or regulator information.
            </p>
        </LegalSection>

        <LaunchRequirements />
    </LegalDocument>;
}


def:pub TermsPage() -> JsxElement {
    return <LegalDocument
        title="Terms of Service"
        intro="These Terms govern access to the BillBacked Medicare bill-audit prototype. They explain what the prototype does, what you are responsible for, and its current limits."
    >
        <LegalSection title="1. Accepting these Terms">
            <p>
                By creating an account or using BillBacked, you agree to these Terms and acknowledge the Privacy Policy. If you do not agree, do not create an account or use the prototype. If you act for another person, you confirm that you are legally authorized to accept these Terms and handle that person&apos;s information.
            </p>
        </LegalSection>

        <LegalSection title="2. Eligibility">
            <p>
                You must be able to form a binding contract where you live and be legally authorized to review every bill you provide. BillBacked is not directed to children under 13. Final age, territory, and representative-access requirements must be established before production launch.
            </p>
        </LegalSection>

        <LegalSection title="3. Prototype service">
            <p>
                BillBacked is an early hackathon prototype. It demonstrates an intended workflow for choosing a Medicare bill, organizing charges, comparing pricing, estimating a fair amount, preparing provider outreach, and asking for your approval.
            </p>
            <p>
                The current audit results, agent progress, negotiated invoices, and savings are demonstration fixtures. They do not establish that a selected bill was read, that an error exists, or that any amount was negotiated.
            </p>
        </LegalSection>

        <LegalSection title="4. Your account">
            <p>
                Provide accurate account information and protect your password and device. Do not share credentials or attempt to access another person&apos;s workspace. Notify the future operator promptly if you believe an account has been compromised; a monitored reporting channel must be published before production use.
            </p>
        </LegalSection>

        <LegalSection title="5. Authorized bills and information">
            <p>
                Only choose a bill that belongs to you or that you are legally authorized to handle. You are responsible for obtaining any consent required from a patient, beneficiary, guardian, estate, or authorized representative.
            </p>
            <p>
                Do not submit false, misleading, unlawfully obtained, malicious, or unnecessary information. Do not upload real patient information to the current prototype.
            </p>
        </LegalSection>

        <LegalSection title="6. Pricing estimates and Medicare data">
            <p>
                Medicare pricing can vary by year, locality, care setting, provider status, coverage, coding, bundling, modifiers, medical necessity, secondary insurance, and other facts. BillBacked comparisons and &quot;true cost&quot; estimates are informational starting points, not authoritative coverage or payment determinations.
            </p>
            <p>
                You must compare the final analysis with the original bill, Medicare statements, insurer explanations of benefits, and information from the provider or payer.
            </p>
        </LegalSection>

        <LegalSection title="7. Not professional advice">
            <p>
                BillBacked does not provide medical diagnosis or treatment, legal representation, accounting services, insurance advice, or financial advice. It does not replace a clinician, attorney, Medicare representative, insurer, billing specialist, or qualified patient advocate.
            </p>
            <p>
                Do not delay medical care, miss an appeal or payment deadline, or ignore official correspondence because of information shown by the prototype.
            </p>
        </LegalSection>

        <LegalSection title="8. No guaranteed result">
            <p>
                BillBacked does not guarantee that a bill contains an error, that an estimate is correct, that a provider will respond, or that a balance will be reduced, paused, refunded, or forgiven. Providers, insurers, and government programs make their own decisions.
            </p>
        </LegalSection>

        <LegalSection title="9. Review and approval before outreach">
            <p>
                You are responsible for reviewing extracted information, calculations, deadlines, and draft messages. BillBacked is designed to require your approval before outreach. You remain responsible for the accuracy and consequences of any communication you approve.
            </p>
            <p>
                The current prototype does not send provider email, call a real provider, submit appeals, make payments, or bind you to a settlement.
            </p>
        </LegalSection>

        <LegalSection title="10. Acceptable use">
            <p>You may not use BillBacked to:</p>
            <ul className="list-disc space-y-2 pl-5">
                <li>violate law, privacy rights, confidentiality duties, or another person&apos;s rights;</li>
                <li>impersonate another person or misrepresent your authority;</li>
                <li>upload malware or interfere with the service or its security;</li>
                <li>scrape, probe, reverse engineer, or overload the service except where law expressly permits;</li>
                <li>train another model or build a competing dataset from protected service content without permission; or</li>
                <li>use automated outputs to harass, threaten, deceive, or discriminate against a provider or other person.</li>
            </ul>
        </LegalSection>

        <LegalSection title="11. Your content and permission to process it">
            <p>
                You retain your rights in bills and other information you provide. You grant the service only the limited permission needed to host, process, reproduce, transform, and transmit that information to operate the features you request, protect the service, and meet legal obligations.
            </p>
            <p>
                A production version must specify whether de-identified or aggregated information is used for analytics or model improvement and obtain any consent required by law. The prototype does not authorize use of real patient bills for model training.
            </p>
        </LegalSection>

        <LegalSection title="12. BillBacked materials">
            <p>
                The software, interface, branding, and original service content are owned by their respective rights holders. These Terms give you a limited, personal, revocable, non-transferable right to use the prototype for its intended evaluation purpose. They do not transfer ownership of the service.
            </p>
        </LegalSection>

        <LegalSection title="13. Third-party services and data">
            <p>
                Medicare datasets and future hosting, communications, AI, or authentication services may be provided by third parties with separate terms. BillBacked does not control third-party websites or official Medicare systems. A production release must identify material providers and define responsibility for their services.
            </p>
        </LegalSection>

        <LegalSection title="14. Availability and changes">
            <p>
                The prototype may be changed, suspended, or discontinued at any time. Features may be incomplete, unavailable, or inaccurate. BillBacked may restrict access needed to protect users, investigate misuse, comply with law, or maintain the service.
            </p>
        </LegalSection>

        <LegalSection title="15. Disclaimers">
            <p>
                To the extent permitted by applicable law, the prototype is provided for evaluation on an &quot;as is&quot; and &quot;as available&quot; basis without promises that it will be uninterrupted, secure, accurate, or suitable for a particular purpose. These Terms do not exclude warranties or rights that cannot lawfully be excluded.
            </p>
        </LegalSection>

        <LegalSection title="16. Liability and production terms">
            <p>
                A final production agreement must include a legally reviewed allocation of liability, any applicable liability cap, indemnity terms, governing law, dispute process, and venue. Those provisions depend on the legal operator and launch jurisdictions and have not been invented for this prototype.
            </p>
            <p>
                Nothing in these Terms limits liability where applicable law does not permit a limitation.
            </p>
        </LegalSection>

        <LegalSection title="17. Ending use">
            <p>
                You may stop using the prototype and sign out at any time. A production service must provide clear account-closure and deletion procedures, explain what information must be retained, and describe what happens to active audits or provider communications.
            </p>
        </LegalSection>

        <LegalSection title="18. Changes to these Terms">
            <p>
                BillBacked may update these Terms as the service changes. Material changes should be presented clearly and, where required, accepted before continued use. The effective date at the top identifies the current version.
            </p>
        </LegalSection>

        <LegalSection title="19. Contact, governing law, and disputes">
            <p>
                No legal operator, notice address, governing law, or dispute venue has been selected for this prototype. Those are essential contract terms and must be completed by the future operator with qualified counsel before public production use.
            </p>
        </LegalSection>

        <LaunchRequirements />
    </LegalDocument>;
}
