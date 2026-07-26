"""Shared account menu for the persistent header and sidebar footer.

The menu behavior and actions live here once. The `variant` prop changes only
the trigger presentation and menu placement for its two layout contexts.
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
    onSettings: Callable[[], None] | None = None,
    variant: str = "header",
    description: str = "Private Medicare workspace"
) -> JsxElement {
    # Radix fires `onSelect` for keyboard AND pointer activation; `onClick`
    # only covers the mouse.
    def handle_logout(_event: Event) {
        onLogout();
    }

    def handle_settings(_event: Event) {
        if onSettings {
            onSettings();
        }
    }

    is_sidebar = variant == "sidebar";
    trigger_label = "Open account menu" if is_sidebar else "Account";
    trigger_class = (
        "flex min-h-12 w-full items-center gap-3 overflow-hidden rounded-xl p-2 text-left transition-colors hover:bg-sidebar-accent focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-700"
        if is_sidebar
        else "flex shrink-0 items-center gap-2 rounded-full p-1 transition-colors hover:bg-accent focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
    );
    menu_side = "top" if is_sidebar else "bottom";
    menu_align = "start" if is_sidebar else "end";
    menu_width = "w-60" if is_sidebar else "w-56";
    secondary_text = email if email else (description if is_sidebar else "");

    return <DropdownMenu>
        <DropdownMenuTrigger asChild={True}>
            <button
                type="button"
                aria-label={trigger_label}
                className={trigger_class}
            >
                <Avatar className="size-8 rounded-full">
                    <AvatarFallback className="rounded-full">
                        {_initials(name)}
                    </AvatarFallback>
                </Avatar>
                {if is_sidebar {
                    <span
                        key="sidebar-account-copy"
                        className="flex min-w-0 flex-col"
                    >
                        <span className="truncate text-sm font-medium">{name}</span>
                        <span className="truncate text-xs text-gray-900">
                            {description}
                        </span>
                    </span>
                } else {
                    <span
                        key="header-account-copy"
                        className="hidden max-w-32 truncate text-sm font-medium sm:block"
                    >
                        {name}
                    </span>
                }}
            </button>
        </DropdownMenuTrigger>
        <DropdownMenuContent
            side={menu_side}
            align={menu_align}
            className={menu_width}
        >
            <DropdownMenuLabel>
                <div className="flex flex-col">
                    <span className="truncate text-sm font-medium">{name}</span>
                    {if secondary_text {
                        <span
                            key="secondary-account-text"
                            className="truncate text-xs font-normal text-muted-foreground"
                        >
                            {secondary_text}
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
