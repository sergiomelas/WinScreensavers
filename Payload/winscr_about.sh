#!/bin/bash
# filename: winscr_about.sh

echo " "
echo " ##################################################################"
echo " #                                                                #"
echo " #                        About screensaver                       #"
echo " #    Developed for X11/Wayland & KDE Plasma by sergio melas 2026 #"
echo " #                                                                #"
echo " #                Emai: sergiomelas@gmail.com                     #"
echo " #                   Released under GPL V2.0                      #"
echo " #                                                                #"
echo " ##################################################################"
echo " "

# --- 1. PATH DETECTION ---
WINEPREFIX_PATH="$HOME/.winscr"
ICON_PATH="$WINEPREFIX_PATH/winscr_icon.png"

if [ ! -f "$ICON_PATH" ]; then
    ICON_PATH="/usr/share/winscreensaver/Payload/winscr_icon.png"
fi

# --- 2. DISPLAY INFO ---
zenity --info --timeout 10 \
    --title="About WinScreensaver" \
    --window-icon="$ICON_PATH" \
    --text="Developed for X11/Wayland and KDE Plasma 6\nAuthor: Sergio Melas 2026\nReleased under GPL V2.0"

# --- 3. UNLOCK & RELAUNCH MENU (Standardized Fixed Block) ---
rm -f "$WINEPREFIX_PATH/.running"

KSRT_EXE=$(command -v kstart6 || command -v kstart5 || command -v kstart)

# Define command first to avoid & || syntax errors
if command -v winscreensaver >/dev/null; then
    LAUNCH_CMD="winscreensaver"
else
    LAUNCH_CMD="bash $WINEPREFIX_PATH/winscr_menu.sh"
fi

if [ -n "$KSRT_EXE" ]; then
    $KSRT_EXE $LAUNCH_CMD &
else
    $LAUNCH_CMD &
fi

exit 0
