#!/usr/bin/env bash
# Uso: bash 19-ejecutar-scripts-paralelos.sh DIRECTORIO_REPORTES SCRIPT [SCRIPT...]
set -euo pipefail
umask 077
directorio_reportes="${1:?Indicá un directorio para reportes}"
shift
(( $# > 0 )) || { echo 'Indicá al menos un script Bash confiable.' >&2; exit 64; }
# Máximo dos scripts por lote. Cada script se ejecuta sin argumentos.
for ruta_script in "$@"; do
    [[ -f "$ruta_script" && -r "$ruta_script" ]] || { printf 'Script ilegible: %q\n' "$ruta_script" >&2; exit 64; }
done
mkdir -p -- "$directorio_reportes"
directorio_ejecucion=$(mktemp -d "$directorio_reportes/lote-XXXXXX")
cantidad_fallos=0
numero_tarea=0
identificadores_procesos=()
identificadores_tareas=()
esperar_lote() {
    local posicion_tarea codigo_salida_tarea
    for posicion_tarea in "${!identificadores_procesos[@]}"; do
        codigo_salida_tarea=0
        wait "${identificadores_procesos[$posicion_tarea]}" || codigo_salida_tarea=$?
        printf '%s\n' "$codigo_salida_tarea" > "$directorio_ejecucion/${identificadores_tareas[$posicion_tarea]}.codigo"
        if (( codigo_salida_tarea != 0 )); then cantidad_fallos=$((cantidad_fallos + 1)); fi
    done
    identificadores_procesos=()
    identificadores_tareas=()
}
for ruta_script in "$@"; do
    numero_tarea=$((numero_tarea + 1))
    printf '%s\t%q\n' "$numero_tarea" "$ruta_script" >> "$directorio_ejecucion/tareas.txt"
    bash -- "$ruta_script" > "$directorio_ejecucion/$numero_tarea.stdout" \
        2> "$directorio_ejecucion/$numero_tarea.stderr" &
    identificadores_procesos+=("$!")
    identificadores_tareas+=("$numero_tarea")
    if (( ${#identificadores_procesos[@]} == 2 )); then esperar_lote; fi
done
esperar_lote
printf 'Reportes: %s; tareas fallidas: %s\n' "$directorio_ejecucion" "$cantidad_fallos"
if (( cantidad_fallos > 0 )); then exit 1; fi
