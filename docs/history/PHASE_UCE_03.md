# UCE-03 — Deterministic RNG, Shuffle and Deal

## Objetivo

Añadir aleatoriedad reproducible y operaciones genéricas de preparación de cartas sin introducir reglas de ningún juego.

## Alcance implementado

1. RNG puro basado en `lcg31-v1` con estado serializable.
2. Semilla explícita y contador de extracciones.
3. Vectores conocidos para comprobar implementaciones en otros lenguajes.
4. Enteros acotados mediante rejection sampling para evitar sesgo de módulo.
5. Fisher-Yates que devuelve un array nuevo y un estado RNG avanzado.
6. Barajado de una zona sin mutar el estado de cartas suministrado.
7. Reparto round-robin atómico entre zonas existentes.
8. Selección explícita del extremo de extracción: START o END.
9. Prevalidación de cartas disponibles, destinos y capacidades antes de mover.
10. Fixture integrado que baraja seis cartas y reparte dos a dos jugadores.

## Fuera de alcance

- Turnos y fases.
- Reglas de prioridad o ganador.
- Puntuación.
- Repartos condicionales específicos de juegos.
- Quemar cartas, repartir lotes irregulares o mercados comunes.
- Persistencia en disco.
- Replay completo de acciones.
- Criptografía o aleatoriedad segura para apuestas con dinero.
- Integración directa con el motor actual de Zápiti.

## Invariantes

- La misma semilla, algoritmo y secuencia de llamadas producen el mismo resultado.
- El estado RNG anterior permanece intacto.
- Un shuffle conserva exactamente los mismos elementos.
- Un reparto fallido no mueve ninguna carta.
- El orden de destinos define el orden round-robin.
- El extremo superior del mazo nunca se presupone: cada llamada declara START o END.
