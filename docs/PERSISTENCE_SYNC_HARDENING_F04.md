# F04 — Persistencia, replay y sincronización

## Objetivo

Hacer que guardar, recuperar, reproducir y sincronizar una partida preserve el significado exacto del snapshot.

## Guardado tipado

JSON ordinario no conserva necesariamente la diferencia entre enteros y flotantes. El codec usa una representación tipada y canónica para:

- `null`, booleanos, enteros, flotantes y cadenas;
- arrays y diccionarios con claves ordenadas;
- identidad/version del paquete y snapshot;
- checksum del contenido canónico.

Se rechazan flotantes no finitos y representaciones no canónicas.

## Almacenamiento

- Solo rutas bajo `user://`.
- Sufijo y traversal validados.
- Límite de tamaño.
- Escritura temporal, backup y commit.
- Recuperación/rollback con errores diferenciados.

## Replay

El replay reconstruye desde configuración, semilla y acciones, y compara el snapshot completo, no únicamente el estado específico del juego. Puede señalar la primera diferencia estructural.

## Sincronización

Los paquetes incluyen:

- schema, motor, módulo y versiones;
- destinatario/viewer válido;
- versión de estado y secuencias;
- vista filtrada y eventos visibles;
- digest de estado y eventos.

## Suite

`res://tests/run_uce_f04_persistence_sync.gd`

Estado: implementada, no ejecutada con Godot.
