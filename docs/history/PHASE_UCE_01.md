# UCE-01 — Action/Event Pipeline Foundation

## Frontera del bloque

Este bloque demuestra que un módulo de reglas puede vivir detrás de una interfaz universal sin que el motor conozca su juego.

## Contrato del módulo

Un módulo debe implementar:

- `module_id()`
- `create_initial_state(config, seed)`
- `validate_action(state, action)`
- `reduce(state, action)`
- `get_public_state(state)`
- `get_player_state(state, viewer_id)`
- `is_finished(state)`

## Invariantes

1. Una acción rechazada no cambia estado, versión, log ni eventos.
2. Una transición defectuosa no se compromete parcialmente.
3. El motor, no el módulo, asigna la secuencia global de eventos.
4. Los eventos privados solo son visibles para los jugadores autorizados.
5. Las vistas reciben copias del estado.
6. Una sesión terminada no admite más acciones.
7. La semilla efectiva queda registrada.
8. Estado y payloads no contienen Objects, Resources, Callables ni claves no textuales.

## Riesgos conocidos

- Código todavía no interpretado por Godot.
- El contrato se valida por nombres de métodos, no por firmas estáticas.
- No existe todavía validación profunda del estado devuelto por cada módulo.
- El snapshot es de ejecución; todavía no es un formato estable de persistencia.
- No se ha decidido aún el esquema de compatibilidad entre versiones de módulos.
