#!/bin/bash
# filename: winscr_about.sh

echo " "
echo " ##################################################################"
echo " #                                                                #"
echo " #                            About                               #"
echo " #    Developed for X11/Wayland & KDE Plasma by sergio melas 2026 #"
echo " #                                                                #"
echo " #                Email: sergiomelas@gmail.com                    #"
echo " #                    Released under GPL V2.0                     #"
echo " #                                                                #"
echo " ##################################################################"
echo " "

WINEPREFIX_PATH="$HOME/.winscr"
SYS_PAYLOAD="/usr/share/winscreensaver/Payload"
GITHUB_REPO="sergiomelas/WinScreensavers"
GITHUB_URL="https://github.com/$GITHUB_REPO"
CURRENT_VER="3.2"

# --- HELPER: STANDARDIZED RELAUNCH ---
relaunch_menu() {
    rm -f "$WINEPREFIX_PATH/.running"
    if command -v winscreensaver >/dev/null; then
        winscreensaver &
    else
        bash "$WINEPREFIX_PATH/winscr_menu.sh" &
    fi
}

# Added "Check for Update" as a third extra button
RESPONSE=$(zenity --info --title="About WinScreensaver" \
    --text="WinScreensaver v$CURRENT_VER\n\nDeveloped by Sergio Melas 2026\nReleased under GPL V2.0\n\nSupports X11/Wayland across all Linux Desktops." \
    --icon-name="winscreensaver" \
    --width=550 \
    --extra-button="Check for Update" \
    --extra-button="Check GitHub" \
    --extra-button="Refresh Installation")

# --- HANDLE THE RESPONSES ---

if [ "$RESPONSE" = "Check GitHub" ]; then
    xdg-open "$GITHUB_URL" &

elif [ "$RESPONSE" = "Check for Update" ]; then
    # Fetch latest tag from GitHub API
    LATEST_TAG=$(curl -s "https://api.github.com/repos/$GITHUB_REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

    if [ -z "$LATEST_TAG" ]; then
        zenity --error --text="Could not connect to GitHub. Check your internet connection."
    elif [ "$LATEST_TAG" == "v$CURRENT_VER" ] || [ "$LATEST_TAG" == "$CURRENT_VER" ]; then
        zenity --info --text="You are up to date! (v$CURRENT_VER is the latest version)."
    else
        if zenity --question --text="A new version ($LATEST_TAG) is available!\n\nWould you like to go to the releases page?"; then
            xdg-open "$GITHUB_URL/releases" &
        fi
    fi

elif [ "$RESPONSE" = "Refresh Installation" ]; then
    echo "[INFO] Refreshing local scripts..."
    if [ -d "$SYS_PAYLOAD" ]; then
        # 1. KILL the old background process so the new code can take over
        pkill -f "winscr_screensaver.sh"

        # 2. Refresh scripts
        rm -f "$WINEPREFIX_PATH"/winscr_*.sh
        cp -f "$SYS_PAYLOAD"/*.sh "$WINEPREFIX_PATH/"
        chmod +x "$WINEPREFIX_PATH"/*.sh

        # 3. RESTART the background monitor immediately
        bash "$WINEPREFIX_PATH/winscr_screensaver.sh" &

        zenity --info --text="Local installation refreshed and monitor restarted!" --timeout=2
    else
        zenity --error --text="System payload not found. Reinstall the .deb package."
    fi
fi

# 5. FINAL TERMINATION
relaunch_menu
exit 0

