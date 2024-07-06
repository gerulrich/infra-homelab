#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <vm-name>"
    exit 1
fi

virsh undefine --nvram $1