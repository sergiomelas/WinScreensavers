#!/bin/bash
# filename: winscr_configure.sh

echo " "
echo " ##################################################################"
echo " #                     Configure scrennsaver                      #"
echo " #       Developed for X11 & KDE Plasma by sergio melas 2026      #"
echo " ##################################################################"

SCR_SAVER=$(cat /home/$USER/.winscr/scrensaver.conf)
if [[ "$SCR_SAVER" != "Random.scr" ]]; then
    WINEPREFIX=/home/$USER/.winscr
    wine "/home/$USER/.winscr/drive_c/windows/system32/$SCR_SAVER"
fi

kstart bash "/home/$USER/.winscr/winscr_menu.sh" &
