# Juego de cartas propio — laboratorio sobre Zapiti Universal Card Engine

Laboratorio independiente para construir el segundo juego de cartas sobre el motor universal de Godot 4.7. Esta carpeta contiene tanto la baseline F05 del motor como el módulo vigente `zapiti.juego_cartas_propio`.

## Estado actual

Módulo: **0.24.0 — Stress Hardening**.

Estado: **mesa manual local funcional + vertical slice prehumana visual/onboarding; CI y RUNTIME PASS en Godot 4.7 estable**.

La descripción breve del sistema jugable está en `JUEGO_CARTAS_PROPIO.md`. La memoria autoritativa para retomar el trabajo está en `docs/cuadernos/README.md`.

## Baseline del motor

Build de origen: **F05 — Systems Hardened**.

Capas reforzadas acumulativamente:

- **F01 — Cimientos:** acciones, eventos, contratos de módulo, atomicidad, ciclo de vida y snapshots.
- **F02 — Cartas y zonas:** definiciones, instancias físicas, mazos, visibilidad, movimientos y conservación.
- **F03 — Sesión y flujo:** jugadores, equipos, turnos, rondas, fases, puntuación y victoria.
- **F04 — Persistencia y red:** guardado tipado, almacenamiento atómico, replay y paquetes de sincronización.
- **F05 — Interfaces y bots:** acciones legales, validación de espectadores/jugadores, políticas de bot y fronteras externas.

La baseline ya fue compilada y ejecutada en este entorno. El último cierre obtuvo 15/15 etapas diagnósticas y 80/80 comprobaciones integrales; el laboratorio del nuevo juego suma además 1.357 comprobaciones específicas en 22 suites. Las puertas de estrés reproducibles han completado en total 12.135 partidas y 1.044.565 acciones tras corregir dos desacuerdos entre enumeración y validación.

## Fuente única

No hay que unir B01, B02, B03, F01 ni paquetes experimentales. El ZIP F05 contiene todo:

- `src/` — núcleo y servicios del motor;
- `games/` — módulos de juegos, incluido High Card Arena;
- `tests/` — regresiones B01–B03, F01–F05 e integración completa;
- `demo/` — bootstrap diagnóstico y demostración;
- `docs/` — arquitectura, hallazgos y alcance de cada fase;
- `tools/` — manifiesto y auditoría estática.

## Próxima fase

Realizar la primera sesión humana controlada sobre `main @ afa92a02d7a1397ff8e0481408f11e173c61a1aa`: guía breve de seis páginas, 10–15 minutos de juego libre sin ayuda procedural y después los escenarios H1–H7 que no hayan aparecido de forma natural. La capa visual actual es deliberadamente provisional y sirve para medir comprensión operacional, no calidad artística final. No iniciar balance antes de registrar esa evidencia. La integración con Zapity sigue fuera de esta capa.

## Documentos principales

- `docs/cuadernos/README.md`
- `docs/cuadernos/01_ESTADO_ACTUAL.md`
- `docs/cuadernos/02_DECISIONES_Y_REGLAS.md`
- `docs/cuadernos/03_BITACORA_DE_TRABAJO.md`
- `docs/cuadernos/04_PRUEBAS_RIESGOS_Y_PENDIENTES.md`
- `docs/CURRENT_STATE.md` — estado histórico de F05
- `docs/FOUNDATION_HARDENING_F01.md`
- `docs/CARDS_ZONES_HARDENING_F02.md`
- `docs/SESSION_FLOW_HARDENING_F03.md`
- `docs/PERSISTENCE_SYNC_HARDENING_F04.md`
- `docs/INTERFACES_AI_HARDENING_F05.md`
- `docs/TEST_PLAN_COMPLETE.md`
