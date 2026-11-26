#!/usr/bin/env bash
# Uso: bash 12-revisar-headers.sh https://mi-web.example/
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/comun.bash"
url="${1:?Indicá URL HTTP/HTTPS propia o autorizada}"
[[ "$url" == http://?* || "$url" == https://?* ]] || { echo 'URL inválida.' >&2; exit 64; }
requerir curl
crear_reporte headers
# GET sin seguir redirecciones; no se desactiva la verificación TLS.
codigo=$(curl -sS --connect-timeout 5 --max-time 15 \
    --dump-header "$REPORTE/headers.txt" --output /dev/null \
    --write-out '%{http_code}' "$url")
printf 'HTTP: %s\n' "$codigo"
[[ "$codigo" == 2?? ]] || { echo 'Se requiere una respuesta 2xx; revisá URL o redirección.' >&2; exit 2; }
# Reiniciar en cada línea HTTP conserva solo el bloque final (ignora 1xx/CONNECT).
awk '/^HTTP\// {bloque=""; next} {bloque=bloque $0 "\n"} END {printf "%s", bloque}' \
    "$REPORTE/headers.txt" > "$REPORTE/headers-finales.txt"
faltantes=0
headers=(content-security-policy x-content-type-options referrer-policy)
if [[ "$url" == https://* ]]; then headers+=(strict-transport-security); fi
for header in "${headers[@]}"; do
    if grep -Eiq "^${header}:[[:space:]]*[^[:space:]]" "$REPORTE/headers-finales.txt"; then
        printf 'PRESENTE: %s\n' "$header"
    else
        printf 'REVISAR AUSENCIA: %s\n' "$header"
        faltantes=$((faltantes + 1))
    fi
done > "$REPORTE/resumen.txt"
cat "$REPORTE/resumen.txt"
# Presencia no garantiza un valor correcto; CSP puede no aplicar a APIs sin HTML.
if (( faltantes > 0 )); then exit 1; fi
