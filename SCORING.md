# SCORING.md — how Sentinel is graded

You grade yourself. Run:

```bash
python3 scoring/score.py
```

You get a category-by-category breakdown, a total out of 100, a letter grade,
and a **receipt** (a SHA-256 over the report). No AWS account, no network, and
no other tools are required to compute your score.

## The determinism guarantee

The score is a **pure function of the files in your checkout.** The scorer:

- uses only the Python standard library;
- never calls the network, a clock, or a random number generator;
- sorts every directory listing before reading it;
- writes a report with **no timestamps**.

Consequences you can rely on:

1. **Same repo state → same score, byte-for-byte, on any machine.** Re-run it a
   hundred times; the number and the receipt never move unless files change.
2. **Different people → different scores.** The score reflects *your* fork's
   contents, so everyone who forks this gets their own independent result.
3. **The receipt is a fingerprint.** Same receipt → identical graded inputs.

> `terraform` and `opa` are **not** part of the score — their version and
> availability differ per machine and would break reproducibility. Run them for
> your own benefit with `python3 scoring/score.py --advisory` (clearly marked as
> *not counted*).

## The 100 points

| Category | Points | What earns them |
|----------|-------:|-----------------|
| Terraform GRC baseline | 25 | CMK, S3+DynamoDB SSE, public-access block, CloudTrail, no wildcard IAM, TLS/FIPS floor, Object Lock audit vault |
| OPA / Rego policy suite | 25 | ≥5 policies, ≥8 tests, ≥6 deny rules, 800-171/CMMC control refs, **every gap referenced** |
| GitHub Actions GRC gate | 15 | plan → policy check → apply, signing, evidence upload |
| OSCAL component | 20 | valid JSON, component-definition shape, **≥6 valid 800-171/CMMC controls mapped**, framework ref, README |
| Evidence chain | 15 | verify script, SHA-256, signature verification, Object Lock immutability check |

The authoritative rubric — every check, its points, and the exact regex it looks
for — is `scoring/rubric.json`. Read it; it *is* the spec.

## Grades

| % | Grade |
|---|-------|
| ≥90 | A — assessment-ready |
| ≥80 | B — strong |
| ≥70 | C — passing |
| ≥50 | D — in progress |
| <50 | F — starter (no remediation yet) |

A freshly-forked starter scores near the bottom by design. Watch the number
climb as you close CUI gaps.

## Running it in CI

`.github/workflows/score.yml` runs the scorer on every push and writes the
result to the GitHub Actions **job summary**, so your fork is auto-graded. It
never fails the build on a low score — it just reports.

## A note on honesty

Gap-coverage requires the *gap id* to appear in a real artifact, and OSCAL
control ids must exist in the framework catalog — so you can't score by gaming
strings. But this is a **self** evaluation. Use `WRITEUP.md` to explain
judgement calls; a human reviewer (or future you) reads it next to the number.
