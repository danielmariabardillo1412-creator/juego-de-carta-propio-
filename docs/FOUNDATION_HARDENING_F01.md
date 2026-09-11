# F01 — Refuerzo de cimientos del motor

Fecha: 2026-07-31

Estado: **IMPLEMENTADO Y AUDITADO ESTÁTICAMENTE — RUNTIME NO EJECUTADO**

## Alcance estricto

Esta fase trabaja únicamente sobre las fronteras universales que sostienen todo juego:

- identidad y versión de módulos;
- acciones y eventos;
- respuestas del contrato de módulos;
- datos puros y límites estructurales;
- atomicidad del núcleo;
- ciclo de vida;
- snapshots canónicos;
- deduplicación de solicitudes;
- digest de estado;
- catálogo de módulos.

No se rediseñaron todavía cartas, zonas, RNG, reparto, turnos, fases de reglas, puntuación, bots ni red.

## Grietas encontradas en la entrega completa revisada

1. `module_version()` era opcional y se consultaba dinámicamente; un módulo podía cambiar de versión durante una sesión.
2. `validate_action()`, `validate_state()` y `reduce()` aceptaban Dictionaries aproximados con campos desconocidos.
3. Un módulo podía emitir nombres reservados como `engine_closed` y mezclarlos con eventos del núcleo.
4. El snapshot no tenía schema propio ni almacenaba el índice completo de request ids comprometidos.
5. No existía un validador único para contadores, acciones, eventos, lifecycle y deduplicación del snapshot.
6. La confirmación de una acción actualizaba varias estructuras internas secuencialmente, en vez de validar una candidatura completa antes del commit.
7. Las vistas públicas/privadas solo se comprobaban como Dictionary; podían contener Objects u otros valores no transportables.
8. Las acciones legales no comprobaban que pertenecieran al viewer solicitado.
9. Un engine sin arrancar podía cerrarse y dejar un lifecycle sin estado inicial.
10. El catálogo comprobaba principalmente `module_id`, no todo el contrato ni la estabilidad de versión.
11. El digest dependía de una representación JSON-like sin etiquetas explícitas de tipo.
12. El validador de datos puros limitaba profundidad, pero no nodos, tamaño de colecciones ni longitud de Strings.

## Refuerzos aplicados

### Contrato e identidad

- `module_version()` pasa a ser obligatorio.
- `module_id` y `module_version` se validan y congelan al construir el engine.
- El engine vuelve a comprobar que la identidad no deriva antes del arranque y de cada transición.
- El catálogo registra y vuelve a verificar contrato, id y versión.

### Frontera de datos

- Añadidos límites de profundidad, nodos, elementos y Strings.
- Identificadores vacíos, solo con espacios, con controles o demasiado largos se rechazan.
- Acciones y eventos serializados exigen claves exactas.
- Las respuestas de los módulos usan protocolos estrictos para éxito, rechazo y transición.

### Atomicidad

- Validación y reducción reciben acciones reconstruidas e independientes.
- El siguiente estado, log, eventos, request ids, lifecycle y contadores se preparan como candidatura.
- La candidatura completa debe superar el schema de snapshot antes de tocar el estado comprometido.
- Rechazos, respuestas malformadas y eventos inválidos dejan el snapshot completo sin cambios.

### Snapshot canónico

Schema: `zapiti-universal-engine-runtime`, versión 1.

Incluye:

- schema y versión del engine;
- módulo y versión congelados;
- config;
- lifecycle y seed;
- estado del módulo;
- acciones comprometidas;
- eventos contiguos;
- contadores;
- índice exacto `request_id -> state_version`.

El validador comprueba que:

- `state_version == actions.size()`;
- `event_sequence == events.size()`;
- las secuencias son 1..N sin huecos;
- no existen request ids comprometidos duplicados;
- el índice de request ids coincide exactamente con el action log;
- un snapshot arrancado comienza con `engine_started`;
- `FINISHED` termina en `engine_finished`;
- `CLOSED` termina en `engine_closed`.

### Digest

La representación canónica usa etiquetas explícitas:

- `n` null;
- `b` bool;
- `i` int;
- `f` float;
- `s` String;
- `a` Array;
- `d` Dictionary.

Así `1`, `1.0` y `"1"` no pueden compartir representación.

## Suite nueva

`res://tests/run_uce_f01_foundations.gd`

Cobertura prevista: **49 checks**.

Incluye módulos hostiles que intentan:

- cambiar su versión;
- devolver una transición con campos desconocidos;
- emitir eventos reservados `engine_*`;
- filtrar un Object en una vista;
- anunciar una acción legal para otro jugador.

También manipula snapshots exportados para comprobar aislamiento, gaps de eventos e índices de request ids falsificados.

## Evidencia disponible ahora

- Auditoría estática: PASS.
- Rutas `preload`: resueltas.
- Contratos directos entre scripts: resueltos.
- JSON y escenas: válidos estructuralmente.
- Archivos GDScript auditados: 54.
- Godot parser/runtime: no ejecutado deliberadamente en esta fase.

## Riesgos que siguen abiertos

1. GDScript no permite verificar estáticamente las firmas completas de métodos duck-typed.
2. El engine exige que los módulos sean lógicamente puros; todavía no puede impedir estado interno oculto dentro de un módulo.
3. Las políticas de privacidad semántica dependen del juego: un payload públicamente válido aún podría incluir información que la regla no debía revelar.
4. No existe todavía restauración directa de un engine desde snapshot; persistence/replay se revisará en su propia fase.
5. Cualquier incompatibilidad de parser o API de Godot 4.7 sigue pendiente de ejecución real.

## Próxima fase propuesta

**F02 — Cartas, definiciones, instancias, mazos y zonas.**

Se revisarán unicidad, propiedad, visibilidad, capacidad, orden, transferencias atómicas, cartas repetidas y ausencia de cartas huérfanas o duplicadas.
