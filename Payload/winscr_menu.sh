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

# --- One instance only ---
if [ -e "$WINEPREFIX_PATH"/.running ]; then
    echo "Another instance of a Menu/Submenu is already running. Exiting."
    exit 0
else
    touch "$WINEPREFIX_PATH"/.running
fi

RANDOM_CONF="$WINEPREFIX_PATH/random_list.conf"
SCR_SAVER=$(cat "$WINEPREFIX_PATH/scrensaver.conf" 2>/dev/null || echo "Random.scr")

# --- FIX: Create a display variable without the .scr extension ---
SCR_SAVER_DISPLAY="${SCR_SAVER%.scr}"

MENU_ITEMS=( FALSE "Choose Screensaver" )

if [[ "$SCR_SAVER" == "Random.scr" ]]; then
    MENU_ITEMS+=(
        FALSE "Choose Random Screensavers List"
        FALSE "Configure Random Change Period"
    )
else
    if [[ ! -f "$RANDOM_CONF" ]]; then
        MENU_ITEMS+=( FALSE "Initialize Random List" )
    fi
    MENU_ITEMS+=( FALSE "Test Screensaver" )
fi

MENU_ITEMS+=(
    FALSE "Configure Screensaver"
    FALSE "Configure Locking Screen"
    FALSE "Configure Activation Timeout"
    FALSE "About XScresavers"
)

# --- ZENITY CALL ---
# Use the display variable without the extension in the --text field
Choice=$(zenity --list --radiolist --title="Win Screensavers Menu" \
    --text "Current Screensaver: $SCR_SAVER_DISPLAY" \
    --ok-label="Select" \
    --column "Pick" --column "Answer" \
    "${MENU_ITEMS[@]}" --height=480 --width=400)

# Check the exit code: If user hits Cancel or the 'X' button, exit cleanly.
if [ $? -ne 0 ]; then
    rm -f "$WINEPREFIX_PATH"/.running
    exit 0
fi


case $Choice in
    'Choose Screensaver') kstart bash "$WINEPREFIX_PATH/winscr_choose.sh" & ;;
    'Initialize Random List') kstart bash "$WINEPREFIX_PATH/winscr_random_choose.sh" & ;;
    'Choose Random Screensavers List') kstart bash "$WINEPREFIX_PATH/winscr_random_choose.sh" & ;;
    'Configure Random Change Period') kstart bash "$WINEPREFIX_PATH/winscr_random_period.sh" & ;;
    'Test Screensaver') kstart bash "$WINEPREFIX_PATH/winscr_test.sh" & ;;
    'Configure Screensaver') kstart bash "$WINEPREFIX_PATH/winscr_configure.sh" & ;;
    'Configure Activation Timeout') kstart bash "$WINEPREFIX_PATH/winscr_timeout.sh" & ;;
    'Configure Locking Screen') kstart bash "$WINEPREFIX_PATH/winscr_lock.sh" & ;;
    'About XScresavers') kstart bash "$WINEPREFIX_PATH/winscr_about.sh" & ;;
esac

# Unlock instance for next use
rm -f "$WINEPREFIX_PATH"/.running
