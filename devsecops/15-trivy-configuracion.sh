#!/usr/bin/env bash
# Uso: bash 15-trivy-configuracion.sh DIRECTORIO_INFRAESTRUCTURA
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/comun.bash"
directorio_infraestructura="${1:?Indicá el directorio de configuraciones}"
[[ -d "$directorio_infraestructura" ]] || { echo 'Directorio inexistente.' >&2; exit 64; }
directorio_infraestructura=$(realpath -e -- "$directorio_infraestructura")
requerir trivy
crear_reporte trivy-configuracion
ruta_reporte_json="$REPORTE/trivy-configuracion.json"
# Analiza configuraciones: no aplica Terraform ni despliega Kubernetes.
ejecutar trivy config --severity HIGH,CRITICAL --exit-code 10 \
    --format json --output "$ruta_reporte_json" "$directorio_infraestructura"
