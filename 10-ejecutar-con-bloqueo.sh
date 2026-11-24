#!/usr/bin/env bash
# Uso: bash 10-ejecutar-con-bloqueo.sh ARCHIVO_LOCK COMANDO [ARGUMENTOS...]
set -euo pipefail
umask 077
lock="${1:?Indicá un archivo de bloqueo en una carpeta tuya}"
shift
(( $# > 0 )) || { echo 'Falta el comando.' >&2; exit 64; }
command -v flock >/dev/null || { echo 'Falta flock (util-linux).' >&2; exit 127; }
# Todos los participantes deben usar el mismo archivo; no borrarlo mientras corren.
# >> abre sin truncar el contenido.
exec 9>>"$lock"
if ! flock --nonblock 9; then
    echo 'Ya hay una ejecución usando ese bloqueo.' >&2
    exit 75
fi
# No usar eval: preserva cada argumento. El comando debe trabajar en primer plano.
codigo=0
"$@" || codigo=$?
printf 'Comando finalizado con código %s\n' "$codigo"
exit "$codigo"
