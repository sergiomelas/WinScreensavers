#!/bin/bash
# filename: remove.sh
# Final version 2026 - User Space Cleanup
# Developed for X11/Wayland by sergio melas 2026

echo " "
echo " ##################################################################"
echo " #                                                                #"
echo " #                Windows screensavers remover                    #"
echo " #    Developed for X11/Wayland & KDE Plasma by sergio melas 2026 #"
echo " #                                                                #"
echo " #                Email: sergiomelas@gmail.com                    #"
echo " #                   Released under GPL V2.0                      #"
echo " #                                                                #"
echo " ##################################################################"
echo " "

WINEPREFIX_PATH="$HOME/.winscr"
AUTOSTART="$HOME/.config/autostart/winscreensaver.desktop"

# Prompt user for confirmation to prevent accidental deletion
if zenity --question --title="Remove WinScreensaver Environment" \
    --text="This will delete all settings and imported screensavers from your home folder.\n\nThe system application will remain installed.\n\nProceed?" --width=400; then

    echo "Stopping background services..."
    # Kill the monitoring service if it is running
    pkill -f "winscr_screensaver.sh" 2>/dev/null

    echo "Removing local files..."
    # Delete the Wine prefix and local scripts
    rm -rf "$WINEPREFIX_PATH"

    echo "Removing autostart entry..."
    # Remove the desktop entry that starts the service at login
    rm -f "$AUTOSTART"

    zenity --info --text="User environment removed successfully." --timeout=3
fi

exit 0
