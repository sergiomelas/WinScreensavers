#!/bin/bash
# filename: remove.sh

echo " "
echo " ##################################################################"
echo " #                       Remove screensaver                       #"
echo " #       Developed for X11 & KDE Plasma by sergio melas 2026      #"
echo " ##################################################################"


INSTALL_DIR="/home/$USER/.winscr"

# 1. Kill the service and the Wine environment immediately
echo "[INFO] Stopping background services and Wine environment..."
pkill -f "winscr_screensaver.sh" 2>/dev/null
pkill -f "winscr_choose.sh" 2>/dev/null
pkill -f "winscr_menu.sh" 2>/dev/null

# Specifically target the Wine prefix server
export WINEPREFIX="$INSTALL_DIR"
wineserver -k 2>/dev/null

# 2. Delete the installation and data directory
if [ -d "$INSTALL_DIR" ]; then
    echo "[INFO] Deleting installation directory: $INSTALL_DIR"
    rm -rf "$INSTALL_DIR"
fi

# 3. Remove Desktop and Autostart entries
echo "[INFO] Removing system menu and autostart entries..."
rm -f "$HOME/.config/autostart/winscr_service.desktop"
rm -f "$HOME/.local/share/applications/WinScreensaver.desktop"

# 4. Refresh KDE Plasma application cache (Ensures icon disappears immediately)
if command -v kbuildsycoca6 >/dev/null; then
    kbuildsycoca6 2>/dev/null
elif command -v kbuildsycoca5 >/dev/null; then
    kbuildsycoca5 2>/dev/null
fi

echo "[SUCCESS] Windows Screensaver Service has been fully removed."
echo "[NOTE] System packages (Wine, PipeWire, etc.) were kept on your system."
