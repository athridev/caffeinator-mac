#!/bin/zsh
set -euo pipefail

SCRIPT_DIR=${0:A:h}
BUILD_DIR="$SCRIPT_DIR/.build"
APP_DIR="$BUILD_DIR/Caffeinator.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
ICONSET_DIR="$BUILD_DIR/Caffeinator.iconset"
COMPOSED_ICON="$BUILD_DIR/Caffeinator-composed.png"
OUTPUT_DIR=${1:-"$SCRIPT_DIR/dist"}

compatibility_flags=()
if swiftc -frontend -help-hidden 2>/dev/null | grep -q "downgrade-typecheck-interface-error"; then
  compatibility_flags=(-Xfrontend -downgrade-typecheck-interface-error)
fi

mkdir -p "$MACOS_DIR" "$RESOURCES_DIR" "$ICONSET_DIR" "$OUTPUT_DIR"

for arch in arm64 x86_64
do
  mkdir -p "$BUILD_DIR/ModuleCache-$arch"
  swiftc \
    -target "$arch-apple-macosx13.0" \
    -swift-version 5 \
    "${compatibility_flags[@]}" \
    -module-cache-path "$BUILD_DIR/ModuleCache-$arch" \
    -O \
    -whole-module-optimization \
    -framework AppKit \
    -framework Carbon \
    -framework QuartzCore \
    "$SCRIPT_DIR"/Sources/*.swift \
    -o "$BUILD_DIR/Caffeinator-$arch"
done
lipo -create \
  "$BUILD_DIR/Caffeinator-arm64" \
  "$BUILD_DIR/Caffeinator-x86_64" \
  -output "$MACOS_DIR/Caffeinator"

cp "$SCRIPT_DIR/Info.plist" "$CONTENTS_DIR/Info.plist"

mkdir -p "$BUILD_DIR/ModuleCache-tools"
swiftc \
  -swift-version 5 \
  "${compatibility_flags[@]}" \
  -module-cache-path "$BUILD_DIR/ModuleCache-tools" \
  -O \
  -framework AppKit \
  "$SCRIPT_DIR/Tools/IconComposer.swift" \
  -o "$BUILD_DIR/icon-composer"
"$BUILD_DIR/icon-composer" "$SCRIPT_DIR/Assets/AppIconSource.png" "$COMPOSED_ICON"

for spec in \
  "16 icon_16x16.png" \
  "32 icon_16x16@2x.png" \
  "32 icon_32x32.png" \
  "64 icon_32x32@2x.png" \
  "128 icon_128x128.png" \
  "256 icon_128x128@2x.png" \
  "256 icon_256x256.png" \
  "512 icon_256x256@2x.png" \
  "512 icon_512x512.png" \
  "1024 icon_512x512@2x.png"
do
  size=${spec%% *}
  name=${spec#* }
  sips -s format png -z "$size" "$size" "$COMPOSED_ICON" --out "$ICONSET_DIR/$name" >/dev/null
done

iconutil -c icns "$ICONSET_DIR" -o "$RESOURCES_DIR/Caffeinator.icns"
codesign --force --deep --sign - "$APP_DIR" >/dev/null

ditto "$APP_DIR" "$OUTPUT_DIR/Caffeinator.app"
ditto -c -k --keepParent "$OUTPUT_DIR/Caffeinator.app" "$OUTPUT_DIR/Caffeinator-macOS.zip"

echo "$OUTPUT_DIR/Caffeinator.app"
