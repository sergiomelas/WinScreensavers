#!/bin/bash
# filename: winscr_menu.sh
# Final version 2026 - Master Controller with PID-Lock & Universal Handover

echo " "
echo " ##################################################################"
echo " #                                                                #"
echo " #                        Choose Option Menu                      #"
echo " #    Developed for X11/Wayland & KDE Plasma by sergio melas 2026 #"
echo " #                                                                #"
echo " #                Email: sergiomelas@gmail.com                    #"
echo " #                   Released under GPL V2.0                      #"
echo " #                                                                #"
echo " ##################################################################"
echo " "

WINEPREFIX_PATH="$HOME/.winscr"
SCR_DIR="$WINEPREFIX_PATH/drive_c/windows/system32"

# --- 1. ROBUST PID-LOCK LOGIC ---
if [ -f "$WINEPREFIX_PATH/.running" ]; then
    OLD_PID=$(cat "$WINEPREFIX_PATH/.running")
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        echo "Instance already running with PID $OLD_PID. Exiting."
        exit 0
    else
        rm -f "$WINEPREFIX_PATH/.running"
    fi
fi
echo $$ > "$WINEPREFIX_PATH/.running"

# --- 2. SYMMETRIC INTEGRITY AUDIT ---
CHECK_FILES=(
    "$WINEPREFIX_PATH/winscr_screensaver.sh"
    "$WINEPREFIX_PATH/winscr_choose.sh"
    "$WINEPREFIX_PATH/winscr_configure.sh"
    "$WINEPREFIX_PATH/winscr_lock.sh"
    "$WINEPREFIX_PATH/winscr_random_choose.sh"
    "$WINEPREFIX_PATH/winscr_random_period.sh"
    "$WINEPREFIX_PATH/winscr_test.sh"
    "$WINEPREFIX_PATH/winscr_timeout.sh"
    "$WINEPREFIX_PATH/winscr_about.sh"
    "$WINEPREFIX_PATH/winscr_import.sh"
)

MISSING_LOCAL=false
if [ ! -d "$SCR_DIR" ] || [ $(find "$SCR_DIR" -maxdepth 1 -iname "*.scr" | wc -l) -eq 0 ]; then
    MISSING_LOCAL=true
fi

if [ "$MISSING_LOCAL" = false ]; then
    for file in "${CHECK_FILES[@]}"; do
        if [ ! -f "$file" ]; then
            MISSING_LOCAL=true
            break
        fi
    done
fi

if [ "$MISSING_LOCAL" = true ]; then
    if zenity --question --title="Setup" --text="Environment incomplete. Repair now?"; then
        rm -f "$WINEPREFIX_PATH/.running"
        bash /usr/share/winscreensaver/install.sh
        exit 0
    fi
    rm -f "$WINEPREFIX_PATH/.running"
    exit 0
fi

# --- 3. MENU UI ---
SCR_SAVER=$(cat "$WINEPREFIX_PATH/scrensaver.conf" 2>/dev/null || echo "Random.scr")
MENU_ITEMS=( FALSE "Choose Screensaver" )
[[ "$SCR_SAVER" == "Random.scr" ]] && MENU_ITEMS+=( FALSE "Choose Random List" FALSE "Random Period" ) || MENU_ITEMS+=( FALSE "Test Screensaver" )
MENU_ITEMS+=( FALSE "Configure Screensaver" FALSE "Lock Screen" FALSE "Timeout" FALSE "Import Screensavers (.scr)" FALSE "About" )

Choice=$(zenity --list --radiolist --title="WinScreensaver" --text "Active: ${SCR_SAVER%.scr}" --column "Pick" --column "Option" "${MENU_ITEMS[@]}" --height=500 --width=420)

if [ -z "$Choice" ]; then
    rm -f "$WINEPREFIX_PATH/.running"
    exit 0
fi

# --- 4. ACTION DISPATCHER ---
case $Choice in
    'Choose Screensaver')             ACTION="winscr_choose.sh" ;;
    'Choose Random List')             ACTION="winscr_random_choose.sh" ;;
    'Random Period')                  ACTION="winscr_random_period.sh" ;;
    'Test Screensaver')                ACTION="winscr_test.sh" ;;
    'Configure Screensaver')           ACTION="winscr_configure.sh" ;;
    'Timeout')                        ACTION="winscr_timeout.sh" ;;
    'Lock Screen')                    ACTION="winscr_lock.sh" ;;
    'About')                          ACTION="winscr_about.sh" ;;
    'Import Screensavers (.scr)')     ACTION="winscr_import.sh" ;;
esac

# --- 5. UNIVERSAL HANDOVER ---
rm -f "$WINEPREFIX_PATH/.running"
winscreensaver &
exit 0
