"""The protected dashboard -- the stateful shell.

This file owns all page state and wires the sections together; the async
handler bodies live next door in DashboardPage.impl.jac. The sections
(AppSidebar / StatsRow / NoteList) are stateless: data flows down as
props, events flow back up through callbacks.

The server module is pulled in with `sv import`, and the two endpoint shapes
arrive differently:

  * READS are functions -> typed async stubs. `await list_notes()` is a real
    HTTP call with no fetch code in between, and the client caches it for 60s.
  * WRITES are walkers -> `await root spawn AddNote(title=...)`. `has` fields
    go up as the request body and `result.reports` comes back. Spawning a
    walker also invalidates every cached read, which is what makes the list
    actually refresh after a write. See the top of `services/notes.sv.jac`.
"""

import from "@jac/runtime" { jacLogout, useNavigate }
import from ".AccountMenu" { AccountMenu }
import from ".AppSidebar" { AppSidebar }
import from ".NoteList" { NoteList }
import from ".StatsRow" { StatsRow }
import from ".ui.button" { Button }
import from ".ui.input" { Input }
import from ".ui.separator" { Separator }
import from ".ui.sidebar" { SidebarInset, SidebarProvider, SidebarTrigger }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" { Add01Icon, Loading03Icon }

sv import from ..services.notes {
    NoteView, Profile, Stats,
    list_notes, my_profile, note_stats,
    AddNote, DeleteNote, ToggleNote
}


def:pub DashboardPage() -> JsxElement {
    has notes: list[NoteView] = [],
        stats: Stats | None = None,
        profile: Profile | None = None,
        draft: str = "",
        error: str = "",
        loading: bool = True,
        busy: bool = False;

    nav = useNavigate();

    can with entry { loadAll(); }

    async def loadAll -> None;
    async def createNote -> None;
    async def toggleNote(note_id: str) -> None;
    async def removeNote(note_id: str) -> None;

    def handle_draft(e: ChangeEvent) { draft = e.target.value; }

    def handle_submit(e: FormEvent) {
        e.preventDefault();
        createNote();
    }

    def handle_logout {
        jacLogout();
        nav("/login");
    }

    display_name = profile.name if profile else "there";

    return <SidebarProvider>
        <AppSidebar
            name={display_name}
            email={profile.email if profile else ""}
            onLogout={handle_logout}
        />
        <SidebarInset>
            <header className="flex h-14 shrink-0 items-center gap-2 border-b pl-4 pr-4">
                <SidebarTrigger />
                <Separator orientation="vertical" className="mr-2 h-4" />
                <h1 className="text-sm font-medium">Notes</h1>
                <div className="ml-auto flex items-center gap-2">
                    <AccountMenu
                        name={display_name}
                        email={profile.email if profile else ""}
                        onLogout={handle_logout}
                    />
                </div>
            </header>
            <main className="flex flex-1 flex-col gap-6 pt-6 pb-6 pl-6 pr-6">
                <div>
                    <h2 className="text-balance text-3xl font-bold tracking-tight">
                        {"Hey " + display_name}
                    </h2>
                    <p className="mt-2 text-base leading-relaxed text-muted-foreground">
                        Everything here is stored on your own graph. No one else can read it.
                    </p>
                </div>

                <StatsRow stats={stats} loading={loading} />

                {if error {
                    <p
                        className="rounded-lg border border-destructive/30 bg-destructive/10 pt-3 pb-3 pl-4 pr-4 text-sm text-destructive"
                        role="alert"
                    >
                        {error}
                    </p>
                }}

                <form className="flex gap-2" onSubmit={handle_submit}>
                    <Input
                        placeholder="Write a note and press enter..."
                        value={draft}
                        onChange={handle_draft}
                        disabled={busy}
                    />
                    <Button type="submit" disabled={busy or not draft}>
                        {if busy {
                            <HugeiconsIcon
                                icon={Loading03Icon}
                                strokeWidth={2}
                                className="size-4 animate-spin"
                            />
                        } else {
                            <HugeiconsIcon icon={Add01Icon} strokeWidth={2} className="size-4" />
                        }}
                        Add note
                    </Button>
                </form>

                <NoteList
                    notes={notes}
                    loading={loading}
                    onToggle={toggleNote}
                    onDelete={removeNote}
                />
            </main>
        </SidebarInset>
    </SidebarProvider>;
}
