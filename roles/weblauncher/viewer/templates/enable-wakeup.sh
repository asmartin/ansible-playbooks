#!/bin/bash
# {{ ansible_managed }}
#
# Script to enable a USB devices to be used to resume computer from sleep
# 
# Source: http://bernaerts.dyndns.org/linux/74-ubuntu/220-ubuntu-resume-usb-hid
#
# Depends on udevadm package
# 09/05/2012 - V1.0 by Nicolas Bernaerts

# if device has been removed, exit
[ "$ACTION" = "remove" ] && exit 0

# set PATH as it is not set for udev scripts
PATH="/usr/sbin:/usr/local/bin:/usr/bin:/sbin:/bin"

# set device SYSFS path
DEVICE_SYSFS="/sys$1"
CURRENT_SYSFS=$DEVICE_SYSFS

# get device product and vendor name from parent SYSFS
DEVICE_VENDOR=`udevadm info --query=all -p "$CURRENT_SYSFS/../" | grep "ID_VENDOR_ID=" | cut -d "=" -f 2`
DEVICE_PRODUCT=`udevadm info --query=all -p "$CURRENT_SYSFS/../" | grep "ID_MODEL_ID=" | cut -d "=" -f 2`
DEVICE_LABEL=`lsusb | grep "${DEVICE_VENDOR}:${DEVICE_PRODUCT}" | sed 's/^.*[0-9a-f]\:[0-9a-f]* \(.*\)$/\1/g'`

# loop thru the SYSFS path, up to PCI bus
CARRY_ON=1
while [ $CARRY_ON -eq 1 ]
do
  # get the first three letters of current SYSFS folder
  FIRST_LETTERS=`basename $CURRENT_SYSFS | sed 's/^\(...\).*$/\1/g'`

  # if current SYSFS is PCI bus, stop the loop
  if [ "$FIRST_LETTERS" = "pci" ] || [ "$FIRST_LETTERS" = "/" ] ; then
    CARRY_ON=0

  # else,
  else
    # if possible, enable wakeup for current SYSFS
    WAKEUP_FILE="${CURRENT_SYSFS}/power/wakeup"
    if [ -f $WAKEUP_FILE ]; then
      echo "enabled" > $WAKEUP_FILE
    fi

    # go to father directory of current SYSFS
    CURRENT_SYSFS=`dirname $CURRENT_SYSFS`
  fi
done

# log the action
LOG_HEADER="USB device ${DEVICE_VENDOR}:${DEVICE_PRODUCT}"
logger "${LOG_HEADER} - Description : ${DEVICE_LABEL}"
logger "${LOG_HEADER} - SysFS path  : ${DEVICE_SYSFS}"
logger "${LOG_HEADER} - Device is enabled to handle suspend/resume"
