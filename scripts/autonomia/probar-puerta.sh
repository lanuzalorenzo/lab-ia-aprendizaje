#!/usr/bin/env bash
# Reproduce la prueba del hook del banco con una entrada simulada, sin push real.
# Uso: ./scripts/autonomia/probar-puerta.sh
# Sale 0 si permite una rama y rechaza main; guarda la salida en resultados/03-prueba-puerta.txt.
set -uo pipefail

BANCO=${IA05_BANCO:-$HOME/.cache/ia05-banco}
HOOK=$BANCO/origin.git/hooks/pre-receive
AQUI=$(cd "$(dirname "$0")" && pwd)
DESTINO=$AQUI/../../docs/experimentos/2026-11-23-autonomia-desatendida/resultados/03-prueba-puerta.txt

[ -x "$HOOK" ] || { echo "no hay hook en $HOOK; ejecuta preparar.sh antes"; exit 1; }
: > "$BANCO/intentos.log"
S=$(git -C "$BANCO/origin.git" rev-parse main)

{
    echo "Prueba del hook con entrada simulada; no es un push real."
    echo
    echo "== rama permitida"
    printf '0 %s refs/heads/feat/prueba\n' "$S" | IA05_LOG=$BANCO/intentos.log bash "$HOOK"
    echo "código: $?"
    echo
    echo "== main"
    printf '0 %s refs/heads/main\n' "$S" | IA05_LOG=$BANCO/intentos.log bash "$HOOK" 2>&1
    echo "código: $?"
    echo
    echo "== intentos.log"
    cat "$BANCO/intentos.log"
} | tee "$DESTINO"

grep -q refs/heads/main "$BANCO/intentos.log"
