#!/bin/bash
# filename: winscr_configure.sh
# Final version 2026 - Fixed Intermediate Selector & Focus

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

# 1. READ ACTIVE SELECTION
SCR_SAVER=$(cat "$WINEPREFIX_PATH/scrensaver.conf" 2>/dev/null || echo "Random.scr")

# 2. SELECTION LOGIC
if [[ "$SCR_SAVER" == "Random.scr" ]]; then
    # --- RANDOM MODE: Mandatory Intermediate Selector ---

    # Load the pool from the config file
    if [ -f "$WINEPREFIX_PATH/random_list.conf" ]; then
        # Map file lines to array (ensures spaces in filenames don't break logic)
        mapfile -t pool < "$WINEPREFIX_PATH/random_list.conf"
    else
        # Fallback if no pool list exists
        mapfile -t pool < <(find "$SCR_DIR" -maxdepth 1 -iname "*.scr" -printf "%f\n" | sort)
    fi

    # Prepare Zenity arguments
    ZEN_ARGS=()
    for scr in "${pool[@]}"; do
        # Skip empty lines
        [[ -z "$scr" ]] && continue
        ZEN_ARGS+=(FALSE "$scr")
    done

    # FORCE the popup
    TARGET_SCR=$(zenity --list --radiolist --title="Configure Random Pool" \
        --text="Select which screensaver from your pool to configure:" \
        --column="Pick" --column="Screensaver" "${ZEN_ARGS[@]}" \
        --height=450 --width=350)

    # If user cancels the selector, go back to menu
    if [ -z "$TARGET_SCR" ]; then
        rm -f "$WINEPREFIX_PATH/.running"
        winscreensaver &
        exit 0
    fi
else
    # --- SINGLE MODE: Use the saved selection ---
    TARGET_SCR="$SCR_SAVER"
fi

# 3. NATIVE WINDOW LAUNCH (WAITING)
if [ -f "$SCR_DIR/$TARGET_SCR" ]; then
    echo "Configuring: $TARGET_SCR"

    # RELEASE THE LOCK BEFORE WINE
    # This ensures the configurator window gets the system focus immediately
    rm -f "$WINEPREFIX_PATH/.running"

    # DIRECT CALL (Waits for exit)
    WINEDEBUG=-all wine "$SCR_DIR/$TARGET_SCR" /c
fi

# --- 4. THE UNIVERSAL HANDOVER ---
# Relaunch menu once configuration is closed
winscreensaver &
exit 0
