#!/usr/bin/env bash
# Uso: bash 16-comparar-puertos.sh crear BASELINE
#      bash 16-comparar-puertos.sh comparar BASELINE
set -euo pipefail
umask 077
modo="${1:?Usá crear o comparar}"
base="${2:?Indicá archivo baseline}"
[[ "$modo" == crear || "$modo" == comparar ]] || { echo 'Modo inválido.' >&2; exit 64; }
actual=$(mktemp)
trap 'rm -f -- "$actual"' EXIT
# Solo endpoints locales TCP en escucha; se omiten PID y contadores cambiantes.
LC_ALL=C ss -Hltn | awk '{print $4}' | LC_ALL=C sort -u > "$actual"
if [[ "$modo" == crear ]]; then
    # noclobber evita reemplazar una baseline por accidente.
    (set -o noclobber; cat "$actual" > "$base")
    printf 'Baseline creada: %s\n' "$base"
else
    [[ -f "$base" && -r "$base" ]] || { echo 'Baseline ilegible.' >&2; exit 64; }
    # diff: 0 iguales, 1 cambios, 2 error. No reemplaza la baseline.
    diff -u -- "$base" "$actual"
fi
