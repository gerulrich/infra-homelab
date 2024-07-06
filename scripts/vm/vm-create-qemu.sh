#!/bin/bash

set -e

# Fuente https://gist.github.com/alainpham/bb1ca9e6be54eb3bf633fa2098f68c9e

# constants
QEMU_DIR=/home/${HOME}/qemu
IMG_DIR=$QEMU_DIR/images
VM_BASE_DIR=$QEMU_DIR/vm

#IMAGE=$IMG_DIR/jammy-server-cloudimg-arm64.img
IMAGE=$IMG_DIR/debian-11-genericcloud-arm64-20230124-1270.qcow2
usage() {
  echo "usage: $0 [-n|--name name] [-c|--cpu vmpu] [-m|--memory memory of vm] [-h|--help]"
  echo ""
  echo "This scripts create a virtual maquine with virt-install with qemu kvm"
  echo ""
  echo "OPTIONS:"
  echo "   -n|--name      name of the virtual maquine"
  echo "   -c|--cpu       number of cpu(s)"
  echo "   -m|--memory    memory in MB"
  echo "   --net          network type (default, macvtap)"
  echo "   -s|--static-ip static ip address"
  echo "   -h|--help      show this message"
}

VM_NAME=
VM_STATIC_IP=
VM_CPU=1
VM_MEM=512
VM_NET="network=default"
INTERFACE="enP4p65s0"

while [ ! $# -eq 0 ]; do
  case "$1" in
    -n | --name)
      VM_NAME=$2
      shift
        ;;
    -c | --cpu)
      VM_CPU=$2
      shift
        ;;
    -m | --memory)
      VM_MEM=$2
      shift
        ;;
    --net)
       case "$2" in
         default)
	  VM_NET="network=default"
	  ;;
	 macvtap)
	  VM_NET="network:macvtap-net,model=virtio"
	  ;;
         *)
          echo "Invalid network type: $2"
	  exit 1
       esac
       shift
	;;
    -s | --static-ip)
      VM_STATIC_IP=$2
      shift
        ;;
    -h | --help)
      usage
      exit
        ;;
    *)
      echo "Invalid parameter $1"
      exit 1
        ;;
  esac
  shift
done

# verificar que los parametros VM_NAME, VM_CPU y VM_MEM no esten vacios
if [ -z $VM_NAME ] || [ -z $VM_CPU ] || [ -z $VM_MEM ]; then
  usage
  exit 1
fi


found=$(virsh list --all | awk 'FNR > 2 {print $2}' | head -n -1 | grep -E "^$VM_NAME\$" | wc -l)
if [ $found -gt 0 ]; then
  echo "vm $VM_NAME already exists"
  exit 1
fi

if [ ! -z $VM_STATIC_IP ] && [ $VM_NET == "network=default" ]; then
  echo "static ip should be used with macvtap network type."
  exit 1
fi

VM_DIR="$VM_BASE_DIR/$VM_NAME"
CI_ISO=$VM_DIR/${VM_NAME}-cidata.iso
DISK=$VM_DIR/${VM_NAME}.qcow2
USER_DATA=$VM_DIR/user-data
META_DATA=$VM_DIR/meta-data
NETWORK_CONFIG=$VM_DIR/network-config

echo "$(date -R) creating machine named $VM_NAME with $VM_MEM MB of RAM and $VM_CPU vcpu(s) ...."
mkdir -p "$VM_DIR"

echo "$(date -R) creating cloud-init iso"

SSH_PUB_KEY=`cat $QEMU_DIR/keys/homelab_ubuntu_vm.pub`

cat > "$USER_DATA" << _EOF_
#cloud-config
password: atomic
chpasswd: {expire: False}
ssh_pwauth: True
ssh_authorized_keys:
  - $SSH_PUB_KEY
_EOF_

cat > "$META_DATA" << _EOF_
instance-id: $VM_NAME
local-hostname: $VM_NAME
_EOF_

if [ ! -z $VM_STATIC_IP ]; then
cat > "$NETWORK_CONFIG" << _EOF_
version: 2
ethernets:
  enp1s0:
    dhcp4: false
    dhcp6: false
    addresses:
      - ${VM_STATIC_IP}/24
    gateway4: 192.168.0.1
    nameservers:
      addresses:
        - 8.8.8.8
        - 8.8.4.4
_EOF_
fi

if [ ! -z $VM_STATIC_IP ]; then
  genisoimage -input-charset utf-8 -output $CI_ISO -volid cidata -joliet -rock "$USER_DATA" "$META_DATA" "$NETWORK_CONFIG"
else
  genisoimage -input-charset utf-8 -output $CI_ISO -volid cidata -joliet -rock "$USER_DATA" "$META_DATA"
fi

echo "$(date -R) Copying template image..."

qemu-img create -f qcow2 -o backing_file=$IMAGE $DISK

echo "$(date -R) Installing the domain and adjusting the configuration..."

virt-install --import --name $VM_NAME --connect qemu:///system \
    --virt-type kvm \
    --ram $VM_MEM \
    --vcpus=$VM_CPU \
    --os-variant ubuntu20.04 \
    --disk path=$DISK,format=qcow2 \
    --disk $CI_ISO,device=cdrom \
    --network $VM_NET \
    --graphics vnc,password=s3cr3t,listen=0.0.0.0 \
    --noautoconsole

# Eject cdrom
#echo "$(date -R) Cleaning up cloud-init..."
#virsh change-media $VM_NAME hda --eject --config
# Remove the unnecessary cloud init files
#rm $USER_DATA $CI_ISO $META_DATA
# echo "$(date -R) DONE. SSH to $1 using $IP , with  username 'cloud-user'."