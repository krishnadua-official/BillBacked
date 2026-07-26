"""Medicare Physician Fee Schedule (MPFS) pricer, CY2026 January release.

Ported from medicare_pricer.py (CLI script under /pricing) so Agent 2 (the
Discrepancy Engine) can call get_price() in-process instead of shelling out.
Same formula, same CMS source files, but errors come back on the result
object instead of being printed, and each CSV is parsed once and cached in
a glob for the life of the server instead of being re-read per call.

Formula:
    Total RVU = (Work RVU x Work GPCI) + (PE RVU x PE GPCI) + (MP RVU x MP GPCI)
    Payment   = Total RVU x Conversion Factor
"""

import pandas as pd;


glob US_STATES: dict[str, str] = {
    "AL": "ALABAMA", "AK": "ALASKA", "AZ": "ARIZONA", "AR": "ARKANSAS",
    "CA": "CALIFORNIA", "CO": "COLORADO", "CT": "CONNECTICUT", "DE": "DELAWARE",
    "DC": "DISTRICT OF COLUMBIA", "FL": "FLORIDA", "GA": "GEORGIA", "HI": "HAWAII",
    "ID": "IDAHO", "IL": "ILLINOIS", "IN": "INDIANA", "IA": "IOWA", "KS": "KANSAS",
    "KY": "KENTUCKY", "LA": "LOUISIANA", "ME": "MAINE", "MD": "MARYLAND",
    "MA": "MASSACHUSETTS", "MI": "MICHIGAN", "MN": "MINNESOTA", "MS": "MISSISSIPPI",
    "MO": "MISSOURI", "MT": "MONTANA", "NE": "NEBRASKA", "NV": "NEVADA",
    "NH": "NEW HAMPSHIRE", "NJ": "NEW JERSEY", "NM": "NEW MEXICO", "NY": "NEW YORK",
    "NC": "NORTH CAROLINA", "ND": "NORTH DAKOTA", "OH": "OHIO", "OK": "OKLAHOMA",
    "OR": "OREGON", "PA": "PENNSYLVANIA", "RI": "RHODE ISLAND", "SC": "SOUTH CAROLINA",
    "SD": "SOUTH DAKOTA", "TN": "TENNESSEE", "TX": "TEXAS", "UT": "UTAH",
    "VT": "VERMONT", "VA": "VIRGINIA", "WA": "WASHINGTON", "WV": "WEST VIRGINIA",
    "WI": "WISCONSIN", "WY": "WYOMING", "PR": "PUERTO RICO", "VI": "VIRGIN ISLANDS",
};

glob RVU_COLS: list[str] = [
    "HCPCS", "MOD", "DESCRIPTION", "STATUS", "UNUSED", "WORK_RVU",
    "NONFAC_PE_RVU", "NONFAC_NA_IND", "FAC_PE_RVU", "FAC_NA_IND", "MP_RVU",
    "NONFAC_TOTAL", "FAC_TOTAL", "PCTC_IND", "GLOBAL_DAYS", "PRE_OP",
    "INTRA_OP", "POST_OP", "MULT_PROC", "BILAT_SURG", "ASST_SURG",
    "CO_SURG", "TEAM_SURG", "PRIC_IND", "ENDO_BASE", "CONV_FACTOR",
    "SUPERVISION_IND", "CALC_FLAG", "IMAGING_FAMILY_IND",
    "NONFAC_OPPS_AMT", "FAC_OPPS_AMT", "MP_OPPS_AMT",
];

glob DATA_DIR: str = "pricing";

glob _rvu_cache: dict[str, any] = {};
glob _gpci_cache: any = None;
glob _oppscap_cache: any = None;
glob _loc_cache: any = None;
glob _anes_cache: any = None;
glob _clfs_cache: any = None;


obj PriceResult {
    has hcpcs: str;
    has found: bool = False;
    has description: str = "";
    has status: str = "";
    has state: str = "";
    has locality: str = "";
    has locality_name: str = "";
    has qpp: bool = False;
    has conversion_factor: float = 0.0;
    has is_anesthesia: bool = False;
    has anesthesia_conversion_factor: float | None = None;
    has non_facility_rvu: float | None = None;
    has non_facility_payment: float | None = None;
    has facility_rvu: float | None = None;
    has facility_payment: float | None = None;
    has oppscap_applied: bool = False;
    has non_facility_cap: float | None = None;
    has facility_cap: float | None = None;
    has selected_site: str = "";
    has selected_payment: float | None = None;
    has error: str | None = None;
}


obj LocalityInfo {
    has state: str;
    has locality: str;
    has locality_name: str;
}


obj LabPriceResult {
    has hcpcs: str;
    has found: bool = False;
    has short_description: str = "";
    has long_description: str = "";
    has effective_date: str = "";
    has nationally_priced: bool = False;
    has rate: float | None = None;
    has error: str | None = None;
}


obj CodeMatch {
    has hcpcs: str;
    has description: str;
    has source: str;
    has match_score: int;
}


def _row_float(row: any, col: str) -> float {
    return float(row[col]);
}


def _row_str(row: any, col: str) -> str {
    return str(row[col]);
}


def _load_rvu(qpp: bool) -> any {
    key: str = "qpp" if qpp else "nonqpp";
    if key in _rvu_cache {
        return _rvu_cache[key];
    }
    fname: str = "PPRRVU2026_Jan_QPP.csv" if qpp else "PPRRVU2026_Jan_nonQPP.csv";
    df = pd.read_csv(f"{DATA_DIR}/{fname}", skiprows=10, header=None,
                      names=RVU_COLS, dtype=str);
    for c in ["WORK_RVU", "NONFAC_PE_RVU", "FAC_PE_RVU", "MP_RVU",
              "NONFAC_TOTAL", "FAC_TOTAL", "CONV_FACTOR"] {
        df[c] = pd.to_numeric(df[c], errors="coerce");
    }
    df["HCPCS"] = df["HCPCS"].str.strip();
    df["MOD"] = df["MOD"].fillna("").str.strip();
    _rvu_cache[key] = df;
    return df;
}


def _load_gpci() -> any {
    if _gpci_cache is None {
        g = pd.read_csv(f"{DATA_DIR}/GPCI2026.csv", skiprows=2, dtype=str);
        g.columns = [str(c).strip() for c in g.columns];
        g = g.rename(columns={
            "Medicare Administrative Contractor (MAC)": "MAC",
            "State": "STATE",
            "Locality Number": "LOCALITY",
            "Locality Name": "LOCALITY_NAME",
            "2026 PW GPCI (with 1.0 Floor)": "PW_GPCI",
            "2026 PE GPCI": "PE_GPCI",
            "2026 MP GPCI": "MP_GPCI",
        });
        for c in ["STATE", "LOCALITY", "LOCALITY_NAME", "MAC"] {
            g[c] = g[c].str.strip();
        }
        for c in ["PW_GPCI", "PE_GPCI", "MP_GPCI"] {
            g[c] = pd.to_numeric(g[c], errors="coerce");
        }
        _gpci_cache = g;
    }
    return _gpci_cache;
}


def _load_oppscap() -> any {
    if _oppscap_cache is None {
        o = pd.read_csv(f"{DATA_DIR}/OPPSCAP_Jan.csv", dtype=str);
        o.columns = [str(c).strip() for c in o.columns];
        o["HCPCS"] = o["HCPCS"].str.strip();
        o["LOCALITY"] = o["LOCALITY"].str.strip();
        o["CARRIER"] = o["CARRIER"].str.strip();
        o["FACILITY PRICE"] = pd.to_numeric(o["FACILITY PRICE"], errors="coerce");
        o["NON-FACILTY PRICE"] = pd.to_numeric(o["NON-FACILTY PRICE"], errors="coerce");
        _oppscap_cache = o;
    }
    return _oppscap_cache;
}


def _load_loc() -> any {
    if _loc_cache is None {
        loc_df = pd.read_csv(f"{DATA_DIR}/26LOCCO.csv", skiprows=2, dtype=str);
        loc_df.columns = [str(c).strip() for c in loc_df.columns];
        loc_df = loc_df.dropna(how="all");
        loc_df["Counties"] = loc_df["Counties"].str.strip();
        loc_df["Fee Schedule Area"] = loc_df["Fee Schedule Area"].str.strip();
        loc_df["State"] = loc_df["State"].str.strip();
        loc_df["Locality Number"] = loc_df["Locality Number"].str.strip();
        _loc_cache = loc_df;
    }
    return _loc_cache;
}


def _load_anes() -> any {
    if _anes_cache is None {
        anes = pd.read_csv(f"{DATA_DIR}/ANES2026.csv", dtype=str);
        anes.columns = [str(c).strip() for c in anes.columns];
        anes["Locality"] = anes["Locality"].str.strip();
        anes["Contractor"] = anes["Contractor"].str.strip();
        _anes_cache = anes;
    }
    return _anes_cache;
}


def _load_clfs() -> any {
    if _clfs_cache is None {
        df = pd.read_csv(f"{DATA_DIR}/PUF_CLFS_CY2026_Q3V1.csv", skiprows=3, dtype=str);
        df.columns = [str(c).strip() for c in df.columns];
        df["HCPCS"] = df["HCPCS"].str.strip().str.upper();
        df["MOD"] = df["MOD"].fillna("").str.strip();
        df["INDICATOR"] = df["INDICATOR"].str.strip();
        df["RATE"] = pd.to_numeric(df["RATE"], errors="coerce");
        _clfs_cache = df;
    }
    return _clfs_cache;
}


def _is_anesthesia_code(hcpcs: str) -> bool {
    prefix: str = hcpcs[:5];
    if not prefix.isdigit() {
        return False;
    }
    n: int = int(prefix);
    return 100 <= n <= 1999;
}


def _find_locality(gpci: any, state: str | None, locality: str | None,
                    locality_name: str | None) -> any {
    rows = gpci;
    if state {
        rows = rows[rows["STATE"].str.upper() == state.upper()];
    }
    if locality {
        rows = rows[rows["LOCALITY"] == locality.zfill(2)];
    }
    if locality_name {
        rows = rows[rows["LOCALITY_NAME"].str.contains(locality_name, case=False, na=False)];
    }
    return rows;
}


"""Look up what Medicare pays for a CPT/HCPCS code in a locality.

Resolve the locality with --state/--locality/--locality-name, or --county
(via 26LOCCO.csv). On any lookup failure PriceResult.error is set and the
other fields are left at their defaults -- callers should check `error`
before trusting `found`/`selected_payment`.
"""
def:pub get_price(
    hcpcs: str,
    state: str | None = None,
    locality: str | None = None,
    locality_name: str | None = None,
    county: str | None = None,
    qpp: bool = False,
    pos: str = "non-facility"
) -> PriceResult {
    code: str = hcpcs.strip();
    res_state: str | None = state;
    res_locality: str | None = locality;

    if county {
        loc_df = _load_loc();
        county_rows = loc_df[loc_df["Counties"].str.contains(county, case=False, na=False)
                              | loc_df["Fee Schedule Area"].str.contains(county, case=False, na=False)];
        if state {
            full_state: str = US_STATES.get(state.upper(), state.upper());
            county_rows = county_rows[county_rows["State"].str.upper() == full_state];
        }
        if county_rows.empty {
            detail: str = f"No county match for '{county}'";
            if state {
                detail = detail + f" in {state}";
            }
            return PriceResult(hcpcs=code, error=detail);
        }
        if len(county_rows) > 1 {
            names: list[str] = [_row_str(r, "Fee Schedule Area") for (_, r) in county_rows.iterrows()];
            return PriceResult(hcpcs=code, error=f"Multiple county matches, narrow with state: {', '.join(names)}");
        }
        row = county_rows.iloc[0];
        if not res_state {
            row_state: str = _row_str(row, "State");
            for (abbr, name) in US_STATES.items() {
                if name == row_state.upper() {
                    res_state = abbr;
                    break;
                }
            }
        }
        res_locality = _row_str(row, "Locality Number");
    }

    gpci = _load_gpci();
    locs = _find_locality(gpci, res_state, res_locality, locality_name);
    if locs.empty {
        return PriceResult(hcpcs=code, error="No matching locality found. Try list_localities(state) to browse.");
    }
    if len(locs) > 1 {
        names: list[str] = [f"{_row_str(r, 'STATE')} {_row_str(r, 'LOCALITY')} - {_row_str(r, 'LOCALITY_NAME')}"
                             for (_, r) in locs.iterrows()];
        return PriceResult(hcpcs=code, error=f"Multiple localities matched: {'; '.join(names)}");
    }
    loc_row = locs.iloc[0];

    rvu = _load_rvu(qpp);
    code_rows = rvu[(rvu["HCPCS"] == code) & (rvu["MOD"] == "")];
    if code_rows.empty {
        code_rows = rvu[rvu["HCPCS"] == code];
    }
    if code_rows.empty {
        return PriceResult(hcpcs=code, error=f"HCPCS/CPT code '{code}' not found in the RVU file.");
    }
    code_row = code_rows.iloc[0];

    result = PriceResult(
        hcpcs=code,
        found=True,
        description=_row_str(code_row, "DESCRIPTION"),
        status=_row_str(code_row, "STATUS"),
        state=_row_str(loc_row, "STATE"),
        locality=_row_str(loc_row, "LOCALITY"),
        locality_name=_row_str(loc_row, "LOCALITY_NAME"),
        qpp=qpp,
        conversion_factor=_row_float(code_row, "CONV_FACTOR"),
    );

    if _is_anesthesia_code(code) {
        anes = _load_anes();
        a_match = anes[(anes["Locality"] == _row_str(loc_row, "LOCALITY")) &
                        (anes["Contractor"] == _row_str(loc_row, "MAC"))];
        result.is_anesthesia = True;
        if not a_match.empty {
            cf_col = a_match.columns[3] if qpp else a_match.columns[4];
            result.anesthesia_conversion_factor = float(a_match.iloc[0][cf_col]);
        }
        return result;
    }

    work_rvu: float = _row_float(code_row, "WORK_RVU");
    nonfac_pe: float = _row_float(code_row, "NONFAC_PE_RVU");
    fac_pe: float = _row_float(code_row, "FAC_PE_RVU");
    mp_rvu: float = _row_float(code_row, "MP_RVU");
    conv_factor: float = _row_float(code_row, "CONV_FACTOR");

    if work_rvu == 0.0 and nonfac_pe == 0.0 and fac_pe == 0.0 {
        result.error = f"Status code '{result.status}' / zero RVUs -- this code is not priced by the standard formula (e.g. carrier-priced, bundled, or invalid).";
        return result;
    }

    pw_gpci: float = _row_float(loc_row, "PW_GPCI");
    pe_gpci: float = _row_float(loc_row, "PE_GPCI");
    mp_gpci: float = _row_float(loc_row, "MP_GPCI");

    nonfac_total_rvu: float = (work_rvu * pw_gpci) + (nonfac_pe * pe_gpci) + (mp_rvu * mp_gpci);
    nonfac_payment: float = nonfac_total_rvu * conv_factor;
    fac_total_rvu: float = (work_rvu * pw_gpci) + (fac_pe * pe_gpci) + (mp_rvu * mp_gpci);
    fac_payment: float = fac_total_rvu * conv_factor;

    result.non_facility_rvu = nonfac_total_rvu;
    result.non_facility_payment = nonfac_payment;
    result.facility_rvu = fac_total_rvu;
    result.facility_payment = fac_payment;

    oppscap = _load_oppscap();
    cap_rows = oppscap[(oppscap["HCPCS"] == code) &
                        (oppscap["CARRIER"] == _row_str(loc_row, "MAC")) &
                        (oppscap["LOCALITY"] == _row_str(loc_row, "LOCALITY"))];
    if not cap_rows.empty {
        cap = cap_rows.iloc[0];
        fac_cap: float = _row_float(cap, "FACILITY PRICE");
        nonfac_cap: float = _row_float(cap, "NON-FACILTY PRICE");
        result.oppscap_applied = True;
        result.facility_cap = fac_cap;
        result.non_facility_cap = nonfac_cap;
        result.facility_payment = min(fac_payment, fac_cap);
        result.non_facility_payment = min(nonfac_payment, nonfac_cap);
    }

    result.selected_site = pos if pos in ("facility", "non-facility") else "non-facility";
    result.selected_payment = result.facility_payment if result.selected_site == "facility" else result.non_facility_payment;

    return result;
}


"""List every GPCI locality for a state, e.g. to disambiguate get_price()."""
def:pub list_localities(state: str) -> list[LocalityInfo] {
    gpci = _load_gpci();
    rows = gpci[gpci["STATE"].str.upper() == state.upper()];
    out: list[LocalityInfo] = [];
    for (_, r) in rows.iterrows() {
        out.append(LocalityInfo(
            state=_row_str(r, "STATE"),
            locality=_row_str(r, "LOCALITY"),
            locality_name=_row_str(r, "LOCALITY_NAME"),
        ));
    }
    return out;
}


"""Look up the national Clinical Laboratory Fee Schedule (CLFS) rate for a
lab HCPCS code, e.g. 80048 (basic metabolic panel) or 0001U.

CLFS rates are national (no GPCI/locality math, unlike get_price()) except
for a small set of carrier/locally-priced codes -- those come back with
found=True but rate=None and an explanatory error, since this file has no
national amount for them.
"""
def:pub get_lab_price(hcpcs: str, mod: str = "") -> LabPriceResult {
    code: str = hcpcs.strip().upper();
    clfs = _load_clfs();

    rows = clfs[(clfs["HCPCS"] == code) & (clfs["MOD"] == mod)];
    if rows.empty {
        rows = clfs[clfs["HCPCS"] == code];
    }
    if rows.empty {
        return LabPriceResult(hcpcs=code, error=f"HCPCS/CPT code '{code}' not found in the CLFS lab fee schedule.");
    }
    row = rows.iloc[0];

    result = LabPriceResult(
        hcpcs=code,
        found=True,
        short_description=_row_str(row, "SHORTDESC"),
        long_description=_row_str(row, "LONGDESC"),
        effective_date=_row_str(row, "EFF_DATE"),
        nationally_priced=(_row_str(row, "INDICATOR") == "N"),
    );

    if result.nationally_priced {
        result.rate = _row_float(row, "RATE");
    } else {
        result.error = "This code is carrier/locally priced -- CLFS sets no national rate; check with the local MAC for the payable amount.";
    }

    return result;
}


"""Search both fee schedules by free-text description when a line item has
no usable HCPCS/CPT code -- e.g. a bill that only says "office visit" or
"basic metabolic panel" with the code missing, illegible, or clearly wrong.

Scores each candidate by how many query words (3+ letters, to skip noise
like "of"/"the") appear in its CMS description, checks the physician fee
schedule (MPFS) and the lab fee schedule (CLFS), and returns the top
`limit` matches sorted best-first. Callers should re-price a candidate's
hcpcs with get_price/get_lab_price before treating it as the benchmark --
this only narrows down candidates, it doesn't price anything itself.
"""
def:pub search_by_description(query: str, limit: int = 5) -> list[CodeMatch] {
    words: list[str] = [w for w in query.lower().split() if len(w) > 2];
    if len(words) == 0 {
        return [];
    }
    first_word: str = words[0];

    matches: list[CodeMatch] = [];

    rvu = _load_rvu(False);
    rvu_candidates = rvu[rvu["DESCRIPTION"].str.lower().str.contains(first_word, regex=False, na=False)];
    for (_, row) in rvu_candidates.iterrows() {
        desc: str = _row_str(row, "DESCRIPTION").lower();
        score: int = 0;
        for w in words {
            if w in desc {
                score += 1;
            }
        }
        if score > 0 {
            matches.append(CodeMatch(
                hcpcs=_row_str(row, "HCPCS"),
                description=_row_str(row, "DESCRIPTION"),
                source="MPFS",
                match_score=score,
            ));
        }
    }

    clfs = _load_clfs();
    clfs_candidates = clfs[clfs["SHORTDESC"].str.lower().str.contains(first_word, regex=False, na=False)
                           | clfs["LONGDESC"].str.lower().str.contains(first_word, regex=False, na=False)];
    for (_, row) in clfs_candidates.iterrows() {
        desc: str = (_row_str(row, "SHORTDESC") + " " + _row_str(row, "LONGDESC")).lower();
        score: int = 0;
        for w in words {
            if w in desc {
                score += 1;
            }
        }
        if score > 0 {
            matches.append(CodeMatch(
                hcpcs=_row_str(row, "HCPCS"),
                description=_row_str(row, "SHORTDESC"),
                source="CLFS",
                match_score=score,
            ));
        }
    }

    best_by_key: dict[str, CodeMatch] = {};
    for m in matches {
        dedup_key: str = f"{m.source}|{m.hcpcs}";
        existing = best_by_key.get(dedup_key, None);
        if existing is None or m.match_score > existing.match_score {
            best_by_key[dedup_key] = m;
        }
    }
    deduped: list[CodeMatch] = list(best_by_key.values());

    def _score(m: CodeMatch) -> int {
        return m.match_score;
    }
    deduped.sort(key=_score, reverse=True);
    return deduped[:limit];
}


# sem descriptions below are consumed as LLM-facing tool docs by
# services/discrepancy.sv.jac's LLM-driven audit agent, which calls
# get_price and get_lab_price directly to ground its benchmark prices in
# real CMS data instead of guessing them.
sem get_price = "Look up what Medicare pays a physician/professional provider for a CPT or HCPCS code under the Physician Fee Schedule (MPFS), in a specific state, locality, or county. Returns a PriceResult -- always check its `error` field before trusting `found` or `selected_payment`.";
sem get_price.hcpcs = "The CPT or HCPCS procedure code to price, e.g. '99213'.";
sem get_price.state = "Two-letter state abbreviation, e.g. 'CA'. Provide this or county.";
sem get_price.locality = "Medicare locality number within the state, e.g. '18'. Optional -- narrows an ambiguous state match.";
sem get_price.locality_name = "Substring of the Medicare locality name, e.g. 'los angeles'. Alternative way to narrow a state match.";
sem get_price.county = "County name to resolve to a Medicare locality, e.g. 'Los Angeles'. Alternative to locality/locality_name.";
sem get_price.qpp = "Whether to use the Qualifying Alternative Payment Model conversion factor instead of the standard one. Default False unless the bill specifies QPP.";
sem get_price.pos = "Place of service for the payment amount: 'facility' or 'non-facility'. Use 'facility' for hospital/outpatient settings, 'non-facility' for a private office visit.";

sem get_lab_price = "Look up the national Clinical Laboratory Fee Schedule (CLFS) rate for a lab HCPCS code, e.g. '80048' or '0001U'. Returns a LabPriceResult -- a carrier-priced code comes back with found=True but rate=None and an explanatory error.";
sem get_lab_price.hcpcs = "The lab HCPCS code to price, e.g. '80048'.";
sem get_lab_price.mod = "Optional HCPCS modifier on the line item, e.g. 'QW'. Leave blank if none.";

sem search_by_description = "Search the physician (MPFS) and lab (CLFS) fee schedules by free-text description to find candidate HCPCS/CPT codes for a line item that has no usable code. Use this when a bill's code is missing, illegible, or looks implausible for its stated description. Returns candidates ranked by how many query words matched -- re-price the best candidate with get_price or get_lab_price before treating it as a benchmark; a match here is a lead, not a priced result.";
sem search_by_description.query = "The billed description text to search for, e.g. 'basic metabolic panel' or 'office visit established patient'.";
sem search_by_description.limit = "Maximum number of candidates to return, best match first.";
