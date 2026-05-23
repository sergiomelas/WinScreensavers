#!/bin/bash
# filename: winscr_screensaver.sh
# Final version 2026 - Seamless Transition & Exit-Activity Detection

echo " "
echo " ##################################################################"
echo " #                                                                #"
echo " #                Windows screensavers launcher                   #"
echo " #    Developed for X11/Wayland & KDE Plasma by sergio melas 2026 #"
echo " #                                                                #"
echo " #                Email: sergiomelas@gmail.com                    #"
echo " #                   Released under GPL V2.0                      #"
echo " #                                                                #"
echo " ##################################################################"
echo " "
echo "--- Service Started: $(date '+%Y-%m-%d %H:%M:%S') ---"

# --- CONFIGURATION ---
WINEPREFIX_PATH="$HOME/.winscr"
SCR_DIR="$WINEPREFIX_PATH/drive_c/windows/system32"
CURRENT_INDEX=-1

export WINEPREFIX="$WINEPREFIX_PATH"
export WINE_PROMPT_WOW64=0
export WINEDEBUG=-all

# --- SESSION SETUP ---
if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
    IS_WAYLAND=true
    if ! pgrep -x "swayidle" > /dev/null; then
        nohup swayidle -w timeout 1 "touch /tmp/winscr_idle" resume "rm -f /tmp/winscr_idle" > /dev/null 2>&1 &
    fi
else
    IS_WAYLAND=false
fi

# --- HELPERS ---
get_cached_config() {
    local val
    val=$( [[ -f "$1" ]] && cat "$1" || echo "$2" )
    echo "${val%.*}"
}

is_screen_locked() {
    local locked
    locked=$(qdbus6 org.freedesktop.ScreenSaver /org/freedesktop/ScreenSaver GetActive 2>/dev/null || \
             qdbus org.freedesktop.ScreenSaver /org/freedesktop/ScreenSaver GetActive 2>/dev/null)
    [[ "$locked" == "true" ]] && return 0 || return 1
}

is_user_active_now() {
    if [ "$IS_WAYLAND" = true ]; then
        [[ ! -f /tmp/winscr_idle ]] && return 0
    else
        local idle
        idle=$(xprintidle 2>/dev/null | tr -dc '0-9')
        [[ -n "$idle" && "$idle" -lt 1500 ]] && return 0
    fi
    return 1
}

is_video_engine_active() {
    local dbus_inhibit
    dbus_inhibit=$(qdbus6 org.freedesktop.PowerManagement.Inhibit /org/freedesktop/PowerManagement/Inhibit HasInhibit 2>/dev/null || \
                   qdbus org.freedesktop.PowerManagement.Inhibit /org/freedesktop/PowerManagement/Inhibit HasInhibit 2>/dev/null)
    [[ "$dbus_inhibit" == "true" ]] && return 0
    if command -v pw-dump >/dev/null; then
        local VideoActive=$(pw-dump | grep -E "node.name.*(firefox|chrome|brave|vlc|mpv)" -A 15 | grep -c "running")
        [[ "$VideoActive" -gt 0 ]] && return 0
    fi
    return 1
}


# --- THE LAUNCHER ---
trigger_cmd() {
    local VALID_ARRAY=()
    local RANDOM_CONF="$WINEPREFIX_PATH/random_list.conf"
    local SINGLE_CONF="$WINEPREFIX_PATH/scrensaver.conf"

    # 1. Read configuration status to determine mode
    local CURRENT_SELECTION=""
    if [[ -f "$SINGLE_CONF" ]]; then
        CURRENT_SELECTION=$(cat "$SINGLE_CONF" 2>/dev/null)
    fi

    # CASE A: User selected a SPECIFIC individual screensaver
    if [[ -n "$CURRENT_SELECTION" && "$CURRENT_SELECTION" != "Random.scr" ]]; then
        if [[ -f "$SCR_DIR/$CURRENT_SELECTION" ]]; then
            VALID_ARRAY+=("$SCR_DIR/$CURRENT_SELECTION")
        fi
    fi

    # CASE B: User selected "Random" -> Read directly from guaranteed pool configuration
    if [[ "$CURRENT_SELECTION" == "Random.scr" ]]; then
        while IFS= read -r line; do
            local clean_line=$(echo "$line" | tr -d '\r')
            [[ -n "$clean_line" && -f "$SCR_DIR/$clean_line" ]] && VALID_ARRAY+=("$SCR_DIR/$clean_line")
        done < "$RANDOM_CONF"
    fi

    while true; do
        # Absolute guard check at loop entry
        if is_user_active_now || is_screen_locked; then break; fi

        # Switch logic with elegant, fixed duplication prevention
        local NEXT_INDEX=$(( RANDOM % ${#VALID_ARRAY[@]} ))
        if [ "$NEXT_INDEX" -eq "$CURRENT_INDEX" ]; then
            NEXT_INDEX=$(( (NEXT_INDEX + 1) % ${#VALID_ARRAY[@]} ))
        fi
        CURRENT_INDEX=$NEXT_INDEX
        local CURRENT_SCR="${VALID_ARRAY[$CURRENT_INDEX]}"

        # DEBUG HISTORY: Print starting screensaver to a new line
        echo -e "\n[$(date +%H:%M:%S)] LAUNCHING: $(basename "$CURRENT_SCR")"

        # Capture the REAL active Windows process PID currently running inside the server
        local REAL_OLD_PID
        REAL_OLD_PID=$(pgrep -f "\.scr" | head -n 1)

        # 1. START THE NEW SCREENSAVER INSIDE AN ISOLATED SUB-SHELL
        (wine "$CURRENT_SCR" /s >/dev/null 2>&1) &

        local ROT_RAW=$(get_cached_config "$WINEPREFIX_PATH/random_period.conf" "1")
        local ROT_TARGET_SECONDS=$(( ROT_RAW == 0 ? 30 : ROT_RAW ))

        # Convert targets and timers into discrete integer ticks (1 tick = 100ms)
        local ROT_TARGET_TICKS=$(( ROT_TARGET_SECONDS * 10 ))
        local ROT_TIMER_TICKS=0

        # 2. INITIAL SETUP LOOP: 3 seconds mapping delay (30 ticks at 100ms)
        # Smooth tracking from the very first frame without fractional arithmetic errors
        for ((setup_tick=0; setup_tick<30; setup_tick++)); do
            if [ ${#VALID_ARRAY[@]} -gt 1 ]; then
                local CURRENT_SEC=$(( ROT_TIMER_TICKS / 10 ))
                local REMAINING_SEC=$(( ROT_TARGET_SECONDS - CURRENT_SEC ))
                printf "\r[ROTATION] Switch in: %02d s (Current: %d s)...                      " "$REMAINING_SEC" "$CURRENT_SEC"
            fi
            sleep 0.1
            ((ROT_TIMER_TICKS++))
        done

        # 3. SURGICAL CLEANUP: Terminate old screensaver. Focus has been grabbed.
        if [[ -n "$REAL_OLD_PID" ]]; then
            kill -15 "$REAL_OLD_PID" 2>/dev/null
        fi

        # 4. CONTINUE REGULAR COUNTDOWN RUNTIME MONITORING (10Hz High-Frequency Loop)
        while true; do
            # Real visual check: if mouse moves, kill everything and exit to main loop
            if is_user_active_now || is_screen_locked; then
                wineserver -k 2>/dev/null
                break 2
            fi

            # ULTRA-FAST ANTI-HOLE CHECK: Detects silent crashes within 100ms max!
            if ! pgrep -f "\.scr" >/dev/null; then
                echo -e "\n[$(date +%H:%M:%S)] DETECTED HOLE: Screensaver exited silently. Recovering..."
                break
            fi

            if [ ${#VALID_ARRAY[@]} -gt 1 ]; then
                local CURRENT_SEC=$(( ROT_TIMER_TICKS / 10 ))
                local REMAINING_SEC=$(( ROT_TARGET_SECONDS - CURRENT_SEC ))
                printf "\r[ROTATION] Switch in: %02d s (Current: %d s)...                      " "$REMAINING_SEC" "$CURRENT_SEC"
            fi

            sleep 0.1
            ((ROT_TIMER_TICKS++))

            # Only target ticks expiration can break this inner loop to trigger a normal rotation
            if [ ${#VALID_ARRAY[@]} -gt 1 ] && [ "$ROT_TIMER_TICKS" -ge "$ROT_TARGET_TICKS" ]; then
                echo -e "\n[$(date +%H:%M:%S)] ROTATION: Timer expired, switching screensaver."
                break
            fi
        done
    done
}


# --- MAIN TICKER LOOP ---
APP_TIMER=0
echo "[$(date +%H:%M:%S)] MONITOR: Internal clock started."

while true; do
    SCR_TIMEOUT=$(get_cached_config "$WINEPREFIX_PATH/timeout.conf" "30")

    if is_user_active_now || is_screen_locked; then
        APP_TIMER=0
    fi

    if is_video_engine_active; then
        APP_TIMER=0
        printf "\r[STATUS] Video Active - Timer Reset.                      "
        sleep 1; continue
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
