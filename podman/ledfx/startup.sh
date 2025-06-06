#!/bin/sh
rm -rf /var/run/pulse /var/lib/pulse /root/.config/pulse
pulseaudio -D --system --disallow-exit --exit-idle-time=-1 --verbose -L "module-native-protocol-tcp auth-anonymous=1 port=4713"
ledfx -v -c /config