# Línea base empírica del primer mazo — 2026-09-15

Estado: **medición inicial, no equilibrio cerrado**. Fuentes de diseño: S01 (primer mazo generalista), S02 (presupuesto provisional) y S04 (preparación y coste de Fusiones). Decisión operativa: JCP-DEC-060.

## Método reproducible

Se ejecutó `tools/run_jcp_stress_matches.gd -- --balance --games=16 --start-seed=1000 --report-tag=balance_paired_20260915` con Godot 4.7. Cada duelo usó 30 vidas reglamentarias y dos barajas de composición idéntica barajadas por separado. Las cuatro políticas ponderadas del simulador se repitieron cuatro veces cada una, alternando el jugador inicial. No son el rival automático de la mesa ni representan decisiones humanas. El informe bruto está en `diagnostic_logs/jcp_stress_balance_paired_20260915.json`; se guarda cada dos partidas con estado `RUNNING` y al completar cambia a `PASS`.

## Observaciones

| Indicador | Resultado |
| --- | ---: |
| Duelos terminados / pedidos | 16 / 16 |
| Acciones legales confirmadas | 5.623 |
| Ataques | 427 |
| Fusiones | 24 |
| Respuestas activadas | 106 |
| Finales por vida a cero | 16 |
| Turnos globales acumulados | 579 (36,2 por duelo) |
| Manos iniciales sin criatura | 1 de 32 |
| Victorias J1 / J2 | 9 / 7 |
| Victorias del jugador inicial | 11 de 16 |

Cartas vistas/jugadas al menos una vez por jugador y partida: criaturas 310/305, Magias 122/117, Trampas 113/107, Objetos 122/110 y Terrenos 71/71. `Vista` significa que la carta terminó fuera de la baraja, no que se jugara bien; `jugada` incluye preparar apoyos boca abajo y no prueba que su efecto se activara. Una carta regresada y vuelta a jugar cuenta una sola vez en este agregado. E05 (19 jugadas de 24 vistas) y E01 (19/22) merecen observación de compatibilidad y oportunidad en partidas humanas, **no** un ajuste automático. Los cruces entre victoria y carta vista/jugada son correlaciones con muestras pequeñas, no estimaciones causales de potencia.

## Decisión de esta pasada

No se modificó ninguna de las 40 cartas, receta, coste, estadística, efecto, límite ni regla. El mismo mazo gana ambos lados; las decisiones de bots y los repartos dominan esta muestra. S01 permite revisar la distribución solo si partidas reales muestran un problema práctico claro, y S02 se declara provisional. La auditoría matemática anterior no sustituye esta exigencia.

El único guardado humano local encontrado, fechado el 2026-09-11, seguía `RUNNING` con cero acciones; no había partida humana completa que medir. `tools/report_jcp_saved_match.gd` puede resumir un guardado posterior en local sin imprimir manos, barajas ni historial completo. Antes de ajustar una carta se necesitan varias partidas humanas terminadas, con semillas/guardados y una incidencia concreta (por ejemplo, carta que se queda inútil en mano, respuesta que domina o Fusión que decide el duelo sin contrajuego). Luego se comparará su tramo de coste, preparación y respuestas reales, y se cambiará una dimensión por vez con una comprobación A/B reproducible.
