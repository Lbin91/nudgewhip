#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/nudgewhip.xcodeproj"
SCHEME="${SCHEME:-nudgewhip}"
SOURCE_PACKAGES_DIR="${SOURCE_PACKAGES_DIR:-$ROOT_DIR/.build/SourcePackages}"
EXPORT_OPTIONS_PLIST="${EXPORT_OPTIONS_PLIST:-$ROOT_DIR/scripts/export-options/developer-id.plist}"
DIST_DIR="${DIST_DIR:-$ROOT_DIR/dist}"
ARCHIVE_PATH="$DIST_DIR/archive/NudgeWhip.xcarchive"
EXPORT_DIR="$DIST_DIR/export"
DMG_ROOT_DIR="$DIST_DIR/dmg-root"
SPARKLE_DIR="$DIST_DIR/sparkle"
NOTARIZE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --notarize)
      NOTARIZE=1
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_command xcodebuild
require_command hdiutil
require_command security
require_command /usr/libexec/PlistBuddy

if ! security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
  echo "Developer ID Application certificate not found in the current keychain." >&2
  echo "Install a Developer ID Application certificate before building a public DMG." >&2
  exit 1
fi

rm -rf "$ARCHIVE_PATH" "$EXPORT_DIR" "$DMG_ROOT_DIR"
mkdir -p "$DIST_DIR/archive" "$EXPORT_DIR" "$DMG_ROOT_DIR" "$SPARKLE_DIR"

echo "Archiving $SCHEME for generic macOS distribution..."
xcodebuild archive \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination "generic/platform=macOS" \
  -archivePath "$ARCHIVE_PATH" \
  -clonedSourcePackagesDirPath "$SOURCE_PACKAGES_DIR"

echo "Exporting Developer ID build..."
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$EXPORT_OPTIONS_PLIST"

APP_PATH="$(find "$EXPORT_DIR" -maxdepth 1 -name '*.app' -print -quit)"
if [[ -z "$APP_PATH" ]]; then
  echo "No exported .app found in $EXPORT_DIR" >&2
  exit 1
fi

APP_NAME="$(basename "$APP_PATH" .app)"
INFO_PLIST="$APP_PATH/Contents/Info.plist"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$INFO_PLIST")"
BUILD_NUMBER="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$INFO_PLIST")"
DMG_NAME="${APP_NAME}-${VERSION}-${BUILD_NUMBER}.dmg"
DMG_PATH="$SPARKLE_DIR/$DMG_NAME"

echo "Preparing DMG staging area..."
rm -f "$DMG_PATH"
cp -R "$APP_PATH" "$DMG_ROOT_DIR/"
ln -s /Applications "$DMG_ROOT_DIR/Applications"

echo "Creating DMG: $DMG_PATH"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_ROOT_DIR" \
  -format UDZO \
  "$DMG_PATH"

echo "Verifying exported app signature..."
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

if [[ "$NOTARIZE" -eq 1 ]]; then
  "$ROOT_DIR/scripts/notarize_dmg.sh" "$DMG_PATH"
else
  echo "Skipping notarization. Re-run with --notarize after configuring notarytool credentials."
fi

echo "Release DMG ready: $DMG_PATH"
