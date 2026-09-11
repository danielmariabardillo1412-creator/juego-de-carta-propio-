# Arquitectura completa experimental

## 1. Núcleo

`UniversalCardEngine` mantiene una sesión y no conoce reglas concretas. Recibe `GameAction`, solicita validación al módulo, calcula una transición sobre copias y solo después realiza un commit atómico.

Responsabilidades:

- ciclo CREATED/RUNNING/FINISHED/CLOSED;
- semilla explícita;
- estado puro portable;
- validación opcional del estado del módulo;
- eventos secuenciados con visibilidad;
- deduplicación de `request_id`;
- vistas públicas y privadas;
- acciones legales opcionales;
- snapshot, digest y registro de acciones.

## 2. Contrato de un juego

Métodos obligatorios:

```text
module_id()
create_initial_state(config, seed)
validate_action(state, action)
reduce(state, action)
get_public_state(state)
get_player_state(state, viewer_id)
is_finished(state)
```

Métodos opcionales usados por el núcleo completo:

```text
module_version()
validate_config(config)
validate_state(state)
get_legal_actions(state, viewer_id)
```

## 3. Dominio de cartas

Se separan tres conceptos:

- `CardDefinition`: qué tipo de carta es.
- `CardInstance`: una copia física única.
- `ZoneDefinition`: lugar ordenado y política de visibilidad.

`CardState` garantiza que cada instancia existe exactamente en una zona.

## 4. Determinismo

El RNG `lcg31-v1` es estado puro y portable. El barajado usa Fisher-Yates. Estado inicial + semilla + acciones aceptadas deben reconstruir el mismo estado.

## 5. Servicios universales

- `PlayerRegistry`: jugadores, equipos y asientos.
- `TurnState`: orden, dirección y jugador activo.
- `PhaseMachine`: grafo explícito de fases.
- `ScoreState`: tabla y objetivo.
- `DataPath`: acceso inmutable a datos anidados.
- `ConditionEvaluator`: lenguaje pequeño de condiciones.
- `EffectExecutor`: efectos genéricos básicos.
- `DeckBuilder`, `CardOperations`, `CardQuery`.

## 6. Persistencia

`SaveCodec` encapsula el snapshot y genera SHA-256 canónico. `ReplayService` reconstruye la partida con semilla y acciones y compara el digest del estado final. `SaveFileStore` realiza escritura temporal y commit por renombrado.

## 7. Red y bots

`SyncPacket` entrega estado filtrado, eventos visibles y digest. `BotAdapter` consume la enumeración de acciones legales del módulo y una política reemplazable.

## 8. Extensibilidad

El motor no intenta expresar toda regla imaginable mediante una tabla universal. Los servicios son genéricos; las reglas complejas viven en módulos de juego aislados. Esta frontera evita convertir el motor en otro Zápiti cerrado.
