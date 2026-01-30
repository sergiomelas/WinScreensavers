#!/bin/bash
# filename: install.sh
# Purpose: Final version with hardcoded absolute paths and no 'bash' prefix

echo " "
echo " ##################################################################"
echo " #                                                                #"
echo " #                Windows screensavers launcher                   #"
echo " #    Developed for X11/Wayland & KDE Plasma by sergio melas 2026 #"
echo " #                                                                #"
echo " #                Email: sergiomelas@gmail.com                    #"
echo " #                   Released under GPL V2.0                      #"
echo " #                                                                #"
echo " ##################################################################"
echo " "

# Get the actual home directory path as a string
REAL_HOME=$(eval echo ~$USER)
WINEPREFIX_PATH="$REAL_HOME/.winscr"
SYS_PATH="/usr/share/winscreensaver/Payload"
AUTOSTART_DIR="$REAL_HOME/.config/autostart"

# 1. Ensure local directories exist
mkdir -p "$WINEPREFIX_PATH/drive_c/windows/system32"
mkdir -p "$AUTOSTART_DIR"

# 2. Sync scripts
cp "$SYS_PATH"/*.sh "$WINEPREFIX_PATH/"
cp "$SYS_PATH"/*.conf "$WINEPREFIX_PATH/"
chmod +x "$WINEPREFIX_PATH"/*.sh

# 3. Create the Direct Autostart Entry
# Notice: No 'bash' prefix and the path is expanded now!
cat <<EOF > "$AUTOSTART_DIR/winscreensaver.desktop"
[Desktop Entry]
Type=Application
Exec=$WINEPREFIX_PATH/winscr_screensaver.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=WinScreensaver Service
Comment=Starts the screensaver monitor at login
EOF

# 4. Trigger the service immediately for this session
if ! pgrep -f "winscr_screensaver.sh" > /dev/null; then
    nohup "$WINEPREFIX_PATH/winscr_screensaver.sh" > /dev/null 2>&1 &
    disown
fi

zenity --info --text="Installation complete. Direct path set to: $WINEPREFIX_PATH/winscr_screensaver.sh" --title="Success"
