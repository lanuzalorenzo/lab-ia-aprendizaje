#!/usr/bin/env bash
# Levanta el banco de pruebas, ejecuta la batería y guarda la salida en bruto.
# Uso: ./lanzar.sh [carpeta-de-resultados]
# Sale distinto de 0 si algo del montaje falla o si alguna comprobación falla.
set -uo pipefail

AQUI=$(cd "$(dirname "$0")" && pwd)
SALIDA=${1:-"$AQUI/resultados"}
ETIQUETA=experimento=contencion-agente
SUFIJO=$$
RED_INTERNA=contencion-interna-$SUFIJO
RED_SALIDA=contencion-salida-$SUFIJO
IMAGEN=contencion-agente:local
IMAGEN_INFRA=python:3.12-alpine
NOMBRE_PROXY=contencion-proxy-$SUFIJO
NOMBRE_ECO=contencion-eco-$SUFIJO
TOKEN=token-de-prueba-no-es-un-secreto
RAIZ_REPO=$(git -C "$AQUI" rev-parse --show-toplevel 2>/dev/null) \
    || RAIZ_REPO=""

# Aislamiento común a la batería y a la inspección: una sola definición.
BANDERAS=(
    --read-only
    --tmpfs /tmp:rw,noexec,nosuid,size=64m
    --user 1000:1000
    --cap-drop ALL
    --security-opt no-new-privileges
    --pids-limit 128
    --memory 256m --memory-swap 256m
    --cpus 1
)

DIR_TEMPORAL=$(mktemp -d)
CONTADOR=""
fail() { echo "ERROR: $*" >&2; exit 1; }

# Borra lo de esta pasada (etiqueta con PID), nunca lo de otra.
limpiar() {
    local ids
    ids=$(docker ps -aq --filter "label=pasada=$SUFIJO" 2>/dev/null)
    [ -n "$ids" ] && docker rm -f $ids >/dev/null 2>&1
    ids=$(docker network ls -q --filter "label=pasada=$SUFIJO" 2>/dev/null)
    [ -n "$ids" ] && docker network rm $ids >/dev/null 2>&1
    [ -n "$CONTADOR" ] && rm -rf "$CONTADOR"
    rm -rf "$DIR_TEMPORAL"
}
trap limpiar EXIT
trap 'limpiar; exit 130' INT TERM

command -v docker >/dev/null 2>&1 || fail "docker no está disponible"
[ -n "$RAIZ_REPO" ] || fail "no se encontró la raíz del repositorio; ejecútalo dentro del clon"
mkdir -p "$SALIDA"
rm -f "$SALIDA"/0[0-9]-*.txt   # solo los artefactos de este experimento

# La credencial va en un fichero que solo lee el proxy: no aparece en `docker inspect`
# ni en /proc/1/environ del host, que es donde queda una variable de contenedor.
printf '%s' "$TOKEN" > "$DIR_TEMPORAL/token"
chmod 600 "$DIR_TEMPORAL/token"

echo "== Construcción de la imagen ==" | tee "$SALIDA/00-preparacion.txt"
docker build -q -t "$IMAGEN" -f "$AQUI/Dockerfile.agente" "$AQUI" >>"$SALIDA/00-preparacion.txt" 2>&1 \
    || fail "la imagen no se construyó"
echo "imagen: $(docker image inspect -f '{{.Id}}' "$IMAGEN")" | tee -a "$SALIDA/00-preparacion.txt"

echo "== Redes ==" | tee -a "$SALIDA/00-preparacion.txt"
docker network create --internal --label "$ETIQUETA" --label "pasada=$SUFIJO" "$RED_INTERNA" >>"$SALIDA/00-preparacion.txt" 2>&1 \
    || fail "la red interna no se creó"
docker network create --label "$ETIQUETA" --label "pasada=$SUFIJO" "$RED_SALIDA" >>"$SALIDA/00-preparacion.txt" 2>&1 \
    || fail "la red con salida no se creó"

# El destino y el proxy viven en la red con salida; el agente, en la interna.
docker run -d --name "$NOMBRE_ECO" --label "$ETIQUETA" --label "pasada=$SUFIJO" --network "$RED_SALIDA" \
    --network-alias eco --entrypoint python3 \
    -v "$AQUI/eco.py:/eco.py:ro" "$IMAGEN_INFRA" /eco.py 9000 >>"$SALIDA/00-preparacion.txt" 2>&1 \
    || fail "el servicio de destino no arrancó"

docker run -d --name "$NOMBRE_PROXY" --label "$ETIQUETA" --label "pasada=$SUFIJO" --network "$RED_SALIDA" \
    --entrypoint python3 \
    -e PERMITIDOS=eco:9000 -e TOKEN_FICHERO=/run/token \
    -v "$AQUI/proxy.py:/proxy.py:ro" \
    -v "$DIR_TEMPORAL/token:/run/token:ro" \
    "$IMAGEN_INFRA" /proxy.py 8080 >>"$SALIDA/00-preparacion.txt" 2>&1 \
    || fail "el proxy no arrancó"

# El proxy también entra en la red interna: es el único camino del agente.
docker network connect --alias proxy "$RED_INTERNA" "$NOMBRE_PROXY" >>"$SALIDA/00-preparacion.txt" 2>&1 \
    || fail "el proxy no se conectó a la red interna"

listo=no
for _ in $(seq 1 30); do
    if docker logs "$NOMBRE_PROXY" 2>&1 | grep -q 'PROXY escuchando'; then listo=si; break; fi
    sleep 1
done
[ "$listo" = si ] || fail "el proxy no anunció que escucha en 30 s"
docker logs "$NOMBRE_PROXY" 2>&1 | head -1 | tee -a "$SALIDA/00-preparacion.txt"

# La variable existe en el host y no se pasa al contenedor: así se comprueba
# que Docker no la propaga por su cuenta.
export TOKEN_DEL_HOST="$TOKEN"

echo "== Batería dentro del contenedor ==" | tee "$SALIDA/01-bateria.txt"
docker run --rm -i --name "agente-bateria-$SUFIJO" --label "$ETIQUETA" --label "pasada=$SUFIJO" \
    --network "$RED_INTERNA" "${BANDERAS[@]}" \
    -e HOME=/tmp \
    -e TESTIGO=visible \
    -e HTTP_PROXY=http://proxy:8080 -e HTTPS_PROXY=http://proxy:8080 \
    -v "$RAIZ_REPO:/repo:ro" \
    "$IMAGEN" sh -s < "$AQUI/pruebas.sh" 2>&1 | tee -a "$SALIDA/01-bateria.txt"
codigo_bateria=${PIPESTATUS[0]}
echo "codigo-salida=$codigo_bateria" | tee -a "$SALIDA/01-bateria.txt"

echo "== Límite de memoria (se espera 137 por OOM) ==" | tee "$SALIDA/02-memoria.txt"
docker run --name "agente-memoria-$SUFIJO" --label "$ETIQUETA" --label "pasada=$SUFIJO" \
    --network none --read-only --tmpfs /tmp:rw,size=256m \
    --user 1000:1000 --cap-drop ALL --security-opt no-new-privileges \
    --memory 128m --memory-swap 128m \
    -e HOME=/tmp \
    "$IMAGEN" sh -c 'dd if=/dev/zero of=/tmp/relleno bs=1M count=200' >>"$SALIDA/02-memoria.txt" 2>&1
codigo_memoria=$?
oom=$(docker inspect -f '{{.State.OOMKilled}}' "agente-memoria-$SUFIJO" 2>&1)
docker rm -f "agente-memoria-$SUFIJO" >/dev/null 2>&1
echo "codigo-salida=$codigo_memoria oom-killed=$oom" | tee -a "$SALIDA/02-memoria.txt"

echo "== Persistencia: escribir y volver a entrar ==" | tee "$SALIDA/03-persistencia.txt"
docker run --rm --name "agente-huella-$SUFIJO" --label "$ETIQUETA" --label "pasada=$SUFIJO" \
    --network none --read-only --tmpfs /tmp:rw,size=16m \
    --user 1000:1000 --cap-drop ALL "$IMAGEN" sh -c 'echo huella > /tmp/huella' >>"$SALIDA/03-persistencia.txt" 2>&1
docker run --rm --name "agente-huella2-$SUFIJO" --label "$ETIQUETA" --label "pasada=$SUFIJO" \
    --network none --read-only --tmpfs /tmp:rw,size=16m \
    --user 1000:1000 --cap-drop ALL "$IMAGEN" sh -c 'cat /tmp/huella' >>"$SALIDA/03-persistencia.txt" 2>&1
codigo_huella=$?
echo "codigo-salida=$codigo_huella (1 significa que la huella ya no existe)" | tee -a "$SALIDA/03-persistencia.txt"

echo "== Límite de procesos: 200 peticiones con tope de 32 ==" | tee "$SALIDA/04-procesos.txt"
CONTADOR=$(mktemp -d)
chmod 777 "$CONTADOR"
docker run --rm --name "agente-pids-$SUFIJO" --label "$ETIQUETA" --label "pasada=$SUFIJO" \
    --network none --read-only --tmpfs /tmp:rw,size=16m \
    --user 1000:1000 --cap-drop ALL \
    --pids-limit 32 \
    -v "$CONTADOR:/contador:rw" \
    "$IMAGEN" sh -c 'i=0; while [ $i -lt 200 ]; do sleep 300 >/dev/null 2>&1 & i=$((i+1)); echo "$i" >> /contador/log 2>/dev/null; done' \
    >>"$SALIDA/04-procesos.txt" 2>&1
codigo_pids=$?
arrancados=$(wc -l < "$CONTADOR/log" 2>/dev/null || echo 0)
rm -rf "$CONTADOR"
echo "pedidos=200 arrancados=$arrancados tope=32 codigo-salida=$codigo_pids" | tee -a "$SALIDA/04-procesos.txt"

echo "== Pausa y reanudación: ¿sobrevive el estado en memoria? ==" | tee "$SALIDA/05-pausa.txt"
docker run -d --name "agente-pausa-$SUFIJO" --label "$ETIQUETA" --label "pasada=$SUFIJO" \
    --network none --read-only --tmpfs /tmp:rw,size=16m \
    --user 1000:1000 --cap-drop ALL \
    "$IMAGEN" sh -c 'echo estado-en-memoria > /tmp/estado; sleep 120' >>"$SALIDA/05-pausa.txt" 2>&1
sleep 2
docker pause "agente-pausa-$SUFIJO" >>"$SALIDA/05-pausa.txt" 2>&1
sleep 1
docker unpause "agente-pausa-$SUFIJO" >>"$SALIDA/05-pausa.txt" 2>&1
echo "contenido-tras-reanudar: $(docker exec "agente-pausa-$SUFIJO" cat /tmp/estado 2>&1)" | tee -a "$SALIDA/05-pausa.txt"
docker rm -f "agente-pausa-$SUFIJO" >/dev/null 2>&1

echo "== Coste de arranque (5 ejecuciones) ==" | tee "$SALIDA/06-arranque.txt"
for i in 1 2 3 4 5; do
    inicio=$(date +%s%N)
    docker run --rm --name "agente-arranque-$SUFIJO" --label "$ETIQUETA" --label "pasada=$SUFIJO" \
        --network none --read-only --user 1000:1000 \
        --cap-drop ALL "$IMAGEN" true >/dev/null 2>&1
    fin=$(date +%s%N)
    echo "ejecucion=$i ms=$(( (fin - inicio) / 1000000 ))" | tee -a "$SALIDA/06-arranque.txt"
done

echo "== Configuración efectiva del contenedor ==" | tee "$SALIDA/07-limites.txt"
docker run -d --name "agente-limites-$SUFIJO" --label "$ETIQUETA" --label "pasada=$SUFIJO" \
    --network "$RED_INTERNA" "${BANDERAS[@]}" "$IMAGEN" sleep 30 >/dev/null 2>&1 \
    || fail "el contenedor de inspección no arrancó"
docker inspect "agente-limites-$SUFIJO" --format \
    'Pids={{.HostConfig.PidsLimit}} Memoria={{.HostConfig.Memory}} Swap={{.HostConfig.MemorySwap}} Cpu={{.HostConfig.NanoCpus}} CapDrop={{.HostConfig.CapDrop}} SecurityOpt={{.HostConfig.SecurityOpt}} Red={{.HostConfig.NetworkMode}} SoloLectura={{.HostConfig.ReadonlyRootfs}}' \
    | tee -a "$SALIDA/07-limites.txt"
docker rm -f "agente-limites-$SUFIJO" >/dev/null 2>&1

echo "== Registro del proxy ==" | tee "$SALIDA/08-proxy.txt"
docker logs "$NOMBRE_PROXY" 2>&1 | tee -a "$SALIDA/08-proxy.txt"

echo "== Credencial: ¿qué pasa si el fichero llega al contenedor? ==" | tee "$SALIDA/09-token.txt"
echo "permisos-en-el-host: $(stat -c '%a %u' "$DIR_TEMPORAL/token")" | tee -a "$SALIDA/09-token.txt"
for uid in 1000 1500; do
    docker run --rm --name "agente-token-$uid-$SUFIJO" --label "$ETIQUETA" --label "pasada=$SUFIJO" \
        --network none --read-only --tmpfs /tmp:rw,size=16m \
        --user "$uid:$uid" --cap-drop ALL \
        -v "$DIR_TEMPORAL/token:/run/token:ro" \
        "$IMAGEN" cat /run/token >>"$SALIDA/09-token.txt" 2>&1
    codigo_token=$?
    printf '\n' >>"$SALIDA/09-token.txt"
    echo "uid=$uid codigo-salida=$codigo_token" | tee -a "$SALIDA/09-token.txt"
done

if [ "$codigo_bateria" -ne 0 ]; then
    echo "La batería terminó con $codigo_bateria comprobaciones fallidas." >&2
    exit 1
fi
echo "Fin. Resultados en $SALIDA"
