#!/bin/bash
# Build MyClaw.app bundle from SwiftPM binary
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP_NAME="My Claw"
BUNDLE_ID="com.nityesh.my-claw"
APP_DIR="$PROJECT_DIR/dist/$APP_NAME.app"

# Extract version from UpdateChecker.swift (single source of truth)
VERSION=$(grep 'static let currentVersion' "$PROJECT_DIR/MyClaw/Sources/MyClaw/Services/UpdateChecker.swift" | sed 's/.*"\(.*\)".*/\1/')
if [ -z "$VERSION" ]; then
    VERSION="1.0.0"
    echo "Warning: Could not extract version, defaulting to $VERSION"
fi
echo "Version: $VERSION"

echo "Building release binary..."
cd "$PROJECT_DIR/MyClaw"
swift build -c release

echo "Creating app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Copy binary
cp .build/release/MyClaw "$APP_DIR/Contents/MacOS/MyClaw"

# Copy icon
if [ -f "$PROJECT_DIR/MyClaw/Sources/MyClaw/Resources/AppIcon.icns" ]; then
    cp "$PROJECT_DIR/MyClaw/Sources/MyClaw/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
    echo "Icon bundled."
fi

# Create Info.plist
cat > "$APP_DIR/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>My Claw</string>
    <key>CFBundleDisplayName</key>
    <string>My Claw</string>
    <key>CFBundleIdentifier</key>
    <string>com.nityesh.my-claw</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleExecutable</key>
    <string>MyClaw</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <false/>
</dict>
</plist>
PLIST

echo ""
echo "✓ Built: $APP_DIR"
echo ""
echo "To install, run:"
echo "  cp -r \"$APP_DIR\" /Applications/"
echo ""
echo "Or drag '$APP_DIR' to your Applications folder in Finder."
