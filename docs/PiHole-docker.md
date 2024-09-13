
# PiHole with macvlan (docker)

Al utilizar una red de tipo macvlan, podemos asignarle una ip estatica en el mismo segmento que en nuestra red lan, lo que permite, por ejemplo tener nginx en el puerto 80 (en la ip del host) y pihole también en el puerto 80 pero en la otra red (dentro del mismo segmento) en la ip espeficiada.
Para poder utilizar el servidor dhcp de pihole es necesario que la ip esté dentro del segmento de la lan.

Creamos las carpetas para pihole:

```
mkdir -p /srv/hass/pihole/etc-pihole
mkdir -p /srv/hass/pihole/etc-dnsmasq.d
```

Crear red macvlan:
```
docker network create -d macvlan \
    -o parent=enP4p65s0 \
    --subnet 192.168.0.0/24 \
    --gateway 192.168.0.1 \
    --ip-range 192.168.0.224/27 \
    --aux-address 'host=192.168.0.225' \
    my-macvlan-net
```


```
docker run --cap-add=NET_ADMIN -d \
    --name pihole \
    -e TZ="America/Buenos Aires" \
    -v "/srv/hass/pihole/etc-pihole:/etc/pihole" \
    -v "/srv/hass/pihole/etc-dnsmasq.d:/etc/dnsmasq.d" \
    --hostname pi.hole \
    -e PIHOLE_DOMAIN=local \
    -e VIRTUAL_HOST="pi.hole" \
    -e INTERFACE=eth0@if2 \
    -e DNSMASQ_LISTENING=single \
    --network=my-macvlan-net \
    --ip 192.168.0.226 \
    --restart=unless-stopped \
    pihole/pihole:latest
```


# PiHole with macvlan (podman)
en progreso

https://stackoverflow.com/questions/59515026/how-do-i-replicate-a-docker-macvlan-network-with-podman

Crear interface macvlan
```
sudo podman network create -d macvlan \
  -o parent=enP4p65s0 \
  --subnet 192.168.0.0/24 \
  --gateway 192.168.0.1 \
  --ip-range 192.168.0.0/24 \
  pihole-net
```



Permitir trafico entre el host y el container
```
sudo ip link add pihole-net link enP4p65s0 type macvlan mode bridge
sudo ip addr add 192.168.0.10/32 dev pihole-net
sudo ip link set pihole-net up
sudo ip route add 192.168.0.20/32 dev pihole-net
```