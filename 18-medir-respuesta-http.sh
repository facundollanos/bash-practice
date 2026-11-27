#!/usr/bin/env bash
# Uso: bash 18-medir-respuesta-http.sh URL [CANTIDAD_MUESTRAS]
set -euo pipefail
url_objetivo="${1:?Indicá URL HTTP/HTTPS}"
cantidad_muestras="${2:-5}"
[[ "$url_objetivo" == http://?* || "$url_objetivo" == https://?* ]] || { echo 'URL inválida.' >&2; exit 64; }
[[ "$cantidad_muestras" =~ ^[0-9]{1,2}$ ]] || { echo 'Cantidad inválida.' >&2; exit 64; }
cantidad_muestras=$((10#$cantidad_muestras))
(( cantidad_muestras >= 1 && cantidad_muestras <= 20 )) || { echo 'Usá entre 1 y 20 muestras.' >&2; exit 64; }
command -v curl >/dev/null || { echo 'Falta curl.' >&2; exit 127; }
cantidad_fallos=0
printf 'MUESTRA\tHTTP\tDNS_S\tCONEXION_ACUM_S\tPRIMER_BYTE_ACUM_S\tTOTAL_S\n'
for (( numero_muestra=1; numero_muestra<=cantidad_muestras; numero_muestra++ )); do
    metricas_respuesta=''
    if metricas_respuesta=$(curl --silent --show-error --output /dev/null \
        --connect-timeout 3 --max-time 10 \
        --write-out '%{http_code}\t%{time_namelookup}\t%{time_connect}\t%{time_starttransfer}\t%{time_total}' \
        "$url_objetivo"); then
        codigo_respuesta_http="${metricas_respuesta%%$'\t'*}"
        if [[ "$codigo_respuesta_http" != 2?? ]]; then cantidad_fallos=$((cantidad_fallos + 1)); fi
    else
        cantidad_fallos=$((cantidad_fallos + 1))
    fi
    printf '%s\t%s\n' "$numero_muestra" "$metricas_respuesta"
    if (( numero_muestra < cantidad_muestras )); then sleep 1; fi
done
printf 'Muestras fallidas: %s\n' "$cantidad_fallos" >&2
if (( cantidad_fallos > 0 )); then exit 1; fi
