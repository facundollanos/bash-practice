#!/usr/bin/env bash
# PostgreSQL: ./03-backup-y-migracion.sh migracion.sql [carpeta-backups]
# Conexión por PGHOST, PGPORT, PGUSER y PGDATABASE. Contraseña por .pgpass.
set -euo pipefail
umask 077
sql="${1:?Uso: $0 migracion.sql [carpeta-backups]}"
destino="${2:-./backups}"
: "${PGDATABASE:?Definí PGDATABASE}"
[[ -f "$sql" && -r "$sql" ]] || { printf 'SQL inexistente o ilegible.\n' >&2; exit 1; }
for herramienta in pg_dump pg_restore psql; do
    command -v "$herramienta" >/dev/null || { printf 'Falta %s\n' "$herramienta" >&2; exit 1; }
done
mkdir -p "$destino"
backup=$(mktemp "$destino/backup-$(date +%Y%m%d-%H%M%S)-XXXXXX.dump")
# Si el dump falla se elimina el archivo incompleto; si la migración falla,
# el backup completo se conserva.
if ! pg_dump --format=custom --file="$backup"; then
    rm -f -- "$backup"
    exit 1
fi
pg_restore --list "$backup" >/dev/null
printf 'Backup generado: %s\n' "$backup"
# --single-transaction exige SQL compatible con una transacción.
psql -X --set=ON_ERROR_STOP=1 --single-transaction --file="$sql"
printf 'Migración finalizada.\n'
