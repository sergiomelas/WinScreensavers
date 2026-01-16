                     ##################################################################
                     ##################################################################
                     ###           Windows Screensavers for X11/KDE                 ###
                     ### Developed by sergio melas (sergiomelas@gmail.com) 2026     ###
                     ##################################################################
                     ##################################################################

This collection of scripts implements the usage of windows screensaver in KDE plasma on X11 with a pretty interface


Installation Instructions:


- Copy the windows  screensavers .scr file in the "SCR files" folder before install
- double click on the Run-me.sh file
- This will lauch the install.sh script in konsole
- Then choose the screensaver and timeout
- Login Logout to activate
- To intall screensavers that have an installer run:
WINEPREFIX=/home/$USER/.winscr wine <path to installer>

Note to be able to enjoy the screensaver you shuld set the lock screen timeout and screen switch of timout larger of the screesaver timeout in kde plasma options

You can find the latest version of this software here:https://github.com/sergiomelas/Kde-X11-Screensavers

##################################################################################################################
Change log:
 -V1.0   25-07-2024: Initial version
 -V1.1   27-07-2024: Added menu
 -v2.0   28-07-2024: First pubblic release, added lock screen option,addes memory of timout
 -V2.1   31-07-2024: Corrected bugs with system lockscreen and scresaver choice, added memory of lockscreen
 -V2.1.1 10-08-2024: Updated Screensaver choice form
 -V2.1.2 09-04-2025: Corrected bugs missing 386 libraries, updated for KDE6
 -V2.1.3 22-08-2025: Corrected bug on alredy running lock screen
 -V2.2   17-01-2026: Updated the bottle creation following new sintax, upgraded menus beaviours with chosen option, added random screensaver cycling, clean up


Thx to Christitus for the inspirational post : https://www.youtube.com/watch?v=J2zasJz5vuA&t=384s
on youtube and the info below I used to create this

https://christitus.com/lcars-screensaver/
