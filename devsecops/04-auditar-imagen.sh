#!/usr/bin/env bash
# Uso: bash 04-auditar-imagen.sh mi-api:prueba
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/comun.bash"
imagen="${1:?Uso: $0 imagen:tag}"
[[ "$imagen" != -* ]] || { printf 'Referencia de imagen inválida.\n' >&2; exit 64; }
requerir trivy
crear_reporte imagen
# Escanea paquetes vulnerables; no ejecuta la aplicación ni corrige la imagen.
# Una imagen no disponible localmente puede descargarse del registro.
ejecutar trivy image --scanners vuln --severity HIGH,CRITICAL \
    --exit-code 10 --format json --output "$REPORTE/trivy.json" "$imagen"
