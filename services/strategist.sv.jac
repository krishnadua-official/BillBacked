"""Agent 3 -- Strategist (BOILERPLATE, expect this to change).

Takes Agent 2's BillAudit and decides which flagged discrepancies to lead
a dispute with, and in what order. Placeholder logic for now: rank by raw
dollar overcharge, descending. Swap in real prioritization later --
confidence in the benchmark match, how clear-cut the code mismatch is,
which angle actually moves a biller, etc.

build_strategy() is deterministic (same shape as analyze_bill in
services/discrepancy.sv.jac -- fast, free, exact). choose_dispute_angle()
is an LLM stub for the "decide the strongest angle" judgment call the
original pitch called out; it is UNTESTED boilerplate, not a real prompt
yet -- fill in real reasoning (which discrepancy to lead with and why,
citing specific dollar amounts/codes) before relying on it.
"""

import from services.discrepancy { BillAudit, LineDiscrepancy }

glob DEFAULT_TOP_N: int = 5;


obj PrioritizedDiscrepancy {
    has discrepancy: LineDiscrepancy;
    has rank: int = 0;
    has priority_score: float = 0.0;
}


obj DisputeStrategy {
    has prioritized: list[PrioritizedDiscrepancy] = [];
    has lead_argument: str = "";
    has total_disputed_amount: float = 0.0;
}


def _impact(d: LineDiscrepancy) -> float {
    return d.overcharge_amount if d.overcharge_amount is not None else 0.0;
}


"""Rank a bill's flagged discrepancies by dollar impact and pick a lead.

PLACEHOLDER: ranks purely by overcharge_amount, descending -- a duplicate
or unresolved-code flag with no benchmark still ranks last even if it's
the strongest legal angle. Real prioritization (confidence, angle
strength, policy citations) belongs here later.
"""
def:pub build_strategy(audit: BillAudit, top_n: int = DEFAULT_TOP_N) -> DisputeStrategy {
    flagged: list[LineDiscrepancy] = [d for d in audit.discrepancies if d.flagged];
    flagged.sort(key=_impact, reverse=True);

    prioritized: list[PrioritizedDiscrepancy] = [];
    total: float = 0.0;
    rank: int = 1;
    for d in flagged[:top_n] {
        impact: float = _impact(d);
        total += impact;
        prioritized.append(PrioritizedDiscrepancy(discrepancy=d, rank=rank, priority_score=impact));
        rank += 1;
    }

    lead: str = "";
    if len(prioritized) > 0 {
        lead = prioritized[0].discrepancy.flag_reason;
    }

    return DisputeStrategy(
        prioritized=prioritized,
        lead_argument=lead,
        total_disputed_amount=total,
    );
}


"""LLM stub -- decide the strongest angle to open a dispute with, given an
already-built DisputeStrategy. Not implemented for real yet: returns
whatever the model says with no grounding, no tools, no verification.
Replace before using this for anything real.
"""
def:pub choose_dispute_angle(strategy: DisputeStrategy) -> str by llm(temperature=0.3);
sem choose_dispute_angle = "TODO(strategist boilerplate): Decide the strongest opening angle for a Medicare bill dispute, given a prioritized list of billing discrepancies. Placeholder only -- replace with real reasoning grounded in the actual discrepancy data (dollar amounts, codes, CMS benchmark sources) before relying on this.";
sem choose_dispute_angle.strategy = "The prioritized discrepancies and totals to build an opening argument from.";
