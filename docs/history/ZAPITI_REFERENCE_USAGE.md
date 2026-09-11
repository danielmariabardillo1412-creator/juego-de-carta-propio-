# Uso de la referencia de Zápiti

## Material consultado

- `Zapiti_Engine_Copy/engine_full.gd`
- `Zapiti_Engine_Copy/ENGINE_REFERENCE.md`
- `Zapiti_Engine_Copy/docs/RULES.md`

El archivo consolidado contiene 14 scripts originales del motor de Zápiti. No se ha modificado ni copiado dentro del nuevo laboratorio.

## Patrones aprovechados como experiencia

1. Un único punto canónico para aplicar acciones.
2. Separación entre acción, resultado y evento.
3. Secuencia incremental de eventos.
4. Vista pública y vista específica del jugador.
5. Semilla explícita y registro de acciones.
6. Estado del motor separado de la IA de los bots.

## Elementos deliberadamente no copiados

- Baraja española fija.
- Cuatro jugadores y parejas 0-2 / 1-3.
- Ronda, mano, chica y chinos.
- Jerarquía propia de Zápiti.
- Apuestas de truco.
- Regla de 29.
- Señas.
- Controlador monolítico de reglas.
- Formato de persistencia específico `zapiti-save`.

## Conclusión

UCE-01 adopta únicamente patrones de frontera que demostraron utilidad. No intenta generalizar `controller.gd`, ni convertir clases específicas de Zápiti en clases supuestamente universales.
