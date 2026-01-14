#!/bin/bash
# filename: winscr_lock.sh

echo  " "
echo  " ##################################################################"
echo  " #                     Configure Lock Screen                      #"
echo  " #       Developed for X11 & KDE Plasma  by sergio melas 2026     #"
echo  " #                                                                #"
echo  " #                Emai: sergiomelas@gmail.com                     #"
echo  " #                   Released under GPL V2.0                      #"
echo  " #                                                                #"
echo  " ##################################################################"
echo  " "

# Read current configuration
# 0 = No (Disabled), 1 = Yes (Enabled)
LockS=$( cat /home/$USER/.winscr/lockscreen.conf 2>/dev/null || echo "0" )

# Logic to set the radio buttons based on the config file
if [ "$LockS" == "1" ]; then
    # If config is 1, set Yes to TRUE
    R_NO="FALSE"
    R_YES="TRUE"
else
    # If config is 0 or file missing, set No to TRUE
    R_NO="TRUE"
    R_YES="FALSE"
fi

# Launch Zenity form with the correct radio button pre-selected
LockScr=$(zenity --list --radiolist --title="Lock Screen Configuration" \
    --text "Do you want to lock the session when the screensaver ends?" \
    --column "Pick" --column "Answer" \
    $R_NO "No" $R_YES "Yes" --height=250 --width=350)

# Process Choice
if [ -z "$LockScr" ]; then
    # If user hits Cancel, do not change anything
    # Reopen the main menu using modern KDE kstart
    kstart bash /home/$USER/.winscr/winscr_menu.sh &
else
    if [ "$LockScr" == "Yes" ]; then
        echo "Lock screen active"
        LockVal=1
    else
        echo "Lock screen inactive"
        LockVal=0
    fi

    # Save the choice back to the config file
    echo $LockVal > /home/$USER/.winscr/lockscreen.conf
    # Reopen the main menu using modern KDE kstart
    kstart bash /home/$USER/.winscr/winscr_menu.sh &
fi


