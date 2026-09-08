# WORKLOAD.md — what Sentinel does

Sentinel is a minimal, serverless **CUI document-drop**. A defense subcontractor
uses it to receive controlled files from partners and pull them back later. It
works — and it fails almost every CMMC Level 2 practice you can name.

## Architecture

```
partner ──POST /documents────▶ API Gateway (HTTP API)
partner ──GET  /documents/{id}▶      │
                                     ▼
                               Lambda: docs
                                │        │
                    put_object  │        │  put_item / get_item
                                ▼        ▼
                          S3 cui/       DynamoDB meta
                          (public!)     (unencrypted)
```

- **API Gateway (HTTP API)** — `POST /documents`, `GET /documents/{id}`, no auth.
- **Lambda `docs`** — stores a base64 file to S3, metadata to DynamoDB; fetch
  returns the file.
- **S3 `cui`** — one prefix per document. Public. Unencrypted.
- **DynamoDB `meta`** — filename, classification label, size.

## Request / response

```bash
# upload
curl -s -X POST "$API/documents" -H 'content-type: application/json' \
  -d "{\"filename\":\"contract.txt\",\"classification\":\"CUI//SP-PRVCY\",\"content_b64\":\"$(printf 'hello cui' | base64)\"}"
# => {"doc_id":"...","status":"stored"}

# fetch
curl -s "$API/documents/<doc_id>"
# => {"doc_id":"...","filename":"contract.txt","content_b64":"aGVsbG8gY3Vp"}
```

## Ground rules

- **Do not change the app's behaviour or contract.** Both routes must keep
  working. You are governing the workload, not rewriting it.
- You **may** (and should) remove insecure infrastructure — the public ACL, the
  wildcard IAM policy — because removing an insecure default is a governance
  fix, not an app rewrite.
- Everything else is fixed with a **governance baseline** (new Terraform),
  **policy-as-code**, a **CI gate**, an **OSCAL** component mapped to 800-171,
  and an **evidence chain**.

Use only synthetic, non-sensitive test files. This is a lab; never place real
CUI in it. See `README.md` for deploy/test/destroy and `GAPS.md` for the work.
