#!/bin/bash

# Youtube Tutorial: https://www.youtube.com/watch?v=4S_c_m6z-RY
FIRMWARE_URL="https://github.com/Koenkk/Z-Stack-firmware/raw/Z-Stack_3.x.0_coordinator_20230507/coordinator/Z-Stack_3.x.0/bin/CC1352P2_CC2652P_launchpad_coordinator_20230507.zip"
DEVICE='/dev/ttyUSB0'

echo "========================================================================"
echo "== This script will flash the Zigbee dongle with the latest firmware. =="
echo "== Before flashing, make sure Zigbee2Mqtt is STOPPED.                 =="
echo "========================================================================"
read -p "Do you want to continue? (y/n) " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Exiting..."
    exit 1
fi

podman run --rm -it \
    --group-add keep-groups \
    --device ${DEVICE}:/dev/ttyUSB0 \
    -e FIRMWARE_URL=${FIRMWARE_URL} \
    gerulrich/sonoff-dongle-flasher:latest -ewv -p /dev/ttyUSB0 --bootloader-sonoff-usb