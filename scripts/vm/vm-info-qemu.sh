#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <vm-name>"
    exit 1
fi

virsh --connect qemu:///system domifaddr $1

echo -e "\nVNC display of the VM:"
virsh --connect qemu:///system vncdisplay ubuntu-vm
