#!/bin/bash
# filename: remove.sh

echo " "
echo " ##################################################################"
echo " #                       Remove screensaver                       #"
echo " #       Developed for X11 & KDE Plasma by sergio melas 2026      #"
echo " ##################################################################"

WINEPREFIX_PATH="/home/$USER/.winscr"
pkill -f "winscr_screensaver.sh"
WINEPREFIX="$WINEPREFIX_PATH" wineserver -k9 2>/dev/null
rm -rf "$WINEPREFIX_PATH"
rm -f "$HOME/.config/autostart/winscr_service.desktop"
rm -f "$HOME/.local/share/applications/WinScreensaver.desktop"
