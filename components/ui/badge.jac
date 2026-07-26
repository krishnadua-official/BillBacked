import from "class-variance-authority" { cva }
import from "radix-ui" { Slot }
import from ...lib.utils { cn }

glob _badgeVariants: any = cva(
         "group/badge inline-flex h-5 w-fit shrink-0 items-center justify-center gap-1 overflow-hidden whitespace-nowrap rounded-full border border-transparent px-2 py-0.5 text-xs font-medium transition-colors has-data-[icon=inline-end]:pr-1.5 has-data-[icon=inline-start]:pl-1.5 [&>svg]:pointer-events-none [&>svg]:size-3! focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 aria-invalid:border-destructive aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40",
         {
             "variants": {
                 "variant": {
                     "default": "bg-primary text-primary-foreground [a]:hover:bg-primary/80",
                     "secondary": "bg-secondary text-secondary-foreground [a]:hover:bg-secondary/80",
                     "success": "border-success-border bg-success-background text-success",
                     "destructive": "bg-destructive/10 text-destructive [a]:hover:bg-destructive/20 focus-visible:ring-destructive/20 dark:bg-destructive/20 dark:focus-visible:ring-destructive/40",
                     "outline": "border-border text-foreground [a]:hover:bg-muted [a]:hover:text-muted-foreground",
                     "ghost": "hover:bg-muted hover:text-muted-foreground dark:hover:bg-muted/50",
                     "link": "text-primary underline-offset-4 hover:underline",
                     "glass": "h-8 border-white/30 bg-white/15 px-3 text-sm text-white backdrop-blur-md"
                 }
             },
             "defaultVariants": {"variant": "default"}
         }
     );

def:pub Badge(props: any) -> JsxElement {
    attrs: dict[str, any] = {** props};
    variant = props["variant"] or "default";
    asChild = props["asChild"] or False;

    variantsFn = _badgeVariants;
    computedClass = cn(variantsFn.call(None, {"variant": variant}), props["className"]);

    if asChild {
        return
            <Slot.Root
                {**props}
                data-slot="badge"
                data-variant={variant}
                className={computedClass}
            />;
    }

    return
        <span
            {**attrs}
            data-slot="badge"
            data-variant={variant}
            className={computedClass}
        />;
}

def:pub badgeVariants -> any {
    return _badgeVariants;
}
