test "_discrepancy_type_for prioritizes duplicate over overcharge" {
    d = LineDiscrepancy(
        hcpcs="99213", is_duplicate=True, flagged=True,
        benchmark_amount=100.0, overcharge_amount=50.0,
    );
    assert _discrepancy_type_for(d) == "duplicate";
}

test "_discrepancy_type_for prioritizes code mismatch over overcharge" {
    d = LineDiscrepancy(
        hcpcs="99213", code_mismatch=True, flagged=True,
        benchmark_amount=100.0, overcharge_amount=50.0,
    );
    assert _discrepancy_type_for(d) == "mismatched_code";
}

test "_discrepancy_type_for reports overcharge when nothing else is set" {
    d = LineDiscrepancy(hcpcs="99213", flagged=True, benchmark_amount=100.0, overcharge_amount=50.0);
    assert _discrepancy_type_for(d) == "overcharge";
}

test "_discrepancy_type_for reports unresolved when there is no benchmark" {
    d = LineDiscrepancy(hcpcs="", flagged=True, benchmark_amount=None);
    assert _discrepancy_type_for(d) == "unresolved";
}

test "_discrepancy_type_for reports none for an unflagged line" {
    d = LineDiscrepancy(hcpcs="99213", flagged=False, benchmark_amount=100.0);
    assert _discrepancy_type_for(d) == "none";
}

test "_lead_argument_for picks the flagged line with the biggest overcharge" {
    audit = BillAudit(
        flagged_count=2,
        discrepancies=[
            LineDiscrepancy(hcpcs="A", flagged=True, overcharge_amount=50.0, flag_reason="small overcharge"),
            LineDiscrepancy(hcpcs="B", flagged=True, overcharge_amount=500.0, flag_reason="big overcharge"),
        ],
    );
    assert _lead_argument_for(audit) == "big overcharge";
}

test "_lead_argument_for falls back to a summary when nothing is flagged" {
    audit = BillAudit(
        flagged_count=0,
        total_overcharge=0.0,
        discrepancies=[LineDiscrepancy(hcpcs="A", flagged=False)],
    );
    summary = _lead_argument_for(audit);
    assert "0 of 1" in summary;
}

test "_build_case_bundle_from_audit maps discrepancies into line item bundles" {
    audit = BillAudit(
        total_billed=500.0, total_benchmark=100.0, total_overcharge=400.0,
        flagged_count=1,
        discrepancies=[
            LineDiscrepancy(
                hcpcs="99213", description="Office visit", billed_amount=500.0,
                benchmark_amount=100.0, overcharge_amount=400.0, flagged=True,
                flag_reason="Billed $500.00 vs Medicare-approved $100.00",
            ),
        ],
    );
    bundle = _build_case_bundle_from_audit("Test Hospital", "Jane Doe", audit);

    assert bundle.provider_name == "Test Hospital";
    assert bundle.patient_name == "Jane Doe";
    assert bundle.strategist_angle == "Billed $500.00 vs Medicare-approved $100.00";
    assert len(bundle.items) == 1;
    item = bundle.items[0];
    assert item.code == "99213";
    assert item.charged_amount == 500.0;
    assert item.medicare_rate == 100.0;
    assert item.discrepancy_type == "overcharge";
    assert item.discrepancy_amount == 400.0;
}

test "StartNegotiationFromAudit persists a Case and LineItems from a real audit" {
    audit = BillAudit(
        total_billed=500.0, total_benchmark=100.0, total_overcharge=400.0,
        flagged_count=1,
        discrepancies=[
            LineDiscrepancy(
                hcpcs="99213", description="Office visit", billed_amount=500.0,
                benchmark_amount=100.0, overcharge_amount=400.0, flagged=True,
                flag_reason="Billed $500.00 vs Medicare-approved $100.00",
            ),
        ],
    );
    result = root spawn StartNegotiationFromAudit(
        provider_name="Test Hospital", patient_name="Jane Doe", audit=audit
    );
    assert len(result.reports) == 1;
    view = result.reports[0];
    assert view.provider_name == "Test Hospital";
    assert view.patient_name == "Jane Doe";
    assert view.original_total == 500.0;
    assert view.disputed_total == 100.0;
    assert len(view.line_items) == 1;
    assert view.line_items[0].code == "99213";
    assert len(view.messages) == 1;
}
