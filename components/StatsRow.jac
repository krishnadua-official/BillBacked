"""KPI cards across the top of the dashboard."""

import from ".ui.card" { Card, CardDescription, CardHeader, CardTitle }
import from ".ui.skeleton" { Skeleton }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    CheckmarkCircle02Icon, StickyNote01Icon, Task01Icon
}

sv import from ..services.notes { Stats }


def:pub StatCard(label: str, value: int, icon: any, hint: str) -> JsxElement {
    return <Card>
        <CardHeader>
            <div className="flex items-center justify-between">
                <CardDescription>{label}</CardDescription>
                <HugeiconsIcon
                    icon={icon}
                    strokeWidth={2}
                    className="size-4 text-muted-foreground"
                />
            </div>
            <CardTitle className="text-3xl font-semibold tabular-nums">{str(value)}</CardTitle>
            <p className="mt-2 text-sm text-muted-foreground">{hint}</p>
        </CardHeader>
    </Card>;
}


def:pub StatsRow(stats: Stats | None, loading: bool) -> JsxElement {
    if loading {
        return <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
            {for i in range(3) {
                <Card key={str(i)}>
                    <CardHeader>
                        <Skeleton className="h-4 w-24" />
                        <Skeleton className="mt-2 h-8 w-12" />
                        <Skeleton className="mt-2 h-4 w-32" />
                    </CardHeader>
                </Card>
            }}
        </div>;
    }

    total = stats.total if stats else 0;
    active = stats.active if stats else 0;
    completed = stats.completed if stats else 0;

    return <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
        <StatCard
            label="Total notes"
            value={total}
            icon={StickyNote01Icon}
            hint="Everything on your graph"
        />
        <StatCard
            label="Open"
            value={active}
            icon={Task01Icon}
            hint="Still to do"
        />
        <StatCard
            label="Done"
            value={completed}
            icon={CheckmarkCircle02Icon}
            hint="Checked off"
        />
    </div>;
}
