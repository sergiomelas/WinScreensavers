#!/bin/bash
# filename: winscr_menu.sh
# Final version 2026 - Master Controller with Strict Integrity Audit

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

# Move to the local directory
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

# --- 2. MASTER INTEGRITY AUDIT (Strict No-Wildcard Check) ---
MISSING_CRAP=0

# A. CHECK DIRECTORIES
CHECK_DIRS=("dosdevices" "drive_c")

# B. CHECK CONFIGURATION & REGISTRY FILES
CHECK_CONFIGS=(
    "random_period.conf" "timeout.conf" "scrensaver.conf"
    "lockscreen.conf" "userdef.reg" "system.reg" "user.reg"
)

# C. CHECK LOGIC SCRIPTS
CHECK_SCRIPTS=(
    "winscr_about.sh" "winscr_import.sh" "winscr_random_choose.sh" "winscr_test.sh"
    "winscr_choose.sh" "winscr_lock.sh" "winscr_random_period.sh" "winscr_timeout.sh"
    "winscr_configure.sh" "winscr_menu.sh" "winscr_screensaver.sh"
)

# Execute the Audit
for dir in "${CHECK_DIRS[@]}"; do
    if [ ! -d "$WINEPREFIX_PATH/$dir" ]; then MISSING_CRAP=1; break; fi
done

if [ "$MISSING_CRAP" -eq 0 ]; then
    for cfg in "${CHECK_CONFIGS[@]}"; do
        if [ ! -f "$WINEPREFIX_PATH/$cfg" ]; then MISSING_CRAP=1; break; fi
    done
fi

if [ "$MISSING_CRAP" -eq 0 ]; then
    for sh in "${CHECK_SCRIPTS[@]}"; do
        if [ ! -f "$WINEPREFIX_PATH/$sh" ]; then MISSING_CRAP=1; break; fi
    done
fi

# Check for .scr presence
SCR_COUNT=$(find "$SCR_DIR" -maxdepth 1 -iname "*.scr" 2>/dev/null | wc -l)
if [ "$SCR_COUNT" -eq 0 ]; then MISSING_CRAP=1; fi

# Rebuild Trigger
if [ "$MISSING_CRAP" -eq 1 ]; then
    if zenity --question --title="Integrity Failure" \
       --text="Missing registry files, scripts, or screensavers detected.\n\nRebuild environment now?" --width=400; then
        rm -f ".running"
        bash /usr/share/winscreensaver/install.sh
        exit 0
    else
        rm -f ".running"
        exit 1
    fi
fi

# --- 3. MENU UI ---
SCR_SAVER=$(cat "scrensaver.conf" 2>/dev/null || echo "Random.scr")
MENU_ITEMS=( FALSE "Choose Screensaver" )

if [[ "$SCR_SAVER" == "Random.scr" ]]; then
    TEST_LABEL="Test pool Screensavers"
    MENU_ITEMS+=( FALSE "Choose Random List" FALSE "Random Period" )
else
    TEST_LABEL="Test Screensaver"
fi

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
    zenity --error --text="Script missing: $ACTION"
fi
exit 0
