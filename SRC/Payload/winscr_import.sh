#!/bin/bash
# filename: winscr_import.sh
# Final version 2026 - Intelligent Import Logic

echo " "
echo " ##################################################################"
echo " #                                                                #"
echo " #                Import Windows screensavers                     #"
echo " #    Developed for X11/Wayland & KDE Plasma by sergio melas 2026 #"
echo " #                                                                #"
echo " #                Email: sergiomelas@gmail.com                    #"
echo " #                   Released under GPL V2.0                      #"
echo " #                                                                #"
echo " ##################################################################"
echo " "
#!/bin/bash
# filename: winscr_import.sh

WINEPREFIX_PATH="$HOME/.winscr"
SCR_DEST="$WINEPREFIX_PATH/drive_c/windows/system32"

# 1. AGGRESSIVE SEARCH (Handling spaces with -print0)
# We find the first .scr and get its directory, keeping it as one solid string
BEST_FOLDER=$(find "$HOME" -maxdepth 9 -iname "*.scr" -not -path "*/.*" -print -quit 2>/dev/null | xargs -0 -I {} dirname "{}")

# 2. DEBUG FALLBACK
if [ -z "$BEST_FOLDER" ] || [ ! -d "$BEST_FOLDER" ]; then
    BEST_FOLDER="$HOME"
fi

# 3. THE ZENITY CALL (The "Quotes" are the secret)
# Note the double quotes around "$BEST_FOLDER/" - this stops the space bug!
SCR_SOURCE=$(zenity --file-selection --directory \
    --title="Import Screensavers, Preselected folder is the one with most .scr" \
    --filename="$BEST_FOLDER/")

# 4. PROCESSING
if [ -n "$SCR_SOURCE" ]; then
    # Use quotes here too so the 'cp' command doesn't break on spaces
    SOURCE_COUNT=$(find "$SCR_SOURCE" -maxdepth 1 -iname "*.scr" 2>/dev/null | wc -l)

    if [ "$SOURCE_COUNT" -gt 0 ]; then
        cp -v "$SCR_SOURCE"/*.scr "$SCR_DEST/"
        zenity --info --text="Successfully imported $SOURCE_COUNT screensavers." --timeout=3
    else
        zenity --error --text="No .scr files found in: $SCR_SOURCE"
    fi
fi

# 5. UNIVERSAL HANDOVER
rm -f "$WINEPREFIX_PATH/.running"
winscreensaver &
exit 0
