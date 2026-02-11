#!/bin/bash
# filename: build_winscr_deb.sh
# Final version 2026 - Universal Edition (Fixes First-Run Icon/Path Bug)
# Developed for X11/Wayland & KDE/Gnome/XFCE by sergio melas 2026

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

PACKAGE_NAME="winscreensaver"
VERSION="3.2"
BUILD_ROOT="./${PACKAGE_NAME}_${VERSION}"

# 1. CLEAN & PREPARE
rm -rf "$BUILD_ROOT"
mkdir -p "$BUILD_ROOT/DEBIAN"
mkdir -p "$BUILD_ROOT/usr/share/winscreensaver/Payload"
mkdir -p "$BUILD_ROOT/usr/bin"
mkdir -p "$BUILD_ROOT/usr/share/applications"
mkdir -p "$BUILD_ROOT/usr/share/pixmaps"

# 2. CONTROL FILE
cat <<EOF > "$BUILD_ROOT/DEBIAN/control"
Package: $PACKAGE_NAME
Version: $VERSION
Section: utils
Priority: optional
Architecture: all
Depends: wine, wine32, xprintidle, x11-utils, procps, swayidle, zenity, xdotool
Maintainer: Sergio Melas <sergiomelas@gmail.com>
Description: Windows .scr manager for Linux.
EOF

# 3. POST-INSTALL (Permissions & Cache)
cat <<EOF > "$BUILD_ROOT/DEBIAN/postinst"
#!/bin/bash
chmod -R 755 /usr/share/winscreensaver
update-desktop-database /usr/share/applications
gtk-update-icon-cache /usr/share/pixmaps 2>/dev/null || true
exit 0
EOF
chmod 755 "$BUILD_ROOT/DEBIAN/postinst"

# 4. SYSTEM ASSETS (THE FIX)
# Install icon to global system path
cp Payload/winscr_icon.png "$BUILD_ROOT/usr/share/pixmaps/winscreensaver.png"

# Install desktop entry to global applications path
cat <<EOF > "$BUILD_ROOT/usr/share/applications/winscreensaver.desktop"
[Desktop Entry]
Name=WinScreensaver
Exec=winscreensaver
Icon=winscreensaver
Terminal=false
Type=Application
Categories=Utility;Settings;
EOF

# 5. DEPLOY PAYLOAD
cp install.sh remove.sh "$BUILD_ROOT/usr/share/winscreensaver/"
cp Payload/winscr_*.sh "$BUILD_ROOT/usr/share/winscreensaver/Payload/" 2>/dev/null
cp Payload/*.conf "$BUILD_ROOT/usr/share/winscreensaver/Payload/" 2>/dev/null

# 6. SYSTEM BINARY WRAPPER
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

# BUILD
dpkg-deb --build --root-owner-group "$BUILD_ROOT"
rm -rf "$BUILD_ROOT"
echo "Package built successfully."
