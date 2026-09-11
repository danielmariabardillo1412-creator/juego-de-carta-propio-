# Guía para crear un módulo de juego

## Principio

El módulo es el único lugar que conoce las reglas concretas. El núcleo solo valida el contrato y aplica transiciones atómicas.

## Estado recomendado

Un estado de juego completo suele contener:

```text
seed
config
players
cards
rng
turn
phase
scores
round/match data
winner_ids
finished_reason
```

Todos los valores deben ser datos puros: null, bool, int, float finito, String, Array y Dictionary con claves String.

## Validación

`validate_action()` no modifica estado. `reduce()` recibe otra copia y devuelve:

```gdscript
{
    "ok": true,
    "state": next_state,
    "events": [
        {"type": "event_name", "payload": {}, "visible_to": []}
    ]
}
```

`visible_to: []` significa evento público. Una lista de ids restringe el evento a esos jugadores.

## Información oculta

No construyas manualmente vistas de manos ocultas. Usa `CardState.view_for(cards, viewer_id)` y selecciona correctamente la visibilidad de cada zona.

## Acciones legales

`get_legal_actions()` debe devolver descripciones serializables. Estas sirven a interfaz, red y bots. La validación real sigue estando en `validate_action()`; la lista legal no sustituye la seguridad del servidor.

## Referencia completa

Consultar `games/high_card_arena/high_card_arena_module.gd`.
