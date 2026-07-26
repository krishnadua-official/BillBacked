"""The first BillBacked product surface.

This is intentionally a front-end prototype. A Medicare bill can be selected
locally and the interface demonstrates the audit workflow without pretending
that real analysis or negotiation has happened.
"""

import from ".ui.badge" { Badge }
import from ".ui.button" { Button }
import from ".ui.card" {
    Card, CardContent, CardDescription, CardHeader, CardTitle
}
import from "..lib.utils" { cn }
import from "@jac/runtime" { Link }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    ArrowRight01Icon, CheckmarkCircle01Icon, Clock01Icon,
    File01Icon, Mail01Icon, Upload01Icon
}


def:pub ProductHeader(
    action_label: str = "Sign in",
    action_href: str = "/login"
) -> JsxElement {
    return <header className="border-b bg-background">
        <div className="mx-auto flex h-16 max-w-6xl items-center justify-between px-4 sm:px-6">
            <div className="flex items-center gap-3">
                <div className="flex size-8 items-center justify-center rounded-md bg-foreground text-background">
                    <span className="text-sm font-semibold" aria-hidden="true">B</span>
                </div>
                <span className="text-sm font-semibold tracking-tight">BillBacked</span>
                <Badge variant="outline" className="hidden sm:inline-flex">
                    Medicare audit
                </Badge>
            </div>
            <div className="flex items-center gap-4">
                <span className="hidden text-xs text-muted-foreground sm:inline">
                    Private by design
                </span>
                <Link
                    to={action_href}
                    className="rounded-md px-2 py-1 text-sm font-medium underline-offset-4 hover:bg-muted focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                >
                    {action_label}
                </Link>
            </div>
        </div>
    </header>;
}


def:pub WorkflowItem(
    number: str,
    title: str,
    description: str
) -> JsxElement {
    return <li className="grid grid-cols-[32px_1fr] gap-3">
        <span className="flex size-8 items-center justify-center rounded-full border bg-background text-xs font-medium">
            {number}
        </span>
        <div className="pt-1">
            <p className="text-sm font-medium">{title}</p>
            <p className="mt-1 text-sm leading-5 text-muted-foreground">
                {description}
            </p>
        </div>
    </li>;
}


def:pub AuditStep(
    step: int,
    current_step: int,
    title: str,
    description: str,
    is_last: bool = False
) -> JsxElement {
    is_complete = step < current_step;
    is_current = step == current_step;

    return <li
        className="relative grid grid-cols-[40px_1fr] gap-4 pb-7 last:pb-0"
        aria-current={"step" if is_current else None}
    >
        {if not is_last {
            <span
                key="connector"
                className={cn(
                    "absolute left-[19px] top-10 h-[calc(100%-40px)] w-px",
                    "bg-inverse-track"
                )}
                aria-hidden="true"
            />
        }}
        <span
            className={cn(
                "relative z-10 flex size-10 items-center justify-center rounded-full border text-sm font-medium",
                "transition-colors duration-150",
                "border-inverse-border bg-inverse-surface-200 text-inverse-text-secondary",
                "border-amber-500 bg-amber-400 text-amber-950" if is_complete else "",
                "border-amber-400 bg-amber-400 text-amber-950 ring-4 ring-amber-400/20" if is_current else ""
            )}
            aria-hidden="true"
        >
            {if is_complete {
                <HugeiconsIcon
                    key="complete-icon"
                    icon={CheckmarkCircle01Icon}
                    strokeWidth={2}
                    className="size-5"
                />
            } else {
                step;
            }}
        </span>
        <div className="pt-0.5">
            <div className="flex flex-wrap items-center gap-2">
                <p className={cn(
                    "text-sm font-medium",
                    "text-inverse-text-primary" if is_complete or is_current else "text-inverse-text-secondary"
                )}>
                    {title}
                </p>
                {if is_current {
                    <span
                        key="current-badge"
                        className="rounded-full border border-amber-400/40 bg-amber-400/10 px-2 py-0.5 text-xs text-amber-200"
                    >
                        Current
                    </span>
                }}
            </div>
            <p className="mt-1 text-sm leading-5 text-inverse-text-secondary">
                {description}
            </p>
        </div>
    </li>;
}


def:pub BillAuditPage() -> JsxElement {
    has file_name: str = "",
        current_step: int = 0;

    def begin_audit(file: any) -> None {
        file_name = file.name;
        current_step = 1;
        setTimeout(lambda -> None { current_step = 2; }, 900);
        setTimeout(lambda -> None { current_step = 3; }, 1900);
        setTimeout(lambda -> None { current_step = 4; }, 3100);
    }

    def handle_file(e: ChangeEvent) -> None {
        if e.target.files {
            begin_audit(e.target.files[0]);
        }
    }

    def reset_audit() -> None {
        file_name = "";
        current_step = 0;
    }

    status_title = "Reading your bill";
    status_copy = "Extracting charge lines and provider information.";
    if current_step == 2 {
        status_title = "Organizing your charges";
        status_copy = "Classifying each item by service, provider, location, and Medicare context.";
    } elif current_step == 3 {
        status_title = "Calculating the true cost";
        status_copy = "Comparing each charge with historical rates for the same Medicare service.";
    } elif current_step == 4 {
        status_title = "Audit ready for review";
        status_copy = "The next product step is your approval before any negotiation begins.";
    }

    if file_name {
        return <div className="min-h-svh bg-background text-foreground">
            <ProductHeader />
            <main className="mx-auto w-full max-w-6xl px-4 py-10 sm:px-6 sm:py-14">
                <div className="mb-8 flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
                    <div className="max-w-2xl">
                        <Badge variant="secondary">Prototype audit</Badge>
                        <h1 className="mt-4 text-3xl font-semibold tracking-[-0.04em] sm:text-4xl">
                            Your bill audit
                        </h1>
                        <p className="mt-3 text-base leading-6 text-muted-foreground">
                            Follow each step. Nothing is sent to the provider without your approval.
                        </p>
                    </div>
                    {if current_step == 4 {
                        <Button
                            key="upload-another"
                            variant="outline"
                            className="h-10 self-start rounded-md px-3 sm:self-auto"
                            onClick={reset_audit}
                        >
                            Upload another bill
                        </Button>
                    }}
                </div>

                <div className="grid gap-6 lg:grid-cols-[320px_minmax(0,1fr)]">
                    <Card className="h-fit rounded-xl shadow-none">
                        <CardHeader>
                            <CardTitle>Uploaded bill</CardTitle>
                            <CardDescription>
                                The file stays in this prototype session.
                            </CardDescription>
                        </CardHeader>
                        <CardContent>
                            <div className="flex items-start gap-3 rounded-md bg-muted p-3">
                                <span className="flex size-10 shrink-0 items-center justify-center rounded-md border bg-background">
                                    <HugeiconsIcon
                                        icon={File01Icon}
                                        strokeWidth={2}
                                        className="size-5 text-muted-foreground"
                                    />
                                </span>
                                <div className="min-w-0 pt-0.5">
                                    <p className="truncate text-sm font-medium">{file_name}</p>
                                    <p className="mt-1 text-xs text-muted-foreground">
                                        PDF or image · Medicare bill
                                    </p>
                                </div>
                            </div>
                            <div className="mt-6 border-t pt-4">
                                <p className="text-xs font-medium uppercase tracking-[0.12em] text-muted-foreground">
                                    Safeguard
                                </p>
                                <p className="mt-2 text-sm leading-5">
                                    Provider outreach starts only after you review the true-cost bill.
                                </p>
                            </div>
                        </CardContent>
                    </Card>

                    <section
                        className="rounded-[24px] border border-inverse-border bg-inverse-surface-100 p-6 text-inverse-text-primary shadow-[0_16px_40px_rgba(0,0,0,0.18)] sm:p-8"
                        aria-labelledby="audit-status-title"
                    >
                        <div aria-live="polite">
                            <div className="flex items-center gap-2 text-sm text-inverse-text-secondary">
                                <HugeiconsIcon
                                    icon={Clock01Icon}
                                    strokeWidth={2}
                                    className="size-4"
                                />
                                {"Complete" if current_step == 4 else "Audit in progress"}
                            </div>
                            <h2
                                id="audit-status-title"
                                className="mt-3 text-2xl font-semibold tracking-[-0.03em]"
                            >
                                {status_title}
                            </h2>
                            <p className="mt-2 max-w-xl text-sm leading-6 text-inverse-text-secondary">
                                {status_copy}
                            </p>
                        </div>

                        <ol className="mt-8">
                            <AuditStep
                                step={1}
                                current_step={current_step}
                                title="Read the bill"
                                description="Extract charge lines, codes, dates, and provider details."
                            />
                            <AuditStep
                                step={2}
                                current_step={current_step}
                                title="Organize the charges"
                                description="Categorize items using service, location, provider, age, and Medicare context."
                            />
                            <AuditStep
                                step={3}
                                current_step={current_step}
                                title="Calculate the true cost"
                                description="Compare each item with historic charges for the same Medicare service."
                            />
                            <AuditStep
                                step={4}
                                current_step={current_step}
                                title="Prepare the negotiation"
                                description="Draft the true-cost bill and provider email for your approval."
                                is_last={True}
                            />
                        </ol>

                        {if current_step == 4 {
                            <div
                                key="approval-note"
                                className="mt-8 flex items-start gap-3 rounded-xl border border-inverse-border bg-inverse-surface-200 p-4"
                            >
                                <HugeiconsIcon
                                    icon={Mail01Icon}
                                    strokeWidth={2}
                                    className="mt-0.5 size-5 shrink-0 text-amber-300"
                                />
                                <div>
                                    <p className="text-sm font-medium">No message has been sent</p>
                                    <p className="mt-1 text-sm leading-5 text-inverse-text-secondary">
                                        The approval and negotiation screens are the next product iteration.
                                    </p>
                                </div>
                            </div>
                        }}
                    </section>
                </div>
            </main>
        </div>;
    }

    return <div className="min-h-svh bg-background text-foreground">
        <ProductHeader />
        <main className="mx-auto grid w-full max-w-6xl gap-10 px-4 py-12 sm:px-6 sm:py-20 lg:grid-cols-[minmax(0,1.05fr)_minmax(360px,0.95fr)] lg:items-start lg:gap-16">
            <section className="pt-2 lg:pt-8">
                <Badge variant="secondary">Built for Medicare bills</Badge>
                <h1 className="mt-6 max-w-2xl text-4xl font-semibold tracking-[-0.05em] sm:text-5xl sm:leading-[1.04]">
                    Find what your medical bill should cost.
                </h1>
                <p className="mt-6 max-w-xl text-lg leading-7 text-muted-foreground">
                    Upload a Medicare bill. BillBacked reads every charge, compares it with historical pricing, and prepares the dispute for you.
                </p>

                <ol className="mt-10 grid max-w-xl gap-6 sm:grid-cols-3 sm:gap-4">
                    <WorkflowItem
                        number="1"
                        title="Read"
                        description="Extract every charge and code."
                    />
                    <WorkflowItem
                        number="2"
                        title="Calculate"
                        description="Estimate the true Medicare cost."
                    />
                    <WorkflowItem
                        number="3"
                        title="Negotiate"
                        description="Prepare outreach for approval."
                    />
                </ol>
            </section>

            <Card className="rounded-xl shadow-[0_2px_2px_rgba(0,0,0,0.04)]">
                <CardHeader className="px-6 pt-2">
                    <CardTitle className="text-xl">Upload a Medicare bill</CardTitle>
                    <CardDescription className="max-w-sm leading-5">
                        Use a PDF or clear photo. You will see every audit step as it happens.
                    </CardDescription>
                </CardHeader>
                <CardContent className="px-6 pb-2">
                    <label
                        htmlFor="bill-upload"
                        className="group flex min-h-56 cursor-pointer flex-col items-center justify-center rounded-md border border-dashed bg-muted/40 p-6 text-center transition-colors hover:border-foreground/30 hover:bg-muted/70 focus-within:ring-2 focus-within:ring-ring focus-within:ring-offset-2"
                    >
                        <input
                            id="bill-upload"
                            type="file"
                            accept=".pdf,image/*"
                            className="sr-only"
                            onChange={handle_file}
                        />
                        <span className="flex size-12 items-center justify-center rounded-full border bg-background shadow-sm">
                            <HugeiconsIcon
                                icon={Upload01Icon}
                                strokeWidth={2}
                                className="size-5"
                            />
                        </span>
                        <span className="mt-5 text-sm font-medium">Choose your bill</span>
                        <span className="mt-2 text-sm text-muted-foreground">
                            PDF, PNG, or JPG
                        </span>
                        <span className="mt-5 inline-flex h-10 items-center gap-2 rounded-md bg-primary px-3 text-sm font-medium text-primary-foreground transition-colors group-hover:bg-primary/80">
                            Upload bill
                            <HugeiconsIcon
                                icon={ArrowRight01Icon}
                                strokeWidth={2}
                                className="size-4"
                            />
                        </span>
                    </label>
                    <p className="mt-4 text-center text-xs leading-5 text-muted-foreground">
                        Prototype only. Your file is not uploaded to a server yet.
                    </p>
                </CardContent>
            </Card>
        </main>
    </div>;
}
