"""Sidebar for the app shell -- stateless, driven entirely by props.

This is `collapsible="offcanvas"`, so below the breakpoint it is not a narrow
rail -- it is gone entirely. Anything a signed-in user MUST always be able to
reach therefore cannot live only in here: the account menu in the page header
(`AccountMenu.cl.jac`) is the one that is guaranteed to be on screen. The footer
entry below is a convenience duplicate for wide viewports.

The footer trigger is a raw `<button>`, and that is load-bearing. Handing a
component like `SidebarMenuButton` to a Radix `*Trigger asChild` looks right and
fails quietly: these primitives are plain function components, so the ref Radix
clones onto them is dropped. With no anchor element to measure, Radix positions
the menu from the page origin -- it opened at y = -91, above the top of the
window, unclickable. A raw `<button>` gives Radix a real DOM node and the menu
lands where it should.
"""

import from ".ui.avatar" { Avatar, AvatarFallback }
import from ".ui.dropdown_menu" {
    DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuLabel,
    DropdownMenuSeparator, DropdownMenuTrigger
}
import from ".ui.sidebar" {
    Sidebar, SidebarContent, SidebarFooter, SidebarGroup, SidebarGroupContent,
    SidebarGroupLabel, SidebarHeader, SidebarMenu, SidebarMenuButton, SidebarMenuItem
}
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    Logout01Icon, SparklesIcon, StickyNote01Icon
}


def _initials(name: str) -> str {
    trimmed = name.strip();
    return trimmed[0].upper() if len(trimmed) > 0 else "U";
}


def:pub AppSidebar(name: str, email: str, onLogout: Callable[[], None]) -> JsxElement {
    def handle_logout(_: any) {
        onLogout();
    }

    return <Sidebar collapsible="offcanvas">
        <SidebarHeader>
            <div className="flex items-center gap-2 pt-2 pb-2 pl-2 pr-2">
                <div className="flex size-8 shrink-0 items-center justify-center rounded-lg bg-primary text-primary-foreground">
                    <HugeiconsIcon icon={SparklesIcon} strokeWidth={2} className="size-4" />
                </div>
                <div className="flex flex-col">
                    <span className="text-sm font-semibold tracking-tight">Notebook</span>
                    <span className="text-xs text-muted-foreground">Jac fullstack starter</span>
                </div>
            </div>
        </SidebarHeader>
        <SidebarContent>
            <SidebarGroup>
                <SidebarGroupLabel>Workspace</SidebarGroupLabel>
                <SidebarGroupContent>
                    <SidebarMenu>
                        <SidebarMenuItem>
                            <SidebarMenuButton isActive={True}>
                                <HugeiconsIcon icon={StickyNote01Icon} strokeWidth={2} />
                                <span>Notes</span>
                            </SidebarMenuButton>
                        </SidebarMenuItem>
                    </SidebarMenu>
                </SidebarGroupContent>
            </SidebarGroup>
        </SidebarContent>
        <SidebarFooter>
            <SidebarMenu>
                <SidebarMenuItem>
                    <DropdownMenu>
                        <DropdownMenuTrigger asChild={True}>
                            <button
                                type="button"
                                aria-label="Account menu"
                                className="flex h-12 w-full items-center gap-2 overflow-hidden rounded-md pt-2 pb-2 pl-2 pr-2 text-left text-sm outline-hidden transition-colors hover:bg-sidebar-accent hover:text-sidebar-accent-foreground focus-visible:ring-2 focus-visible:ring-sidebar-ring"
                            >
                                <Avatar className="size-8 rounded-lg">
                                    <AvatarFallback className="rounded-lg">
                                        {_initials(name)}
                                    </AvatarFallback>
                                </Avatar>
                                <div className="flex flex-col items-start overflow-hidden text-left">
                                    <span className="truncate text-sm font-medium">{name}</span>
                                    <span className="truncate text-xs text-muted-foreground">
                                        {email}
                                    </span>
                                </div>
                            </button>
                        </DropdownMenuTrigger>
                        <DropdownMenuContent side="right" align="end" className="w-56">
                            <DropdownMenuLabel>
                                <div className="flex flex-col">
                                    <span className="text-sm font-medium">{name}</span>
                                    <span className="text-xs font-normal text-muted-foreground">
                                        {email}
                                    </span>
                                </div>
                            </DropdownMenuLabel>
                            <DropdownMenuSeparator />
                            <DropdownMenuItem onSelect={handle_logout} className="cursor-pointer">
                                <HugeiconsIcon icon={Logout01Icon} strokeWidth={2} />
                                Sign out
                            </DropdownMenuItem>
                        </DropdownMenuContent>
                    </DropdownMenu>
                </SidebarMenuItem>
            </SidebarMenu>
        </SidebarFooter>
    </Sidebar>;
}
