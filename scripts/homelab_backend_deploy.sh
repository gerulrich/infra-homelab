#!/bin/bash
PATH=$PATH:
cd "${0%/*}"
PATH=$PATH:node-v18.14.2/bin

if [ ! -d "node-v18.14.2" ]; then
    wget -q https://nodejs.org/dist/v18.14.2/node-v18.14.2-linux-arm64.tar.gz
    tar -xf node-v18.14.2-linux-arm64.tar.gz
    rm node-v18.14.2-linux-arm64.tar.gz
fi

app_bundle=$(curl -s https://api.github.com/repos/gerulrich/homelab/releases/latest | jq -r '.assets[] | select(.name == "homelab-backend.tar.gz") | .browser_download_url')
app_file="$(basename $app_bundle).tar.gz"

echo "Install $app_file"
rm -rf $( ls -I deploy.sh -I .env -I "node-v18.14.2" )
wget -O $app_file -q "$app_bundle"
tar -xzf "$app_file"
rm -rf node_modules
npm install

systemctl --user restart homelab