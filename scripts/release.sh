#!/bin/zsh
# Gera o Tern-X.Y.Z.dmg universal e atualiza o appcast do Sparkle.
# A versão vem de MARKETING_VERSION no projeto. A chave EdDSA fica no Keychain (conta "tern").
#
# Uso: scripts/release.sh
# Variáveis opcionais: BUILD_DIR (padrão: build), APPCAST (padrão: site/appcast.xml),
#   SIGN_IDENTITY (padrão: certificado "Tern Code Signing" do Keychain)
#
# O app é assinado com um certificado autoassinado estável. Assim a identidade do app
# (bundle id + certificado) não muda entre versões e o macOS mantém a Acessibilidade
# depois de cada atualização. Assinatura ad-hoc mudaria a cada build.
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION=$(grep -m1 'MARKETING_VERSION = ' Tern.xcodeproj/project.pbxproj | sed -E 's/.*= ([^;]+);/\1/')
BUILD_DIR=${BUILD_DIR:-build}
APPCAST=${APPCAST:-site/appcast.xml}
DD="$BUILD_DIR/DerivedData"
OUT="$BUILD_DIR/release-$VERSION"
SPARKLE_BIN="$DD/SourcePackages/artifacts/sparkle/Sparkle/bin"
SIGN_IDENTITY=${SIGN_IDENTITY:-$(security find-identity -p codesigning | awk -F'"' '/"Tern Code Signing"/ {split($1, a, " "); print a[2]; exit}')}
if [[ -z "$SIGN_IDENTITY" ]]; then
  echo "ERRO: certificado \"Tern Code Signing\" não encontrado no Keychain. Sem ele, a release" >&2
  echo "sairia ad-hoc e todo usuário teria que conceder Acessibilidade de novo." >&2
  exit 1
fi

echo "==> Tern $VERSION"
rm -rf "$OUT"
mkdir -p "$OUT/dmg-root" "$OUT/updates"

xcodebuild -project Tern.xcodeproj -scheme Tern -configuration Release \
  -destination 'generic/platform=macOS' -derivedDataPath "$DD" \
  ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_IDENTITY="-" CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM="" \
  -quiet build

APP="$DD/Build/Products/Release/Tern.app"

# Reassina de dentro para fora, como o Sparkle orienta (sem --deep).
echo "==> Assinando com $SIGN_IDENTITY"
SPARKLE="$APP/Contents/Frameworks/Sparkle.framework/Versions/B"
sign() { codesign --force --sign "$SIGN_IDENTITY" --options runtime "$@" 2>&1 | grep -v "replacing existing signature" || true; }
for xpc in "$SPARKLE"/XPCServices/*.xpc; do sign --preserve-metadata=entitlements "$xpc"; done
sign "$SPARKLE/Autoupdate"
sign "$SPARKLE/Updater.app"
sign "$APP/Contents/Frameworks/Sparkle.framework"
sign --entitlements Tern/Tern.entitlements "$APP"
codesign --verify --deep --strict "$APP"
if ! codesign -d -r- "$APP" 2>&1 | grep -q 'certificate root = H"'; then
  echo "ERRO: a identidade do app não ficou presa ao certificado." >&2
  exit 1
fi

# Abre o app por alguns segundos: se o dyld ou o macOS recusarem algo (como na 1.1.0,
# que fechava ao abrir por validação de biblioteca), a release para aqui.
echo "==> Testando se o app abre"
"$APP/Contents/MacOS/Tern" >/dev/null 2>&1 &
SMOKE_PID=$!
sleep 4
if ! kill -0 "$SMOKE_PID" 2>/dev/null; then
  echo "ERRO: o Tern fechou sozinho ao abrir. Veja ~/Library/Logs/DiagnosticReports/Tern-*.ips" >&2
  exit 1
fi
kill "$SMOKE_PID"
wait "$SMOKE_PID" 2>/dev/null || true

ditto "$APP" "$OUT/dmg-root/Tern.app"
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
