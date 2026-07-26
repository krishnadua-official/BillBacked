"""Shared Medicare bill picker with drag-and-drop support.

With `href`, the zone is a public CTA and routes after click or file drop.
Without `href`, the selected browser File is passed to `onFile`.
"""

import from "@jac/runtime" { Link, useNavigate }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    ArrowRight01Icon, Upload01Icon
}


def BillDropZoneContent(
    dragging: bool,
    action_label: str
) -> JsxElement {
    prompt = (
        "Drop your Medicare bill"
        if dragging
        else "Choose or drop a Medicare bill"
    );

    return <>
        <HugeiconsIcon
            icon={Upload01Icon}
            strokeWidth={2}
            className="size-7 text-blue-700"
        />
        <span
            className="mt-6 text-base font-medium text-gray-1000"
            aria-live="polite"
        >
            {prompt}
        </span>
        <span className="mt-2 text-sm text-gray-700">
            PDF, PNG, or JPG
        </span>
        <span className="mt-6 inline-flex h-11 items-center gap-2 rounded-full bg-primary px-5 text-sm font-medium text-primary-foreground transition-transform group-hover:translate-y-[-1px]">
            {action_label}
            <HugeiconsIcon
                icon={ArrowRight01Icon}
                strokeWidth={2}
                className="size-4"
            />
        </span>
    </>;
}


def:pub BillDropZone(
    # Browser File objects cross the Jac client boundary as interop values.
    onFile: Callable[[any], None] | None = None,
    href: str = "",
    action_label: str = "Upload bill",
    input_id: str = "bill-upload"
) -> JsxElement {
    has dragging: bool = False;
    nav = useNavigate();

    def handle_drag_enter(event: DragEvent) -> None {
        event.preventDefault();
        event.stopPropagation();
        dragging = True;
    }

    def handle_drag_over(event: DragEvent) -> None {
        event.preventDefault();
        event.stopPropagation();
    }

    def handle_drag_leave(event: DragEvent) -> None {
        event.preventDefault();
        event.stopPropagation();
        dragging = False;
    }

    def handle_drop(event: DragEvent) -> None {
        event.preventDefault();
        event.stopPropagation();
        dragging = False;
        data_transfer = event.dataTransfer;
        if data_transfer {
            files = data_transfer.files;
            if files and files[0] {
                if href {
                    nav(href);
                } elif onFile {
                    onFile(files[0]);
                }
            }
        }
    }

    def handle_change(event: ChangeEvent) -> None {
        if onFile and event.target.files and event.target.files[0] {
            onFile(event.target.files[0]);
        }
    }

    zone_state = (
        "bg-blue-100 ring-2 ring-inset ring-blue-700"
        if dragging
        else "bg-background hover:bg-blue-100"
    );
    zone_class = (
        "group flex min-h-64 w-full flex-col items-center justify-center "
        "rounded-2xl p-6 text-center transition-colors "
        "focus-visible:outline-none focus-visible:ring-2 "
        "focus-visible:ring-blue-700 focus-visible:ring-offset-4 "
        + zone_state
    );

    return <>
        {if href {
            <Link
                key="bill-drop-zone-link"
                to={href}
                className={zone_class}
                aria-label="Create an account to start a Medicare bill negotiation"
                onDragEnter={handle_drag_enter}
                onDragOver={handle_drag_over}
                onDragLeave={handle_drag_leave}
                onDrop={handle_drop}
            >
                <BillDropZoneContent
                    dragging={dragging}
                    action_label={action_label}
                />
            </Link>
        } else {
            <label
                key="bill-drop-zone-input"
                htmlFor={input_id}
                className={zone_class + " cursor-pointer focus-within:ring-2 focus-within:ring-blue-700 focus-within:ring-offset-4"}
                onDragEnter={handle_drag_enter}
                onDragOver={handle_drag_over}
                onDragLeave={handle_drag_leave}
                onDrop={handle_drop}
            >
                <input
                    id={input_id}
                    type="file"
                    accept=".pdf,image/*"
                    className="sr-only"
                    onChange={handle_change}
                />
                <BillDropZoneContent
                    dragging={dragging}
                    action_label={action_label}
                />
            </label>
        }}
    </>;
}
