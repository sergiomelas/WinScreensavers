#!/bin/bash
# filename: remove.sh
# Purpose: Clean up user-space environment during uninstallation

echo " "
echo " ##################################################################"
echo " #                                                                #"
echo " #                Windows screensavers launcher                   #"
echo " #    Developed for X11/Wayland & KDE Plasma by sergio melas 2026 #"
echo " #                                                                #"
echo " #                Email: sergiomelas@gmail.com                    #"
echo " #                   Released under GPL V2.0                      #"
echo " #                                                                #"
echo " ##################################################################"
echo " "

WINEPREFIX_PATH="$HOME/.winscr"

# 1. Kill any active processes
echo "Stopping background services..."
pkill -f "winscr_screensaver.sh" 2>/dev/null
pkill -f "winscr_menu.sh" 2>/dev/null
pkill -f ".scr" 2>/dev/null

# 2. Remove from Autostart
if [ -f "$HOME/.config/autostart/winscreensaver.desktop" ]; then
    echo "Removing autostart entry..."
    rm "$HOME/.config/autostart/winscreensaver.desktop"
fi

# 3. Optional: Notification
# We leave the ~/.winscr folder intact so the user doesn't lose their .scr files
# If you want to wipe everything, uncomment the line below:
# rm -rf "$WINEPREFIX_PATH"

echo "User-space cleanup complete."
