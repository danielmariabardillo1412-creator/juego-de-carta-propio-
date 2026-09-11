# Matriz de cobertura de criaturas M01–M18 V0.1

Fuentes: S01 y S03, sin cambios en Drive respecto al manifiesto, y baraja inicial aprobada localmente. Esta matriz distingue identidad registrada de habilidad ejecutable.

| ID | Habilidad aprobada | Estado al abrir la auditoría | Bloque |
| --- | --- | --- | --- |
| M01 | Sin habilidad | Completa | Básica |
| M02 | Sin habilidad | Completa | Básica |
| M03 | Sin habilidad | Completa | Básica |
| M04 | Sin habilidad | Completa | Básica |
| M05 | +1 ATQ durante el combate al declarar ataque | Completa | Automática |
| M06 | +1 DEF en el combate al revelarse por un ataque | Completa | Automática |
| M07 | Al ser destruido, roba 1 | Completa | Automática |
| M08 | Sin habilidad | Completa | Básica |
| M09 | Paga 1 Energía una vez por turno: +1 ATQ ese turno | Completa | Acción propia |
| M10 | En guardia obtiene +1 ATQ | Completa | Continua |
| M11 | Sin habilidad | Completa | Básica |
| M12 | Al entrar visible, mira un apoyo rival oculto | Completa | Información privada |
| M13 | Una vez por turno redirige hacia sí un ataque a otra criatura propia | Completa | Elección durante ataque |
| M14 | Sin habilidad | Completa | Básica |
| M15 | Al entrar visible, otra criatura propia obtiene +1/+1 ese turno | Completa | Objetivo de entrada |
| M16 | Primera destrucción de criatura en combate de cada turno: recupera 1 Energía | Completa | Automática |
| M17 | Sin habilidad | Completa | Básica |
| M18 | Primera destrucción con supervivencia de cada turno: ataque adicional | Completa e independiente de F005 | Automática |

Resultado cerrado en `0.21.0-creature-abilities`: las dieciocho criaturas tienen su texto aprobado ejecutable y probado. Las Fusiones no heredan estas habilidades salvo texto expreso; una carta física usada como portador deja de ejecutar su identidad base mientras contiene una entidad de Fusión.

Cobertura específica: 25 comprobaciones automáticas, 39 de acciones/objetivos/privacidad y 38 verticales mediante `UniversalCardEngine` con replay exacto. Con las 55 comprobaciones de mesa manual, fases ampliadas a 48, invocación a 32, posturas a 69 y acción de Fusión a 72, la batería completa suma 1.357/1.357 comprobaciones en 22 suites.
