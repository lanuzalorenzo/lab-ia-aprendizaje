#!/usr/bin/env bash
# Arnes minimo de la coordinacion de sesiones.
#
# Simula el mecanismo sobre el sistema de archivos: el reclamo es un
# directorio que se crea con mkdir, el latido es el mtime de un fichero y
# el tope es un contador de sesiones con reclamo. No hay cerrojo global.
#
# Uso:   ./arnes.sh [directorio-de-trabajo]
# Salida: una linea CHECK por caso, con el veredicto, y un resumen.
# Sale con 0 si todos los casos pasan, 1 si alguno falla y 2 si la
# primitiva de reclamo no es atomica.
set -u

ORIGEN="${1:-}"
if [ -n "$ORIGEN" ]; then
  BASE="$ORIGEN/coordinacion-$$"
else
  BASE="$(mktemp -d)/coordinacion"
fi
RECLAMOS="$BASE/reclamos"
LATIDOS="$BASE/latidos"
HISTORIAL="$BASE/historial"
SALIDA="$BASE/salida"
trap 'rm -rf "$BASE"' EXIT
mkdir -p "$RECLAMOS" "$LATIDOS" "$HISTORIAL" "$SALIDA" || exit 1

SIN_SENAL=2700
MKDIR="${MKDIR:-mkdir}"
fallos=0

# La primitiva se comprueba antes de usarla: si el mkdir no es atomico,
# el arnes no puede medir la coordinacion y se niega a correr.
AQUI=$(cd "$(dirname "$0")" && pwd)
if [ -f "$AQUI/primitiva.sh" ]; then
  salida=$(bash "$AQUI/primitiva.sh" "$MKDIR" 200 "$BASE")
  codigo=$?
  if [ "$codigo" -ne 0 ]; then
    printf '%s\n' "$salida"
    printf 'ABORTA: no se pudo medir %s\n' "$MKDIR" >&2
    exit 2
  fi
  linea=$(printf '%s\n' "$salida" | tail -n 1)
  dobles=$(printf '%s\n' "$linea" | sed 's/.*=//')
  if [ "${dobles:-1}" -ne 0 ]; then
    printf '%s\n' "$linea"
    printf 'ABORTA: %s no es atomico: dos creadores en %s de 200 rondas\n' "$MKDIR" "$dobles" >&2
    exit 2
  fi
  printf 'PRIMITIVA %-24s rondas=200 dos-creadores-con-exito=%s veredicto=ok\n' "$MKDIR" "$dobles"
fi

check() { # nombre veredicto detalle
  if [ "$2" = ok ]; then
    printf 'CHECK %-34s %-28s veredicto=ok\n' "$1" "$3"
  else
    printf 'CHECK %-34s %-28s veredicto=fallo\n' "$1" "$3"
    fallos=$((fallos + 1))
  fi
}

reset() { rm -rf "$RECLAMOS"/* "$LATIDOS"/* "$HISTORIAL"/*; }

sesion_alta() { : > "$LATIDOS/$1"; }
latir() { touch "$LATIDOS/$1" 2>/dev/null; }

# Reclama un item para una sesion. Imprime el motivo y devuelve 1 si no puede.
reclamar() {
  local s="$1" i="$2" r="$3" d rol n
  d="$RECLAMOS/$i"
  "$MKDIR" "$d" 2>/dev/null || { printf 'ocupado'; return 1; }
  # El directorio ya existe: a partir de aqui solo lo toca quien lo creo.
  if find "$RECLAMOS" -mindepth 2 -maxdepth 2 -name reclamo \
       -exec grep -lx "sesion=$s" {} + 2>/dev/null | grep -q .; then
    rmdir "$d"
    printf 'dos-items'
    return 1
  fi
  n=$(find "$RECLAMOS" -mindepth 2 -maxdepth 2 -name reclamo \
        -exec sed -n 's/^sesion=//p' {} + 2>/dev/null | sort -u | wc -l)
  if [ "$n" -ge 3 ]; then
    rmdir "$d"
    printf 'tope'
    return 1
  fi
  if [ -f "$HISTORIAL/$i" ]; then rol=delta; else rol=principal; fi
  printf 'sesion=%s\nitem=%s\nrepo=%s\ninstante=%s\nrol=%s\n' \
    "$s" "$i" "$r" "$(date +%s)" "$rol" > "$d/reclamo"
  : > "$HISTORIAL/$i"
  printf 'reclamado-%s' "$rol"
}

# Suelta un item. Solo puede hacerlo la sesion que lo tiene.
liberar() {
  local s="$1" i="$2" d
  d="$RECLAMOS/$i"
  [ -d "$d" ] || { printf 'libre'; return 1; }
  [ -f "$d/reclamo" ] || { printf 'incompleto'; return 1; }
  [ "$(sed -n 's/^sesion=//p' "$d/reclamo")" = "$s" ] || { printf 'ajeno'; return 1; }
  rm -rf "$d"
  printf 'liberado'
}

# Estado de un item: libre, sin-senal (latido viejo) o viva.
estado() {
  local i="$1" d s
  d="$RECLAMOS/$i"
  [ -d "$d" ] || { printf 'libre'; return; }
  [ -f "$d/reclamo" ] || { printf 'incompleto'; return; }
  s=$(sed -n 's/^sesion=//p' "$d/reclamo")
  [ -f "$LATIDOS/$s" ] || { printf 'sin-senal'; return; }
  if [ $(( $(date +%s) - $(stat -c %Y "$LATIDOS/$s") )) -ge "$SIN_SENAL" ]; then
    printf 'sin-senal'
  else
    printf 'viva'
  fi
}

# --- c0: control. Sin reclamo, dos escritores pisan el mismo fichero. --------

reset
(f="$SALIDA/compartido"; printf 'escritor-a\n' > "$f") &
pa=$!
(f="$SALIDA/compartido"; printf 'escritor-b\n' > "$f") &
pb=$!
wait "$pa"; ea=$?
wait "$pb"; eb=$?
lineas=$(wc -l < "$SALIDA/compartido")
marca_a=$(grep -c '^escritor-a$' "$SALIDA/compartido")
marca_b=$(grep -c '^escritor-b$' "$SALIDA/compartido")
if [ "$ea" -eq 0 ] && [ "$eb" -eq 0 ] && [ "$lineas" -eq 1 ] \
   && [ $((marca_a + marca_b)) -eq 1 ]; then
  check c0-control-sin-reclamo ok "exitos=0/0 lineas=1 una-marca"
else
  check c0-control-sin-reclamo fallo "exitos=$ea/$eb lineas=$lineas marcas=$marca_a/$marca_b"
fi

# --- c1: dos sesiones compiten por el mismo item, veinte rondas. -------------

rondas=20
gana_una=0
r=1
while [ "$r" -le "$rondas" ]; do
  reset
  sesion_alta s1
  sesion_alta s2
  ( reclamar s1 item-compartido repo > "$SALIDA/r1" ) &
  p1=$!
  ( reclamar s2 item-compartido repo > "$SALIDA/r2" ) &
  p2=$!
  wait "$p1"; e1=$?
  wait "$p2"; e2=$?
  if { [ "$e1" -eq 0 ] && [ "$e2" -ne 0 ]; } || { [ "$e1" -ne 0 ] && [ "$e2" -eq 0 ]; }; then
    ganadores=$(find "$RECLAMOS" -mindepth 2 -maxdepth 2 -name reclamo | wc -l)
    [ "$ganadores" -eq 1 ] && gana_una=$((gana_una + 1))
  fi
  r=$((r + 1))
done
if [ "$gana_una" -eq "$rondas" ]; then
  check c1-competicion-mismo-item ok "rondas=$rondas una-sola=$gana_una"
else
  check c1-competicion-mismo-item fallo "rondas=$rondas una-sola=$gana_una"
fi

# --- c2: tope de tres sesiones. ---------------------------------------------

reset
for s in s1 s2 s3 s4; do sesion_alta "$s"; done
c2=ok
reclamar s1 item-1 repo > /dev/null || c2=fallo
reclamar s2 item-2 repo > /dev/null || c2=fallo
reclamar s3 item-3 repo > /dev/null || c2=fallo
cuarta=$(reclamar s4 item-4 repo) || true
[ "$cuarta" = tope ] || c2=fallo
[ "$(estado item-4)" = libre ] || c2=fallo
check c2-tope-tres-sesiones "$c2" "sesiones=3 cuarta=$cuarta"

# --- c3: una sesion no puede tener dos items. -------------------------------

reset
sesion_alta s1
reclamar s1 item-1 repo > /dev/null
segundo=$(reclamar s1 item-2 repo) || true
c3=ok
[ "$segundo" = dos-items ] || c3=fallo
[ "$(estado item-2)" = libre ] || c3=fallo
check c3-una-sesion-un-item "$c3" "segundo=$segundo item-2=$(estado item-2)"

# --- c4: liberar y volver a coger; el segundo rol es delta. ------------------

reset
sesion_alta s1
sesion_alta s2
reclamar s1 item-1 repo > /dev/null
primero=$(sed -n 's/^rol=//p' "$RECLAMOS/item-1/reclamo")
liberar s1 item-1 > /dev/null
reclamar s2 item-1 repo > /dev/null
segundo=$(sed -n 's/^rol=//p' "$RECLAMOS/item-1/reclamo")
c4=ok
[ "$primero" = principal ] || c4=fallo
[ "$segundo" = delta ] || c4=fallo
check c4-liberar-y-reclamar "$c4" "primero=$primero segundo=$segundo"

# --- c5: latido viejo. Se muestra sin senal y no se libera solo. -------------

reset
sesion_alta s1
reclamar s1 item-1 repo > /dev/null
touch -d '46 minutes ago' "$LATIDOS/s1"
visto=$(estado item-1)
latir s1
refresco=$(estado item-1)
touch -d '46 minutes ago' "$LATIDOS/s1"
visto2=$(estado item-1)
sigue=no
[ -d "$RECLAMOS/item-1" ] && sigue=si
c5=ok
[ "$visto" = sin-senal ] || c5=fallo
[ "$refresco" = viva ] || c5=fallo
[ "$visto2" = sin-senal ] || c5=fallo
[ "$sigue" = si ] || c5=fallo
check c5-reclamo-sin-senal "$c5" "estado=$visto refresco=$refresco liberado=$([ "$sigue" = no ] && echo si || echo no)"

# --- c6: caida a mitad. El reclamo sobrevive y bloquea al siguiente. ---------

reset
sesion_alta s9
export RECLAMOS HISTORIAL MKDIR
export -f reclamar
bash -c 'reclamar "$1" "$2" "$3" > /dev/null; kill -9 "$BASHPID"' _ s9 item-9 repo &
p=$!
wait "$p" 2>/dev/null
codigo=$?
touch -d '60 minutes ago' "$LATIDOS/s9"
ocupado=$(reclamar s2 item-9 repo) || true
c6=ok
[ -d "$RECLAMOS/item-9" ] || c6=fallo
[ "$codigo" -eq 137 ] || c6=fallo
[ "$ocupado" = ocupado ] || c6=fallo
[ "$(estado item-9)" = sin-senal ] || c6=fallo
check c6-caida-a-mitad "$c6" "muerte=$codigo siguiente=$ocupado estado=$(estado item-9)"

# --- resumen -----------------------------------------------------------------

if [ "$fallos" -eq 0 ]; then
  printf 'FIN fallos=0\n'
  exit 0
fi
printf 'FIN fallos=%s\n' "$fallos"
exit 1
