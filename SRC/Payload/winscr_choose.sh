#!/bin/bash
# filename: winscr_lock.sh

echo " "
echo " ##################################################################"
echo " #                                                                #"
echo " #                     Configure Lock Screen                      #"
echo " #    Developed for X11/Wayland & KDE Plasma by sergio melas 2026 #"
echo " #                                                                #"
echo " #                Emai: sergiomelas@gmail.com                     #"
echo " #                   Released under GPL V2.0                      #"
echo " #                                                                #"
echo " ##################################################################"
echo " "

# --- 1. PATH DETECTION ---
WINEPREFIX_PATH="$HOME/.winscr"

# --- 2. READ CONFIGURATION ---
LockS=$(cat "$WINEPREFIX_PATH/lockscreen.conf" 2>/dev/null || echo "0")

if [ "$LockS" == "1" ]; then
    R_NO="FALSE"; R_YES="TRUE"
else
    R_NO="TRUE"; R_YES="FALSE"
fi

# --- 3. LAUNCH ZENITY ---
LockScr=$(zenity --list --radiolist --title="Lock Screen Configuration" \
    --text "Lock the session when the screensaver ends (on activity)?" \
    --column "Pick" --column "Answer" \
    $R_NO "No" $R_YES "Yes" --height=250 --width=400)

# --- 4. PROCESS SELECTION ---
if [ -n "$LockScr" ]; then
    [[ "$LockScr" == "Yes" ]] && LockVal=1 || LockVal=0
    echo "$LockVal" > "$WINEPREFIX_PATH/lockscreen.conf"
fi

# --- 5. THE UNIVERSAL HANDOVER ---
rm -f "$WINEPREFIX_PATH/.running"
winscreensaver &
exit 0
