# Developer ID Distribution

This repository targets public distribution outside the Mac App Store.

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

```bash
scripts/build_release_dmg.sh
```

This archives the app, exports a Developer ID signed `.app`, and creates a DMG in:

```bash
dist/sparkle/
```

## Notarize and staple

```bash
scripts/build_release_dmg.sh --notarize
```

Or notarize an existing DMG directly:

```bash
scripts/notarize_dmg.sh dist/sparkle/<your-dmg>
```

## Generate Sparkle appcast

After placing notarized DMG or ZIP archives in `dist/sparkle/`:

```bash
SPARKLE_RELEASE_TAG=v0.1.0 scripts/generate_sparkle_appcast.sh dist/sparkle
```

This updates:

```bash
docs/release/appcast.xml
```

If you do not use GitHub Releases, you can instead provide a full download prefix:

```bash
SPARKLE_DOWNLOAD_URL_PREFIX=https://example.com/downloads/v0.1.0 \
scripts/generate_sparkle_appcast.sh dist/sparkle
```

## Current feed URL

`https://lbin91.github.io/nudgewhip/release/appcast.xml`
