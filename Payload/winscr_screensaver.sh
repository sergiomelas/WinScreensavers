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
RANDOM_CONF="$WINEPREFIX_PATH/random_list.conf"
export WINEPREFIX="$WINEPREFIX_PATH"
SCRIPT_PID=$$

trigger_cmd() {
    MedRun=$(pacmd list-sink-inputs 2>/dev/null | grep -c 'state: RUNNING')
    LockSc=$(cat "$WINEPREFIX_PATH/lockscreen.conf" 2>/dev/null || echo "0")

    if [ "$MedRun" -eq '0' ]; then
        SCR_SAVER=$(cat "$WINEPREFIX_PATH/scrensaver.conf" 2>/dev/null || echo "Random.scr")
        SysLockSc=$(/usr/lib/qt6/bin/qdbus org.freedesktop.ScreenSaver /org/freedesktop/ScreenSaver GetActive)

        if [[ "$SCR_SAVER" == "Random.scr" ]]; then
            # 1. Load the list
            if [[ -s "$RANDOM_CONF" ]]; then
                readarray -t array < "$RANDOM_CONF"
            else
                readarray -t array < <(find "$SCR_DIR" -maxdepth 1 -name "*.scr" -printf "%f\n")
            fi

            [[ ${#array[@]} -eq 0 ]] && return

            # 2. Logic Check: If only ONE screensaver is selected, do NOT use the rotation loop
            if [ "${#array[@]}" -eq 1 ]; then
                SINGLE_SCR="${array[0]}"
                wine "$SCR_DIR/$SINGLE_SCR" /s &
                WINE_PID=$!
                while true; do
                    sleep 1
                    if [ "$(xprintidle)" -lt 1000 ] || [[ "$(xset q)" == *"Monitor is Off"* ]]; then
                        kill -9 "$WINE_PID" 2>/dev/null
                        wineserver -k9 2>/dev/null
                        break
                    fi
                done
            else
                # 3. Multiple Screensavers: Use the Rotation/Cycle Logic
                PREVIOUS_PID=""
                while true; do
                    PERIOD=$(cat "$WINEPREFIX_PATH/random_period.conf" 2>/dev/null || echo "60")
                    CURRENT_SCR="${array[$(( RANDOM % ${#array[@]} ))]}"

                    wine "$SCR_DIR/$CURRENT_SCR" /s &
                    NEW_PID=$!
                    sleep 1.5
                    [ -n "$PREVIOUS_PID" ] && kill -9 "$PREVIOUS_PID" 2>/dev/null
                    PREVIOUS_PID=$NEW_PID

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
            fi
        else
            # Standard Single Mode (from scrensaver.conf)
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
