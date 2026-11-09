# Servidores MCP: qué son, qué aportan y por qué no compensan aquí

> **Estado:** Parcial. Decisión tomada y piloto ejecutado; el coste del esquema no tiene medición reproducible adjunta.

Un servidor MCP da al asistente acceso a otro sistema —archivos, una base de datos, un repositorio remoto— sin escribir una integración distinta para cada cliente. Funciona como un adaptador de corriente universal: el mismo enchufe sirve para varios aparatos, pero ocupa sitio en la regleta aunque no lo uses. En este laboratorio el adaptador no compensa, porque el asistente ya llega a lo que necesita con `grep` y `read`, y el esquema de un servidor grande consume casi toda la ventana de un modelo local.

## 1. Qué es

MCP (*Model Context Protocol*) es un protocolo abierto que describe cómo un agente descubre y llama a herramientas de otro proceso. Tiene dos mitades:

- **Servidor:** proceso que declara un catálogo —herramientas (`tools`), recursos (`resources`) y plantillas de prompt (`prompts`)— y ejecuta lo que se le pide. Corre en local por `stdio` (la entrada y salida estándar del proceso) o como servicio remoto por HTTP.
- **Cliente:** el agente que se conecta (OpenCode, Continue, un IDE). Al iniciar la sesión descubre el catálogo y traduce cada herramienta a una llamada que el modelo puede decidir usar.

Hay servidores para el sistema de archivos, Git, GitHub, bases de datos, navegador o servicios SaaS (software en la nube de un tercero). Un servidor no añade inteligencia ni conocimiento al modelo: añade **alcance**. Quien decide llamarlo es el agente; quien ejecuta y responde es el servidor, con las credenciales y los permisos con los que se haya arrancado.

## 2. Qué aporta

- **Llegar donde no hay interfaz de línea de comandos (CLI).** Un servicio con API paginada, autenticación y formatos propios se convierte en dos o tres herramientas con parámetros claros.
- **Catálogo declarado.** El agente conoce nombres, parámetros y significado sin leer documentación ni ensayar llamadas a ciegas, lo que reduce el tanteo.
- **Reutilización.** El mismo servidor sirve a varios clientes; la integración se escribe una vez y no por herramienta.
- **Frontera explícita.** Si el servidor es el único camino a ese sistema, se puede encerrar en un contenedor, darle credenciales de solo lectura y auditar por ahí. Es más fácil de acotar que dar al agente un shell con red.
- **Datos fijos sin herramienta propia.** Un esquema, un catálogo o una tabla de referencia se exponen como recurso y el agente los lee cuando los necesita.

## 3. Qué cuesta

- **Contexto fijo por petición.** La descripción de cada herramienta viaja en cada llamada al modelo, se use o no. Es coste que se paga durante toda la sesión, no solo cuando se invoca. El detalle y la regla de conteo están en [`coste-contexto-y-optimizacion.md`](coste-contexto-y-optimizacion.md) §2.7.
- **Ventana del modelo.** Con un modelo local de 16K —la ventana que se sincroniza en [`continue-remote-ollama-setup.md`](../guias/continue-remote-ollama-setup.md)—, un esquema de 14,2 k tokens deja la tarea casi sin espacio. Antes de que el asistente pregunte nada, la ventana ya está ocupada.
- **Confianza y superficie.** El servidor es código de terceros que se ejecuta con las credenciales que le des. Un paquete comprometido o mal mantenido es una entrada de cadena de suministro dentro del entorno del agente.
- **Inyección por la salida.** Todo lo que devuelve el servidor entra en el contexto como contenido: un registro manipulado puede llevar instrucciones. Es la misma clase de riesgo que leer un archivo envenenado del repositorio, con un canal más ancho y menos revisado.
- **Credenciales nuevas.** Cada servicio conectado suma un token OAuth o una clave que hay que guardar, acotar y rotar.
- **Mantenimiento silencioso.** El esquema crece con cada versión del servidor y puede cambiar sin que cambie su uso; el coste hay que volver a contarlo.
- **Duplicación.** Si la tarea ya se resuelve con `git`, `grep`, `curl` o el SDK del servicio, el servidor repite lo que existe y se paga dos veces.

## 4. Criterio de adopción

Un servidor se conecta solo si se cumplen las cuatro condiciones a la vez:

1. **Tarea repetitiva** con coste real; no un uso mensual.
2. **Sistema sin vía razonable** por CLI o por API directa desde el agente.
3. **Esquema medido**: tokens de sus herramientas frente al ahorro esperado en esa tarea.
4. **Frontera declarada**: qué datos salen, con qué permiso y dónde corre el servidor.

Si se conecta, con el mínimo: solo lectura por defecto, pocas herramientas, descripciones breves y revisión del esquema tras cada actualización.

## 5. Por qué no compensa en este laboratorio

- **El alcance es local y de archivos.** El trabajo es leer repositorios, buscar con `grep`, editar y usar `git`. No hay un SaaS en el circuito que justifique un conector.
- **El caso ya lo probé y salió caro.** Un esquema MCP añadía del orden de 14,2 k tokens en cada petición, por encima del ahorro esperado. Descarté el piloto por esa razón; la cifra es una observación del laboratorio, no un benchmark.
- **Con un esquema de ese tamaño, en local no es solo caro: es inviable.** Con la ventana de 16K que se usa con Ollama, el esquema se come la sesión antes de empezar.
- **Cada conector abre una salida.** La premisa del laboratorio es saber qué cruza la frontera y con qué permiso; sumar servidores suma destinos, credenciales y código de terceros sin una tarea que lo pida.
- **No añade evidencia.** Conectar un servidor no demuestra nada sobre el criterio. Lo que enseña este laboratorio es decidir cuándo no conectarlo, y eso se documenta mejor de lo que se instala.

## 6. Cuándo se revisaría

Lo reviso si aparece una tarea que se repite y que las alternativas resuelven peor, o un sistema que el agente necesita alcanzar y no tiene CLI utilizable. Entonces, en este orden: medir el esquema completo, compararlo con el ahorro de la tarea concreta y declarar la frontera antes de conectar. La prueba que zanjaría la duda —misma tarea con y sin servidor, tokens y resultado— no la he hecho.

## 7. Límites

- No tengo medición reproducible del coste del esquema. La cifra de 14,2 k procede de un piloto concreto y no se extrapola a otros servidores ni a otros clientes: el coste depende del tamaño del catálogo.
- No se juzga el protocolo ni ningún producto. Solo se fija el criterio de este laboratorio.
- No se afirma nada sobre versiones futuras de MCP ni sobre servidores que aún no se han probado.
