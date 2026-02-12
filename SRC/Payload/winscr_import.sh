#!/bin/bash
# filename: winscr_import.sh
# Final version 2026 - Smart Discovery + Selective Extension Correction (Preserves Name Case)

echo " "
echo " ##################################################################"
echo " #                                                                #"
echo " #                 Windows screensavers importer                  #"
echo " #    Developed for X11/Wayland & KDE Plasma by sergio melas 2026 #"
echo " #                                                                #"
echo " ##################################################################"
echo " "

WINEPREFIX_PATH="$HOME/.winscr"
SCR_DEST="$WINEPREFIX_PATH/drive_c/windows/system32"

# --- HELPER: STANDARDIZED RELAUNCH ---
relaunch_menu() {
    rm -f "$WINEPREFIX_PATH/.running"
    if command -v winscreensaver >/dev/null; then
        winscreensaver &
    else
        bash "$WINEPREFIX_PATH/winscr_menu.sh" &
    fi
}

# --- SMART AUTO-DISCOVERY ---
echo "Scanning home for additional screensavers..."
BEST_FOLDER=""
MAX_COUNT=0

while read -r count_folder; do
    count=$(echo "$count_folder" | awk '{print $1}')
    folder=$(echo "$count_folder" | cut -d' ' -f2-)
    if [ "$count" -gt "$MAX_COUNT" ]; then
        MAX_COUNT=$count
        BEST_FOLDER="$folder/"
    fi
done < <(find "$HOME" -maxdepth 5 -path "$WINEPREFIX_PATH" -prune -o -iname "*.scr" -exec dirname {} + 2>/dev/null | sort | uniq -c | sort -nr)

# --- DYNAMIC WIDTH ---
PATH_LEN=${#BEST_FOLDER}
CALC_WIDTH=$(( PATH_LEN * 9 ))
[ "$CALC_WIDTH" -lt 600 ] && CALC_WIDTH=600
[ "$CALC_WIDTH" -gt 1200 ] && CALC_WIDTH=1200

# --- PROMPT USER ---
if [ -n "$BEST_FOLDER" ] && [ -d "$BEST_FOLDER" ]; then
    msg="Auto-detected $MAX_COUNT screensavers in: $BEST_FOLDER. Import these Selecting Files (OK) or Browse or cancel?"
    SCR_SOURCE=$(zenity --file-selection --directory --filename="$BEST_FOLDER" --title="$msg" --width=$CALC_WIDTH)
else
    SCR_SOURCE=$(zenity --file-selection --directory --title="Select folder to import .scr files from" --width=600)
fi

# --- MAIN LOGIC BLOCK ---
if [ -n "$SCR_SOURCE" ]; then
    echo "[INFO] Analyzing source: $SCR_SOURCE"

    # Check for Assets (DLLs/Data)
    CRITICAL_ASSETS=$(find "$SCR_SOURCE" -maxdepth 1 -type f -not -iname "*.scr" -not -iname "*.txt" | wc -l)

    if [ "$CRITICAL_ASSETS" -gt 0 ]; then
        echo "[DEBUG] Assets found. Opening Checklist."
        CHECKLIST_ARGS=()
        MAX_FILE_LEN=0
        while IFS= read -r -d '' file; do
            CHECKLIST_ARGS+=("TRUE" "$file")
            [ ${#file} -gt "$MAX_FILE_LEN" ] && MAX_FILE_LEN=${#file}
        done < <(find "$SCR_SOURCE" -maxdepth 1 -type f -not -path "$SCR_SOURCE" -printf "%f\0" | sort -z)

        LIST_WIDTH=$(( MAX_FILE_LEN * 10 + 200 ))
        [ "$LIST_WIDTH" -lt 600 ] && LIST_WIDTH=600
        [ "$LIST_WIDTH" -gt 1100 ] && LIST_WIDTH=1100

        CHOICE=$(zenity --list --title="Selective Import" --width=$LIST_WIDTH --height=450 \
            --checklist --text="Select files to import from:\n$SCR_SOURCE" \
            --column="Pick" --column="File Name" "${CHECKLIST_ARGS[@]}" --separator="|")

        # Handle Checklist Result
        if [ $? -eq 0 ] && [ -n "$CHOICE" ]; then
            IFS="|" read -ra SELECTED_FILES <<< "$CHOICE"
            for filename in "${SELECTED_FILES[@]}"; do
                # EXTENSION-ONLY NORMALIZATION: Keep name, lowercase extension
                ext="${filename##*.}"
                base="${filename%.*}"
                target_name="${base}.${ext,,}"

                cp -vn "$SCR_SOURCE/$filename" "$SCR_DEST/$target_name"
                echo "  -> Imported: $filename as $target_name"
            done
            zenity --info --text="Imported ${#SELECTED_FILES[@]} items (Fixed .scr extension)." --timeout=2
        fi
    else
        # Surgical Import (Only .scr)
        echo "[INFO] Clean folder. Fixing extensions while preserving names."
        SCR_COUNT=0

        while IFS= read -r -d '' full_path; do
            filename=$(basename "$full_path")

            # EXTENSION-ONLY NORMALIZATION
            ext="${filename##*.}"
            base="${filename%.*}"
            target_name="${base}.${ext,,}"

            cp -vn "$full_path" "$SCR_DEST/$target_name"
            ((SCR_COUNT++))
            echo "  -> Normalized: $filename -> $target_name"
        done < <(find "$SCR_SOURCE" -maxdepth 1 -iname "*.scr" -print0)

        if [ "$SCR_COUNT" -gt 0 ]; then
            zenity --info --text="Imported $SCR_COUNT screensaver(s) with fixed extensions." --timeout=2
        else
            zenity --error --text="No .scr files found in source."
        fi
    fi
fi

# 5. FINAL TERMINATION
relaunch_menu
exit 0
