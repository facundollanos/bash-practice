#!/usr/bin/env bash
# Uso: bash 17-revisar-permisos-clave.sh CLAVE_PRIVADA
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/comun.bash"
ruta_clave_privada="${1:?Indicá una clave privada para revisar sus metadatos}"
[[ -f "$ruta_clave_privada" && ! -L "$ruta_clave_privada" ]] || { echo 'Se requiere archivo normal, no enlace simbólico.' >&2; exit 64; }
requerir stat
crear_reporte permisos-clave
permisos_archivo=$(stat --format='%a' -- "$ruta_clave_privada")
identificador_propietario=$(stat --format='%u' -- "$ruta_clave_privada")
identificador_usuario_actual=$(id -u)
permisos_numericos=$((8#$permisos_archivo))
cantidad_hallazgos=0
{
    printf 'Permisos octales: %s; UID propietario: %s\n' "$permisos_archivo" "$identificador_propietario"
    # 077 = permisos de grupo/otros. 07000 = bits especiales.
    if (( (permisos_numericos & 077) != 0 || (permisos_numericos & 07000) != 0 )); then
        echo 'REVISAR: permisos para grupo/otros o bits especiales.'
        cantidad_hallazgos=$((cantidad_hallazgos + 1))
    fi
    if [[ "$identificador_propietario" != "$identificador_usuario_actual" ]]; then
        echo 'REVISAR: el propietario no es el usuario actual.'
        cantidad_hallazgos=$((cantidad_hallazgos + 1))
    fi
    if (( (permisos_numericos & 0400) == 0 )); then
        echo 'REVISAR: falta lectura para el propietario.'
        cantidad_hallazgos=$((cantidad_hallazgos + 1))
    fi
    printf 'Hallazgos: %s\n' "$cantidad_hallazgos"
} > "$REPORTE/permisos.txt"
cat "$REPORTE/permisos.txt"
# No lee, copia ni modifica el contenido de la clave.
if (( cantidad_hallazgos > 0 )); then exit 1; fi
