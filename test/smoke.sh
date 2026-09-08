#!/usr/bin/env bash
# Smoke test: upload a SYNTHETIC file to Sentinel, then fetch it back.
# Never use real CUI. This lab is for governance practice only.
set -euo pipefail

API="${API:-}"
if [[ -z "$API" ]]; then
  echo "error: set API to the invoke URL, e.g. API=https://abc.execute-api...amazonaws.com" >&2
  exit 1
fi
API="${API%/}"

CONTENT_B64=$(printf 'this is a synthetic test document, not real CUI' | base64)

echo "==> POST ${API}/documents"
RESP=$(curl -sS -X POST "${API}/documents" \
  -H 'content-type: application/json' \
  -d "{\"filename\":\"synthetic.txt\",\"classification\":\"CUI//SP-PRVCY\",\"content_b64\":\"${CONTENT_B64}\"}")
echo "$RESP"

DOC_ID=$(printf '%s' "$RESP" | sed -n 's/.*"doc_id":"\([^"]*\)".*/\1/p')
if [[ -n "$DOC_ID" ]]; then
  echo "==> GET ${API}/documents/${DOC_ID}"
  curl -sS "${API}/documents/${DOC_ID}"
  echo
fi
echo "==> if you saw the document round-trip, the flawed workload is live."
