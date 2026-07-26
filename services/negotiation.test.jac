test "demo negotiation case stays safe within bounds" {
    case_data = get_demo_negotiation_case();
    assert case_data.is_demo;
    assert case_data.user_name == "Alex Morgan";
    assert case_data.patient_name == "Alex Morgan";
    assert case_data.invoice_number == "BB-1042";
    assert case_data.original_balance == 8400.0;
    assert case_data.target_amount == 3500.0;
    assert case_data.maximum_authorized_amount == 4200.0;
    assert case_data.target_amount <= case_data.maximum_authorized_amount;
}


test "an existing audit becomes a complete negotiation call case" {
    documents: list[StructuredDocument] = [
        StructuredDocument(
            case_id="case-audit-42",
            patient_name="",
            provider_name="",
            claim_number=""
        ),
        StructuredDocument(
            case_id="case-audit-42",
            patient_name="Morgan, Alex",
            provider_name="Example General Hospital",
            claim_number="CLAIM-1042"
        ),
    ];
    audit = BillAudit(
        total_billed=8400.0,
        total_benchmark=3100.0,
        total_overcharge=5300.0,
        flagged_count=1,
        discrepancies=[
            LineDiscrepancy(
                hcpcs="70553",
                description="MRI brain",
                billed_amount=1500.0,
                benchmark_amount=650.0,
                overcharge_amount=850.0,
                flagged=True,
                flag_reason="Possible duplicate imaging charge."
            )
        ]
    );

    case_data = _build_case_from_audit("", documents, audit);

    assert not case_data.is_demo;
    assert case_data.case_id == "case-audit-42";
    assert case_data.user_name == "Morgan, Alex";
    assert case_data.patient_name == "Morgan, Alex";
    assert case_data.provider_name == "Example General Hospital";
    assert case_data.invoice_number == "CLAIM-1042";
    assert case_data.original_balance == 8400.0;
    assert case_data.reference_amount == 3100.0;
    assert case_data.target_amount == 3100.0;
    assert case_data.maximum_authorized_amount == 3100.0;
    assert len(case_data.disputed_items) == 1;
    assert "MRI brain" in case_data.disputed_items[0];
    assert "Possible duplicate imaging charge" in case_data.disputed_items[0];
}


test "outbound call passes complete case context while preserving ElevenLabs presentation" {
    case_data = get_demo_negotiation_case();
    initiation_data = _build_conversation_initiation_data(case_data);
    overrides = (
        initiation_data["conversation_config_override"] as dict[str, any]
    );
    agent_override = overrides["agent"] as dict[str, any];
    prompt_override = agent_override["prompt"] as dict[str, any];
    dynamic_variables = initiation_data["dynamic_variables"] as dict[str, any];

    assert "first_message" not in agent_override;
    assert "language" not in agent_override;
    assert "tts" not in overrides;
    prompt = prompt_override["prompt"] as str;
    assert case_data.provider_name in prompt;
    assert "You are Ava" not in prompt;
    assert dynamic_variables["case_id"] == case_data.case_id;
    assert dynamic_variables["user_name"] == case_data.user_name;
    assert dynamic_variables["patient_name"] == case_data.patient_name;
    assert dynamic_variables["provider_name"] == case_data.provider_name;
    assert dynamic_variables["invoice_number"] == case_data.invoice_number;
    assert dynamic_variables["original_balance"] == case_data.original_balance;
    assert dynamic_variables["original_balance_display"] == "$8,400.00";
    assert dynamic_variables["reference_amount"] == case_data.reference_amount;
    assert dynamic_variables["reference_amount_display"] == "$3,100.00";
    assert dynamic_variables["target_amount"] == case_data.target_amount;
    assert dynamic_variables["target_amount_display"] == "$3,500.00";
    assert (
        dynamic_variables["maximum_authorized_amount"]
        == case_data.maximum_authorized_amount
    );
    assert dynamic_variables["maximum_authorized_amount_display"] == "$4,200.00";
    assert dynamic_variables["disputed_items_summary"] == (
        "; ".join(case_data.disputed_items)
    );
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
