"""
Sentinel CUI document handler (INTENTIONALLY NON-COMPLIANT STARTER).

Do not rewrite the app logic. Govern it: encrypt CUI at rest, block public
access, authenticate callers, audit everything, and prove it with policy +
OSCAL mapped to NIST SP 800-171 / CMMC L2.

Flaws are tagged with their gap id (SN-0x); keep the tags.
"""

import base64
import json
import os
import uuid

import boto3

s3 = boto3.client("s3")
dynamodb = boto3.resource("dynamodb")

CUI_BUCKET = os.environ.get("CUI_BUCKET", "sentinel-dev-cui")
META_TABLE = os.environ.get("META_TABLE", "sentinel-dev-meta")


def handler(event, context):
    method = event.get("requestContext", {}).get("http", {}).get("method", "GET")

    if method == "POST":
        return _upload(event)
    return _fetch(event)


def _upload(event):
    body = json.loads(event.get("body") or "{}")
    filename = body.get("filename", "document.bin")
    # CUI file contents, base64-encoded in the request.
    content = base64.b64decode(body.get("content_b64", ""))
    classification = body.get("classification", "CUI")

    doc_id = str(uuid.uuid4())

    # SN-05: no caller authentication is performed — anyone can upload.
    # SN-01: object written with no ServerSideEncryption.
    # SN-06: no CUI marking metadata / no integrity hash stored.
    s3.put_object(
        Bucket=CUI_BUCKET,
        Key=f"cui/{doc_id}/{filename}",
        Body=content,
        # SN-01: no ServerSideEncryption="aws:kms" and no SSEKMSKeyId.
    )

    table = dynamodb.Table(META_TABLE)
    table.put_item(Item={
        "doc_id": doc_id,
        "filename": filename,
        "classification": classification,
        "bytes": len(content),
    })

    return _ok({"doc_id": doc_id, "status": "stored"})


def _fetch(event):
    doc_id = event.get("pathParameters", {}).get("id", "")
    table = dynamodb.Table(META_TABLE)
    meta = table.get_item(Key={"doc_id": doc_id}).get("Item")
    if not meta:
        return {"statusCode": 404, "body": json.dumps({"error": "not found"})}

    key = f"cui/{doc_id}/{meta['filename']}"
    obj = s3.get_object(Bucket=CUI_BUCKET, Key=key)
    data = obj["Body"].read()

    # SN-05: no authorization check before returning CUI.
    return _ok({
        "doc_id": doc_id,
        "filename": meta["filename"],
        "content_b64": base64.b64encode(data).decode("utf-8"),
    })


def _ok(payload):
    return {
        "statusCode": 200,
        "headers": {"content-type": "application/json"},
        "body": json.dumps(payload),
    }
