#!/bin/bash
# filename: winscr_random_choose.sh

echo " "
echo " ##################################################################"
echo " #                                                                #"
echo " #                Choose Random scr list  Menu                    #"
echo " #   Developed for X11/Wayland & KDE Plasma by sergio melas 2026  #"
echo " #                                                                #"
echo " #                Emai: sergiomelas@gmail.com                     #"
echo " #                   Released under GPL V2.0                      #"
echo " #                                                                #"
echo " ##################################################################"
echo " "

# --- HELPER: STANDARDIZED RELAUNCH ---
relaunch_menu() {
    rm -f "$WINEPREFIX_PATH/.running"
    if command -v winscreensaver >/dev/null; then
        winscreensaver &
    else
        bash "$WINEPREFIX_PATH/winscr_menu.sh" &
    fi
}

# Generalizing the base path
WINEPREFIX_PATH="$HOME/.winscr"
SCR_DIR="$WINEPREFIX_PATH/drive_c/windows/system32"
RANDOM_CONF="$WINEPREFIX_PATH/random_list.conf"

# 1. Get the list of available screensavers
readarray -t array < <(find "$SCR_DIR" -maxdepth 1 -name "*.scr" -printf "%f\n" | sort 2>/dev/null)

if [[ ${#array[@]} -eq 0 ]]; then
    zenity --error --text="No Windows screensavers found in $SCR_DIR"
    relaunch_menu
    exit 1
fi

# 2. Build Zenity arguments and track current state
BEFORE_STATE=$(cat "$RANDOM_CONF" 2>/dev/null)
ZEN_ARGS=()

for scr in "${array[@]}"; do
    if [[ ! -f "$RANDOM_CONF" ]]; then
        STATE="TRUE"
    else
        if grep -Fxq "$scr" "$RANDOM_CONF" 2>/dev/null; then
            STATE="TRUE"
        else
            STATE="FALSE"
        fi
    fi
    ZEN_ARGS+=("$STATE" "$scr")
done

# 3. Open the Zenity selection menu
CHOICE=$(zenity --list --checklist \
    --title="Select Screensavers for Random Mode" \
    --text="Check the screensavers you want to include in the random cycle:" \
    --column="Include" --column="Screensaver Name" \
    "${ZEN_ARGS[@]}" --separator=$'\n' --height=500 --width=400)

# 4. Save selections with intelligent notification
if [ $? -eq 0 ]; then
    if [[ "$CHOICE" == "$BEFORE_STATE" ]]; then
        zenity --info --text="No changes made to the random list." --timeout=3
    else
        echo "$CHOICE" > "$RANDOM_CONF"
        COUNT=$(echo "$CHOICE" | grep -c ".scr")
        zenity --info --text="Random pool updated! $COUNT screensavers selected." --timeout=3
    fi
fi

# 5. RETURN TO MENU
relaunch_menu
exit 0
