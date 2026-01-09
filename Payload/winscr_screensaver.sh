#!/bin/bash
#This script will lauch windows screensaver

echo  " "
echo  " ##################################################################"
echo  " #                 Windows screensavers laucher                   #"
echo  " #       Developed for X11 & KDE Plasma  by sergio melas 2025     #"
echo  " #                                                                #"
echo  " #                Emai: sergiomelas@gmail.com                     #"
echo  " #                   Released under GPL V2.0                      #"
echo  " #                                                                #"
echo  " ##################################################################"
echo  " "


#Run screensaver subroutine
trigger_cmd() {
    #Check if any media is plaing
    MedRun=$( pacmd list-sink-inputs | grep -c 'state: RUNNING' )
    #Read if lock screen is required
    LockSc=$( cat /home/$USER/.winscr/lockscreen.conf )
    if [ $MedRun -eq '0' ]; then #if no media running run screensaver
      SCR_SAVER=$( cat /home/$USER/.winscr/scrensaver.conf )
      #Check if lock screen is running
      SysLockSc=$( /usr/lib/qt6/bin/qdbus org.freedesktop.ScreenSaver /org/freedesktop/ScreenSaver GetActive ) #get status of kde lockscreen after scrrensaver exits
      #Run Screensaver
      WINEPREFIX=/home/$USER/.winscr
      wine /home/$USER/.winscr/drive_c/windows/system32/"$SCR_SAVER" /s

      if [[ "$SysLockSc" == *"false"* ]]; then #If  kde didnt alredy locked the screen
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
