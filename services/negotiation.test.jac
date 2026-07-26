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


test "outbound call destination is required on the server" {
    previous_destination = os.environ.pop(
        "TWILIO_VERIFIED_DESTINATION_NUMBER",
        None
    );
    result = start_demo_negotiation_call();
    if previous_destination is not None {
        os.environ["TWILIO_VERIFIED_DESTINATION_NUMBER"] = previous_destination;
    }
    assert not result.success;
    assert result.status == "configuration_required";
    assert "TWILIO_VERIFIED_DESTINATION_NUMBER" in result.message;
    assert result.conversation_id == "";
}


test "conversation statuses map to product call states" {
    active = _call_status_result("conv_test", "in-progress");
    assert active.success;
    assert active.status == "in_progress";

    processing = _call_status_result("conv_test", "processing");
    assert processing.success;
    assert processing.status == "processing";

    completed = _call_status_result("conv_test", "done");
    assert completed.success;
    assert completed.status == "completed";

    failed = _call_status_result("conv_test", "failed");
    assert not failed.success;
    assert failed.status == "failed";
}
