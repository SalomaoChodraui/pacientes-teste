#!/bin/zsh
# Assina com Developer ID, notariza e grampeia. Gera CPF-Fake.zip pronto para distribuir.
set -e
cd "$(dirname "$0")"
./build.sh >/dev/null
APP=~/Applications/"CPF Fake.app"
ID=$(security find-identity -v -p codesigning | grep -o '"Developer ID Application:[^"]*"' | head -1 | tr -d '"')
[[ -z "$ID" ]] && { echo "Falta o certificado Developer ID Application no Keychain."; exit 1; }
codesign --force --options runtime --timestamp -s "$ID" "$APP"
rm -f CPF-Fake.zip
ditto -c -k --keepParent "$APP" CPF-Fake.zip
xcrun notarytool submit CPF-Fake.zip --keychain-profile notary --wait
xcrun stapler staple "$APP"
rm -f CPF-Fake.zip
ditto -c -k --keepParent "$APP" CPF-Fake.zip
spctl -a -vv "$APP"
echo "Pronto: $(pwd)/CPF-Fake.zip"
