# Experimento — Inferencia local 7B + Continue

**Qué probé:** conectar `qwen2.5-coder:7b` a Continue en local.

**Qué salió:** la integración responde; la latencia percibida es alta («lento»).

**Qué no está medido:** versiones, hardware y latencia numérica. La velocidad es una apreciación, no una cifra.

> Resumen añadido el 2026-11-04; los artefactos no cambian.

> **Corrección (2026-11-05):** el estado pasa a Validado el uso en este equipo: la prueba se hizo y la observación es «funciona, lento». No se añaden mediciones ni se repite la prueba; se retira la lista de pasos pendientes. Cambia el estado y esa lista; el resto del registro se mantiene.

> **Fecha de registro:** 2026-10-30
> **Fecha de la prueba:** no registrada
> **Estado:** Validado el uso en este equipo, sin medición ni reproducibilidad; no el rendimiento
> **Modelo:** `qwen2.5-coder:7b` (digest no registrado)
> **Cliente:** Continue (versión no registrada)
> **Endpoint:** placeholder de laboratorio; no se publica una IP real

## Qué se observó

Confirmo que la integración responde con el modelo de 7B en mi equipo. La latencia percibida es alta («lento»), pero la integración funciona.

## Límites

No hay `entorno.json`, `resultados.json`, captura ni log. Esta página no es una medición de rendimiento: «lento» es una apreciación, no una cifra de tokens por segundo. El estado valida el uso, no la reproducibilidad ni el rendimiento, y no acredita el laboratorio de extremo a extremo.
