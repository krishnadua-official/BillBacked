test "build_strategy ranks flagged discrepancies by dollar impact, descending" {
    audit = BillAudit(
        discrepancies=[
            LineDiscrepancy(hcpcs="A", flagged=True, overcharge_amount=50.0, flag_reason="small overcharge"),
            LineDiscrepancy(hcpcs="B", flagged=True, overcharge_amount=500.0, flag_reason="big overcharge"),
            LineDiscrepancy(hcpcs="C", flagged=False, overcharge_amount=1000.0, flag_reason=""),
        ],
    );

    strategy = build_strategy(audit);

    assert len(strategy.prioritized) == 2;
    assert strategy.prioritized[0].discrepancy.hcpcs == "B";
    assert strategy.prioritized[0].rank == 1;
    assert strategy.prioritized[1].discrepancy.hcpcs == "A";
    assert strategy.lead_argument == "big overcharge";
    assert strategy.total_disputed_amount == 550.0;
}

test "build_strategy respects top_n" {
    audit = BillAudit(
        discrepancies=[
            LineDiscrepancy(hcpcs="A", flagged=True, overcharge_amount=10.0),
            LineDiscrepancy(hcpcs="B", flagged=True, overcharge_amount=20.0),
            LineDiscrepancy(hcpcs="C", flagged=True, overcharge_amount=30.0),
        ],
    );

    strategy = build_strategy(audit, top_n=2);

    assert len(strategy.prioritized) == 2;
    assert strategy.prioritized[0].discrepancy.hcpcs == "C";
    assert strategy.prioritized[1].discrepancy.hcpcs == "B";
}

test "build_strategy on a clean bill with no flags returns an empty strategy" {
    audit = BillAudit(
        discrepancies=[
            LineDiscrepancy(hcpcs="A", flagged=False),
        ],
    );

    strategy = build_strategy(audit);

    assert len(strategy.prioritized) == 0;
    assert strategy.lead_argument == "";
    assert strategy.total_disputed_amount == 0.0;
}
