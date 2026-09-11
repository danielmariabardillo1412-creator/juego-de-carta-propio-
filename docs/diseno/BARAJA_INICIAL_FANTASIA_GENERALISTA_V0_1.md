# Baraja inicial de fantasía generalista V0.1

Estado: **baraja inicial integrada en el runtime 0.21.0**. Sustituye las asignaciones provisionales de identidad de los libros de familia cuando exista conflicto. Las cifras siguen siendo hipótesis de equilibrio, no valores competitivos definitivos.

Fuentes conservadas:

- S01 fija 40 cartas distintas: 18 criaturas, 7 Magias, 6 Trampas, 6 equipos/objetos y 3 Terrenos.
- S01 fija también costes, estadísticas, habilidades, elementos y la aptitud Manipulador de M01–M18.
- S03 fija familias, afinidades y capas de clasificación.
- S04 fija nombres y recetas de F001–F125.

## Identidad de la baraja

Es una expedición de fantasía clásica alrededor de un bosque, un lago y un volcán. Presenta criaturas pequeñas y grandes, combate, guardia, equipo, respuestas, información oculta, Terrenos y Fusiones sin exigir que el jugador domine todavía una baraja tribal.

- 3 Lobos: Naturaleza y Neutral.
- 4 Goblins: Neutral, Naturaleza y Fuego.
- 5 Elementales: Agua y Fuego.
- 4 Trolls: Neutral y Naturaleza.
- 2 Dragones: Fuego.
- Ocho resultados de Fusión accesibles con cartas del propio mazo.

## Las 18 criaturas

| ID | Nombre | Familia | Elemento | Coste | ATQ/DEF | Manipulador | Texto |
| --- | --- | --- | --- | ---: | ---: | --- | --- |
| M01 | Lobo de Zarza | Lobo/Bestial | Naturaleza | 1 | 2/0 | No | Sin habilidad. |
| M02 | Ondina del Remanso | Elemental | Agua | 1 | 1/2 | Sí | Sin habilidad. |
| M03 | Núcleo de Escoria | Elemental | Fuego | 1 | 0/3 | No | Sin habilidad. |
| M04 | Goblin Rebuscador | Goblin/Humanoide | Neutral | 1 | 1/1 | Sí | Sin habilidad. |
| M05 | Goblin Portaantorchas | Goblin/Humanoide | Fuego | 1 | 1/1 | Sí | Al declarar un ataque, obtiene +1 ATQ durante ese combate. |
| M06 | Muro de Marea | Elemental | Agua | 1 | 0/2 | No | Cuando sea revelado al recibir un ataque, obtiene +1 DEF durante ese combate. |
| M07 | Cachorro de la Senda Verde | Lobo/Bestial | Naturaleza | 1 | 0/1 | No | Cuando sea destruido, roba 1 carta. |
| M08 | Oleada Errante | Elemental | Agua | 2 | 3/1 | No | Sin habilidad. |
| M09 | Goblin Pendenciero | Goblin/Humanoide | Neutral | 2 | 2/2 | Sí | Una vez por turno, durante una fase principal propia, puedes pagar 1 de Energía: obtiene +1 ATQ hasta el final del turno. |
| M10 | Goblin Trampero del Matorral | Goblin/Humanoide | Naturaleza | 2 | 1/3 | Sí | Mientras esté en postura de guardia, obtiene +1 ATQ. |
| M11 | Troll Quebrapuertas | Troll/Humanoide | Neutral | 3 | 4/2 | Sí | Sin habilidad. |
| M12 | Oráculo del Espejo de Agua | Elemental | Agua | 3 | 3/2 | Sí | Al entrar boca arriba, mira una carta de apoyo boca abajo del rival sin revelarla públicamente. |
| M13 | Troll Guarda del Puente | Troll/Humanoide | Neutral | 3 | 2/2 | Sí | Una vez por turno, cuando otra criatura propia sea atacada, puedes hacer que esta criatura pase a ser el objetivo. |
| M14 | Lobo Gris del Páramo | Lobo/Bestial | Neutral | 4 | 4/4 | No | Sin habilidad. |
| M15 | Troll Chamán del Musgo | Troll/Humanoide | Naturaleza | 4 | 3/3 | Sí | Al entrar boca arriba, otra criatura propia obtiene +1 ATQ y +1 DEF hasta el final del turno. |
| M16 | Troll Cobrador del Paso | Troll/Humanoide | Neutral | 5 | 4/4 | Sí | La primera vez en cada turno que destruya una criatura en combate, recuperas 1 de Energía. |
| M17 | Dragón de la Caldera | Dragón/Dracónico | Fuego | 6 | 7/4 | No | Sin habilidad. |
| M18 | Dragón Rojo de las Dos Coronas | Dragón/Dracónico | Fuego | 7 | 5/6 | Sí | La primera vez en cada turno que destruya una criatura en combate y sobreviva, obtiene 1 ataque adicional ese turno. Solo una vez por turno. |

M18 es un Dragón sapiente con garras delanteras prensiles; esa anatomía concreta justifica Manipulador. M17 es una bestia dracónica y no puede utilizar equipo que exija esa aptitud.

## Las 7 Magias

| ID | Nombre | Tipo | Texto conservado de S01 |
| --- | --- | --- | --- |
| G01 | Furia de la Manada | Fase principal | Una criatura propia obtiene +2 ATQ hasta el final del turno. |
| G02 | Piel de Piedra | Fase principal | Una criatura propia obtiene +2 DEF hasta el final del turno. |
| G03 | Travesura de Trasgo | Fase principal | Devuelve a la mano una criatura enemiga con coste impreso de 2 o menos. |
| G04 | Bastión de Raíces | Persistente | Mientras permanezca boca arriba, tus criaturas en guardia obtienen +1 DEF. |
| G05 | Llamada a la Carga | Persistente | La primera vez en cada turno propio que una criatura propia pase de guardia a ataque, obtiene +1 ATQ hasta el final del turno. |
| G06 | Marea Protectora | Reactiva | Cuando una criatura propia sea atacada, obtiene +2 DEF durante ese combate. Requiere preparación previa. |
| G07 | Retirada entre la Niebla | Reactiva | Cuando una criatura propia sea atacada, devuélvela a tu mano. Requiere preparación previa. |

## Las 6 Trampas

| ID | Nombre | Texto conservado de S01 |
| --- | --- | --- |
| T01 | Foso de Caza | Cuando una criatura enemiga de coste impreso 2 o menos declare un ataque, destrúyela. |
| T02 | Enredaderas Traicioneras | Cuando una criatura propia sea atacada, la atacante obtiene −2 ATQ durante ese combate. |
| T03 | Silencio del Chamán | Cuando el rival active una Magia, anula su efecto; después, ambas cartas van al Cementerio. |
| T04 | Sendero Embarrado | Cuando una criatura enemiga pase voluntariamente de guardia a ataque, devuélvela a guardia. |
| T05 | Manos Rebuscadoras | Cuando el rival vincule un equipo u objeto a una criatura, destruye esa carta vinculada. |
| T06 | Último Zarpazo | Cuando una criatura propia sea destruida en combate, destruye la criatura enemiga que combatió contra ella si continúa en el campo. |

## Los 6 equipos y objetos

| ID | Nombre | Clase | Texto conservado de S01 |
| --- | --- | --- | --- |
| E01 | Espada del Aventurero | Equipo | El portador obtiene +1 ATQ. Requiere Manipulador. |
| E02 | Coraza de Cuero Endurecido | Equipo | El portador obtiene +1 DEF. |
| E03 | Escudo del Puente | Equipo | En guardia, el portador obtiene +1 ATQ y +1 DEF. Requiere Manipulador. |
| E04 | Banco de Herramientas Goblin | Artefacto independiente | Una vez por turno en fase principal propia, traslada un equipo propio entre dos criaturas propias que puedan utilizarlo legalmente. |
| E05 | Coraza del Bastión | Equipo; Set Bastión | El portador obtiene +1 DEF. |
| E06 | Martillo del Bastión | Equipo; Set Bastión | El portador obtiene +1 ATQ. Requiere Manipulador. |

Si E05 y E06 están vinculados al mismo portador, este obtiene además +1 ATQ y +1 DEF: bonificación total del conjunto, +2 ATQ/+2 DEF.

## Los 3 Terrenos

| ID | Nombre | Elemento | Texto conservado de S01 |
| --- | --- | --- | --- |
| R01 | Bosque | Naturaleza | Tus criaturas de Naturaleza obtienen +1 DEF. |
| R02 | Lago | Agua | Tus criaturas de Agua obtienen +1 DEF. |
| R03 | Volcán | Fuego | Tus criaturas de Fuego obtienen +1 ATQ. |

Se conservan las seis combinaciones ordenadas ya aprobadas: Bosque Inundado, Humedal Fértil, Bosque Ardiente, Bosque Volcánico, Caldera de Vapor y Llanura de Obsidiana.

## Libro de Fusiones de la baraja

Las Fusiones son entidades generadas y no ocupan hueco entre las 40 cartas. Todas las recetas son no ordenadas, usan dos cartas propias boca arriba y se realizan durante una fase principal propia. Los materiales quedan contenidos. No existe coste universal adicional. Para la primera prueba se utilizará un límite provisional de **una Fusión por jugador y turno**; limita la acción, no el número de Fusiones que pueden permanecer simultáneamente en el campo.

| ID jugable | Resultado | Materiales legales de esta baraja | Coste ref. | ATQ/DEF | Habilidad propuesta |
| --- | --- | --- | ---: | ---: | --- |
| F001-NAT | Alfa de la Manada | M01 + M07 | 3 | 3/2 | La primera vez en cada turno propio que otra criatura propia ataque, obtiene +1 ATQ durante ese combate. |
| F010-NEU | Banda Goblin | M04 + M09 | 3 | 3/3 | Una vez por turno en fase principal propia, paga 1 de Energía: una criatura propia obtiene +1 ATQ hasta el final del turno. |
| F011-NF | Banda de Antorchas | M05 + M04 o M09 | 3 | 3/2 | Al atacar, obtiene +1 ATQ durante ese combate. Si controlas otro Goblin, obtiene además +1 DEF durante ese combate. |
| F012-NN | Cuadrilla del Matorral | M10 + M04 o M09 | 3 | 2/4 | Una vez por turno, cuando sea atacada, la criatura atacante obtiene −1 ATQ durante ese combate. |
| F018-NEU | Troll Bicéfalo | Dos distintos entre M11, M13 y M16 | 6 | 6/6 | Una vez por turno, si fuera a ser destruido en combate, no es destruido y pasa a guardia. |
| F067-AGU | Elemental Mayor de Agua | Dos distintos entre M02, M06, M08 y M12 | 4 | 4/4 | Al comenzar el primer combate en que participe cada turno, elige +1 ATQ o +1 DEF durante ese combate. |
| F068-FA | Elemental de Vapor | M03 + uno entre M02, M06, M08 y M12 | 3 | 2/4 | Al entrar, una criatura enemiga obtiene −1 ATQ hasta el final del siguiente turno de su controlador. |
| F005-FUE | Dragón Bicéfalo Elemental | M17 + M18 | 8 | 8/8 | La primera vez en cada turno que destruya una criatura en combate y sobreviva, obtiene 1 ataque adicional ese turno. Solo una vez por turno. |

Todas las parejas anteriores aplican literalmente las recetas familiares de S04. Variar los dos individuos no cambia el resultado: familia y elementos determinan la receta, mientras que las cartas físicas utilizadas quedan registradas como materiales contenidos.

## Cobertura didáctica

- Lobos: pérdida con reposición, ofensiva rápida y liderazgo mediante F001.
- Goblins: equipo, gasto de Energía, guardia y tres Formaciones distintas.
- Elementales: defensa oculta, ataque frágil, información y dos Integraciones.
- Trolls: fuerza, protección, apoyo, recuperación de Energía y regeneración fusionada.
- Dragones: amenazas finales, uso diferente de equipo y una Fusión tardía de gran tamaño.

## Estado de entrada en el motor

1. Revisar nombres y tono, sin alterar efectos funcionales aprobados salvo decisión expresa.
2. Conservar las ocho recetas como conjunto de comparación al ampliar el catálogo.
3. Las ocho Fusiones iniciales están registradas e integradas: F001-NAT, F005-FUE, F010-NEU, F011-NF, F012-NN, F018-NEU, F067-AGU y F068-FA. Sus recorridos verticales verifican el duelo y el replay. El perfil corporal de F005 es provisional explícito en JCP-DEC-031.
4. Ajustar cifras únicamente con resultados de partida; esta V0.1 no declara el equilibrio cerrado.

La auditoría matemática y el orden de implementación propuesto están en [`AUDITORIA_BARAJA_INICIAL_FANTASIA_V0_1.md`](AUDITORIA_BARAJA_INICIAL_FANTASIA_V0_1.md).
