"""The entire backend. Same language as the UI, no database to set up.

Five things worth noticing in this file:

1. ONE LANGUAGE. This is the same Jac you write in `.cl.jac` components.
   No second runtime, no ORM, no schema file, no API layer to hand-write.

2. AUTO-REST. Every declaration below is already an endpoint -- a `def` at
   `POST /function/<name>`, a `walker` at `POST /walker/<Name>` -- with a typed
   request body, a typed response, and an entry in the OpenAPI docs at `/docs`.
   Nothing registers a route by hand. A leading underscore (`_now`) keeps a
   helper OFF the API entirely.

3. AUTH IS THE DEFAULT. On the auth axis only `:pub` skips the JWT. A plain
   `def` / plain `walker` -- everything in this file -- requires a token and
   runs on the caller's OWN root. `:pub` would land every anonymous caller on
   ONE shared guest graph: a silent cross-user leak, with no compile or runtime
   error to catch it. Nothing here is `:pub`, because nothing here is anonymous
   data. See `jac guide jac-sv-auth`.

4. READS ARE FUNCTIONS, WRITES ARE WALKERS. This split is not decoration --
   the client runtime reads it. Every endpoint carries an `is_writer` flag in
   the client manifest: functions default to `is_writer: false`, so the client
   CACHES their responses for 60s (a feature -- `list_notes` does not refetch on
   every render). Walkers default to `is_writer: true`, so spawning one
   INVALIDATES those cached reads.

   Write a mutation as a `def` and the client caches it like a read and never
   invalidates anything -- you add a note, it saves, and the list does not
   update until you reload. That bug is invisible under `jac start --dev`
   (dev mode ships no manifest, so there is no cache); it only appears in
   production. So: new read -> `def`. New write -> `walker`.

   It is also what the docs prescribe -- "start with `def:pub` to prototype
   quickly, switch to walkers when you need authentication, per-user data
   isolation, or multi-step graph traversal"
   (https://docs.jaseci.org/tutorials/language/osp/). This app needs all three.

5. `root` PERSISTS, AND IT IS PER USER. `here ++> note` stores the node --
   that is the whole persistence layer as far as this file is concerned.
   There IS a database underneath; you just never configure one. Jac persists
   the graph for you: SQLite under `.jac/data/` by default, MongoDB (plus a
   Redis L2 cache) the moment `MONGODB_URI` is set. Same code, same model,
   either way -- no schema, no migrations, no ORM. `jac guide
   jac-sv-persistence` has the details.

   And it is per user: on an authenticated endpoint `root` is the *calling
   user's own* graph, so `[root -->][?:Note]` can only ever return the
   caller's notes. Isolation is structural, not a WHERE clause we have to
   remember to add.
"""

import from datetime { datetime, timezone }


node Profile {
    has name: str = "";
    has email: str = "";
}


node Note {
    has title: str = "";
    has done: bool = False;
    has created_at: str = "";

    def to_view -> NoteView {
        return NoteView(
            id=jid(self),
            title=self.title,
            done=self.done,
            created_at=self.created_at
        );
    }
}


obj NoteView {
    has id: str, title: str, done: bool, created_at: str;
}


obj Stats {
    has total: int = 0, active: int = 0, completed: int = 0;
}


def _now -> str {
    return datetime.now(timezone.utc).isoformat();
}


# ---------------------------------------------------------------------------
# READS -- plain functions.
#
# The client caches these for 60s and every walker below invalidates them, so
# a read stays a `def` precisely BECAUSE it is cacheable. Keep them free of
# side effects: a `def` that writes would be cached as a read and silently
# stop invalidating anything.
# ---------------------------------------------------------------------------

"""Return the signed-in user's profile, or None if they never saved one."""
def my_profile -> Profile | None {
    found = [root -->][?:Profile];
    return found[0] if len(found) > 0 else None;
}


"""Every note belonging to the caller, newest first."""
def list_notes -> list[NoteView] {
    views = [n.to_view() for n in [root -->][?:Note]];
    views.sort(key=lambda (v: NoteView) { v.created_at; }, reverse=True);
    return views;
}


"""Counts for the dashboard stat cards."""
def note_stats -> Stats {
    notes = [root -->][?:Note];
    completed = len([n for n in notes if n.done]);
    return Stats(total=len(notes), active=len(notes) - completed, completed=completed);
}


# ---------------------------------------------------------------------------
# WRITES -- walkers.
#
# A plain `walker` (no `:pub`) needs a JWT and spawns on the CALLER'S OWN ROOT,
# which is why not one of them takes a user id: `root` is already you. `has`
# fields are the request body; `report` values come back as `result.reports`.
# Inside `with Root entry`, `here` IS that root -- so `here ++> note` and
# `[here -->]` can only ever touch the caller's own graph.
#
# Give every `has` field a default. Without one it becomes a REQUIRED spawn
# argument -- including `reports` itself, whose `= []` is what keeps
# `root spawn AddNote(title=...)` from failing with E1050.
# ---------------------------------------------------------------------------

"""Create or update the signed-in user's profile. Called once at signup."""
walker SaveProfile {
    has name: str = "";
    has email: str = "";

    can save with Root entry {
        found = [here -->][?:Profile];
        if len(found) > 0 {
            found[0].name = self.name;
            found[0].email = self.email;
            report found[0];
            disengage;
        }
        profile = Profile(name=self.name, email=self.email);
        here ++> profile;
        report profile;
    }
}


"""Attach a new note to the caller's root. This is the whole "save" path."""
walker AddNote {
    has title: str = "";

    can create with Root entry {
        note = Note(title=self.title, created_at=_now());
        here ++> note;
        report note.to_view();
    }
}


"""Flip a note's done flag.

We look the note up by walking the caller's OWN root rather than resolving the
id globally -- so one user can never toggle another user's note, even if they
guess the id. Reports nothing when the id is not the caller's, so `reports`
comes back empty rather than leaking whether that note exists at all.
"""
walker ToggleNote {
    has note_id: str = "";

    can flip with Root entry {
        for n in [here -->][?:Note] {
            if jid(n) == self.note_id {
                n.done = not n.done;
                report n.to_view();
                disengage;
            }
        }
    }
}


"""Delete a note the caller owns. Same root-scoped lookup as ToggleNote.

NOTE the ability is `can remove`, not `can drop`. In Jac 0.34 naming a walker
ability `drop` corrupts the generated request-body OpenAPI schema: the walker
stops exposing its `has` fields and instead demands a wrapper field called
`inst`, so `root spawn DeleteNote(note_id=...)` 422s and the delete silently
no-ops ("Could not delete that note."). Any other verb (`remove`, `flip`,
`create`) generates the correct schema. Upstream jaclang bug -- reported."""
walker DeleteNote {
    has note_id: str = "";

    can remove with Root entry {
        for n in [here -->][?:Note] {
            if jid(n) == self.note_id {
                del n;
                report True;
                disengage;
            }
        }
        report False;
    }
}
