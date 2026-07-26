def _msn() -> StructuredDocument {
    return StructuredDocument(
        case_id="BB-20260726-TEST01",
        document_type=DocumentType.MSN,
        care_type="OUTPATIENT",
        patient_name="Jane Doe",
        provider_name="Sunrise Regional Medical Center",
        total_billed=340.00,
        total_patient_owed=87.05,
        line_items=[
            LineItem(
                description="Office visit, established patient (level 3)",
                service_date="2026-01-05", code="99213",
                billed_amount=340.00, allowed_amount=87.05,
            ),
        ],
    );
}

test "no bills exist before one is saved" {
    assert my_bills() == [];
}

test "saving extracted documents persists a Bill with its line items" {
    result = root spawn SaveExtractedBills(documents=[_msn()]);

    assert len(result.reports) == 1;
    saved = result.reports[0] as BillView;
    assert saved.provider_name == "Sunrise Regional Medical Center";
    assert saved.document_type == DocumentType.MSN;
    assert len(saved.line_items) == 1;
    assert saved.line_items[0].code == "99213";
    assert saved.line_items[0].billed_amount == 340.00;

    fetched = get_bill(saved.id);
    assert fetched is not None;
    assert (fetched as BillView).case_id == "BB-20260726-TEST01";
}

test "each upload creates a new Bill instead of updating a previous one" {
    root spawn SaveExtractedBills(documents=[_msn()]);
    root spawn SaveExtractedBills(documents=[_msn()]);

    all_bills = my_bills();
    assert len(all_bills) >= 2, "two separate uploads should produce two separate bills";
}

test "saving multiple documents in one call creates one Bill per document" {
    doc_a = _msn();
    doc_b = StructuredDocument(
        document_type=DocumentType.PROVIDER_BILL,
        provider_name="Sunrise Regional Medical Center",
        line_items=[],
    );

    result = root spawn SaveExtractedBills(documents=[doc_a, doc_b]);

    assert len(result.reports) == 2;
}

test "saving an empty document list reports nothing" {
    result = root spawn SaveExtractedBills(documents=[]);
    assert result.reports == [];
}
