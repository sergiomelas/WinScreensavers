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
SCR_SAVER=$(cat "$WINEPREFIX_PATH/scrensaver.conf" 2>/dev/null || echo "Random.scr")

MENU_ITEMS=( FALSE "Choose Screensaver" )

if [[ "$SCR_SAVER" == "Random.scr" ]]; then
    MENU_ITEMS+=( FALSE "Random Change Period Configuration" )
else
    MENU_ITEMS+=( FALSE "Test Screensaver" FALSE "Screensaver Configuration" )
fi

MENU_ITEMS+=(
    FALSE "Locking Screen Configuration"
    FALSE "Activation Timeout Configuration"
    FALSE "About"
)

Choice=$(zenity --list --radiolist --title="Win Screensavers Menu" \
    --text "Current Mode: $SCR_SAVER" \
    --column "Pick" --column "Answer" \
    "${MENU_ITEMS[@]}" --height=400 --width=400)

case $Choice in
    'Choose Screensaver') kstart bash "$WINEPREFIX_PATH/winscr_choose.sh" & ;;
    'Random Change Period Configuration') kstart bash "$WINEPREFIX_PATH/winscr_random_period.sh" & ;;
    'Test Screensaver') kstart bash "$WINEPREFIX_PATH/winscr_test.sh" & ;;
    'Screensaver Configuration') kstart bash "$WINEPREFIX_PATH/winscr_configure.sh" & ;;
    'Activation Timeout Configuration') kstart bash "$WINEPREFIX_PATH/winscr_timeout.sh" & ;;
    'Locking Screen Configuration') kstart bash "$WINEPREFIX_PATH/winscr_lock.sh" & ;;
    'About') kstart bash "$WINEPREFIX_PATH/winscr_about.sh" & ;;
esac
