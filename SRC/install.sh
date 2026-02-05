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

# 2. THE SMART VALIDATION LOOP
while true; do
    # Check for existing screensavers in the destination
    CURRENT_COUNT=$(find "$SCR_DEST" -maxdepth 1 -iname "*.scr" 2>/dev/null | wc -l)

    if [ "$CURRENT_COUNT" -gt 0 ]; then
        echo "Integrity Check: $CURRENT_COUNT screensavers found. Proceeding to payload deployment."
        break
    fi

    # --- SPACE-PROOF AUTO-DISCOVERY ---
    echo "Scanning home for screensaver collections..."
    # Find the first .scr and get its directory
    BEST_FOLDER=$(find "$HOME" -maxdepth 9 -iname "*.scr" -not -path "*/.*" -print -quit 2>/dev/null | xargs -0 -I {} dirname "{}")

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
    SOURCE_COUNT=$(find "$SCR_SOURCE" -maxdepth 1 -iname "*.scr" 2>/dev/null | wc -l)
    if [ "$SOURCE_COUNT" -gt 0 ]; then
        cp -v "$SCR_SOURCE"/*.scr "$SCR_DEST/" 2>/dev/null
        zenity --info --text="Successfully imported $SOURCE_COUNT screensavers." --timeout=3
        break
    else
        zenity --error --text="The selected folder contains 0 .scr files. Please pick another."
    fi
done

# 4. DEPLOY PAYLOAD & AUTOSTART (REFRESH LOGIC)
echo "Deploying/Refreshing scripts and configurations..."

# Always force update scripts (-f)
cp -f "$SYS_PATH"/*.sh "$WINEPREFIX_PATH/"
# Preserving user settings for configs if they exist (-n)
cp -n "$SYS_PATH"/*.conf "$WINEPREFIX_PATH/" 2>/dev/null
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

# 5. BACKGROUND PROCESS RESTART
# Ensure the background monitor is running the fresh code
pkill -f "winscr_screensaver.sh"
bash "$WINEPREFIX_PATH/winscr_screensaver.sh" &

# 6. UNLOCK & FINISH
rm -f "$WINEPREFIX_PATH/.running"

echo "Installation/Refresh successful!"
zenity --info --title="Success" --text="Installation successful!\n\n- Registry verified\n- Scripts updated\n- Background monitor restarted."
