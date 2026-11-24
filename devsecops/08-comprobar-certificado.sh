#!/usr/bin/env bash
# Uso: bash 08-comprobar-certificado.sh certificado.pem [dias]
# Inspección local del certificado, sin conexión de red.
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/comun.bash"
certificado="${1:?Indicá certificado PEM, no clave privada}"
dias="${2:-30}"
[[ -r "$certificado" && -f "$certificado" ]] || { echo 'Certificado ilegible.' >&2; exit 64; }
[[ "$dias" =~ ^[0-9]{1,4}$ ]] || { echo 'Días inválidos (0 a 3650).' >&2; exit 64; }
dias=$((10#$dias))
(( dias <= 3650 )) || { echo 'Máximo: 3650 días.' >&2; exit 64; }
requerir openssl
crear_reporte certificado
# Parsear primero distingue un archivo inválido de una alerta de vencimiento.
if ! openssl x509 -in "$certificado" -noout -subject -issuer -dates \
    > "$REPORTE/certificado.txt" 2> "$REPORTE/errores.txt"; then
    echo 'No se pudo leer un certificado X.509 PEM.' >&2; exit 2
fi
cat "$REPORTE/certificado.txt"
if openssl x509 -in "$certificado" -noout -checkend "$((dias * 86400))" \
    >> "$REPORTE/certificado.txt" 2>> "$REPORTE/errores.txt"; then
    printf 'OK: no vence dentro de %s días.\n' "$dias"
else
    printf 'ALERTA: ya venció o vence dentro de %s días.\n' "$dias" >&2
    exit 1
fi
# No verifica confianza de la cadena, hostname, revocación ni notBefore.
