#!/bin/bash
# filename: winscr_screensaver.sh
# Final Production Version 2026 - Clean Wayland & X11 with Improved Cycling

echo " "
echo " ##################################################################"
echo " #                                                                #"
echo " #                Windows screensavers launcher                   #"
echo " #    Developed for X11/Wayland & KDE Plasma by sergio melas 2026 #"
echo " #                                                                #"
echo " #  DETECTION: Xorg (xprintidle) / Wayland (Swayidle Pulse)       #"
echo " #  STATUS: Production Ready - Cycling Optimized for Wayland      #"
echo " ##################################################################"
echo " "

# --- CONFIGURATION ---
WINEPREFIX_PATH="$HOME/.winscr"
SCR_DIR="$WINEPREFIX_PATH/drive_c/windows/system32"
export WINEPREFIX="$WINEPREFIX_PATH"
export WINEDEBUG=-all

# The clean location for the heartbeat (RAM-based)
PULSE_FILE="/tmp/winscr_idle"

# --- SESSION SETUP ---
if [[ -n "$WAYLAND_DISPLAY" ]]; then
    IS_WAYLAND=true
    rm -f "$PULSE_FILE"
    pkill -f "swayidle -w timeout 1" 2>/dev/null

    # Start the "State Manager"
    swayidle -w timeout 1 "touch '$PULSE_FILE'" resume "rm -f '$PULSE_FILE'" &
    LISTENER_PID=$!
    echo "[DEBUG] Wayland engine started (PID: $LISTENER_PID)"
else
    IS_WAYLAND=false
    echo "[DEBUG] X11 engine active."
fi

# Cleanup listener and pulse file on script exit
trap '[[ -n "$LISTENER_PID" ]] && kill $LISTENER_PID 2>/dev/null; rm -f "$PULSE_FILE"; exit' SIGINT SIGTERM

# --- HELPERS ---
is_user_active_now() {
    if [ "$IS_WAYLAND" = true ]; then
        if [ ! -f "$PULSE_FILE" ]; then
            return 0 # SUCCESS: RESET TIMER
        fi
    else
        local idle
        idle=$(xprintidle 2>/dev/null | tr -dc '0-9')
        [[ -n "$idle" && "$idle" -lt 1500 ]] && return 0
    fi
    return 1
}

is_screen_locked() {
    local locked
    locked=$( (qdbus6 org.freedesktop.ScreenSaver /org/freedesktop/ScreenSaver GetActive || \
               qdbus org.freedesktop.ScreenSaver /org/freedesktop/ScreenSaver GetActive) 2>/dev/null )
    [[ "$locked" == "true" ]] && return 0 || return 1
}

# --- THE LAUNCHER ---
trigger_cmd() {
    local VALID_ARRAY=()
    while IFS= read -r -d '' file; do
        VALID_ARRAY+=("$file")
    done < <(find "$SCR_DIR" -maxdepth 1 -iname "*.scr" -print0 2>/dev/null)

    [[ ${#VALID_ARRAY[@]} -eq 0 ]] && return

    local OLD_PID=""
    while true; do
        if is_user_active_now || is_screen_locked; then break; fi

        local CURRENT_SCR="${VALID_ARRAY[$(( RANDOM % ${#VALID_ARRAY[@]} ))]}"
        echo -e "\n[$(date +%H:%M:%S)] LAUNCHING: $(basename "$CURRENT_SCR")"

        # Start the new screensaver
        wine "$CURRENT_SCR" /s >/dev/null 2>&1 &
        local NEW_PID=$!

        # Wayland transition: Give the new one 3 seconds to claim the surface
        # before we aggressively kill the previous one.
        sleep 3
        if [[ -n "$OLD_PID" ]]; then
            kill "$OLD_PID" 2>/dev/null
            sleep 0.5
            kill -9 "$OLD_PID" 2>/dev/null
        fi

        local ROT_TIMER=0
        while true; do
            sleep 1
            if is_user_active_now || is_screen_locked; then
                echo -e "\n[$(date +%H:%M:%S)] STOP: Activity detected."
                kill -9 "$NEW_PID" 2>/dev/null
                break 2
            fi

            # If the process died on its own, exit this loop
            if ! kill -0 "$NEW_PID" 2>/dev/null; then break 2; fi

            ((ROT_TIMER++))
            local ROT_RAW=$(cat "$WINEPREFIX_PATH/random_period.conf" 2>/dev/null || echo "60")
            ROT_RAW=${ROT_RAW%.*}

            # Since you are now using seconds everywhere, we use ROT_RAW directly
            local ROT_TARGET=$(( ROT_RAW == 0 ? 30 : ROT_RAW ))

            printf "\r[ROTATION] Switch in: %02d s...                     " "$(( ROT_TARGET - ROT_TIMER ))"

            if [ ${#VALID_ARRAY[@]} -gt 1 ] && [ "$ROT_TIMER" -ge "$ROT_TARGET" ]; then
                OLD_PID="$NEW_PID"
                break
            fi
        done
    done
}

# --- MAIN LOOP ---
APP_TIMER=0
echo "[$(date +%H:%M:%S)] MONITOR: Started."

while true; do
    SCR_TIMEOUT_RAW=$(cat "$WINEPREFIX_PATH/timeout.conf" 2>/dev/null || echo 30)
    SCR_TIMEOUT=${SCR_TIMEOUT_RAW%.*}

    if is_user_active_now || is_screen_locked; then
        APP_TIMER=0
    fi

    if [ "$APP_TIMER" -ge "$SCR_TIMEOUT" ]; then
        trigger_cmd
        APP_TIMER=0
    else
        printf "\r[TIMER] Launch in: %02d s (Current: %d s)               " "$(( SCR_TIMEOUT - APP_TIMER ))" "$APP_TIMER"
        ((APP_TIMER++))
    fi
    sleep 1
done
