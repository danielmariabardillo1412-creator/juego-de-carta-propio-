# F05 — Interfaces externas, acciones legales y bots

## Objetivo

Evitar que UI, red, espectadores o políticas de bot introduzcan acciones o vistas que el núcleo nunca autorizó.

## Acciones legales

El contrato reside en `src/core/legal_action.gd`; el núcleo no depende de la carpeta de IA.

Una acción legal debe tener:

- identificador y actor válidos;
- etiqueta acotada;
- payload y metadatos de datos puros;
- claves exactas;
- ausencia de duplicados en la lista publicada.

## Viewers

Un módulo puede implementar `validate_viewer`. High Card Arena rechaza jugadores/espectadores desconocidos antes de construir vistas, acciones o paquetes de sincronización.

## Bots

El adaptador:

1. obtiene la lista canónica de acciones legales;
2. entrega copias aisladas a la política;
3. valida la respuesta;
4. exige que la selección coincida exactamente con una acción canónica;
5. genera o acepta un `request_id` único;
6. devuelve el índice legal elegido para trazabilidad.

Una política no puede inventar una acción, modificar la lista original ni reutilizar silenciosamente una petición fija.

## Integración demostradora

High Card Arena se endureció para validar orden de jugadores que ya actuaron, privacidad y capacidades de zonas, ronda/turno, baraja exacta y condiciones terminales.

## Suite

`res://tests/run_uce_f05_interfaces_ai.gd`

Estado: implementada, no ejecutada con Godot.
