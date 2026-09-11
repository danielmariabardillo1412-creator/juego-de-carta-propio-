# Estado histórico de la baseline F05

> Este documento conserva el estado del motor universal a 2026-07-31. Ya no es el estado vigente del juego de cartas propio. Para retomar el desarrollo debe leerse `docs/cuadernos/01_ESTADO_ACTUAL.md`.

Fecha: 2026-07-31

Build: **F05 — Systems Hardened**

Estado: **STATIC_REVIEW_PASS / RUNTIME_UNTESTED**

## Baseline externa conservada

- UCE-01: PASS 27/27 en Godot 4.7.
- UCE-02: PASS 58/58 en Godot 4.7 después de una corrección exclusiva del script de prueba.
- Ningún archivo `src/` de B01/B02 necesitó corrección en aquella ejecución.
- UCE-03 y las capas F01–F05 todavía no tienen certificación de runtime.

## Capas reforzadas

### F01 — Cimientos

Contratos estrictos de acciones/eventos/módulos, datos puros, identidad y versión congeladas, transición atómica, ciclo de vida y snapshot canónico.

### F02 — Cartas, mazos y zonas

Inventario total verificable, instancias únicas, movimientos masivos atómicos, zonas con políticas independientes de identidad y conteo, reparto desigual y ocultación parcial sin identificadores estables filtrados.

### F03 — Sesión y flujo

Jugadores/equipos estrictos, turnos anclados, rondas correctas aunque el inicio no sea la silla cero, grafo de fases cerrado y alcanzable, puntuación finita y condiciones de objetivo explícitas.

### F04 — Persistencia, replay y sincronización

JSON tipado que conserva enteros/flotantes, guardado limitado y atómico, recuperación de backup, replay de snapshot completo y paquetes de sincronización con identidad, versión y digests.

### F05 — Interfaces y bots

Contrato de acciones legales trasladado al núcleo, rechazo de viewers inexistentes, bots obligados a elegir una acción canónica y aislamiento de mutaciones externas.

## Integración High Card Arena

El juego demostrador valida además:

- mazo estándar exacto de 52 cartas;
- privacidad/capacidad de cada zona;
- correspondencia entre mesa, jugadores ya actuados y orden de turno;
- sincronía entre ronda genérica y ronda del juego;
- condiciones de finalización, motivo y ganadores;
- imposibilidad de permanecer RUNNING después de cumplir una condición terminal.

## Auditoría estática

PASS. Comprueba estructura, manifiesto, JSON, preload, escenas, contratos conocidos y patrones problemáticos. No prueba parser ni runtime de Godot.

## Puerta obligatoria

La siguiente fase es ejecución, no desarrollo:

1. integridad del paquete;
2. diagnóstico escalonado;
3. UCE-01, UCE-02 y UCE-03;
4. F01–F05;
5. integración completa;
6. escena principal.
