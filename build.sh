#!/bin/bash
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
APP="$DIR/CopyPasteMagic.app"
BIN="$APP/Contents/MacOS/CopyPasteMagic"

# Kill existing instance
pkill -f "CopyPasteMagic" 2>/dev/null && sleep 0.3 || true

# Build
echo "⚙️  Building..."
swift build --package-path "$DIR" 2>&1

# Copy binary to .app bundle
mkdir -p "$APP/Contents/MacOS"
cp "$DIR/.build/debug/CopyPasteMagic" "$BIN"
cp "$DIR/Resources/Info.plist" "$APP/Contents/Info.plist"

# Sign — use dev certificate if available, otherwise ad-hoc
IDENTITY=$(security find-identity -v -p codesigning 2>/dev/null | head -1 | grep -o '".*"' | tr -d '"')
if [ -n "$IDENTITY" ]; then
    codesign -fs "$IDENTITY" "$APP" --force 2>/dev/null
    echo "✅ Signé avec: $IDENTITY"
else
    codesign -fs - "$APP" --force 2>/dev/null
    echo "⚠️  Signature ad-hoc (permission Accessibilité à réautoriser)"
fi

# Launch
echo "🚀 Launching CopyPasteMagic..."
open "$APP"
