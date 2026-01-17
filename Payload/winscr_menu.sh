#!/bin/bash
# filename: winscr_menu.sh

echo " "
echo " ##################################################################"
echo " #                        Choose Option Menu                      #"
echo " #       Developed for X11 & KDE Plasma by sergio melas 2026      #"
echo " #                                                                #"
echo " #                Emai: sergiomelas@gmail.com                     #"
echo " #                   Released under GPL V2.0                      #"
echo " #                                                                #"
echo " ##################################################################"

WINEPREFIX_PATH="/home/$USER/.winscr"


# --- One istance only ---

if [ -e "$WINEPREFIX_PATH"/.running ] #If not first instance or interrupted backup
then
    echo "Another instance of a Menu/Submenu is already running. Exiting."
    exit 0
else
    touch "$WINEPREFIX_PATH"/.running
fi
# -----------------------------------------------------------



WINEPREFIX_PATH="/home/$USER/.winscr"
RANDOM_CONF="$WINEPREFIX_PATH/random_list.conf"
SCR_SAVER=$(cat "$WINEPREFIX_PATH/scrensaver.conf" 2>/dev/null || echo "Random.scr")

MENU_ITEMS=( FALSE "Choose Screensaver" )

# Logic for Random Mode options
if [[ "$SCR_SAVER" == "Random.scr" ]]; then
    MENU_ITEMS+=(
        FALSE "Choose Random Screensavers List"
        FALSE "Configuration Random Change Period"
    )
else
    # If not in random mode AND the list doesn't exist, show Initialize option
    if [[ ! -f "$RANDOM_CONF" ]]; then
        MENU_ITEMS+=( FALSE "Initialize Random List" )
    fi

    # Show Test only when a specific saver is selected
    MENU_ITEMS+=( FALSE "Test Screensaver" )
fi

# ALWAYS show Configuration and the rest of the settings
MENU_ITEMS+=(
    FALSE "Configuration Screensaver"
    FALSE "Configuration Locking Screen"
    FALSE "Configuration Activation Timeout"
    FALSE "About XScresavers"
)

Choice=$(zenity --list --radiolist --title="Win Screensavers Menu" \
    --text "Current Mode: $SCR_SAVER" \
    --column "Pick" --column "Answer" \
    "${MENU_ITEMS[@]}" --height=480 --width=400)

case $Choice in
    'Choose Screensaver') kstart bash "$WINEPREFIX_PATH/winscr_choose.sh" & ;;
    'Initialize Random List') kstart bash "$WINEPREFIX_PATH/winscr_random_choose.sh" & ;;
    'Choose Random Screensavers List') kstart bash "$WINEPREFIX_PATH/winscr_random_choose.sh" & ;;
    'Configuration Random Change Period') kstart bash "$WINEPREFIX_PATH/winscr_random_period.sh" & ;;
    'Test Screensaver') kstart bash "$WINEPREFIX_PATH/winscr_test.sh" & ;;
    'Configuration Screensaver') kstart bash "$WINEPREFIX_PATH/winscr_configure.sh" & ;;
    'Configuration Activation Timeout') kstart bash "$WINEPREFIX_PATH/winscr_timeout.sh" & ;;
    'Configuration Locking Screen') kstart bash "$WINEPREFIX_PATH/winscr_lock.sh" & ;;
    'About XScresavers') kstart bash "$WINEPREFIX_PATH/winscr_about.sh" & ;;
    *) rm -f "$WINEPREFIX_PATH"/.running  #Unlock istance

esac


