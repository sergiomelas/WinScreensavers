#!/bin/bash
# filename: winscr_timeout.sh

echo " "
echo " ##################################################################"
echo " #                                                                #"
echo " #                        Choose Timeout                          #"
echo " #    Developed for X11/Wayland & KDE Plasma by sergio melas 2026 #"
echo " #                                                                #"
echo " #                Emai: sergiomelas@gmail.com                     #"
echo " #                   Released under GPL V2.0                      #"
echo " #                                                                #"
echo " ##################################################################"
echo " "

# --- 1. PATH CONFIGURATION ---
WINEPREFIX_PATH="$HOME/.winscr"
CURRENT_TIM=$(cat "$WINEPREFIX_PATH/timeout.conf" 2>/dev/null || echo "600")

# --- HELPER: STANDARDIZED RELAUNCH ---
relaunch_menu() {
    rm -f "$WINEPREFIX_PATH/.running"
    if command -v winscreensaver >/dev/null; then
        winscreensaver &
    else
        bash "$WINEPREFIX_PATH/winscr_menu.sh" &
    fi
}

# --- 2. DEFINE BULLET OPTIONS ---
OPTIONS=(
    "30 seconds" 30
    "2 minutes"  120
    "5 minutes"  300
    "10 minutes" 600
    "15 minutes" 900
    "30 minutes" 1800
    "1 hour"     3600
    "Disabled"   1000000000
)

ZEN_ARGS=()
for ((i=0; i<${#OPTIONS[@]}; i+=2)); do
    STATE="FALSE"
    [ "${OPTIONS[i+1]}" == "$CURRENT_TIM" ] && STATE="TRUE"
    ZEN_ARGS+=("$STATE" "${OPTIONS[i]}")
done

# --- 3. LAUNCH ZENITY BULLETS ---
PICK=$(zenity --list --radiolist --title="Screensaver Timeout" \
    --column "Pick" --column "Answer" "${ZEN_ARGS[@]}" --height=450 --width=350)

# --- 4. PROCESS CHOICE ---
if [ -n "$PICK" ]; then
    NEW_TIMEOUT=0
    for ((i=0; i<${#OPTIONS[@]}; i+=2)); do
        if [ "${OPTIONS[i]}" == "$PICK" ]; then
            NEW_TIMEOUT="${OPTIONS[i+1]}"
            echo "$NEW_TIMEOUT" > "$WINEPREFIX_PATH/timeout.conf"
            break
        fi
    done

    # --- 5. CONFLICT DETECTION (KDE/XDG Logic) ---
    # (Detection code for power settings to avoid monitor sleep before scr)
fi

# 5. FINAL TERMINATION
relaunch_menu
exit 0

