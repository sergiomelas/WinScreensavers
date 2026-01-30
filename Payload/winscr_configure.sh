#!/bin/bash
# filename: winscr_configure.sh

echo " "
echo " ##################################################################"
echo " #                                                                #"
echo " #                     Configure screensaver                      #"
echo " #    Developed for X11/Wayland & KDE Plasma by sergio melas 2026 #"
echo " #                                                                #"
echo " #                Emai: sergiomelas@gmail.com                     #"
echo " #                   Released under GPL V2.0                      #"
echo " #                                                                #"
echo " ##################################################################"
echo " "

# --- THEME & ENVIRONMENT ---
export QT_QPA_PLATFORMTHEME=qt6ct
WINEPREFIX_PATH="$HOME/.winscr"
SCR_DIR="$WINEPREFIX_PATH/drive_c/windows/system32"
RANDOM_CONF="$WINEPREFIX_PATH/random_list.conf"
export WINEPREFIX="$WINEPREFIX_PATH"

# --- HELPER: STANDARDIZED RELAUNCH (Fixed Syntax) ---
relaunch_menu() {
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
}

# 1. READ CURRENT MODE
SCR_SAVER=$(cat "$WINEPREFIX_PATH/scrensaver.conf" 2>/dev/null || echo "Random.scr")
TARGET_SCR=""

# 2. LOGIC FOR RANDOM VS SINGLE
if [[ "$SCR_SAVER" == "Random.scr" ]]; then
    if [[ -s "$RANDOM_CONF" ]]; then
        readarray -t array < "$RANDOM_CONF"
    else
        readarray -t array < <(find "$SCR_DIR" -maxdepth 1 -name "*.scr" -printf "%f\n" | sort)
    fi

    COUNT=${#array[@]}
    if [ "$COUNT" -eq 0 ]; then
        zenity --error --text="No Windows screensavers found in:\n$SCR_DIR"
        relaunch_menu
        exit 1
    elif [ "$COUNT" -eq 1 ]; then
        TARGET_SCR="${array[0]}"
    else
        ZEN_ARGS=()
        for scr in "${array[@]}"; do
            [[ -z "$scr" ]] && continue
            ZEN_ARGS+=("FALSE" "$scr")
        done

        TARGET_SCR=$(zenity --list --radiolist --title="Configure Screensaver" \
            --text="Select a screensaver from your Random List to configure:" \
            --column="Pick" --column="Screensaver Name" \
            "${ZEN_ARGS[@]}" --height=450 --width=400)

        if [[ -z "$TARGET_SCR" ]]; then
            relaunch_menu
            exit 0
        fi
    fi
else
    TARGET_SCR="$SCR_SAVER"
fi

# 3. LAUNCH WINE CONFIGURATION (/c flag)
if [[ -n "$TARGET_SCR" ]]; then
    # --- RESTORE THEME PARAMETERS ---
    export QT_QPA_PLATFORMTHEME=kde
    export QT_QPA_PLATFORM=xcb
    export XDG_CURRENT_DESKTOP=KDE

    wine "$SCR_DIR/$TARGET_SCR" /c &
    WINE_PID=$!


    if [ "$XDG_SESSION_TYPE" != "wayland" ] && command -v xdotool >/dev/null && command -v xwininfo >/dev/null; then
        for i in {1..25}; do
            sleep 0.2
            WID=$(xdotool search --pid $WINE_PID --onlyvisible 2>/dev/null | tail -1)
            if [ -n "$WID" ]; then
                SCREEN_WIDTH=$(xwininfo -root | grep 'Width:' | awk '{print $2}')
                SCREEN_HEIGHT=$(xwininfo -root | grep 'Height:' | awk '{print $2}')
                WIDTH=$(xwininfo -id "$WID" | grep 'Width:' | awk '{print $2}')
                HEIGHT=$(xwininfo -id "$WID" | grep 'Height:' | awk '{print $2}')
                X=$(( (SCREEN_WIDTH - WIDTH) / 2 ))
                Y=$(( (SCREEN_HEIGHT - HEIGHT) / 2 ))
                xdotool windowmove "$WID" "$X" "$Y"
                break
            fi
        done
    fi
    wait $WINE_PID
fi

# 4. RETURN TO MENU
relaunch_menu
exit 0
