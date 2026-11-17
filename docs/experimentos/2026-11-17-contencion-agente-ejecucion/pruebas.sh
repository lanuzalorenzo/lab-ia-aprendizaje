#!/bin/sh
# Batería que se ejecuta DENTRO del contenedor del agente, por la entrada estándar.
# Cada línea: CHECK <id> esperado=<...> observado=<...> veredicto=<ok|fallo>
# No aborta en el primer fallo: se quieren todos los datos de una pasada.
# Sale con el número de comprobaciones fallidas.

FALLOS=0

marcar() { # id esperado observado veredicto
    printf 'CHECK %-28s esperado=%-42s observado=%-46s veredicto=%s\n' "$1" "$2" "$3" "$4"
    [ "$4" = "ok" ] || FALLOS=$((FALLOS + 1))
}

# --- Identidad y privilegios -------------------------------------------
uid_actual=$(id -u)
if [ "$uid_actual" -ne 0 ]; then v=ok; else v=fallo; fi
marcar usuario-sin-root "uid distinto de 0" "uid=$uid_actual" "$v"

capacidades=$(awk '/^CapEff:/ {print $2}' /proc/self/status)
nuevos=$(awk '/^NoNewPrivs:/ {print $2}' /proc/self/status)
seccomp=$(awk '/^Seccomp:/ {print $2}' /proc/self/status)
if [ "$capacidades" = "0000000000000000" ] && [ "$nuevos" = "1" ] && [ "$seccomp" = "2" ]; then v=ok; else v=fallo; fi
marcar capacidades-y-seccomp "CapEff=0 NoNewPrivs=1 Seccomp=2" "CapEff=$capacidades NoNewPrivs=$nuevos Seccomp=$seccomp" "$v"

# --- Sistema de archivos ------------------------------------------------
if cat /etc/shadow >/dev/null 2>&1; then v=fallo; else v=ok; fi
marcar lectura-etc-shadow "denegado" "$(cat /etc/shadow 2>&1 | head -1)" "$v"

if touch /archivo-en-raiz 2>/dev/null; then v=fallo; else v=ok; fi
marcar escritura-en-raiz "denegada (raíz de solo lectura)" "$(touch /archivo-en-raiz 2>&1 | head -1)" "$v"

if touch /tmp/archivo 2>/dev/null; then v=ok; else v=fallo; fi
marcar escritura-en-tmp "permitida" "touch /tmp/archivo" "$v"

# Lo que se ve del host: destinos montados. Nada bajo /home debe aparecer.
destinos=$(awk '{print $2}' /proc/self/mounts)
entradas=$(printf '%s\n' "$destinos" | wc -l)
bajo_home=$(printf '%s\n' "$destinos" | grep -c '^/home')
if [ "$bajo_home" -eq 0 ]; then v=ok; else v=fallo; fi
marcar montajes-del-host "ninguno bajo /home" "entradas=$entradas bajo-home=$bajo_home" "$v"

# El repositorio se monta de solo lectura y se puede leer.
opciones=$(awk '$2 == "/repo" {print $4}' /proc/self/mounts)
case "$opciones" in
    *ro*) v=ok ;;
    *)    v=fallo ;;
esac
marcar montaje-repositorio "visible en /repo y ro" "opciones=${opciones:-sin-montaje}" "$v"

if touch /repo/prueba-de-escritura 2>/dev/null; then v=fallo; else v=ok; fi
marcar escritura-en-montaje "denegada (montaje de solo lectura)" "$(touch /repo/prueba-de-escritura 2>&1 | head -1)" "$v"

# --- Credenciales y entorno --------------------------------------------
if env 2>/dev/null | grep -q '^TOKEN_DEL_HOST='; then v=fallo; else v=ok; fi
marcar entorno-sin-token "TOKEN_DEL_HOST ausente" "presente=$(env 2>/dev/null | grep -c '^TOKEN_DEL_HOST=')" "$v"

# Testigo: una variable sí pasada con -e tiene que verse dentro.
if env 2>/dev/null | grep -q '^TESTIGO=visible$'; then v=ok; else v=fallo; fi
marcar testigo-pasado "TESTIGO visible dentro" "presente=$(env 2>/dev/null | grep -c '^TESTIGO=visible$')" "$v"

# La credencial no está en el entorno.
if env 2>/dev/null | grep -q 'token-de-prueba-no-es-un-secreto'; then v=fallo; else v=ok; fi
marcar credencial-fuera-del-entorno "valor ausente del entorno" "coincidencias=$(env 2>/dev/null | grep -c 'token-de-prueba-no-es-un-secreto')" "$v"

if [ -S /var/run/docker.sock ]; then v=fallo; else v=ok; fi
marcar socket-docker "ausente" "$(ls -l /var/run/docker.sock 2>&1 | head -1)" "$v"

procesos=$(ps -o pid,comm 2>/dev/null | wc -l)
primero=$(ps -o comm 2>/dev/null | sed -n 2p)
if [ "$procesos" -le 8 ]; then v=ok; else v=fallo; fi
marcar procesos-visibles "solo los del contenedor" "lineas=$procesos pid1=$primero" "$v"

# --- Red ----------------------------------------------------------------
if curl -sS --noproxy '*' --max-time 8 https://example.com/ >/dev/null 2>&1; then v=fallo; else v=ok; fi
marcar salida-directa "sin ruta a Internet" "$(curl -sS --noproxy '*' --max-time 8 https://example.com/ 2>&1 | head -1)" "$v"

if getent hosts example.com >/dev/null 2>&1; then v=fallo; else v=ok; fi
marcar dns-externo "sin resolución externa" "$(getent hosts example.com 2>&1 | head -1)" "$v"

# Sin DNS no se distingue «no hay ruta» de «no hay resolución»: se prueba por IP.
if curl -sS --noproxy '*' --max-time 6 https://1.1.1.1/ >/dev/null 2>&1; then v=fallo; else v=ok; fi
marcar salida-por-ip "sin ruta a Internet" "$(curl -sS --noproxy '*' --max-time 6 https://1.1.1.1/ 2>&1 | head -1)" "$v"

respuesta=$(curl -sS --max-time 8 -x http://proxy:8080 http://eco:9000/ 2>&1)
codigo=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 8 -x http://proxy:8080 http://eco:9000/ 2>&1)
if [ "$codigo" = "200" ] && echo "$respuesta" | grep -q 'Bearer token-de-prueba-no-es-un-secreto'; then v=ok; else v=fallo; fi
marcar proxy-host-permitido "200 y cabecera inyectada" "codigo=$codigo $(echo "$respuesta" | tr -d '\n' | head -c 240)" "$v"

codigo=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 8 -x http://proxy:8080 http://example.com/ 2>&1)
if [ "$codigo" = "403" ]; then v=ok; else v=fallo; fi
marcar proxy-host-denegado "403 del proxy" "codigo=$codigo" "$v"

# En un CONNECT rechazado curl devuelve 56 y deja http_code a cero.
salida=$(curl -sS -o /dev/null --max-time 8 -x http://proxy:8080 https://example.com/ 2>&1)
if echo "$salida" | grep -q 'response 403'; then v=ok; else v=fallo; fi
marcar proxy-connect-denegado "rechazo del proxy en el túnel" "$(echo "$salida" | head -1)" "$v"

echo "FIN DE LA BATERIA fallos=$FALLOS"
exit "$FALLOS"
