#!/bin/bash
# filename: winscr_configure.sh

echo " "
echo " ##################################################################"
echo " #                     Configure screensaver                      #"
echo " #       Developed for X11 & KDE Plasma by sergio melas 2026      #"
echo " ##################################################################"

# Set the Qt theme variable for this script and its child processes
export QT_QPA_PLATFORMTHEME=qt6ct

# Configure global paths
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
        # If only one item exists, pick it automatically
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

# 3. Launch Wine Configuration with Hidden Centering
if [[ -n "$TARGET_SCR" ]]; then
    # Launch in background
    wine "$SCR_DIR/$TARGET_SCR" /c &
    WINE_PID=$!

    # Search for the window and center it invisibly
    # Using a faster polling rate (0.2s) to catch the window before it draws
    for i in {1..25}; do
        sleep 0.2
        # Find window ID associated with the wine process
        WID=$(xdotool search --pid $WINE_PID --onlyvisible 2>/dev/null | tail -1)

        if [ -n "$WID" ]; then
            # 1. Instantly hide the window before it can be seen in the corner
            xdotool windowunmap "$WID"

            # 2. Get screen and window dimensions
            SCREEN_WIDTH=$(xwininfo -root | grep 'Width:' | awk '{print $2}')
            SCREEN_HEIGHT=$(xwininfo -root | grep 'Height:' | awk '{print $2}')

            # Use xwininfo on the hidden ID to get its size
            WIDTH=$(xwininfo -id "$WID" | grep 'Width:' | awk '{print $2}')
            HEIGHT=$(xwininfo -id "$WID" | grep 'Height:' | awk '{print $2}')

            # 3. Calculate center position
            X=$(( (SCREEN_WIDTH - WIDTH) / 2 ))
            Y=$(( (SCREEN_HEIGHT - HEIGHT) / 2 ))

            # 4. Move the window while it is invisible
            xdotool windowmove "$WID" "$X" "$Y"

            # 5. Show the window now that it is centered
            xdotool windowmap "$WID"
            break
        fi
    done

    # Wait for the configuration window to close before returning to menu
    wait $WINE_PID
fi

# 4. Return to Menu
kstart bash "$WINEPREFIX_PATH/winscr_menu.sh" &
