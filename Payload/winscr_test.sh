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

SCR_SAVER=$(cat /home/$USER/.winscr/scrensaver.conf)
WINEPREFIX=/home/$USER/.winscr

if [[ "$SCR_SAVER" != "Random.scr" ]]; then
    wine "/home/$USER/.winscr/drive_c/windows/system32/$SCR_SAVER" /s
fi

kstart bash "/home/$USER/.winscr/winscr_menu.sh" &
