#!/bin/bash
# filename: winscr_lock.sh

echo  " "
echo  " ##################################################################"
echo  " #                                                                #"
echo  " #                     Configure Lock Screen                      #"
echo  " #    Developed for X11/Wayland & KDE Plasma by sergio melas 2026 #"
echo  " #                                                                #"
echo  " #                Emai: sergiomelas@gmail.com                     #"
echo  " #                   Released under GPL V2.0                      #"
echo  " #                                                                #"
echo  " ##################################################################"
echo  " "

# --- 1. PATH DETECTION ---
WINEPREFIX_PATH="$HOME/.winscr"

# --- HELPER: STANDARDIZED RELAUNCH ---
relaunch_menu() {
    # 1. Clean the lock file so the new menu can start
    rm -f "$WINEPREFIX_PATH/.running"

    # 2. Heal the Daemon (Only if not already running)
    if ! pgrep -f "winscr_screensaver.sh" >/dev/null; then
        pkill -f "winscreensaver" 2>/dev/null
        wineserver -k 2>/dev/null
        sleep 0.5
        bash "$WINEPREFIX_PATH/winscr_screensaver.sh" &
    fi

    # 3. Always launch the menu script directly
    # This ignores the 'winscreensaver' command check and uses your script
    bash "$WINEPREFIX_PATH/winscr_menu.sh" &

    # 4. Exit
    exit 0
}

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

# --- 5. UNLOCK & RELAUNCH MENU (Standardized Fixed Block) ---
rm -f "$WINEPREFIX_PATH/.running"

KSRT_EXE=$(command -v kstart6 || command -v kstart5 || command -v kstart)

if command -v winscreensaver >/dev/null; then
    LAUNCH_CMD="winscreensaver"
else
    LAUNCH_CMD="bash $WINEPREFIX_PATH/winscr_menu.sh"
fi

# 5. FINAL TERMINATION
relaunch_menu
exit 0

