# Auditoría métrica F001/F067 V0.1

Fecha: 2026-09-11  
Herramienta reproducible: `res://tools/run_jcp_balance_probe.gd`  
Estado: **medición inicial; no autoriza cambios de cifras**

## Método y límites

La sonda lee las dieciocho criaturas y las ocho Fusiones directamente del catálogo runtime. Compara ATQ/DEF impresos con la regla estricta `ATQ > DEF`.

No modela probabilidad de reunir materiales, Energía, turnos de preparación, postura, Terreno, equipo, Magias, Trampas, pérdida de cartas ni habilidades del oponente. Por ello mide umbrales brutos, no tasa de victoria.

## F001 — Alfa de la Manada de Naturaleza

Perfil: coste de referencia 3; 3 ATQ / 2 DEF. Su liderazgo concede +1 ATQ a **otra** criatura propia en el primer ataque beneficiable de cada turno.

- Entre 18 atacantes básicos y 18 defensores básicos existen 324 parejas. El +1 convierte 55 igualdades ATQ/DEF en destrucción: **16,98 %** de las parejas.
- Frente a las ocho Fusiones, cambia 18 de 144 parejas básicas: **12,50 %**.
- Dieciséis de las dieciocho criaturas pueden encontrar al menos un defensor básico cuyo umbral cambie; nueve pueden encontrarlo frente al catálogo actual de Fusiones.

La cobertura amplia es relevante, pero el efecto está limitado a otra criatura, una vez por turno y exige haber concentrado dos materiales en F001. No hay evidencia matemática suficiente para reducirlo.

Restringirlo a Lobo sería especialmente severo en la baraja inicial de una copia: F001 consume M01 y M07, y solo quedaría M14 como Lobo aliado. Restringirlo a Bestial añadiría muy pocos objetivos. La posible limitación tribal queda aplazada hasta observar uso real; no se aplica preventivamente.

## F067 — Elemental Mayor de Agua

Perfil: coste de referencia 4; 4 ATQ / 4 DEF. En su primer combate de cada turno el controlador elige +1 ATQ o +1 DEF.

Contra las dieciocho criaturas básicas, ignorando sus efectos:

| Elección de F067 | Victoria limpia | Intercambio | Derrota | Bloqueo sin destrucción |
| --- | ---: | ---: | ---: | ---: |
| 5 ATQ / 4 DEF | 16 | 1 | 1 | 0 |
| 4 ATQ / 5 DEF | 14 | 0 | 1 | 3 |

La excepción ofensiva es M17, que intercambia, y M18 derrota a F067. Con la elección defensiva, M17 lo derrota; M14, M16 y M18 producen bloqueo por cifras impresas.

Contra las ocho Fusiones, tratando a los rivales solo por sus cifras impresas:

| Elección de F067 | Victoria limpia | Intercambio | Derrota | Bloqueo sin destrucción |
| --- | ---: | ---: | ---: | ---: |
| 5 ATQ / 4 DEF | 6 | 0 | 2 | 0 |
| 4 ATQ / 5 DEF | 3 | 0 | 2 | 3 |

F018 y F005 superan ambas elecciones por cifras. La fila incluye el espejo F067 sin ejecutar la elección del rival, de modo que no debe interpretarse como ventaja real en espejo.

F067 es fuerte y flexible frente a cuerpos individuales, como corresponde a concentrar dos Elementales de Agua. Su elección defensiva sí confirma el riesgo de bloqueos señalado por la auditoría de baraja, sobre todo al añadir Lago o equipo. Aun así, reducir estadísticas ahora confundiría potencia bruta con rendimiento de partida.

## Decisión provisional

- F001 conserva objetivo universal.
- F067 conserva 4/4 y su primera elección de +1.
- En la primera sesión se registrarán: turno de formación, cartas comprometidas, combates ganados, combates bloqueados, respuestas sufridas y turnos de permanencia.
- Solo se ajustará una dimensión después de datos de partida: objetivo de F001; o cifra, frecuencia o condición de F067.
