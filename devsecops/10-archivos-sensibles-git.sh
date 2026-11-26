#!/usr/bin/env bash
# Uso: bash 10-archivos-sensibles-git.sh RAIZ_REPOSITORIO
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/comun.bash"
repo="${1:?Indicá raíz del repositorio}"
requerir git
raiz=$(git -C "$repo" rev-parse --show-toplevel)
[[ "$(cd -- "$repo" && pwd -P)" == "$(cd -- "$raiz" && pwd -P)" ]] || {
    echo 'Indicá la raíz del repositorio.' >&2; exit 64;
}
crear_reporte archivos-sensibles
# Consulta el índice: incluye archivos preparados aunque aún no tengan commit.
git -C "$raiz" ls-files -z > "$REPORTE/versionados.nul"
hallazgos=0
while IFS= read -r -d '' ruta; do
    nombre="${ruta##*/}"
    case "$nombre" in
        .env.example|.env.sample|.env.template) continue ;;
        .env|.env.*|*.key|*.p12|*.pfx|*.pem|id_rsa|id_ed25519|*.tfstate|*.tfstate.*)
            printf '%q\n' "$ruta"
            hallazgos=$((hallazgos + 1)) ;;
    esac
done < "$REPORTE/versionados.nul" > "$REPORTE/revisar.txt"
cat "$REPORTE/revisar.txt"
printf 'Archivos a revisar: %s\n' "$hallazgos"
# Solo nombres; un .pem puede ser un certificado público, no una clave privada.
# No reemplaza Gitleaks ni revisa el historial o el contenido.
if (( hallazgos > 0 )); then exit 1; fi
