#!/usr/bin/env bash
# Uso: bash 13-revisar-cliente-ssh.sh HOST [CONFIG_SSH_CONFIABLE]
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/comun.bash"
host="${1:?Indicá host o alias de SSH}"
[[ "$host" != -* && "$host" != *[[:space:]]* ]] || { echo 'Host inválido.' >&2; exit 64; }
requerir ssh
crear_reporte ssh-cliente
opciones=()
if [[ $# -ge 2 ]]; then
    [[ -f "$2" && -r "$2" ]] || { echo 'Configuración ilegible.' >&2; exit 64; }
    opciones=(-F "$2")
fi
# -G no abre sesión; la configuración confiable puede tener Match exec/CanonicalizeHostname.
ssh -G "${opciones[@]}" "$host" > "$REPORTE/efectiva.txt"
# Política didáctica del cliente, NO configuración de sshd del servidor.
awk '
$1 == "stricthostkeychecking" && $2 != "true" && $2 != "yes" && $2 != "ask" { print "REVISAR: " $0; problemas++ }
$1 == "forwardagent" && $2 == "yes" { print "REVISAR: " $0; problemas++ }
$1 == "forwardx11" && $2 == "yes" { print "REVISAR: " $0; problemas++ }
END {if (!problemas) print "Sin coincidencias bajo esta política limitada."; exit (problemas > 0)}
' "$REPORTE/efectiva.txt" > "$REPORTE/resumen.txt" && codigo=0 || codigo=$?
cat "$REPORTE/resumen.txt"
exit "$codigo"
