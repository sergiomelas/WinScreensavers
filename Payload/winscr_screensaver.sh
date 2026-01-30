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
    while IFS= read -r -d '' file; do
        VALID_ARRAY+=("$file")
    done < <(find "$SCR_DIR" -maxdepth 1 -iname "*.scr" -print0 2>/dev/null)

    [[ ${#VALID_ARRAY[@]} -eq 0 ]] && { echo "[$(date +%H:%M:%S)] No files found!"; return; }

    local OLD_PID=""
    while true; do
        if is_user_active_now || is_screen_locked; then break; fi

        local CURRENT_SCR="${VALID_ARRAY[$(( RANDOM % ${#VALID_ARRAY[@]} ))]}"
        echo -e "\n[$(date +%H:%M:%S)] LAUNCHING: $(basename "$CURRENT_SCR")"

        wine "$CURRENT_SCR" /s >/dev/null 2>&1 &
        local NEW_PID=$!

        sleep 2
        [[ -n "$OLD_PID" ]] && kill -9 "$OLD_PID" 2>/dev/null

        local ROT_TIMER=0
        local ROT_RAW=$(get_cached_config "$WINEPREFIX_PATH/random_period.conf" "1")
        local ROT_TARGET=$(( ROT_RAW == 0 ? 30 : ROT_RAW * 60 ))

        while true; do
            sleep 1
            if is_user_active_now || is_screen_locked; then
                echo -e "\n[$(date +%H:%M:%S)] STOP: External activity detected."
                kill -9 "$NEW_PID" 2>/dev/null
                break 2
            fi

            if ! kill -0 "$NEW_PID" 2>/dev/null; then
                echo -e "\n[$(date +%H:%M:%S)] STOP: Screensaver exited (Internal activity)."
                break 2
            fi

            ((ROT_TIMER++))
            printf "\r[ROTATION] Switch in: %02d s...                     " "$(( ROT_TARGET - ROT_TIMER ))"

            if [ ${#VALID_ARRAY[@]} -gt 1 ] && [ "$ROT_TIMER" -ge "$ROT_TARGET" ]; then
                echo -e "\n[$(date +%H:%M:%S)] ROTATION: Switching screensaver."
                OLD_PID="$NEW_PID"
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
