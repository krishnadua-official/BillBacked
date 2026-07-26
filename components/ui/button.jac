import from "class-variance-authority" { cva }
import from "radix-ui" { Slot }
import from ...lib.utils { cn }

glob _buttonVariants: any = cva(
         "group/button inline-flex shrink-0 select-none items-center justify-center whitespace-nowrap rounded-full border border-transparent bg-clip-padding text-sm font-medium outline-none transition-colors disabled:pointer-events-none disabled:cursor-not-allowed disabled:bg-muted disabled:text-gray-700 disabled:opacity-100 focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/30 focus-visible:ring-offset-2 focus-visible:ring-offset-background aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4",
         {
             "variants": {
                 "variant": {
                     "primary": "bg-primary text-primary-foreground hover:bg-primary/90 active:bg-primary/80",
                     "secondary": "border-border bg-background text-foreground hover:border-input hover:bg-muted active:bg-background-200",
                     "tertiary": "bg-transparent text-primary hover:bg-blue-100 active:bg-blue-100",
                     "default": "bg-primary text-primary-foreground hover:bg-primary/90 active:bg-primary/80",
                     "outline": "border-border bg-background text-foreground hover:border-input hover:bg-muted active:bg-background-200",
                     "ghost": "bg-transparent text-foreground hover:bg-muted active:bg-background-200",
                     "destructive": "bg-destructive text-white hover:bg-destructive/90 active:bg-destructive/80 focus-visible:ring-destructive/30",
                     "link": "rounded-md border-0 px-0 text-primary underline-offset-4 hover:underline"
                 },
                 "size": {
                     "default": "h-10 gap-2 px-5",
                     "xs": "h-8 gap-1.5 px-3 text-xs",
                     "sm": "h-9 gap-1.5 px-4",
                     "lg": "h-12 gap-2 px-6 text-base",
                     "icon": "size-10 p-0",
                     "icon-xs": "size-8 p-0 [&_svg:not([class*='size-'])]:size-3",
                     "icon-sm": "size-10 p-0 [&_svg:not([class*='size-'])]:size-3.5",
                     "icon-lg": "size-12 p-0"
                 }
             },
             "defaultVariants": {"variant": "primary", "size": "default"}
         }
     ),
     _buttonExcludeKeys: list[str] = [
         "className",
         "variant",
         "size",
         "asChild",
         "children"
     ];

def:pub Button(props: any) -> JsxElement {
    variant = props["variant"] or "default";
    size = props["size"] or "default";
    asChild = props["asChild"] or False;

    restProps = {};
    for key in Object.keys(props) {
        if key not in _buttonExcludeKeys {
            restProps[key] = props[key];
        }
    }

    computedClass = cn(
        _buttonVariants.call(
            None, {"variant": variant, "size": size, "className": props["className"]}
        )
    );

    if asChild {
        return
            <Slot.Root
                data-slot="button"
                data-variant={variant}
                data-size={size}
                className={computedClass}
                {**restProps}
            >
                {props["children"]}
            </Slot.Root>;
    }

    return
        <button
            data-slot="button"
            data-variant={variant}
            data-size={size}
            className={computedClass}
            {**restProps}
        >
            {props["children"]}
        </button>;
}

def:pub buttonVariants -> any {
    return _buttonVariants;
}
