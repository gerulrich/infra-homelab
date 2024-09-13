# Qemu en aarch64 (rock 5b)

### Instalar paquetes necesarios

```
apt-get install qemu-system-arm
apt-get install qemu-efi-aarch64
apt-get install qemu-utils qemu qemu-kvm qemu-system
```

### Crear flash images

```
dd if=/dev/zero of=flash1.img bs=1M count=64
dd if=/dev/zero of=flash0.img bs=1M count=64
dd if=/usr/share/qemu-efi-aarch64/QEMU_EFI.fd of=flash0.img conv=notrunc
```

### Descargar la imagen a instalar

```
wget http://ports.ubuntu.com/ubuntu-ports/dists/bionic-updates/main/installer-arm64/current/images/netboot/mini.iso
````


### Crear una imagen de disco para instalar ubuntu

```
qemu-img create ubuntu-image.img 20G
```

### Iniciar qemu con el instalador

```
qemu-system-aarch64 -nographic -machine virt,gic-version=max -enable-kvm -m 512M -cpu max -smp 4 \
    -netdev user,id=vnet,hostfwd=:127.0.0.1:0-:22 -device virtio-net-pci,netdev=vnet \
    -drive file=ubuntu-image.img,if=none,id=drive0,cache=writeback -device virtio-blk,drive=drive0,bootindex=0 \
    -drive file=mini.iso,if=none,id=drive1,cache=writeback -device virtio-blk,drive=drive1,bootindex=1 \
    -drive file=flash0.img,format=raw,if=pflash -drive file=flash1.img,format=raw,if=pflash 
```

### Una vez finalizado la instalación salir de qemu (para reiniciar) con:

```
Cntrl + a
c
quit
```

### Iniciar la vm (ya sin el instalador)

```
qemu-system-aarch64 -nographic -machine virt,gic-version=max -m 512M -cpu max -smp 4 \
    -netdev user,id=vnet,hostfwd=:127.0.0.1:0-:22 -device virtio-net-pci,netdev=vnet \
    -drive file=ubuntu-image.img,if=none,id=drive0,cache=writeback -device virtio-blk,drive=drive0,bootindex=0 \
    -drive file=flash0.img,format=raw,if=pflash -drive file=flash1.img,format=raw,if=pflash 
```

Fuente: [ow-to-launch-aarch64-vm](https://futurewei-cloud.github.io/ARM-Datacenter/qemu/how-to-launch-aarch64-vm/)


### Redireccionar puerto ssh
Se debe agregar (o modificar el siguiente parámetro en la linea de comandos)
```
-net user,hostfwd=tcp::8022-:22
```


## Usando cloud images

Descargar cloud images (preferiblemente en formato qcow2)

```
apt-get update && apt-get install libvirt-clients libvirt-daemon-system virtinst
mkdir -p ~/qemu/images
cd ~/qemu/images
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-arm64.img
```

[Ubuntu](https://cloud-images.ubuntu.com/)
[Debian](https://cloud.debian.org/images/cloud/)

Verificamos el formato de la imagen
```
qemu-img info jammy-server-cloudimg-arm64.img
(output)
image: jammy-server-cloudimg-arm64.img
file format: qcow2
virtual size: 2.2 GiB (2361393152 bytes)
disk size: 614 MiB
cluster_size: 65536
Format specific information:
    compat: 0.10
    compression type: zlib
    refcount bits: 16
```

Creamos una carpeta para guardar la imagen para la vm:

```
mkdir -p ~/qemu/ubuntu-vm
cd ~/qemu/ubuntu-vm
qemu-img create -f qcow2 -F qcow2 -o backing_file=~/qemu/images/jammy-server-cloudimg-arm64.img ubuntu-vm.img
```

Verificamos la imagen generada:

```
qemu-img info ubuntu-vm.qcow2
(output)
image: ubuntu-vm.qcow2
file format: qcow2
virtual size: 2.2 GiB (2361393152 bytes)
disk size: 196 KiB
cluster_size: 65536
backing file: ~/qemu/images/jammy-server-cloudimg-arm64.img
backing file format: qcow2
Format specific information:
    compat: 1.1
    compression type: zlib
    lazy refcounts: false
    refcount bits: 16
    corrupt: false
    extended l2: false
```

Configuramos en 5 GB el tamaño virtual del disco (está en 2.2 GB)

```
qemu-img resize ubuntu-vm.img 5G
```

Configurtación para cloud-init

```
cat >meta-data <<EOF
local-hostname: ubuntu-vm
EOF

cat >user-data <<EOF
#cloud-config
password: atomic
chpasswd: {expire: False}
EOF

```

PARA COMPLETAR (keys para ssh y otras configuraciones)

Crear un disco con la configuración de Cloud-Init:

```
genisoimage  -input-charset utf-8 -output ubuntu-vm-cidata.iso -volid cidata -joliet -rock user-data meta-data
```

Iniciar la vm:

```
virt-install --connect qemu:///system \
	--virt-type kvm \
	--name ubuntu-vm \
	--ram 512 \
	--vcpus=1 \
	--os-variant ubuntu20.04 \
	--disk path=~/qemu/vm/ubuntu-vm/ubuntu-vm.img,format=qcow2 \
	--disk ~/qemu/vm/ubuntu-vm/ubuntu-vm-cidata.iso,device=cdrom \
	--import \
	--network network=default \
	--graphics vnc,password=s3cr3t,listen=0.0.0.0 \
	--noautoconsole
```

Si muestra el siguiente error, se debe habilitar la interface de red

> ERROR    Requested operation is not valid: network 'default' is not active

```
virsh net-list --all
(output)
 Name      State      Autostart   Persistent
----------------------------------------------
 default   inactive   no          yes
```

Habilitar la interface:
```
sudo virsh net-start default
(output)
Network default started


virsh net-list --all
(output)
 Name      State    Autostart   Persistent
--------------------------------------------
 default   active   no          yes
```

Con la interface habilitada, iniciar nuevamente la vm.

# Auto start de la interface:

```
virsh net-autostart default

```

## Utilizar interface macvlan

Al utilizar una interface de red macvlan, va a permitir que la vm tenga una ip dentro del segmento de la lan, que se obtendrá por dhcp.

Para crear la interface macvlan se debe crear el siguiente archivo ```macvtap-def.xml```:

```
<network>
  <name>macvtap-net</name>
  <forward mode="bridge">
    <interface dev="eth1"/>
  </forward>
</network>
```

En la interface dev="..." se debe colocar el nombre de la interface de red física del host.

Luego ejecutar:

```
virsh net-autostart macvtap-net
virsh net-start macvtap-net
```

Luego crear la vm de la siguiente forma:

```
virt-install --connect qemu:///system \
    --virt-type kvm \
    --name ubuntu-vm \
    --ram 512 \
    --vcpus=1 \
    --os-variant ubuntu20.04 \
    --disk path=~/qemu/ubuntu-vm/ubuntu-vm.img,format=qcow2 \
    --disk ~/qemu/ubuntu-vm/ubuntu-vm-cidata.iso,device=cdrom \
    --import \
    --network network:macvtap-net,model=virtio \
    --graphics vnc,password=secret,listen=0.0.0.0 \
    --noautoconsole
```

De esta manera obtendrá una dirección mediante dhcp.


### Interface macvlan con ip estática

se debe crear el siguiente archivo:

```
cat <<EOF>> network-config
version: 2
ethernets:
    enp1s0:
        dhcp4: false
        dhcp6: false
        addresses:
          - 192.168.0.11/24
        gateway4: 192.168.0.1
        nameservers:
          addresses:
            - 8.8.8.8
            - 8.8.4.4
EOF
```


Generamos un disco con la configuración de Cloud-Init incluyendo la configuración de red:

```
genisoimage  -input-charset utf-8 -output ubuntu-vm-cidata.iso -volid cidata -joliet -rock user-data meta-data network-config
```

Iniciamos la vm:

```
virt-install --connect qemu:///system \
	--virt-type kvm \
	--name ubuntu-vm \
	--ram 512 \
	--vcpus=1 \
	--os-variant ubuntu20.04 \
	--disk path~/qemu/ubuntu-vm/ubuntu-vm.img,format=qcow2 \
	--disk ~/qemu/ubuntu-vm/ubuntu-vm-cidata.iso,device=cdrom \
	--import \
	--network network:macvtap-net,model=virtio \
    --graphics vnc,password=secret,listen=0.0.0.0 \
    --noautoconsole
```
