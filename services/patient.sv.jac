"""Patient profile -- identity and coverage, persisted per logged-in user.

Agent 2 (services/discrepancy.sv.jac) needs a state/locality to price a
bill against, and the discrepancy math itself depends on what kind of
coverage the patient has -- MPFS/CLFS benchmarks are Medicare rates, which
are the wrong reference point for a privately-insured or self-pay patient.
Nothing upstream currently supplies either piece of context; this is where
it will come from once wired in.

One Patient node per user, attached to their own `root` -- the same
per-user isolation model the rest of this app uses (see `jac guide
jac-sv-auth`). Read is a function (cached client-side); the save path is a
walker using the get-or-create pattern (`visit ... else`) so the first
save creates the profile and every save after that updates the same node
in place, instead of accumulating duplicates.
"""

import from datetime { datetime, timezone }


def _now() -> str {
    return datetime.now(timezone.utc).isoformat();
}


enum CoverageType: str {
    MEDICARE = "MEDICARE",
    PRIVATE_INSURANCE = "PRIVATE_INSURANCE",
    UNINSURED = "UNINSURED",
}


node Patient {
    has name: str = "";
    has state: str = "";
    has county: str | None = None;
    has locality: str | None = None;
    has coverage_type: CoverageType = CoverageType.MEDICARE;
    has created_at: str = "";

    def to_view -> PatientView {
        return PatientView(
            id=jid(self),
            name=self.name,
            state=self.state,
            county=self.county,
            locality=self.locality,
            coverage_type=self.coverage_type,
            created_at=self.created_at,
        );
    }
}


obj PatientView {
    has id: str;
    has name: str;
    has state: str;
    has county: str | None;
    has locality: str | None;
    has coverage_type: CoverageType;
    has created_at: str;
}


"""The calling user's own patient profile, or None if they haven't saved one yet."""
def my_patient() -> PatientView | None {
    for p in [root -->][?:Patient] {
        return p.to_view();
    }
    return None;
}


"""Create or update the calling user's patient profile. Get-or-create: the
first call for a user creates their Patient node; every call after that
updates the same node instead of creating a second one.
"""
walker SavePatientProfile {
    has name: str;
    has state: str;
    has coverage_type: CoverageType = CoverageType.MEDICARE;
    has county: str | None = None;
    has locality: str | None = None;

    can save with Root entry {
        visit [here -->][?:Patient] else {
            fresh = here ++> Patient(created_at=_now());
            visit fresh;
        }
    }

    can update with Patient entry {
        here.name = self.name;
        here.state = self.state;
        here.coverage_type = self.coverage_type;
        here.county = self.county;
        here.locality = self.locality;
        report here.to_view();
    }
}
