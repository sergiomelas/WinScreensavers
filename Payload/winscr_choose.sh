#!/bin/bash
#This script will install autorotate system for KDE

echo  " "
echo  " ##################################################################"
echo  " #                        Choose scrennsaver                      #"
echo  " #       Developed for X11 & KDE Plasma  by sergio melas 2024     #"
echo  " #                                                                #"
echo  " #                Emai: sergiomelas@gmail.com                     #"
echo  " #                   Released unde GPV V2.0                       #"
echo  " #                                                                #"
echo  " ##################################################################"
echo  " "

echo  ""


echo  ""
echo -n "Choose the screensaver : "

#Get List Of Avaliable Screen Saver
readarray array < <((cd  /home/$USER/.winscr/drive_c/windows/system32 &&ls *.scr))

#Remove estenction for nice list
for i in "${!array[@]}"; do
 arrayz[$i]=$( basename -a "${array[$i]%.*}" )
done

#ask user to choose screen saver
arrayz=( "Dummy" "${arrayz[@]}" )
SCR=$(zenity --entry --title "Winscr Chooser" --text "${arrayz[@]}" --text "Plese choose the screensaver")


if [ -z "$SCR" ]
then
    zenity --info --timeout 2 --text="No screesaver chosen!" #user aborted
    SCR_SAVER=$( cat /home/$USER/.winscr/scrensaver.conf )
    SCR=$SCR_SAVER
else
    SCR=$SCR.scr
    echo  -n "The chosen screesaver is:  $SCR"
fi

rm /home/$USER/.winscr/scrensaver.conf
echo $SCR | tee -a /home/$USER/.winscr/scrensaver.conf  > /dev/null

#reopen menu
cmd="/home/$USER/.winscr/winscr_menu.sh"
kstart5 bash $cmd  &





