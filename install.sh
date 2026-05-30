#!/usr/bin/env bash
set -euo pipefail

APPIMAGE_URL="https://work-message.onrender.com/Conversate-x86_64.AppImage"
APPIMAGE_NAME="Conversate-x86_64.AppImage"
APP_NAME="Conversate"
APP_COMMENT="Conversate - Fast messaging for Linux"

BIN_DIR="$HOME/.local/bin"
APP_DIR="$HOME/.local/share/Conversate"
DESKTOP_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons/hicolor/256x256/apps"

echo "==> Conversate Installer"
echo ""

# --- Download ---
if [ -f "$APPIMAGE_NAME" ]; then
  echo "==> Using existing $APPIMAGE_NAME"
else
  echo "==> Downloading $APPIMAGE_NAME ..."
  wget -q --show-progress "$APPIMAGE_URL" -O "$APPIMAGE_NAME"
fi

echo "==> Making AppImage executable ..."
chmod +x "$APPIMAGE_NAME"

# --- Install ---
echo "==> Installing to $APP_DIR ..."
mkdir -p "$APP_DIR"
mv "$APPIMAGE_NAME" "$APP_DIR/"

echo "==> Creating launcher symlink in $BIN_DIR ..."
mkdir -p "$BIN_DIR"
ln -sf "$APP_DIR/$APPIMAGE_NAME" "$BIN_DIR/$APP_NAME"

# --- Create .desktop entry ---
echo "==> Creating desktop shortcut ..."
mkdir -p "$DESKTOP_DIR"
mkdir -p "$ICON_DIR"

# Try to use butterflylogo.webp (bundled alongside this script) as icon
ICON_NAME="$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]')"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ICON_SRC="$SCRIPT_DIR/butterflylogo.webp"
if [ -f "$ICON_SRC" ]; then
  echo "==> Converting butterflylogo.webp to icon ..."
  if command -v convert &>/dev/null; then
    convert "$ICON_SRC" "$ICON_DIR/$ICON_NAME.png"
  elif command -v ffmpeg &>/dev/null; then
    ffmpeg -y -i "$ICON_SRC" "$ICON_DIR/$ICON_NAME.png" 2>/dev/null
  elif command -v dwebp &>/dev/null; then
    dwebp "$ICON_SRC" -o "$ICON_DIR/$ICON_NAME.png" 2>/dev/null
  else
    echo "==> No webp converter found, trying to extract icon from AppImage ..."
    "$APP_DIR/$APPIMAGE_NAME" --appimage-extract ".DirIcon" &>/dev/null || true
    if [ -f squashfs-root/.DirIcon ]; then
      cp squashfs-root/.DirIcon "$ICON_DIR/$ICON_NAME.png" 2>/dev/null || true
    fi
    rm -rf squashfs-root 2>/dev/null || true
  fi
else
  echo "==> butterflylogo.webp not found, extracting icon from AppImage ..."
  "$APP_DIR/$APPIMAGE_NAME" --appimage-extract ".DirIcon" &>/dev/null || true
  if [ -f squashfs-root/.DirIcon ]; then
    cp squashfs-root/.DirIcon "$ICON_DIR/$ICON_NAME.png" 2>/dev/null || true
  fi
  rm -rf squashfs-root 2>/dev/null || true
fi

cat > "$DESKTOP_DIR/$APP_NAME.desktop" << EOF
[Desktop Entry]
Type=Application
Name=$APP_NAME
Comment=$APP_COMMENT
Exec=$APP_DIR/$APPIMAGE_NAME
Icon=$ICON_NAME
Terminal=false
Categories=Network;InstantMessaging;
StartupWMClass=Conversate
EOF

echo "==> Updating desktop database ..."
update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true

echo "==> Updating icon cache ..."
ICON_BASE="$(dirname "$ICON_DIR")"
if [ -d "$ICON_BASE" ] && command -v gtk-update-icon-cache &>/dev/null; then
  gtk-update-icon-cache "$ICON_BASE" 2>/dev/null || true
fi

echo ""
echo "==> Done! $APP_NAME has been installed."
echo ""
echo "    Run it from your application menu or type: $BIN_DIR/$APP_NAME"
echo ""
echo "    If $BIN_DIR is not in your PATH, add this to ~/.bashrc:"
echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
