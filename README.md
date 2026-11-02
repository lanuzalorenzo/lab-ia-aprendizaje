<img src="assets/iconos/ia-local.svg" width="64" alt="Icono del laboratorio de IA local">

# Laboratorio y portfolio de aprendizaje en IA local

Laboratorio personal de **aprendizaje en IA**. Pruebo herramientas y formas de trabajar con agentes, comparo alternativas y cuento lo que pasa. El punto de partida fue la IA local, por privacidad y por límites de uso. Ahora el foco es aprender a elegir: qué herramienta, qué modelo y qué datos pueden salir de la red.

> **Estado del repositorio (2026-11-02).**
> - **Validado:** la instalación de Ollama en el servidor del laboratorio (bitácora, entradas 01–03) y la inferencia con `qwen2.5:3b` (evidencia del 22 de octubre, en un entorno que el script instaló y desinstaló), el instrumento de la prueba de robustez, y el uso de OpenCode en esta máquina.
> - **Parcial:** tres pasadas de robustez sobre `qwen2.5:3b`, y la integración de `qwen2.5-coder:7b` con Continue, probada por el autor pero sin registro reproducible.
> - **Diseño:** firewall y TLS, evaluación de funciones con LLM, RAG y equipo de agentes.
> - **Pendiente:** la fase 1 de la [hoja de ruta de seguridad](docs/referencia/hoja-de-ruta-seguridad-asistentes.md) (modelo `portfolio-agent` con digest fijado, y firewall) y los tres experimentos de seguridad de asistentes.
>
> El detalle y los límites de cada evidencia están en [`docs/evidencias/`](docs/evidencias/).

## Propósito

Dejar memoria técnica reproducible del entorno (procedimientos y diagnóstico), el porqué de cada decisión y un portfolio de aprendizaje: patrones con agentes, continuidad entre sesiones y medición de robustez de prompts.

## Alcance

**Incluye:** inferencia local con Ollama, clientes de desarrollo (Continue y OpenCode), un reparto entre modelo local y remoto, continuidad entre sesiones y un marco para evaluar salidas.

**Está en la hoja de ruta, sin evidencia todavía:** RAG local, cuantización, agentes locales, contenedores y pruebas de seguridad de funciones con LLM.

**No incluye:** rankings de modelos, noticias de IA, tutoriales de prompting sin prueba propia, ni comparativas de rendimiento sin medición propia. El eje es la **inferencia local y la seguridad**: los datos sensibles se quedan en local. El trabajo diario usa un proveedor remoto, con criterios claros sobre qué datos pueden salir.

## El escenario

Un servidor sin escritorio (Ubuntu Server) ejecuta modelos con Ollama. Lo administras por SSH desde tu equipo, y tu editor (VS Code con Continue, u OpenCode) usa el modelo a través de la red. El modelo operativo es `qwen2.5-coder:7b`; también se probaron Llama 3 y Mistral al inicio, sin dejar registro.

El montaje se hizo en el servidor. La guía de despliegue y la red están documentadas como runbook, no como ejecución verificada; el firewall sigue en Diseño. Antes de usar el laboratorio, revisa el estado en [`docs/README.md`](docs/README.md) y en el índice de evidencias.

> **Ojo:** que el modelo corra en local garantiza que los datos no salen al proveedor del modelo. No garantiza que no haya fugas: hay que comprobar los puertos abiertos, el firewall y la configuración del cliente.

![Arquitectura local prevista: el equipo cliente usa VS Code con Continue y OpenCode; ambos hablan con Ollama por HTTP en el puerto 11434 y administran el servidor por SSH. El puerto se prevé limitado a la red de laboratorio; la configuración de red no se ha verificado en este repositorio](docs/arquitectura-local.svg)

## Seguridad

Antes de usar el laboratorio, comprueba:

- [ ] Ollama no escucha en `0.0.0.0` sin firewall.
- [ ] El puerto `11434` no está abierto a Internet.
- [ ] La clave de API está en el entorno, no en `opencode.json`.
- [ ] El contexto enviado a un proveedor remoto no contiene secretos ni datos personales.
- [ ] El modelo local y su licencia están identificados.

El acceso remoto usa SSH; si cruza redes no confiables, un proxy con TLS. Los logs se tratan como sensibles y no se publican con prompts. Las claves no se versionan.

## Documentación

El índice completo está en [`docs/README.md`](docs/README.md). Para empezar:

| Documento | Qué aporta |
|---|---|
| [Despliegue en Ubuntu Server](docs/guias/server-deployment-ubuntu-ollama.md) | Servidor sin escritorio, red, SSH y Ollama |
| [Inferencia local frente a cloud](docs/guias/local-vs-cloud.md) | Criterios, flujo híbrido y configuración del modelo local |
| [Continuidad de la IA local](docs/guias/continuidad-ia-local.md) | Qué conservar en disco para seguir trabajando sin proveedor remoto |
| [OpenCode desde cero](docs/guias/opencode-desde-cero.md) | Qué es, por qué empezar con un modelo local y la primera sesión |
| [Programación agéntica](docs/referencia/programacion-agentica.md) | Dónde paga, qué riesgos añade y qué controles la hacen defendible |
| [Hoja de ruta de seguridad](docs/referencia/hoja-de-ruta-seguridad-asistentes.md) | Qué datos salen, qué obedece el asistente y qué puede tocar |
| [Bitácora de decisiones](docs/referencia/bitacora-decisiones-aprendizaje.md) | Decisiones, problemas, causas y ejes de aprendizaje |
| [Evidencias](docs/evidencias/) | Ejecuciones reales y registros parciales |

## Lo que he aprendido

- «Local» describe dónde corre Ollama. No demuestra que todo el flujo sea local ni que la configuración sea privada.
- Ver una GPU y recibir una respuesta no basta para saber que Ollama usó CUDA. Hay que observar la inferencia.
- Instalar desde un script remoto implica confiar en el proveedor y en lo que se descargue en ese momento. La instalación no está fijada a una versión.
- La unidad de `config/` es una referencia sin verificar. No la copies sobre la que está instalada sin revisar usuario, permisos, rutas y acceso a la GPU.
- Los ejemplos son material ilustrativo. No son mediciones de rendimiento ni registros de una sesión comprobada.

Licencia: MIT.
