#!/usr/bin/env bash
# Uso: bash 12-resumir-log.sh app.log
set -euo pipefail
archivo="${1:?Indicá un log de texto}"
[[ -f "$archivo" && -r "$archivo" ]] || { echo 'Log ilegible.' >&2; exit 64; }
# Una línea puede contribuir a más de una categoría.
# Son palabras clave, no una interpretación del nivel real de cada evento.
LC_ALL=C awk '
{
    total++
    linea = tolower($0)
    if (linea ~ /(^|[^a-z])(error|fatal)([^a-z]|$)/) errores++
    if (linea ~ /(^|[^a-z])(warn|warning)([^a-z]|$)/) avisos++
    if (linea ~ /(^|[^a-z])info([^a-z]|$)/) info++
}
END {
    printf "Líneas: %d\nCon ERROR/FATAL: %d\nCon WARN/WARNING: %d\nCon INFO: %d\n", total, errores, avisos, info
}' < "$archivo"
