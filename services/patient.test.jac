test "no patient profile exists before one is saved" {
    fetched = my_patient();
    assert fetched is None;
}

test "save then read a patient profile" {
    result = root spawn SavePatientProfile(
        name="Jane Doe", state="CA", coverage_type=CoverageType.MEDICARE
    );
    assert len(result.reports) == 1;
    saved = result.reports[0] as PatientView;
    assert saved.name == "Jane Doe";
    assert saved.state == "CA";
    assert saved.coverage_type == CoverageType.MEDICARE;

    fetched = my_patient();
    assert fetched is not None;
    assert (fetched as PatientView).name == "Jane Doe";
}

test "saving again updates the same patient instead of creating a second one" {
    root spawn SavePatientProfile(name="Jane Doe", state="CA", coverage_type=CoverageType.MEDICARE);
    root spawn SavePatientProfile(name="Jane A. Doe", state="NY", coverage_type=CoverageType.PRIVATE_INSURANCE);

    assert len([root -->][?:Patient]) == 1;
    fetched = my_patient() as PatientView;
    assert fetched.name == "Jane A. Doe";
    assert fetched.state == "NY";
    assert fetched.coverage_type == CoverageType.PRIVATE_INSURANCE;
}
