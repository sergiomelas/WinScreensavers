#!/bin/bash
# filename: winscr_random_choose.sh

echo " "
echo " ##################################################################"
echo " #              Choose Random scr list  Menu                      #"
echo " #       Developed for X11 & KDE Plasma by sergio melas 2026      #"
echo " #                                                                #"
echo " #                Emai: sergiomelas@gmail.com                     #"
echo " #                   Released under GPL V2.0                      #"
echo " #                                                                #"
echo " ##################################################################"

WINEPREFIX_PATH="/home/$USER/.winscr"
SCR_DIR="$WINEPREFIX_PATH/drive_c/windows/system32"
RANDOM_CONF="$WINEPREFIX_PATH/random_list.conf"

# 1. Get the list of available screensavers
readarray -t array < <(find "$SCR_DIR" -maxdepth 1 -name "*.scr" -printf "%f\n" | sort)

# Check if any screensavers exist
if [[ ${#array[@]} -eq 0 ]]; then
    zenity --error --text="No Windows screensavers found in $SCR_DIR"
    exit 1
fi

# 2. Build the Zenity checklist arguments with SMART PRE-SELECTION
ZEN_ARGS=()
for scr in "${array[@]}"; do
    # COSMETIC LOGIC:
    # If the config file do NOT exist, pre-select EVERYTHING (TRUE)
    # If the config file DOES exist, check if this specific file is inside it
    if [[ ! -f "$RANDOM_CONF" ]]; then
        STATE="TRUE"
    else
        if grep -Fxq "$scr" "$RANDOM_CONF" 2>/dev/null; then
            STATE="TRUE"
        else
            STATE="FALSE"
        fi
    fi

    ZEN_ARGS+=("$STATE" "$scr")
done

# 3. Open the Zenity selection menu
CHOICE=$(zenity --list --checklist \
    --title="Select Screensavers for Random Mode" \
    --text="Check the screensavers you want to include in the random cycle:" \
    --column="Include" --column="Screensaver Name" \
    "${ZEN_ARGS[@]}" --separator=$'\n' --height=500 --width=400)

# 4. Save selections to the relative config file
if [ $? -eq 0 ]; then
    echo "$CHOICE" > "$RANDOM_CONF"

    # Count selections for the notification
    COUNT=$(echo "$CHOICE" | grep -c ".scr")
    zenity --info --text="Random pool updated! $COUNT screensavers selected." --timeout=3
else
    echo "Selection canceled."
fi

# Standard behavior: call back the menu
kstart bash "$WINEPREFIX_PATH/winscr_menu.sh" &
