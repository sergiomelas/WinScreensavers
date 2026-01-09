#!/bin/bash
#This script will install autorotate system for KDE

echo  " "
echo  " ##################################################################"
echo  " #                     Test      scrennsaver                      #"
echo  " #       Developed for X11 & KDE Plasma  by sergio melas 2024     #"
echo  " #                                                                #"
echo  " #                Emai: sergiomelas@gmail.com                     #"
echo  " #                   Released under GPL V2.0                      #"
echo  " #                                                                #"
echo  " ##################################################################"
echo  " "

echo  ""

SCR_SAVER=$( cat /home/$USER/.winscr/scrensaver.conf )

#Start bootle with screensaver configuration
WINEPREFIX=/home/$USER/.winscr
wine /home/$USER/.winscr/drive_c/windows/system32/"$SCR_SAVER" /s

#reopen menu
cmd="/home/$USER/.winscr/winscr_menu.sh"
kstart5 bash $cmd  &
