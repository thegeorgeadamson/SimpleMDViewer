#!/usr/bin/env bash
# Build a Release .app and package it as a drag-to-install DMG.
# Output: dist/SimpleMDViewer.dmg

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

APP_NAME="SimpleMDViewer"
SCHEME="$APP_NAME"
BUILD_DIR="build"
STAGING_DIR="dmg-staging"
DIST_DIR="dist"
DMG_PATH="$DIST_DIR/$APP_NAME.dmg"
APP_PATH="$BUILD_DIR/Build/Products/Release/$APP_NAME.app"

rm -rf "$BUILD_DIR" "$STAGING_DIR" "$DMG_PATH"
mkdir -p "$DIST_DIR" "$STAGING_DIR"

echo "→ Building $APP_NAME (Release, ad-hoc signed)"
xcodebuild \
    -project "$APP_NAME.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    CODE_SIGN_IDENTITY=- \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    build | tail -5

echo "→ Staging DMG contents"
cp -R "$APP_PATH" "$STAGING_DIR/"
ln -sf /Applications "$STAGING_DIR/Applications"

echo "→ Creating DMG"
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

rm -rf "$STAGING_DIR"

echo "✓ $DMG_PATH"
ls -lh "$DMG_PATH"
