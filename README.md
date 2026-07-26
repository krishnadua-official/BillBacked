# Fullstack Auth

Sign up, write notes, sign out. Nobody else can read them.

A complete login-gated app where the backend, the UI, and the data model are all
the same language — and there is no database to set up. Your data is persisted
for you from the first run. No ORM, no schema file, no connection string, no
hand-written API layer.

## What this demonstrates

### 1. A function is already a REST endpoint

[`services/notes.sv.jac`](services/notes.sv.jac) is the entire backend. This is
the whole "save" path:

```jac
"""Attach a new note to the caller's root. This is the whole "save" path."""
def:protect add_note(title: str) -> NoteView {
    note = Note(title=title, created_at=_now());
    root ++> note;
    return note.to_view();
}
```

That is live at `POST /function/add_note` — typed request body, typed response,
and an entry in the Swagger docs at `/docs`. Seven functions in that file, seven
endpoints, and nothing anywhere registers an API route:

`add_note`, `delete_note`, `list_notes`, `my_profile`, `note_stats`,
`save_profile`, `toggle_note`.

The helper `_now` is *not* one of them — a leading underscore keeps a function
off the API entirely. The only route table in this repo is the client-side
one in `main.jac` — the API has none.

### 2. `root` persists — there is no database to set up

```jac
node Note {
    has title: str = "";
    has done: bool = False;
    has created_at: str = "";
}

root ++> note;     # <- the entire persistence layer
```

`root ++> note` stores the node. Restart the server; the notes are still there.

To be precise, because the distinction matters: there **is** a database — you
just never configure one. Per `jac guide jac-sv-persistence`, persisted data
lives in `.jac/data/` (SQLite) by default, and setting `MONGODB_URI` (an env
var, or `[scale.database] mongodb_uri` in `jac.toml`) flips the same app to
MongoDB with a Redis L2 cache. Same model, same code, either backend.

What you don't write is the usual apparatus: no schema, no migration, no
connection string, no ORM, no `CREATE TABLE`, and nothing to install or point at.
Reads are a graph query rather than a SELECT:

```jac
notes = [root -->][?:Note];
```

Editing your archetypes later doesn't cost you data either: a newly added field
takes its default on old rows, and a removed field's value moves to an "attic"
sub-document rather than being dropped. (Renames are the one case you must
declare — see the guide.)

### 3. Auth is per-user by construction

Notice what `add_note` does **not** take: a `user_id`.

Every endpoint here requires a JWT, and `root` is the *calling user's own*
graph — so `[root -->][?:Note]` can only ever return the caller's notes.
Isolation is structural. It is not a `WHERE user_id = ?` you have to remember to
add, and it is not something a forged id can defeat:

```jac
def:protect toggle_note(note_id: str) -> NoteView | None {
    for n in [root -->][?:Note] {       # the caller's OWN root
        if jid(n) == note_id {
            n.done = not n.done;
            return n.to_view();
        }
    }
    return None;
}
```

Be precise about the modifier, because the name misleads. All seven functions
are `def:protect`. On the **auth** axis only `:pub` skips the JWT — `:protect`,
`:priv`, and a plain `def` are all equally locked down, and `:protect` is *not*
a middle auth tier. The `:pub`/`:protect`/`:priv` gradient is the **source
visibility** axis: `:priv` is module-only, `:protect` is project-wide, `:pub` is
world. These endpoints need a JWT *and* need importing from `.jac`
components, so `:protect` is the exact fit — `:priv` would compile and then warn
(`W2037`) when a component tried to import it.

### 4. Protected routes are one line in the route table

Routing is MANUAL: `base_route_app = "app"` in `jac.toml` points the client at
`app()` in `main.jac`, which declares every route explicitly:

```jac
<Routes>
    <Route path="/" element={<IndexRedirect />} />
    <Route path="/login" element={<LoginPage />} />
    <Route path="/signup" element={<SignupPage />} />
    <Route element={<AuthGuard redirect="/login" />}>
        <Route path="/dashboard" element={<DashboardPage />} />
    </Route>
</Routes>
```

The `<AuthGuard>` layout route is what protects the dashboard: logged-in
visitors fall through its `<Outlet/>` to the nested route, everyone else is
redirected to `/login` before `DashboardPage` ever renders. (Don't pass the
page as AuthGuard's JSX child — children are ignored and the page renders
blank; nest a `<Route>` instead.) `DashboardPage` itself does not mention
auth — the guard lives in the route table, so there is exactly one place to
check.

## Run it

```bash
jac install
jac start --dev
```

Open <http://localhost:8000>. Client files hot-reload; server changes restart.

## Auth API

`/user/register` and `/user/login` are provided by the runtime — nobody wrote
them and they are not in this repo. The contract is **not** `{email, password}`.
Identity is multi-identity from the start:

```
POST /user/register  {"identities":[{"type":"email","value":"a@b.io"}],
                      "credential":{"type":"password","password":"..."}}

POST /user/login     {"identity":{"type":"email","value":"a@b.io"},
                      "credential":{"type":"password","password":"..."}}
```

Register takes `identities` — a list, because a user may have several. Login
takes a single `identity`. `type` is `email` or `username`.

The JWT comes back **nested at `data.token`**, not at the top level. The API
serves on the app port + 1, so 8001 when the app is on 8000:

```bash
# register
curl -s -X POST http://localhost:8001/user/register \
  -H 'Content-Type: application/json' \
  -d '{"identities":[{"type":"email","value":"ada@example.io"}],
       "credential":{"type":"password","password":"hunter2hunter2"}}'

# login -- the token is at data.token
TOKEN=$(curl -s -X POST http://localhost:8001/user/login \
  -H 'Content-Type: application/json' \
  -d '{"identity":{"type":"email","value":"ada@example.io"},
       "credential":{"type":"password","password":"hunter2hunter2"}}' \
  | jq -r '.data.token')

# call a protected endpoint
curl -s -X POST http://localhost:8001/function/add_note \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"title": "written over http"}'
```

Drop the `Authorization` header and that last call is `401 UNAUTHORIZED` — the
same rule the UI plays by. Responses arrive in an envelope; your return value is
at `data.result`.

The browser never assembles any of this by hand: `jacSignup` and `jacLogin` from
`@jac/runtime` wrap these endpoints and park the token in localStorage. See
[`components/LoginPage.jac`](components/LoginPage.jac).

## Layout

```
main.jac                           entry: server import + the route table (manual routing)
jac.toml                           project config: theme, npm deps, single-process
services/notes.sv.jac              the whole backend -- 2 nodes, 2 objs, 7 endpoints
components/LoginPage.jac        /login     sign-in form -> jacLogin
components/SignupPage.jac       /signup    jacSignup, then jacLogin, then save_profile
components/DashboardPage.jac    /dashboard (AuthGuard) stateful shell: owns page state
components/DashboardPage.impl.jac  the async handler bodies
components/AccountMenu.jac      header account menu + sign out (visible at every width)
components/AppSidebar.jac       sidebar + user menu (stateless, props only)
components/NoteList.jac         the list, plus its empty and loading states
components/StatsRow.jac         the three KPI cards
components/ui/                     jac-shadcn primitives (yours to edit)
lib/utils.jac                   cn()
styles/global.css                  semantic tokens + theme
```

## The `app` export in `main.jac`

`app()` in `main.jac` is the client root: `base_route_app = "app"` in
`jac.toml` tells the runtime to mount it, and it owns the `<Router>`. Delete
or rename it and the bundle dies with `The requested module
'/compiled/main.js' does not provide an export named 'app'` — the page renders
blank with no build error to point you at.

## Extending it

See [`AGENTS.md`](AGENTS.md) — it has a **Try next** list of concrete prompts,
plus how to reach the Jac reference guides bundled with the compiler
(`jac guide jac-sv-auth` is the one that matters most here).
