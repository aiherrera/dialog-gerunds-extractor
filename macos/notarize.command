#!/bin/zsh
set -euo pipefail

root="$(cd "$(dirname "$0")" && pwd)"
app="$root/Andante.app"
zip="$root/Andante.zip"
profile="${NOTARY_PROFILE:-andante}"

if [[ ! -d "$app" ]]; then
  echo "No está Andante.app. Ejecuta primero macos/open.command." >&2
  exit 1
fi

if ! xcrun notarytool history --keychain-profile "$profile" >/dev/null 2>&1; then
  echo "Falta el perfil de notarización «$profile»." >&2
  echo "Créalo una vez, con una contraseña de app de appleid.apple.com:" >&2
  echo "xcrun notarytool store-credentials $profile --apple-id TU_APPLE_ID --team-id W38F27R93G" >&2
  exit 1
fi

ditto -c -k --keepParent "$app" "$zip"
xcrun notarytool submit "$zip" --keychain-profile "$profile" --wait
xcrun stapler staple "$app"
echo "Notarizada: $app"
echo "Para enviar: $zip"
