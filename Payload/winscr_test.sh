#!/bin/bash
# filename: winscr_test.sh

echo " "
echo " ##################################################################"
echo " #                                                                #"
echo " #                         Test  scrennsaver                      #"
echo " #    Developed for X11/Wayland & KDE Plasma by sergio melas 2026 #"
echo " #                                                                #"
echo " #                Emai: sergiomelas@gmail.com                     #"
echo " #                   Released under GPL V2.0                      #"
echo " #                                                                #"
echo " ##################################################################"
echo " "

# --- 1. PATH CONFIGURATION ---
WINEPREFIX_PATH="$HOME/.winscr"
SCR_DIR="$WINEPREFIX_PATH/drive_c/windows/system32"

# --- 2. GET SELECTION ---
SCR_SAVER=$(cat "$WINEPREFIX_PATH/scrensaver.conf" 2>/dev/null || echo "Random.scr")

# --- 3. TEST LOGIC ---
if [[ "$SCR_SAVER" == "Random.scr" ]]; then
    zenity --info --title="Test Mode" --text="To test a specific screensaver, please select one in the 'Choose' menu first.\n\nRandom mode cannot be tested here." --width=350
else
    if [ -f "$SCR_DIR/$SCR_SAVER" ]; then
        echo "Testing: $SCR_SAVER"
        WINEPREFIX="$WINEPREFIX_PATH" WINEDEBUG=-all wine "$SCR_DIR/$SCR_SAVER" /s
    else
        zenity --error --text="File not found: $SCR_SAVER\nPlease check your installation."
    fi
fi

# --- 4. UNLOCK & RELAUNCH MENU (Standardized Fixed Block) ---
rm -f "$WINEPREFIX_PATH/.running"

KSRT_EXE=$(command -v kstart6 || command -v kstart5 || command -v kstart)

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
