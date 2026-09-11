# Auditoría de estrés automático V0.1

Fecha: 2026-09-11  
Runtime cerrado: `0.24.0-stress-hardening`

## Objetivo

Forzar partidas completas con decisiones variadas antes de dedicar tiempo a pruebas humanas. Cada fallo conserva semilla, paso, acción y estado para hacerlo reproducible.

## Dos niveles

- `tools/run_jcp_rule_stress.gd`: recorre rápidamente el módulo de reglas, valida acciones legales, transiciones, eventos, estado final, ganador o empate y huella canónica.
- `tools/run_jcp_stress_matches.gd`: atraviesa `UniversalCardEngine` y añade atomicidad, versiones, vistas, snapshots y muestras de replay completo.

Las políticas alternan desarrollo de campo, agresión, respuestas y selección exploratoria. La vida reducida multiplica combates y desenlaces; el nivel UCE incluye también partidas con 30 vidas. El agotamiento de baraja conserva además su recorrido específico de 48 comprobaciones.

## Fallos encontrados y corregidos

1. Semilla 1, paso 46: después de atacar, Principal 2 anunciaba un cambio a guardia que `validate_action()` rechazaba con `JCP_POSITION_AFTER_ATTACK`.
2. Semilla 9, paso 282: una Fusión previa podía aparecer como material de otra Fusión, aunque `JCP_FUSION_CHAIN_NOT_ENABLED` la rechazaba.

Ambos fallos eran discrepancias entre el conjunto legal anunciado y la validación. Se corrigieron y recibieron regresiones específicas.

## Barrido limpio posterior

- Partidas: **2.110**.
- Acciones aceptadas: **137.300**.
- Fusiones: **931**.
- Ataques: **7.770**.
- Respuestas activadas: **2.767**.
- Elecciones de combate de F067: **379**.
- Redirecciones de M13: **83**; rechazos de redirección: **53**.
- Traslados de equipo: **275**.
- Empates por vida cero simultánea: **85**, todos representados como final sin ganador.
- Fallos después de las correcciones: **0**.

## Alcance de la evidencia

El resultado demuestra coherencia y resistencia para las combinaciones recorridas; no demuestra equilibrio competitivo ni comodidad de interfaz. La siguiente fuente de información útil es una partida humana, especialmente para ritmo, comprensión de objetivos, relevo privado y lectura del registro.

## Ampliación duradera

Run `long_20260911_073150`, semillas 1.000.000–1.010.024:

- 10.000 partidas mediante el módulo de reglas y ocho perfiles de conducta.
- 25 partidas adicionales mediante `UniversalCardEngine`; dos se reconstruyeron por replay completo.
- **10.025 partidas y 907.265 acciones**, cero fallos del motor.
- 4.323 Fusiones, 37.057 ataques, 13.322 respuestas activadas, 1.811 elecciones de F067, 509 redirecciones de M13 y 1.736 traslados de equipo.
- 55 derrotas por baraja vacía y 470 empates por vida cero simultánea.

Sumada a la primera puerta, la evidencia acumulada posterior a las dos correcciones asciende a **12.135 partidas y 1.044.565 acciones limpias**.
