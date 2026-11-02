# Guía para agentes: lab-ia-aprendizaje

Laboratorio local de agentes de IA con Ollama y Continue, usado como herramienta de desarrollo y seguridad del portfolio público. Estructura y guías: `README.md` y `docs/`.

## Convenciones

- Alcance: IA local y seguridad. Los datos sensibles se quedan en local; el trabajo diario puede usar un proveedor remoto con política revisada. Nada de rankings, noticias ni comparativas sin medición propia.
- No expongas Ollama a Internet; documenta firewall, TLS y autenticación.
- Usa `ollama.lab.local` u otro placeholder, nunca una IP interna real.
- README de práctica de 240–310 palabras; `informe.md` solo si sostiene el contenido; `runbook.md` solo si es reejecutable; `bitacora/` solo con hechos nuevos.
- En evaluación de IA, separa diseño y expectativas de resultados medidos; no presentes umbrales como resultados.
- Lab independiente del lab final de ciberseguridad: si se enlaza desde el portfolio, el alcance y las evidencias van separados.
- El cuaderno de laboratorio (`docs/referencia/bitacora-decisiones-aprendizaje.md`) es una excepción declarada a la regla de no guardar registros: recoge hechos, fallos y decisiones del entorno local con fecha y resultado, y mantiene allí los ejes de aprendizaje (GGUF/CUDA, clientes, RAG). No se duplica en `bitacora/`. La seguridad del asistente vive en `docs/referencia/hoja-de-ruta-seguridad-asistentes.md`.
- Sin secretos, credenciales ni datos personales.

## Contrato editorial

El contrato completo —apertura llana, jerga, estados, evidencias y claridad que no cambia lo que se afirma— está en [portfolio-ciberseguridad-lorenzo](https://github.com/lanuzalorenzo/portfolio-ciberseguridad-lorenzo/blob/main/AGENTS.md). En este repo: español claro, estados explícitos (Validado · Parcial · Runbook preparado · Diseño · Pendiente) y evidencia separada del hallazgo; un hallazgo no es un PASS.

## Gobernanza

`main` exige PR, los tres checks de CI y rama actualizada; solo el propietario fusiona.

## Commits

Formato: `type(scope): imperative summary in English`. Scopes: `docs`, `examples`, `scripts`, `config`, `repo`. Tipos: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`. Asunto imperativo, conciso y en inglés.
