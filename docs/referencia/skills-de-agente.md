# Skills de agente: qué son, qué aportan y por qué no compensan aquí

> **Estado:** Diseño (2026-11-18). La adopción sigue **Pendiente**: no hay ninguna skill escrita, cargada ni medida, así que el criterio es una deducción y no un resultado. Lo que lo cambiaría: publicar una skill que otro pueda instalar, o encontrar un procedimiento largo, condicional y con juicio que ninguna comprobación cubra.

Un `AGENTS.md` es el manual de la oficina: está siempre encima de la mesa y se lee entero cada vez que el cliente lo carga, aunque sea para no usarlo. Una skill es la ficha que se saca del cajón cuando toca hacer esa cosa concreta: no ocupa sitio en la mesa y no se lee si no se va a usar. Esa diferencia —estar siempre o aparecer cuando hace falta— es lo que aporta el formato y lo que cuesta.

## 1. Qué es

Una carpeta con un archivo `SKILL.md`: un frontmatter YAML, un cuerpo en Markdown y, alrededor, subcarpetas opcionales con material de apoyo (`references/`, `scripts/` y `assets/`). En el frontmatter son obligatorios dos campos, `name` y `description`; hay otros opcionales, como `license`, `compatibility`, `metadata` y `allowed-tools`. El formato lo define la [especificación Agent Skills](https://agentskills.io), que fija el nombre en 1 a 64 caracteres en kebab-case y la descripción en hasta 1.024. El tope de 500 líneas para el cuerpo no es un límite del formato: es una recomendación de la propia especificación, no una regla que imponga el validador.

`allowed-tools` declara herramientas, pero lo que cada cliente hace con esa declaración no es uniforme. Mientras no se compruebe en el cliente concreto, no cuenta como permiso.

## 2. Qué aporta

- **Contexto mínimo por defecto.** De todas las skills disponibles solo viaja el nombre y la descripción; el cuerpo se paga cuando se usa.
- **Criterio versionado junto al código.** Un procedimiento que hoy vive en la cabeza o en un párrafo del manual pasa a ser un archivo con dueño y fecha.
- **Reutilización entre clientes.** La misma carpeta la leen varios asistentes, aunque cada uno con sus límites y sus rutas.
- **Material a demanda.** Los archivos de apoyo no entran en el contexto hasta que el cuerpo los necesita.

## 3. Cómo se carga

Tres niveles, y solo el primero se paga siempre:

| Nivel | Qué llega al modelo | Cuándo |
|---|---|---|
| 1 | El `name` y la `description` de todas las skills disponibles | Siempre, en cada turno |
| 2 | El cuerpo del `SKILL.md` | Cuando el modelo juzga que la descripción encaja con el encargo |
| 3 | Los archivos de `references/`, `scripts/` o `assets/` | Cuando el cuerpo los menciona y hacen falta |

Por defecto el nivel 2 lo dispara el modelo por relevancia, no la persona; según el cliente, además se puede invocar la skill por su nombre. Es decir: la diferencia con un comando no es que no se pueda pedir, sino quién decide cuando nadie lo pide.

## 4. En qué se diferencia de lo que ya hay

| Pieza | Entra en contexto | La dispara por defecto | Qué garantiza |
|---|---|---|---|
| Instrucciones del repositorio (`AGENTS.md`) | Siempre | Nadie: es texto pasivo | Que la regla se leyó, no que se cumpla |
| Comando | Solo al invocarlo | La persona | El mismo procedimiento cada vez |
| Agente o subagente | Al lanzarlo | La persona | Contexto y permisos separados |
| Comprobación en el `pipeline` | En cada `push` | El propio `pipeline` | Bloquea si no pasa |
| Skill | Solo el nombre y la descripción | El modelo, por relevancia | Criterio a demanda, sin garantía |

La última columna decide. Una skill orienta; no impide y no comprueba. El permiso y la verificación están fuera del formato, como ya está razonado en [`programacion-agentica.md`](programacion-agentica.md) §1 y en [`agents-md-publico-privado.md`](../guias/agents-md-publico-privado.md) §6.

## 5. Criterio de adopción

Una skill compensa solo si se cumplen las cuatro condiciones a la vez:

1. **Condicional.** Aplica a veces, no en cada turno.
2. **Con juicio.** Hay que decidir, no ejecutar una lista fija.
3. **Largo.** No cabe en una línea de regla; explicarlo ocupa más de lo que cuesta tenerlo delante.
4. **Sin comprobador.** Ninguna prueba determinista puede verificarlo.

Si falla la primera, el sitio es el `AGENTS.md`. Si falla la segunda, es un script. Si falla la tercera, es una línea más de la regla. Si falla la cuarta, es una comprobación en el `pipeline` y no hay nada que discutir.

## 6. Qué cuesta

- **Contexto fijo por turno.** La descripción de cada skill disponible viaja en cada petición, se use o no, y crece con cada skill instalada. Es el mismo coste que el esquema de un [servidor MCP](servidores-mcp.md) §3, con la diferencia de que aquí la descripción se escribe a mano y se puede medir.
- **Mantenimiento por cliente.** Cada cliente lee la carpeta a su manera y aplica sus propios límites sobre la descripción, la indentación o el tamaño. Una skill que carga en uno puede no cargar en otro.
- **Fallo silencioso.** Una skill que no carga no da error: simplemente no se usa, y eso se descubre tarde, cuando alguien da por hecho un procedimiento que nunca se ejecutó.
- **Duplicación.** Cada skill es un texto más que dice lo que ya dice una regla o una guía. Dos dueños del mismo hecho acaban contradiciéndose, y este repositorio prohíbe duplicar una pieza en dos capas.

## 7. Por qué no compensa en este laboratorio

Lo comprobé el 2026-11-18 recorriendo cada repositorio público del portfolio con `find . -type f -name SKILL.md -not -path './.git/*'` lanzado en su raíz. Ninguno devolvió nada: no hay ni una skill escrita, ni aquí ni en el resto.

No es un olvido. Es el resultado de que las cuatro condiciones choquen con lo que ya existe:

- Lo que hay que cumplir siempre ya está en el `AGENTS.md` de cada repositorio, donde llega entero y no depende de que el modelo lo considere relevante.
- Lo que se puede comprobar ya se comprueba en el `pipeline`: en este repositorio, los secretos del historial y los enlaces y anclas con las acciones compartidas de [`core`](https://github.com/lanuzalorenzo/core), y la sintaxis de los scripts con un paso propio. Una comprobación bloquea; una skill solo sugiere.
- No hay todavía un procedimiento que cumpla las cuatro condiciones sin ser a la vez una regla del manual y una prueba automática.

Añadir una skill hoy sería mantener un segundo dueño de algo que ya tiene uno, pagando contexto fijo en cada turno para que aparezca cuando el modelo quiera.

## 8. Qué lo cambiaría

Tres disparadores, y los tres se pueden comprobar:

1. **Publicar skills para que las use otro.** Si el criterio sirviera fuera de estos repositorios, la skill deja de ser una copia interna y pasa a ser distribución: se instala desde su repositorio y el coste de mantenerla lo comparte quien la usa.
2. **Un procedimiento largo, condicional y con juicio que ninguna prueba cubra.** Hoy no lo hay; el día que aparezca, el sitio natural es una skill y no un párrafo más del manual.
3. **Una medición.** Qué cambia en el resultado de un agente con la skill delante y sin ella, con el mismo encargo. Sin esa comparación, adoptarla es una preferencia, no una mejora.

## Lo que no está medido

No he escrito ninguna skill, no la he cargado en ningún cliente y no he medido si cambia lo que un agente hace. Este documento ordena el criterio; el experimento que lo respalde está pendiente, y hasta entonces la decisión es una deducción.
