#!/bin/zsh
set -e
cd "$(dirname "$0")"
APP=~/Applications/"Pacientes Teste.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
# Ícone: Icon/AppIcon.icon vira Resources/Assets.car e AppIcon.icns quando muda.
if [[ ! -f Resources/Assets.car || -n "$(find Icon/AppIcon.icon -newer Resources/Assets.car | head -1)" ]]; then tools/make_icon.sh; fi
cp -X Resources/Assets.car Resources/AppIcon.icns "$APP/Contents/Resources/"
swiftc -O -target arm64-apple-macos13 main.swift gerador.swift dados.swift enderecos.swift -o /tmp/pacientes-arm
 swiftc -O -target x86_64-apple-macos13 main.swift gerador.swift dados.swift enderecos.swift -o /tmp/pacientes-x86
 lipo -create /tmp/pacientes-arm /tmp/pacientes-x86 -output "$APP/Contents/MacOS/PacientesTeste"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>com.salomao.pacientesteste</string>
<key>CFBundleName</key><string>Pacientes Teste</string>
<key>CFBundleExecutable</key><string>PacientesTeste</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>CFBundleIconName</key><string>AppIcon</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>LSUIElement</key><true/>
<key>LSMinimumSystemVersion</key><string>13.0</string>
</dict></plist>
PLIST
codesign --force -s - "$APP"
echo "$APP"
