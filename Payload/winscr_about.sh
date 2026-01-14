#!/bin/bash
# filename: winscr_about.sh

echo " "
echo " ##################################################################"
echo " #                        About screensaver                       #"
echo " #       Developed for X11 & KDE Plasma by sergio melas 2026      #"
echo " ##################################################################"

zenity --info --timeout 5 --title="About" --text="Developed for X11 and KDE Plasma by sergio melas 2026"

kstart bash "/home/$USER/.winscr/winscr_menu.sh" &
