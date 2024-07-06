#!/bin/bash
if [ ! -z "$FIRMWARE_URL" ]; then
    echo "Downloading the firmware from ${FIEMWARE_URL} ..."
    wget -O firmware.zip ${FIRMWARE_URL}
    if [ $? -ne 0 ]; then
        echo "Failed to download the firmware, exiting..."
        exit 1
    fi
    FIRMWARE_FILE=$(unzip firmware.zip | sed -nE 's/  inflating: (.+)/\1/p')
elif [ ! -z "$FIRMWARE_FILE" ] && [ -f "$FIRMWARE_FILE" ]; then
    echo "Using existing firmware file ${FIRMWARE_FILE}"
else
    echo "No firmware file specified, exiting..."
    exit 1
fi
echo "python3 cc2538-bsl.py "${@}" ${FIRMWARE_FILE}"
python3 cc2538-bsl.py "${@}" ${FIRMWARE_FILE}