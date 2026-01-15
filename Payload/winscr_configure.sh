#!/bin/bash
# filename: winscr_configure.sh

echo " "
echo " ##################################################################"
echo " #                     Configure screensaver                      #"
echo " #       Developed for X11 & KDE Plasma by sergio melas 2026      #"
echo " ##################################################################"

WINEPREFIX_PATH="/home/$USER/.winscr"
SCR_DIR="$WINEPREFIX_PATH/drive_c/windows/system32"
RANDOM_CONF="$WINEPREFIX_PATH/random_list.conf"
export WINEPREFIX="$WINEPREFIX_PATH"

# 1. Check current mode
SCR_SAVER=$(cat "$WINEPREFIX_PATH/scrensaver.conf" 2>/dev/null || echo "Random.scr")

# 2. Logic to determine which screensaver to configure
TARGET_SCR=""

if [[ "$SCR_SAVER" == "Random.scr" ]]; then
    # Load the custom list if it exists
    if [[ -s "$RANDOM_CONF" ]]; then
        readarray -t array < "$RANDOM_CONF"
    else
        # Fallback to all if list is empty
        readarray -t array < <(find "$SCR_DIR" -maxdepth 1 -name "*.scr" -printf "%f\n" | sort)
    fi

    # Check how many items we have
    COUNT=${#array[@]}

    if [ "$COUNT" -eq 0 ]; then
        zenity --error --text="No Windows screensavers found."
        kstart bash "$WINEPREFIX_PATH/winscr_menu.sh" &
        exit 1
    elif [ "$COUNT" -eq 1 ]; then
        # LOGIC IMPROVEMENT: If only one item exists, pick it automatically
        TARGET_SCR="${array[0]}"
    else
        # Multiple items: Show the Radiolist
        ZEN_ARGS=()
        for scr in "${array[@]}"; do
            [[ -z "$scr" ]] && continue
            ZEN_ARGS+=("FALSE" "$scr")
        done

        TARGET_SCR=$(zenity --list --radiolist --title="Configure Screensaver" \
            --text="Select a screensaver from your Random List to configure:" \
            --column="Pick" --column="Screensaver Name" \
            "${ZEN_ARGS[@]}" --height=450 --width=400)

        # If user cancels the menu
        if [[ -z "$TARGET_SCR" ]]; then
            kstart bash "$WINEPREFIX_PATH/winscr_menu.sh" &
            exit 0
        fi
    fi
else
    # Single Mode: Directly use the active screensaver
    TARGET_SCR="$SCR_SAVER"
fi

# 3. Launch Wine Configuration
if [[ -n "$TARGET_SCR" ]]; then
    wine "$SCR_DIR/$TARGET_SCR" /c
fi

# 4. Return to Menu
kstart bash "$WINEPREFIX_PATH/winscr_menu.sh" &
