# SCORING.md — how Sentinel is graded

You grade yourself. Run:

```bash
python3 scoring/score.py
```

You get a category-by-category breakdown, a total out of 100, a letter grade,
and a **receipt** (a SHA-256 over the report). No AWS account, no network, and
no other tools are required to compute your score.

## How to evaluate (and the pass/fail gate)

The scorer does two things: it **scores** you 0–100, and it renders a
**pre-flight checklist** — a hard pass/fail gate. A number alone lets you pile
up easy points while skipping a whole layer; the gate stops that. To **pass**,
you must clear **both** conditions:

1. **Total score ≥ 70** (the pass threshold), and
2. **every required deliverable is fully present** (see the checklist below).

Miss either and the verdict is **FAIL** — even at 99/100, if (say) you never
wrote an evidence script.

### The required deliverables (the checklist)

| Required check | What it demands |
|----------------|-----------------|
| `s3_public_block` | No public CUI — S3 public access fully blocked |
| `no_wildcard_iam` | No `Action:"*"` — least-privilege IAM (remove the god-mode role) |
| `policy_count` | A real policy suite — ≥5 Rego files |
| `deny_rules` | ≥6 `deny`/`violation` rules that actually enforce something |
| `gap_coverage` | Every `SN-0x` gap attested in a policy/OSCAL/WRITEUP |
| `oscal_json` | A valid OSCAL component-definition (parses as JSON) |
| `oscal_controls` | ≥6 **valid** 800-171/CMMC control ids mapped |
| `verify_script` | An evidence-chain verification script exists |

The authoritative list lives in `scoring/rubric.json` under `"gate"`. Any check
short of its full points shows `[ ] FAIL` on the checklist.

### Enforce it (exit code = the verdict)

```bash
python3 scoring/score.py           # report only; always exits 0
python3 scoring/score.py --gate    # exit 0 if PASS, exit 1 (FAIL) if not met
```

`--gate` is what CI runs, so **your fork's CI stays red until it passes and turns
green when it does** — a clear finish line. A freshly-forked starter is *meant*
to fail the gate; that's the baseline you work up from.

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

`.github/workflows/score.yml` runs on every push: it writes the result to the
GitHub Actions **job summary** (so you can see the score and receipt in the run)
and then runs `--gate`, which **fails the workflow until you pass**. So the run
is red on a fresh fork and turns green the moment your fork clears the threshold
and all required deliverables — an automatic, per-fork finish line.

## A note on honesty

Gap-coverage requires the *gap id* to appear in a real artifact, and OSCAL
control ids must exist in the framework catalog — so you can't score by gaming
strings. But this is a **self** evaluation. Use `WRITEUP.md` to explain
judgement calls; a human reviewer (or future you) reads it next to the number.
