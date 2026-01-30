#!/bin/bash
# filename: winscr_import.sh

echo  " "
echo  " ##################################################################"
echo  " #                                                                #"
echo  " #                     Imports Screen Savers                      #"
echo  " #    Developed for X11/Wayland & KDE Plasma by sergio melas 2026 #"
echo  " #                                                                #"
echo  " #                Emai: sergiomelas@gmail.com                     #"
echo  " #                   Released under GPL V2.0                      #"
echo  " #                                                                #"
echo  " ##################################################################"
echo  " "

# --- 1. PATHS ---
WINEPREFIX_PATH="$HOME/.winscr"
SCR_DIR="$WINEPREFIX_PATH/drive_c/windows/system32"

# --- 2. FOLDER SELECTION ---
SRC=$(zenity --file-selection --directory --title="Select folder containing .scr files")

if [ -n "$SRC" ]; then
    # Check if there are actually any .scr files inside
    COUNT=$(ls -1 "$SRC"/*.scr 2>/dev/null | wc -l)

    if [ "$COUNT" -gt 0 ]; then
        mkdir -p "$SCR_DIR"
        cp "$SRC"/*.scr "$SCR_DIR/" 2>/dev/null
        zenity --info --text="Success: $COUNT screensavers imported!" --timeout=3
    else
        zenity --error --text="No .scr files found in:\n$SRC"
    fi
fi

# --- 3. UNLOCK & RELAUNCH MENU (Standardized Fixed Block) ---
rm -f "$WINEPREFIX_PATH/.running"

KSRT_EXE=$(command -v kstart6 || command -v kstart5 || command -v kstart)

if command -v winscreensaver >/dev/null; then
    LAUNCH_CMD="winscreensaver"
else
    LAUNCH_CMD="bash $WINEPREFIX_PATH/winscr_menu.sh"
fi

if [ -n "$KSRT_EXE" ]; then
    $KSRT_EXE $LAUNCH_CMD &
else
    $LAUNCH_CMD &
fi

exit 0
