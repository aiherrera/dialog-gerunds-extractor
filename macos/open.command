#!/bin/zsh
set -euo pipefail

root="$(cd "$(dirname "$0")" && pwd)"
cd "$root"

swift build -c release

app="$root/Andante.app"
rm -rf "$app" "$root/Gerundios.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$root/.build/release/Gerundios" "$app/Contents/MacOS/Gerundios"
cp "$root/Info.plist" "$app/Contents/Info.plist"
cp "$root/Resources/andante-icon.png" "$app/Contents/Resources/andante-icon.png"

iconset="$(mktemp -d)/Andante.iconset"
mkdir -p "$iconset"
sips -s format png -z 16 16 "$root/Resources/andante-icon.png" --out "$iconset/icon_16x16.png" >/dev/null
sips -s format png -z 32 32 "$root/Resources/andante-icon.png" --out "$iconset/icon_16x16@2x.png" >/dev/null
sips -s format png -z 32 32 "$root/Resources/andante-icon.png" --out "$iconset/icon_32x32.png" >/dev/null
sips -s format png -z 64 64 "$root/Resources/andante-icon.png" --out "$iconset/icon_32x32@2x.png" >/dev/null
sips -s format png -z 128 128 "$root/Resources/andante-icon.png" --out "$iconset/icon_128x128.png" >/dev/null
sips -s format png -z 256 256 "$root/Resources/andante-icon.png" --out "$iconset/icon_128x128@2x.png" >/dev/null
sips -s format png -z 256 256 "$root/Resources/andante-icon.png" --out "$iconset/icon_256x256.png" >/dev/null
sips -s format png -z 512 512 "$root/Resources/andante-icon.png" --out "$iconset/icon_256x256@2x.png" >/dev/null
sips -s format png -z 512 512 "$root/Resources/andante-icon.png" --out "$iconset/icon_512x512.png" >/dev/null
sips -s format png -z 1024 1024 "$root/Resources/andante-icon.png" --out "$iconset/icon_512x512@2x.png" >/dev/null
iconutil -c icns "$iconset" -o "$app/Contents/Resources/AppIcon.icns"

codesign --force --sign - "$app" >/dev/null

echo "$app"
open "$app"
