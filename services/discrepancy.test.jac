test "fairly billed line item is not flagged" {
    fair_price = get_price("99213", state="CA", locality="18").selected_payment as float;
    items: list[LineItem] = [
        LineItem(code="99213", billed_amount=fair_price),
    ];
    audit = analyze_bill(items, state="CA", locality="18");

    assert audit.flagged_count == 0;
    assert len(audit.discrepancies) == 1;
    assert not audit.discrepancies[0].flagged;
    assert audit.discrepancies[0].benchmark_source.startswith("MPFS");
}

test "overcharged line item is flagged with the benchmark cited" {
    benchmark = get_price("99213", state="CA", locality="18").selected_payment as float;
    items: list[LineItem] = [
        LineItem(code="99213", billed_amount=benchmark * 5.0),
    ];
    audit = analyze_bill(items, state="CA", locality="18");

    disc = audit.discrepancies[0];
    assert audit.flagged_count == 1;
    assert disc.flagged;
    assert not disc.is_duplicate;
    assert disc.benchmark_amount == benchmark;
    assert disc.overcharge_amount is not None;
    assert (disc.overcharge_amount as float) > 0.0;
    assert disc.overcharge_pct is not None;
    assert abs((disc.overcharge_pct as float) - 400.0) < 0.01, f"expected ~400% (billed is 5x benchmark), got {disc.overcharge_pct}";
}

test "duplicate line items are flagged as possible duplicate billing" {
    items: list[LineItem] = [
        LineItem(code="99213", billed_amount=100.0, service_date="2026-01-05"),
        LineItem(code="99213", billed_amount=100.0, service_date="2026-01-05"),
    ];
    audit = analyze_bill(items, state="CA", locality="18");

    assert audit.discrepancies[0].is_duplicate;
    assert audit.discrepancies[1].is_duplicate;
    assert audit.flagged_count == 2;
}

test "unresolvable code is flagged instead of silently priced at zero" {
    items: list[LineItem] = [
        LineItem(code="00000", billed_amount=250.0),
    ];
    audit = analyze_bill(items, state="CA", locality="18");

    disc = audit.discrepancies[0];
    assert disc.flagged;
    assert disc.benchmark_amount is None;
    assert disc.flag_reason != "";
}

test "lab code benchmarks against CLFS, not the zero-RVU MPFS row" {
    lab_rate = get_lab_price("80048").rate as float;
    items: list[LineItem] = [
        LineItem(code="80048", billed_amount=lab_rate),
    ];
    audit = analyze_bill(items, state="CA", locality="18");

    disc = audit.discrepancies[0];
    assert disc.benchmark_source == "CLFS";
    assert not disc.flagged;
}

test "totals on the audit add up across a mixed bill" {
    benchmark = get_price("99213", state="CA", locality="18").selected_payment as float;
    items: list[LineItem] = [
        LineItem(code="99213", billed_amount=benchmark),
        LineItem(code="99213", billed_amount=benchmark * 3.0, service_date="2026-01-06"),
    ];
    audit = analyze_bill(items, state="CA", locality="18");

    assert audit.total_billed == benchmark + (benchmark * 3.0);
    assert audit.total_benchmark == benchmark * 2.0;
    assert audit.total_overcharge == audit.total_billed - audit.total_benchmark;
}

test "line item with no extracted code is flagged instead of guessed at" {
    items: list[LineItem] = [
        LineItem(code="", description="illegible charge"),
    ];
    audit = analyze_bill(items, state="CA", locality="18");

    disc = audit.discrepancies[0];
    assert disc.flagged;
    assert disc.benchmark_amount is None;
    assert "No CPT/HCPCS code" in disc.flag_reason;
}

test "line item with no billed amount is flagged instead of silently counted as zero" {
    items: list[LineItem] = [
        LineItem(code="99213", billed_amount=None),
    ];
    audit = analyze_bill(items, state="CA", locality="18");

    disc = audit.discrepancies[0];
    assert disc.flagged;
    assert disc.billed_amount == 0.0;
    assert "No billed amount" in disc.flag_reason;
    assert audit.total_billed == 0.0;
}
