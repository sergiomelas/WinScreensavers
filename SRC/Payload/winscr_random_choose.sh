#!/bin/bash
# filename: winscr_random_choose.sh

echo " "
echo " ##################################################################"
echo " #                                                                #"
echo " #                Choose Random scr list  Menu                    #"
echo " #    Developed for X11/Wayland & KDE Plasma by sergio melas 2026 #"
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

# 2. Build Zenity arguments (Displaying without .scr)
BEFORE_STATE=$(cat "$RANDOM_CONF" 2>/dev/null)
ZEN_ARGS=()

for scr in "${array[@]}"; do
    # Remove .scr for display
    display_name="${scr%.*}"

    if [[ ! -f "$RANDOM_CONF" ]]; then
        STATE="TRUE"
    else
        # Still check the config against the FULL filename
        if grep -Fxq "$scr" "$RANDOM_CONF" 2>/dev/null; then
            STATE="TRUE"
        else
            # If config exists but file isn't inside, default to FALSE
            STATE="FALSE"
        fi
    fi
    ZEN_ARGS+=("$STATE" "$display_name")
done

# 3 & 4. LOOP UNTIL VALID SELECTION (Minimum 2 screensavers required)
while true; do
    # Open the Zenity selection menu
    CHOICE_NAMES=$(zenity --list --checklist \
        --title="Select Screensavers for Random Mode" \
        --text="Check the screensavers you want to include in the random cycle (Minimum 2 required):" \
        --column="Include" --column="Screensaver Name" \
        "${ZEN_ARGS[@]}" --separator=$'\n' --height=500 --width=400)

    # If user presses "Cancel" or closes the window, exit loop without changing configuration
    if [ $? -ne 0 ]; then
        zenity --info --text="Operation cancelled. No changes made." --timeout=3
        break
    fi

    # Count how many screensavers were selected
    if [ -n "$CHOICE_NAMES" ]; then
        COUNT=$(echo "$CHOICE_NAMES" | wc -l)
    else
        COUNT=0
    fi

    # Sbarramento: Controlla se sono almeno 2
    if [ "$COUNT" -lt 2 ]; then
        zenity --error --text="Error: You must select AT LEAST 2 screensavers to maintain a functional random pool!\n\nCurrent selection: $COUNT"

        # Rigenera gli argomenti di Zenity basandoti sulla selezione appena fallita dell'utente
        # In questo modo non perde i checkmark che aveva appena messo!
        ZEN_ARGS=()
        for scr in "${array[@]}"; do
            display_name="${scr%.*}"
            if echo "$CHOICE_NAMES" | grep -Fxq "$display_name" 2>/dev/null; then
                ZEN_ARGS+=("TRUE" "$display_name")
            else
                ZEN_ARGS+=("FALSE" "$display_name")
            fi
        done
        continue # Riavvia il ciclo while e riapre Zenity
    fi

    # Se arriviamo qui, la selezione è valida (>= 2). Prepariamo il salvataggio.
    CHOICE_FULL=$(echo "$CHOICE_NAMES" | sed 's/$/.scr/')

    if [[ "$CHOICE_FULL" == "$BEFORE_STATE" ]]; then
        zenity --info --text="No changes made to the random list." --timeout=3
    else
        echo "$CHOICE_FULL" > "$RANDOM_CONF"
        zenity --info --text="Random pool updated! $COUNT screensavers selected." --timeout=3
    fi
    break # Selezione riuscita, usciamo dal ciclo while
done

# 5. RETURN TO MENU
relaunch_menu
exit 0
