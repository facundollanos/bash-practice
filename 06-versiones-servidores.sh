#!/usr/bin/env bash
# Uso: ./06-versiones-servidores.sh servidores.txt clave.pem [reporte.tsv]
# Una entrada usuario@host por línea. Hosts conocidos y claves ya configurados.
set -euo pipefail
hosts="${1:?Uso: $0 servidores.txt clave.pem [reporte.tsv]}"
clave="${2:?Indicá la clave privada SSH}"
reporte="${3:-./versiones.tsv}"
[[ -r "$hosts" && -r "$clave" ]] || { printf 'Archivo de hosts o clave ilegible.\n' >&2; exit 1; }
# No sobrescribir un reporte anterior ni los archivos de entrada.
set -o noclobber
exec 3>"$reporte"
printf 'host\testado\tversion_kernel\n' >&3
fallos=0
while IFS= read -r host || [[ -n "$host" ]]; do
    [[ -z "$host" || "$host" == \#* ]] && continue
    [[ "$host" != -* && "$host" != *[[:space:]]* ]] || {
        printf 'Host inválido: %s\n' "$host" >&2
        fallos=$((fallos + 1))
        continue
    }
    # -n evita que SSH consuma las siguientes líneas de servidores.txt.
    if version=$(ssh -n -i "$clave" -o BatchMode=yes \
        -o StrictHostKeyChecking=yes -o ConnectTimeout=5 \
        -o ServerAliveInterval=5 -o ServerAliveCountMax=2 \
        "$host" 'uname -r'); then
        printf '%s\tOK\t%s\n' "$host" "$version" >&3
    else
        printf '%s\tERROR\t-\n' "$host" >&3
        fallos=$((fallos + 1))
    fi
done < "$hosts"
printf 'Reporte: %s. Fallos: %s\n' "$reporte" "$fallos"
if (( fallos > 0 )); then exit 1; fi
