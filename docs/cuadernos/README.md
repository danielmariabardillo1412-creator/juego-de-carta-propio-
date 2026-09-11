# Cuadernos vivos del juego de cartas propio

Este directorio es la memoria operativa del proyecto. Su finalidad es poder retomar el trabajo después de una compactación de contexto, revisar decisiones antiguas y localizar una regresión sin reconstruir la historia a partir del código.

Se mantienen **cuatro cuadernos**. Más documentos separarían información que normalmente cambia junta y aumentarían el riesgo de que alguno quede abandonado.

1. `01_ESTADO_ACTUAL.md`: fotografía breve y autoritativa de lo que existe ahora.
2. `02_DECISIONES_Y_REGLAS.md`: decisiones técnicas y reglas jugables que no deben reinterpretarse silenciosamente.
3. `03_BITACORA_DE_TRABAJO.md`: historia cronológica de fases terminadas, cambios y correcciones.
4. `04_PRUEBAS_RIESGOS_Y_PENDIENTES.md`: pruebas reproducibles, riesgos conocidos y cola ordenada de trabajo.

## Autoridad documental

- Para saber **qué funciona ahora**, manda `01_ESTADO_ACTUAL.md`.
- Para saber **por qué se hizo así**, manda `02_DECISIONES_Y_REGLAS.md`.
- Para saber **qué cambió y cuándo**, manda `03_BITACORA_DE_TRABAJO.md`.
- Para saber **qué está verificado y qué falta**, manda `04_PRUEBAS_RIESGOS_Y_PENDIENTES.md`.
- Los documentos de `docs/history/` y los informes F01–F05 describen la construcción del motor universal. Son antecedentes, no el estado actual del nuevo juego.
- Los documentos enlazados de Google Drive siguen siendo fuentes de diseño. Una regla no se considera implementada por estar escrita allí: debe figurar como implementada en el estado actual y estar cubierta por pruebas.
- `docs/fuentes_diseno/README.md` es el índice temático del corpus y `SOURCE_MANIFEST.json` registra su sincronización. Las copias locales sirven para consulta; Drive conserva la autoridad editable.

## Protocolo de actualización

Cada fase de código debe dejar, en la misma sesión:

- el estado actual corregido;
- una entrada de bitácora con archivos y comportamiento afectados;
- el resultado real de las pruebas ejecutadas;
- los riesgos o tareas que continúan abiertos;
- cualquier decisión nueva numerada.

No se copian bloques antiguos para “guardar por si acaso”. Git, la bitácora y las decisiones numeradas conservan la historia sin crear fuentes vigentes contradictorias.
