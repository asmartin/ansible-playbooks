#!/bin/bash
# {{ ansible_managed }}
#######################################################
## Author:      Andrew Martin <amartin@avidandrew.com
## Date:        8/02/15
## Descr:       Checks for a scheduled sleep task and
##              if one exists, executes it
#######################################################
SCRIPT_NAME="$(basename $0)"
SLEEP_TIMER="{{ sleep_timer }}"
if [ -f "$SLEEP_TIMER" ]; then
	time=$(cat "$SLEEP_TIMER")
	if [ "$time" != "" ]; then
		now=$(date +%s)
		if [ $time -lt $now ]; then
			logger -t $SCRIPT_NAME "sleeping now..."
			echo "" > "$SLEEP_TIMER"
			echo sleep | /usr/local/bin/weblauncher.sh 2>&1 | logger -t $SCRIPT_NAME
		fi
	fi
fi
