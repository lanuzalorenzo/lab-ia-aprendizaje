# Guía para agentes: lab-ia-aprendizaje

Portfolio público de aprendizaje en IA: guías de herramientas y agentes, experimentos con su resultado y sus límites, y criterios sobre qué datos pueden salir de la red. Estructura e índice: `README.md` y `docs/README.md`.

## Rol

Aquí se escribe como **ingeniero de IA aplicada con criterio de seguridad**: se integran herramientas y modelos, se mide lo que se afirma y se declara qué dato cruza la frontera. No es investigación ni entrenamiento de modelos; no atribuyas al repositorio lo que no se haya ejecutado o medido.

## Convenciones

- Alcance: IA aplicada al trabajo de desarrollo y su seguridad. Dos ejes: la frontera de datos (qué sale del equipo y con qué permiso) y el criterio de elección (herramienta, modelo, permisos). Lo local es una forma de cumplir el primero, no el tema. Nada de rankings, noticias ni comparativas sin medición propia.
- Las guías son la espina dorsal; los experimentos, la prueba de lo que se afirma. Un experimento no es un PASS: abre con qué probé, qué salió y qué no está medido.
- Capas de `docs/`: `guias/` (procedimiento reejecutable), `referencia/` (marco y criterio), `experimentos/` (ejecución con artefactos y límites) y `arquitectura/` (montaje local). No se crean carpetas sin contenido que las sostenga ni se duplica una pieza en dos capas.
- README de 240–310 palabras: qué es y para qué sirve, no el montaje. El índice vive en `docs/README.md`.
- No expongas Ollama a Internet; documenta firewall, TLS y autenticación.
- Usa `ollama.lab.local` u otro placeholder, nunca una IP interna real.
- En evaluación de IA, separa diseño y expectativas de resultados medidos; no presentes umbrales como resultados.
- Lab independiente del lab final de ciberseguridad: si se enlaza desde el portfolio, el alcance y los experimentos van separados.
- El cuaderno de laboratorio (`docs/referencia/bitacora-decisiones-aprendizaje.md`) es una excepción declarada a la regla de no guardar registros: recoge hechos, fallos y decisiones del laboratorio con fecha y resultado, y mantiene allí los ejes de aprendizaje (hardware y cuantización, clientes, RAG y agentes, evaluación y robustez). No se duplica en `experimentos/`, que guarda lo que se probó, no por qué se decidió.
- No reescribas un experimento cerrado: si hay que corregirlo, se anota la fecha, el motivo y lo que cambia; los artefactos no se tocan.
- Sin secretos, credenciales ni datos personales.

## Contrato editorial

El contrato completo —apertura llana, jerga, estados, evidencias y claridad que no cambia lo que se afirma— está en [portfolio-ciberseguridad-lorenzo](https://github.com/lanuzalorenzo/portfolio-ciberseguridad-lorenzo/blob/main/AGENTS.md). En este repo: español claro, estados explícitos en experimentos y resultados (Validado · Parcial · Runbook preparado · Diseño · Pendiente); las guías no llevan estado propio. **Validado el uso** es un matiz de Validado: se ejecutó y se observó, sin reproducibilidad declarada; no equivale a un PASS. Separación entre lo medido y el hallazgo; un hallazgo no es un PASS.

## Gobernanza

`main` exige PR, los tres checks de CI y rama actualizada; solo el propietario fusiona, salvo las PRs de Dependabot de parche y minor, que fusiona el flujo automático si pasan los checks.

## Verificación

```bash
python3 scripts/check_links.py
python3 -m compileall -q scripts
gitleaks detect --source . --redact --verbose --exit-code 2
```

Son los tres trabajos de `.github/workflows/ci.yml`: enlaces relativos, sintaxis de los scripts y secretos sobre el historial completo.

## Commits

Formato: `type(scope): imperative summary in English`. Scopes: `docs`, `examples`, `scripts`, `config`, `repo`. Tipos: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`. Asunto imperativo, conciso y en inglés.
