#!/bin/zsh
# Assina com Developer ID, notariza e grampeia. Gera Pacientes-Teste.zip pronto para distribuir.
set -e
cd "$(dirname "$0")"
./build.sh >/dev/null
APP=~/Applications/"Pacientes Teste.app"
ID=$(security find-identity -v -p codesigning | grep -o '"Developer ID Application:[^"]*"' | head -1 | tr -d '"')
[[ -z "$ID" ]] && { echo "Falta o certificado Developer ID Application no Keychain."; exit 1; }
codesign --force --options runtime --timestamp -s "$ID" "$APP"
rm -f Pacientes-Teste.zip
ditto -c -k --keepParent "$APP" Pacientes-Teste.zip
xcrun notarytool submit Pacientes-Teste.zip --keychain-profile notary --wait
xcrun stapler staple "$APP"
rm -f Pacientes-Teste.zip
ditto -c -k --keepParent "$APP" Pacientes-Teste.zip
spctl -a -vv "$APP"
echo "Pronto: $(pwd)/Pacientes-Teste.zip"
