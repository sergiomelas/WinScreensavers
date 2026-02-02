##################################################################
##################################################################
###           Windows Screensavers for Linux                   ###
### Developed by sergio melas (sergiomelas@gmail.com) 2026     ###
##################################################################
##################################################################

This collection of scripts implements the usage of Windows screensavers (.scr) in KDE Plasma (X11 & Wayland) with a clean interface and automated background management.

Current Setup Features:
- Debian Package (.deb) for easy system-wide installation.
- Automated User-Space setup (environment built in ~/.winscr).
- Global menu integration with a dedicated system icon.
- Symmetric Integrity Audit: Automatically detects missing scripts or empty .scr folders.

Installation Instructions:

1. Install the Package:
   - Use apt or gdebi to install it:
     sudo apt install ./sml-screensaver_3.0-2026.deb

2. Initialize Environment (First Run):
   - Launch "WinScreensaver" from your  Application Menu (under Utilities/Settings).
   - The first run will automatically trigger the Intelligent Setup.
   - Select the folder containing your .scr files when prompted. The installer intelligently discovers and suggests your collection folder that contains most of screensavers.

3. Activation:
   - The service starts automatically after setup and is added to your Autostart.
   - You do NOT need to logout; the service begins monitoring immediately.

How to add screensavers with installers:
To install screensavers that require a setup.exe, use the following command to ensure they land in the correct folder:
WINEPREFIX=/home/$USER/.winscr wine <path_to_installer.exe>

Note: To ensure the screensaver triggers correctly, set your "Screen Locking" and "Power Management" (Screen Energy Saving) timeouts to be LARGER than the screensaver timeout set in the WinScreensaver menu.

Latest Version: https://github.com/sergiomelas/WinScreensavers

##################################################################################################################
Change log:
 -V1.0    25-07-2024: Initial version
 -V1.1    27-07-2024: Added menu
 -V2.0    28-07-2024: First public release, added lock screen option, added memory of timeout
 -V2.1    31-07-2024: Corrected bugs with system lockscreen and screensaver choice, added memory of lockscreen
 -V2.1.1  10-08-2024: Updated Screensaver choice form
 -V2.1.2  09-04-2025: Corrected bugs missing 386 libraries, updated for KDE6
 -V2.1.3  22-08-2025: Corrected bug on already running lock screen
 -V2.2    22-01-2026: Updated the bottle creation following new syntax, upgraded menus behaviors with chosen option,
                      added random screensaver cycling, avoid more than one instance, clean up
 -V2.3    29-01-2026: Added support for Wayland
 -V3.0    31-01-2026: Implemented Debian Builder, global icon registration, fixed root-permission issues,
                      space-proof intelligent folder discovery, and absolute pathing for reliable autostart.
 -V3.1    02-02-2026: Full support for Wayland is operational

Thx to Christitus for the inspirational post: https://www.youtube.com/watch?v=J2zasJz5vuA&t=384s
on youtube and the info below I used to create this:
https://christitus.com/lcars-screensaver/
