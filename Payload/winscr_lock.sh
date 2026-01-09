#!/bin/bash
#This script will install autorotate system for KDE

echo  " "
echo  " ##################################################################"
echo  " #                     Configure scrennsaver                      #"
echo  " #       Developed for X11 & KDE Plasma  by sergio melas 2024     #"
echo  " #                                                                #"
echo  " #                Emai: sergiomelas@gmail.com                     #"
echo  " #                   Released under GPL V2.0                      #"
echo  " #                                                                #"
echo  " ##################################################################"
echo  " "

echo  ""



echo -n "Choose the locksession : "

#lauch form with current timeout
LockS=$( cat /home/$USER/.winscr/lockscreen.conf )
case $LockS in
   '0')
     LockScr=$(zenity --list  --title="Lock Screen Configuration:" --text "Do you want to lock screen? " --column "Pick" --column "Answer" --radiolist  TRUE "No" FALSE "Yes"  )
   ;;
   '1')
     LockScr=$(zenity --list  --title="Lock Screen Configuration:" --text "Do you want to lock screen? " --column "Pick" --column "Answer" --radiolist  FALSE "No" TRUE "Yes"  )
   ;;
esac




if [ -z "$LockScr" ]
then
      zenity --info --timeout 2 --text="No option chosen! Defaulting to lock screen" #user aborted
      LockSc=1;
else
    echo  -n "The chosen lockscreen option is:  $LockScr"

    case $LockScr in
     'Yes')
        echo  "Lock screen active"
        LockSc=1;
        ;;
      'No')
        echo  "Lock screen inactive"
        LockSc=0;
   ;;
   *)
   zenity --info --timeout 2 --text="No option chosen! Defaulting to lock screen" #user aborted
   LockSc=1;
   ;;
   esac


fi

rm /home/$USER/.winscr/lockscreen.conf
echo $LockSc   |  tee -a /home/$USER/.winscr/lockscreen.conf       > /dev/null

#reopen menu
cmd="/home/$USER/.winscr/winscr_menu.sh"
kstart5 bash $cmd  &
