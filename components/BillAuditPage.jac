"""Protected Medicare bill upload page."""

import from "@jac/runtime" { useNavigate }
import from ".AppHeader" { DashboardHeader }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    ArrowRight01Icon, Upload01Icon
}


def:pub BillAuditPage() -> JsxElement {
    nav = useNavigate();

    def handle_file(e: ChangeEvent) -> None {
        if e.target.files {
            selected_file: any = e.target.files[0];
            nav(
                "/dashboard/audit",
                {"state": {"file_name": selected_file.name}}
            );
        }
    }

    return <div className="min-h-svh bg-background text-gray-1000">
        <DashboardHeader />
        <main className="mx-auto w-full max-w-7xl px-4 sm:px-6">
            <section className="mx-auto my-10 max-w-2xl rounded-[20px] bg-canvas p-6 sm:my-14 sm:p-8 lg:my-16">
                <div>
                    <h2 className="text-2xl font-medium tracking-[-0.04em]">
                        Upload your bill
                    </h2>
                    <p className="mt-2 text-sm leading-6 text-gray-900">
                        Use a PDF or clear photo. You will see the agent work step by step.
                    </p>
                </div>
                <label
                    htmlFor="bill-upload"
                    className="group mt-8 flex min-h-64 cursor-pointer flex-col items-center justify-center rounded-2xl bg-background p-6 text-center transition-colors hover:bg-blue-100 focus-within:ring-2 focus-within:ring-blue-700 focus-within:ring-offset-4"
                >
                    <input
                        id="bill-upload"
                        type="file"
                        accept=".pdf,image/*"
                        className="sr-only"
                        onChange={handle_file}
                    />
                    <HugeiconsIcon
                        icon={Upload01Icon}
                        strokeWidth={2}
                        className="size-7 text-blue-700"
                    />
                    <span className="mt-6 text-base font-medium">Choose a Medicare bill</span>
                    <span className="mt-2 text-sm text-gray-700">PDF, PNG, or JPG</span>
                    <span className="mt-6 inline-flex h-11 items-center gap-2 rounded-full bg-primary px-5 text-sm font-medium text-primary-foreground transition-transform group-hover:translate-y-[-1px]">
                        Upload bill
                        <HugeiconsIcon
                            icon={ArrowRight01Icon}
                            strokeWidth={2}
                            className="size-4"
                        />
                    </span>
                </label>
                <p className="mt-5 text-sm leading-6 text-gray-700">
                    Prototype only. Your file stays in this browser session.
                </p>
            </section>
        </main>
    </div>;
}
