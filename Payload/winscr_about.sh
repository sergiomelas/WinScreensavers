#!/bin/bash
# filename: winscr_about.sh

echo " "
echo " ##################################################################"
echo " #                        About screensaver                       #"
echo " #       Developed for X11 & KDE Plasma by sergio melas 2026      #"
echo " ##################################################################"

WINEPREFIX_PATH="/home/$USER/.winscr"
ICON_PATH="$WINEPREFIX_PATH/winscr_icon.png"

zenity --info --timeout 5  --title="About XScresavers" --window-icon="$ICON_PATH"  --text="Developed for X11 and KDE Plasma \n          (C) sergio melas 2026"

rm -f "$WINEPREFIX_PATH"/.running  #Unlock istance
kstart bash "$WINEPREFIX_PATH/winscr_menu.sh" &
