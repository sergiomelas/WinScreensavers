#!/bin/bash
# filename: winscr_screensaver.sh
# Final version 2026 for X11 & KDE Plasma 6


# Display title block as a persistent header
echo " "
echo " ##################################################################"
echo " #                 Windows screensavers launcher                  #"
echo " #       Developed for X11 & KDE Plasma by sergio melas 2026      #"
echo " #                                                                #"
echo " #                Email: sergiomelas@gmail.com                    #"
echo " #                   Released under GPL V2.0                      #"
echo " ##################################################################"
echo " "
echo "--- Service Started: $(date '+%Y-%m-%d %H:%M:%S') ---"


# --- TERMINATION HANDLER ---
cleanup_exit() {
    echo -e "\n[$(date +%H:%M:%S)] SHUTDOWN: Signal received. Cleaning up..."
    # Kill the current wine screensaver process if it exists
    [[ -n "$NEW_PID" ]] && kill -9 "$NEW_PID" 2>/dev/null
    # Kill the wine server for this prefix specifically
    WINEPREFIX="/home/$USER/.winscr" wineboot -s 2>/dev/null
    exit 0
}

# Trap SIGTERM (shutdown/logout) and SIGINT (Ctrl+C)
trap cleanup_exit SIGTERM SIGINT


WINEPREFIX_PATH="/home/$USER/.winscr"
rm -f "$WINEPREFIX_PATH"/.running
SCR_DIR="$WINEPREFIX_PATH/drive_c/windows/system32"
RANDOM_CONF="$WINEPREFIX_PATH/random_list.conf"
export WINEPREFIX="$WINEPREFIX_PATH"
export WINE_PROMPT_WOW64=0
export WINEDEBUG=-all

# Toggle variable to prevent spamming logs
VIDEO_MSG_SENT=false

get_cached_config() {
    local file="$1"
    local default="$2"
    local var_name="$3"
    local current_mtime=$(stat -c %Y "$file" 2>/dev/null || echo 0)
    local mtime_var="LAST_MTIME_${var_name}"

    if [[ "$current_mtime" != "${!mtime_var}" ]]; then
        local value=$(cat "$file" 2>/dev/null || echo "$default")
        eval "${var_name}=\"$value\""
        eval "${mtime_var}=\"$current_mtime\""
    fi
}

check_stop_conditions() {
    if [ "$(xprintidle)" -lt 1200 ]; then
        STOP_REASON="User activity detected"
        return 0
    fi
    local MON_STATUS=$(xset q | grep "Monitor is" | awk '{print $NF}')
    if [[ "$MON_STATUS" != "On" ]]; then
        STOP_REASON="Monitor turned off (DPMS)"
        return 0
    fi
    local SysLockSc=$(qdbus6 org.freedesktop.ScreenSaver /org/freedesktop/ScreenSaver GetActive 2>/dev/null || \
                    qdbus org.freedesktop.ScreenSaver /org/freedesktop/ScreenSaver GetActive 2>/dev/null)
    if [[ "$SysLockSc" == "true" ]]; then
        STOP_REASON="System Lock detected"
        return 0
    fi
    return 1
}

is_video_engine_active() {
    if command -v pw-dump >/dev/null; then
        local VideoActive=$(pw-dump | grep -E "media.class.*Video" -B 20 | grep -c "running")
        if [ "$VideoActive" -gt 0 ]; then return 0; fi
    fi
    if command -v playerctl >/dev/null; then
        if playerctl status 2>/dev/null | grep -q "Playing"; then return 0; fi
    fi
    if command -v wpctl >/dev/null; then
        local AudioRun=$(wpctl status | sed -n '/Streams:/,/^$/p' | grep -c "running")
        if [ "$AudioRun" -gt 0 ]; then return 0; fi
    fi
    return 1
}

trigger_cmd() {
    if is_video_engine_active; then
        # Check if we already told the user about this video session
        if [ "$VIDEO_MSG_SENT" = false ]; then
            echo -e "\n[$(date +%H:%M:%S)] STATUS: Video Engine Active. Screensaver Inhibited."
            VIDEO_MSG_SENT=true
        fi
        return;
    fi

    # Reset the toggle if video stops so it can print again for the next video
    VIDEO_MSG_SENT=false

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

    PREVIOUS_PID=""
    while true; do
        if check_stop_conditions; then break; fi

        CURRENT_SCR="${VALID_ARRAY[$(( RANDOM % ${#VALID_ARRAY[@]} ))]}"
        echo -e "\n[$(date +%H:%M:%S)] Starting $CURRENT_SCR in Wine..."

        wine "$SCR_DIR/$CURRENT_SCR" /s >/dev/null 2>&1 &
        NEW_PID=$!
        sleep 2

        START_TIME=$(date +%s)
        USER_STOP=false

        while true; do
            sleep 0.2
            get_cached_config "$WINEPREFIX_PATH/random_period.conf" "60" "CURRENT_PERIOD"

            if check_stop_conditions || is_video_engine_active || ! kill -0 "$NEW_PID" 2>/dev/null; then
                USER_STOP=true
                break
            fi

            NOW=$(date +%s)
            if [ ${#VALID_ARRAY[@]} -gt 1 ]; then
                ELAPSED=$(( NOW - START_TIME ))
                REMAINING=$(( CURRENT_PERIOD - ELAPSED ))
                printf "\r    >> Rotation: %02d seconds remaining... " "$REMAINING"
                [[ $ELAPSED -ge "$CURRENT_PERIOD" ]] && { echo ""; break; }
            fi
        done

        if $USER_STOP; then
            echo -e "\n[$(date +%H:%M:%S)] CLEANUP: $STOP_REASON. Terminating Wine environment."
            kill -9 "$NEW_PID" 2>/dev/null
            wineserver -k 2>/dev/null
            break
        fi
    done
}

# MAIN SERVICE LOOP
while true; do
    get_cached_config "$WINEPREFIX_PATH/timeout.conf" "60" "SCR_TIME"
    IDLE_LIMIT=$((SCR_TIME * 1000))
    CURRENT_IDLE=$(xprintidle)

    if [ "$CURRENT_IDLE" -ge "$IDLE_LIMIT" ]; then
        trigger_cmd
    else
        # Reset the message toggle when user is active so it works the next time they go idle
        VIDEO_MSG_SENT=false

        REMAINING_IDLE=$(( (IDLE_LIMIT - CURRENT_IDLE) / 1000 ))
        [ "$REMAINING_IDLE" -lt 0 ] && REMAINING_IDLE=0
        printf "\r[IDLE MONITOR] Screensaver starting in: %02d seconds... " "$REMAINING_IDLE"
    fi

    sleep 1
done


