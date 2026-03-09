# QR Generator

Este contenedor genera un PDF con codigos QR para tags de musica.

## Build

Desde la raiz del repo:

```bash
docker build -t qr-generator ./podman/qr-generator
```

## Run

### Help

Para ver la ayuda del script:

```bash
docker run --rm qr-generator --help
```

El script requiere:
- `BASE_URL` o `--base-url`
- `OUTPUT_DIR` o `--output-dir`

Opcional:
- `--pages` cantidad de paginas a generar (default: `1`)

El archivo se genera con nombre:
`music-qr-codes-YYYY-MM-DD_HH-MM-SS.pdf`

### Ejemplo con volumen de salida

```bash
docker run --rm \
  -e BASE_URL="https://music.example.com/tag" \
  -e OUTPUT_DIR="/data" \
  -v "$(pwd):/data" \
  qr-generator \
  --pages 2
```

### Ejemplo usando argumentos CLI

```bash
docker run --rm \
  -v "$(pwd):/data" \
  qr-generator \
  --base-url "https://music.example.com/tag" \
  --output-dir "/data" \
  --pages 2
```

