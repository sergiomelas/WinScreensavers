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

# --- THE LAUNCHER ---
trigger_cmd() {
    local VALID_ARRAY=()
    local RANDOM_CONF="$WINEPREFIX_PATH/random_list.conf"

    # Check if the user has a specific list saved from winscr_random_choose.sh
    if [[ -f "$RANDOM_CONF" ]] && [[ -s "$RANDOM_CONF" ]]; then
        echo "[DEBUG] Using custom random pool from random_list.conf"
        while IFS= read -r line; do
            # Ensure the file actually exists before adding to pool
            if [[ -f "$SCR_DIR/$line" ]]; then
                VALID_ARRAY+=("$SCR_DIR/$line")
            fi
        done < "$RANDOM_CONF"
    else
        # Fallback: Use everything in System32 if no list is defined
        echo "[DEBUG] No random list found. Using all available screensavers."
        while IFS= read -r -d '' file; do
            VALID_ARRAY+=("$file")
        done < <(find "$SCR_DIR" -maxdepth 1 -iname "*.scr" -print0 2>/dev/null)
    fi

    [[ ${#VALID_ARRAY[@]} -eq 0 ]] && return

    # ... rest of your OLD_PID / NEW_PID logic remains exactly the same ...

    local OLD_PID=""
    local NEW_PID="" # Explicitly declare both here

    while true; do
        if is_user_active_now || is_screen_locked; then  #Kill screesavers if lock screen
            echo -e "\n[$(date +%H:%M:%S)] STOP: Activity or Lock detected."
            # Kill the current screensaver
            kill "$NEW_PID" 2>/dev/null
            sleep 0.5
            kill -9 "$NEW_PID" 2>/dev/null

            # Kill the transition screensaver if it exists
            if [[ -n "$OLD_PID" ]]; then
               kill "$OLD_PID" 2>/dev/null
               sleep 0.5
               kill -9 "$OLD_PID" 2>/dev/null
            fi
            break 2
        fi

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
        LockSc=$( cat $HOME/.winscr/lockscreen.conf )
        SysLockSc=$( /usr/lib/qt6/bin/qdbus org.freedesktop.ScreenSaver /org/freedesktop/ScreenSaver GetActive ) #get status of kde lockscreen after scrrensaver exits
        if [[ "$SysLockSc" == *false* ]]; then #If  kde didnt alredy losked the screen
            if [ $LockSc -gt '0' ]; then #if asked lock screen
                loginctl lock-session
            fi
        fi
     done
}

# --- MAIN LOOP ---
APP_TIMER=0
echo "[$(date +%H:%M:%S)] MONITOR: Started."

while true; do
    SCR_TIMEOUT_RAW=$(cat "$WINEPREFIX_PATH/timeout.conf" 2>/dev/null || echo 30)
    SCR_TIMEOUT=${SCR_TIMEOUT_RAW%.*}

    if is_user_active_now || is_screen_locked || is_video_engine_active; then
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
