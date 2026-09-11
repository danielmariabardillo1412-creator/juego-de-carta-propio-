# Hallazgos de revisión previa al primer arranque

## Integridad de contexto

No se encontraron señales de contenido cortado, pegado a medias o sustituido por relleno. La auditoría recorre todos los scripts, recursos, JSON y contratos directos entre módulos cargados con `preload`.

Esto no demuestra que Godot vaya a compilarlo ni que la lógica sea perfecta. Demuestra que el paquete tiene continuidad estructural y que las referencias internas visibles son coherentes.

## Fallos reales o latentes encontrados

### BOT_REQUEST_ID_REUSE

El adaptador fabricaba siempre `bot:<actor_id>`. El segundo turno del mismo bot podía rechazarse como duplicado. El request id queda ahora en manos del llamador y por defecto es vacío.

### SAVE_JSON_NUMERIC_TYPE_LOSS

JSON ordinario no conserva la distinción de tipos numéricos que necesita el estado. Se introdujo un árbol JSON tipado: enteros y floats se codifican y restauran explícitamente antes de validar el checksum.

### PHASE_GRAPH_AND_HISTORY_GAPS

El grafo permitía destinos sin nodo propio y el estado no demostraba que su historial siguiera transiciones legales. Ahora el grafo debe estar cerrado y `entry_count` debe coincidir exactamente con el historial.

### INITIALIZATION_RESULT_ASSUMPTIONS

El juego demostrador accedía a resultados intermedios suponiendo éxito. Cada servicio propaga ahora un error estructurado y el núcleo devuelve un fallo de arranque legible.

### ACTION_OBJECT_CROSS_PHASE_MUTATION

El mismo objeto de acción llegaba a `validate_action()` y `reduce()`. Un módulo defectuoso podía modificarlo durante la validación. El núcleo reconstruye copias canónicas e independientes y conserva un action log inmutable.

### REPLAY_PARTIAL_COMPARISON

El replay comparaba únicamente `module_state`. Ahora valida claves, config, módulo, versión, ciclo de vida, contadores, acciones y eventos; después compara el digest del snapshot completo.

### SAVE_CONSISTENCY_AND_FILE_ROBUSTNESS

Se verifica que versión y ciclo de vida coincidan entre paquete y snapshot. La escritura crea directorios, comprueba errores de escritura y distingue fallo de commit de fallo de rollback.

### SYNC_AND_DEMO_BOUNDARIES

La sincronización valida ahora el viewer mediante el módulo y rechaza participantes inexistentes, no únicamente números negativos. La demo informa si supera el límite de acciones o si el guardado no puede construirse.

### ROUND_ANCHOR_AND_GAME_ROUND_DRIFT

El flujo genérico podía contar una ronda al cruzar la silla cero aunque la ronda hubiera comenzado en otra silla. Además, el contador genérico y el contador específico de High Card podían separarse después de una victoria o empate. Ambos usan ahora un ancla explícita y avanzan conjuntamente, incluido el snapshot terminal.

### CORE_TO_AI_DEPENDENCY_INVERSION

El protocolo central estaba a punto de utilizar una clase alojada bajo `src/ai`. El contrato de acción legal se movió a `src/core`, dejando la IA como consumidora opcional del núcleo.

### CARD_VISIBILITY_AND_TRACKING

Una zona oculta necesitaba separar visibilidad del conteo y revelación parcial. Las vistas ocultas ya no publican IDs opacos estables con los que un cliente pudiera seguir una carta entre zonas.

### COMPLETE_TEST_DUPLICATE_LOCAL

La suite integral contenía una declaración local duplicada consecutiva. Se eliminó y la auditoría estática incorpora una detección específica para esta familia de error.

## Lo que el diagnóstico puede aislar

- archivo ausente o no cargable;
- error al construir módulo/núcleo;
- estado inicial inválido;
- fuga de información privada;
- mutación por acción rechazada;
- contaminación del objeto de acción;
- partida que no termina;
- divergencia de versiones/eventos;
- fallo de guardado, escritura o lectura;
- replay divergente;
- sync o viewer inválido;
- acción de bot inventada o mutación de la lista legal;
- divergencia entre ronda genérica y ronda del juego;
- trato no determinista de la semilla.

## Límites inevitables

- Un error de parser en el bootstrap se ve en el log externo, no en el JSON interno.
- Un crash nativo antes de `_ready()` solo puede registrarse mediante stderr/código de salida.
- Un cierre forzado por el sistema operativo puede impedir que se complete el último checkpoint.
- Ningún diagnóstico finito cubre todas las reglas futuras de módulos todavía no escritos.
