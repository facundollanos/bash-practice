#!/usr/bin/env bash
# Uso: bash 11-reporte-git.sh REPOSITORIO [CARPETA_REPORTES]
set -euo pipefail
umask 077
repo="${1:?Indicá un repositorio local}"
base="${2:-./reportes-git}"
# No se hace fetch ni se modifican ramas o commits.
git -C "$repo" rev-parse --git-dir >/dev/null
mkdir -p -- "$base"
reporte=$(mktemp -d "$base/git-$(date +%Y%m%d-%H%M%S)-XXXXXX")
git -C "$repo" status --short --branch > "$reporte/estado.txt"
# Sin diff completo para no copiar contenido sensible de los archivos.
git -C "$repo" diff --stat > "$reporte/cambios.txt"
git -C "$repo" diff --cached --stat > "$reporte/preparados.txt"
if git -C "$repo" rev-parse --verify HEAD >/dev/null 2>&1; then
    git -C "$repo" log -n 10 --format='%h %ad %s' --date=iso-strict > "$reporte/commits.txt"
else
    printf 'El repositorio todavía no tiene commits.\n' > "$reporte/commits.txt"
fi
printf 'Reporte local: %s\n' "$reporte"
