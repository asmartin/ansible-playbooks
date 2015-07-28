#!/bin/bash
# {{ ansible_managed }}
#######################################################
## Author:	Andrew Martin <amartin@avidandrew.com
## Date:	5/12/15
## Descr:	Launches a given URL to the browser
#######################################################
SCRIPT_NAME="$(basename $0)"

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
	sed -i 's/"exit_type": "Crashed"/"exit_type": "Normal"/' ~/.config/chromium/Default/Preferences
	sed -i 's/"exited_cleanly": false/"exited_cleanly": true/' ~/.config/chromium/Default/Preferences
	google-chrome --ssl-version-min=tls1 --kiosk --ignore-gpu-blacklist --disable-restore-session-state $1 &
}

function launch_firefox() {
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

link=$(readstdin)

# set DISPLAY
export DISPLAY=:0.0

if [ "$link" == "reboot" ]; then
	sudo reboot
elif [ "$link" == "sleep" ]; then
	kill_browsers
	sudo dbus-send --system --print-reply --dest=org.freedesktop.UPower /org/freedesktop/UPower org.freedesktop.UPower.Suspend > /dev/null 2>&1
	exit 0
elif [ "$link" == "services" ]; then
	kill -9 $(ps aux | grep [S]impleComputerRemote | awk '{ print $2 }')
	sleep 1
	log "restarting SimpleComputerRemote and other services"
	sudo service websockify restart 2>&1 | logger -t $SCRIPT_NAME
	sudo service x11vnc restart 2>&1 | logger -t $SCRIPT_NAME
	nohup /opt/rekap/SimpleComputerRemote & disown
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
