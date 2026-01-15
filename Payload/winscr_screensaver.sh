#!/bin/bash
# filename: winscr_screensaver.sh

echo " "
echo " ##################################################################"
echo " #                 Windows screensavers launcher                  #"
echo " #       Developed for X11 & KDE Plasma by sergio melas 2026      #"
echo " #                                                                #"
echo " #                Email: sergiomelas@gmail.com                    #"
echo " #                   Released under GPL V2.0                      #"
echo " #                                                                #"
echo " ##################################################################"

WINEPREFIX_PATH="/home/$USER/.winscr"
SCR_DIR="$WINEPREFIX_PATH/drive_c/windows/system32"
RANDOM_CONF="$WINEPREFIX_PATH/random_list.conf"
export WINEPREFIX="$WINEPREFIX_PATH"
export WINE_PROMPT_WOW64=0
SCRIPT_PID=$$

# Efficient Refresh Function
get_cached_config() {
    local file="$1"
    local default="$2"
    local var_name="$3"
    local mtime_var="LAST_MTIME_${var_name}"
    local current_mtime=$(stat -c %Y "$file" 2>/dev/null || echo 0)

    if [[ "$current_mtime" != "${!mtime_var}" ]]; then
        local value=$(cat "$file" 2>/dev/null || echo "$default")
        eval "${var_name}=\"$value\""
        eval "${mtime_var}=\"$current_mtime\""
    fi
}

trigger_cmd() {
    MedRun=$(pacmd list-sink-inputs 2>/dev/null | grep -c 'state: RUNNING')
    if [ "$MedRun" -eq '0' ]; then
        # Clean start
        SCR_SAVER=$(cat "$WINEPREFIX_PATH/scrensaver.conf" 2>/dev/null || echo "Random.scr")

        VALID_ARRAY=()
        if [[ "$SCR_SAVER" == "Random.scr" ]]; then
            if [[ -s "$RANDOM_CONF" ]]; then
                readarray -t temp_array < "$RANDOM_CONF"
                for f in "${temp_array[@]}"; do [[ -f "$SCR_DIR/$f" ]] && VALID_ARRAY+=("$f"); done
            else
                readarray -t VALID_ARRAY < <(find "$SCR_DIR" -maxdepth 1 -name "*.scr" -printf "%f\n")
            fi
        else
            [[ -f "$SCR_DIR/$SCR_SAVER" ]] && VALID_ARRAY+=("$SCR_SAVER")
        fi

        [[ ${#VALID_ARRAY[@]} -eq 0 ]] && return

        if [ "${#VALID_ARRAY[@]}" -eq 1 ]; then
            TARGET_SCR="${VALID_ARRAY[0]}"
            wine "$SCR_DIR/$TARGET_SCR" /s >/dev/null 2>&1 &
            WINE_PID=$!

            while true; do
                sleep 1
                # Improved detection: Check if monitor is NOT "On" (covers Standby, Suspend, Off)
                MON_STATUS=$(xset q | grep "Monitor is" | awk '{print $NF}')
                if [ "$(xprintidle)" -lt 1500 ] || [[ "$MON_STATUS" != "On" ]] || ! kill -0 "$WINE_PID" 2>/dev/null; then
                    kill -9 "$WINE_PID" 2>/dev/null
                    break
                fi
            done
        else
            # ROTATION MODE
            PREVIOUS_PID=""
            while true; do
                CURRENT_SCR="${VALID_ARRAY[$(( RANDOM % ${#VALID_ARRAY[@]} ))]}"
                wine "$SCR_DIR/$CURRENT_SCR" /s >/dev/null 2>&1 &
                NEW_PID=$!

                sleep 2
                if ! kill -0 "$NEW_PID" 2>/dev/null; then continue; fi

                [ -n "$PREVIOUS_PID" ] && kill -9 "$PREVIOUS_PID" 2>/dev/null
                PREVIOUS_PID=$NEW_PID

                USER_ACTIVE=false
                START_TIME=$(date +%s)

                while true; do
                    sleep 1
                    get_cached_config "$WINEPREFIX_PATH/random_period.conf" "60" "CURRENT_PERIOD"

                    # Improved detection for Rotation Mode
                    MON_STATUS=$(xset q | grep "Monitor is" | awk '{print $NF}')
                    if [ "$(xprintidle)" -lt 1500 ] || [[ "$MON_STATUS" != "On" ]] || ! kill -0 "$NEW_PID" 2>/dev/null; then
                        USER_ACTIVE=true
                        break
                    fi

                    NOW=$(date +%s)
                    [[ $(( NOW - START_TIME )) -ge "$CURRENT_PERIOD" ]] && break
                done

                if $USER_ACTIVE; then
                    kill -9 "$NEW_PID" 2>/dev/null
                    break
                fi
            done
        fi

        # Cleanup Wine and Handle Locking
        wineserver -k 2>/dev/null
        LockSc=$(cat "$WINEPREFIX_PATH/lockscreen.conf" 2>/dev/null || echo "0")
        SysLockSc=$(/usr/lib/qt6/bin/qdbus org.freedesktop.ScreenSaver /org/freedesktop/ScreenSaver GetActive)
        [[ "$SysLockSc" == *"false"* ]] && [[ "$LockSc" -gt '0' ]] && loginctl lock-session

        # COOLDOWN: Wait for idle to settle before returning to the main loop
        sleep 3
    fi
}

# MAIN SERVICE LOOP
while true; do
    get_cached_config "$WINEPREFIX_PATH/timeout.conf" "60" "SCR_TIME"
    IDLE_LIMIT=$((SCR_TIME * 1000))

    if [ "$(xprintidle)" -ge "$IDLE_LIMIT" ]; then
        trigger_cmd
    fi
    sleep 2
done
