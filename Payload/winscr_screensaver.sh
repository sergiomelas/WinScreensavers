#!/bin/bash
# filename: winscr_screensaver.sh

echo " "
echo " ##################################################################"
echo " #                 Windows screensavers launcher                  #"
echo " #       Developed for X11 & KDE Plasma by sergio melas 2026      #"
echo " #                                                                #"
echo " #                Emai: sergiomelas@gmail.com                     #"
echo " #                   Released under GPL V2.0                      #"
echo " #                                                                #"
echo " ##################################################################"
echo " "

WINEPREFIX_PATH="/home/$USER/.winscr"
SCR_DIR="$WINEPREFIX_PATH/drive_c/windows/system32"
export WINEPREFIX="$WINEPREFIX_PATH"
SCRIPT_PID=$$

trigger_cmd() {
    MedRun=$(pacmd list-sink-inputs 2>/dev/null | grep -c 'state: RUNNING')
    LockSc=$(cat "$WINEPREFIX_PATH/lockscreen.conf" 2>/dev/null || echo "0")

    if [ "$MedRun" -eq '0' ]; then
        SCR_SAVER=$(cat "$WINEPREFIX_PATH/scrensaver.conf" 2>/dev/null || echo "Random.scr")
        SysLockSc=$(/usr/lib/qt6/bin/qdbus org.freedesktop.ScreenSaver /org/freedesktop/ScreenSaver GetActive)

        PREVIOUS_PID=""

        if [[ "$SCR_SAVER" == "Random.scr" ]]; then
            while true; do
                # 1. Read the user-defined rotation period (Default to 60s)
                PERIOD=$(cat "$WINEPREFIX_PATH/random_period.conf" 2>/dev/null || echo "60")

                # 2. Select next random screensaver
                readarray -t array < <(find "$SCR_DIR" -maxdepth 1 -name "*.scr" -printf "%f\n")
                [[ ${#array[@]} -eq 0 ]] && return
                CURRENT_SCR="${array[$(( RANDOM % ${#array[@]} ))]}"

                # 3. Seamless Transition: Launch new before killing old
                wine "$SCR_DIR/$CURRENT_SCR" /s &
                NEW_PID=$!
                sleep 1.5

                [ -n "$PREVIOUS_PID" ] && kill -9 "$PREVIOUS_PID" 2>/dev/null
                PREVIOUS_PID=$NEW_PID

                # 4. Monitor for activity OR screen blanking
                USER_ACTIVE=false
                LOOPS=$(( PERIOD * 2 ))
                for (( i=0; i<LOOPS; i++ )); do
                    sleep 0.5
                    if [ "$(xprintidle)" -lt 500 ]; then
                        USER_ACTIVE=true
                        break
                    fi
                    if [[ "$(xset q)" == *"Monitor is Off"* ]]; then
                        USER_ACTIVE=true
                        break
                    fi
                done

                if $USER_ACTIVE; then
                    WINE_PIDS=$(pgrep -f "$WINEPREFIX_PATH" | grep -v "^$SCRIPT_PID$")
                    [ -n "$WINE_PIDS" ] && kill -9 $WINE_PIDS 2>/dev/null
                    wineserver -k9 2>/dev/null
                    break
                fi
            done
        else
            wine "$SCR_DIR/$SCR_SAVER" /s &
            WINE_PID=$!
            while true; do
                sleep 1
                if [ "$(xprintidle)" -lt 1000 ] || [[ "$(xset q)" == *"Monitor is Off"* ]]; then
                    kill -9 "$WINE_PID" 2>/dev/null
                    wineserver -k9 2>/dev/null
                    break
                fi
            done
        fi
        [[ "$SysLockSc" == *"false"* ]] && [[ "$LockSc" -gt '0' ]] && loginctl lock-session
    fi
}

while true; do
    SCR_TIME=$(cat "$WINEPREFIX_PATH/timeout.conf" 2>/dev/null || echo "60")
    IDLE_LIMIT=$((SCR_TIME * 1000))
    if [ "$(xprintidle)" -ge "$IDLE_LIMIT" ]; then
        trigger_cmd
    fi
    sleep 2
done
