#!/bin/zsh
# Gera o Tern-X.Y.Z.dmg universal e atualiza o appcast do Sparkle.
# A versão vem de MARKETING_VERSION no projeto. A chave EdDSA fica no Keychain (conta "tern").
#
# Uso: scripts/release.sh
# Variáveis opcionais: BUILD_DIR (padrão: build), APPCAST (padrão: site/appcast.xml)
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION=$(grep -m1 'MARKETING_VERSION = ' Tern.xcodeproj/project.pbxproj | sed -E 's/.*= ([^;]+);/\1/')
BUILD_DIR=${BUILD_DIR:-build}
APPCAST=${APPCAST:-site/appcast.xml}
DD="$BUILD_DIR/DerivedData"
OUT="$BUILD_DIR/release-$VERSION"
SPARKLE_BIN="$DD/SourcePackages/artifacts/sparkle/Sparkle/bin"

echo "==> Tern $VERSION"
rm -rf "$OUT"
mkdir -p "$OUT/dmg-root" "$OUT/updates"

xcodebuild -project Tern.xcodeproj -scheme Tern -configuration Release \
  -destination 'generic/platform=macOS' -derivedDataPath "$DD" \
  ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_IDENTITY="-" CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM="" \
  -quiet build

ditto "$DD/Build/Products/Release/Tern.app" "$OUT/dmg-root/Tern.app"
ln -s /Applications "$OUT/dmg-root/Applications"
DMG="$OUT/updates/Tern-$VERSION.dmg"
hdiutil create -volname Tern -srcfolder "$OUT/dmg-root" -ov -format UDZO "$DMG" >/dev/null

NOTES=()
if [[ -f "scripts/release-notes/$VERSION.html" ]]; then
  cp "scripts/release-notes/$VERSION.html" "$OUT/updates/Tern-$VERSION.html"
  NOTES=(--embed-release-notes)
fi

"$SPARKLE_BIN/generate_appcast" --account tern \
  --download-url-prefix "https://github.com/gitlherme/tern/releases/download/v$VERSION/" \
  --full-release-notes-url "https://github.com/gitlherme/tern/releases" \
  --link "https://tern.gitlher.me" \
  "${NOTES[@]}" -o "$APPCAST" "$OUT/updates"

echo "==> DMG:     $DMG"
echo "==> SHA-256: $(shasum -a 256 "$DMG" | cut -d' ' -f1)"
echo "==> Appcast: $APPCAST"
echo "Publique a release v$VERSION com esse .dmg ANTES de enviar o appcast para a main."
