#!/usr/bin/env bash
# Cuts a Developer ID release: universal archive, Developer ID signing, notarization, stapling,
# zip, and a draft GitHub Release. See RELEASING.md. (The App Store build goes through Xcode's
# Organizer instead.)
#
#   scripts/release.sh <version> [--dry-run]
#
# --dry-run archives and zips with your development signature, and skips the Developer ID
# export, notarization, tagging, and the GitHub Release.
#
# Environment:
#   NOTARY_PROFILE  notarytool keychain profile name (default: hautekey; any profile for team S4F666RB9G works)
set -euo pipefail

cd "$(dirname "$0")/.."

VERSION="${1:?usage: release.sh <version> [--dry-run]}"
DRY_RUN=false
[[ "${2:-}" == "--dry-run" ]] && DRY_RUN=true

[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "version must look like 1.2.3" >&2; exit 1; }
TAG="v$VERSION"
ZIP="build/DinkyCal-$VERSION.zip"
ARCHIVE="build/DinkyCal.xcarchive"
EXPORT="build/export"
APP="$EXPORT/DinkyCal.app"

if ! $DRY_RUN; then
    [[ -z "$(git status --porcelain)" ]] || { echo "commit or stash your changes first" >&2; exit 1; }
    [[ "$(git branch --show-current)" == "main" ]] || { echo "release from main" >&2; exit 1; }
    ! git rev-parse -q --verify "refs/tags/$TAG" >/dev/null || { echo "$TAG already exists" >&2; exit 1; }
    command -v gh >/dev/null || { echo "needs the GitHub CLI (brew install gh)" >&2; exit 1; }
fi

BUILD_NUMBER=$(git rev-list --count HEAD)
rm -rf "$ARCHIVE" "$EXPORT"
mkdir -p build

echo "Archiving $VERSION ($BUILD_NUMBER)…"
xcodebuild archive \
    -project DinkyCal.xcodeproj -scheme DinkyCal -configuration Release \
    -archivePath "$ARCHIVE" -destination "generic/platform=macOS" \
    MARKETING_VERSION="$VERSION" CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
    ONLY_ACTIVE_ARCH=NO -quiet

if $DRY_RUN; then
    mkdir -p "$EXPORT"
    cp -R "$ARCHIVE/Products/Applications/DinkyCal.app" "$APP"
else
    xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportPath "$EXPORT" \
        -exportOptionsPlist scripts/ExportOptions-DeveloperID.plist -quiet
fi

echo "Architectures: $(lipo -archs "$APP/Contents/MacOS/DinkyCal")"
codesign --verify --deep --strict "$APP"

rm -f "$ZIP"
if $DRY_RUN; then
    ditto -c -k --keepParent "$APP" "$ZIP"
    echo "Dry run: skipped Developer ID export, notarization, and GitHub Release."
else
    ditto -c -k --keepParent "$APP" "build/notarize.zip"
    xcrun notarytool submit "build/notarize.zip" --keychain-profile "${NOTARY_PROFILE:-hautekey}" --wait
    xcrun stapler staple "$APP"
    rm -f "build/notarize.zip"
    spctl --assess --type execute --verbose "$APP"
    ditto -c -k --keepParent "$APP" "$ZIP"
fi

SHA=$(shasum -a 256 "$ZIP" | cut -d' ' -f1)
echo "Built $ZIP"
echo "sha256 $SHA"

if ! $DRY_RUN; then
    git tag -a "$TAG" -m "Dinky Cal $VERSION"
    git push origin "$TAG"
    # DinkyCal.zip is a stable name, so releases/latest/download/DinkyCal.zip always works.
    cp -f "$ZIP" build/DinkyCal.zip
    gh release create "$TAG" "$ZIP" build/DinkyCal.zip --draft --title "Dinky Cal $VERSION" --generate-notes
    echo "Draft release $TAG created. Review and publish it on GitHub, then update the cask:"
    echo "  version \"$VERSION\""
    echo "  sha256 \"$SHA\""
fi
