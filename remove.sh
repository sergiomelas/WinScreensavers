#!/bin/bash
# filename: remove.sh
# Final version 2026 for X11 & KDE Plasma 6

echo " "
echo "##################################################################"
echo "#                   Uninstalling XScreensaver                    #"
echo "#       Developed for X11 & KDE Plasma by sergio melas 2026      #"
echo "##################################################################"

WINEPREFIX_PATH="/home/$USER/.winscr"

echo "Stopping services and Wine processes..."
# 1. Kill the bash service loop first
pkill -f "winscr_screensaver.sh" 2>/dev/null

# 2. Kill the wine environment properly
export WINEPREFIX="$WINEPREFIX_PATH"
wineserver -k 2>/dev/null
# Wait a moment for Wine to release file locks
sleep 1

# 3. Force kill any remaining stray wine processes for this prefix
pgrep -f "$WINEPREFIX_PATH" | xargs kill -9 2>/dev/null

echo "Removing application files..."
# 4. Remove the main installation directory
if [ -d "$WINEPREFIX_PATH" ]; then
    rm -rf "$WINEPREFIX_PATH"
    echo "  [OK] Installation directory removed."
fi

echo "Removing desktop shortcuts..."
# 5. Remove the autostart and menu entries
rm -f "$HOME/.config/autostart/winscr_service.desktop"
rm -f "$HOME/.local/share/applications/WinScreensaver.desktop"

# 6. Notify the desktop environment to refresh its menus
if command -v update-desktop-database >/dev/null; then
    update-desktop-database "$HOME/.local/share/applications/" 2>/dev/null
fi

echo " "
echo "WinScreensaver has been successfully removed."
echo "##################################################################"
