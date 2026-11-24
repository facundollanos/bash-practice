#!/usr/bin/env bash
# Uso: bash 06-checkov-iac.sh CARPETA [terraform|kubernetes|dockerfile|github_actions]
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/comun.bash"
carpeta="${1:?Indicá carpeta de infraestructura}"
framework="${2:-terraform}"
[[ -d "$carpeta" ]] || { echo 'Carpeta inexistente.' >&2; exit 64; }
case "$framework" in
    terraform|kubernetes|dockerfile|github_actions) ;;
    *) echo 'Framework no admitido por este ejemplo.' >&2; exit 64 ;;
esac
requerir checkov
crear_reporte checkov
# Se conserva el JSON incluso si Checkov encuentra incumplimientos.
codigo=0
checkov --directory "$carpeta" --framework "$framework" \
    --download-external-modules false --output json \
    > "$REPORTE/checkov.json" || codigo=$?
printf '%s\n' "$codigo" > "$REPORTE/codigo-salida.txt"
printf 'Checkov finalizó con código %s\n' "$codigo"
exit "$codigo"
