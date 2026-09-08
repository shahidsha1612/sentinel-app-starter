# FRAMEWORKS.md — mapping Sentinel to NIST SP 800-171 / CMMC L2

Your framework is **CMMC Level 2**, which is implemented by the 110 practices of
**NIST SP 800-171 Rev 2**. Sentinel handles **CUI**, so this is the real-world
framework a DoD subcontractor would be assessed against.

## The families you will touch

| 800-171 family | Practices | Sentinel relevance |
|----------------|-----------|--------------------|
| **AC** Access Control | 3.1.1, 3.1.2, 3.1.5, 3.1.20 | Lock the public bucket; least-privilege IAM (SN-02, SN-07) |
| **AU** Audit & Accountability | 3.3.1, 3.3.2, 3.3.8 | CloudTrail + access logs; immutable retention (SN-03, SN-09) |
| **IA** Identification & Auth | 3.5.2, 3.5.3 | Authenticate callers; MFA story (SN-05, SN-10) |
| **MP** Media Protection | 3.8.1, 3.8.3 | Mark CUI; protect media at rest (SN-06) |
| **SC** System & Comms Protection | 3.13.1, 3.13.8, 3.13.11, 3.13.16 | Boundary protection; FIPS in transit + at rest (SN-01, SN-04, SN-08) |
| **SI** System & Info Integrity | 3.14.1 | Flaw remediation / config baseline (cross-cutting) |

## Two id styles the scorer accepts

Use **either**:

- the bare 800-171 control number — `"3.13.16"`, or
- the CMMC L2 practice id — `"SC.L2-3.13.16"`.

Each mapped OSCAL `control-id` is validated against `scoring/controls.json`; ids
not in that catalog do not count (so you can't "map" to controls that don't
exist). If you need one that isn't listed, add it to `controls.json` in your
fork and justify it in `WRITEUP.md`.

## CUI-specific expectations

- **Encrypt CUI with FIPS-validated cryptography** — AWS KMS in FIPS endpoints
  satisfies SC.3.13.11 / SC.3.13.16. Note the endpoint choice in your writeup.
- **Mark CUI** — carry the classification label through to object metadata /
  tags (MP.3.8.3). The starter stores a `classification` field but never marks
  the S3 object with it — fix that.
- **Least functionality & boundary protection** — SN-08 wants deny-by-default
  networking; describe how you'd add a WAF / restrict egress even in a
  serverless design (SC.3.13.1).

## Suggested primary-framework declaration (put this in WRITEUP.md)

> **Framework:** CMMC Level 2 (NIST SP 800-171 Rev 2).
> **CUI scope:** the Sentinel enclave — the docs Lambda, the CUI bucket, the
> metadata table, and the audit/evidence path.
> **Assumptions:** FIPS-validated KMS endpoints; identities federated from the
> contractor's IdP (stubbed in this lab).
