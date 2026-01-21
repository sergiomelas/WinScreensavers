#!/bin/bash
# filename: install.sh
# 2026 Installer: Preserves config and ensures directory creation.

echo " "
echo " ##################################################################"
echo " #                       Install screensaver                      #"
echo " #       Developed for X11 & KDE Plasma by sergio melas 2026      #"
echo " ##################################################################"

# 1. Environment Check
[[ "$XDG_SESSION_TYPE" != "x11" ]] && { echo "Error: X11 session required."; exit 1; }

# 2. Kill existing service to prevent duplicates
echo "[INFO] Cleaning up existing processes..."
pkill -f "winscr_screensaver.sh" 2>/dev/null
wineserver -k 2>/dev/null

# 3. System Dependencies (Updated for Debian/Ubuntu 2026)
echo "[INFO] Updating system dependencies..."
sudo apt-get update && sudo apt-get install -y \
  libnotify-bin xprintidle xdotool zenity wine wine32 \
  x11-utils procps pipewire-bin playerctl

# 4. Directory Setup
INSTALL_DIR="/home/$USER/.winscr"

# Preserve user settings but clean the Wine drive and scripts
if [ -d "$INSTALL_DIR" ]; then
    echo "[INFO] Refreshing binaries while preserving Registry settings..."
    rm -rf "$INSTALL_DIR/drive_c"
    rm -f "$INSTALL_DIR"/*.sh
else
    mkdir -p "$INSTALL_DIR"
fi

export WINEPREFIX="$INSTALL_DIR"
echo "[INFO] Initializing Wine environment (2026)..."
# Reindirizziamo anche stderr per una console più pulita
wineboot --init >/dev/null 2>&1

# 5. File Deployment
echo "[INFO] Deploying payload files..."
cp ./Payload/*.sh "$INSTALL_DIR/"
cp ./Payload/winscr_icon.png "$INSTALL_DIR/"

# Aggiunta CRUCIALE: crea la directory di destinazione prima di copiare
mkdir -p "$INSTALL_DIR/drive_c/windows/system32/"

cp ./'Scr files'/*.scr "$INSTALL_DIR/drive_c/windows/system32/"
chmod +x "$INSTALL_DIR"/*.sh

# 6. Default Configuration (Only if NOT already present)
[ ! -f "$INSTALL_DIR/scrensaver.conf" ] && echo "Random.scr" > "$INSTALL_DIR/scrensaver.conf"
[ ! -f "$INSTALL_DIR/timeout.conf" ] && echo "300" > "$INSTALL_DIR/timeout.conf"
[ ! -f "$INSTALL_DIR/lockscreen.conf" ] && echo "0" > "$INSTALL_DIR/lockscreen.conf"
[ ! -f "$INSTALL_DIR/random_period.conf" ] && echo "60" > "$INSTALL_DIR/random_period.conf"

# 7. Menu Desktop File
DESKTOP_FILE="$HOME/.local/share/applications/WinScreensaver.desktop"
rm -f "$DESKTOP_FILE"
cat <<EOF > "$DESKTOP_FILE"
[Desktop Entry]
Name=WinScreensaver
Exec=$INSTALL_DIR/winscr_menu.sh
Icon=$INSTALL_DIR/winscr_icon.png
Type=Application
Categories=Settings;
EOF

# 8. Autostart Service
AUTOSTART_FILE="$HOME/.config/autostart/winscr_service.desktop"
rm -f "$AUTOSTART_FILE"
cat <<EOF > "$AUTOSTART_FILE"
[Desktop Entry]
Name=WinScreensaver Service
Exec=$INSTALL_DIR/winscr_screensaver.sh
Type=Application
X-KDE-AutostartScript=true
EOF

chmod +x "$DESKTOP_FILE"
chmod +x "$AUTOSTART_FILE"

echo "[SUCCESS] Installation complete."
echo "[INFO] Launching chooser..."
nohup "$INSTALL_DIR/winscr_screensaver.sh" >/dev/null 2>&1 &
bash "$INSTALL_DIR/winscr_choose.sh" &
