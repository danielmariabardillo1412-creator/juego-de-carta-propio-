# UCE-02 — Card / Instance / Zone Foundation

## Objetivo

Añadir una capa de dominio de cartas completamente separada de las reglas de cualquier juego.

## Alcance implementado

1. Definiciones de carta con atributos y etiquetas arbitrarios.
2. Instancias físicas independientes de las definiciones.
3. Zonas ordenadas con capacidad opcional.
4. Visibilidad de identidades PUBLIC, OWNER, HIDDEN o LISTED.
5. Estado puro con invariantes globales de colocación.
6. Movimiento atómico e inmutable de una carta entre zonas.
7. Vistas con ocultación de identidades.
8. Fixture de integración que roba dos cartas mediante UniversalCardEngine.

## Fuera de alcance

- Barajado y RNG.
- Reparto múltiple.
- Movimiento por lotes.
- Pilas con orientación o cartas boca arriba/boca abajo.
- Propiedad permanente de cartas.
- Reglas de turnos.
- Puntuación.
- Persistencia y replay.
- Integración con el motor real de Zápiti.

## Autoridad de las reglas

La capa de cartas garantiza estructura e invariantes. Cada módulo de juego continúa siendo responsable de decidir quién puede mover una carta, cuándo y por qué.
