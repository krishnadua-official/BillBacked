"""Real-call tests -- deliberately NOT using MockLLM here.

A prior version of this file declared `glob llm = MockLLM(...)` to mock
structure_document. That override does not stay scoped to `jac test`: this
Jac version's build cache is keyed only on the base module's own file hash,
so the mocked compile unit kept being reused by `jac start` too -- the live
server silently returned canned test data for every upload until the cache
was cleared. These tests call the real configured model (GOOGLE_API_KEY)
instead, so there is nothing here that can leak a fake result into serving.
"""

def _print_doc(label: str, doc: StructuredDocument) -> None {
    print(f"\n--- {label} ---");
    print(f"patient_name:        {doc.patient_name}");
    print(f"provider_name:       {doc.provider_name}");
    print(f"document_type:       {doc.document_type}");
    print(f"care_type:           {doc.care_type}");
    print(f"claim_number:        {doc.claim_number}");
    print(f"service_date_from:   {doc.service_date_from}");
    print(f"service_date_to:     {doc.service_date_to}");
    print(f"total_billed:        {doc.total_billed}");
    print(f"total_patient_owed:  {doc.total_patient_owed}");
    print(f"total_paid:          {doc.total_paid}");
    print(f"review_flags:        {doc.review_flags}");
    print(f"line_items ({len(doc.line_items)}):");
    for item in doc.line_items {
        print(f"  - {item.description} | date={item.service_date} code={item.code} "
              f"billed={item.billed_amount} allowed={item.allowed_amount} "
              f"paid={item.paid_amount} owed={item.patient_owed}");
    }
}


test "extract_and_structure produces a plausible result from a real sample EOB" {
    with open("Sample Data/patient-01-margaret-chen/eob.pdf", "rb") as f {
        data: bytes = f.read();
    }
    doc = extract_and_structure(data, "application/pdf", "eob.pdf");
    _print_doc("patient-01-margaret-chen/eob.pdf", doc);
    assert doc.patient_name != "", "expected a patient name to be extracted";
    assert doc.provider_name != "", "expected a provider name to be extracted";
    assert doc.document_type == DocumentType.EOB;
    assert len(doc.line_items) > 0, "expected at least one line item";
    assert doc.line_items[0].billed_amount is not None or doc.line_items[0].allowed_amount is not None;
}

test "extract_and_structure handles a different patient's ER bill distinctly" {
    with open("Sample Data/patient-03-rosa-martinez/eob.pdf", "rb") as f {
        data: bytes = f.read();
    }
    doc = extract_and_structure(data, "application/pdf", "eob.pdf");
    _print_doc("patient-03-rosa-martinez/eob.pdf", doc);
    assert doc.patient_name != "";
    assert len(doc.line_items) > 1, "this bill has multiple ER line items";
    assert doc.total_patient_owed is not None;
}

test "every upload gets its own case_id, distinct across uploads" {
    with open("Sample Data/patient-01-margaret-chen/eob.pdf", "rb") as f {
        data: bytes = f.read();
    }
    first = extract_and_structure(data, "application/pdf", "eob.pdf");
    second = extract_and_structure(data, "application/pdf", "eob.pdf");
    assert first.case_id != "", "expected a case_id to be assigned on upload";
    assert first.case_id.startswith("BB-"), "expected the BB- case number prefix";
    assert first.case_id != second.case_id, "each upload should get its own case_id";
}
