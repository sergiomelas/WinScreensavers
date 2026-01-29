#!/bin/bash
# filename: winscr_timeout.sh

echo " "
echo " ##################################################################"
echo " #                        Choose Timeout                          #"
echo " #       Developed for X11 & KDE Plasma by sergio melas 2026      #"
echo " #                                                                #"
echo " #                Emai: sergiomelas@gmail.com                     #"
echo " #                   Released under GPL V2.0                      #"
echo " #                                                                #"
echo " ##################################################################"



WINEPREFIX_PATH="/home/$USER/.winscr"
CURRENT_TIM=$(cat "$WINEPREFIX_PATH/timeout.conf" 2>/dev/null || echo "300")

OPTIONS=(
    "30 seconds" 30
    "2 minutes"  120
    "5 minutes"  300
    "10 minutes" 600
    "15 minutes" 900
    "30 minutes" 1800
    "1 hour"     3600
    "Disabled"   1000000000
)

ZEN_ARGS=()
for ((i=0; i<${#OPTIONS[@]}; i+=2)); do
    STATE="FALSE"
    [ "${OPTIONS[i+1]}" == "$CURRENT_TIM" ] && STATE="TRUE"
    ZEN_ARGS+=("$STATE" "${OPTIONS[i]}")
done

PICK=$(zenity --list --radiolist --title="Screensaver Timeout" --column "Pick" --column "Answer" "${ZEN_ARGS[@]}" --height=400)

if [ -n "$PICK" ]; then
    NEW_TIMEOUT=0
    for ((i=0; i<${#OPTIONS[@]}; i+=2)); do
        if [ "${OPTIONS[i]}" == "$PICK" ]; then
            NEW_TIMEOUT="${OPTIONS[i+1]}"
            echo "$NEW_TIMEOUT" > "$WINEPREFIX_PATH/timeout.conf"
            break
        fi
    done

    # --- 2026 CONFLICT DETECTION (KDE 6 FIX) ---

    # 1. Read KDE Screen Lock Timeout (Seconds)
    # kscreenlockerrc stores this in seconds. If 0 or missing, it is disabled.
    KDE_LOCK=$(kreadconfig6 --file kscreenlockerrc --group "Daemon" --key "Timeout" --default 0)
    KDE_LOCK_ENABLED=$(kreadconfig6 --file kscreenlockerrc --group "Daemon" --key "Autolock" --default "false")

    # 2. Read KDE Screen Energy Saving (DPMS)
    # In Plasma 6, idleTime is stored in powermanagementprofilesrc under [AC][DPMSControl]
    # Units are typically seconds.
    KDE_BLANK=$(kreadconfig6 --file powermanagementprofilesrc --group "AC" --group "DPMSControl" --key "idleTime" --default 0)

    # Validation: Treat missing/invalid values as 0 (not a conflict)
    [[ ! "$KDE_LOCK" =~ ^[0-9]+$ ]] && KDE_LOCK=0
    [[ ! "$KDE_BLANK" =~ ^[0-9]+$ ]] && KDE_BLANK=0

    CONFLICT=false
    MSG="<b>WARNING: Conflict Detected!</b>\n\nYour screensaver is set to <b>$PICK</b> ($NEW_TIMEOUT s),\nbut system settings will interfere:\n"

    if [ "$NEW_TIMEOUT" -lt 1000000000 ]; then
        # Check if Monitor turns off BEFORE screensaver starts
        if [ "$KDE_BLANK" -gt 0 ] && [ "$NEW_TIMEOUT" -ge "$KDE_BLANK" ]; then
            MSG+="\n- <b>Screen Energy Saving:</b> Happens at ${KDE_BLANK}s. (Monitor turns off first)"
            CONFLICT=true
        fi
        # Check if System Lock screen blocks the screensaver
        if [[ "$KDE_LOCK_ENABLED" == "true" ]] && [ "$KDE_LOCK" -gt 0 ] && [ "$NEW_TIMEOUT" -ge "$KDE_LOCK" ]; then
            MSG+="\n- <b>Screen Lock:</b> Happens at ${KDE_LOCK}s. (Lock screen takes priority)"
            CONFLICT=true
        fi
    fi

    if [ "$CONFLICT" = true ]; then
        MSG+="\n\n<b>To fix this:</b>\n1. Go to <i>System Settings > Power Management</i>.\n2. Set 'Screen Energy Saving' and 'Screen Lock' to values <b>HIGHER</b> than $NEW_TIMEOUT s."
        zenity --warning --title="Timeout Conflict" --text="$MSG" --width=450 --no-wrap
    fi
fi

rm -f "$WINEPREFIX_PATH"/.running
kstart bash "$WINEPREFIX_PATH/winscr_menu.sh" &
