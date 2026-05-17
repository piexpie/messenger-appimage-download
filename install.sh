#!/usr/bin/env bash
set -euo pipefail

APPIMAGE_URL="https://work-message.onrender.com/Messenger-x86_64.AppImage"
APPIMAGE_NAME="Messenger-x86_64.AppImage"
APP_NAME="Messenger"
APP_COMMENT="Messenger for Linux"

BIN_DIR="$HOME/.local/bin"
APP_DIR="$HOME/.local/share/Messenger"
DESKTOP_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons/hicolor/256x256/apps"

echo "==> Messenger Installer"
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

# Extract icon from AppImage if possible
if "$APP_DIR/$APPIMAGE_NAME" --appimage-extract ".DirIcon" &>/dev/null; then
  echo "==> Extracting icon from AppImage ..."
  if [ -f squashfs-root/.DirIcon ]; then
    cp squashfs-root/.DirIcon "$ICON_DIR/$APP_NAME.png" 2>/dev/null || true
  fi
  rm -rf squashfs-root
fi

cat > "$DESKTOP_DIR/$APP_NAME.desktop" << EOF
[Desktop Entry]
Type=Application
Name=$APP_NAME
Comment=$APP_COMMENT
Exec=$APP_DIR/$APPIMAGE_NAME
Icon=$APP_NAME
Terminal=false
Categories=Network;InstantMessaging;
StartupWMClass=Messenger
EOF

echo "==> Updating desktop database ..."
update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true

echo ""
echo "==> Done! $APP_NAME has been installed."
echo ""
echo "    Run it from your application menu or type: $BIN_DIR/$APP_NAME"
echo ""
echo "    If $BIN_DIR is not in your PATH, add this to ~/.bashrc:"
echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
