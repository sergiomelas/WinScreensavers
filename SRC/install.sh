#!/bin/bash
# filename: install.sh
# Final version 2026 - Space-Proof Environment Setup & Full Refresh

echo " "
echo " ##################################################################"
echo " #                                                                #"
echo " #            Windows screensavers Local Installer                #"
echo " #    Developed for X11/Wayland & KDE Plasma by sergio melas 2026 #"
echo " #                                                                #"
echo " #                Email: sergiomelas@gmail.com                    #"
echo " #                    Released under GPL V2.0                     #"
echo " #                                                                #"
echo " ##################################################################"
echo " "

# Path variables
REAL_HOME=$(eval echo ~$USER)
WINEPREFIX_PATH="$REAL_HOME/.winscr"
SYS_PATH="/usr/share/winscreensaver/Payload"
SCR_DEST="$WINEPREFIX_PATH/drive_c/windows/system32"

mkdir -p "$SCR_DEST"

# 1. WINE INIT & REGISTRY REPAIR
export WINEPREFIX="$WINEPREFIX_PATH"
export WINEDEBUG=-all

# Zenity notification for blind users/GUI feedback
zenity --info --text="Initializing Environment: Verifying Wine registry and folder structure. Please wait..." --timeout=3 --width=300

echo "Initializing Wine Prefix and Rebuilding Registry..."
# wineboot -u ensures .reg files (user.reg, system.reg, userdef.reg) are healthy
wineboot -u > /dev/null 2>&1

# 2. DEPLOY PAYLOAD
echo "Deploying scripts and configurations..."

# Always force update scripts
cp -f "$SYS_PATH"/*.sh "$WINEPREFIX_PATH/"
cp -n "$SYS_PATH"/*.conf "$WINEPREFIX_PATH/" 2>/dev/null
chmod +x "$WINEPREFIX_PATH"/*.sh

# Register background service
cat <<EOF > "$REAL_HOME/.config/autostart/winscreensaver.desktop"
[Desktop Entry]
Type=Application
Exec=$WINEPREFIX_PATH/winscr_screensaver.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=WinScreensaver Service
EOF

# 3. POST-DEPLOYMENT: INTELLIGENT REFRESH
# Check if system32 is empty
SCR_COUNT=$(find "$SCR_DEST" -maxdepth 1 -iname "*.scr" | wc -l)

if [ "$SCR_COUNT" -eq 0 ]; then
    # SCENARIO A: Fresh Install (Empty)
    zenity --info --text="First-time setup detected. Launching Importer..." --timeout=2
    bash "$WINEPREFIX_PATH/winscr_import.sh"
else
    # SCENARIO B: Upgrade/Refresh (Existing files found)
    # Give the user a choice: Refresh/Add more or skip import
    zenity --question --title="System Update" \
    --text="Screensaver environment already exists ($SCR_COUNT files).\n\nDo you want to run the Importer to add/test new screensavers?" \
    --width=400

    if [ $? -eq 0 ]; then
        bash "$WINEPREFIX_PATH/winscr_import.sh"
    fi
fi

# 4. RESTART BACKGROUND PROCESS (Always restart after updates)
pkill -f "winscr_screensaver.sh"
bash "$WINEPREFIX_PATH/winscr_screensaver.sh" &

# 5. UNLOCK & FINISH
rm -f "$WINEPREFIX_PATH/.running"
zenity --info --title="Success" --text="Installation/Refresh successful!"
