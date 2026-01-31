#!/bin/bash
# filename: winscr_configure.sh

echo " "
echo " ##################################################################"
echo " #                                                                #"
echo " #                 Configure Windows scrennsaver                  #"
echo " #    Developed for X11/Wayland & KDE Plasma by sergio melas 2026 #"
echo " #                                                                #"
echo " #                Email: sergiomelas@gmail.com                    #"
echo " #                   Released under GPL V2.0                      #"
echo " #                                                                #"
echo " ##################################################################"
echo " "

WINEPREFIX_PATH="$HOME/.winscr"
SCR_DIR="$WINEPREFIX_PATH/drive_c/windows/system32"
export WINEPREFIX="$WINEPREFIX_PATH"

SCR_SAVER=$(cat "$WINEPREFIX_PATH/scrensaver.conf" 2>/dev/null || echo "Random.scr")

if [[ "$SCR_SAVER" == "Random.scr" ]]; then
    # Pick a random one just to show a config menu
    TARGET_SCR=$(find "$SCR_DIR" -maxdepth 1 -iname "*.scr" -printf "%f\n" | shuf -n 1)
else
    TARGET_SCR="$SCR_SAVER"
fi

if [ -f "$SCR_DIR/$TARGET_SCR" ]; then
    wine "$SCR_DIR/$TARGET_SCR" /c
fi

# --- THE UNIVERSAL HANDOVER ---
rm -f "$WINEPREFIX_PATH/.running"
winscreensaver &
exit 0
