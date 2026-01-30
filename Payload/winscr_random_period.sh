#!/bin/bash
# filename: winscr_random_period.sh

echo " "
echo " ##################################################################"
echo " #                                                                #"
echo " #                Configure Random Change Period                  #"
echo " #    Developed for X11/Wayland & KDE Plasma by sergio melas 2026 #"
echo " #                                                                #"
echo " #                Emai: sergiomelas@gmail.com                     #"
echo " #                   Released under GPL V2.0                      #"
echo " #                                                                #"
echo " ##################################################################"
echo " "

# --- 1. PATH CONFIGURATION ---
WINEPREFIX_PATH="$HOME/.winscr"
PERIOD_CONF="$WINEPREFIX_PATH/random_period.conf"

# --- 2. READ CURRENT CONFIG ---
# Default to 1 hour (60 minutes) if file is missing
CURRENT_VAL=$(cat "$PERIOD_CONF" 2>/dev/null || echo "60")

# --- 3. DEFINE BULLET OPTIONS (Timeout Philosophy) ---
OPTIONS=(
    "30 seconds" 0.5
    "2 minutes"  2
    "5 minutes"  5
    "10 minutes" 10
    "15 minutes" 15
    "30 minutes" 30
    "1 hour"     60
)

ZEN_ARGS=()
for ((i=0; i<${#OPTIONS[@]}; i+=2)); do
    STATE="FALSE"
    [ "${OPTIONS[i+1]}" == "$CURRENT_VAL" ] && STATE="TRUE"
    ZEN_ARGS+=("$STATE" "${OPTIONS[i]}")
done

# --- 4. LAUNCH ZENITY BULLETS ---
PICK=$(zenity --list --radiolist --title="Random Period" \
    --text="How many minutes between screensaver changes?" \
    --column="Pick" --column="Period" \
    "${ZEN_ARGS[@]}" --height=450 --width=350)

# --- 5. PROCESS CHOICE & SAVE ---
if [ -n "$PICK" ]; then
    NEW_VAL=0
    for ((i=0; i<${#OPTIONS[@]}; i+=2)); do
        if [ "${OPTIONS[i]}" == "$PICK" ]; then
            NEW_VAL="${OPTIONS[i+1]}"
            echo "$NEW_VAL" > "$PERIOD_CONF"
            break
        fi
    done
fi

# --- 6. UNLOCK & RELAUNCH MENU (Standardized Fixed Block) ---
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

exit 0
