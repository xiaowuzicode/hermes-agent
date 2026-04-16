#!/bin/zsh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
SVG_PATH="$REPO_DIR/assets/hermes-gateway-launcher.svg"
APP_DIR="$HOME/Applications"
APP_NAME="Hermes Gateway.app"
APP_PATH="$APP_DIR/$APP_NAME"

mkdir -p "$APP_DIR"
TMP_DIR="$(mktemp -d)"
ICONSET_DIR="$TMP_DIR/HermesGateway.iconset"
mkdir -p "$ICONSET_DIR"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

if [[ ! -f "$SVG_PATH" ]]; then
  echo "Missing SVG icon: $SVG_PATH"
  exit 1
fi

cat > "$TMP_DIR/launcher.applescript" <<'APPLESCRIPT'
on run
  set scriptPath to "__REPO_DIR__/scripts/macos/hermes-gateway.command"
  set ghosttyPath to "/Applications/Ghostty.app"

  if (do shell script "test -d " & quoted form of ghosttyPath & " && echo yes || echo no") is "yes" then
    do shell script "open -na " & quoted form of ghosttyPath & " --args -e " & quoted form of scriptPath
  else
    tell application "Terminal"
      activate
      do script quoted form of scriptPath
    end tell
  end if
end run
APPLESCRIPT

sed -i '' "s|__REPO_DIR__|$REPO_DIR|g" "$TMP_DIR/launcher.applescript"
osacompile -o "$APP_PATH" "$TMP_DIR/launcher.applescript"

# Render svg -> png via Quick Look, then make iconset and icns
qlmanage -t -s 1024 -o "$TMP_DIR" "$SVG_PATH" >/dev/null 2>&1 || true
THUMB_PATH="$TMP_DIR/$(basename "$SVG_PATH").png"

if [[ -f "$THUMB_PATH" ]]; then
  cp "$THUMB_PATH" "$ICONSET_DIR/icon_512x512@2x.png"
  sips -z 16 16     "$THUMB_PATH" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
  sips -z 32 32     "$THUMB_PATH" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
  sips -z 32 32     "$THUMB_PATH" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
  sips -z 64 64     "$THUMB_PATH" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
  sips -z 128 128   "$THUMB_PATH" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
  sips -z 256 256   "$THUMB_PATH" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
  sips -z 256 256   "$THUMB_PATH" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
  sips -z 512 512   "$THUMB_PATH" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
  sips -z 512 512   "$THUMB_PATH" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
  iconutil -c icns "$ICONSET_DIR" -o "$TMP_DIR/HermesGateway.icns"
  cp "$TMP_DIR/HermesGateway.icns" "$APP_PATH/Contents/Resources/applet.icns"
fi

touch "$APP_PATH"
echo "Created launcher app: $APP_PATH"
