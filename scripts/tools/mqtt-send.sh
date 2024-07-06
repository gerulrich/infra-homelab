#!/bin/bash
# Usage: mqtt_send.sh <topic> <message>
MQTT_HOST="192.168.0.10"
MQTT_USER="{{mqtt_notity_user}}"
MQTT_PASS="{{mqtt_notity_pass}}"
TOPIC=$1
MESSAGE=$2

if [ -z "$TOPIC" ] || [ -z "$MESSAGE" ]; then
    echo "Usage: $0 <topic> <message>"
    exit 1
fi

mosquitto_pub -h "$MQTT_HOST" -t "$TOPIC" -m "$MESSAGE" -u "$MQTT_USER"  -P "$MQTT_PASS"