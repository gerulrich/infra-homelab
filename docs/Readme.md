# Script varios

firewall_list.sh
```bash
!/bin/bash

DIR=$(dirname $0)
. $DIR/env.sh

ssh -i ${KEY_FILE} root@${ROUTER_IP} 'iptables -L FORWARD -v --line-numbers' | grep DROP
```

restart_wifi.sh
```bash
#!/bin/bash

DIR=$(dirname $0)
. $DIR/env.sh

ssh -i ${KEY_FILE} root@${ROUTER_IP} "/sbin/wifi down radio0 && sleep 20 && /sbin/wifi up radio0"
```


mqtt-integration-py:
```python
#!/usr/bin/env python
# required packages:
# apt-get install python3-paho-mqtt python3-dotenv

import paho.mqtt.client as mqtt
import json
import os
import logging
from dotenv import load_dotenv
load_dotenv()

script_dir = os.getenv("SCRIPT_DIR")
# TODO sacar mediante servicio rest
client = mqtt.Client("mqtt-ha")
devices = {
  "redmi7a": "192.168.0.141",
  "redmi_note4": "192.168.0.155",
  "google_tv": "192.168.0.209",
  "xbox": "192.168.1.112",
  "mac_book_pro": "192.168.0.168"
}

def on_camera_message(payload):
    os.system(f'{script_dir}/security_cam.sh')
    result = {
        "chatId": payload["chatId"],
        "content": "/tmp/camera/webcam.jpeg"
    }
    logging.info("Sending image path to topic '/camera/snapshot/output'")
    client.publish("/camera/snapshot/output", json.dumps(result))

def on_firewall_message(payload):
    device=payload["device"]
    if payload["status"] == "on":
        logging.info(f'Enable internet on {device} device with ip {devices[device]}')
        os.system(f'{script_dir}/enable_internet.sh {devices[device]}')
    else:
        logging.info(f'Disable internet on {device} device with ip {devices[device]}')
        os.system(f'{script_dir}/disable_internet.sh {devices[device]}')
        client.publish("/firewall/forward/result", "ok")

def on_wifi_message(payload):
    logging.info("Reiniciando wifi")
    os.system("f'{script_dir}/restart_wifi.sh")
    client.publish("/wifi/radio0/result", "ok")

def on_message(mclient, userdata, message):
    payload = json.loads(str(message.payload.decode("utf-8","ignore")))
    match message.topic:
        case "/camera/snapshot":
            on_camera_message(payload)
        case "/firewall/forward":
            on_firewall_message(payload)
        case "/wifi/radio0":
            on_wifi_message(payload)
        case _:
            logging.warn(f'Topic {message.topic} not handled')


if __name__ == "__main__":
    format = "%(asctime)s: %(message)s"
    logging.basicConfig(format=format, level=logging.INFO, datefmt="%H:%M:%S")

    try:
        mqtt_host = os.getenv("MQTT_HOST")
        mqtt_user = os.getenv("MQTT_USER")
        mqtt_pass = os.getenv("MQTT_PASS")

        client.username_pw_set(mqtt_user, mqtt_pass)
        client.connect(mqtt_host)
        client.subscribe("/camera/foto/action")
        client.subscribe("/internet/access")
        client.subscribe("/wifi/radio0")
        client.on_message=on_message
        client.loop_forever()
    except:
        logging.error("failed to connect, moving on")
```


enable_internet.sh:
```bash
#!/bin/bash

DIR=$(dirname $0)
. $DIR/env.sh

disabled=$($DIR/firewall_list.sh | grep $1 | wc -l)

if [ $disabled -gt 0 ]; then
    ssh -i ${KEY_FILE} root@${ROUTER_IP} "iptables -D FORWARD -s $1 -j DROP"
fi
```

disable_internet.sh:
```bash
#!/bin/bash

DIR=$(dirname $0)
. $DIR/env.sh

disabled=$($DIR/firewall_list.sh | grep $1 | wc -l)

if [ $disabled -eq 0 ]; then
    ssh -i ${KEY_FILE} root@${ROUTER_IP} "iptables -I FORWARD -s $1 -j DROP"
fi
```


flow-epg.py:
```python
import argparse
import json
import os
import base64
import time
import logging
import requests

STATIC_FLOW_URL = "https://static.flow.com.ar/images/"
FLOW_URL = "https://web.flow.com.ar/api/v1"
USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 " \
             "(HTML, like Gecko) Chrome/81.0.4044.129 Safari/537.36"
TOKEN_FILE = os.getenv("HOME") + "/flow/token"
CREDENTIAL_FILE = os.getenv("HOME") + "/flow/credentials.json"
ACCOUNT_FILE = os.getenv("HOME") + "/flow/account.json"
CHANNELS_FILE = os.getenv("HOME") + "/flow/channels.json"
EPG_FILE = os.getenv("HOME") + "/flow/epg.json"


class AuthException(Exception):
    """Authentication Error"""

    def __init__(self, message="Salary is not in (5000, 15000) range"):
        self.message = message
        super().__init__(self.message)

    pass


# format epoc time in date time string
def format_epoc(epoch_time):
    return time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(epoch_time))


# get a token from the file or generate a new one if needed
def get_token():
    token = None
    # check if token file exists
    if os.path.exists(TOKEN_FILE):
        with open(TOKEN_FILE, 'r') as file:
            token = file.read().rstrip()
            token_validation = token.split('.')[1]
            token_validation += ('=' * (-len(token_validation) % 4))  # restore stripped '='s
            # validate expiration time
            token_data = json.loads(base64.b64decode(token_validation).decode('utf-8'))
            current_time = int(time.time())
            exp_time = token_data["exp"]
            if current_time > exp_time:
                token = None
                logging.info(f'Token expired (time: {format_epoc(current_time)}, exp: {format_epoc(exp_time)}')
            else:
                logging.info(f'Token not expired (time: {format_epoc(current_time)}, exp: {format_epoc(exp_time)}')

    # check if credential file exists
    if token is None and os.path.exists(CREDENTIAL_FILE):
        logging.info("Authenticating in flow app ...")
        if os.path.exists(CREDENTIAL_FILE):
            with open(CREDENTIAL_FILE, 'r') as file:
                credentials = json.loads(file.read().replace('\n', ''))
            # requesting new token
            headers = {"Content-Type": "application/json; charset=utf-8", "User-Agent": USER_AGENT}
            response = requests.post('https://web.flow.com.ar/auth/v2/provision/login', headers=headers,
                                     json=credentials)
            if response.status_code == 200:
                token = json.loads(response.text)['jwt']
                # save token in file
                with open(TOKEN_FILE, "w") as text_file:
                    text_file.write(token)
            else:
                raise AuthException(message=f'Error trying to login in flow with credentials: {credentials}')
        else:
            logging.error("file credentials.json not exists")
            exit(-1)

    if token is not None and os.path.exists(CREDENTIAL_FILE):
        logging.info("Generating account token ...")
        with open(ACCOUNT_FILE, 'r') as account_file:
            account = json.loads(account_file.read().replace('\n', ''))
            headers = {
                "Content-Type": "application/json; charset=utf-8",
                "User-Agent": USER_AGENT,
                "Authorization": "Bearer " + token
            }
            response = requests.post('https://web.flow.com.ar/auth/v2/provision/account', headers=headers, json=account)
            if response.status_code == 200:
                return response.text.replace("\"", '')
            else:
                raise AuthException(message=f'Error trying to generate account token')
    else:
        logging.error("file account.json not exists")
        exit(-1)


def get_channels(token):
    headers = {"Content-Type": "application/json; charset=utf-8",
               "User-Agent": USER_AGENT, "Authorization": f'Bearer {token}'}
    response = requests.get('https://web.flow.com.ar/api/v1/content/channels', headers=headers)
    if response.status_code == 200:
        channels = json.loads(response.text)
        channel_list = []
        # processing channel list
        for channel in channels:
            new_channel = {
                "id": channel["id"],
                "number": channel["number"],
                "title": channel["title"],
                "image": f'{STATIC_FLOW_URL}{channel["id"]}/CH_LOGO/472/320/{channel["images"][0]["suffix"]}.png',
                "resources": [],
                "enabled": True,
                "epg_enabled": True
            }
            # add resource only if protocol is dash
            for resource in channel["resources"]:
                if resource["protocol"] == "DASH":
                    dash_resource = {
                        "protocol": "DASH",
                        "url": resource["url"],
                        "encryption": resource["encryption"]
                    }
                    new_channel["resources"].append(dash_resource)
            channel_list.append(new_channel)
        # save json file with channels
        with open(CHANNELS_FILE, 'w') as file:
            file.write(json.dumps(channel_list, indent=2, sort_keys=False))
            logging.info("Channel list saved")
    else:
        logging.error(f'error requesting channel list: {response.status_code}')


def get_flow_epg(date_from, date_to, ids, token):
    headers = {
        "Content-Type": "application/json; charset=utf-8", 'Accept': 'application/json, text/plain, */*',
        'Referer': 'https://web.flow.com.ar/inicio',
        "User-Agent": USER_AGENT,
        "Authorization": f'Bearer {token}'
    }
    response = requests.post(
        f'{FLOW_URL}/content/channel?size=1440&dateFrom={date_from}000&dateTo={date_to}999&tvRating=6&all=true',
        headers=headers,
        json=ids
    )
    epg = []
    if response.status_code == 200:
        epg_channels = json.loads(response.text)
        for epg_channel in epg_channels:
            for entry in epg_channel:
                program = {
                    "id": entry["id"],
                    "title": entry["title"],
                    "channelId": int(entry["channelId"]),
                    "startTime": int(entry["startTime"] / 1000),
                    "endTime": int(entry["endTime"] / 1000),
                    "start": format_epoc(int(entry["startTime"] / 1000)),
                    "end": format_epoc(int(entry["endTime"] / 1000)),
                    "resources": [],
                    "description": entry.get("description", None),
                    "showType": entry["showType"],
                    "episodeTitle": entry.get("episodeTitle", None),
                    "programId": entry["programId"],
                    "seasonNumber": entry.get("seasonNumber", None),
                    "episodeNumber": entry.get("episodeNumber", None),
                }
                for resource in entry["resources"]:
                    if resource["protocol"] == "DASH":
                        dash_resource = {
                            "protocol": "DASH",
                            "url": resource["url"],
                            "encryption": resource["encryption"]
                        }
                        program["resources"].append(dash_resource)

                epg.append(program)
        return epg
    else:
        print(response.status_code)


def get_epg_json(token):
    with open(CHANNELS_FILE, 'r') as file:
        channels = json.loads(file.read().replace('\n', ''))
    # filter elements with epg enabled
    filtered_channels = [channel for channel in channels if (channel["epg_enabled"] and channel["group"] == "deporte")]
    # split the channels into chunks of 5 elements
    chunks = [filtered_channels[x:x + 5] for x in range(0, len(filtered_channels), 5)]
    # start 24 hours ago
    current_time = int(time.time()) - 86400
    epg = []
    for chunk in chunks:
        ids = [int(channel["id"]) for channel in chunk]
        titles = [channel["title"] for channel in chunk]
        date = current_time
        # each range represents 6 hours
        for t in range(0, 12):
            date_from = date
            date_to = date + 21600
            date = date_to + 1
            logging.info(f'Request epg from {format_epoc(date_from)} to {format_epoc(date_to)} for channels {titles}')
            epg_partial = get_flow_epg(date_from, date_to, ids, token)
            epg.extend(epg_partial)
    with open(EPG_FILE, 'w') as file:
        # remove duplicates, sort and save
        epg_dic = {}
        for program in epg:
            epg_dic[program["id"]] = program
        epg_sorted = sorted(list(epg_dic.values()), key=lambda x: (x["channelId"], x["startTime"]))
        file.write(json.dumps(epg_sorted, indent=2, sort_keys=False))
        logging.info("epg json file saved")


def main():
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
        handlers=[logging.StreamHandler()]
    )
    parser = argparse.ArgumentParser(description='Optional app description')
    group = parser.add_mutually_exclusive_group()
    group.add_argument('--channels', action='store_true', help='Create channels file')
    group.add_argument('--epg', action='store_true', help='Create epg file')
    args = parser.parse_args()

    try:
        token = get_token()
        if args.channels:
            get_channels(token)
        else:
            get_epg_json(token)
    except AuthException as err:
        logging.error(err.message)


if __name__ == '__main__':
    main()
```


Download with freyrjs:
```bash
ocker run -it --rm -v $PWD:/data freyrcli/freyrjs <URL spotify|apple music|dezeer>
```

Download with deezer-dw
```bash
# create deez_settings.ini file with this content:
[deez_login]
mail=<email>
pwd=<password>
arl=<arl session cookie>

[spot_login]
mail=
pwd=

# execute docker
docker run -it -p 8001:8000 -v $PWD/downloads/:/home/user/Songs -v $PWD/deez_settings.ini:/home/user/.deez_settings.ini --rm gerulrich/deezer-dw
$ su - user # inside container
$ download-album.sh <deezer album id>
```


Open Port:
```bash
#!/bin/bash

DIR=$(dirname $0)
. $DIR/env.sh

rule=$(ssh -i ${KEY_FILE} root@${ROUTER_IP} "uci show firewall | grep redirect | grep '""${OPEN_PORT_RULE_NAME}""'")
command=$(echo $rule | sed 's/\(.*\).name.*/\1.enabled=1/')
ssh -i ${KEY_FILE} root@${ROUTER_IP} "uci set ${command} && uci commit"
```

Close port:
```bash
#!/bin/bash

DIR=$(dirname $0)
. $DIR/env.sh

rule=$(ssh -i ${KEY_FILE} root@${ROUTER_IP} "uci show firewall | grep redirect | grep '""${OPEN_PORT_RULE_NAME}""'")
command=$(echo $rule | sed 's/\(.*\).name.*/\1.enabled=0/')
ssh -i ${KEY_FILE} root@${ROUTER_IP} "uci set ${command} && uci commit"
```

Reboot handy tone
```bash
#!/bin/sh

IP_ADDRESS="192.168.1.x"
PASSWORD="put password here"

##############################
# cron configuration openwrt #
##############################
# Habilitar servicio:
#/etc/init.d/cron start
#/etc/init.d/cron enable
#
# crontab -e
# 30 4 * * * /path-to-script/reboot_handy_tone.sh

# Edit configuration
#crontab -e
# 
# Show configuration
#crontab -l
#
# Apply changes
#service cron restart

curl -c /tmp/cookies.txt -d"P2=${PASSWORD}&Login=Login&gnkey=0b82" http://${IP_ADDRESS}/cgi-bin/dologin > /dev/null
curl -b /tmp/cookies.txt http://${IP_ADDRESS}/cgi-bin/rs > /dev/null
```