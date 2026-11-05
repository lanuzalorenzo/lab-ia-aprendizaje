# Dimensionado de hardware para IA local

Antes de comprar o alquilar una máquina para ejecutar modelos en casa hay que responder tres preguntas distintas, y casi todos los anuncios responden solo a la primera. Si el modelo cabe en memoria, si se mueve a una velocidad que sirva para trabajar y cuánto cuesta tenerlo encendido frente a pagar por uso.

Es como elegir una furgoneta para una mudanza: primero se mira si la carga entra en el maletero, después si el motor la mueve con soltura, y al final si compensa comprarla o alquilarla solo el día que hace falta. Una furgoneta enorme para llevar una caja dos veces al año sale carísima; alquilada por horas, barata.

> **Estado: Parcial.** La aritmética de capacidad se puede comprobar con el tamaño real del archivo descargado. La velocidad es una estimación por ancho de banda y **no una medición propia**: en este repositorio no hay todavía ninguna cifra de tokens por segundo medida. El umbral de coste parte del experimento de coste de sesiones (Validado) y de supuestos de precio de hardware y electricidad que se declaran en el §6.

> **La cuenta en una frase.** Un equipo capaz de mover modelos de 32B cuesta entre 44 y 66 € al mes contando luz y amortización; la factura de API de este laboratorio, con 162 sesiones en 30 días, es de 11,54 $, unos 11 €. Por debajo de 44 € al mes de gasto real, comprar hardware no se justifica con dinero: se justifica por la frontera del dato.

## 1. Las tres preguntas

| Pregunta | Qué la decide | Qué no la decide |
|---|---|---|
| ¿Cabe? | Memoria del equipo | La potencia del procesador |
| ¿Va rápido? | Ancho de banda de memoria | Los núcleos ni los teraflops |
| ¿Compensa? | Volumen de uso y frontera del dato | Lo que diga un vídeo de comparativas |

A esas tres se suma una cuarta que no es técnica: **qué dato entra**. Si el dato no puede salir de la red, el local deja de ser una preferencia y pasa a ser un requisito. Ese criterio se desarrolla en [local frente a cloud](../guias/local-vs-cloud.md).

## 2. Si cabe: la cuenta de memoria

```
pesos  = parámetros × (bits por peso / 8)
caché  = 2 × capas × cabezas_kv × dimensión_cabeza × tokens × bytes_por_valor
total  = pesos + caché + sobrecarga del runtime
```

La sobrecarga del runtime son entre 1 y 2 GB según el backend: contexto CUDA, buffers de cálculo y fragmentación del asignador. Es la partida que hace fallar las estimaciones optimistas.

**Los bits por peso no son los del nombre.** `Q4_K_M` no usa 4 bits en todas las capas; el promedio real queda entre 4,8 y 4,9 según el modelo. Un «7B» en Q4 no pesa 3,5 GB: el que usa este laboratorio tiene 7.600 millones de parámetros y ronda los 4,7. La tabla de bits efectivos la publica el propio [README de `quantize` de llama.cpp](https://github.com/ggml-org/llama.cpp/blob/master/tools/quantize/README.md), medida sobre Llama-3.1-8B, y se comprueba mejor todavía mirando el tamaño real del archivo descargado.

**La caché de contexto crece con cada token.** No es un porcentaje fijo: sale de la fórmula de arriba. Un modelo de 8B con 32 capas y 8 cabezas de clave y valor cuesta unos 128 KB por token en 16 bits; el 7B de este laboratorio, con 28 capas y 4 cabezas, unos 56 KB. Ocho mil tokens van de 0,45 a 1 GB según el modelo, y treinta y dos mil, de 1,8 a 4 GB.

**Los modelos de mezcla de expertos no se saltan la cuenta.** Activan pocos parámetros por token, así que son más rápidos de lo que sugiere su tamaño, pero necesitan todos los expertos cargados. Si la mitad vive en RAM, el modelo funciona y pierde la ventaja de velocidad que anunciaba.

## 3. Si va rápido: la cuenta de ancho de banda

Para generar cada token, el modelo relee los pesos que ese token necesita. En una sola conversación, nada más se acerca a ese coste. Por eso la velocidad de decodificación tiene un techo que marca la memoria, no el cálculo:

```
tokens/s ≈ (ancho de banda × eficiencia) / bytes leídos por token
```

La eficiencia es la parte que se aprende midiendo: el mismo equipo rinde distinto según el backend y el modelo. Como orden de magnitud, en GPU con CUDA se suele aprovechar en torno al 65% del ancho de banda teórico, y en CPU en torno al 45%. Son valores de referencia de la comunidad, **no mediciones de este laboratorio**.

Aquí está la explicación del famoso «va lento»: cuando el modelo no cabe entero y parte se queda en la memoria del sistema, cada token tiene que atravesar capas que van a la velocidad de la RAM. Una tarjeta gráfica moderna mueve entre 500 y 1.000 GB/s; la RAM de un portátil, entre 50 y 80. La caída no es del 20%: es de un orden de magnitud.

Y hay una asimetría útil: **leer el prompt es cálculo, escribir la respuesta es memoria**. Un prompt largo penaliza el primer token (prefill), pero no cambia tanto los siguientes. Por eso un modelo grande con contexto largo puede tardar en arrancar y luego ir aceptable, y por eso «lento» sin decir en qué fase no significa nada.

## 4. Qué cabe con cada cantidad de memoria

Tabla orientativa: dice **lo que entra**, no lo que rinde. Los tamaños son de cuantización Q4 salvo que se indique otra, con contexto moderado de 8K.

| Memoria | Modelo que entra entero | 14B | 32B | 70B |
|---|---|---|---|---|
| 4 GB (portátil de este laboratorio) | 3B | No | No | No |
| 8 GB | 7B u 8B, con poco margen | No | No | No |
| 12 GB | 8B en Q5 o Q8 | Justo, a 4–8K | No | No |
| 16 GB | 14B en Q4 o Q5 | Sí, cómodo | No | No |
| 24 GB | 32B en Q4 | Sí | Sí, apurado | No |
| 48 GB | 70B en Q4 | Sí | Sí | Sí, justo |
| 64–128 GB unificada | 70B en Q4 con holgura | Sí | Sí | Sí, más lento |

En memoria unificada, el modelo cabe aunque el ancho de banda sea menor que el de una tarjeta dedicada. Cabe y va más despacio: son dos columnas distintas, no una.

La capacidad no lo es todo. Un modelo que cabe puede no servir para la tarea: diseño, refactor que cruza varios módulos y sesiones de agente largas piden más del que un equipo doméstico mueve con soltura hoy.

### Qué compra cada presupuesto

Precios de orden de magnitud para un equipo completo nuevo, no solo la tarjeta. La primera fila es el equipo que ya se tiene. Antes de comprar hay que verificarlos: cambian por país y el mercado de segunda mano los mueve mucho.

| Presupuesto | Memoria | Qué desbloquea | Qué sigue sin poder hacer |
|---|---|---|---|
| 0 €, el equipo que ya tienes | 8–16 GB de RAM o una tarjeta de 4–8 GB | Modelos de 3B a 8B, autocompletado, renombrados, resúmenes y clasificación | Refactor amplio, sesiones largas, razonamiento sostenido |
| ~1.200 € | 16 GB de VRAM | Modelos de 14B en Q4: escribir y revisar un archivo, tests, documentación | Cambios que cruzan varios módulos; contexto largo con holgura |
| ~2.500 € | 24 GB de VRAM | Modelos de 32B en Q4 y de 14B en Q8; sesiones más largas | Sustituir a un modelo frontier en trabajo de arquitectura |
| ~4.000 € o más | 48 GB de VRAM o 64–128 GB unificados | Modelos de 70B en Q4, más lentos que una tarjeta dedicada | Competir en calidad con el mejor modelo remoto |

Ninguna fila sustituye al modelo remoto en capacidad. La diferencia entre presupuestos no es «mejor o peor IA»: es qué tareas dejan de doler. Y en todas, el coste mensual de tenerlo sigue siendo el del §6.

## 5. El contexto es la partida que se olvida

Subir la ventana de contexto parece gratis y no lo es. Duplicar los tokens de contexto duplica su caché, y esa caché compite por la misma memoria que los pesos. El resultado típico: se sube el contexto, el modelo deja de caber entero, el runtime expulsa capas al procesador y la velocidad se desploma sin que nadie haya tocado el modelo.

Mi propio ajuste de 16K en un Modelfile de otro proyecto tiene ese coste, y no está medido. Es un buen ejemplo de configuración que se copia sin comprobar qué se llevó por delante.

## 6. Lo que cuesta tenerlo

Comparar «hardware contra API» con el precio de la tarjeta es la forma más fácil de equivocarse. Hay que comparar **coste mensual de tenerlo** contra **gasto mensual de usarlo**, y sumar la luz.

Con un equipo de 2.000 € —la fila de 24 GB de la tabla anterior si la tarjeta se compra de segunda mano—:

| Concepto | 3 años de vida | 5 años de vida |
|---|---:|---:|
| Amortización del hardware | 55,6 €/mes | 33,3 €/mes |
| Electricidad (100 W de media a 0,15 €/kWh) | ~10,8 €/mes | ~10,8 €/mes |
| **Total** | **~66 €/mes** | **~44 €/mes** |

La luz no es un detalle: con ese consumo, la factura eléctrica sola se parece bastante a la factura de API de este laboratorio, que es de **11,54 $ en 30 días** según el [experimento de coste de sesiones](../experimentos/2026-11-02-coste-contexto-sesiones/README.md). A 0,25 €/kWh, la electricidad sube a unos 18 €/mes.

Con esas cifras, el punto de equilibrio está en gastar entre 44 y 66 € al mes en API, es decir, entre 46 y 69 $ al cambio de 1 € ≈ 1,05 $. Hoy el laboratorio gasta unos 11 € al mes. Es decir: **habría que multiplicar por cuatro o por seis el uso actual para que comprar el equipo saliera a cuenta**, y aun así el modelo local seguiría siendo menos capaz que el remoto.

A eso se suma el coste que no sale en ninguna factura: montar, actualizar drivers, ajustar cuantizaciones y diagnosticar por qué no usa la GPU. En este laboratorio ese tiempo fue la razón de que el flujo local dejara de ser el de por defecto, y no está cuantificado.

## 7. Los tres disparadores para pasar a local

La decisión no se toma por gusto ni por ideología. Se reabre cuando ocurre una de estas tres cosas:

1. **El dato deja de poder salir.** Un cliente exige que su código no cruce la red. Entonces el local es un requisito, no una alternativa, y basta un modelo pequeño para clasificar, resumir y renombrar.
2. **El gasto sube de orden de magnitud.** Por encima de 44–66 € al mes, el hardware entra en la conversación. Por debajo, es un capricho caro.
3. **Aparece un modelo abierto que quepa y haga el trabajo.** Los modelos de mezcla de expertos de 30B ya se acercan a 24 GB. Si uno de ellos cubre el trabajo diario, la capacidad deja de ser el argumento en contra.

Y una vía intermedia que no se suele considerar: **alquilar una GPU por horas**. Sirve para estudiar el umbral y para lotes grandes y reproducibles —evaluar un conjunto dorado, comparar cuantizaciones— sin comprar nada. No resuelve la frontera del dato, porque el dato sigue saliendo, y añade gestión. Su precio varía; la comparación se hace por hora y con la misma carga que se usa a diario.

### Del cálculo a la decisión, en cinco pasos

1. **Fija la tarea y mide el uso actual.** Sesiones o peticiones al mes y lo que cuestan. Sin esa cifra no hay comparación posible, solo intuición.
2. **Comprueba si cabe.** Modelo, cuantización y contexto que necesitas de verdad (§2 y §4). Deja 1–2 GB de memoria libre para el runtime.
3. **Estima la velocidad y ponle umbral.** Por debajo de unos 10 tokens por segundo no se puede conversar con el modelo; entre 20 y 30 vale para autocompletar y tareas cortas; por encima de 40 resulta cómodo. Son umbrales de uso, no mediciones.
4. **Compara el coste mensual** de tenerlo (§6) con el gasto actual. Si el hardware sale más caro, solo queda el argumento del dato.
5. **Escribe la decisión con fecha de revisión** y los tres disparadores del §7. Una decisión sin fecha se convierte en deuda.

Los cinco pasos valen igual para decidir una máquina que un proveedor: son el mismo procedimiento con otro objeto.

## 8. Cómo comprobarlo en el equipo propio

Tres comprobaciones bastan para sustituir una estimación por un dato:

```bash
ollama ps            # reparto real entre CPU y GPU mientras el modelo está cargado
nvidia-smi           # memoria de la GPU durante la inferencia
```

- **`ollama ps` debe decir `100% GPU`.** Cualquier otro reparto significa que parte del modelo está en RAM y que la velocidad anotada no es la de la tarjeta.
- **La memoria de la GPU sube durante la respuesta.** Que la tarjeta aparezca en `nvidia-smi` no prueba que se esté usando; la comprobación completa está en la [guía de la GPU](../guias/gpu-setup.md).
- **Anotar tokens por segundo con el modelo, la cuantización y el contexto.** Sin esos tres datos, la cifra no se puede repetir ni comparar.

### Si tu cifra no cuadra con la mía, gana la tuya

Todas las cuentas de esta página se pueden repetir con los números de otro equipo, y conviene hacerlo antes de comprar nada. Si al medir te sale una velocidad muy distinta a la que estima el §3, el error casi siempre está en uno de estos tres sitios: el modelo no cabía entero y estaba repartido, el contexto real era mayor que el que creías, o la cifra de ancho de banda que usaste no era la de tu memoria.

Si tu medición contradice esta página, la que vale es la tuya. Las estimaciones sirven para decidir antes de gastar; los datos de tu equipo, para decidir después.

## 9. Límites de esta página

- No hay ninguna medición de tokens por segundo hecha en este laboratorio. Las velocidades son estimaciones por ancho de banda.
- Los precios de hardware y electricidad son supuestos declarados, no cotizaciones. Cambian por país, por tarjeta y por tarifa.
- La eficiencia por backend son valores de referencia de la comunidad, no medidos aquí.
- La tabla de qué cabe usa tamaños de cuantización típicos; el tamaño real de cada archivo manda.
- No se comparan modelos concretos por calidad. Que algo quepa no dice que sirva para una tarea.
- Las cifras de precio y los modelos citados corresponden a 2026-11-05. Se revisan cuando cambia el mercado o el catálogo disponible.
- La conversión entre euros y dólares usa 1 € ≈ 1,05 $, el cambio redondeado en la misma fecha.

## 10. Relacionado

- [Inferencia local frente a cloud](../guias/local-vs-cloud.md): la decisión, escenario a escenario.
- [Continuidad sin proveedor remoto](../guias/continuidad-ia-local.md): qué dejar en disco y qué cabe en este equipo concreto.
- [Coste real de las sesiones](../experimentos/2026-11-02-coste-contexto-sesiones/README.md): de dónde sale la cifra de 11,54 $ al mes.
- [Bitácora, entrada 07](bitacora-decisiones-aprendizaje.md#entrada-07-cifras-de-vram-de-terceros-la-aritmética-primero): la misma aritmética aplicada a una cifra de VRAM ajena.
