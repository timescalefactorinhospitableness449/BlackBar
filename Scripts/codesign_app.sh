#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
APP_PATH="${1:-$ROOT/.build/release/BlackBar.app}"
IDENTITY="${2:-${BLACKBAR_CODE_SIGN_IDENTITY:-${CODESIGN_IDENTITY:-${CODE_SIGN_IDENTITY:-}}}}"
APP_NAME="BlackBar"
BUNDLE_ID="com.steipete.blackbar"
TMP_ENTITLEMENTS="/tmp/BlackBar_entitlements.plist"

log() { printf '%s\n' "[$(date '+%H:%M:%S')] $*"; }

if [[ -z "$IDENTITY" ]]; then
  log "No signing identity provided; skipping codesign for $APP_PATH"
  exit 0
fi
[[ -d "$APP_PATH" ]] || { echo "App bundle not found: $APP_PATH" >&2; exit 1; }

bundle_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP_PATH/Contents/Info.plist" 2>/dev/null || echo "$BUNDLE_ID")"
cat > "$TMP_ENTITLEMENTS" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.hardened-runtime</key>
    <true/>
    <key>com.apple.security.temporary-exception.mach-lookup.global-name</key>
    <array>
        <string>${bundle_id}-spks</string>
        <string>${bundle_id}-spkd</string>
    </array>
</dict>
</plist>
PLIST

xattr -cr "$APP_PATH" 2>/dev/null || true

log "Signing frameworks"
find "$APP_PATH/Contents/Frameworks" \( -type d -name '*.framework' -o -type f -name '*.dylib' \) 2>/dev/null | while read -r framework; do
  codesign --force --options runtime --timestamp --sign "$IDENTITY" "$framework"
done

SPARKLE_FRAMEWORK="$APP_PATH/Contents/Frameworks/Sparkle.framework"
if [[ -d "$SPARKLE_FRAMEWORK" ]]; then
  log "Signing Sparkle components"
  SPARKLE_VERSION="$SPARKLE_FRAMEWORK/Versions/B"
  for path in \
    "$SPARKLE_VERSION/Sparkle" \
    "$SPARKLE_VERSION/Autoupdate" \
    "$SPARKLE_VERSION/Updater.app/Contents/MacOS/Updater" \
    "$SPARKLE_VERSION/Updater.app" \
    "$SPARKLE_VERSION/XPCServices/Downloader.xpc/Contents/MacOS/Downloader" \
    "$SPARKLE_VERSION/XPCServices/Downloader.xpc" \
    "$SPARKLE_VERSION/XPCServices/Installer.xpc/Contents/MacOS/Installer" \
    "$SPARKLE_VERSION/XPCServices/Installer.xpc" \
    "$SPARKLE_VERSION" \
    "$SPARKLE_FRAMEWORK"; do
    if [[ -e "$path" ]]; then
      codesign --force --options runtime --timestamp --sign "$IDENTITY" "$path"
    fi
  done
fi

log "Signing app executable"
codesign --force --options runtime --timestamp --entitlements "$TMP_ENTITLEMENTS" --sign "$IDENTITY" "$APP_PATH/Contents/MacOS/$APP_NAME"

log "Signing app bundle"
codesign --force --options runtime --timestamp --entitlements "$TMP_ENTITLEMENTS" --sign "$IDENTITY" "$APP_PATH"

log "Verifying"
codesign --verify --verbose=2 "$APP_PATH"
rm -f "$TMP_ENTITLEMENTS"
log "Done codesigning $APP_PATH"
