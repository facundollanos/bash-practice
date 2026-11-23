#!/usr/bin/env bash
# Uso: ./07-comprobar-disco.sh [ruta] [umbral-porcentaje]
set -euo pipefail
ruta="${1:-/}"
umbral="${2:-80}"
[[ "$umbral" =~ ^[0-9]{1,3}$ ]] || { printf 'Umbral inválido.\n' >&2; exit 1; }
umbral=$((10#$umbral))
(( umbral >= 1 && umbral <= 100 )) || { printf 'Usá un umbral entre 1 y 100.\n' >&2; exit 1; }
# En GNU/Linux, --output=pcent obtiene únicamente la columna de porcentaje.
uso=$(LC_ALL=C df --output=pcent -- "$ruta" | awk 'NR == 2 {gsub(/[%[:space:]]/, ""); print}')
[[ "$uso" =~ ^[0-9]+$ ]] || { printf 'No se pudo interpretar df.\n' >&2; exit 1; }
printf 'Ruta: %s | Uso: %s%% | Umbral: %s%%\n' "$ruta" "$uso" "$umbral"
if (( uso >= umbral )); then
    printf 'ALERTA: se alcanzó el umbral de disco.\n' >&2
    exit 1
fi
printf 'OK: espacio dentro del umbral.\n'
