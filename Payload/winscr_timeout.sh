#!/bin/bash
# filename: winscr_timeout.sh

echo " "
echo " ##################################################################"
echo " #                        Choose Timeout                          #"
echo " #       Developed for X11 & KDE Plasma by sergio melas 2026      #"
echo " #                                                                #"
echo " #                Emai: sergiomelas@gmail.com                     #"
echo " #                   Released under GPL V2.0                      #"
echo " #                                                                #"
echo " ##################################################################"

WINEPREFIX_PATH="/home/$USER/.winscr"
CURRENT_TIM=$(cat "$WINEPREFIX_PATH/timeout.conf" 2>/dev/null || echo "300")
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

PICK=$(zenity --list --radiolist --title="Scrennesaver Timeout" --column "Pick" --column "Answer" "${ZEN_ARGS[@]}" --height=400)

if [ -n "$PICK" ]; then
    for ((i=0; i<${#OPTIONS[@]}; i+=2)); do
        if [ "${OPTIONS[i]}" == "$PICK" ]; then
            echo "${OPTIONS[i+1]}" > "$WINEPREFIX_PATH/timeout.conf"
            break
        fi
    done
fi
kstart bash "$WINEPREFIX_PATH/winscr_menu.sh" &
