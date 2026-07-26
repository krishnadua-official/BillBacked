"""The per-user note list.

Each row wraps the incoming callbacks in a local handler so the row's own
id is closed over when the event fires -- that is why `onToggle` is called
from inside `handle_toggle` rather than inline in the JSX.
"""

import from ".ui.button" { Button }
import from ".ui.card" { Card, CardContent }
import from ".ui.checkbox" { Checkbox }
import from ".ui.empty" {
    Empty, EmptyDescription, EmptyHeader, EmptyMedia, EmptyTitle
}
import from ".ui.skeleton" { Skeleton }
import from "..lib.utils" { cn }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" { Delete02Icon, StickyNote01Icon }

sv import from ..services.notes { NoteView }


def:pub NoteRow(
    noteId: str,
    title: str,
    done: bool,
    onToggle: Callable[[str], None],
    onDelete: Callable[[str], None]
) -> JsxElement {
    def handle_toggle() {
        onToggle(noteId);
    }

    def handle_delete(_: MouseEvent) {
        onDelete(noteId);
    }

    return <div className="flex items-center gap-4 border-b pt-3 pb-3 pl-4 pr-4 last:border-b-0">
        <Checkbox checked={done} onCheckedChange={handle_toggle} />
        <span
            className={cn(
                "flex-1 text-sm",
                "text-muted-foreground line-through" if done else "text-foreground"
            )}
        >
            {title}
        </span>
        <Button
            variant="ghost"
            size="icon"
            onClick={handle_delete}
            aria-label="Delete note"
        >
            <HugeiconsIcon
                icon={Delete02Icon}
                strokeWidth={2}
                className="size-4 text-muted-foreground"
            />
        </Button>
    </div>;
}


def:pub NoteList(
    notes: list[NoteView],
    loading: bool,
    onToggle: Callable[[str], None],
    onDelete: Callable[[str], None]
) -> JsxElement {
    if loading {
        return <Card>
            <CardContent className="flex flex-col gap-4 pt-6 pb-6">
                {for i in range(3) {
                    <Skeleton key={str(i)} className="h-6 w-full" />
                }}
            </CardContent>
        </Card>;
    }

    if len(notes) == 0 {
        return <Card>
            <CardContent className="pt-12 pb-12">
                <Empty>
                    <EmptyHeader>
                        <EmptyMedia variant="icon">
                            <HugeiconsIcon icon={StickyNote01Icon} strokeWidth={2} />
                        </EmptyMedia>
                        <EmptyTitle>No notes yet</EmptyTitle>
                        <EmptyDescription>
                            Add your first note above. It saves straight to your graph.
                        </EmptyDescription>
                    </EmptyHeader>
                </Empty>
            </CardContent>
        </Card>;
    }

    return <Card>
        <CardContent className="pt-0 pb-0 pl-0 pr-0">
            {for n in notes {
                <NoteRow
                    key={n.id}
                    noteId={n.id}
                    title={n.title}
                    done={n.done}
                    onToggle={onToggle}
                    onDelete={onDelete}
                />
            }}
        </CardContent>
    </Card>;
}
