"""Protected Medicare bill upload page."""

import from "@jac/runtime" { useNavigate }
import from ".BillDropZone" { BillDropZone }


def:pub BillAuditPage() -> JsxElement {
    nav = useNavigate();

    def handle_file(selected_file: any) -> None {
        nav(
            "/dashboard/audit",
            {"state": {"file_name": selected_file.name, "file": selected_file}}
        );
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
                <BillDropZone onFile={handle_file} />
            </div>
        </section>
    </div>;
}
