#!/bin/bash
# Final version 2026 - Fresh Start with Silent Initialization

echo "##################################################################"
echo "#                    Installing WinScreensaver                   #"
echo "#       Developed for X11 & KDE Plasma by sergio melas 2026      #"
echo "##################################################################"

# 1. SILENT DEPENDENCY CHECK
# Added -qq for apt and redirected output to /dev/null
echo "Checking system dependencies..."
sudo apt-get update -qq
sudo apt-get install -y -qq wine wine32 xprintidle x11-xserver-utils procps playerctl wireplumber swayidle > /dev/null 2>&1

INSTALL_DIR="/home/$USER/.winscr"
TEMP_BACKUP="/tmp/winscr_temp_$(date +%s)"
SCR_TARGET="$INSTALL_DIR/drive_c/windows/system32"

# 2. BUFFER SETTINGS
if [ -d "$INSTALL_DIR" ]; then
    echo "Buffering user registry and configs..."
    mkdir -p "$TEMP_BACKUP"
    cp "$INSTALL_DIR"/*.reg "$TEMP_BACKUP/" 2>/dev/null
    cp "$INSTALL_DIR"/*.conf "$TEMP_BACKUP/" 2>/dev/null
    rm -rf "$INSTALL_DIR"
fi

# 3. SILENT WINE INITIALIZATION
mkdir -p "$INSTALL_DIR"
echo "Initializing fresh Wine environment (please wait)..."
# WINEDEBUG=-all removes the ole/rpc error messages from the terminal
export WINEPREFIX="$INSTALL_DIR"
export WINEDEBUG=-all
wineboot --init > /dev/null 2>&1

sleep 5
wineboot -s > /dev/null 2>&1
sleep 2

# 4. DEPLOY FRESH PAYLOAD
echo "Deploying fresh scripts and assets..."
cp ./Payload/*.sh "$INSTALL_DIR/"
cp ./Payload/winscr_icon.png "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR"/*.sh

# 5. DEPLOY CURRENT SCREENSAVERS
echo "Deploying screensavers to system32..."
mkdir -p "$SCR_TARGET"
cp ./'Scr files'/*.scr "$SCR_TARGET/"

# 6. RESTORE SETTINGS
if [ -d "$TEMP_BACKUP" ]; then
    echo "Restoring buffered settings and registry..."
    cp "$TEMP_BACKUP"/*.reg "$INSTALL_DIR/" 2>/dev/null
    cp "$TEMP_BACKUP"/*.conf "$INSTALL_DIR/" 2>/dev/null
    rm -rf "$TEMP_BACKUP"
else
    cp ./Payload/*.conf "$INSTALL_DIR/" 2>/dev/null
fi

# 7. REFRESH DESKTOP & AUTOSTART
cat <<EOF > "$HOME/.local/share/applications/WinScreensaver.desktop"
[Desktop Entry]
Name=WinScreensaver
Exec=$INSTALL_DIR/winscr_menu.sh
Icon=$INSTALL_DIR/winscr_icon.png
Type=Application
EOF

cat <<EOF > "$HOME/.config/autostart/winscr_service.desktop"
[Desktop Entry]
Name=WinScreensaver Service
Exec=$INSTALL_DIR/winscr_screensaver.sh
Type=Application
X-KDE-AutostartScript=true
EOF

# 8. RESTART SERVICE
echo "Stopping old processes..."
pkill -f "winscr_screensaver.sh" 2>/dev/null
pkill -f "winscr_choose.sh" 2>/dev/null
# Silently stop wine without restarting the whole session
WINEPREFIX="$INSTALL_DIR" wineboot -s > /dev/null 2>&1
sleep 2

echo "Launching service safely in the background..."

# Use subshells and redirection to detach from the terminal properly
# This prevents the script from closing when the installer exits
( nohup "$INSTALL_DIR/winscr_screensaver.sh" > /dev/null 2>&1 & )
( nohup "$INSTALL_DIR/winscr_choose.sh" > /dev/null 2>&1 & )

# Ensure .desktop files are executable (Mandatory in 2026 for KDE 6)
chmod +x "$HOME/.local/share/applications/WinScreensaver.desktop"
chmod +x "$HOME/.config/autostart/winscr_service.desktop"

# Refresh the Plasma shell ONLY if needed (does NOT log you out)
# This is safe and won't kill your windows
if command -v systemctl >/dev/null; then
    systemctl --user daemon-reload
fi

echo "Installation Finished. Service is running in the background."
