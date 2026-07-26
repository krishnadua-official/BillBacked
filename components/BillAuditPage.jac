"""Protected Medicare bill upload page."""

import from "@jac/runtime" { useNavigate }
import from ".BillDropZone" { BillDropZone }
import from ".ui.button" { Button }

sv import from ..services.email_negotiation { StartNegotiation, CaseDetailView }


def:pub BillAuditPage() -> JsxElement {
    has negotiation_busy: bool = False;
    has negotiation_status: str = "";
    has negotiation_error: str = "";

    nav = useNavigate();

    def handle_files(selected_files: list[any]) -> None {
        file_names: list[str] = [f.name for f in selected_files];
        nav(
            "/dashboard/audit",
            {"state": {"file_names": file_names, "files": selected_files}}
        );
    }

    async def start_negotiation -> None {
        negotiation_busy = True;
        negotiation_error = "";
        negotiation_status = "";
        try {
            result = await root spawn StartNegotiation();
            rpt: CaseDetailView | None = result.reports[0] if result and result.reports and len(result.reports) > 0 else None;
            if rpt is None {
                negotiation_error = "Could not start negotiation. Try again.";
            } else {
                negotiation_status = "Negotiation started -- dispute email sent. Case " + rpt.id;
            }
        } except Exception {
            negotiation_error = "Something went wrong starting the negotiation.";
        }
        negotiation_busy = False;
    }

    def handle_start_negotiation(e: MouseEvent) -> None {
        start_negotiation();
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
                    Add every page you have for this visit -- MSN, EOB, provider bill, receipt.
                    The agent will show every audit step in this workspace.
                </p>
            </div>
            <div className="mt-8 rounded-[20px] bg-canvas p-5 sm:p-6">
                <BillDropZone onFiles={handle_files} />
            </div>
            <div className="mt-6 flex flex-col items-center gap-2">
                <Button
                    variant="primary"
                    onClick={handle_start_negotiation}
                    disabled={negotiation_busy}
                >
                    {"Sending..." if negotiation_busy else "Start negotiation"}
                </Button>
                {if negotiation_status {
                    <p key="neg-status" className="text-sm text-blue-700">
                        {negotiation_status}
                    </p>
                }}
                {if negotiation_error {
                    <p key="neg-error" className="text-sm text-red-700" role="alert">
                        {negotiation_error}
                    </p>
                }}
            </div>
        </section>
    </div>;
}
