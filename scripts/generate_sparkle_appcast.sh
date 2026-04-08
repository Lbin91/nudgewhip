#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPARKLE_BIN_DIR="$ROOT_DIR/.build/SourcePackages/artifacts/sparkle/Sparkle/bin"
APPCAST_TOOL="$SPARKLE_BIN_DIR/generate_appcast"

ARCHIVES_DIR="${1:-$ROOT_DIR/dist/sparkle}"
KEYCHAIN_ACCOUNT="${SPARKLE_KEYCHAIN_ACCOUNT:-com.bongjinlee.nudgewhip}"
APPCAST_OUTPUT="${SPARKLE_APPCAST_OUTPUT:-$ROOT_DIR/docs/release/appcast.xml}"
RELEASE_LINK="${SPARKLE_RELEASE_LINK:-https://github.com/Lbin91/nudgewhip/releases}"
RELEASE_TAG="${SPARKLE_RELEASE_TAG:-}"
DOWNLOAD_URL_PREFIX="${SPARKLE_DOWNLOAD_URL_PREFIX:-}"

if [[ ! -x "$APPCAST_TOOL" ]]; then
  echo "Sparkle generate_appcast tool not found at: $APPCAST_TOOL" >&2
  echo "Run an Xcode build first to resolve the Sparkle package artifacts." >&2
  exit 1
fi

if [[ ! -d "$ARCHIVES_DIR" ]]; then
  echo "Archives directory does not exist: $ARCHIVES_DIR" >&2
  echo "Place notarized DMG or ZIP updates in this directory before generating the appcast." >&2
  exit 1
fi

if [[ -z "$DOWNLOAD_URL_PREFIX" ]]; then
  if [[ -z "$RELEASE_TAG" ]]; then
    echo "Missing release download URL context." >&2
    echo "Set either SPARKLE_DOWNLOAD_URL_PREFIX or SPARKLE_RELEASE_TAG before generating the appcast." >&2
    echo "Example: SPARKLE_RELEASE_TAG=v0.1.0 scripts/generate_sparkle_appcast.sh dist/sparkle" >&2
    exit 1
  fi

  DOWNLOAD_URL_PREFIX="https://github.com/Lbin91/nudgewhip/releases/download/$RELEASE_TAG/"
fi

mkdir -p "$(dirname "$APPCAST_OUTPUT")"

"$APPCAST_TOOL" \
  --account "$KEYCHAIN_ACCOUNT" \
  --download-url-prefix "$DOWNLOAD_URL_PREFIX" \
  --link "$RELEASE_LINK" \
  -o "$APPCAST_OUTPUT" \
  "$ARCHIVES_DIR"

echo "Wrote Sparkle appcast to: $APPCAST_OUTPUT"
