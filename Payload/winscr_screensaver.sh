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

# Function to read config only if the file has been modified (Efficient Refresh)
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
    # Check if audio is playing
    MedRun=$(pacmd list-sink-inputs 2>/dev/null | grep -c 'state: RUNNING')
    if [ "$MedRun" -eq '0' ]; then
        wineserver -k 2>/dev/null
        sleep 1

        # Determine which screensaver mode we are in
        SCR_SAVER=$(cat "$WINEPREFIX_PATH/scrensaver.conf" 2>/dev/null || echo "Random.scr")

        # Build the list of valid screensavers to use
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

        # OPTIMIZATION: If only ONE screensaver is active, don't use the rotation loop
        if [ "${#VALID_ARRAY[@]}" -eq 1 ]; then
            TARGET_SCR="${VALID_ARRAY[0]}"
            wine "$SCR_DIR/$TARGET_SCR" /s >/dev/null 2>&1 &
            WINE_PID=$!

            while true; do
                sleep 1
                # Exit if: User Active OR Monitor Off OR Process Crashed
                if [ "$(xprintidle)" -lt 1000 ] || [[ "$(xset q)" == *"Monitor is Off"* ]] || ! kill -0 "$WINE_PID" 2>/dev/null; then
                    kill "$WINE_PID" 2>/dev/null
                    wineserver -k 2>/dev/null
                    break
                fi
            done
        else
            # ROTATION MODE: Multiple screensavers selected
            PREVIOUS_PID=""
            while true; do
                CURRENT_SCR="${VALID_ARRAY[$(( RANDOM % ${#VALID_ARRAY[@]} ))]}"

                wine "$SCR_DIR/$CURRENT_SCR" /s >/dev/null 2>&1 &
                NEW_PID=$!

                # Wait for startup and check for immediate crash
                sleep 2
                if ! kill -0 "$NEW_PID" 2>/dev/null; then continue; fi

                # Seamless transition
                [ -n "$PREVIOUS_PID" ] && kill "$PREVIOUS_PID" 2>/dev/null
                PREVIOUS_PID=$NEW_PID

                USER_ACTIVE=false
                START_TIME=$(date +%s)

                # Monitoring loop with Immediate Config Refresh
                while true; do
                    sleep 1
                    # Refresh Rotation Period from disk only if changed
                    get_cached_config "$WINEPREFIX_PATH/random_period.conf" "60" "CURRENT_PERIOD"

                    NOW=$(date +%s)
                    ELAPSED=$(( NOW - START_TIME ))

                    # Exit conditions
                    if [ "$(xprintidle)" -lt 1000 ] || [[ "$(xset q)" == *"Monitor is Off"* ]] || ! kill -0 "$NEW_PID" 2>/dev/null; then
                        USER_ACTIVE=true
                        break
                    fi

                    # Time to rotate?
                    if [ "$ELAPSED" -ge "$CURRENT_PERIOD" ]; then
                        break
                    fi
                done

                if $USER_ACTIVE; then
                    kill "$NEW_PID" 2>/dev/null
                    wineserver -k 2>/dev/null
                    break
                fi
            done
        fi

        # Locking logic after screensaver ends
        LockSc=$(cat "$WINEPREFIX_PATH/lockscreen.conf" 2>/dev/null || echo "0")
        SysLockSc=$(/usr/lib/qt6/bin/qdbus org.freedesktop.ScreenSaver /org/freedesktop/ScreenSaver GetActive)
        [[ "$SysLockSc" == *"false"* ]] && [[ "$LockSc" -gt '0' ]] && loginctl lock-session
    fi
}

# MAIN SERVICE LOOP
while true; do
    # Refresh Timeout setting from disk only if changed
    get_cached_config "$WINEPREFIX_PATH/timeout.conf" "60" "SCR_TIME"

    IDLE_LIMIT=$((SCR_TIME * 1000))

    if [ "$(xprintidle)" -ge "$IDLE_LIMIT" ]; then
        trigger_cmd
    fi
    sleep 2
done
