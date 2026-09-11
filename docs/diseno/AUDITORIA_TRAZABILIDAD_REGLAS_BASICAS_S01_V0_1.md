# Auditoría de trazabilidad de reglas básicas S01 V0.1

Fecha: 2026-09-11  
Runtime revisado: `0.23.0-summon-attack`  
Fuente: S01, `docs/fuentes_diseno/01_MECANICAS_BASICAS_EN_DISCUSION.md`

## Alcance y resultado

Se contrastaron las reglas marcadas como **CERRADO PARA PROTOTIPO** que pertenecen al núcleo ya construido. No se convierten en obligación técnica las propuestas abiertas, el equilibrio provisional ni los sistemas aplazados.

Resultado: **ninguna discrepancia cerrada conocida permanece abierta**. La auditoría encontró y corrigió dos diferencias: derrota al robar con baraja vacía (`0.22.0`) y ataque durante el turno de una invocación normal boca arriba (`0.23.0`).

## Matriz

| Regla cerrada de S01 | Implementación vigente | Evidencia principal | Estado |
| --- | --- | --- | --- |
| 30 vidas; derrota a vida 0 o por rendición | Vida pública, final inmediato y ganadores | `run_juego_cartas_propio_combat.gd`, `run_juego_cartas_propio_phases.gd` | Completa |
| Toda criatura rival protege contra ataque directo | Objetivo directo legal solo con fila rival vacía | `run_juego_cartas_propio_combat.gd` | Completa |
| Doble comparación estricta ATQ contra DEF | Igualar no destruye; pueden morir ambas | `run_juego_cartas_propio_combat.gd` | Completa |
| Guardia evita daño sobrante; ataque lo permite | Daño diferencial condicionado por postura | `run_juego_cartas_propio_combat.gd` | Completa |
| Una criatura ataca una vez por turno por defecto | Marcador de ataque y excepciones expresas M18/F005 | combate y suites de habilidades/Fusión | Completa |
| Invocación normal boca arriba puede atacar al entrar | Acción ofrecida y validada en el mismo turno | `run_juego_cartas_propio_summon.gd` | Completa en 0.23.0 |
| El jugador inicial no ataca en el primer turno | Bloqueo común en acciones legales y validación | `run_juego_cartas_propio_summon.gd` | Completa en 0.23.0 |
| Colocada boca abajo entra en guardia y no se revela ese turno | Identidad privada y cambio de postura bloqueado | posturas, zonas y combate | Completa |
| Cambio voluntario una vez por turno posterior; quien atacó no pasa a guardia | Marcadores y rechazos específicos | `run_juego_cartas_propio_postures.gd`, combate | Completa |
| Revelación por ataque ocurre antes del cálculo y conserva guardia | Evento anterior al combate y habilidad M06 | combate y habilidades automáticas | Completa |
| Cinco espacios de criaturas y cinco de apoyo | Capacidades validadas por zona | zonas, invocación y cartas de campo | Completa |
| Equipos vinculados no ocupan apoyo; un Terreno propio activo | Zonas separadas de vínculos y Terreno | artefactos y combinaciones de Terreno | Completa |
| Mano inicial de cinco; el inicial omite su primer robo | Reparto privado y avance automático a Robo | fases, zonas y mesa | Completa |
| Robo normal de una carta por turno | Movimiento determinista a mano y evento privado | fases y efectos | Completa |
| Robar obligatoriamente con baraja vacía pierde | `deck_empty`, ganador, fase final y evento público | `run_juego_cartas_propio_phases.gd` | Completa en 0.22.0 |
| Sin descarte obligatorio por tamaño de mano | No existe límite ni acción forzada de descarte | validación de estado y recorridos de robo | Completa |
| Mazo base de 40 cartas distintas; Fusiones fuera del mazo | Una copia de cada definición por jugador; entidades de Fusión en catálogo | zonas, compatibilidad y catálogo de Fusión | Completa para mazo base |
| Una invocación o colocación normal por turno | Uso único compartido y coste de criatura | `run_juego_cartas_propio_summon.gd` | Completa |
| Magias principales desde mano; reactivas y Trampas preparadas | Modos, ventanas, cadena y turno de preparación | cartas de campo, reacciones y reacciones de Magia | Completa para G01–G07/T01–T06 |
| Magias, Trampas, objetos y Terrenos cuestan 0 por defecto | Solo criaturas y habilidades con texto consumen Energía | fases, efectos, artefactos y Terrenos | Completa para baraja inicial |
| Energía pública 1…10, aumenta y se rellena al comenzar turno | Recursos validados por jugador | `run_juego_cartas_propio_phases.gd` | Provisional implementada |

## Decisiones que siguen abiertas o fuera del primer núcleo

- Cambio de mano inicial.
- Construcción personalizada de mazos y formatos con restricciones de copias.
- Equilibrio definitivo de vida, costes, ritmo y techo efectivo de Energía.
- Ataques combinados, Perforación general y herramientas contra bloqueos defensivos.
- Compatibilidades alternativas confirmables, clases, transformaciones y resultados narrativos.
- Excepciones futuras que sustituyan robo, derrota, postura, equipo o Fusión.

Estas materias no son errores ausentes del runtime: S01 las marca como provisionales, futuras o pendientes de diseño.
