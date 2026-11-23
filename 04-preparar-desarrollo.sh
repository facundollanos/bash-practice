#!/usr/bin/env bash
# Uso: ./04-preparar-desarrollo.sh /ruta/al/proyecto
set -euo pipefail
proyecto="${1:?Uso: $0 /ruta/al/proyecto}"
cd -- "$proyecto"
command -v docker >/dev/null
docker compose version >/dev/null
# Crear configuración inicial sin sobrescribir una existente.
if [[ ! -e .env && -f .env.example ]]; then
    cp -n -- .env.example .env
    printf 'Se creó .env: completá sus valores y volvé a ejecutar.\n'
    exit 1
fi
docker compose config --quiet
mkdir -p logs tmp
docker compose up --detach --build --wait --wait-timeout 120
docker compose ps
