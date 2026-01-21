#!/usr/bin/env bash
set -euo pipefail

# Prepare an unsigned build for local launch without disabling Gatekeeper globally.
# Usage: ./scripts/prepare_unsigned_app.sh [/Applications/Doorbell.app]

APP_PATH="${1:-/Applications/Doorbell.app}"

if [ ! -d "$APP_PATH" ]; then
  echo "App bundle not found at: $APP_PATH"
  exit 1
fi

if [ "${EUID:-$(id -u)}" -ne 0 ]; then
  SUDO="sudo"
else
  SUDO=""
fi

echo "Ad-hoc signing app bundle to keep it intact for Gatekeeper…"
$SUDO codesign --force --deep --sign - "$APP_PATH"

echo "Re-applying quarantine attribute so macOS shows 'Open Anyway' flow…"
$SUDO xattr -w com.apple.quarantine "0081;$(date +%s);Doorbell;" "$APP_PATH"

echo
echo "Done. Now open via Finder (ПКМ/Ctrl+Click → Open) or System Settings → Privacy & Security → Open Anyway."
echo "If macOS still claims 'повреждено', clear quarantine and retry: sudo xattr -rd com.apple.quarantine \"$APP_PATH\""
