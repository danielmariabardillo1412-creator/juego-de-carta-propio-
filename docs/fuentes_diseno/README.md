# Índice de fuentes de diseño

Este directorio es una **caché local de consulta** del corpus de diseño de Google Drive. Los originales de Drive continúan siendo la fuente editable. La caché existe para poder buscar, citar y leer únicamente el bloque necesario de cada fase sin cargar todos los documentos en el contexto.

La carpeta oficial es **`JUEGO_CARTAS_PROPIO`**, ID `1m54Q-WmufRhdVleWMq6mTwUbP3Nzxqcl`. No debe confundirse con **`Juego de cartas original — Diseño y reglas`**, que contiene documentación anterior y no sustituye este corpus S00–S05. La auditoría de reconciliación del 2026-09-15 está en `docs/diseno/AUDITORIA_RECONCILIACION_DRIVE_CONTENIDO_LOCAL_V0_1.md`.

## Regla de autoridad

1. Una afirmación sobre el diseño debe indicar el documento que la respalda.
2. El estado escrito dentro del documento —ABIERTO, PROVISIONAL, CERRADO PARA PROTOTIPO o DESCARTADO— se conserva; estar en la caché no convierte una idea en regla implementada.
3. `docs/cuadernos/01_ESTADO_ACTUAL.md` determina qué está implementado y probado.
4. Si Drive tiene una revisión posterior a `SOURCE_MANIFEST.json`, se sincroniza primero la fuente afectada y se revisa el índice antes de modificar reglas.
5. Si una asignación no aparece explícitamente, se registra como **falta diseñarla**. No se deduce de una ilustración, estadísticas, elemento o ejemplo conceptual.

## Inventario

| Clave | Documento local | Función principal |
| --- | --- | --- |
| S00 | `00_ESTADO_Y_METODO_DE_TRABAJO.md` | Método, estados de decisión, límites y orden del diseño. |
| S01 | `01_MECANICAS_BASICAS_EN_DISCUSION.md` | Reglas del duelo, turnos, zonas, cartas, compatibilidad, narrador y primer mazo. |
| S02 | `02_TABLA_PRESUPUESTO_DE_CARTAS_V0_1.md` | Presupuestos, valores, fórmulas y notas de equilibrio. |
| S03 | `03_BIBLIA_DE_FAMILIAS_Y_COMBINACIONES_V0_1.md` | Taxonomía: familia, superfamilia, elemento, anatomía, disciplina, aptitud y rutas temáticas. |
| S04 | `04_LIBRO_DE_FUSIONES_V0_1.md` | Contrato de Fusión, materiales, recetas y resultados conceptuales. |
| S05 | `05_PERSONAJES_ESPECIALES_Y_CARTAS_DE_AMIGOS_V0_1.md` | Identidades especiales, excepciones y rutas futuras reservadas. |

## Rutas de lectura por fase

| Fase o pregunta | Leer primero | Ampliar solo si hace falta |
| --- | --- | --- |
| Vida, derrota, daño y combate | S01: `MECÁNICA 01` y bloques de combate | S02 para presupuesto numérico. |
| Turnos, fases, energía, robo y zonas | S01: mecánicas y cierres correspondientes | S00 para comprobar estado y método. |
| Primer mazo M01–M18, G01–G07, T01–T06, E01–E06 y R01–R03 | S01: `LOTE PROVISIONAL` y bloques del tipo de carta | S02 para valores; S03 si se asigna identidad. |
| Anatomía, aptitudes, objetos y grimorios | S01: `NOTA DE DISEÑO FUTURO — APTITUDES, ANATOMÍA Y NARRADOR` y `AMPLIACIÓN — APTITUDES MODIFICABLES` | S03: `PRINCIPIOS DE CLASIFICACIÓN`; S04 para equipo heredado por una Fusión. |
| Identidad, especie, familia o disciplina de una criatura | S03: clasificación y familia elegida | S01 para comprobar el esqueleto M correspondiente; S05 solo si es personaje especial. |
| Terrenos y transformaciones ambientales | S01: bloque de Terrenos | S03 para propiedades derivadas; S04 para recetas relacionadas. |
| Fusiones | S04 completo para el contrato y la receta concreta | S03 para taxonomía; S01 para materiales del mazo; S05 si interviene un personaje especial. |
| Narrador/locutor | S01: `FUNCIÓN DEL NARRADOR`, `PAPEL DEL NARRADOR` y `NARRADOR` | S00 para el principio general. El narrador describe; el motor decide. |
| Personajes especiales | S05: personaje concreto | S03 y S04 para compatibilidad y receta. |
| Equilibrio y coste | S02 y la carta concreta de S01 | S04 si es una Fusión. |

## Hallazgo vigente sobre M01–M18

S01 sí define la separación entre anatomía y aptitudes y asigna provisionalmente elemento y Manipulador a M01–M18. Sin embargo, el propio bloque `ASIGNACIÓN PROVISIONAL — ELEMENTOS Y MANIPULACIÓN DE LAS 18 CRIATURAS` indica que **los nombres, especies, anatomías y habilidades concretas se diseñarán después**. Por tanto:

- la infraestructura anatómica procede de los papeles;
- el reparto de Manipulador procede de los papeles;
- la anatomía concreta de cada M01–M18 todavía no está escrita y debe diseñarse, no adivinarse.

## Procedimiento breve para una fase

1. Leer los cuatro cuadernos vivos.
2. Consultar este índice y escoger la ruta de lectura.
3. Ejecutar `tools/check_design_source_cache.ps1`.
4. Buscar el término dentro de las fuentes seleccionadas y leer el bloque completo que lo rodea.
5. Registrar en la decisión o bitácora las claves S00–S05 utilizadas.
6. Si la fuente guarda silencio o marca algo como pendiente, detener la implementación de ese dato y anotarlo como decisión de diseño necesaria.

## Sincronización

`SOURCE_MANIFEST.json` conserva los IDs, URLs, revisiones y fechas observadas. La comprobación local garantiza integridad, pero no consulta Internet. Al comenzar una fase de diseño o cuando el usuario indique que cambió los papeles, se comparan los metadatos actuales de Drive con el manifiesto y solo se vuelve a descargar el documento modificado.
