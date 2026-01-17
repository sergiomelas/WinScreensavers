#!/bin/bash
# filename: winscr_test.sh

echo " "
echo " ##################################################################"
echo " #                     Test      scrennsaver                      #"
echo " #       Developed for X11 & KDE Plasma by sergio melas 2026      #"
echo " #                                                                #"
echo " #                Emai: sergiomelas@gmail.com                     #"
echo " #                   Released under GPL V2.0                      #"
echo " #                                                                #"
echo " ##################################################################"


WINEPREFIX_PATH=/home/$USER/.winscr
SCR_SAVER=$(cat $WINEPREFIX_PATH/scrensaver.conf)

if [[ "$SCR_SAVER" != "Random.scr" ]]; then
    wine "$WINEPREFIX_PATH/drive_c/windows/system32/$SCR_SAVER" /s
fi

rm -f "$WINEPREFIX_PATH"/.running  #Unlock istance
kstart bash "/home/$USER/.winscr/winscr_menu.sh" &
