#!/bin/bash
# {{ ansible_managed }}
#######################################################
## Author:	Andrew Martin <amartin@avidandrew.com
## Date:	5/12/15
## Descr:	Launches a given URL to the browser
#######################################################
SCRIPT_NAME="$(basename $0)"
SLEEP_TIMER="{{ sleep_timer }}"

# use Firefox for sites that work better on it (e.g sites that require HAL)
FIREFOX_SITES_REGEX="{{ firefox_sites }}"

# use Chrome for sites that work better on it
CHROME_SITES_REGEX="{{ chrome_sites }}"

function readstdin() {
	if read -t 0; then
		cat
	else
		echo "$*"
	fi
}

function log() {
	logger -t $SCRIPT_NAME "$*"
}

function launch_chrome() {
	notify "Loading..." "$(echo $1 | awk -F/ '{ print $3 }')"
	sed -i 's/"exit_type": "Crashed"/"exit_type": "Normal"/' ~/.config/chromium/Default/Preferences
	sed -i 's/"exited_cleanly": false/"exited_cleanly": true/' ~/.config/chromium/Default/Preferences
	google-chrome --no-default-browser-check --ssl-version-min=tls1 --start-fullscreen --ignore-gpu-blacklist --disable-restore-session-state --disable-infobars --disable-session-crashed-bubble  --app=$1 &
}

function launch_firefox() {
	notify "Loading..." "$(echo $1 | awk -F/ '{ print $3 }')"
	firefox $1 &
}

function kill_browsers() {
	close_wait=0
	max_wait=6

	# initially try to kill gracefully
	killall chrome firefox
	ps aux | grep -qE '[c]hrome|[f]irefox'
	while [ $? -eq 0 ] && [ $close_wait -lt $max_wait ]; do
		# wait for chrome and firefox to have closed
		sleep 0.5
		let close_wait=close_wait+1
		ps aux | grep -qE '[c]hrome|[f]irefox'
	done
	if [ $close_wait -eq $max_wait ]; then
		# forcefully kill chrome and firefox since they won't gracefully close
		killall -9 chrome firefox
	fi
}

## prints a libnotify message on the screen
# $1 the title to print
# $2 the message to print
function notify() {
	local title=$1
	local msg=$2
	log "$title: $msg"
#	export $(egrep -z DBUS_SESSION_BUS_ADDRESS /proc/$(pgrep -u $LOGNAME lxsession)/environ)
#	notify-send --icon=dialog-information "$title" "$msg"
}

## puts the computer to sleep now
function sleep_now() {
	notify "Sleeping Now" "Putting the Viewer into sleep mode now..."
	kill_browsers
        if pidof systemd > /dev/null 2>&1; then
		# xenial and later
                sudo systemctl suspend
        else
		# trusty and earlier
		sudo dbus-send --system --print-reply --dest=org.freedesktop.UPower /org/freedesktop/UPower org.freedesktop.UPower.Suspend > /dev/null 2>&1
	fi
	exit 0
}

## remove existing scheduled sleep
function sleep_clear() {
	echo "" > $SLEEP_TIMER

	notify "Sleep Canceled" "All existing scheduled sleep jobs have been canceled"
}

## sleeps after the specified delay
# $1 the number of minutes to wait to sleep
function sleep_delay() {
	time=$1
	sleep_clear
	echo $(date --date="now + ${time}min" +%s) > $SLEEP_TIMER
	if [ $? -eq 0 ]; then
		notify "Sleeping in $time min" "The Viewer will go into sleep mode in $time minutes"
	else
		notify "Error" "Error scheduling sleep in ${time} minutes"
	fi
	exit 0
}

link=$(readstdin)

# set DISPLAY
export DISPLAY=:0.0

if [ "$link" == "reboot" ]; then
	notify "Reboot" "Rebooting the Viewer now..."
	sudo reboot
elif [ "$link" == "sleep" ]; then
	sleep_now
elif [ "$link" == "sleep-5" ]; then
	sleep_delay 5
elif [ "$link" == "sleep-15" ]; then
	sleep_delay 15
elif [ "$link" == "sleep-30" ]; then
	sleep_delay 30
elif [ "$link" == "sleep-45" ]; then
	sleep_delay 45
elif [ "$link" == "sleep-60" ]; then
	sleep_delay 60
elif [ "$link" == "sleep-clear" ]; then
	sleep_clear
elif [ "$link" == "services" ]; then
	kill -9 $(ps aux | grep [S]impleComputerRemote | awk '{ print $2 }')
	sleep 1
	log "restarting SimpleComputerRemote and other services"
	sudo service lightdm restart 2>&1 | logger -t $SCRIPT_NAME
	sudo service websockify restart 2>&1 | logger -t $SCRIPT_NAME
	sudo service x11vnc restart 2>&1 | logger -t $SCRIPT_NAME
	nohup /opt/rekap/SimpleComputerRemote & disown
	notify "Services Restarted" "All WebLauncher services have been restarted"
	exit 0
elif [ "$link" == "close" ]; then
	kill_browsers
	exit 0
fi

ps aux | grep -q [S]impleComputerRemote
if [ $? -ne 0 ]; then
	log "starting SimpleComputerRemote"
	nohup /opt/rekap/SimpleComputerRemote & disown
	sleep 2
	ps aux | grep -q [S]impleComputerRemote
	if [ $? -ne 0 ]; then
		log "cannot start SimpleComputerRemote"
		exit 2
	fi
fi

# kill any existing browser processes
kill_browsers

echo "$link" | grep -qiE "$FIREFOX_SITES_REGEX"
if [ $? -eq 0 ]; then
	ps aux | grep -q [h]ald
	if [ $? -ne 0 ]; then
		# start hald for sites that need it, e.g Amazon Prime
		hald
	fi
fi

echo "$link" | grep -qiE "$CHROME_SITES_REGEX"
chrome_ret=$?
echo "$link" | grep -qiE "$FIREFOX_SITES_REGEX"
firefox_ret=$?
if [ $chrome_ret -eq 0 ]; then
	# launch chrome for sites that work better on it
	launch_chrome "$link"
elif [ $firefox_ret -eq 0 ]; then
	# launch firefox for sites that work better on it
	launch_firefox "$link"
else
	# use the preferred browser 
	if [ "{{ preferred_browser }}" == "chrome" ]; then
		launch_chrome "$link"
	else
		launch_firefox "$link"
	fi
fi
