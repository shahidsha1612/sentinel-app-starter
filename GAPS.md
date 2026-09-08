# GAPS.md — Sentinel deliberate compliance gaps

Sentinel is a working CUI (Controlled Unclassified Information) document-drop API
that is **intentionally non-compliant** with CMMC Level 2 / NIST SP 800-171. Each
gap is real, reachable from the deployed workload, and tagged in the source with
its id. Your capstone closes every gap and *proves* it.

> Keep the `SN-0x` tags in the code. The scorer checks that each gap id is
> referenced by one of your remediation artifacts (policy, OSCAL, or
> WRITEUP.md) — that's how it knows you attested to the fix.

| ID | Severity | Gap | Where | 800-171 / CMMC control |
|------|----------|-----|-------|-------------------------|
| **SN-01** | Critical | CUI stored unencrypted at rest (no CMK on S3 or DynamoDB) | `main.tf`, `handler.py` | 3.13.16 / SC.L2-3.13.16 |
| **SN-02** | Critical | CUI bucket is world-readable (public-read ACL, no public access block) | `main.tf` | 3.1.1 / AC.L2-3.1.1 |
| **SN-03** | High | No CloudTrail / no API access logging — no audit trail | `main.tf` | 3.3.1 / AU.L2-3.3.1 |
| **SN-04** | High | CUI transmitted over an API with no TLS/FIPS floor | `main.tf` | 3.13.8 / SC.L2-3.13.8 |
| **SN-05** | Critical | No authenticator on upload/fetch — anonymous CUI access | `main.tf`, `handler.py` | 3.5.3 / IA.L2-3.5.3 |
| **SN-06** | Medium | No CUI marking / no integrity hash on stored objects | `handler.py` | 3.8.3 / MP.L2-3.8.3 |
| **SN-07** | Critical | Lambda role grants `Action:"*"` on `Resource:"*"` | `main.tf` | 3.1.5 / AC.L2-3.1.5 |
| **SN-08** | High | No boundary protection (no WAF, open egress, no segmentation) | `main.tf` | 3.13.1 / SC.L2-3.13.1 |
| **SN-09** | Medium | Audit/evidence records are mutable (no Object Lock) | (missing) | 3.3.8 / AU.L2-3.3.8 |
| **SN-10** | Medium | Shared secret hardcoded in plaintext Lambda env | `main.tf` | 3.5.2 / 3.13.10 |

## What "closing a gap" means here

For each gap, point to **three** things:

1. **Prevention** — Terraform in your baseline making the secure state real
   (e.g. a FIPS-validated CMK + SSE-KMS on the CUI bucket for SN-01).
2. **Detection** — a Rego policy that *fails* if the insecure pattern returns
   (e.g. `deny` when an S3 bucket has no `server_side_encryption`).
3. **Attestation** — an OSCAL `implemented-requirement` (or WRITEUP.md entry)
   naming the gap id and the 800-171 control / CMMC practice it satisfies.

CUI-specific nuance: 800-171 wants CUI **encrypted with FIPS-validated
cryptography** (SC.3.13.11) and **marked** (MP.3.8). SN-05 is the one people
under-scope — "no auth" isn't just a missing API key; the fix is an authorizer
plus an identity story you can describe (IA.3.5.x).

See `FRAMEWORKS.md` for the mapping primer and `SCORING.md` for the rubric.
