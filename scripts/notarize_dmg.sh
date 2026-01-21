#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DMG_PATH="$ROOT/dist/Doorbell.dmg"
PRIMARY_BUNDLE_ID="${PRIMARY_BUNDLE_ID:-com.doorbell.app}"
NOTARY_KEY_ID="${NOTARY_KEY_ID:-}"
NOTARY_ISSUER_ID="${NOTARY_ISSUER_ID:-}"
NOTARY_KEY_CONTENTS="${NOTARY_KEY_CONTENTS:-${NOTARY_KEY_BASE64:-}}"

if [ ! -f "$DMG_PATH" ]; then
  echo "DMG not found at $DMG_PATH; run scripts/build_dmg.sh first."
  exit 1
fi

if [ -z "$NOTARY_KEY_ID" ] || [ -z "$NOTARY_ISSUER_ID" ] || [ -z "$NOTARY_KEY_CONTENTS" ]; then
  echo "Notarization credentials are missing; skipping notarization."
  exit 0
fi

KEY_FILE="$(mktemp /tmp/notary-key-XXXXXX).p8"
echo "$NOTARY_KEY_CONTENTS" | base64 --decode > "$KEY_FILE"

echo "Submitting DMG for notarization…"
xcrun notarytool submit "$DMG_PATH" \
  --key "$KEY_FILE" \
  --key-id "$NOTARY_KEY_ID" \
  --issuer "$NOTARY_ISSUER_ID" \
  --primary-bundle-id "$PRIMARY_BUNDLE_ID" \
  --wait

echo "Stapling notarization ticket…"
xcrun stapler staple "$DMG_PATH"

rm -f "$KEY_FILE"
echo "Notarization completed for $DMG_PATH"
