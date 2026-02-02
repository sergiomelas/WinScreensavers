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

WINEPREFIX_PATH="$HOME/.winscr"
PERIOD_CONF="$WINEPREFIX_PATH/random_period.conf"
# Default to 60 seconds if file doesn't exist
CURRENT_VAL=$(cat "$PERIOD_CONF" 2>/dev/null || echo "60")

# All values now in SECONDS
OPTIONS=(
    "30 seconds" 30
    "1 minute"   60
    "2 minutes"  120
    "5 minutes"  300
    "10 minutes" 600
    "15 minutes" 900
)

ZEN_ARGS=()
for ((i=0; i<${#OPTIONS[@]}; i+=2)); do
    STATE="FALSE"
    # Match the second value (the integer)
    [ "${OPTIONS[i+1]}" == "$CURRENT_VAL" ] && STATE="TRUE"
    ZEN_ARGS+=("$STATE" "${OPTIONS[i]}")
done

PICK=$(zenity --list --radiolist --title="Random Period" \
    --text="How many seconds/minutes between screensaver changes?" \
    --column="Pick" --column="Period" \
    "${ZEN_ARGS[@]}" --height=450 --width=350)

if [ -n "$PICK" ]; then
    for ((i=0; i<${#OPTIONS[@]}; i+=2)); do
        if [ "${OPTIONS[i]}" == "$PICK" ]; then
            echo "${OPTIONS[i+1]}" > "$PERIOD_CONF"
            break
        fi
    done
fi

rm -f "$WINEPREFIX_PATH/.running"
winscreensaver &
exit 0
