### Instalación de algunos paquetes

```
apt-get install dialog locales
dpkg-reconfigure locales
dpkg-reconfigure tzdata
```

### Configurar ip estática:

Editar el archivo ```/etc/network/interfaces```

```
# The loopback network interface
auto lo
iface lo inet loopback
 
# The primary network interface
auto enP4p65s0
iface enP4p65s0  inet static
 address 192.168.0.10
 netmask 255.255.255.0
 gateway 192.168.0.1
 dns-domain lan
 dns-nameservers 192.168.0.1
```

### Configuración NFS

```
apt-get install nfs-kernel-server -y
```

Editar el archivo ```/etc/exports```

```
/mnt/seagate    192.168.0.0/24(ro,no_root_squash,insecure)
```

### instalar fan-control:

```
wget https://github.com/pymumu/fan-control-rock5b/releases/download/1.1.0/fan-control-rock5b.1.1.0.arm64.deb
dpkg -i fan-control-rock5b.1.1.0.arm64.deb
systemctl enable fan-control
systemctl start fan-control
```

### Enable linger

Para iniciar systemd services de usuario

```
loginctl enable-linger rock
```