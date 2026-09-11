# 02_TABLA_PRESUPUESTO_DE_CARTAS_V0_1

> Copia local de consulta de los valores y fórmulas de la hoja. Fuente editable: https://docs.google.com/spreadsheets/d/1_IQTmvl9pOBa3erD9jsuEA0XaJJ5y2vgDSfosndaEU8/edit
> ID de Drive: `1_IQTmvl9pOBa3erD9jsuEA0XaJJ5y2vgDSfosndaEU8`  
> Modificación observada en Drive: `2026-08-06T20:30:27.115Z`  
> Sincronización local: `2026-09-08`

## Presupuesto base

| A | B | C | D | E | F | G | H |
| --- | --- | --- | --- | --- | --- | --- | --- |
| TABLA PROVISIONAL DE PRESUPUESTO DE CARTAS V0.1 |  |  |  |  |  |  |  |
| Modelo inicial para diseñar criaturas antes de existir el primer lote. No es balance definitivo. |  |  |  |  |  |  |  |
| Coste de energía | Presupuesto base (PB) | Ejemplo equilibrado sin habilidad | Ejemplo ofensivo sin habilidad | Ejemplo defensivo sin habilidad | PB sugerido para habilidades | Fórmula | Observación |
| 1 | 5 | 1 ATQ / 3 DEF | 2 ATQ / 1 DEF | 0 ATQ / 5 DEF | 0–1 PB | 3 × coste + 2 | Cartas simples; habilidades muy pequeñas. |
| 2 | 8 | 2 ATQ / 4 DEF | 3 ATQ / 2 DEF | 1 ATQ / 6 DEF | 0–2 PB | 3 × coste + 2 | Primeras cartas de apoyo o defensa real. |
| 3 | 11 | 3 ATQ / 5 DEF | 4 ATQ / 3 DEF | 2 ATQ / 7 DEF | 1–3 PB | 3 × coste + 2 | Punto de referencia para criaturas estándar. |
| 4 | 14 | 4 ATQ / 6 DEF | 5 ATQ / 4 DEF | 3 ATQ / 8 DEF | 1–4 PB | 3 × coste + 2 | Puede sostener una habilidad útil. |
| 5 | 17 | 5 ATQ / 7 DEF | 6 ATQ / 5 DEF | 4 ATQ / 9 DEF | 2–5 PB | 3 × coste + 2 | Criatura potente, todavía respondible. |
| 6 | 20 | 6 ATQ / 8 DEF | 7 ATQ / 6 DEF | 5 ATQ / 10 DEF | 2–6 PB | 3 × coste + 2 | Debe justificar su coste con impacto. |
| 7 | 23 | 7 ATQ / 9 DEF | 8 ATQ / 7 DEF | 6 ATQ / 11 DEF | 3–7 PB | 3 × coste + 2 | Alta gama; vigilar protección y ventaja de cartas. |
| 8 | 26 | 8 ATQ / 10 DEF | 9 ATQ / 8 DEF | 7 ATQ / 12 DEF | 3–8 PB | 3 × coste + 2 | Jefes o fusiones con requisitos. |
| 9 | 29 | 9 ATQ / 11 DEF | 10 ATQ / 9 DEF | 8 ATQ / 13 DEF | 4–9 PB | 3 × coste + 2 | No debe ser jugable demasiado pronto sin coste real. |
| 10 | 32 | 10 ATQ / 12 DEF | 11 ATQ / 10 DEF | 9 ATQ / 14 DEF | 4–10 PB | 3 × coste + 2 | Techo inicial; las excepciones requieren auditoría. |

## Valores y ajustes

| A | B | C | D |
| --- | --- | --- | --- |
| VALORES Y AJUSTES PROVISIONALES |  |  |  |
| Elemento | Valor PB | Uso inicial | Advertencia |
| 1 punto de ATAQUE | 2 | Presión, destrucción y posible daño al jugador. | Se revisará si el combate final reduce su impacto. |
| 1 punto de DEFENSA | 1 | Supervivencia y bloqueo. | Si la defensa refleja daño al jugador, su valor deberá subir. |
| Habilidad muy menor o muy estrecha | 1 | Bonificación pequeña, condición rara o filtro limitado. | No usar para robar cartas o destruir unidades. |
| Habilidad menor | 2 | Efecto puntual pequeño o palabra clave de bajo impacto. | El valor depende de frecuencia y facilidad. |
| Habilidad estándar | 3 | Efecto útil, condicionado o de una sola vez. | Referencia inicial, no tarifa universal. |
| Habilidad fuerte | 4 | Ventaja clara, eliminación condicionada o protección relevante. | Debe reducir estadísticas o exigir condición. |
| Habilidad muy fuerte | 5 | Ventaja de cartas, eliminación potente o efecto repetible. | Requiere pruebas específicas. |
| Motor o habilidad definitoria | 6–8 | Generación repetida, protección fuerte, transformación importante. | No debe añadirse a estadísticas máximas. |
| Efecto de mesa o catástrofe | 9+ | Afecta muchas cartas, terreno o condiciones de victoria. | Necesita costes, demora o requisitos duros. |
| Penalización leve | +1 PB | Restricción pequeña o condición desfavorable ocasional. | No debe regalar estadísticas gratis si casi nunca importa. |
| Penalización real | +2 a +3 PB | Entra agotada, pierde vida, exige descarte o terreno concreto. | El reembolso depende de la probabilidad de sufrirla. |
| Penalización grave | +4 a +6 PB | Se destruye con contador, sacrifica recursos o daña al controlador. | Puede ser explotable como ventaja; auditar sinergias. |
| Coste o requisito externo | Variable | Fusión, catalizador, terreno o materiales específicos. | No se valora solo por rareza: debe medirse la consistencia del mazo. |

## Calculadora

| A | B | C |
| --- | --- | --- |
| CALCULADORA PROVISIONAL DE CRIATURAS |  |  |
| Dato | Valor | Explicación |
| Coste de energía | 3 | Valor inicial entre 1 y 10. |
| Ataque | 3 | Cada punto consume 2 PB. |
| Defensa | 3 | Cada punto consume 1 PB. |
| Coste total de habilidades (PB) | 2 | Suma estimada de todas sus habilidades. |
| Reembolso por penalizaciones (PB) | 0 | Solo penalizaciones que realmente importen. |
| Otros ajustes (PB consumidos) | 0 | Sinergias, facilidad de búsqueda o protección externa. |
| Presupuesto base | 11<br>`=3*B3+2` | Fórmula inicial: 3 × coste + 2. |
| Presupuesto utilizado | 11<br>`=2*B4+B5+B6-B7+B8` | ATQ × 2 + DEF + habilidades − penalizaciones + ajustes. |
| Margen restante | 0<br>`=B9-B10` | Positivo: queda margen. Negativo: excede presupuesto. |
| Diagnóstico | AJUSTE EXACTO<br>`=IF(B11=0;"AJUSTE EXACTO";IF(B11>0;"POR DEBAJO DEL PRESUPUESTO";"SOBRE PRESUPUESTO"))` | Solo alerta inicial; no sustituye pruebas. |

## Notas y decisiones

| A | B | C |
| --- | --- | --- |
| NOTAS Y DECISIONES DEL MODELO V0.1 |  |  |
| Actualización | 6 de agosto de 2026, 20:09, Europe/Madrid |  |
| Estado | PROVISIONAL. Herramienta de diseño, no reglamento cerrado. |  |
| Proyecto | Se desarrolla separado de Zápiti. El motor de Zápiti se usará como referencia y la integración se decidirá después de una auditoría. |  |
| Terreno y clima | No hay clima aleatorio. Todo terreno, lluvia, incendio, tormenta o transformación procede de cartas, habilidades o consecuencias deterministas. |  |
| Tablero | Sin casillas ni movimiento. Fila frontal de criaturas y fila trasera de soportes; atacar representa entrar temporalmente en el campo rival. |  |
| Vida de prueba | 30 puntos como hipótesis inicial, todavía abierta. |  |
| Supuesto crítico | El modelo valora 1 ATQ como 2 PB y 1 DEF como 1 PB. Si la defensa causa daño diferencial al atacante o protege demasiado, habrá que aumentar su valor. |  |
| Limitación | Una fórmula no detecta combos, búsqueda consistente, ventaja de cartas, protección en cadena ni interacciones con terreno y fusiones. |  |
| Uso correcto | Crear una primera versión razonable de cada carta, simular partidas, registrar resultados y recalibrar la tabla. |  |
| Próxima mecánica | Cerrar el flujo básico de turno y el sistema de recursos antes de diseñar cartas concretas. |  |
| 06/08/2026 22:28 | Combate base aprobado | Se elimina la posición de defensa y se adopta doble comparación: ATQ atacante contra DEF defensor y ATQ defensor contra DEF atacante. |
| 06/08/2026 22:28 | Revisión pendiente del presupuesto | La valoración actual de DEF es provisional y debe recalibrarse, porque DEF protege también cuando la criatura inicia un ataque. |

