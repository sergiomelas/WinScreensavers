#!/bin/bash
# filename: winscr_menu.sh
# Final version 2026 - Master Controller with Enhanced Integrity Audit

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
KSRT_EXE=$(command -v kstart6 || command -v kstart5 || command -v kstart)

# --- 1. LOCK LOGIC ---
if [ -e "$WINEPREFIX_PATH/.running" ]; then
    echo "Instance already running."
    exit 0
fi
mkdir -p "$WINEPREFIX_PATH"
touch "$WINEPREFIX_PATH/.running"

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

# Audit Part A: Check Directory Existence
if [ ! -d "$SCR_DIR" ]; then
    MISSING_LOCAL=true
else
    # Audit Part B: Check for .scr file presence
    SC_COUNT=$(find "$SCR_DIR" -maxdepth 1 -iname "*.scr" | wc -l)
    if [ "$SC_COUNT" -eq 0 ]; then
        MISSING_LOCAL=true
    fi
fi

# Audit Part C: Check for all 10 sub-scripts
if [ "$MISSING_LOCAL" = false ]; then
    for file in "${CHECK_FILES[@]}"; do
        if [ ! -f "$file" ]; then
            MISSING_LOCAL=true
            break
        fi
    done
fi

if [ "$MISSING_LOCAL" = true ]; then
    if zenity --question --title="WinScreensaver Setup" --text="Environment incomplete or no screensavers found. Finalise now?" --width=400; then
        if [ -f "/usr/share/winscreensaver/install.sh" ]; then
            SETUP_DIR="/usr/share/winscreensaver"
        else
            zenity --info --text="Select the WinScreensaver source folder (containing install.sh)."
            SETUP_DIR=$(zenity --file-selection --directory)
        fi

        if [ -z "$SETUP_DIR" ] || [ ! -f "$SETUP_DIR/install.sh" ]; then
           rm -f "$WINEPREFIX_PATH/.running"
           exit 1
        fi

        # Run the install.sh AS THE USER to avoid root ownership in home
        bash "$SETUP_DIR/install.sh" "$SETUP_DIR"
        rm -f "$WINEPREFIX_PATH/.running"
        exit 0
    else
        rm -f "$WINEPREFIX_PATH/.running"
        exit 0
    fi
fi

# --- 3. MENU ---
SCR_SAVER=$(cat "$WINEPREFIX_PATH/scrensaver.conf" 2>/dev/null || echo "Random.scr")
MENU_ITEMS=( FALSE "Choose Screensaver" )
[[ "$SCR_SAVER" == "Random.scr" ]] && MENU_ITEMS+=( FALSE "Choose Random List" FALSE "Random Period" ) || MENU_ITEMS+=( FALSE "Test Screensaver" )

MENU_ITEMS+=(
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

# --- 5. THE HANDOVER ---
rm -f "$WINEPREFIX_PATH/.running"
if [ -n "$KSRT_EXE" ]; then
    $KSRT_EXE bash "$WINEPREFIX_PATH/$ACTION" &
else
    bash "$WINEPREFIX_PATH/$ACTION" &
fi
exit 0
