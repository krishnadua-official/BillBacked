"""Protected Medicare bill upload page."""

import from "@jac/runtime" { useNavigate }
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

    return <div className="flex flex-1 items-center justify-center px-4 py-10 sm:px-8 sm:py-14">
        <section
            className="w-full max-w-2xl"
            aria-labelledby="new-audit-title"
        >
            <div className="text-center">
                <h2
                    id="new-audit-title"
                    className="text-3xl font-medium tracking-[-0.05em] text-gray-1000 sm:text-4xl"
                >
                    Upload a Medicare bill
                </h2>
                <p className="mx-auto mt-3 max-w-lg text-sm leading-6 text-gray-900">
                    Add a PDF or clear photo. The agent will show every audit step in this workspace.
                </p>
            </div>
            <div className="mt-8 rounded-[20px] bg-canvas p-5 sm:p-6">
                <label
                    htmlFor="bill-upload"
                    className="group flex min-h-64 cursor-pointer flex-col items-center justify-center rounded-2xl bg-background p-6 text-center transition-colors hover:bg-blue-100 focus-within:ring-2 focus-within:ring-blue-700 focus-within:ring-offset-4"
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
            </div>
        </section>
    </div>;
}
