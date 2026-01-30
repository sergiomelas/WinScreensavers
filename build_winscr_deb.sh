#!/bin/bash
# filename: build_winscr_deb.sh
# Final version 2026 - Global Icon & Menu Registration

echo " "
echo " ##################################################################"
echo " #                                                                #"
echo " #                      Debian Builder                            #"
echo " #    Developed for X11/Wayland & KDE Plasma by sergio melas 2026 #"
echo " #                                                                #"
echo " #                Email: sergiomelas@gmail.com                    #"
echo " #                   Released under GPL V2.0                      #"
echo " #                                                                #"
echo " ##################################################################"
echo " "

PACKAGE_NAME="sml-screensaver"
VERSION="1.0-2026"
BUILD_ROOT="./${PACKAGE_NAME}_${VERSION}"

# Clean old builds
rm -rf "$BUILD_ROOT"

# Create System Structure
mkdir -p "$BUILD_ROOT/DEBIAN"
mkdir -p "$BUILD_ROOT/usr/share/winscreensaver/Payload"
mkdir -p "$BUILD_ROOT/usr/bin"
mkdir -p "$BUILD_ROOT/usr/share/applications"
mkdir -p "$BUILD_ROOT/usr/share/pixmaps"

# 1. THE CONTROL FILE
cat <<EOF > "$BUILD_ROOT/DEBIAN/control"
Package: $PACKAGE_NAME
Version: $VERSION
Section: utils
Priority: optional
Architecture: all
Depends: wine, wine32, xprintidle, x11-utils, procps, swayidle, zenity, xdotool, qdbus-qt5 | qdbus-qt6, libkf6config-bin | libkf5config-bin, kde-cli-tools, desktop-file-utils
Maintainer: Sergio Melas <sergiomelas@gmail.com>
Description: SML-Screensaver: Windows .scr manager for KDE Plasma.
 Includes global menu icon and user-space environment setup.
EOF

# 2. POST-INSTALL SCRIPT
cat <<EOF > "$BUILD_ROOT/DEBIAN/postinst"
#!/bin/bash
chmod -R 755 /usr/share/winscreensaver
update-desktop-database /usr/share/applications
exit 0
EOF
chmod 755 "$BUILD_ROOT/DEBIAN/postinst"

# 3. DEPLOY ASSETS
cp install.sh remove.sh "$BUILD_ROOT/usr/share/winscreensaver/"
cp Payload/winscr_*.sh "$BUILD_ROOT/usr/share/winscreensaver/Payload/" 2>/dev/null
cp Payload/*.conf "$BUILD_ROOT/usr/share/winscreensaver/Payload/" 2>/dev/null
cp Payload/winscr_icon.png "$BUILD_ROOT/usr/share/winscreensaver/Payload/" 2>/dev/null
cp Payload/winscr_icon.png "$BUILD_ROOT/usr/share/pixmaps/winscreensaver.png"

# 4. SYSTEM BINARY WRAPPER
cat <<EOF > "$BUILD_ROOT/usr/bin/winscreensaver"
#!/bin/bash
WINEPREFIX_PATH="\$HOME/.winscr"
if [ ! -d "\$WINEPREFIX_PATH" ] || [ ! -f "\$WINEPREFIX_PATH/winscr_menu.sh" ]; then
    bash /usr/share/winscreensaver/install.sh
fi
if [ -f "\$WINEPREFIX_PATH/winscr_menu.sh" ]; then
    bash "\$WINEPREFIX_PATH/winscr_menu.sh" "\$@"
fi
EOF
chmod 755 "$BUILD_ROOT/usr/bin/winscreensaver"

# 5. GLOBAL DESKTOP ENTRY
cat <<EOF > "$BUILD_ROOT/usr/share/applications/winscreensaver.desktop"
[Desktop Entry]
Name=WinScreensaver
Comment=Manage Windows Screensavers
Exec=winscreensaver
Icon=winscreensaver
Terminal=false
Type=Application
Categories=Qt;KDE;Utility;
StartupNotify=true
EOF

# Build the package
chmod -R 755 "$BUILD_ROOT/usr/share/winscreensaver"
dpkg-deb --build --root-owner-group "$BUILD_ROOT"

# Clean up build dir
rm -rf "$BUILD_ROOT"

echo "------------------------------------------------"
echo "Done: ${BUILD_ROOT}.deb has been created."
echo "Install with: sudo apt install ./${PACKAGE_NAME}_${VERSION}.deb"
