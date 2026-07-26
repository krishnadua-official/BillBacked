"""Handler bodies for DashboardPage.

The annex sees the head file's imports (including the `sv import` stubs), so
nothing is re-imported here. Reactive `has` fields are read and written bare
-- no `self.` -- and each assignment re-renders.

Three rules show up in every handler below:

  * Every server call is awaited -- the function stubs and `root spawn` alike.
    They are async; forgetting the await assigns a Promise and the UI silently
    breaks.
  * Mutations write, then refetch. `notes.append(...)` would mutate in place
    and never re-render, so we rebind `notes` to a fresh server response.
  * A walker's report is read defensively -- a walker that finds nothing
    reports nothing. Note the variable is `rpt`: `report` is a KEYWORD in
    `.cl.jac` and naming a variable that fails with a cryptic parse error.
"""

impl DashboardPage.loadAll -> None {
    loading = True;
    error = "";
    try {
        profile = await my_profile();
        notes = await list_notes();
        stats = await note_stats();
    } except Exception as e {
        # SELF-HEAL A STALE / FOREIGN TOKEN.
        #
        # `jacIsLoggedIn()` only checks that a `jac_token` STRING exists, not
        # that it is valid -- so a token left in localStorage by a DIFFERENT Jac
        # app on this same origin (every `jac start` app is localhost:8000)
        # routes us into this protected page, and then every auth'd read 401s.
        # The client runtime clears a dead token automatically on the WALKER
        # path but NOT the function path (these reads are functions), so it
        # would otherwise sit here forever: "logged in" per the guard, broken in
        # fact, and the user cannot reach /login because the guard keeps
        # bouncing them back. So we clear it ourselves: drop the token and hard-
        # redirect to a clean sign-in. A genuine (network) failure does NOT match
        # and just shows the error, keeping a valid session intact.
        if "UNAUTHORIZED" in str(e) or "401" in str(e) {
            jacLogout();
            window.location.replace("/login");
            return;
        }
        error = "Could not load your notes.";
    }
    loading = False;
}

impl DashboardPage.createNote -> None {
    title = draft.strip();
    if not title {
        return;
    }
    busy = True;
    error = "";
    try {
        result = await root spawn AddNote(title=title);
        rpt = result.reports[0] if result and result.reports and len(result.reports) > 0 else None;
        if rpt is None {
            error = "Could not save that note.";
            busy = False;
            return;
        }
        draft = "";
        notes = await list_notes();
        stats = await note_stats();
    } except Exception {
        error = "Could not save that note.";
    }
    busy = False;
}

impl DashboardPage.toggleNote(note_id: str) -> None {
    error = "";
    try {
        await root spawn ToggleNote(note_id=note_id);
        notes = await list_notes();
        stats = await note_stats();
    } except Exception {
        error = "Could not update that note.";
    }
}

impl DashboardPage.removeNote(note_id: str) -> None {
    error = "";
    try {
        await root spawn DeleteNote(note_id=note_id);
        notes = await list_notes();
        stats = await note_stats();
    } except Exception {
        error = "Could not delete that note.";
    }
}
