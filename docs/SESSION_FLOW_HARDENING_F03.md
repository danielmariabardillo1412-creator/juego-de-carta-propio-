# F03 — Jugadores, turnos, fases y puntuación

## Objetivo

Asegurar que el flujo temporal de una partida no pueda producir rondas, fases o marcadores imposibles.

## Registro de jugadores

- IDs, asientos y nombres únicos.
- Equipos opcionales con miembros válidos.
- Metadatos públicos separados de datos internos.
- Límites explícitos de participantes.

## Turnos y rondas

- Orden y dirección explícitos.
- Jugador activo verificable.
- Ancla de inicio de ronda independiente de la silla cero.
- La ronda aumenta solo al volver al jugador que la inició.
- Inversión de dirección y retirada de jugadores conservan un estado válido.

Se corrigió un defecto conceptual del prototipo: iniciar en una silla distinta de cero podía incrementar la ronda antes de que todos actuaran.

## Fases

- Grafo cerrado: todo destino debe existir.
- Estados terminales sin salidas.
- Alcanzabilidad desde el inicio.
- Historial compatible con las transiciones declaradas.
- Conteos de entrada coherentes.

## Puntuación

- Valores numéricos finitos.
- Objetivos `AT_LEAST`, `AT_MOST` o `EXACT`.
- Liderazgo alto o bajo según el juego.
- Ganadores calculados de forma determinista.

## Suite

`res://tests/run_uce_f03_session_flow.gd`

Estado: implementada, no ejecutada con Godot.
