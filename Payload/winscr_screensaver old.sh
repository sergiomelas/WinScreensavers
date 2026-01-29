#!/bin/bash
# filename: winscr_screensaver.sh
# Final version 2026 for X11 & KDE Plasma 6
# Features: Application Timer, Video Reset, Lock-Detection Fix, and Status Messaging

# Display title block
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
    [[ -n "$NEW_PID" ]] && kill -9 "$NEW_PID" 2>/dev/null
    [[ -n "$OLD_PID" ]] && kill -9 "$OLD_PID" 2>/dev/null
    WINEPREFIX="/home/$USER/.winscr" wineboot -s 2>/dev/null
    exit 0
}

trap cleanup_exit SIGTERM SIGINT

WINEPREFIX_PATH="/home/$USER/.winscr"
SCR_DIR="$WINEPREFIX_PATH/drive_c/windows/system32"
RANDOM_CONF="$WINEPREFIX_PATH/random_list.conf"
export WINEPREFIX="$WINEPREFIX_PATH"
export WINE_PROMPT_WOW64=0
export WINEDEBUG=-all

# Internal Application Timer
APP_TIMER=0

get_cached_config() {
    local file="$1"
    local default="$2"
    if [[ -f "$file" ]]; then
        cat "$file"
    else
        echo "$default"
    fi
}

is_screen_locked() {
    # Detects if KDE Plasma lock screen is active
    local locked=$(qdbus6 org.freedesktop.ScreenSaver /org/freedesktop/ScreenSaver GetActive 2>/dev/null || \
                   qdbus org.freedesktop.ScreenSaver /org/freedesktop/ScreenSaver GetActive 2>/dev/null)
    if [[ "$locked" == "true" ]]; then return 0; fi
    return 1
}

is_video_engine_active() {
    # 1. D-Bus Inhibit (Browsers/YouTube)
    local dbus_inhibit=$(qdbus6 org.freedesktop.PowerManagement.Inhibit /org/freedesktop/PowerManagement/Inhibit HasInhibit 2>/dev/null || \
                         qdbus org.freedesktop.PowerManagement.Inhibit /org/freedesktop/PowerManagement/Inhibit HasInhibit 2>/dev/null)
    if [[ "$dbus_inhibit" == "true" ]]; then return 0; fi

    # 2. Pipewire Node Check (Targeting browsers/media players)
    if command -v pw-dump >/dev/null; then
        local VideoActive=$(pw-dump | grep -E "node.name.*(firefox|chrome|brave|vlc|mpv)" -A 15 | grep -c "running")
        if [ "$VideoActive" -gt 0 ]; then return 0; fi
    fi
    return 1
}

trigger_cmd() {
    SCR_SAVER=$(get_cached_config "$WINEPREFIX_PATH/scrensaver.conf" "Random.scr")
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

    OLD_PID=""
    while true; do
        # Exit if user moves mouse or screen is locked
        if [ "$(xprintidle)" -lt 1500 ] || is_screen_locked; then
            break;
        fi

        CURRENT_SCR="${VALID_ARRAY[$(( RANDOM % ${#VALID_ARRAY[@]} ))]}"
        echo -e "\n[$(date +%H:%M:%S)] Starting $CURRENT_SCR..."

        wine "$SCR_DIR/$CURRENT_SCR" /s >/dev/null 2>&1 &
        NEW_PID=$!
        disown $NEW_PID 2>/dev/null

        sleep 4
        [[ -n "$OLD_PID" ]] && kill -9 "$OLD_PID" 2>/dev/null

        START_TIME=$(date +%s)
        USER_STOP=false

        while true; do
            sleep 0.5

            # CRITICAL: Kill saver if screen locks to allow password entry
            if is_screen_locked; then
                USER_STOP=true
                STOP_REASON="System Locked"
                break
            fi

            # Monitor physical activity
            if [ "$(xprintidle)" -lt 1500 ] || ! kill -0 "$NEW_PID" 2>/dev/null; then
                USER_STOP=true
                STOP_REASON="User activity detected"
                break
            fi

            CURRENT_PERIOD=$(get_cached_config "$WINEPREFIX_PATH/random_period.conf" "60")
            ELAPSED=$(( $(date +%s) - START_TIME ))
            if [ ${#VALID_ARRAY[@]} -gt 1 ] && [ $ELAPSED -ge "$CURRENT_PERIOD" ]; then
                break
            fi
        done

        if $USER_STOP; then
            echo -e "\n[$(date +%H:%M:%S)] CLEANUP: $STOP_REASON."
            kill -9 "$NEW_PID" 2>/dev/null

            # --- MINIMIZED LATENCY LOCKING ---
            # We lock here, as soon as activity is detected and process is killed
            LockSc=$(get_cached_config "/home/$USER/.winscr/lockscreen.conf" "0")
            if [ "$LockSc" -gt "0" ] && ! is_screen_locked; then
                loginctl lock-session
                echo -e "[$(date +%H:%M:%S)] Locking Screen."
            fi

            WINEPREFIX="$WINEPREFIX_PATH" wineboot -s 2>/dev/null
            break
        fi
        OLD_PID="$NEW_PID"
    done
}

# --- MAIN SERVICE LOOP ---
while true; do
    SCR_TIME=$(get_cached_config "$WINEPREFIX_PATH/timeout.conf" "60")

    # 1. Reset timer if system is locked
    if is_screen_locked; then
        APP_TIMER=0
        sleep 5
        continue
    fi

    # 2. Reset timer if physical movement detected
    if [ "$(xprintidle)" -lt 1500 ]; then
        APP_TIMER=0
    fi

    # 3. Check for Video Activity
    if is_video_engine_active; then
        APP_TIMER=0
        printf "\r[STATUS] Video activity detected! Timer Reset.             "
        xset s reset 2>/dev/null
        sleep 2
        continue
    fi

    # 4. Handle Countdown or Launch
    if [ "$APP_TIMER" -ge "$SCR_TIME" ]; then
        trigger_cmd
        APP_TIMER=0
    else
        REMAINING=$(( SCR_TIME - APP_TIMER ))
        printf "\r[TIMER] Starting in: %02d seconds... (Current: %ss)      " "$REMAINING" "$APP_TIMER"
        ((APP_TIMER++))
    fi

    sleep 1
done
