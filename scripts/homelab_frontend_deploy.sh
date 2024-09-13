#!/bin/bash
PATH=$PATH:
cd "${0%/*}"
PATH=$PATH:node-v18.14.2/bin

app_bundle=$(curl -s https://api.github.com/repos/gerulrich/homelab/releases/latest | jq -r '.assets[] | select(.name == "homelab-frontend.tar.gz") | .browser_download_url')
app_file="$(basename $app_bundle).tar.gz"

echo "Install $app_file"
rm -rf $( ls -I deploy.sh -I .env* )
wget -O $app_file -q "$app_bundle"
tar -xzf "$app_file"