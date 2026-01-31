#!/bin/bash
# filename: install.sh
# Final version 2026 - Smart Environment Setup & Collection Discovery

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

REAL_HOME=$(eval echo ~$USER)
WINEPREFIX_PATH="$REAL_HOME/.winscr"
SYS_PATH="/usr/share/winscreensaver/Payload"
SCR_DEST="$WINEPREFIX_PATH/drive_c/windows/system32"

mkdir -p "$SCR_DEST"

# 1. WINE INIT
export WINEPREFIX="$WINEPREFIX_PATH"
wineboot -u > /dev/null 2>&1

# 2. THE SMART VALIDATION LOOP
while true; do
    CURRENT_COUNT=$(find "$SCR_DEST" -maxdepth 1 -iname "*.scr" 2>/dev/null | wc -l)
    if [ "$CURRENT_COUNT" -gt 0 ]; then
        zenity --info --text="Existing screensavers detected ($CURRENT_COUNT files). Keeping collection." --timeout=5
        break
    fi

    # SMART AUTO-DISCOVERY
    BEST_FOLDER=""
    MAX_COUNT=0
    while read -r count_folder; do
        count=$(echo "$count_folder" | awk '{print $1}')
        folder=$(echo "$count_folder" | cut -d' ' -f2-)
        if [ "$count" -gt "$MAX_COUNT" ]; then
            MAX_COUNT=$count
            BEST_FOLDER="$folder/"
        fi
    done < <(find "$HOME" -maxdepth 5 -iname "*.scr" -exec dirname {} + 2>/dev/null | sort | uniq -c | sort -nr)

    if [ -n "$BEST_FOLDER" ] && [ -d "$BEST_FOLDER" ]; then
        msg="Auto-detected $MAX_COUNT screensavers in:\n$BEST_FOLDER"
        SCR_SOURCE=$(zenity --file-selection --directory --filename="$BEST_FOLDER" --title="$msg")
    else
        SCR_SOURCE=$(zenity --file-selection --directory --title="Select folder CONTAINING .scr files")
    fi

    [ -z "$SCR_SOURCE" ] && exit 1
    if [ $(find "$SCR_SOURCE" -maxdepth 1 -iname "*.scr" 2>/dev/null | wc -l) -gt 0 ]; then
        cp "$SCR_SOURCE"/*.scr "$SCR_DEST/" 2>/dev/null
        break
    else
        zenity --error --text="The selected folder contains 0 .scr files."
    fi
done

# 3. DEPLOY & UNLOCK
cp -f "$SYS_PATH"/*.sh "$WINEPREFIX_PATH/"
cp -f "$SYS_PATH"/*.conf "$WINEPREFIX_PATH/"
chmod +x "$WINEPREFIX_PATH"/*.sh

# Autostart entry for the service
cat <<EOF > "$REAL_HOME/.config/autostart/winscreensaver.desktop"
[Desktop Entry]
Type=Application
Exec=$WINEPREFIX_PATH/winscr_screensaver.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=WinScreensaver Service
EOF

# Clear PID lock so menu can start immediately after setup
rm -f "$WINEPREFIX_PATH/.running"

# --- CLEANUP LOCAL OVERRIDES ---
# This disables the "caching" problem by removing old local files
rm -f "$HOME/.local/share/applications/winscreensaver.desktop"
rm -f "$HOME/.local/share/applications/winscr_menu.desktop"

# Tell KDE to refresh the menu immediately
kbuildsycoca6 --noincremental > /dev/null 2>&1 || kbuildsycoca5 --noincremental > /dev/null 2>&1


zenity --info --text="Installation successful!" --title="Success"
