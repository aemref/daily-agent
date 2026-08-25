#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$PROJECT_DIR/build/Codex Pet.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"
RESOURCES_DIR="$APP_DIR/Contents/Resources"

cd "$PROJECT_DIR"
swift build -c release --product CodexPet

mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
install -m 755 ".build/release/CodexPet" "$MACOS_DIR/CodexPet"
install -m 644 "AppResources/Info.plist" "$APP_DIR/Contents/Info.plist"

codesign --force --deep --sign - "$APP_DIR"
echo "$APP_DIR"
