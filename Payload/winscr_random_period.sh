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
CURRENT_VAL=$(cat "$PERIOD_CONF" 2>/dev/null || echo "60")

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

PICK=$(zenity --list --radiolist --title="Random Period" \
    --text="How many minutes between screensaver changes?" \
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

# --- THE UNIVERSAL HANDOVER ---
rm -f "$WINEPREFIX_PATH/.running"
winscreensaver &
exit 0
