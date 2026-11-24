#!/usr/bin/env bash
# Uso: bash 09-descargar-verificado.sh URL ARCHIVO SHA256
set -euo pipefail
umask 077
url="${1:?Indicá URL HTTPS}"
destino="${2:?Indicá archivo de destino}"
esperado="${3:?Indicá SHA256 obtenido de una fuente confiable}"
[[ "$url" == https://?* && "$esperado" =~ ^[[:xdigit:]]{64}$ ]] || {
    echo 'Se requiere HTTPS y un SHA256 de 64 caracteres hexadecimales.' >&2; exit 64;
}
[[ ! -e "$destino" && ! -L "$destino" ]] || { echo 'El destino ya existe.' >&2; exit 64; }
carpeta=$(dirname -- "$destino")
[[ -d "$carpeta" ]] || { echo 'La carpeta destino no existe.' >&2; exit 64; }
temporal=$(mktemp "$carpeta/.descarga-XXXXXX")
trap 'rm -f -- "$temporal"' EXIT
curl --fail --silent --show-error --location \
    --proto '=https' --proto-redir '=https' \
    --connect-timeout 5 --max-time 120 --output "$temporal" "$url"
calculado=$(sha256sum < "$temporal")
calculado="${calculado%% *}"
[[ "$calculado" == "${esperado,,}" ]] || { echo 'SHA256 incorrecto: descarga descartada.' >&2; exit 1; }
# Enlace duro: publica el archivo completo sin sobrescribir un destino existente.
ln -- "$temporal" "$destino"
printf 'Descarga verificada: %s\n' "$destino"
