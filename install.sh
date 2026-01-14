#!/bin/bash
# filename: install.sh

echo " "
echo " ##################################################################"
echo " #                       Install screensaver                      #"
echo " #       Developed for X11 & KDE Plasma by sergio melas 2026      #"
echo " ##################################################################"

[[ "$XDG_SESSION_TYPE" != "x11" ]] && exit 0

sudo apt-get update && sudo apt-get install -y libnotify-bin xprintidle xdotool zenity wine wine32 x11-xserver-utils pgrep

INSTALL_DIR="/home/$USER/.winscr"
rm -rf "$INSTALL_DIR"
WINEPREFIX="$INSTALL_DIR" wineboot --init

cp ./Payload/*.sh "$INSTALL_DIR/"
cp ./Payload/winscr_icon.png "$INSTALL_DIR/"
cp ./Payload/*.conf "$INSTALL_DIR/"

cp ./'Scr files'/*.scr "$INSTALL_DIR/drive_c/windows/system32/"
chmod +x "$INSTALL_DIR"/*.sh

echo "Random.scr" > "$INSTALL_DIR/scrensaver.conf"
echo "300" > "$INSTALL_DIR/timeout.conf"
echo "0" > "$INSTALL_DIR/lockscreen.conf"
echo "60" > "$INSTALL_DIR/random_period.conf"

cat <<EOF > "$HOME/.local/share/applications/WinScreensaver.desktop"
[Desktop Entry]
Name=WinScreensaver
Exec=$INSTALL_DIR/winscr_menu.sh
Icon=$INSTALL_DIR/winscr_icon.png
Type=Application
EOF

cat <<EOF > "$HOME/.config/autostart/winscr_service.desktop"
[Desktop Entry]
Name=WinScreensaver Service
Exec=$INSTALL_DIR/winscr_screensaver.sh
Type=Application
X-KDE-AutostartScript=true
EOF

kstart bash "$INSTALL_DIR/winscr_choose.sh" &
