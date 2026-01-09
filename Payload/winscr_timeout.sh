#!/bin/bash
#This script will install autorotate system for KDE

echo  " "
echo  " ##################################################################"
echo  " #                        Choose Timeout                          #"
echo  " #       Developed for X11 & KDE Plasma  by sergio melas 2024     #"
echo  " #                                                                #"
echo  " #                Emai: sergiomelas@gmail.com                     #"
echo  " #                   Released under GPL V2.0                      #"
echo  " #                                                                #"
echo  " ##################################################################"


Tim=15;

#read current timeout
Tim=$( cat /home/$USER/.winscr/timeout.conf )


echo $Tim

#lauch form with current timeout
case $Tim in
   '30')
   Time=$(zenity --list  --title="Scrennesaver Timeout Configuration" --text "Pick an option" --column "Pick" --column "Answer" --radiolist  TRUE "30 seconds" FALSE "2 minutes"  FALSE "5 minutes"  FALSE "10 minutes"  FALSE "15 minutes" FALSE "30 minutes" FALSE "1 hour" FALSE "Screensaver Disabled"  )
   ;;
   '120')
   Time=$(zenity --list  --title="Scrennesaver Timeout Configuration" --text "Pick an option" --column "Pick" --column "Answer" --radiolist  FALSE "30 seconds" TRUE "2 minutes"  FALSE "5 minutes"  FALSE "10 minutes"  FALSE "15 minutes" FALSE "30 minutes" FALSE "1 hour" FALSE "Screensaver Disabled"  )

   ;;
   '300')
   Time=$(zenity --list  --title="Scrennesaver Timeout Configuration" --text "Pick an option" --column "Pick" --column "Answer" --radiolist  FALSE "30 seconds" FALSE "2 minutes"  TRUE "5 minutes"  FALSE "10 minutes"  FALSE "15 minutes" FALSE "30 minutes" FALSE "1 hour" FALSE "Screensaver Disabled"  )

;;
   '600')
   Time=$(zenity --list  --title="Scrennesaver Timeout Configuration" --text "Pick an option" --column "Pick" --column "Answer" --radiolist  FALSE "30 seconds" FALSE "2 minutes" FALSE  "5 minutes"  TRUE "10 minutes"  FALSE "15 minutes" FALSE "30 minutes" FALSE "1 hour" FALSE "Screensaver Disabled"  )

;;
   '900')
   Time=$(zenity --list  --title="Scrennesaver Timeout Configuration" --text "Pick an option" --column "Pick" --column "Answer" --radiolist  FALSE "30 seconds" FALSE "2 minutes" FALSE  "5 minutes" FALSE  "10 minutes"  TRUE "15 minutes" FALSE "30 minutes" FALSE "1 hour" FALSE "Screensaver Disabled"  )

;;
   '1800')
   Time=$(zenity --list  --title="Scrennesaver Timeout Configuration" --text "Pick an option" --column "Pick" --column "Answer" --radiolist  FALSE "30 seconds" FALSE "2 minutes" FALSE  "5 minutes" FALSE  "10 minutes"  FALSE  "15 minutes" TRUE "30 minutes" FALSE "1 hour" FALSE "Screensaver Disabled"  )

;;
   '3600')
   Time=$(zenity --list  --title="Scrennesaver Timeout Configuration" --text "Pick an option" --column "Pick" --column "Answer" --radiolist  FALSE "30 seconds" FALSE "2 minutes" FALSE  "5 minutes" FALSE  "10 minutes"  FALSE  "15 minutes" FALSE "30 minutes" TRUE "1 hour" FALSE "Screensaver Disabled"  )

;;
  '1000000000')
   Time=$(zenity --list  --title="Scrennesaver Timeout Configuration" --text "Pick an option" --column "Pick" --column "Answer" --radiolist  FALSE "30 seconds" FALSE "2 minutes" FALSE  "5 minutes" FALSE  "10 minutes"  FALSE  "15 minutes" FALSE "30 minutes" FALSE "1 hour" TRUE "Screensaver Disabled"  )

;;
esac


if [ -z "$Time" ]
then #if no scoice mantain current
     Time=$Tim #user aborted
else #trasform choice in time
    echo  -n "The chosen screesaver is:  $SCR"
    echo $SCR   |  tee -a /home/$USER/.winscr/scrensaver.conf       > /dev/null

    case $Time in
     '30 seconds')
        echo  "30 seconds"
        Tim=30;
     ;;
     '2 minutes')
        echo  "2 minutes"
        Tim=120;
     ;;
     '5 minutes')
        echo  "5 minutes"
        Tim=300;
     ;;
     '10 minutes')
        echo  "10 minutes"
        Tim=600;
     ;;
    '15 minutes')
       echo  "15 minutes"
      Tim=900;
     ;;
    '30 minutes')
       echo  "30 minutes"
       Tim=1800;
    ;;
   '1 hour')
      echo  "1 hour"
      Tim=3600;
    ;;
    'Screensaver Disabled')
      echo  "Screensaver Disabled"
      Tim=1000000000;
    ;;
    esac
    #write in conf
    rm  /home/$USER/.winscr/timeout.conf
    echo $Tim   |  tee -a /home/$USER/.winscr/timeout.conf       > /dev/null

fi

#reopen menu
cmd="/home/$USER/.winscr/winscr_menu.sh"
kstart5 bash $cmd  &




