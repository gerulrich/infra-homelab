# Ejecutar Mosquitto Broker con Podman Rootless

Este documento proporciona instrucciones para ejecutar el broker Mosquitto utilizando Podman en modo rootless. Mosquitto es un broker MQTT (Message Queuing Telemetry Transport) de código abierto que implementa el protocolo MQTT para la comunicación de mensajes en la Internet de las cosas (IoT) y otros sistemas de mensajería.

## Integración con systemd

Para integrar Mosquitto con systemd, sigue estos pasos:

1. Crea un archivo de unidad llamado `mosquitto.service` en el directorio `~/.config/systemd/user/` con el siguiente contenido:

```plaintext
[Unit]
Description=Mosquitto MQTT Broker
Wants=network-online.target
After=network-online.target
RequiresMountsFor=%t/containers

[Service]
Environment=PODMAN_SYSTEMD_UNIT=%n TZ=America/Argentina/Buenos_Aires
Restart=on-failure
RestartSec=30
TimeoutStopSec=10
ExecStartPre=/bin/rm -f %t/%n.ctr-id
ExecStart=/usr/bin/podman run \
	--cidfile=%t/%n.ctr-id \
	--cgroups=no-conmon \
	--rm \
	--sdnotify=conmon \
	--replace \
	--detach \
	--label "io.containers.autoupdate=registry" \
	--name mosquitto \
	--network host \
	-p 1883:1883 \
	--volume=%h/hass/mosquitto/config:/mosquitto/config:Z \
	--volume=%h/hass/mosquitto/data:/mosquitto/data:Z \
	--volume=%h/hass/mosquitto/log:/mosquitto/log:Z \
	docker.io/eclipse-mosquitto
ExecStop=/usr/bin/podman stop --ignore --cidfile=%t/%n.ctr-id
ExecStopPost=/usr/bin/podman rm -f --ignore --cidfile=%t/%n.ctr-id
Type=notify
NotifyAccess=all

[Install]
WantedBy=default.target
```

2. En el archivo de unidad, hemos utilizado el specifier `%h` para hacer referencia al directorio principal del usuario. Esto te permite utilizar el path relativo `~/hass` en lugar del path absoluto.

## Habilitar y ejecutar el servicio

Para habilitar y ejecutar el servicio de Mosquitto, sigue estos comandos:

1. Habilita el servicio para que se inicie automáticamente al iniciar la sesión de usuario:

```plaintext
systemctl --user enable mosquitto.service
```

2. Inicia el servicio:

```plaintext
systemctl --user start mosquitto.service
```

Ahora, Mosquitto se ejecutará como un servicio utilizando Podman en modo rootless.

## Instalación de dependencias

El script `mqtt_send.sh` hace uso del comando `mosquitto_pub` para publicar mensajes en el broker MQTT. Para instalar las dependencias necesarias, ejecuta los siguientes comandos:

```plaintext
sudo apt-get update
sudo apt-get install mosquitto-clients
```

Esto instalará los clientes de Mosquitto, incluyendo `mosquitto_pub`.

## Configuración del script mqtt_send.sh

El script `mqtt_send.sh` es utilizado para enviar mensajes MQTT al broker. Asegúrate de crear el script en la ubicación `~/hass/scripts/mqtt_send.sh` utilizando el siguiente contenido:

```bash
#!/bin/bash

MQTT_HOST=<host>


MQTT_USER=user_notify
MQTT_PASS=<pass>
TOPIC=$1
MESSAGE=$2

mosquitto_pub -h $MQTT_HOST -t "$TOPIC" -m "$MESSAGE" -u $MQTT_USER  -P $MQTT_PASS
```

Reemplaza `<host>` con la dirección del host donde se ejecuta Mosquitto, `<pass>` con la contraseña deseada para el usuario MQTT y guarda el archivo.

Asegúrate de dar permisos de ejecución al script mediante el siguiente comando:

```plaintext
chmod +x ~/hass/scripts/mqtt_send.sh
```

## Creación de usuario para el script

Para utilizar el usuario `user_notify` en el script `mqtt_send.sh`, primero necesitas crearlo en Mosquitto. Ejecuta el siguiente comando:

```plaintext
podman exec -it mosquitto mosquitto_passwd /mosquitto/config/mqttuser user_notify
```

Esto creará el usuario `user_notify` en el archivo de configuración de Mosquitto.

## Configuración de ACL

Para permitir que el usuario `user_notify` publique mensajes en ciertos temas, debes configurar las listas de control de acceso (ACL) en el archivo de configuración de Mosquitto. Abre el archivo de configuración `mosquitto.conf` ubicado en `$HOME/hass/mosquitto/config` y agrega las siguientes líneas:

```
acl_file /mosquitto/config/acl
acl_file /mosquitto/config/acl-patterns
```

A continuación, crea los archivos `acl` y `acl-patterns` en el directorio `$HOME/hass/mosquitto/config` y configúralos según tus necesidades. Consulta la documentación de Mosquitto para obtener más información sobre la configuración de ACL.

## Ejemplo de uso del script mqtt_send.sh

Ahora puedes utilizar el script `mqtt_send.sh` para enviar mensajes MQTT al broker Mosquitto. Aquí tienes un ejemplo:

```plaintext
~/hass/scripts/mqtt_send.sh topic/subtopic "Hola, mundo!"
```

Esto publicará el mensaje "Hola, mundo!" en el tema `topic/subtopic` utilizando el usuario `user_notify` configurado previamente.

Utiliza este script en combinación con Node-RED u otras herramientas de automatización para enviar mensajes MQTT y realizar acciones en tu sistema.

¡Explora las posibilidades de la automatización con Mosquitto en la IoT y disfruta de la comunicación MQTT en tus proyectos!