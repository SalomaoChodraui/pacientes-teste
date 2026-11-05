#!/bin/zsh
set -e
cd "$(dirname "$0")"
APP=~/Applications/"CPF Fake.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
swiftc -O -target arm64-apple-macos13 main.swift -o /tmp/cpf-arm
 swiftc -O -target x86_64-apple-macos13 main.swift -o /tmp/cpf-x86
 lipo -create /tmp/cpf-arm /tmp/cpf-x86 -output "$APP/Contents/MacOS/CPFFake"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>com.salomao.cpffake</string>
<key>CFBundleName</key><string>CPF Fake</string>
<key>CFBundleExecutable</key><string>CPFFake</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>LSUIElement</key><true/>
<key>LSMinimumSystemVersion</key><string>13.0</string>
</dict></plist>
PLIST
codesign --force -s - "$APP"
echo "$APP"
