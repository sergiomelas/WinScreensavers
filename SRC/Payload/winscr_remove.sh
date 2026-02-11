#!/bin/bash
# filename: winscr_remove.sh
# Purpose: Scan and safely uninstall selected Windows screensavers

echo " "
echo " ##################################################################"
echo " #                                                                #"
echo " #              Windows Screensaver Uninstaller                   #"
echo " #    Developed for X11/Wayland & KDE Plasma by sergio melas 2026 #"
echo " #                                                                #"
echo " ##################################################################"
echo " "

WINEPREFIX_PATH="$HOME/.winscr"
SCR_DIR="$WINEPREFIX_PATH/drive_c/windows/system32"
RANDOM_CONF="$WINEPREFIX_PATH/random_list.conf"

# --- HELPER: STANDARDIZED RELAUNCH ---
relaunch_menu() {
    rm -f "$WINEPREFIX_PATH/.running"
    if command -v winscreensaver >/dev/null; then
        winscreensaver &
    else
        bash "$WINEPREFIX_PATH/winscr_menu.sh" &
    fi
}

# 1. Scan for installed .scr files
readarray -t files < <(find "$SCR_DIR" -maxdepth 1 -iname "*.scr" -printf "%f\n" | sort 2>/dev/null)

if [[ ${#files[@]} -eq 0 ]]; then
    zenity --info --text="No screensavers found to remove." --width=300
    relaunch_menu
    exit 0
fi

# 2. Build Zenity Checklist (Hiding the .scr extension for the user)
ZEN_ARGS=()
for f in "${files[@]}"; do
    # Strip the .scr extension for display
    display_name="${f%.*}"
    ZEN_ARGS+=("FALSE" "$display_name")
done

# 3. Open the removal list
# We use the display names, then re-add .scr when processing deletion
SELECTED_NAMES=$(zenity --list --checklist \
    --title="Uninstall Screensavers" \
    --text="Select the screensavers you want to PERMANENTLY delete:" \
    --column="Remove" --column="Screensaver Name" \
    "${ZEN_ARGS[@]}" --separator=$'\n' --height=500 --width=400)

# 4. Process Deletion
if [[ -n "$SELECTED_NAMES" ]]; then
    # Count selections
    COUNT=$(echo "$SELECTED_NAMES" | wc -l)

    zenity --question --text="Are you sure you want to delete $COUNT screensavers?\nThis cannot be undone." --width=300
    if [[ $? -eq 0 ]]; then
        while IFS= read -r name; do
            [[ -z "$name" ]] && continue

            # Reconstruct the actual filename
            full_file="${name}.scr"

            echo "[DEBUG] Deleting: $full_file"
            rm -f "$SCR_DIR/$full_file"

            # Clean up the random selection list
            if [[ -f "$RANDOM_CONF" ]]; then
                sed -i "/^$full_file$/d" "$RANDOM_CONF"
            fi
        done <<< "$SELECTED_NAMES"

        zenity --info --text="Uninstallation complete." --timeout=2
    fi
fi

# 5. FINAL TERMINATION
relaunch_menu
exit 0
