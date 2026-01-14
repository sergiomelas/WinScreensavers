#!/bin/bash
# filename: winscr_random_period.sh

echo " "
echo " ##################################################################"
echo " #                  Choose Random Change Period                   #"
echo " #       Developed for X11 & KDE Plasma by sergio melas 2026      #"
echo " ##################################################################"

WINEPREFIX_PATH="/home/$USER/.winscr"
CURRENT_PER=$(cat "$WINEPREFIX_PATH/random_period.conf" 2>/dev/null || echo "60")

OPTIONS=(
    "10 seconds" 10
    "30 seconds" 30
    "1 minute"   60
    "2 minutes"  120
    "5 minutes"  300
    "10 minutes" 600
)

ZEN_ARGS=()
for ((i=0; i<${#OPTIONS[@]}; i+=2)); do
    STATE="FALSE"
    [ "${OPTIONS[i+1]}" == "$CURRENT_PER" ] && STATE="TRUE"
    ZEN_ARGS+=("$STATE" "${OPTIONS[i]}")
done

PICK=$(zenity --list --radiolist --title="Random Rotation Period" \
    --column "Pick" --column "Time" "${ZEN_ARGS[@]}" --height=400 --width=350)

if [ -n "$PICK" ]; then
    for ((i=0; i<${#OPTIONS[@]}; i+=2)); do
        if [ "${OPTIONS[i]}" == "$PICK" ]; then
            echo "${OPTIONS[i+1]}" > "$WINEPREFIX_PATH/random_period.conf"
            break
        fi
    done
fi
kstart bash "$WINEPREFIX_PATH/winscr_menu.sh" &
