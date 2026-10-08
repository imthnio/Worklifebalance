#!/bin/bash
# Builds Worklifebalance.app and the Worklifebalance-<version>.pkg installer into ./build
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT=$(pwd)
NAME=Worklifebalance
BUNDLE_ID=com.imthnio.Worklifebalance
VERSION=$(tr -d '[:space:]' < VERSION)
BUILD="$ROOT/build"
APP="$BUILD/$NAME.app"

rm -rf "$BUILD"
mkdir -p "$BUILD"

echo "==> Compiling ($VERSION)"
for arch in arm64 x86_64; do
    swift build -c release --triple "$arch-apple-macosx13.0" \
        --scratch-path "$ROOT/.build/$arch" \
        -Xswiftc -Osize -Xlinker -dead_strip
done

echo "==> Assembling $NAME.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
lipo -create \
    "$ROOT/.build/arm64/release/$NAME" \
    "$ROOT/.build/x86_64/release/$NAME" \
    -output "$APP/Contents/MacOS/$NAME"
strip -x "$APP/Contents/MacOS/$NAME"
cp Resources/Info.plist "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$APP/Contents/Info.plist"
find Resources -type f ! -name Info.plist -exec cp {} "$APP/Contents/Resources/" \;
codesign --force --deep --sign - "$APP"

echo "==> Building installer"
cat > "$BUILD/component.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<array>
    <dict>
        <key>RootRelativeBundlePath</key>
        <string>$NAME.app</string>
        <key>BundleIsRelocatable</key>
        <false/>
        <key>BundleIsVersionChecked</key>
        <false/>
        <key>BundleHasStrictIdentifier</key>
        <true/>
        <key>BundleOverwriteAction</key>
        <string>upgrade</string>
    </dict>
</array>
</plist>
PLIST
mkdir -p "$BUILD/payload"
cp -R "$APP" "$BUILD/payload/"
pkgbuild \
    --root "$BUILD/payload" \
    --component-plist "$BUILD/component.plist" \
    --scripts scripts/pkg \
    --identifier "$BUNDLE_ID.pkg" \
    --version "$VERSION" \
    --install-location /Applications \
    "$BUILD/component.pkg"

cat > "$BUILD/distribution.xml" <<XML
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="2">
    <title>$NAME $VERSION</title>
    <options customize="never" require-scripts="false" hostArchitectures="arm64,x86_64"/>
    <domains enable_localSystem="true"/>
    <volume-check>
        <allowed-os-versions>
            <os-version min="13.0"/>
        </allowed-os-versions>
    </volume-check>
    <choices-outline>
        <line choice="default"/>
    </choices-outline>
    <choice id="default" visible="false">
        <pkg-ref id="$BUNDLE_ID.pkg"/>
    </choice>
    <pkg-ref id="$BUNDLE_ID.pkg" version="$VERSION">component.pkg</pkg-ref>
</installer-gui-script>
XML
productbuild \
    --distribution "$BUILD/distribution.xml" \
    --package-path "$BUILD" \
    "$BUILD/$NAME-$VERSION.pkg"

rm -rf "$BUILD/payload" "$BUILD/component.pkg" "$BUILD/component.plist" "$BUILD/distribution.xml"
echo "==> Done: $BUILD/$NAME-$VERSION.pkg"
