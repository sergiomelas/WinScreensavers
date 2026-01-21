#!/bin/bash
# filename: winscr_choose.sh

echo " "
echo " ##################################################################"
echo " #                        Choose screensaver                      #"
echo " #       Developed for X11 & KDE Plasma by sergio melas 2026      #"
echo " #                                                                #"
echo " #                Emai: sergiomelas@gmail.com                     #"
echo " #                   Released under GPL V2.0                      #"
echo " #                                                                #"
echo " ##################################################################"
echo " "


WINEPREFIX_PATH="/home/$USER/.winscr"
WINE_DIR="$WINEPREFIX_PATH/drive_c/windows/system32"
# Read current config (e.g., "Random.scr" or "Mystify.scr")
CURRENT_SCR=$(cat $WINEPREFIX_PATH/scrensaver.conf 2>/dev/null || echo "Random.scr")

# 1. Get the list of all .scr files
readarray -t file_list < <(cd "$WINE_DIR" && ls *.scr)

# 2. Build the Zenity argument list with TRUE/FALSE toggles
# Format: [State] [Name]
ZEN_LIST=()

# Handle the "Random" option first
if [[ "$CURRENT_SCR" == "Random.scr" ]]; then
    ZEN_LIST+=("TRUE" "Random")
else
    ZEN_LIST+=("FALSE" "Random")
fi

# Handle all other screensavers
for file in "${file_list[@]}"; do
    NAME="${file%.*}"
    if [[ "$file" == "$CURRENT_SCR" ]]; then
        ZEN_LIST+=("TRUE" "$NAME")
    else
        ZEN_LIST+=("FALSE" "$NAME")
    fi
done

# 3. Launch Zenity list with radiobuttons
SCR=$(zenity --list --radiolist --title "Winscr Chooser" \
    --text "Current: $CURRENT_SCR" \
    --column "Pick" --column "Screensavers" \
    "${ZEN_LIST[@]}" --height=500 --width=350)

# 4. Save Selection
if [ -n "$SCR" ]; then
    if [ "$SCR" == "Random" ]; then
        FINAL_VAL="Random.scr"
    else
        FINAL_VAL="$SCR.scr"
    fi
    echo "$FINAL_VAL" > $WINEPREFIX_PATH/scrensaver.conf
    echo "Saved: $FINAL_VAL"
fi

# Reopen menu using modern KDE kstart
rm -f "$WINEPREFIX_PATH"/.running  #Unlock istance
kstart bash "$WINEPREFIX_PATH/winscr_menu.sh" &
