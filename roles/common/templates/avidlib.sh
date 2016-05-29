#!/bin/bash
# {{ ansible_managed }}
#######################################################
## Author:	Andrew Martin <amartin@avidandrew.com>
## Date:	10/8/15
## Descr:	Library of common functions
## Depend:	sendmail, logger, rsync
#######################################################

###############
## VARIABLES ##
###############

# internal variables
ME=$(basename "$0" .sh)
LOCKDIR="/tmp/${ME}.lock"
KEEP_LOCK=0
USE_LOCKING=0
NONGLOBAL=0
RSYNC_GLOBAL_OPTIONS="-av --no-g --no-o --no-p --one-file-system --exclude=*.swp --exclude=*.swo --exclude=.cache --exclude=Trash"

# counters
NUM_INFO=0
NUM_WARNING=0
NUM_ERROR=0
NUM_SUCCESS=0

# status exit codes
STATUS_SUCCESS=0
STATUS_WARNING=1
STATUS_ERROR=2

# loggers
INFO=""
WARNING=""
ERROR=""
SUCCESS=""

# strings
STR_BANNER="----------"
STR_PRETEND="$STR_BANNER PRETEND MODE $STR_BANNER"
STR_REAL="$STR_BANNER REAL MODE $STR_BANNER"

# can be changed by the calling script
LOGFILE=/var/log/${ME}.log			# name of the log file (when not using syslog)
FROM="$(hostname)@axe.avidandrew.com"		# "from" email address for alert emails
TO="{{ notification_email }}"			# destination email address for alert emails
USE_SYSLOG="no"					# set to "yes" to log to syslog
DEBUG=0						# set to 1 to enable debugging (console logging only)
PRETEND=1					# set to 0 to disable pretend/simulation mode
SUPPRESS_EMAIL=0				# set to 1 to disable sending summary email


###############
## FUNCTIONS ##
###############

## logs a string to the specified logging facility
# $1 the message to log
function log() {
	if [ $DEBUG -ne 1 ]; then
		if [ "$USE_SYSLOG" == "yes" ]; then
			echo "$@" | logger -t $ME
		else
			echo -e "[$(date)] $@" >> $LOGFILE
		fi
	fi

	# always output a copy to the console too
	echo -e "[$(date)] $@"
}

## logs an info message
# $1 the message to log
function info() {
	let NUM_INFO=NUM_INFO+1
	INFO="$INFO\n$@"
	log "$@"
}

## logs a warning message
# $1 the message to log
function warning() {
	let NUM_WARNING=NUM_WARNING+1
	WARNING="$WARNING\n$@"
	log "[WARNING] $@"
}

## logs an error message
# $1 the message to log
function error() {
	let NUM_ERROR=NUM_ERROR+1
	ERROR="$ERROR\n$@"
	log "[ERROR] $@"
}

## logs a success message
# $1 the message to log
function success() {
	let NUM_SUCCESS=NUM_SUCCESS+1
	SUCCESS="$SUCCESS\n$@"
	log "[SUCCESS] $@"
}

## log a command before running it
# $1 the message to log and then run
# ret - the exit code of the command (or first command if a pipe was used
function logandrun() {
	local ret=1
	info "Executing: $@"
	if [ $DEBUG -eq 1 ]; then
		$@
		ret=${PIPESTATUS[0]}
	else
		if [ "$USE_SYSLOG" == "yes" ]; then
			$@ 2>&1 | logger -t $ME -s
			ret=${PIPESTATUS[0]}
		else
			$@ 2>&1 | tee -a $LOGFILE
			ret=${PIPESTATUS[0]}
		fi
	fi

	return $ret
}

## sends an email to the specified address
# $1 destination address
# $2 subject
# $3 body
function email() {
	info "[EMAIL] Subject: $2\n$3"

	content=$(mktemp)
cat <<- EOF >> $content
Subject: $2
From: ${FROM}
To: $1

$(echo -e "$3")
EOF

	/usr/sbin/sendmail -t "$1" < $content
	ret=$?
	rm -f $content
	return $ret
}

function lib_on_exit() {
        # clean up the lock file on exit
        if [ -d ${LOCKDIR} ] && [ $KEEP_LOCK -ne 1 ]; then
                rmdir ${LOCKDIR} 2> /dev/null
                if [ $? -ne 0 ]; then
                        warning "When $ME exited, it could not remove its lock directory, $LOCKDIR. Please remove this directory manually."
                fi
        fi

	# print summary message to log
	if [ $SUPPRESS_EMAIL -eq 0 ]; then 
		email "$TO" "$ME Status Report" "$ME completed with $NUM_ERROR errors, $NUM_WARNING warnings, $NUM_INFO info, and $NUM_SUCCESS success messages:\nErrors:\n$ERROR\n\n\nWarnings:\n$WARNING\n\nSuccesses:\n$SUCCESS"
	fi

	# run a local on_exit() function if it exists
	type on_exit &> /dev/null && on_exit

	info "$STR_BANNER run of $ME finished $STR_BANNER"

	if [ $NUM_ERROR -gt 0 ]; then
		exit $STATUS_ERROR
	elif [ $NUM_WARNING -gt 0 ]; then
		exit $STATUS_WARNING
	elif [ $NUM_SUCCESS -gt 0 ]; then
		exit $STATUS_SUCCESS
	else
		error "$ME must log at least 1 success, warning, or error, but none were logged"
		exit $STATUS_ERROR
	fi
}

## syncs a directory
# $1 src dir
# $2 dest dir or remote server
# $3 extra rsync options (e.g exclude list)
function syncdir() {
        local src=$1
	local dest=$2
        local options=$3
        if [ ! -d "$src" ] && [[ $src != *":"* ]]; then
                error "$src does not exist"
                return 1
        fi

        info "rsync $RSYNC_GLOBAL_OPTIONS $options $src $dest"
        rsync $RSYNC_GLOBAL_OPTIONS $options $src $dest 2>&1 | tee -a $LOGFILE
        local ret=${PIPESTATUS[0]}
        if [ $ret -eq 23 ]; then
                warning "rsync exited with $ret, meaning some files could not be backed up"
        elif [ $ret -eq 0 ] || [ $ret -eq 24 ]; then
                success "rsync exited successfully ($ret)"
        else
                error "rsync failed with exit code $ret"
        fi

        return $ret
}

## try to acquire lock and if successful run main()
# $1 custom name of the lock file
function lockThenMain() {
        if [ "$1" != "" ]; then
                # use a custom lockdir
                LOCKDIR=$1
        fi

        if mkdir "${LOCKDIR}" &>/dev/null; then
                # no other instances of this script are currently running, proceed
                main
        else
                # another instance of this this script is already running - abort (and don't remove the lock file on exit)
                KEEP_LOCK=1
                error "$ME already running, aborting!"
                email "$ME Cannot Run" "$ME $@ already running, aborting!"
                exit 1
        fi
}

function setup() {
	info "$STR_BANNER run of $ME starting $STR_BANNER"

	if [ $PRETEND -ne 0 ]; then
		info "$STR_PRETEND"
	else
		info "$STR_REAL"
	fi
}


##########
## MAIN ##
##########

trap lib_on_exit EXIT

# parses global args (uppercase only)
while getopts "DP:" opt 2>/dev/null; do
        case $opt in

        D) # enable debug mode (send to console only)
           DEBUG=1
        ;;
        P) # configure pretend mode (enabled by default)
           if [ "$OPTARG" == "no" ]; then
		   PRETEND=0
           fi
        ;;
        *)
                (( NONGLOBAL += 1 ))
        ;;
        esac
done

# shift args so that scripts can parse their own args
shift $(( OPTIND - 1 - NONGLOBAL ))
OPTIND=1

