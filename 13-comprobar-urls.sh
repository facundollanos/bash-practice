#!/usr/bin/env bash
# Uso: bash 13-comprobar-urls.sh urls.txt
set -euo pipefail
lista="${1:?Indicá archivo con una URL por línea}"
[[ -f "$lista" && -r "$lista" ]] || { echo 'Lista ilegible.' >&2; exit 64; }
command -v curl >/dev/null || { echo 'Falta curl.' >&2; exit 127; }
fallos=0
total=0
printf 'HTTP\tSEGUNDOS\tURL\n'
while IFS= read -r url || [[ -n "$url" ]]; do
    url="${url%$'\r'}"
    [[ -z "$url" || "$url" == \#* ]] && continue
    total=$((total + 1))
    if [[ "$url" != http://?* && "$url" != https://?* ]] || [[ "$url" == *[[:space:]]* ]]; then
        printf 'URL inválida: %q\n' "$url" >&2
        fallos=$((fallos + 1))
        continue
    fi
    resultado=''
    if resultado=$(curl --silent --show-error --output /dev/null \
        --connect-timeout 3 --max-time 10 \
        --write-out '%{http_code}\t%{time_total}' "$url"); then
        codigo="${resultado%%$'\t'*}"
        if [[ "$codigo" != 2?? ]]; then fallos=$((fallos + 1)); fi
    else
        fallos=$((fallos + 1))
    fi
    printf '%s\t%s\n' "$resultado" "$url"
done < "$lista"
(( total > 0 )) || { echo 'La lista no contiene URLs.' >&2; exit 64; }
printf 'Consultadas: %s; fallidas: %s\n' "$total" "$fallos" >&2
if (( fallos > 0 )); then exit 1; fi
