# F02 — Cartas, mazos, instancias y zonas

## Objetivo

Convertir el subsistema de cartas en un inventario conservativo: ninguna operación válida puede crear, duplicar, perder o colocar dos veces una instancia física.

## Refuerzos

- Definiciones de carta inmutables y datos puros.
- Instancias físicas con `instance_id` único, definición, propietario y metadatos.
- Constructor de mazos con conteos, secciones, serial y `copy_index`.
- Validación de capacidad, propietarios y referencias.
- Cada instancia debe estar exactamente en una zona.
- Movimientos simples y masivos preparados como una sola candidatura atómica.
- Reordenación dentro de una zona sin pérdida de cartas.
- Reparto desigual por jugador mediante conteos explícitos.
- Digest de inventario antes/después para verificar conservación.

## Privacidad

La política de una zona separa:

- quién ve la identidad de las cartas;
- quién ve únicamente el número de cartas;
- si se revela un borde inicial o final de la pila;
- si el propietario o una lista concreta puede verla.

Las cartas ocultas se representan como ranuras sin exponer IDs opacos estables que permitan rastrearlas entre vistas.

## Suite

`res://tests/run_uce_f02_cards_hardening.gd`

Estado: implementada, no ejecutada con Godot.
