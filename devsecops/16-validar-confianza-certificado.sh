#!/usr/bin/env bash
# Uso: bash 16-validar-confianza-certificado.sh CERTIFICADO_PEM CA_PEM HOSTNAME [INTERMEDIOS_PEM]
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/comun.bash"
ruta_certificado_servidor="${1:?Indicá certificado PEM del servidor}"
ruta_autoridades_confiables="${2:?Indicá archivo PEM de autoridades confiables}"
nombre_dns_esperado="${3:?Indicá hostname DNS esperado}"
for ruta_certificado in "$ruta_certificado_servidor" "$ruta_autoridades_confiables"; do
    [[ -f "$ruta_certificado" && -r "$ruta_certificado" ]] || { echo 'Archivo PEM ilegible.' >&2; exit 64; }
done
opciones_certificados_intermedios=()
if [[ $# -ge 4 ]]; then
    [[ -f "$4" && -r "$4" ]] || { echo 'Intermedios ilegibles.' >&2; exit 64; }
    opciones_certificados_intermedios=(-untrusted "$4")
fi
requerir openssl
crear_reporte confianza-certificado
codigo_verificacion=0
openssl verify -CAfile "$ruta_autoridades_confiables" -no-CApath -no-CAstore \
    -purpose sslserver -verify_hostname "$nombre_dns_esperado" \
    "${opciones_certificados_intermedios[@]}" "$ruta_certificado_servidor" \
    > "$REPORTE/verificacion.txt" 2> "$REPORTE/errores.txt" || codigo_verificacion=$?
cat "$REPORTE/verificacion.txt"
cat "$REPORTE/errores.txt" >&2
printf '%s\n' "$codigo_verificacion" > "$REPORTE/codigo-salida.txt"
exit "$codigo_verificacion"
