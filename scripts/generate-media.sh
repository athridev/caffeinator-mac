#!/bin/zsh
set -euo pipefail

SCRIPT_DIR=${0:A:h}
ROOT_DIR="$SCRIPT_DIR/.."
BUILD_DIR="$ROOT_DIR/.build"
CACHE_DIR="$BUILD_DIR/ModuleCache-social"
TOOL="$BUILD_DIR/social-card-composer"

mkdir -p "$BUILD_DIR" "$CACHE_DIR" "$ROOT_DIR/media"

compatibility_flags=()
if swiftc -frontend -help-hidden 2>/dev/null | grep -q "downgrade-typecheck-interface-error"; then
  compatibility_flags=(-Xfrontend -downgrade-typecheck-interface-error)
fi

swiftc \
  -swift-version 5 \
  "${compatibility_flags[@]}" \
  -module-cache-path "$CACHE_DIR" \
  -O \
  -framework AppKit \
  "$ROOT_DIR/Tools/SocialCardComposer.swift" \
  -o "$TOOL"

"$TOOL" \
  "$ROOT_DIR/media/app-icon.png" \
  "$ROOT_DIR/media/caffeinator-ui.png" \
  "$ROOT_DIR/media/social-preview.png"

echo "$ROOT_DIR/media/social-preview.png"
