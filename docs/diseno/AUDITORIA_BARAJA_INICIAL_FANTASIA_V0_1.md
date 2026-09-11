# Auditoría de la baraja inicial de fantasía V0.1

Estado: **apta para primera prueba en papel; equilibrio no cerrado**.

## Integridad

- 40 cartas físicas distintas.
- 18 criaturas, 7 Magias, 6 Trampas, 6 equipos/objetos y 3 Terrenos.
- Curva conservada de S01: siete criaturas de coste 1; tres de coste 2; tres de coste 3; dos de coste 4; una de coste 5; una de coste 6 y una de coste 7.
- Reparto elemental conservado: 6 Neutral, 4 Naturaleza, 4 Agua y 4 Fuego.
- Reparto de Manipulador conservado: 11 sí y 7 no.
- Ocho Fusiones accesibles mediante recetas de S04.

## Consistencia de la mano inicial

Los cálculos son hipergeométricos exactos para una baraja de 40 cartas sin reemplazo y una mano de cinco.

- Al menos una criatura: **96,00 %**.
- Al menos dos criaturas: **75,99 %**.
- Al menos una criatura de coste 1: **63,93 %**.

La baraja cumple su objetivo didáctico: casi nunca empieza sin criatura, pero no garantiza una salida de coste 1. Esa incertidumbre permite comprobar si la Energía creciente y la colocación defensiva toleran manos algo lentas.

## Accesibilidad de las Fusiones

La tabla mide la probabilidad de que entre las cartas vistas exista al menos una pareja que satisfaga alguna de las ocho recetas. No presupone que ambas criaturas hayan sido invocadas todavía.

| Cartas vistas | Alguna receta familiar disponible |
| ---: | ---: |
| 5 | 22,23 % |
| 6 | 31,20 % |
| 7 | 40,54 % |
| 8 | 49,80 % |
| 9 | 58,62 % |
| 10 | 66,70 % |
| 12 | 80,01 % |
| 15 | 92,44 % |

Aceptar todas las parejas que cumplen familia y elementos es importante. Si cada resultado se restringiera sin motivo a una única pareja nominal, la probabilidad con diez cartas vistas caería de 66,70 % a 37,74 %.

## Lectura estratégica

- F001 enseña una Integración sencilla con dos Lobos baratos de Naturaleza.
- F010–F012 convierten a los Goblins en el núcleo más flexible. M04 y M09 compiten por varias Formaciones, lo que obliga a elegir en vez de fusionar automáticamente.
- F067 y F068 ofrecen muchas parejas, pero consumir dos Elementales puede desactivar temporalmente el bono amplio del Lago al reducir el número de cuerpos.
- F018 permite tres parejas Neutrales distintas y enseña regeneración sin crear una familia completa de Trolls elementales.
- F005 es deliberadamente tardía: exige conservar y desplegar las dos criaturas más caras. Debe sentirse como culminación excepcional, no como plan fiable de apertura.

## Límite inicial de Fusión

Para la primera prueba se aplica **una acción de Fusión por jugador y turno**.

- No limita cuántas Fusiones pueden coexistir en el campo.
- No impide encadenar una Fusión en un turno posterior si una receta futura acepta una entidad fusionada.
- No añade coste de Energía universal.
- Evita comprimir cuatro o más criaturas en una sola fase y simplifica el seguimiento de materiales, casillas, equipo y disparadores.
- Se retirará o ampliará únicamente si las pruebas muestran que frena innecesariamente las decisiones.

## Riesgos concretos para la primera prueba

1. **Troll Bicéfalo:** 6/6 con prevención de destrucción puede bloquear demasiado bajo Bastión de Raíces. Primera corrección posible: limitar su protección a una vez por duelo de esa entidad o reducir DEF a 5.
2. **Elemental Mayor de Agua:** puede alcanzar 6 DEF bajo Lago y Bastión de Raíces antes de respuestas. Debe medirse la frecuencia de empates sin destrucción.
3. **Banda Goblin:** la mejora universal puede hacer que su identidad tribal importe poco. Si ocurre, el objetivo pasará a ser únicamente Goblin o Humanoide.
4. **Dragón Bicéfalo:** 8/8 y segundo ataque pueden cerrar partidas inmediatamente. Su dificultad de preparación debe compensarlo; no se reducirá antes de verlo en mesa.
5. **Concentración de materiales:** una retirada o destrucción elimina la entidad y manda todos sus materiales al Cementerio. Debe comprobarse si liberar una casilla compensa este riesgo.

## Orden recomendado de implementación

1. **F010-NEU — Banda Goblin:** Formación, aptitudes y equipo; prueba la infraestructura sin elección durante combate.
2. **F001-NAT — Alfa de la Manada:** Integración Bestial y disparador de liderazgo al atacar.
3. **F067-AGU — Elemental Mayor de Agua:** Integración Amorfa y elección de estadística en combate.
4. Después: F011, F012, F068, F018 y F005, en ese orden aproximado de complejidad y potencia.

La primera prueba debe utilizar dos copias idénticas de la baraja, registrar cartas vistas, turnos sin invocación, primera Fusión posible, primera Fusión realizada, duración y causa del final. No se ajustarán cifras por una sola partida salvo error reglamentario inequívoco.

La primera comparación reproducible de umbrales para F001 y F067 está en `AUDITORIA_METRICA_F001_F067_V0_1.md`. Confirma riesgos que deben observarse, pero no modifica todavía ninguna cifra ni objetivo.
