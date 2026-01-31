#!/bin/bash
# filename: winscr_menu.sh
# Final version 2026 - Master Controller with Dynamic Test Labels

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

# Move to the local directory so scripts find each other
cd "$WINEPREFIX_PATH" || exit 1

# --- 1. ROBUST PID-LOCK LOGIC ---
if [ -f ".running" ]; then
    OLD_PID=$(cat ".running")
    if ! ps -p "$OLD_PID" > /dev/null 2>&1; then
        rm -f ".running"
    else
        exit 0
    fi
fi
echo $$ > ".running"

# --- 2. INTEGRITY AUDIT ---
if [ ! -d "$SCR_DIR" ] || [ $(find "$SCR_DIR" -maxdepth 1 -iname "*.scr" 2>/dev/null | wc -l) -eq 0 ]; then
    if zenity --question --title="Setup" --text="Environment incomplete. Repair now?"; then
        rm -f ".running"
        bash /usr/share/winscreensaver/install.sh
        exit 0
    fi
    rm -f ".running"
    exit 0
fi

# --- 3. MENU UI (Restored with Dynamic Labels) ---
SCR_SAVER=$(cat "scrensaver.conf" 2>/dev/null || echo "Random.scr")

# Build the menu items dynamically
MENU_ITEMS=( FALSE "Choose Screensaver" )

if [[ "$SCR_SAVER" == "Random.scr" ]]; then
    # Mode: Random
    TEST_LABEL="Test pool Screensavers"
    MENU_ITEMS+=( FALSE "Choose Random List" FALSE "Random Period" )
else
    # Mode: Single
    TEST_LABEL="Test Screensaver"
fi

# Add the Test option (Always visible) and the rest of the fixed menu
MENU_ITEMS+=(
    FALSE "$TEST_LABEL"
    FALSE "Configure Screensaver"
    FALSE "Lock Screen"
    FALSE "Timeout"
    FALSE "Import Screensavers (.scr)"
    FALSE "About"
)

Choice=$(zenity --list --radiolist --title="WinScreensaver" \
    --text "Active: ${SCR_SAVER%.scr}" \
    --column "Pick" --column "Option" \
    "${MENU_ITEMS[@]}" --height=500 --width=420)

if [ -z "$Choice" ]; then
    rm -f ".running"
    exit 0
fi

# --- 4. ACTION DISPATCHER ---
case $Choice in
    'Choose Screensaver')             ACTION="winscr_choose.sh" ;;
    'Choose Random List')             ACTION="winscr_random_choose.sh" ;;
    'Random Period')                  ACTION="winscr_random_period.sh" ;;
    'Test Screensaver'|'Test pool Screensavers') ACTION="winscr_test.sh" ;;
    'Configure Screensaver')           ACTION="winscr_configure.sh" ;;
    'Timeout')                        ACTION="winscr_timeout.sh" ;;
    'Lock Screen')                    ACTION="winscr_lock.sh" ;;
    'About')                          ACTION="winscr_about.sh" ;;
    'Import Screensavers (.scr)')     ACTION="winscr_import.sh" ;;
esac

# --- 5. UNIVERSAL HANDOVER ---
rm -f ".running"

if [ -f "$WINEPREFIX_PATH/$ACTION" ]; then
    bash "$WINEPREFIX_PATH/$ACTION" &
else
    zenity --error --text="Script not found: $WINEPREFIX_PATH/$ACTION"
fi

exit 0
