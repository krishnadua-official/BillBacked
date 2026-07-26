test "known CPT code prices in a facility locality" {
    result = get_price("99213", state="CA", locality="18");
    assert result.error is None, f"unexpected error: {result.error}";
    assert result.found;
    assert result.state == "CA";
    assert result.locality == "18";
    assert result.non_facility_payment is not None;
    assert result.selected_payment is not None;
    assert (result.selected_payment as float) > 0.0;
}

test "anesthesia code takes the anesthesia CF path, not the RVU formula" {
    result = get_price("00100", state="CA", locality="18");
    assert result.error is None, f"unexpected error: {result.error}";
    assert result.is_anesthesia;
    assert result.anesthesia_conversion_factor is not None;
    assert result.non_facility_payment is None;
}

test "unknown HCPCS code reports an error instead of raising" {
    result = get_price("00000", state="CA", locality="18");
    assert not result.found;
    assert result.error is not None;
}

test "missing locality reports an error instead of raising" {
    result = get_price("99213");
    assert not result.found;
    assert result.error is not None;
}

test "list_localities finds Los Angeles under CA" {
    localities = list_localities("CA");
    assert len(localities) > 0;
    names = [loc.locality_name for loc in localities if loc.locality == "18"];
    assert len(names) == 1;
}

test "nationally-priced lab code returns a rate" {
    result = get_lab_price("80048");
    assert result.error is None, f"unexpected error: {result.error}";
    assert result.found;
    assert result.nationally_priced;
    assert result.rate is not None;
    assert (result.rate as float) > 0.0;
}

test "carrier-priced lab code reports an error instead of a rate" {
    result = get_lab_price("0526U");
    assert result.found;
    assert not result.nationally_priced;
    assert result.rate is None;
    assert result.error is not None;
}

test "unknown lab code reports an error instead of raising" {
    result = get_lab_price("99999Z");
    assert not result.found;
    assert result.error is not None;
}

test "county name resolves to the same locality as state+locality" {
    by_county = get_price("99213", county="Los Angeles", state="CA");
    by_locality = get_price("99213", state="CA", locality="18");
    assert by_county.error is None, f"unexpected error: {by_county.error}";
    assert by_county.locality == "18";
    assert by_county.selected_payment == by_locality.selected_payment;
}

test "lab price lookup accepts an explicit modifier" {
    result = get_lab_price("80048", mod="QW");
    assert result.error is None, f"unexpected error: {result.error}";
    assert result.found;
    assert result.rate is not None;
}
