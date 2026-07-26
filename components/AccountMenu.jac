"""The account menu -- always reachable, at every width.

This lives in the page HEADER rather than the sidebar footer, and that is the
whole point. The sidebar is `collapsible="offcanvas"`, so on a narrow viewport
it is not merely thin -- it is gone, and anything parked inside it (including
sign out) goes with it. The header is on screen at every width, so the one
control a signed-in user must always be able to find lives here.

Two details that look cosmetic and are not:

  * The trigger is a raw `<button>`, not `<Button>`. A jac-shadcn `<Button>`
    handed to a Radix `*Trigger asChild` swallows the click and the menu never
    opens.
  * `side="bottom" align="end"`. The header sits at the TOP of the page, so the
    menu has room below it. Opening upward from here would flip the content off
    the top of the viewport and make it unclickable.

Stateless, like the other sections: identity comes down as props, the sign-out
event goes back up through `onLogout`.
"""

import from ".ui.avatar" { Avatar, AvatarFallback }
import from ".ui.dropdown_menu" {
    DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuLabel,
    DropdownMenuSeparator, DropdownMenuTrigger
}
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" { Logout01Icon, Settings01Icon }


def _initials(name: str) -> str {
    trimmed = name.strip();
    return trimmed[0].upper() if len(trimmed) > 0 else "U";
}


def:pub AccountMenu(
    name: str,
    email: str,
    onLogout: Callable[[], None],
    onSettings: Callable[[], None] | None = None
) -> JsxElement {
    # Radix fires `onSelect` for keyboard AND pointer activation; `onClick`
    # only covers the mouse.
    def handle_logout(_: any) {
        onLogout();
    }

    def handle_settings(_: any) {
        if onSettings {
            onSettings();
        }
    }

    return <DropdownMenu>
        <DropdownMenuTrigger asChild={True}>
            <button
                type="button"
                aria-label="Account"
                className="flex shrink-0 items-center gap-2 rounded-full pt-1 pb-1 pl-1 pr-1 transition-colors hover:bg-accent focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
            >
                <Avatar className="size-8 rounded-full">
                    <AvatarFallback className="rounded-full">
                        {_initials(name)}
                    </AvatarFallback>
                </Avatar>
                <span className="hidden max-w-32 truncate text-sm font-medium sm:block">
                    {name}
                </span>
            </button>
        </DropdownMenuTrigger>
        <DropdownMenuContent side="bottom" align="end" className="w-56">
            <DropdownMenuLabel>
                <div className="flex flex-col">
                    <span className="truncate text-sm font-medium">{name}</span>
                    {if email {
                        <span className="truncate text-xs font-normal text-muted-foreground">
                            {email}
                        </span>
                    }}
                </div>
            </DropdownMenuLabel>
            <DropdownMenuSeparator />
            {if onSettings {
                <DropdownMenuItem
                    key="settings"
                    onSelect={handle_settings}
                    className="cursor-pointer"
                >
                    <HugeiconsIcon icon={Settings01Icon} strokeWidth={2} />
                    Settings
                </DropdownMenuItem>
            }}
            <DropdownMenuItem onSelect={handle_logout} className="cursor-pointer">
                <HugeiconsIcon icon={Logout01Icon} strokeWidth={2} />
                Sign out
            </DropdownMenuItem>
        </DropdownMenuContent>
    </DropdownMenu>;
}
