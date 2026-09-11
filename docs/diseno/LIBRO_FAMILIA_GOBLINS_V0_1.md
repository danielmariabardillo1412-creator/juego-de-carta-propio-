# Libro de familia — Goblins V0.1

Estado: **propuesta de criaturas base para revisión**.

Procedencia:

- S01 fija los esqueletos M01–M18, sus elementos, habilidades y Manipulador.
- S03 fija Goblin como familia Humanoide de afinidades Neutral, Naturaleza y Fuego.
- S04 fija F010–F013 y establece que las Fusiones Goblin son principalmente Formaciones.
- Los nombres y conceptos de las seis criaturas base se proponen ahora; no estaban escritos previamente.

## Identidad de la familia

- Familia: Goblin.
- Superfamilia: Humanoide.
- Anatomía común: Humanoide.
- Aptitudes comunes propuestas: Sapiente y Manipulador.
- Afinidades base: Neutral, Naturaleza y Fuego.
- Afinidad excepcional de receta: Oscuridad.
- Disciplinas frecuentes: Saqueador, Guerrero, Explorador, Trampero, Guardián y Chamán.
- Fantasía jugable: criaturas individualmente modestas que convierten recursos, posiciones y coordinación en Formaciones superiores.
- Límite estético: artesanía fantástica de madera, cuero, cuerda, hueso y metal sencillo; no tecnología moderna.

## Primer núcleo de seis criaturas

| Clave conceptual | Nombre de trabajo | Elemento | M compatible | Valores conservados | Disciplina y función |
| --- | --- | --- | --- | --- | --- |
| GOB-01 | Goblin Rebuscador | Neutral | M04 | Coste 1; 1 ATQ / 1 DEF; sin habilidad | Saqueador. Referencia básica que recupera objetos y puede utilizar equipo. |
| GOB-02 | Goblin Pendenciero | Neutral | M09 | Coste 2; 2 ATQ / 2 DEF; paga 1 de Energía para obtener +1 ATQ ese turno | Guerrero. Convierte recursos y bravuconería en presión temporal. |
| GOB-03 | Goblin Rompefilas | Neutral | Futuro | Pendientes | Guerrero ofensivo reservado para una futura baraja Goblin. M11 pasa al núcleo Troll de la baraja inicial. |
| GOB-04 | Goblin Guardaespaldas | Neutral | Futuro | Pendientes | Guardián reservado para una futura baraja Goblin. M13 pasa al núcleo Troll de la baraja inicial. |
| GOB-05 | Goblin Portaantorchas | Fuego | M05 | Coste 1; 1 ATQ / 1 DEF; al declarar un ataque obtiene +1 ATQ durante ese combate | Saqueador. La antorcha explica el impulso ofensivo y habilita F011. |
| GOB-06 | Goblin Trampero del Matorral | Naturaleza | M10 | Coste 2; 1 ATQ / 3 DEF; en guardia obtiene +1 ATQ | Explorador/Trampero. Convierte la defensa preparada en represalia y habilita F012. |

## Anatomía, aptitudes y presentación futura

Los seis son Humanoides, Sapientes y Manipuladores. Sapiente no implica Lector ni Canalizador: ninguno recibe esas aptitudes sin una versión que las necesite.

- Rebuscador: figura ligera, mochila irregular, cuerda y piezas reutilizadas.
- Pendenciero: cuerpo compacto, garrote y actitud provocadora.
- Rompefilas: arma pesada improvisada, protección escasa y silueta inclinada hacia delante.
- Guardaespaldas: escudo grande o protección corporal que haga legible la redirección de ataques.
- Portaantorchas: llama real y controlada; no es un Elemental ni un hechicero por llevar fuego.
- Trampero: redes, estacas y camuflaje vegetal; Naturaleza describe afinidad y entorno, no bondad.

## Fusiones autorizadas

| ID | Resultado existente | Materiales | Situación con este núcleo |
| --- | --- | --- | --- |
| F010 | Banda Goblin | 2 Goblins del mismo elemento | **Disponible:** M04 + M09 |
| F011 | Banda de Antorchas | Goblin Neutral + Goblin de Fuego | **Disponible:** M04 o M09 + M05 |
| F012 | Cuadrilla del Matorral | Goblin Neutral + Goblin de Naturaleza | **Disponible:** M04 o M09 + M10 |
| F013 | Saqueadores de la Brasa Negra | Goblin de Fuego + Goblin de Oscuridad | Pendiente: el núcleo no contiene todavía un Goblin de Oscuridad |

Las parejas posibles no crean resultados distintos por elegir dos Goblins Neutrales diferentes: F010 sigue produciendo la misma Banda Goblin Neutral mientras la receta no añada requisitos de identidad concretos.

## Recetas integradas

F010 fue la candidata inicial y ya está integrada:

- M04 — Goblin Rebuscador.
- M09 — Goblin Pendenciero.
- Resultado — Banda Goblin Neutral.
- Modo: Formación; ambos individuos quedan contenidos y la unidad ocupa una casilla.

F011 y F012 ya están integradas y han completado recorridos verticales mediante el motor real. F013 continúa pendiente porque la baraja inicial no contiene un Goblin de Oscuridad.

Desde 0.21.0 también son ejecutables los textos individuales de M05, M09 y M10: impulso al atacar, pago de Energía en fase principal y bono continuo en guardia. M04 permanece sin habilidad por diseño.

## Comprobaciones de coherencia

- Los seis esqueletos ya poseían Manipulador; no se altera el reparto de S01.
- Los elementos Neutral, Fuego y Naturaleza coinciden con las afinidades base de S03.
- Las habilidades existentes reciben una explicación visual sin reescribirse.
- Ningún Goblin se vuelve Lector, Canalizador o Chamán por pertenecer a la especie.
- No se habilita Goblin + Lobo, Goblin + Orco ni otro cruce sin receta registrada.
