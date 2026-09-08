# CAPSTONE.md — deliverable checklist

Tick these off and your score follows. Point values in brackets map to
`scoring/rubric.json`.

## 1. Terraform GRC baseline  `terraform/`  [25]

- [ ] Customer-managed **KMS key** (FIPS endpoints) with rotation `[4]`
- [ ] CUI bucket **SSE-KMS** with your CMK `[4]`
- [ ] Metadata table **encrypted at rest** `[3]`
- [ ] S3 **public access block** (all four flags `true`) + drop the public ACL `[3]`
- [ ] **CloudTrail** trail (management + S3 data events on the CUI bucket) `[3]`
- [ ] Replace the wildcard IAM policy with **least privilege** `[4]`
- [ ] **TLS/FIPS floor** in transit (custom domain security policy / min TLS) `[2]`
- [ ] Audit/evidence bucket with **S3 Object Lock** `[2]`

## 2. OPA / Rego policy suite  `policies/`  [25]

- [ ] ≥5 `.rego` policy files `[6]`
- [ ] ≥8 unit tests (`test_...` rules), passing `opa test ./policies` `[6]`
- [ ] ≥6 `deny`/`violation` rules `[5]`
- [ ] Policies cite 800-171 / CMMC control ids `[4]`
- [ ] Every `SN-0x` gap id referenced by a policy/oscal/writeup `[4]`

Ideas: deny S3 without SSE (SN-01); deny bucket without public-access-block
(SN-02); deny API route with `authorization_type == NONE` (SN-05); deny IAM
`"*"` actions (SN-07); deny objects stored without a CUI marking tag (SN-06);
deny plaintext secrets in Lambda env (SN-10).

## 3. GitHub Actions GRC gate  `.github/workflows/`  [15]

- [ ] Workflow runs **plan → conftest/opa test → apply** `[6]`
- [ ] **Signs** the plan/artifact with cosign `[4]`
- [ ] **Uploads evidence** to the vault `[5]`
- [ ] Show one **blocked** PR (policy failed) and one **passed** PR

## 4. OSCAL component  `oscal/`  [20]

- [ ] Valid JSON `component-definition` `[4 + 3]`
- [ ] ≥6 `implemented-requirement`s mapped to **valid 800-171/CMMC control ids** `[8]`
- [ ] Declares 800-171 / CMMC L2 as the framework `[2]`
- [ ] `oscal/README.md` with your validation command + result `[3]`

## 5. Evidence chain  `scripts/`  [15]

- [ ] `verify-evidence.sh` recomputing **SHA-256** over evidence `[3+4]`
- [ ] **Verifies signatures** (cosign verify) `[4]`
- [ ] Confirms **Object Lock** immutability on the audit vault `[4]`
- [ ] Prints a clear verdict (e.g. `CHAIN INTACT`)

## 6. WRITEUP.md (human-graded, not scored by the script)

- [ ] Framework declaration + CUI enclave scope
- [ ] One paragraph per gap: prevention, detection, attestation
- [ ] Judgement calls (FIPS endpoint choice, identity/MFA model for SN-05)

Run `python3 scoring/score.py` after each step and watch the number climb.
