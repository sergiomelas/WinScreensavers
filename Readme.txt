##################################################################
##################################################################
###          Windows(c) Screensavers for Linux KDE             ###
###   Developed by sergio melas (sergiomelas@gmail.com) 2026   ###
##################################################################
##################################################################

This collection of scripts implements the usage of Windows(c) screensavers (.scr) in KDE Plasma (X11 & Wayland) with a clean interface and automated background management.

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
Good Source for Windows(c) screesavers: https://www.screensaversplanet.com/screensavers/windows

##################################################################################################################
Change log:

- V4.1    09-07-2026: Implemented "Surgical QA Engine":
                      High-precision Group CPU Delta monitoring to distinguish
                      active screensavers from "zombie" processes.
                      Advanced X11/Wayland process-tree cleanup for total
                      elimination of "Program Error" dialogs and orphaned debuggers.
                      Optimized import validation loop to prevent valid
                      screensavers from being incorrectly flagged during initialization.

- V4.0    23-05-2026: Fixed critical engine bugs and optimized runtime stability.
                      Resolved an issue where random mode ignored the custom checklist pool.
                      Fixed a collision bug where consecutive selections of the same screensaver
                      failed under Wine, exposing the naked desktop; implemented a mathematical
                      step-and-wrap deduplication algorithm to guarantee seamless transitions.
                      Upgraded core rotation monitoring loop to high-frequency 10Hz (0.1s sleep)
                      with an active 'Anti-Hole' pgrep interceptor to eliminate visual desktop exposure
                      caused by silent Wine crashes. Enforced a hard minimum barrier of 2 screensavers
                      within the Zenity selection menu to prevent engine deadlocks.

 -V3.2    12-02-2026: Implemented "Responsive-Loop" (0.1s) for instant-kill on lock.
                      Added winscr_remove.sh for safe uninstallation with
                      bulleted confirmation lists and automatic pool cleanup.
                      Optimized session detection using loginctl for zero-lag.

 -V3.1    08-02-2026: Full support for Wayland is operational and debugged.

 -V3.0    31-01-2026: Implemented Debian Builder, global icon registration, fixed root-permission issues,
                      space-proof intelligent folder discovery, and absolute pathing for reliable autostart. -V1.0    25-07-2024: Initial version.

 -V2.3    29-01-2026: Added support for Wayland.

 -V2.2    22-01-2026: Updated the bottle creation following new syntax, upgraded menus behaviors with chosen option,
                      added random screensaver cycling, avoid more than one instance, clean up.

 -V2.1.3  22-08-2025: Corrected bug on already running lock screen.

 -V2.1.2  09-04-2025: Corrected bugs missing 386 libraries, updated for KDE6.

 -V2.1.1  10-08-2024: Updated Screensaver choice form.

 -V2.1    31-07-2024: Corrected bugs with system lockscreen and screensaver choice, added memory of lockscreen.

 -V2.0    28-07-2024: First public release, added lock screen option, added memory of timeout.

 -V1.1    27-07-2024: Added menu.


Thx to Christitus for the inspirational post: https://www.youtube.com/watch?v=J2zasJz5vuA&t=384s
on youtube and the info below I used to create this:
https://christitus.com/lcars-screensaver/
