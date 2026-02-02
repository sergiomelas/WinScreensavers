#!/bin/bash
# filename: install.sh
# Final version 2026 - Space-Proof Environment Setup

echo " "
echo " ##################################################################"
echo " #                                                                #"
echo " #                Windows screensavers launcher                   #"
echo " #    Developed for X11/Wayland & KDE Plasma by sergio melas 2026 #"
echo " #                                                                #"
echo " #                Email: sergiomelas@gmail.com                    #"
echo " #                   Released under GPL V2.0                      #"
echo " #                                                                #"
echo " ##################################################################"
echo " "

# Path variables
REAL_HOME=$(eval echo ~$USER)
WINEPREFIX_PATH="$REAL_HOME/.winscr"
SYS_PATH="/usr/share/winscreensaver/Payload"
SCR_DEST="$WINEPREFIX_PATH/drive_c/windows/system32"

mkdir -p "$SCR_DEST"

# 1. WINE INIT
export WINEPREFIX="$WINEPREFIX_PATH"
echo "Initializing Wine Prefix..."
wineboot -u > /dev/null 2>&1

# 2. THE SMART VALIDATION LOOP
while true; do
    # Check for existing screensavers
    CURRENT_COUNT=$(find "$SCR_DEST" -maxdepth 1 -iname "*.scr" 2>/dev/null | wc -l)

    if [ "$CURRENT_COUNT" -gt 0 ]; then
        break
    fi

    # --- SPACE-PROOF AUTO-DISCOVERY ---
    echo "Scanning home for screensaver collections..."
    # Find the first .scr and get its directory as one solid string
    BEST_FOLDER=$(find "$HOME" -maxdepth 9 -iname "*.scr" -not -path "*/.*" -print -quit 2>/dev/null | xargs -0 -I {} dirname "{}")

    # --- THE ZENITY FIX (Double Quoted) ---
    if [ -n "$BEST_FOLDER" ] && [ -d "$BEST_FOLDER" ]; then
         SCR_SOURCE=$(zenity --file-selection --directory \
         --title="Import Screensavers, Preselected folder is the one with most .scr" \
        --filename="$BEST_FOLDER/")
    else
        SCR_SOURCE=$(zenity --file-selection --directory --title="Select folder containing .scr files")
    fi

    # User clicked Cancel
    if [ -z "$SCR_SOURCE" ]; then
        zenity --error --text="Installation aborted. Local environment is incomplete."
        exit 1
    fi

    # 3. FINAL COPY VALIDATION
    # Use quotes around $SCR_SOURCE to handle paths with spaces
    SOURCE_COUNT=$(find "$SCR_SOURCE" -maxdepth 1 -iname "*.scr" 2>/dev/null | wc -l)
    if [ "$SOURCE_COUNT" -gt 0 ]; then
        cp -v "$SCR_SOURCE"/*.scr "$SCR_DEST/" 2>/dev/null
        zenity --info --text="Successfully imported $SOURCE_COUNT screensavers." --timeout=3
        break
    else
        zenity --error --text="The selected folder contains 0 .scr files. Please pick another."
    fi
done

# 4. DEPLOY PAYLOAD & AUTOSTART
cp -f "$SYS_PATH"/*.sh "$WINEPREFIX_PATH/"
cp -f "$SYS_PATH"/*.conf "$WINEPREFIX_PATH/"
chmod +x "$WINEPREFIX_PATH"/*.sh

# Register background service for login
cat <<EOF > "$REAL_HOME/.config/autostart/winscreensaver.desktop"
[Desktop Entry]
Type=Application
Exec=$WINEPREFIX_PATH/winscr_screensaver.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=WinScreensaver Service
EOF

# 5. UNLOCK & FINISH
rm -f "$WINEPREFIX_PATH/.running"

zenity --info --text="Installation successful!" --title="Success"
