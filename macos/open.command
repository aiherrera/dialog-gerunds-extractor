#!/bin/zsh
set -euo pipefail

root="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$root/.." && pwd)"
cd "$root"

swift build -c release -Xswiftc -cache-disable-replay

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

swiftc -O -framework AppKit -o "$root/.build/mask-icon" "$root/mask-icon.swift"
mask_icon() {
  local file="$1"
  local tmp="${file}.masked.png"
  "$root/.build/mask-icon" "$file" "$tmp" || exit 1
  mv "$tmp" "$file"
}
mask_icon "$app/Contents/Resources/andante-icon.png"
for icon in "$iconset"/*.png; do
  mask_icon "$icon"
done
iconutil -c icns "$iconset" -o "$app/Contents/Resources/AppIcon.icns"
rm -rf "$(dirname "$iconset")"

node_src="$(ls -d "$HOME"/.nvm/versions/node/*/bin/node 2>/dev/null | sort -V | tail -1 || true)"
if [[ -z "$node_src" ]]; then
  node_src="$(command -v node || true)"
fi
if [[ -z "$node_src" || ! -e "$node_src" ]]; then
  echo "No encuentro un binario de Node para incluir en la app." >&2
  exit 1
fi
cp -L "$node_src" "$app/Contents/Resources/node"
chmod 755 "$app/Contents/Resources/node"

if [[ ! -d "$repo/node_modules/mammoth" && ! -L "$repo/node_modules/mammoth" ]]; then
  echo "Faltan dependencias. Ejecuta pnpm install en la raíz del proyecto." >&2
  exit 1
fi

engine="$app/Contents/Resources/engine"
mkdir -p "$engine"
cp "$repo/package.json" "$repo/index.js" "$engine/"
rsync -a --exclude '.DS_Store' --exclude 'exclusion_list.txt' "$repo/utils/" "$engine/utils/"

stage="$(mktemp -d)"
cp "$repo/package.json" "$stage/package.json"
npm_bin="$(dirname "$node_src")/npm"
if [[ ! -x "$npm_bin" ]]; then
  npm_bin="$(command -v npm)"
fi
"$npm_bin" install --prefix "$stage" --omit=dev --no-audit --no-fund
rsync -a --exclude '.bin' "$stage/node_modules/" "$engine/node_modules/"
rm -rf "$stage"

if ! "$app/Contents/Resources/node" -e "require(process.argv[1])" "$engine/node_modules/mammoth" >/dev/null; then
  echo "El motor no puede cargar mammoth." >&2
  exit 1
fi

identity="$(security find-identity -p codesigning -v | sed -n 's/.*"\(Developer ID Application:.*\)"/\1/p' | head -1)"
if [[ -n "$identity" ]]; then
  codesign --force --options runtime --timestamp \
    --entitlements "$root/node.entitlements.plist" \
    --sign "$identity" "$app/Contents/Resources/node"
  codesign --force --options runtime --timestamp \
    --sign "$identity" "$app"
  echo "Firmada con $identity"
else
  codesign --force --sign - "$app" >/dev/null
  echo "Firma local: no hay certificado Developer ID en este Mac."
fi

echo "$app"
open "$app"
