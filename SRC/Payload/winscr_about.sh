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
SYS_PAYLOAD="/usr/share/winscreensaver/Payload"
GITHUB_URL="https://github.com/sergiomelas/WinScreensavers"

# Using two extra buttons: one for GitHub and one for Refresh
RESPONSE=$(zenity --info --title="About WinScreensaver" \
    --text="WinScreensaver v3.1\n\nDeveloped by Sergio Melas 2026\nReleased under GPL V2.0\n\nSupports X11/Wayland across all Linux Desktops." \
    --icon-name="winscreensaver" \
    --width=450 \
    --extra-button="Check GitHub" \
    --extra-button="Refresh Installation")

# --- HANDLE THE RESPONSES ---

if [ "$RESPONSE" = "Check GitHub" ]; then
    xdg-open "$GITHUB_URL" &

elif [ "$RESPONSE" = "Refresh Installation" ]; then
    # Perform the "Crap-Killer" sync manually
    echo "[INFO] Refreshing local scripts..."
    if [ -d "$SYS_PAYLOAD" ]; then
        # Remove old scripts first to ensure a clean slate
        rm -f "$WINEPREFIX_PATH"/winscr_*.sh
        # Copy fresh ones from system path
        cp -f "$SYS_PAYLOAD"/*.sh "$WINEPREFIX_PATH/"
        chmod +x "$WINEPREFIX_PATH"/*.sh
        zenity --info --text="Local installation refreshed successfully!" --timeout=2
    else
        zenity --error --text="System payload not found. Reinstall the .deb package."
    fi
fi

# --- THE UNIVERSAL HANDOVER ---
rm -f "$WINEPREFIX_PATH/.running"
winscreensaver &
exit 0
