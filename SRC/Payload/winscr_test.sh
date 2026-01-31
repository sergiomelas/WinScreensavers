#!/bin/bash
# filename: winscr_test.sh

echo " "
echo " ##################################################################"
echo " #                                                                #"
echo " #                         Test  screensaver                      #"
echo " #    Developed for X11/Wayland & KDE Plasma by sergio melas 2026 #"
echo " #                                                                #"
echo " #                Email: sergiomelas@gmail.com                    #"
echo " #                   Released under GPL V2.0                      #"
echo " #                                                                #"
echo " ##################################################################"
echo " "

# --- 1. PATH CONFIGURATION ---
WINEPREFIX_PATH="$HOME/.winscr"
SCR_DIR="$WINEPREFIX_PATH/drive_c/windows/system32"
export WINEPREFIX="$WINEPREFIX_PATH"

# --- 2. GET CURRENT SELECTION ---
SCR_SAVER=$(cat "$WINEPREFIX_PATH/scrensaver.conf" 2>/dev/null || echo "Random.scr")

# --- 3. SELECTION LOGIC ---
if [[ "$SCR_SAVER" == "Random.scr" ]]; then
    # --- RANDOM MODE: Ask which one to test ---
    # Try to load the user's specific pool first
    if [ -f "$WINEPREFIX_PATH/random_list.conf" ]; then
        readarray -t pool < "$WINEPREFIX_PATH/random_list.conf"
    else
        # Fallback to scanning the directory if no pool is defined
        readarray -t pool < <(find "$SCR_DIR" -maxdepth 1 -iname "*.scr" -printf "%f\n" | sort)
    fi

    # Build the Zenity list
    ZEN_ARGS=()
    for scr in "${pool[@]}"; do
        [ -z "$scr" ] && continue
        ZEN_ARGS+=(FALSE "$scr")
    done

    TARGET_SCR=$(zenity --list --radiolist --title="Test Random Pool" \
        --text="Select which screensaver to preview:" \
        --column="Pick" --column="Screensaver" "${ZEN_ARGS[@]}" --height=450 --width=350)

    # If user cancels
    if [ -z "$TARGET_SCR" ]; then
        rm -f "$WINEPREFIX_PATH/.running"
        winscreensaver &
        exit 0
    fi
else
    # --- SINGLE MODE: Direct test ---
    TARGET_SCR="$SCR_SAVER"
fi

# --- 4. EXECUTE PREVIEW ---
if [ -f "$SCR_DIR/$TARGET_SCR" ]; then
    echo "Testing: $TARGET_SCR"
    # WINEDEBUG=-all keeps the console clean
    # /s is the Windows flag for "Start Screensaver" mode
    WINEDEBUG=-all wine "$SCR_DIR/$TARGET_SCR" /s
else
    zenity --error --text="File not found: $TARGET_SCR\nPlease check your installation." --width=350
fi

# --- 5. THE UNIVERSAL HANDOVER ---
rm -f "$WINEPREFIX_PATH/.running"
winscreensaver &
exit 0
