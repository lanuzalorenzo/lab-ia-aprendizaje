#!/usr/bin/env bash
# Mide si el mkdir que se le pasa es atomico: dos procesos crean el mismo
# camino a la vez y solo uno debe salir con exito.
#
# Uso: ./primitiva.sh [binario] [rondas] [raiz]
# Ejemplos: ./primitiva.sh mkdir 200 ; ./primitiva.sh /usr/bin/gnumkdir 200
set -u

MKDIR="${1:-mkdir}"
RONDAS="${2:-200}"
RAIZ="${3:-}"
if [ -n "$RAIZ" ]; then
  BASE="$RAIZ/primitiva-$$"
else
  BASE="$(mktemp -d)/primitiva"
fi
trap 'rm -rf "$BASE"' EXIT
mkdir -p "$BASE"

dobles=0
k=1
# Control: si el binario no crea un directorio, el cero de la carrera no
# significa atomicidad, sino que no se ha ejecutado nada.
if ! "$MKDIR" "$BASE/control" 2>/dev/null; then
  printf 'ERROR %s no crea directorios; no se puede medir\n' "$MKDIR" >&2
  exit 2
fi
rmdir "$BASE/control"
while [ "$k" -le "$RONDAS" ]; do
  d="$BASE/r-$k"
  mkdir "$d"
  ( "$MKDIR" "$d/i" 2>/dev/null; printf '%s' "$?" >> "$d/a" ) &
  ( "$MKDIR" "$d/i" 2>/dev/null; printf '%s' "$?" >> "$d/b" ) &
  wait
  if [ "$(cat "$d/a")" = 0 ] && [ "$(cat "$d/b")" = 0 ]; then
    dobles=$((dobles + 1))
  fi
  k=$((k + 1))
done

printf 'PRIMITIVA %-24s rondas=%s dos-creadores-con-exito=%s\n' \
  "$MKDIR" "$RONDAS" "$dobles"
