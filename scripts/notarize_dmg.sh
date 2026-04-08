#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <path-to-dmg> [--profile <keychain-profile>]" >&2
  exit 1
fi

DMG_PATH=""
NOTARY_PROFILE="${NOTARYTOOL_KEYCHAIN_PROFILE:-nudgewhip-notary}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      NOTARY_PROFILE="$2"
      shift 2
      ;;
    *)
      if [[ -z "$DMG_PATH" ]]; then
        DMG_PATH="$1"
      else
        echo "Unexpected argument: $1" >&2
        exit 1
      fi
      shift
      ;;
  esac
done

if [[ -z "$DMG_PATH" ]]; then
  echo "Missing DMG path." >&2
  exit 1
fi

if [[ ! -f "$DMG_PATH" ]]; then
  echo "DMG not found: $DMG_PATH" >&2
  exit 1
fi

if ! xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" >/dev/null 2>&1; then
  echo "Notary keychain profile '$NOTARY_PROFILE' is not configured." >&2
  echo "Create it first with:" >&2
  echo "  xcrun notarytool store-credentials $NOTARY_PROFILE --apple-id <APPLE_ID> --team-id KCS6FN2MJD --password <APP_SPECIFIC_PASSWORD>" >&2
  exit 1
fi

echo "Submitting DMG for notarization: $DMG_PATH"
xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait

echo "Stapling ticket to DMG: $DMG_PATH"
xcrun stapler staple "$DMG_PATH"

echo "Validating stapled ticket: $DMG_PATH"
xcrun stapler validate "$DMG_PATH"

echo "Notarization complete: $DMG_PATH"
