#!/usr/bin/env bash
# Uso: bash 15-ranking-access-log.sh access.log [cantidad]
set -euo pipefail
archivo="${1:?Indicá un access.log Common/Combined}"
limite="${2:-10}"
[[ -r "$archivo" && -f "$archivo" ]] || { echo 'Log ilegible.' >&2; exit 64; }
[[ "$limite" =~ ^[0-9]{1,3}$ ]] || { echo 'Cantidad inválida.' >&2; exit 64; }
limite=$((10#$limite))
(( limite >= 1 && limite <= 100 )) || { echo 'Usá entre 1 y 100.' >&2; exit 64; }
# Common/Combined: el primer campo identifica al cliente registrado.
# No usar para CSV/JSON o formatos con columnas distintas.
LC_ALL=C awk 'NF {conteo[$1]++} END {for (cliente in conteo) print conteo[cliente], cliente}' \
    < "$archivo" | LC_ALL=C sort -k1,1nr -k2,2 | awk -v n="$limite" 'NR <= n'
