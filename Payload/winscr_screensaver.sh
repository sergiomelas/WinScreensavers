#!/bin/bash
#This script will lauch windows screensaver

echo  " "
echo  " ##################################################################"
echo  " #                 Windows screensavers laucher                   #"
echo  " #       Developed for X11 & KDE Plasma  by sergio melas 2025     #"
echo  " #                                                                #"
echo  " #                Emai: sergiomelas@gmail.com                     #"
echo  " #                   Released unde GPV V2.0                       #"
echo  " #                                                                #"
echo  " ##################################################################"
echo  " "


#Run screensaver subroutine
trigger_cmd() {
    #Check if any media is plaing
    SounRun=$( pacmd list-sink-inputs | grep -c 'state: RUNNING' )
    LockSc=$( cat /home/$USER/.winscr/lockscreen.conf )
    if [ $SounRun -eq '0' ]; then #if not run screensaver
      SCR_SAVER=$( cat /home/$USER/.winscr/scrensaver.conf )
      WINEPREFIX=/home/$USER/.winscr
      wine /home/$USER/.winscr/drive_c/windows/system32/"$SCR_SAVER" /s
      SysLockSc=$( /usr/lib/qt6/bin/qdbus  org.freedesktop.ScreenSaver /ScreenSaver GetActive ) #get status of kde lockscreen after scrrensaver exits
      if [[ "$SysLockSc" == *false* ]]; then #If  kde didnt alredy losked the screen
          if [ $LockSc -gt '0' ]; then #if asked lock screen
              loginctl lock-session
          fi
      fi
    fi
}

sleep_time=$IDLE_TIME
triggered=false

#enter main screen loop
while sleep $(((sleep_time+999)/1000)); do
    #screensaver time in seconds
    SCR_TIME=$( cat /home/$USER/.winscr/timeout.conf )
    # Calculate idle time time in millisencos
    IDLE_TIME=$(($SCR_TIME*1000))
    idle=$(xprintidle)
    echo "Waiting for Screensaver"
    if [ $idle -ge $IDLE_TIME ]; then #if timout witout activity start screensaver one shot
        if ! $triggered; then
            echo "Start Screensaver"
            trigger_cmd
            triggered=true
            sleep_time=$IDLE_TIME
        fi
    else
        triggered=false #reset trigger for one shot
        # Give 100 ms buffer to avoid frantic loops shortly before triggers.
        sleep_time=$((IDLE_TIME-idle+100))
    fi
    sleep 1 #idle for cpu to minimise resource
done
