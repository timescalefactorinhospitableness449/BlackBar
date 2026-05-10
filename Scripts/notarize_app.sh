#!/usr/bin/env bash
set -euo pipefail

APP_PATH=${1:-}
PROFILE=${2:-${NOTARY_PROFILE:-Xcode Notary}}

if [[ -z "$APP_PATH" || ! -d "$APP_PATH" ]]; then
  echo "Usage: $0 /path/to/BlackBar.app [profile]" >&2
  exit 1
fi

TMP_DIR=$(mktemp -d)
ZIP_PATH="$TMP_DIR/blackbar.zip"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "==> Zipping app"
/usr/bin/ditto -ck --keepParent "$APP_PATH" "$ZIP_PATH"

echo "==> Submitting to Apple Notary Service (profile: $PROFILE)"
xcrun notarytool submit "$ZIP_PATH" --keychain-profile "$PROFILE" --wait

echo "==> Stapling ticket"
xcrun stapler staple "$APP_PATH"
xcrun stapler validate "$APP_PATH"

echo "==> Notarization complete"
