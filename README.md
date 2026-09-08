# Sentinel — GRC Engineering Capstone Starter 🛡️

> A working, **deliberately non-compliant** CUI document-drop workload.
> Fork it, govern it to CMMC Level 2, and prove it — then score yourself,
> deterministically.

Sentinel receives Controlled Unclassified Information (`POST /documents`), stores
each file in S3, records metadata in DynamoDB, and hands files back
(`GET /documents/{id}`). It also stores CUI in the clear, serves it from a
**public** bucket, requires **no authentication**, keeps **no audit trail**, and
runs on a **god-mode** IAM role. Your job is to make it **assessment-defensible
against NIST SP 800-171 / CMMC L2** *without rewriting the app* — by adding the
five governance layers a real GRC engineer would.

Sibling of [`GRCEngClub/cgep-app-starter`](https://github.com/GRCEngClub/cgep-app-starter).
Same skill stack (Terraform · OPA/Rego · GitHub Actions · OSCAL · evidence
chain), new domain (defense/CUI), new framework (CMMC L2 / 800-171), fresh gaps.

## The mission

| Layer | Deliverable | Lives in |
|-------|-------------|----------|
| 1. GRC baseline | Terraform that encrypts, isolates, and audits the CUI enclave | `terraform/` (add new `.tf`) |
| 2. Policy suite | ≥5 OPA/Rego policies that *detect* the gaps, with tests | `policies/` |
| 3. CI gate | GitHub Actions: plan → policy check → apply → sign → upload evidence | `.github/workflows/` |
| 4. OSCAL | Component definition mapping controls to 800-171 / CMMC | `oscal/` |
| 5. Evidence chain | Script proving integrity (SHA-256), signing (cosign), immutability (Object Lock) | `scripts/` |

All work is enumerated in **[GAPS.md](GAPS.md)** (10 gaps, `SN-01`…`SN-10`). The
control-mapping primer is **[FRAMEWORKS.md](FRAMEWORKS.md)**.

## Score yourself (deterministic)

```bash
python3 scoring/score.py
```

Same repo state → same score, on any machine, no network needed. A fresh fork
scores near zero — the baseline you climb.

To **pass**, clear the gate: `python3 scoring/score.py --gate` exits 0 only if
you score ≥ 70 **and** every required deliverable is present (else exit 1 = FAIL).
CI enforces this — your fork stays red until it passes. See
**[SCORING.md](SCORING.md)** for the guarantee, the checklist, and the full
100-point rubric (`scoring/rubric.json`).

## Deploy the starter (optional, to see it work)

Requires AWS credentials for a **throwaway sandbox** and Terraform.

```bash
make deploy  AWS_PROFILE=<sandbox>    # terraform init + apply
make test    AWS_PROFILE=<sandbox>    # upload + fetch a synthetic file
make destroy AWS_PROFILE=<sandbox>    # tear it down
```

~\$0 if destroyed within a day (all pay-per-use). **Sandbox only** — it is
insecure on purpose. Use synthetic files; **never place real CUI in this lab.**

## Suggested workflow

1. Fork this repo (keep the fork **public** so lineage and Actions runs are
   visible), then `git clone` it.
2. Read `GAPS.md`, `WORKLOAD.md`, `FRAMEWORKS.md`, `SCORING.md`.
3. Work gap-by-gap: prevention (Terraform) → detection (Rego) → attestation
   (OSCAL / `WRITEUP.md`). Run `python3 scoring/score.py` as you go.
4. Wire the CI gate and evidence chain last; aim for an **A**.
5. Write `WRITEUP.md`: framework declaration, one paragraph per gap, judgement
   calls (FIPS endpoints, identity model). This is what a human reviewer reads.

## Repo layout

```
sentinel-app-starter/
├── README.md WORKLOAD.md GAPS.md FRAMEWORKS.md SCORING.md
├── Makefile
├── terraform/           # the flawed workload (+ your baseline .tf)
│   ├── main.tf variables.tf outputs.tf
│   └── lambda/handler.py
├── test/smoke.sh        # upload + fetch a synthetic file
├── scoring/
│   ├── score.py         # deterministic scorer (stdlib only)
│   ├── rubric.json      # the authoritative 100-point rubric
│   ├── controls.json    # valid 800-171 / CMMC control ids
│   └── README.md
├── docs/CAPSTONE.md     # deliverable checklist
└── .github/workflows/score.yml   # auto-scores every push

# you will create:  policies/  oscal/  scripts/  WRITEUP.md
```

## Ethics & scope

For authorized learning and portfolio use. The workload models real CUI-handling
failures so you can practice fixing them — deploy only to sandboxes you own, use
synthetic data only, and never point this at anyone else's infrastructure.

License: MIT.
