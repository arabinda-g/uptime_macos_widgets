#!/bin/zsh
# Builds Uptime.app (host app + WidgetKit extension) without an Xcode project.
#   ./build.sh            build into ./build
#   ./build.sh install    build, copy to /Applications, register and launch
#   ./build.sh preview    render docs/preview.png
#   ./build.sh icon       render Resources/AppIcon.icns and docs/icon.png
set -euo pipefail
cd "${0:A:h}"

SDK=$(xcrun --sdk macosx --show-sdk-path)
TARGET="$(uname -m)-apple-macos15.0"
# Prefer an Apple Development cert (WidgetKit may hide widgets without a team ID).
# Override with IDENTITY=<name or hash>, or IDENTITY=- for ad-hoc signing.
DEV_ID=$(security find-identity -v -p codesigning | awk -F'"' '/"Apple Development:/ {print $2; exit}')
IDENTITY=${IDENTITY:-${DEV_ID:--}}

APP=build/Uptime.app
APPEX=$APP/Contents/PlugIns/UptimeWidgetExtension.appex
SWIFTC=(xcrun swiftc -swift-version 5 -O -parse-as-library -target "$TARGET" -sdk "$SDK")

if [[ ${1:-} == preview ]]; then
  mkdir -p build docs
  "${SWIFTC[@]}" Sources/Shared/*.swift Preview/Render.swift -o build/render
  build/render docs/preview.png
  echo "Rendered docs/preview.png"
  exit 0
fi

if [[ ${1:-} == icon ]]; then
  rm -rf build/AppIcon.iconset && mkdir -p build docs
  "${SWIFTC[@]}" Sources/Shared/*.swift Icon/AppIcon.swift -o build/icon-render
  build/icon-render build/AppIcon.iconset docs/icon.png
  iconutil -c icns -o Resources/AppIcon.icns build/AppIcon.iconset
  echo "Rendered Resources/AppIcon.icns"
  exit 0
fi

echo "Signing with: $IDENTITY"

rm -rf build
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APPEX/Contents/MacOS"

# Like Xcode, enter through Foundation's NSExtensionMain; starting at the Swift
# main skips extension setup and ExtensionFoundation traps on launch.
"${SWIFTC[@]}" -application-extension Sources/Shared/*.swift Sources/Widget/*.swift \
  -Xlinker -e -Xlinker _NSExtensionMain -Xlinker -application_extension \
  -o "$APPEX/Contents/MacOS/UptimeWidgetExtension"
"${SWIFTC[@]}" Sources/Shared/*.swift Sources/App/*.swift \
  -o "$APP/Contents/MacOS/Uptime"

cp Resources/Widget-Info.plist "$APPEX/Contents/Info.plist"
cp Resources/App-Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/"

# Sign inside-out; WidgetKit only loads sandboxed extensions.
codesign --force --sign "$IDENTITY" --entitlements Resources/Sandbox.entitlements "$APPEX"
codesign --force --sign "$IDENTITY" --entitlements Resources/Sandbox.entitlements "$APP"
codesign --verify --deep --strict "$APP"
echo "Built $APP"

if [[ ${1:-} == install ]]; then
  # Stop the old extension too, or macOS keeps rendering with the previous binary.
  pkill -x Uptime 2>/dev/null || true
  pkill -x UptimeWidgetExtension 2>/dev/null || true
  rm -rf /Applications/Uptime.app
  cp -R "$APP" /Applications/
  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f /Applications/Uptime.app
  open /Applications/Uptime.app
  echo "Installed /Applications/Uptime.app"
fi
