#!/bin/bash
# filename: winscr_choose.sh
# Final version 2026 - Choice Manager with Absolute Path Fix

echo " "
echo " ##################################################################"
echo " #                                                                #"
echo " #                Choose Windows screensaver                      #"
echo " #    Developed for X11/Wayland & KDE Plasma by sergio melas 2026 #"
echo " #                                                                #"
echo " #                Email: sergiomelas@gmail.com                    #"
echo " #                   Released under GPL V2.0                      #"
echo " #                                                                #"
echo " ##################################################################"
echo " "

WINEPREFIX_PATH="$HOME/.winscr"
SCR_DIR="$WINEPREFIX_PATH/drive_c/windows/system32"
CONF_FILE="$WINEPREFIX_PATH/scrensaver.conf"

# --- 1. SCAN FOR SCREENSAVERS ---
# Use absolute path to find the .scr files
readarray -t array < <(find "$SCR_DIR" -maxdepth 1 -iname "*.scr" -printf "%f\n" | sort 2>/dev/null)

# Check if we have any files to show
if [ ${#array[@]} -eq 0 ]; then
    zenity --error --text="No screensavers found in:\n$SCR_DIR" --width=350
    rm -f "$WINEPREFIX_PATH/.running"
    winscreensaver &
    exit 1
fi

# --- 2. GET CURRENT SELECTION ---
CURRENT_SCR=$(cat "$CONF_FILE" 2>/dev/null || echo "Random.scr")

# --- 3. BUILD ZENITY LIST ---
ZEN_ARGS=()

# Add the 'Random' option first
STATE="FALSE"
[ "$CURRENT_SCR" == "Random.scr" ] && STATE="TRUE"
ZEN_ARGS+=("$STATE" "Random.scr")

# Add all found .scr files
for scr in "${array[@]}"; do
    STATE="FALSE"
    [ "$CURRENT_SCR" == "$scr" ] && STATE="TRUE"
    ZEN_ARGS+=("$STATE" "$scr")
done

# --- 4. DISPLAY PICKER ---
Choice=$(zenity --list --radiolist --title="Choose Screensaver" \
    --text "Select the active screensaver:" \
    --column="Pick" --column="Screensaver" \
    "${ZEN_ARGS[@]}" --height=500 --width=400)

# --- 5. SAVE SELECTION ---
if [ -n "$Choice" ]; then
    echo "$Choice" > "$CONF_FILE"
fi

# --- 6. UNIVERSAL HANDOVER ---
# Clear the lock and relaunch the master menu via the system wrapper
rm -f "$WINEPREFIX_PATH/.running"
winscreensaver &
exit 0
