#!/bin/bash
# filename: winscr_configure.sh
# Final version 2026 - Clean Display Intermediate Selector

echo " "
echo " ##################################################################"
echo " #                                                                #"
echo " #                 Configure Windows screensaver                  #"
echo " #    Developed for X11/Wayland & KDE Plasma by sergio melas 2026 #"
echo " #                                                                #"
echo " #                Email: sergiomelas@gmail.com                    #"
echo " #                   Released under GPL V2.0                      #"
echo " #                                                                #"
echo " ##################################################################"
echo " "

WINEPREFIX_PATH="$HOME/.winscr"
SCR_DIR="$WINEPREFIX_PATH/drive_c/windows/system32"
export WINEPREFIX="$WINEPREFIX_PATH"

# --- HELPER: STANDARDIZED RELAUNCH ---
relaunch_menu() {
    rm -f "$WINEPREFIX_PATH/.running"
    if command -v winscreensaver >/dev/null; then
        winscreensaver &
    else
        bash "$WINEPREFIX_PATH/winscr_menu.sh" &
    fi
}

# 1. READ ACTIVE SELECTION
SCR_SAVER=$(cat "$WINEPREFIX_PATH/scrensaver.conf" 2>/dev/null || echo "Random.scr")

# 2. SELECTION LOGIC
if [[ "$SCR_SAVER" == "Random.scr" ]]; then
    # --- RANDOM MODE: Mandatory Intermediate Selector ---

    if [ -f "$WINEPREFIX_PATH/random_list.conf" ]; then
        mapfile -t pool < "$WINEPREFIX_PATH/random_list.conf"
    else
        mapfile -t pool < <(find "$SCR_DIR" -maxdepth 1 -iname "*.scr" -printf "%f\n" | sort)
    fi

    # Prepare Zenity arguments (Displaying without .scr extension)
    ZEN_ARGS=()
    for scr in "${pool[@]}"; do
        [[ -z "$scr" ]] && continue
        # Zenity uses the hidden first column value for the choice
        # We show the name without extension in the second column
        ZEN_ARGS+=(FALSE "$scr" "${scr%.scr}")
    done

    # FORCE the popup with hidden data column
    TARGET_SCR=$(zenity --list --radiolist --title="Configure Random Pool" \
        --text="Select which screensaver from your pool to configure:" \
        --column="Pick" --column="ID" --column="Screensaver" \
        --hide-column=2 --print-column=2 \
        "${ZEN_ARGS[@]}" --height=450 --width=350)

    if [ -z "$TARGET_SCR" ]; then
        rm -f "$WINEPREFIX_PATH/.running"
        winscreensaver &
        exit 0
    fi
else
    TARGET_SCR="$SCR_SAVER"
fi

# 3. NATIVE WINDOW LAUNCH (WAITING)
if [ -f "$SCR_DIR/$TARGET_SCR" ]; then
    echo "Configuring: $TARGET_SCR"
    rm -f "$WINEPREFIX_PATH/.running"
    WINEDEBUG=-all wine "$SCR_DIR/$TARGET_SCR" /c
fi

# 5. FINAL TERMINATION
relaunch_menu
exit 0

