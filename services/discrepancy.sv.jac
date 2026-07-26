"""Agent 2 -- Discrepancy Engine.

Compares each line item on a bill (as extracted by Agent 1 --
services/extractor.sv.jac's LineItem) against Medicare-approved benchmarks
-- services/pricing.sv.jac's Physician Fee Schedule (get_price) and Clinical
Laboratory Fee Schedule (get_lab_price) -- and flags:

  - overcharges: billed amount exceeds the benchmark by more than
    OVERCHARGE_THRESHOLD
  - duplicate billing: the same code + service date appears more than once
    in the bill
  - mismatched codes: the billed description shares no words with the
    CMS description for the code it was billed under (a gross word-overlap
    check, not semantic understanding -- see _plausibly_matches)
  - unresolved codes: HCPCS/CPT not found in either fee schedule, or
    missing entirely on the line item as extracted

Physician-priced codes are tried first (get_price), since a code found
there with a real payable rate is the authoritative benchmark; only codes
that come back unpriced (not found, or zero-RVU/status codes that mean
"not paid under MPFS" -- CLFS lab codes show up in the RVU file exactly
this way) fall through to the lab fee schedule.

Agent 1's LineItem does not carry a billing location (state/locality) --
a bill has one provider, not one per line -- so callers pass that context
once for the whole document, not per item.

Feeds Agent 3 (Strategist), which prioritizes these flagged discrepancies
by size/confidence.
"""

import from services.extractor { LineItem }
import from services.pricing { get_price, get_lab_price, search_by_description, CodeMatch }

glob OVERCHARGE_THRESHOLD: float = 1.15;


obj LineDiscrepancy {
    has hcpcs: str;
    has description: str = "";
    has billed_amount: float = 0.0;
    has benchmark_amount: float | None = None;
    has benchmark_source: str = "";
    has overcharge_amount: float | None = None;
    has overcharge_pct: float | None = None;
    has is_duplicate: bool = False;
    has code_mismatch: bool = False;
    has flagged: bool = False;
    has flag_reason: str = "";
}


obj BillAudit {
    has total_billed: float = 0.0;
    has total_benchmark: float = 0.0;
    has total_overcharge: float = 0.0;
    has flagged_count: int = 0;
    has discrepancies: list[LineDiscrepancy] = [];
}


obj BenchmarkLookup {
    has amount: float | None = None;
    has source: str = "";
    has cms_description: str = "";
    has error: str | None = None;
}


def _benchmark_for(
    item: LineItem,
    state: str,
    locality: str | None,
    locality_name: str | None,
    county: str | None,
    qpp: bool,
    pos: str
) -> BenchmarkLookup {
    code: str = item.code.strip();
    if code == "" {
        return BenchmarkLookup(error="No CPT/HCPCS code was extracted for this line item.");
    }

    price = get_price(
        code,
        state=state,
        locality=locality,
        locality_name=locality_name,
        county=county,
        qpp=qpp,
        pos=pos,
    );
    if price.found and price.error is None and price.selected_payment is not None {
        return BenchmarkLookup(
            amount=price.selected_payment,
            source=f"MPFS ({price.selected_site})",
            cms_description=price.description,
        );
    }

    lab = get_lab_price(code);
    if lab.found and lab.error is None and lab.rate is not None {
        return BenchmarkLookup(
            amount=lab.rate,
            source="CLFS",
            cms_description=f"{lab.short_description} {lab.long_description}",
        );
    }

    if price.found and price.error is not None {
        return BenchmarkLookup(error=price.error);
    }
    if lab.found and lab.error is not None {
        return BenchmarkLookup(error=lab.error);
    }
    return BenchmarkLookup(error=f"HCPCS/CPT code '{code}' not found in MPFS or CLFS.");
}


"""Cheap sanity check for whether a billed description plausibly matches
the CMS description for the code it was billed under -- NOT semantic
understanding, just whether they share any real word. Catches gross
mismatches (a code for a lab panel billed as "MRI brain"); misses subtle
ones (synonyms, abbreviations CMS and the provider both use differently).
That's intentional -- this is a fast, free first-pass filter, not a
replacement for a real judgment call.
"""
def _plausibly_matches(billed_description: str, cms_description: str) -> bool {
    words: list[str] = [w for w in billed_description.lower().split() if len(w) > 2];
    if len(words) == 0 {
        return True;
    }
    cms_lower: str = cms_description.lower();
    for w in words {
        if w in cms_lower {
            return True;
        }
    }
    return False;
}


"""Compare every line item on a bill to Medicare benchmarks and flag discrepancies.

Agent 1's list[LineItem] goes in, along with the bill's billing location
(state, and optionally locality/county/qpp/pos); a BillAudit comes out with
a per-line benchmark, overcharge amount, and a flag + human-readable reason
wherever something looks wrong. Nothing here calls an LLM -- price
comparison is exact arithmetic against CMS's own published rates, so plain
Jac logic is faster, free, and reproducible where an LLM call would just
add noise. Line items with no extracted code are flagged rather than
guessed at -- see audit_bill() below for the LLM-driven variant intended
to recover these using search_by_description.
"""
def:pub analyze_bill(
    items: list[LineItem],
    state: str,
    locality: str | None = None,
    locality_name: str | None = None,
    county: str | None = None,
    qpp: bool = False,
    pos: str = "non-facility"
) -> BillAudit {
    audit = BillAudit();

    key_counts: dict[str, int] = {};
    for item in items {
        code: str = item.code.strip();
        if code != "" {
            key: str = f"{code}|{item.service_date}";
            key_counts[key] = key_counts.get(key, 0) + 1;
        }
    }

    for item in items {
        code: str = item.code.strip();
        billed: float = item.billed_amount if item.billed_amount is not None else 0.0;

        lookup = _benchmark_for(item, state, locality, locality_name, county, qpp, pos);
        disc = LineDiscrepancy(
            hcpcs=code,
            description=item.description,
            billed_amount=billed,
        );

        audit.total_billed += billed;

        reasons: list[str] = [];

        if item.billed_amount is None {
            reasons.append("No billed amount was extracted for this line item.");
        }

        if lookup.amount is not None {
            benchmark: float = lookup.amount;
            disc.benchmark_amount = benchmark;
            disc.benchmark_source = lookup.source;
            disc.overcharge_amount = billed - benchmark;
            audit.total_benchmark += benchmark;

            if benchmark > 0.0 {
                overcharge_amt: float = disc.overcharge_amount as float;
                disc.overcharge_pct = (overcharge_amt / benchmark) * 100.0;
            }
            if benchmark > 0.0 and billed > benchmark * OVERCHARGE_THRESHOLD {
                pct: float = disc.overcharge_pct as float;
                reasons.append(f"Billed ${billed:,.2f} vs Medicare-approved ${benchmark:,.2f} ({pct:.0f}% over benchmark)");
            }

            if item.description.strip() != "" and not _plausibly_matches(item.description, lookup.cms_description) {
                disc.code_mismatch = True;
                reasons.append(f"Billed as '{item.description}' but code {code} is officially described as '{lookup.cms_description}' -- possible mismatched code.");
            }
        } elif lookup.error is not None {
            reasons.append(lookup.error);
        } else {
            reasons.append("Could not resolve a benchmark price for this code.");
        }

        if code != "" {
            key: str = f"{code}|{item.service_date}";
            if key_counts[key] > 1 {
                disc.is_duplicate = True;
                reasons.append("Appears more than once with the same code/date (possible duplicate billing).");
            }
        }

        disc.flagged = len(reasons) > 0;
        disc.flag_reason = " ".join(reasons);

        if disc.flagged {
            audit.flagged_count += 1;
        }
        audit.discrepancies.append(disc);
    }

    audit.total_overcharge = audit.total_billed - audit.total_benchmark;
    return audit;
}


sem LineDiscrepancy.hcpcs = "The CPT/HCPCS code for this line item, if one was extracted. Empty string if none was found on the bill.";
sem LineDiscrepancy.description = "Short description of the billed service.";
sem LineDiscrepancy.billed_amount = "The amount actually billed for this line item, in dollars. 0.0 if no amount was printed on the bill (see flag_reason).";
sem LineDiscrepancy.benchmark_amount = "The Medicare-approved benchmark price for this code, in dollars, if one could be resolved via a tool call.";
sem LineDiscrepancy.benchmark_source = "Which fee schedule the benchmark came from, e.g. 'MPFS (non-facility)' or 'CLFS'. Empty if unresolved.";
sem LineDiscrepancy.overcharge_amount = "billed_amount minus benchmark_amount, in dollars. Positive means overcharged.";
sem LineDiscrepancy.overcharge_pct = "overcharge_amount as a percentage of benchmark_amount.";
sem LineDiscrepancy.is_duplicate = "True if this same code/service date appears more than once on the bill.";
sem LineDiscrepancy.code_mismatch = "True if the billed description shares no words with the CMS description for this code -- a gross mismatch check (e.g. a lab-panel code billed as an MRI), not a nuanced one. Only set when a benchmark was resolved, since there's no CMS description to compare against otherwise.";
sem LineDiscrepancy.flagged = "True if this line item has ANY issue worth the patient disputing -- overcharge, duplicate, mismatched/implausible code, missing code, missing amount, or an unresolved benchmark.";
sem LineDiscrepancy.flag_reason = "Plain-English explanation of why this line is flagged, citing the dollar amounts or codes involved. Empty string if not flagged.";

sem BillAudit.total_billed = "Sum of billed_amount across every line item.";
sem BillAudit.total_benchmark = "Sum of benchmark_amount across every line item that resolved one.";
sem BillAudit.total_overcharge = "total_billed minus total_benchmark.";
sem BillAudit.flagged_count = "Number of line items with flagged = True.";
sem BillAudit.discrepancies = "One LineDiscrepancy per input line item, in the same order they were given.";

sem analyze_bill = "Deterministically price every line item against Medicare benchmarks (MPFS/CLFS) and flag overcharges (>15% over benchmark), exact duplicate code+service-date entries, and lines with no extracted code or billed amount. Call this FIRST to get exact, free numbers for any line item with a clean HCPCS code -- never guess a number this can compute exactly.";
sem analyze_bill.items = "The patient's line items to audit, as extracted by Agent 1.";
sem analyze_bill.state = "Two-letter state abbreviation for the billing provider's location, e.g. 'CA'.";
sem analyze_bill.locality = "Medicare locality number within the state, e.g. '18'. Optional -- narrows an ambiguous state match.";
sem analyze_bill.locality_name = "Substring of the Medicare locality name, e.g. 'los angeles'. Alternative way to narrow a state match.";
sem analyze_bill.county = "County name to resolve to a Medicare locality. Alternative to locality/locality_name.";
sem analyze_bill.qpp = "Whether to use the Qualifying Alternative Payment Model conversion factor. Default False.";
sem analyze_bill.pos = "Place of service for pricing: 'facility' or 'non-facility'.";


"""Agent 2, LLM-driven variant -- for the messy real-world cases the
deterministic analyze_bill can't cleanly handle: a code that might be
miskeyed, a billed description that doesn't match what its CPT/HCPCS code
actually covers, or other irregularities a human biller would catch on a
manual read. Grounds every dollar figure in a real tool call (analyze_bill
/ get_price / get_lab_price) instead of inventing a benchmark price from
the model's own guess.

search_by_description is NOT included as a tool here yet: combining it
with analyze_bill triggers a byLLM schema-generation bug (AttributeError:
'str' object has no attribute 'fields' in schema.impl.jac, while building
the JSON schema for the tool list) that reproduces on a clean cache and is
independent of the mock/production-leak issue documented elsewhere in this
file's history. search_by_description works correctly when it is the only
tool on a by-llm call (verified) -- the bug is specifically about mixing
it with analyze_bill's more deeply-nested BillAudit/LineDiscrepancy return
type. Line items with no extracted code currently just get flagged by
analyze_bill as unresolvable; wiring in description-based recovery needs
either a byLLM fix/workaround or restructuring so this function's own
return type doesn't collide with search_by_description's schema.
"""
def:pub audit_bill(
    items: list[LineItem],
    state: str,
    locality: str | None = None,
    county: str | None = None
) -> BillAudit by llm(
    tools=[analyze_bill, get_price, get_lab_price],
    temperature=0.2,
    max_react_iterations=10
);
sem audit_bill = "Audit a patient's billed line items for discrepancies a real medical biller would flag: overcharges vs. the Medicare-approved rate, duplicate billing, and mismatched or implausible codes. Call analyze_bill first for exact, deterministic numbers on the straightforward cases -- pass it the same state/locality/county you were given. For anything it can't cleanly resolve -- a possibly-miskeyed code, a description that doesn't match its code -- call get_price / get_lab_price directly and use judgment, the way an experienced medical biller would. Always ground every dollar figure in an actual tool call result; never invent a benchmark price. Return one LineDiscrepancy per input item, in order, plus correct running totals.";
sem audit_bill.items = "The patient's line items to audit, as extracted by Agent 1.";
sem audit_bill.state = "Two-letter state abbreviation for the billing provider's location, e.g. 'CA'.";
sem audit_bill.locality = "Medicare locality number within the state, if known.";
sem audit_bill.county = "County name to resolve to a Medicare locality, if known (alternative to locality).";
