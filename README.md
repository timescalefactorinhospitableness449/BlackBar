# BlackBar

[![CI](https://github.com/openclaw/BlackBar/actions/workflows/ci.yml/badge.svg)](https://github.com/openclaw/BlackBar/actions/workflows/ci.yml)

Native macOS menu bar app for Blacksmith CI status and live vCPU usage.

BlackBar sits in the menu bar, shows the current Blacksmith core count, and opens into an AppKit-native menu with status, live job totals, platform buckets, a tiny history graph, and links back to Blacksmith and GitHub Actions.

## Features

- Live vCPU and job totals from Blacksmith's dashboard API.
- Public Blacksmith status from `status.blacksmith.sh`.
- Platform breakdown for `amd64`, `arm64`, and `macos`.
- Compact menu bar graph with dynamic width for larger core counts.
- Native menu, native Settings window, no SwiftUI popover shell.
- GitHub login through Blacksmith's OAuth flow in a WebKit window.
- Session cookie stored in Keychain and cached in memory to avoid repeated prompts.
- Sparkle-based automatic updates for signed release builds.

## Install

Download the latest `BlackBar-<version>.zip` from GitHub Releases, unzip it, and move `BlackBar.app` to `/Applications`.

BlackBar is a menu bar app. It does not show a Dock icon.

## Login

1. Launch BlackBar.
2. Open the menu bar item.
3. Choose `Login with GitHub`.
4. Complete the Blacksmith login.

The login stores the Blacksmith session cookie in the macOS Keychain. Polling uses the cached in-memory cookie after launch, so normal refreshes do not keep touching Keychain.

## Settings

Defaults:

- organization: `openclaw`
- repository filter: empty, meaning all visible org usage
- refresh interval: `60s`

Use `Settings...` from the menu to change the org, optional repository filter, or polling interval.

## Development

Requirements:

- macOS 14 or newer
- Xcode / Swift toolchain

Build:

```sh
swift build -c release
```

Package an app bundle:

```sh
make app
```

Run locally:

```sh
make run
```

CI-equivalent local check:

```sh
make ci
```

## Release

BlackBar uses the same Sparkle release shape as RepoBar:

- `version.env` owns `MARKETING_VERSION` and `BUILD_NUMBER`.
- `CHANGELOG.md` owns release notes.
- `Scripts/package_app.sh` builds the `.app`, embeds `Sparkle.framework`, and writes release metadata.
- `Scripts/codesign_app.sh` signs the app, nested Sparkle framework, Sparkle updater, XPC services, and the main bundle.
- `Scripts/sign-and-notarize.sh` builds, signs, notarizes, staples, and zips the release app.
- `Scripts/release.sh` tags, creates the GitHub release, uploads app and dSYM zips, updates `appcast.xml`, and verifies release assets.
- `Scripts/verify_appcast.sh` verifies Sparkle enclosure length and ed25519 signature.
- `Scripts/test_live_update.sh` smoke-tests an update from a previous release.

The app uses Sparkle's public ed25519 key from `Resources/Info.plist`; the matching private key must be passed through `SPARKLE_PRIVATE_KEY_FILE` during release.

Required release environment:

```sh
export APP_STORE_CONNECT_API_KEY_P8='...'
export APP_STORE_CONNECT_KEY_ID='...'
export APP_STORE_CONNECT_ISSUER_ID='...'
export SPARKLE_PRIVATE_KEY_FILE=/path/to/sparkle-ed25519.key
```

Cut a release:

```sh
make release
```

Before running the release script, replace the `Unreleased` date in `CHANGELOG.md` with the release date.
