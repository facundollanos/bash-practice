#!/usr/bin/env bash
# Uso: bash 03-detectar-secretos.sh /ruta/al/repositorio
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/comun.bash"
repo="${1:?Uso: $0 /ruta/al/repositorio}"
requerir git
requerir gitleaks
# Exigir la raíz del repositorio para que el alcance no sea ambiguo.
raiz=$(git -C "$repo" rev-parse --show-toplevel)
entrada=$(cd -- "$repo" && pwd -P)
[[ "$entrada" == "$(cd -- "$raiz" && pwd -P)" ]] || {
    printf 'Indicá la raíz del repositorio: %s\n' "$raiz" >&2; exit 64;
}
crear_reporte secretos
# --redact oculta valores; aun así el reporte es información privada.
# Analiza historial Git disponible, NO archivos sin commit ni ramas no descargadas.
ejecutar gitleaks git "$raiz" --redact --exit-code 10 \
    --report-format json --report-path "$REPORTE/gitleaks.json"
