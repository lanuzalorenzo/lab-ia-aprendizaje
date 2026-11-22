#!/usr/bin/env bash
#
# continuidad-local.sh — simulacro de continuidad de la IA local
# Proyecto: lab-ia-aprendizaje
#
# Comprueba que un cliente sin salida a Internet puede usar un modelo que ya
# está en disco. La red del equipo no se toca: el servidor y el cliente corren
# en una red Docker interna, sin puerta de enlace hacia Internet.
#
# Uso:
#   ./continuidad-local.sh preparar    # imagen y pesos (necesita red)
#   ./continuidad-local.sh simulacro   # inventario + corte + tareas + cliente
#   ./continuidad-local.sh restaurar   # copia de pesos, restauración y prueba
#
# Variables: IMAGEN, CLIENTE, BASE, MODELO, VOLUMEN, RED, SERVIDOR, COPIA_DIR.

set -euo pipefail

IMAGEN="${IMAGEN:-ollama/ollama:0.12.10}"
CLIENTE="${CLIENTE:-curlimages/curl:8.11.1}"
BASE="${BASE:-ubuntu:24.04}"
MODELO="${MODELO:-qwen2.5:3b}"
VOLUMEN="${VOLUMEN:-ollama-simulacro}"
RESTAURADO="${RESTAURADO:-ollama-restaurado}"
RED="${RED:-lab-drill}"
SERVIDOR="${SERVIDOR:-ollama-servidor}"
COPIA_DIR="${COPIA_DIR:-/tmp/opencode/simulacro}"
BINARIO_OPENCODE="${BINARIO_OPENCODE:-$HOME/.opencode/bin/opencode}"
OPCIONES="${OPCIONES:-responde solo con la palabra listo}"

fecha() { date -u +%FT%TZ; }
tamano() { numfmt --to=iec --suffix=B "$1"; }
raiz=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)

limpiar() { docker rm -f "$SERVIDOR" >/dev/null 2>&1 || true; }

exigir_imagenes() {
    for img in "$@"; do
        docker image inspect "$img" >/dev/null 2>&1 || {
            echo "falta la imagen $img: ejecuta antes $0 preparar" >&2
            exit 1
        }
    done
}

esperar_servicio() {
    for _ in $(seq 1 40); do
        docker exec "$SERVIDOR" ollama list >/dev/null 2>&1 && return 0
        sleep 1
    done
    echo "el servicio no arrancó" >&2
    return 1
}

red() {
    docker network create --internal "$RED" >/dev/null 2>&1 || true
    limpiar
    docker run -d --name "$SERVIDOR" --network "$RED" \
        -v "$VOLUMEN:/root/.ollama" "$IMAGEN" >/dev/null
    esperar_servicio
}

corte() {
    echo "### El corte es real: sin salida a Internet"
    echo '```'
    if docker run --rm --network "$RED" "$CLIENTE" \
        curl -sS -m 5 -o /dev/null https://example.com 2>&1; then
        echo 'FALLO: la red del simulacro tiene salida a Internet; no vale.'
        exit 1
    else
        echo 'sin salida a Internet (esperado)'
    fi
    echo "la red $RED es interna: sin puerta de enlace hacia fuera"
    docker run --rm --network "$RED" "$CLIENTE" \
        curl -sS -m 20 "http://$SERVIDOR:11434/api/tags" | head -c 400 || true
    echo
    echo '```'
}

inventario() {
    echo "### Qué hay en disco"
    echo '```'
    echo "imagen: $IMAGEN ($(docker images --format '{{.Size}}' "$IMAGEN"))"
    echo "digest: $(docker image inspect --format '{{range .RepoDigests}}{{.}}{{end}}' "$IMAGEN")"
    echo "cliente de prueba: $CLIENTE ($(docker images --format '{{.Size}}' "$CLIENTE"))"
    docker exec "$SERVIDOR" ollama --version
    docker exec "$SERVIDOR" ollama list
    echo "--- manifiesto: línea FROM"
    docker exec "$SERVIDOR" ollama show --modelfile "$MODELO" | grep '^FROM'
    echo "--- tamaño del almacén"
    docker exec "$SERVIDOR" du -sh /root/.ollama/models
    echo "--- blob de pesos: tamaño y sha256 (nombre = hash)"
    docker exec "$SERVIDOR" sh -c '
        for f in /root/.ollama/models/blobs/*; do
            s=$(stat -c %s "$f")
            [ "$s" -ge 100000000 ] || continue
            n=$(basename "$f" | sed "s/^sha256-//; s/^sha256://")
            h=$(sha256sum "$f" | cut -d" " -f1)
            [ "$n" = "$h" ] && ok=coincide || ok=NO_COINCIDE
            printf "%s\t%s bytes\t%s\n" "$n" "$s" "$ok"
        done'
    echo '```'
}

tareas() {
    echo "### Tareas en el servidor"
    echo '```'
    echo "--- T1: explicación (paso 3 de la guía)"
    local inicio=$SECONDS
    docker exec "$SERVIDOR" ollama run "$MODELO" \
        'explica en tres líneas qué hace este comando: tar -czf'
    echo "T1: $((SECONDS - inicio)) s"

    echo
    echo "--- T2: tarea real sobre el repositorio (fragmento de scripts/utilidades/run_agent.sh)"
    local fragmento
    fragmento=$(head -30 "$raiz/scripts/utilidades/run_agent.sh")
    inicio=$SECONDS
    printf '%s\n\nPregunta: en cinco líneas, qué hace este script y qué riesgo tiene ejecutarlo sin revisar.\n' "$fragmento" |
        docker exec -i "$SERVIDOR" ollama run "$MODELO"
    echo "T2: $((SECONDS - inicio)) s"
    echo '```'
}

cliente() {
    echo "### Cliente sin red (el que se usa a diario)"
    echo '```'
    local cfg="$COPIA_DIR/cliente"
    mkdir -p "$cfg"
    cat > "$cfg/opencode.json" <<EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "model": "ollama/$MODELO",
  "providers": {
    "ollama": {
      "package": "@opencode/ai/providers/openai-compatible",
      "settings": { "baseURL": "http://$SERVIDOR:11434/v1" },
      "models": { "$MODELO": { "name": "Qwen 2.5 3B (local)" } }
    }
  }
}
EOF
    if [ ! -x "$BINARIO_OPENCODE" ]; then
        echo "sin binario de OpenCode en $BINARIO_OPENCODE: cliente gráfico no medido"
        echo '```'
        return 0
    fi
    local inicio=$SECONDS
    echo "cliente: $("$BINARIO_OPENCODE" --version) ($(tamano "$(stat -c %s "$BINARIO_OPENCODE")"))"
    docker run --rm --network "$RED" \
        -v "$BINARIO_OPENCODE:/usr/local/bin/opencode:ro" \
        -v "$cfg:/root/.config/opencode:ro" \
        -v "$cfg/home:/root" "$BASE" \
        opencode run "Explica en tres líneas qué hace este script y un riesgo de ejecutarlo sin revisar:

$(head -20 "$raiz/scripts/utilidades/run_agent.sh")"
    echo "cliente: $((SECONDS - inicio)) s"
    echo '```'
}

simulacro() {
    exigir_imagenes "$IMAGEN" "$CLIENTE" "$BASE"
    echo "## Simulacro ($(fecha))"
    echo
    echo "### Equipo que lanza el simulacro"
    echo '```'
    LC_ALL=C lscpu | grep -E 'Model name|^CPU\(s\):' || true
    free -h | sed -n '2p' || true
    nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader || echo 'sin GPU'
    docker --version
    uname -r
    echo '```'
    echo
    red
    corte
    echo
    inventario
    echo
    echo "### Servicio y su interfaz"
    echo '```'
    echo "interfaces del servidor: $(docker exec "$SERVIDOR" sh -c 'ls /sys/class/net | tr "\n" " "')"
    echo "red: $(docker network inspect --format '{{.Driver}} interno={{.Internal}}' "$RED")"
    echo '```'
    echo
    tareas
    echo
    cliente
    limpiar
    echo
    echo "Volumen $VOLUMEN conservado. Para borrarlo: docker volume rm $VOLUMEN"
}

restaurar() {
    local sello copia inicio
    exigir_imagenes "$IMAGEN"
    sello=$(date +%F)
    copia="$COPIA_DIR/ollama-models-$sello.tar.gz"
    mkdir -p "$COPIA_DIR"
    docker network create --internal "$RED" >/dev/null 2>&1 || true
    echo "## Copia y restauración ($(fecha))"
    echo
    echo "### Copia de los pesos con el servicio parado"
    echo '```'
    limpiar
    docker run --rm -v "$VOLUMEN:/origen:ro" -v "$COPIA_DIR:/copia" \
        --entrypoint tar "$IMAGEN" -czf "/copia/$(basename "$copia")" -C /origen models
    echo "$(basename "$copia")	$(tamano "$(stat -c %s "$copia")")"
    echo "$(sha256sum "$copia" | cut -d' ' -f1)  $(basename "$copia")"
    echo '```'
    echo
    echo "### Restauración en un volumen limpio"
    echo '```'
    docker volume rm "$RESTAURADO" >/dev/null 2>&1 || true
    docker volume create "$RESTAURADO" >/dev/null
    docker run --rm -v "$RESTAURADO:/destino" -v "$COPIA_DIR:/copia:ro" \
        --entrypoint tar "$IMAGEN" -xzf "/copia/$(basename "$copia")" -C /destino
    docker run -d --name "$SERVIDOR" --network "$RED" \
        -v "$RESTAURADO:/root/.ollama" "$IMAGEN" >/dev/null
    esperar_servicio
    docker exec "$SERVIDOR" ollama list
    echo "--- manifiesto restaurado"
    docker exec "$SERVIDOR" ollama show --modelfile "$MODELO" | grep '^FROM'
    inicio=$SECONDS
    docker exec "$SERVIDOR" ollama run "$MODELO" "$OPCIONES"
    echo "inferencia restaurada: $((SECONDS - inicio)) s"
    echo '```'
    limpiar
    echo
    echo "Restaurado en el volumen $RESTAURADO; copia en $copia"
}

case "${1:-}" in
    preparar)
        echo "## Preparación ($(fecha))"
        docker volume create "$VOLUMEN" >/dev/null
        docker pull "$IMAGEN"
        docker pull "$CLIENTE"
        docker pull "$BASE"
        docker network create --internal "$RED" >/dev/null 2>&1 || true
        limpiar
        docker run -d --name "$SERVIDOR" -v "$VOLUMEN:/root/.ollama" "$IMAGEN" >/dev/null
        esperar_servicio
        docker exec "$SERVIDOR" ollama pull "$MODELO"
        limpiar
        echo "Preparación terminada. Los pesos quedan en el volumen $VOLUMEN."
        ;;
    simulacro) simulacro ;;
    restaurar) restaurar ;;
    *) echo "uso: $0 {preparar|simulacro|restaurar}" >&2; exit 2 ;;
esac
