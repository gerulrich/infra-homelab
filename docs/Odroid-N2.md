## Cambiar el nombre que reporta desde la conexion HDMI a DENON:

```
fdtput -t s /media/boot/amlogic/meson64_odroidn2.dtb /amhdmitx/vend_data product_desc Odroid
```

Chequear que se cambió (o antes de cambiarlo cual es el nombre):
```
fdtget /media/boot/amlogic/meson64_odroidn2.dtb /amhdmitx/vend_data product_desc
```