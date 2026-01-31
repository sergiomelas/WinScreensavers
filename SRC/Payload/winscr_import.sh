#!/bin/bash
# filename: winscr_import.sh

echo " "
echo " ##################################################################"
echo " #                                                                #"
echo " #                Windows screensavers importer                   #"
echo " #    Developed for X11/Wayland & KDE Plasma by sergio melas 2026 #"
echo " #                                                                #"
echo " #                Email: sergiomelas@gmail.com                    #"
echo " #                   Released under GPL V2.0                      #"
echo " #                                                                #"
echo " ##################################################################"
echo " "

WINEPREFIX_PATH="$HOME/.winscr"
SCR_DEST="$WINEPREFIX_PATH/drive_c/windows/system32"

# --- SMART AUTO-DISCOVERY (Fixed Logic) ---
echo "Scanning home for additional screensavers..."
BEST_FOLDER=""
MAX_COUNT=0

# Use a faster, accurate pipe to find the folder with the most .scr files
while read -r count_folder; do
    count=$(echo "$count_folder" | awk '{print $1}')
    folder=$(echo "$count_folder" | cut -d' ' -f2-)

    if [ "$count" -gt "$MAX_COUNT" ]; then
        MAX_COUNT=$count
        BEST_FOLDER="$folder/" # Trailing slash forces Zenity to ENTER the folder
    fi
done < <(find "$HOME" -maxdepth 5 -iname "*.scr" -exec dirname {} + 2>/dev/null | sort | uniq -c | sort -nr)

# --- PROMPT USER ---
if [ -n "$BEST_FOLDER" ] && [ -d "$BEST_FOLDER" ]; then
    msg="Auto-detected $MAX_COUNT screensavers in:\n$BEST_FOLDER\n\nImport these files or Browse for another folder?"
    SCR_SOURCE=$(zenity --file-selection --directory --filename="$BEST_FOLDER" --title="$msg")
else
    SCR_SOURCE=$(zenity --file-selection --directory --title="Select folder to import .scr files from")
fi

if [ -n "$SCR_SOURCE" ]; then
    SOURCE_COUNT=$(find "$SCR_SOURCE" -maxdepth 1 -iname "*.scr" 2>/dev/null | wc -l)
    if [ "$SOURCE_COUNT" -gt 0 ]; then
        cp -n "$SCR_SOURCE"/*.scr "$SCR_DEST/" 2>/dev/null
        zenity --info --text="Successfully imported $SOURCE_COUNT screensavers." --timeout=3
    fi
fi

# --- THE UNIVERSAL HANDOVER ---
rm -f "$WINEPREFIX_PATH/.running"
winscreensaver &
exit 0
