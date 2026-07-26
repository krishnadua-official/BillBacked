test "demo negotiation case is safe and bounded" {
    case_data = get_demo_negotiation_case();
    assert case_data.is_demo;
    assert case_data.patient_name == "Alex Morgan";
    assert case_data.invoice_number == "BB-1042";
    assert case_data.original_balance == 8400.0;
    assert case_data.target_amount == 3500.0;
    assert case_data.maximum_authorized_amount == 4200.0;
    assert case_data.target_amount <= case_data.maximum_authorized_amount;
}


test "outbound call rejects a non-E164 destination before contacting ElevenLabs" {
    result = start_demo_negotiation_call("415 555 0100");
    assert not result.success;
    assert result.status == "invalid_destination";
    assert result.conversation_id == "";
}
