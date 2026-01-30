#!/bin/bash
# filename: winscr_choose.sh

echo " "
echo " ##################################################################"
echo " #                                                                #"
echo " #                        Choose screensaver                      #"
echo " #    Developed for X11/Wayland & KDE Plasma by sergio melas 2026 #"
echo " #                                                                #"
echo " #                Emai: sergiomelas@gmail.com                     #"
echo " #                   Released under GPL V2.0                      #"
echo " #                                                                #"
echo " ##################################################################"
echo " "

# --- PATHS ---
WINEPREFIX_PATH="$HOME/.winscr"
WINE_DIR="$WINEPREFIX_PATH/drive_c/windows/system32"

# --- 1. READ CURRENT SELECTION ---
CURRENT_SCR=$(cat "$WINEPREFIX_PATH/scrensaver.conf" 2>/dev/null || echo "Random.scr")

# --- 2. GET LOCAL .SCR FILES ---
if [ -d "$WINE_DIR" ]; then
    readarray -t file_list < <(cd "$WINE_DIR" && ls *.scr 2>/dev/null)
else
    file_list=()
fi

# --- 3. BUILD ZENITY LIST ---
ZEN_LIST=()
[[ "$CURRENT_SCR" == "Random.scr" ]] && ZEN_LIST+=("TRUE" "Random") || ZEN_LIST+=("FALSE" "Random")

for file in "${file_list[@]}"; do
    NAME="${file%.*}"
    [[ "$NAME" == "Random" ]] && continue

    if [[ "$file" == "$CURRENT_SCR" ]]; then
        ZEN_LIST+=("TRUE" "$NAME")
    else
        ZEN_LIST+=("FALSE" "$NAME")
    fi
done

# --- 4. LAUNCH CHOOSER ---
SCR=$(zenity --list --radiolist --title "WinScreensaver Chooser" \
    --text "Pick a screensaver for $USER" \
    --column "Pick" --column "Screensavers" \
    "${ZEN_LIST[@]}" --height=500 --width=350)

# --- 5. SAVE SELECTION ---
if [ -n "$SCR" ]; then
    [[ "$SCR" == "Random" ]] && FINAL_VAL="Random.scr" || FINAL_VAL="$SCR.scr"
    echo "$FINAL_VAL" > "$WINEPREFIX_PATH/scrensaver.conf"
fi

# --- 6. UNLOCK & RELAUNCH MENU (Standardized Fixed Block) ---
rm -f "$WINEPREFIX_PATH/.running"

KSRT_EXE=$(command -v kstart6 || command -v kstart5 || command -v kstart)

if command -v winscreensaver >/dev/null; then
    LAUNCH_CMD="winscreensaver"
else
    LAUNCH_CMD="bash $WINEPREFIX_PATH/winscr_menu.sh"
fi

if [ -n "$KSRT_EXE" ]; then
    $KSRT_EXE $LAUNCH_CMD &
else
    $LAUNCH_CMD &
fi

exit 0
