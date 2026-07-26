import from ...lib.utils { cn }

def:pub Table(props: any) -> JsxElement {
    attrs: dict[str, any] = {** props};
    return
        <div data-slot="table-container" className="relative w-full overflow-x-auto">
            <table
                {**attrs}
                data-slot="table"
                className={cn("w-full caption-bottom border-separate border-spacing-0 text-[13px]", props["className"])}
            />
        </div>;
}

def:pub TableHeader(props: any) -> JsxElement {
    attrs: dict[str, any] = {** props};
    return
        <thead
            {**attrs}
            data-slot="table-header"
            className={cn("[&_tr]:border-0", props["className"])}
        />;
}

def:pub TableBody(props: any) -> JsxElement {
    attrs: dict[str, any] = {** props};
    return
        <tbody
            {**attrs}
            data-slot="table-body"
            className={cn("[&_tr:last-child>td]:border-b-0", props["className"])}
        />;
}

def:pub TableFooter(props: any) -> JsxElement {
    attrs: dict[str, any] = {** props};
    return
        <tfoot
            {**attrs}
            data-slot="table-footer"
            className={cn("bg-muted/50 border-t font-medium [&>tr]:last:border-b-0", props["className"])}
        />;
}

def:pub TableRow(props: any) -> JsxElement {
    attrs: dict[str, any] = {** props};
    return
        <tr
            {**attrs}
            data-slot="table-row"
            className={cn("group border-0 [&>td]:transition-colors [&:hover>td]:bg-gray-100 [&[data-state=selected]>td]:bg-gray-200", props["className"])}
        />;
}

def:pub TableHead(props: any) -> JsxElement {
    attrs: dict[str, any] = {** props};
    return
        <th
            {**attrs}
            data-slot="table-head"
            className={cn("h-9 border-b border-border px-3 text-left align-middle text-xs font-medium whitespace-nowrap text-table-header [&:has([role=checkbox])]:pr-0", props["className"])}
        />;
}

def:pub TableCell(props: any) -> JsxElement {
    attrs: dict[str, any] = {** props};
    return
        <td
            {**attrs}
            data-slot="table-cell"
            className={cn("h-11 border-b border-border px-3 py-2 align-middle whitespace-nowrap [&:has([role=checkbox])]:pr-0", props["className"])}
        />;
}

def:pub TableCaption(props: any) -> JsxElement {
    attrs: dict[str, any] = {** props};
    return
        <caption
            {**attrs}
            data-slot="table-caption"
            className={cn("text-muted-foreground mt-4 text-sm", props["className"])}
        />;
}
