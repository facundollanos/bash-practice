#!/usr/bin/env bash
# Uso: ./05-recolectar-diagnostico.sh [carpeta-destino]
set -euo pipefail
umask 077
base="${1:-./diagnosticos}"
mkdir -p "$base"
salida=$(mktemp -d "$base/diagnostico-$(date +%Y%m%d-%H%M%S)-XXXXXX")
fallos=0
capturar() {
    local nombre="$1"
    shift
    if ! "$@" >"$salida/$nombre.txt" 2>"$salida/$nombre.error.txt"; then
        printf 'Falló la consulta: %s\n' "$nombre" >&2
        fallos=$((fallos + 1))
    fi
}
capturar fecha date --iso-8601=seconds
capturar disco df -h
capturar memoria free -h
capturar procesos ps -eo user,pid,ppid,pcpu,pmem,comm --sort=-pcpu
capturar puertos ss -ltn
capturar logs journalctl --since '30 minutes ago' --lines=200 --no-pager
printf 'Guardado en %s. Consultas fallidas: %s\n' "$salida" "$fallos"
if (( fallos > 0 )); then exit 1; fi
