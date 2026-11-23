# Funciones compartidas. Se carga con source; no ejecutar directamente.
set -euo pipefail
umask 077
requerir() {
    command -v "$1" >/dev/null || {
        printf 'Falta la herramienta: %s. Consultá README.md.\n' "$1" >&2
        exit 127
    }
}
crear_reporte() {
    local base="${REPORT_DIR:-$SCRIPT_DIR/reportes}"
    mkdir -p -- "$base"
    REPORTE=$(mktemp -d "$base/$1-$(date +%Y%m%d-%H%M%S)-XXXXXX")
    REPORTE=$(cd -- "$REPORTE" && pwd -P)
    printf 'Reportes: %s\n' "$REPORTE"
}
ejecutar() {
    local codigo=0
    # Un fallo esperado del escáner no debe impedir informar dónde está el reporte.
    "$@" || codigo=$?
    printf '%s\n' "$codigo" > "$REPORTE/codigo-salida.txt"
    printf 'Código de salida de la herramienta: %s\n' "$codigo"
    return "$codigo"
}
