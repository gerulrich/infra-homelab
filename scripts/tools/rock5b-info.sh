#!/bin/bash

# Show the usage of the script
if [ "$1" == "-h" ]; then
    echo "Usage: $0 [-t | -v | -p]"
    echo "  -t: Display the temperature of the CPU"
    echo "  -v: Display the input voltage"
    echo "  -p: Display the log PD (power delivery)"
    exit 0
fi

# Displat the temperature of the CPU
if [ "$1" == "-t" ]; then
    paste <(cat /sys/class/thermal/thermal_zone*/type) <(cat /sys/class/thermal/thermal_zone*/temp) \
        | column -s $'\t' -t | sed 's/\(.\)..$/.\1°C/'
fi

# Displa input voltage
if [ "$1" == "-v" ]; then
    awk '{print $1/172.5}' </sys/bus/iio/devices/iio:device0/in_voltage6_raw
fi

# Display log PD (power delivery)
if [ "$1" == "-p" ]; then
    sudo cat /sys/kernel/debug/usb/fusb302-4-0022 /sys/kernel/debug/usb/tcpm-4-0022 | sort
fi