                     ##################################################################
                     ##################################################################
                     ###           Windows Screensavers for X11/KDE                 ###
                     ### Developed by sergio melas (sergiomelas@gmail.com) 2025     ###
                     ##################################################################
                     ##################################################################

This collection of scripts implements the usage of windows screensaver in KDE plasma on X11 with a pretty interface


Installation Instructions:


- Copy the windows  screensavers .scr file in the "SCR files" folder before install
- double click on the Run-me.sh file
- This will lauch the install.sh script in konsole
- When wine bottle config arrives chose windows XP
- Then choose the screensaver and timeout
- Login Logout to activate
- To intall screensavers that have an installer run:
WINEPREFIX=/home/$USER/.winscr wine <path to installer>

Note to be agle to enjoy the screensaver you shuld set yhe lock screen timeout and screen switch of timout larger of the screesaver timeout in kde plasma options


##################################################################################################################
Change log:
 -V1.0   25-07-2024: Initial version
 -V1.1   27-07-2024: Added menu
 -v2.0   28-07-2024: First pubblic release, added lock screen option,addes memory of timout
 -V2.1   31-07-2024: Corrected bugs with system lockscreen and scresaver choice, added memory of lockscreen
 -V2.1.1 10-08-2024: Updated Screensaver choice form
 -V2.1.2 09-04-2025: Corrected bugs missing 386 libraries, updated for KDE6

Thx to Christitus for the inspirational post : https://www.youtube.com/watch?v=J2zasJz5vuA&t=384s
on youtube and the info below I used to create this

https://christitus.com/lcars-screensaver/
