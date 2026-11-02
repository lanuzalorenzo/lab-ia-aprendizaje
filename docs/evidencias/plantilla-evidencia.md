# Plantilla de Evidencia

> **Uso:** Copia esta plantilla a una carpeta nueva bajo `docs/evidencias/` con el nombre `YYYY-MM-DD-descripcion-corta[-vN]` (por ejemplo, `2026-10-22-robustez-ejecucion-v2`). Rellena cada sección. Elimina secciones que no apliquen.

---

## 1. Metadatos

| Campo | Valor |
|-------|-------|
| **Fecha** | YYYY-MM-DD |
| **Tipo** | Validación de instrumento / Ejecución con modelo / Comparativa / Otro |
| **Modelo(s)** | Nombre exacto y digest (ej. `qwen2.5:3b` `357c53fb659c`) |
| **Script/Versión** | Script usado y commit/hash |
| **Entorno** | Equipo, GPU, RAM, Ollama version |
| **Estado** | Validado / Parcial / Runbook preparado / Diseño / Pendiente |

---

## 2. Qué se ha ejecutado

```bash
# Comando exacto reproducido
./scripts/... --opciones
```

Salida relevante:
```text
...
```

Artefactos generados:
- `archivo.json` — descripción

---

## 3. Qué mide y qué no

| Pregunta | Estado |
|----------|--------|
| ¿Qué valida esta evidencia? | Validado / No medido / N/A |
| ¿Qué **no** valida? | ... |

---

## 4. Resultados

Tabla resumen con métricas clave.

---

## 5. Hallazgos / Limitaciones

- **H-1**: Descripción del hallazgo y corrección si aplica
- **H-2**: ...

---

## 6. Qué no demuestra

- No hay resultado sobre X
- La métrica Y está pendiente
- ...

---

## 7. Cómo reproducir

```bash
cd lab-ia-aprendizaje
# Pasos exactos
```

---

## 8. Siguiente paso

Acción concreta y medible.