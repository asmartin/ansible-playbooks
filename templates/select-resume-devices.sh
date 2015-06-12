#!/bin/bash
# {{ ansible_managed }}
# 
# Script to create resume udev rules for USB devices
#
# Source: http://bernaerts.dyndns.org/linux/74-ubuntu/220-ubuntu-resume-usb-hid
#
# Depends on zenity
# 09/05/2012 - V1.0 by Nicolas Bernaerts
{% raw %}

# udev file to generate
UDEV_FILE="/etc/udev/rules.d/90-hid-wakeup-enable.rules"

# set separator as CR
IFS=$'\n'

# list all USB devices, excluding root & hubs
LIST_DEVICE=(`lsusb | grep -v "0000:0000" | grep -iv "hub" | sed 's/^.*[0-9a-f]\:[0-9a-f]* \(.*\)$/\1/g'`)

# loop thru the devices array to generate zenity parameter
for DEVICE in "${LIST_DEVICE[@]}"
do
  # if needed, remove [xxx] from device name as it gives trouble with grep
  DEVICE=`echo "$DEVICE" | sed 's/\[.*\]//g'`

  # add it to the parameters list
  ARR_PARAMETER=( FALSE ${DEVICE} ${ARR_PARAMETER[@]} )
done

# display the dialog box to choose devices
TITLE="Wakeup - Enable USB devices"
TEXT="Please, select USB devices you want to use to resume your computer"
CHOICE=`zenity --list --width=600 --height=250 --text=$TEXT --title=$TITLE --checklist --column "Select" --column "Device name" "${ARR_PARAMETER[@]}"`

# slit the device choice into an array
IFS="|" read -a ARR_CHOICE <<< "$CHOICE"

# if at least one device has been selected, initialise udev rules file
[ ${#ARR_CHOICE[@]} -gt 0 ] && echo "# udev rule for USB wake-up of selected devices" > $UDEV_FILE
[ ${#ARR_CHOICE[@]} -gt 0 ] && echo "#" >> $UDEV_FILE

# loop thru the selected devices to create udev rules
for DEVICE_NAME in "${ARR_CHOICE[@]}"
do
  # get current device data
  DEVICE_DATA=`lsusb | grep "${DEVICE_NAME}" | sed 's/^.*ID \([0-9a-f]*\):\([0-9a-f]*\).*$/\1|\2/g'`
  DEVICE_VENDOR=`echo $DEVICE_DATA | cut -d"|" -f1`
  DEVICE_PRODUCT=`echo $DEVICE_DATA | cut -d"|" -f2`

  # create udev rule for current device
  DEVICE_RULE="SUBSYSTEM==\"usb\", ATTRS{idVendor}==\"$DEVICE_VENDOR\", ATTRS{idProduct}==\"$DEVICE_PRODUCT\" RUN+=\"/usr/local/bin/enable-wakeup.sh \$env{DEVPATH}\" "

  # add udev rule for current device
  echo "# ${DEVICE_NAME}" >> $UDEV_FILE
  echo ${DEVICE_RULE} >> $UDEV_FILE
done

# if at least one device has been selected, display notification
TITLE="USB resume enabled"
TEXT="Your USB devices are resume enabled.\nTo finalize configuration you have to do one of these actions :\n- replug USB devices\n- reboot the computer"
[ ${#ARR_CHOICE[@]} -gt 0 ] && notify-send --icon=media-eject $TITLE $TEXT
{% endraw %}
