"""Public BillBacked marketing page.

The landing page explains the value and routes visitors into authentication.
Bill upload and audit controls intentionally live only in the protected
dashboard.
"""

import from "@jac/runtime" { Link }
import from ".AppHeader" { PublicHeader }
import from ".BillDropZone" { BillDropZone }
import from ".ui.badge" { Badge }


def:pub LandingPage() -> JsxElement {
    return <div className="min-h-svh bg-background text-gray-1000">
        <PublicHeader overlay={True} inverse={True} />
        <main>
            <section className="relative isolate min-h-svh overflow-hidden">
                <picture
                    className="absolute inset-0 -z-20 block"
                    aria-hidden="true"
                >
                    <source
                        type="image/webp"
                        srcSet="/assets/images/happy-medicare-patient-hero-640.webp 640w, /assets/images/happy-medicare-patient-hero-1024.webp 1024w, /assets/images/happy-medicare-patient-hero-1672.webp 1672w"
                        sizes="100vw"
                    />
                    <img
                        src="/assets/images/happy-medicare-patient-hero-1672.jpg"
                        srcSet="/assets/images/happy-medicare-patient-hero-640.jpg 640w, /assets/images/happy-medicare-patient-hero-1024.jpg 1024w, /assets/images/happy-medicare-patient-hero-1672.jpg 1672w"
                        sizes="100vw"
                        width={1672}
                        height={941}
                        alt=""
                        fetchpriority="high"
                        loading="eager"
                        decoding="async"
                        className="h-full w-full object-cover object-[28%_center] lg:object-center"
                    />
                </picture>
                <div
                    className="pointer-events-none absolute inset-0 -z-10 bg-linear-to-r from-black/55 to-transparent"
                    aria-hidden="true"
                />
                <div className="mx-auto grid min-h-svh w-full max-w-7xl content-center gap-12 px-4 py-16 sm:px-6 sm:py-20 lg:grid-cols-[minmax(0,1.08fr)_minmax(360px,0.92fr)] lg:items-center lg:gap-16 lg:py-24">
                    <div className="text-white">
                        <Badge variant="glass">Built for Medicare bills</Badge>
                        <h1 className="mt-8 max-w-3xl text-balance text-4xl font-medium tracking-[-0.06em] sm:text-5xl sm:leading-[1.02] lg:text-6xl">
                            Understand your bill before you pay it.
                        </h1>
                        <p className="mt-6 max-w-2xl text-balance text-lg leading-8">
                            BillBacked audits every charge, estimates the fair Medicare cost, and prepares provider outreach for your approval.
                        </p>
                        <p className="mt-9 text-sm">
                            Your dashboard stays private. No provider message is sent without your approval.
                        </p>
                    </div>

                    <section
                        className="rounded-[20px] bg-canvas p-6 sm:p-8"
                        aria-labelledby="landing-upload-title"
                    >
                        <h2
                            id="landing-upload-title"
                            className="text-2xl font-medium tracking-[-0.04em]"
                        >
                            Upload a Medicare bill.
                        </h2>
                        <p className="mt-2 text-sm leading-6 text-gray-900">
                            Create a private account before choosing your PDF or photo.
                        </p>
                        <div className="mt-8">
                            <BillDropZone
                                href="/signup"
                                action_label="Sign up to upload"
                            />
                        </div>
                        <p className="mt-5 text-sm text-gray-900">
                            Already have an account?{" "}
                            <Link
                                to="/login"
                                className="rounded-md font-medium text-blue-700 underline-offset-4 hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-700"
                            >
                                Sign in
                            </Link>
                        </p>
                    </section>
                </div>
            </section>
        </main>
    </div>;
}
