# Developer ID Distribution

This repository targets public distribution outside the Mac App Store.

> Local release automation is intentionally not committed to the public repository.
> The steps below describe the required flow, but the exact archive/export/notarize
> scripts are maintained locally.

## Prerequisites

- `Developer ID Application` certificate installed in the local keychain
- `Sparkle` public EdDSA key embedded in the app build settings
- `notarytool` credential profile stored in the keychain
- GitHub Pages serving `docs/` so `release/appcast.xml` is reachable

## One-time setup

Create a notary profile in the local keychain:

```bash
xcrun notarytool store-credentials nudgewhip-notary \
  --apple-id <APPLE_ID> \
  --team-id KCS6FN2MJD \
  --password <APP_SPECIFIC_PASSWORD>
```

## Build a public DMG

Required flow:

1. Archive the app for generic macOS distribution
2. Export a `Developer ID Application` signed `.app`
3. Package the exported app into a DMG for public distribution
4. Place the final DMG in a release artifacts directory such as `dist/sparkle/`

## Notarize and staple

Required flow:

1. Submit the DMG to Apple using `xcrun notarytool submit --wait`
2. Staple the approved ticket with `xcrun stapler staple`
3. Validate the stapled DMG with `xcrun stapler validate`

## Generate Sparkle appcast

After placing notarized DMG or ZIP archives in `dist/sparkle/`:

1. Run Sparkle's `generate_appcast` tool locally
2. Point the generated enclosure URLs at your public download location
3. Publish the resulting `docs/release/appcast.xml`

## Current feed URL

`https://lbin91.github.io/nudgewhip/release/appcast.xml`
