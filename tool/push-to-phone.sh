#!/bin/bash
# Push the release APK to a phone via LocalSend.
# Requires PHONE_IP env var (the phone's LAN IP from LocalSend's "Receive" tab).
# The phone must have LocalSend open in the foreground.
set -euo pipefail

APK="${APK:-build/app/outputs/flutter-apk/app-release.apk}"
PORT="${PORT:-53317}"
PHONE_IP="${PHONE_IP:-}"

if [[ -z "$PHONE_IP" ]]; then
  echo "ERROR: PHONE_IP is not set." >&2
  echo "  Open LocalSend on your phone, tap 'Receive', and read the IP shown." >&2
  echo "  Then: PHONE_IP=192.168.x.y make push" >&2
  exit 1
fi

if [[ ! -f "$APK" ]]; then
  echo "ERROR: APK not found at $APK" >&2
  echo "  Run 'make apk' first." >&2
  exit 1
fi

BASE="https://${PHONE_IP}:${PORT}/api/localsend/v2"
SIZE=$(stat -c %s "$APK")
SHA=$(sha256sum "$APK" | cut -d' ' -f1)
FP=$(head -c 32 /dev/urandom | sha256sum | cut -d' ' -f1)

# Verify the phone responds before we ask the user to tap accept.
echo "Checking phone at $PHONE_IP:$PORT ..."
INFO=$(curl -k -sS -m 5 "$BASE/info" || true)
if [[ -z "$INFO" ]]; then
  echo "ERROR: No response from $BASE/info" >&2
  echo "  Is LocalSend open on the phone? Same WiFi? Firewall blocking?" >&2
  exit 1
fi
ALIAS=$(echo "$INFO" | grep -oP '"alias":"\K[^"]+' || echo "?")
echo "Found device: $ALIAS"

PAYLOAD=$(cat <<EOF
{
  "info": {
    "alias": "claude-cli",
    "version": "2.1",
    "deviceModel": "linux",
    "deviceType": "headless",
    "fingerprint": "$FP",
    "port": $PORT,
    "protocol": "https",
    "download": false
  },
  "files": {
    "f1": {
      "id": "f1",
      "fileName": "quicktask-vikunja.apk",
      "size": $SIZE,
      "fileType": "application/vnd.android.package-archive",
      "sha256": "$SHA",
      "preview": null
    }
  }
}
EOF
)

# prepare-upload blocks until the user taps Accept on the phone (or declines).
# Some LocalSend versions return 204/403 on decline. Retry once on transient failure.
echo "Sending upload request — tap ACCEPT on $ALIAS to continue ..."
ATTEMPT=0
RESP=""
while (( ATTEMPT < 2 )); do
  RESP=$(curl -k -sS -m 120 -w "\n%{http_code}" -X POST "$BASE/prepare-upload" \
    -H "Content-Type: application/json" -d "$PAYLOAD" || true)
  CODE=$(echo "$RESP" | tail -n1)
  BODY=$(echo "$RESP" | sed '$d')
  if [[ "$CODE" == "200" ]]; then
    break
  fi
  ATTEMPT=$((ATTEMPT + 1))
  if (( ATTEMPT < 2 )); then
    echo "  HTTP $CODE — retrying in 2s ..."
    sleep 2
  fi
done

if [[ "$CODE" != "200" ]]; then
  echo "ERROR: prepare-upload failed (HTTP $CODE): $BODY" >&2
  echo "  403 = declined on phone. 408/timeout = no tap. Check phone screen." >&2
  exit 1
fi

SID=$(echo "$BODY" | grep -oP '"sessionId":"\K[^"]+')
TOK=$(echo "$BODY" | grep -oP '"f1":"\K[^"]+')
if [[ -z "$SID" || -z "$TOK" ]]; then
  echo "ERROR: Could not parse sessionId/token from: $BODY" >&2
  exit 1
fi

echo "Uploading $(numfmt --to=iec --suffix=B $SIZE) ..."
HTTP=$(curl -k -sS -o /dev/null -w "%{http_code}" -X POST \
  "$BASE/upload?sessionId=$SID&fileId=f1&token=$TOK" \
  -H "Content-Type: application/octet-stream" \
  --data-binary "@$APK")

if [[ "$HTTP" == "200" ]]; then
  echo "Done. APK delivered to $ALIAS."
else
  echo "ERROR: upload failed (HTTP $HTTP)" >&2
  exit 1
fi
