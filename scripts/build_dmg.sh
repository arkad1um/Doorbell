#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Doorbell"
BUILD_DIR="$ROOT/.build/release"
DIST_DIR="$ROOT/dist"
APP_BUNDLE="$DIST_DIR/${APP_NAME}.app"
DMG_STAGING="$DIST_DIR/dmg_root"
DMG_PATH="$DIST_DIR/${APP_NAME}.dmg"
DMG_RW="$DIST_DIR/${APP_NAME}-temp.dmg"
PLIST_SRC="$ROOT/Packaging/Info.plist"
RESOURCES_SRC="$ROOT/Sources/Resources"
ICON_PNG="$ROOT/Packaging/dmg-background.png"
ICONSET_DIR="$DIST_DIR/app_icon.iconset"
APP_ICON_ICNS="$DIST_DIR/Doorbell.icns"
DMG_ICON_ICNS="$DIST_DIR/VolumeIcon.icns"

echo "Cleaning dist folder…"
rm -rf "$DIST_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources" "$DMG_STAGING"

if [ -f "$ICON_PNG" ]; then
  echo "Generating app and DMG icons from ${ICON_PNG}…"
  mkdir -p "$ICONSET_DIR"
  sips -z 16 16     "$ICON_PNG" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
  sips -z 32 32     "$ICON_PNG" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
  sips -z 32 32     "$ICON_PNG" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
  sips -z 64 64     "$ICON_PNG" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
  sips -z 128 128   "$ICON_PNG" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
  sips -z 256 256   "$ICON_PNG" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
  sips -z 256 256   "$ICON_PNG" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
  sips -z 512 512   "$ICON_PNG" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
  sips -z 512 512   "$ICON_PNG" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
  sips -z 1024 1024 "$ICON_PNG" --out "$ICONSET_DIR/icon_512x512@2x.png" >/dev/null
  python3 - "$ICONSET_DIR" "$APP_ICON_ICNS" <<'PY'
import pathlib, struct, sys
iconset = pathlib.Path(sys.argv[1])
output = pathlib.Path(sys.argv[2])
size_to_file = {
    16: "icon_16x16.png",
    32: "icon_32x32.png",
    64: "icon_32x32@2x.png",
    128: "icon_128x128.png",
    256: "icon_256x256.png",
    512: "icon_512x512.png",
    1024: "icon_512x512@2x.png",
}
size_to_type = {
    16: b"icp4",
    32: b"icp5",
    64: b"icp6",
    128: b"ic07",
    256: b"ic08",
    512: b"ic09",
    1024: b"ic10",
}
chunks = []
for size, name in size_to_file.items():
    data = (iconset / name).read_bytes()
    ctype = size_to_type[size]
    chunks.append(ctype + struct.pack(">I", len(data) + 8) + data)
content = b"".join(chunks)
with output.open("wb") as f:
    f.write(b"icns")
    f.write(struct.pack(">I", len(content) + 8))
    f.write(content)
PY
  cp "$APP_ICON_ICNS" "$DMG_ICON_ICNS"
else
  echo "Warning: icon source not found at ${ICON_PNG}; app and DMG icons will be default."
fi

echo "Building release binary…"
SWIFTPM_MODULECACHE_OVERRIDE="${SWIFTPM_MODULECACHE_OVERRIDE:-$ROOT/.build/modulecache}" \
SWIFT_MODULE_CACHE_PATH="${SWIFT_MODULE_CACHE_PATH:-$ROOT/.build/modulecache}" \
swift build --disable-sandbox -c release

echo "Assembling app bundle…"
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "$PLIST_SRC" "$APP_BUNDLE/Contents/Info.plist"
if [ -d "$RESOURCES_SRC" ]; then
  cp -R "$RESOURCES_SRC"/. "$APP_BUNDLE/Contents/Resources/"
fi
if [ -f "$APP_ICON_ICNS" ]; then
  cp "$APP_ICON_ICNS" "$APP_BUNDLE/Contents/Resources/Doorbell.icns"
fi

if [ -n "${CODESIGN_IDENTITY:-}" ]; then
  echo "Codesigning app bundle with identity '${CODESIGN_IDENTITY}'…"
  codesign --force --options runtime --timestamp --sign "$CODESIGN_IDENTITY" "$APP_BUNDLE"
  codesign --verify --deep --strict "$APP_BUNDLE"
else
  echo "Skipping app codesign (CODESIGN_IDENTITY not set)."
fi

echo "Preparing DMG staging…"
cp -R "$APP_BUNDLE" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

echo "Creating DMG…"
STAGING_KB=$(du -sk "$DMG_STAGING" | awk '{print $1}')
# add ~20MB padding for .VolumeIcon.icns, background, Finder metadata; floor at 50MB total
PADDING_KB=$((20 * 1024))
DMG_SIZE_MB=$(( (STAGING_KB + PADDING_KB + 1023) / 1024 ))
if [ "$DMG_SIZE_MB" -lt 50 ]; then
  DMG_SIZE_MB=50
fi
hdiutil create -fs HFS+J -volname "$APP_NAME" -srcfolder "$DMG_STAGING" -ov -format UDRW -size "${DMG_SIZE_MB}m" "$DMG_RW"

echo "Customizing DMG layout (background + positions + volume icon)…"
MOUNT_DIR="/Volumes/${APP_NAME}"
hdiutil detach "$MOUNT_DIR" -quiet || true
ATTACH_OUTPUT=$(hdiutil attach "$DMG_RW" -mountpoint "$MOUNT_DIR" -noverify -owners off 2>/tmp/dmg_attach.log || true)
DEV_NAME=$(echo "$ATTACH_OUTPUT" | grep '^/dev/' | head -n 1 | awk '{print $1}')

if [ -n "$DEV_NAME" ]; then
  if [ -f "$DMG_ICON_ICNS" ]; then
    cp "$DMG_ICON_ICNS" "$MOUNT_DIR/.VolumeIcon.icns"
    if command -v SetFile >/dev/null 2>&1; then
      SetFile -a C "$MOUNT_DIR"
      SetFile -a V "$MOUNT_DIR/.VolumeIcon.icns" || true
    else
      echo "Warning: SetFile not available; volume icon attribute not set."
    fi
  fi

  if command -v osascript >/dev/null 2>&1; then
    sleep 2
    /usr/bin/osascript <<EOF || echo "Warning: could not apply Finder layout; continuing with default window."
      tell application "Finder"
        tell disk "$APP_NAME"
          open
          set current view of container window to icon view
          set toolbar visible of container window to false
          set statusbar visible of container window to false
          set the bounds of container window to {100, 100, 700, 500}
          set viewOptions to the icon view options of container window
          set arrangement of viewOptions to not arranged
          set icon size of viewOptions to 96
          try
            set position of item "Doorbell.app" of container window to {140, 260}
            set position of item "Applications" of container window to {420, 260}
          end try
          update without registering applications
          delay 1
          close
        end tell
      end tell
EOF

    sleep 1
  else
    echo "osascript not available; DMG layout/background not applied."
  fi

  hdiutil detach "$DEV_NAME" -quiet || true
else
  echo "Warning: could not attach DMG for layout; using plain DMG."
fi

hdiutil convert "$DMG_RW" -format UDZO -ov -o "$DMG_PATH"

if [ -n "${CODESIGN_IDENTITY:-}" ]; then
  echo "Codesigning DMG with identity '${CODESIGN_IDENTITY}'…"
  codesign --force --timestamp --sign "$CODESIGN_IDENTITY" "$DMG_PATH"
else
  echo "Skipping DMG codesign (CODESIGN_IDENTITY not set)."
fi

rm -f "$DMG_RW"
rm -rf "$DMG_STAGING" "$ICONSET_DIR" "$APP_ICON_ICNS" "$DMG_ICON_ICNS"

echo "Done. DMG at: $DMG_PATH"
