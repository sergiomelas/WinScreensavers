#!/bin/bash
# filename: winscr_screensaver.sh

echo " "
echo " ##################################################################"
echo " #                 Windows screensavers launcher                  #"
echo " #       Developed for X11 & KDE Plasma by sergio melas 2026      #"
echo " ##################################################################"

#!/bin/bash
# filename: winscr_screensaver.sh

WINEPREFIX_PATH="/home/$USER/.winscr"
SCR_DIR="$WINEPREFIX_PATH/drive_c/windows/system32"
RANDOM_CONF="$WINEPREFIX_PATH/random_list.conf"
export WINEPREFIX="$WINEPREFIX_PATH"
# Disable the experimental mode that is causing your SEH errors
export WINE_PROMPT_WOW64=0

trigger_cmd() {
    MedRun=$(pacmd list-sink-inputs 2>/dev/null | grep -c 'state: RUNNING')
    if [ "$MedRun" -eq '0' ]; then
        # Ensure a clean environment before starting
        wineserver -k 2>/dev/null
        sleep 1

        SCR_SAVER=$(cat "$WINEPREFIX_PATH/scrensaver.conf" 2>/dev/null || echo "Random.scr")

        # Build Valid List
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

        while true; do
            CURRENT_SCR="${VALID_ARRAY[$(( RANDOM % ${#VALID_ARRAY[@]} ))]}"
            PERIOD=$(cat "$WINEPREFIX_PATH/random_period.conf" 2>/dev/null || echo "60")

            # Launch with redirected stderr to prevent D-Bus spam from breaking the loop
            wine "$SCR_DIR/$CURRENT_SCR" /s >/dev/null 2>&1 &
            NEW_PID=$!

            # WAIT LOGIC: Verify the process actually stays alive
            # If it dies in the first 2 seconds, it's a crash (like in your logs)
            sleep 2
            if ! kill -0 "$NEW_PID" 2>/dev/null; then
                echo "Screensaver $CURRENT_SCR crashed, picking another..."
                continue # Try the next random one immediately
            fi

            # Seamlessly kill previous if it exists
            [ -n "$PREVIOUS_PID" ] && kill "$PREVIOUS_PID" 2>/dev/null
            PREVIOUS_PID=$NEW_PID

            # Monitoring Loop
            USER_ACTIVE=false
            LOOPS=$(( PERIOD * 2 ))
            for (( i=0; i<LOOPS; i++ )); do
                sleep 0.5
                # Check for activity OR if the screensaver crashed mid-way
                if [ "$(xprintidle)" -lt 500 ] || ! kill -0 "$NEW_PID" 2>/dev/null; then
                    USER_ACTIVE=true
                    break
                fi
            done

            if $USER_ACTIVE; then
                # Clean exit: Kill everything and shutdown wineserver
                kill "$NEW_PID" 2>/dev/null
                wineserver -k 2>/dev/null
                break
            fi
        done

        # Locking logic
        LockSc=$(cat "$WINEPREFIX_PATH/lockscreen.conf" 2>/dev/null || echo "0")
        SysLockSc=$(/usr/lib/qt6/bin/qdbus org.freedesktop.ScreenSaver /org/freedesktop/ScreenSaver GetActive)
        [[ "$SysLockSc" == *"false"* ]] && [[ "$LockSc" -gt '0' ]] && loginctl lock-session
    fi
}

# Main Loop
while true; do
    SCR_TIME=$(cat "$WINEPREFIX_PATH/timeout.conf" 2>/dev/null || echo "60")
    if [ "$(xprintidle)" -ge $((SCR_TIME * 1000)) ]; then
        trigger_cmd
    fi
    sleep 2
done
