#!/bin/bash
# filename: winscr_about.sh

echo " "
echo " ##################################################################"
echo " #                                                                #"
echo " #                           About                                #"
echo " #    Developed for X11/Wayland & KDE Plasma by sergio melas 2026 #"
echo " #                                                                #"
echo " #                Emai: sergiomelas@gmail.com                     #"
echo " #                   Released under GPL V2.0                      #"
echo " #                                                                #"
echo " ##################################################################"
echo " "

WINEPREFIX_PATH="$HOME/.winscr"

zenity --info --title="About WinScreensaver" \
    --text="WinScreensaver v1.0\n\nDeveloped by Sergio Melas 2026\nReleased under GPL V2.0\n\nSupports X11/Wayland across all Linux Desktops." \
    --icon-name="winscreensaver" --width=350

# --- THE UNIVERSAL HANDOVER ---
rm -f "$WINEPREFIX_PATH/.running"
winscreensaver &
exit 0
