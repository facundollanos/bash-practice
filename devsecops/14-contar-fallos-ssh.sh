#!/usr/bin/env bash
# Uso: bash 14-contar-fallos-ssh.sh auth.log [umbral]
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/comun.bash"
archivo="${1:?Indicá un auth.log de OpenSSH}"
umbral="${2:-5}"
[[ -f "$archivo" && -r "$archivo" ]] || { echo 'Log ilegible.' >&2; exit 64; }
[[ "$umbral" =~ ^[0-9]{1,4}$ ]] || { echo 'Umbral inválido.' >&2; exit 64; }
umbral=$((10#$umbral))
(( umbral >= 1 )) || { echo 'El umbral debe ser mayor que cero.' >&2; exit 64; }
crear_reporte fallos-ssh
# Solo formato habitual sshd: Failed password/publickey ... from DIRECCION port N.
# No incluye journald JSON, PAM genérico, rotados ni eventos sin dirección.
LC_ALL=C awk '
/sshd(\[[0-9]+\])?:/ && /Failed (password|publickey) / {
    for (i=1; i<NF; i++) if ($i=="from" && $(i+2)=="port") {n[$(i+1)]++; break}
}
END {for (ip in n) print n[ip], ip}
' < "$archivo" | LC_ALL=C sort -k1,1nr -k2,2 > "$REPORTE/conteo.txt"
awk -v u="$umbral" '$1 >= u' "$REPORTE/conteo.txt" > "$REPORTE/alertas.txt"
cat "$REPORTE/conteo.txt"
# Cuenta TODO el archivo, no una ventana temporal; no bloquea direcciones.
if [[ -s "$REPORTE/alertas.txt" ]]; then
    printf 'Hay direcciones con al menos %s fallos; revisar alertas.txt.\n' "$umbral" >&2
    exit 1
fi
printf 'Sin coincidencias que superen el umbral (no implica ausencia de ataques).\n'
