#!/bin/bash
# Final version 2026 - Fresh Start with Registry Preservation

echo "##################################################################"
echo "#                    Installing XScreensaver                     #"
echo "#       Developed for X11 & KDE Plasma by sergio melas 2026      #"
echo "##################################################################"

# Dependency check (procps provides pgrep)
sudo apt-get update && sudo apt-get install -y wine wine32 xprintidle x11-xserver-utils procps playerctl wireplumber

INSTALL_DIR="/home/$USER/.winscr"
TEMP_BACKUP="/tmp/winscr_temp_$(date +%s)"
SCR_TARGET="$INSTALL_DIR/drive_c/windows/system32"

# 1. BUFFER SETTINGS
if [ -d "$INSTALL_DIR" ]; then
    echo "Buffering user registry and configs..."
    mkdir -p "$TEMP_BACKUP"
    cp "$INSTALL_DIR"/*.reg "$TEMP_BACKUP/" 2>/dev/null
    cp "$INSTALL_DIR"/*.conf "$TEMP_BACKUP/" 2>/dev/null
    rm -rf "$INSTALL_DIR"
fi

# 2. FRESH DIRECTORY & WINE INITIALIZATION
mkdir -p "$INSTALL_DIR"
echo "Initializing fresh Wine environment..."
WINEPREFIX="$INSTALL_DIR" wineboot --init

# CRITICAL: Wait for Wine to finish initializing and then SHUT IT DOWN
# This ensures the new (default) registry files are actually written to disk
# so we can safely overwrite them.
sleep 5
WINEPREFIX="$INSTALL_DIR" wineboot -s
sleep 2

# 3. DEPLOY FRESH PAYLOAD
echo "Deploying fresh scripts and assets..."
cp ./Payload/*.sh "$INSTALL_DIR/"
cp ./Payload/winscr_icon.png "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR"/*.sh

# 4. DEPLOY CURRENT SCREENSAVERS
echo "Deploying screensavers to system32..."
mkdir -p "$SCR_TARGET"
cp ./'Scr files'/*.scr "$SCR_TARGET/"

# 5. RESTORE SETTINGS (Now safe from being overwritten)
if [ -d "$TEMP_BACKUP" ]; then
    echo "Restoring buffered settings and registry..."
    # Overwrite the fresh default registry with your saved user settings
    cp "$TEMP_BACKUP"/*.reg "$INSTALL_DIR/" 2>/dev/null
    cp "$TEMP_BACKUP"/*.conf "$INSTALL_DIR/" 2>/dev/null
    rm -rf "$TEMP_BACKUP"
else
    cp ./Payload/*.conf "$INSTALL_DIR/" 2>/dev/null
fi

# 5. REFRESH DESKTOP & AUTOSTART (Prevents Duplicates)
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

# 6. RESTART SERVICE
echo "Stopping old processes..."
pkill -f "winscr_screensaver.sh" 2>/dev/null

# CRITICAL: If wineserver is still running from 'wineboot',
# the runner might hang. Force it to stop.
wineboot -s 2>/dev/null
sleep 2

echo "Launching service in the background..."

# 1. Start the screensaver runner service DETACHED
# setsid creates a new session so the service doesn't die when the installer exits.
# we redirect output to a log file so you can see if it fails.
setsid nohup bash "$INSTALL_DIR/winscr_screensaver.sh" > "$INSTALL_DIR/service.log" 2>&1 &
setsid nohup bash "$INSTALL_DIR/winscr_choose.sh" &


echo "Installation Finished. Service is running (check $INSTALL_DIR/service.log for errors)."

