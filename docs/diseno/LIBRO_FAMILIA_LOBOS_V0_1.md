# Libro de familia — Lobos V0.1

Estado: **propuesta de criaturas base para revisión**.

Procedencia:

- S01 fija los esqueletos M01–M18, sus elementos y Manipulador.
- S03 fija la familia Lobo, la superfamilia Bestial y sus afinidades razonables.
- S04 fija F001–F004 y sus materiales.
- Los seis nombres base y sus conceptos visuales se proponen ahora; no estaban escritos previamente.

## Identidad de la familia

- Familia: Lobo.
- Superfamilia: Bestial.
- Anatomía común: Cuadrúpedo.
- Aptitud común: Bestial.
- Afinidades base: Naturaleza, Neutral y Hielo.
- Ramas excepcionales: Fuego y Luz cuando una criatura o receta concreta las justifique.
- Fantasía jugable: manada, rastreo, protección mutua, resistencia territorial y formas superiores obtenidas por coordinación.
- Restricción temática: los Lobos base no reciben Manipulador, Sapiente, Lector ni Canalizador automáticamente.

## Primer núcleo de seis criaturas

| Clave conceptual | Nombre de trabajo | Elemento | M compatible | Valores conservados | Función y concepto |
| --- | --- | --- | --- | --- | --- |
| LOB-01 | Lobo de Zarza | Naturaleza | M01 | Coste 1; 2 ATQ / 0 DEF; sin habilidad | Atacante pequeño que se lanza desde la maleza. Su DEF cero expresa exposición, no fragilidad anatómica absoluta. |
| LOB-02 | Cachorro de la Senda Verde | Naturaleza | M07 | Coste 1; 0 ATQ / 1 DEF; al ser destruido, roba 1 carta | Rastreador joven. Cuando cae, su rastro y aullido permiten a la manada encontrar el siguiente recurso. |
| LOB-03 | Lobo Gris del Páramo | Neutral | M14 | Coste 4; 4 ATQ / 4 DEF; sin habilidad | Referencia física adulta, equilibrada y sin magia. |
| LOB-04 | Lobo de la Escarcha Quieta | Hielo | Futuro | Pendientes | Cazador paciente de tundra; sirve como material natural de F002. |
| LOB-05 | Lobo del Claro Dorado | Luz | Futuro | Pendientes | Guardián terrenal de lugares sagrados; Luz no lo convierte en Celestial. Habilita F003 y F004. |
| LOB-06 | Lobo de Ascua Salvaje | Fuego | Futuro | Pendientes | Rama rara y agresiva reservada para una futura baraja temática. M17 se asigna al Dragón de la Caldera en la baraja inicial generalista. |

## Anatomía y presentación futura

Los seis son Cuadrúpedos. Deben reconocerse como miembros de una misma familia mediante proporciones, hocico, patas y lenguaje de manada, pero cada elemento modifica pelaje, entorno y señales sobrenaturales sin convertirlos en «el mismo Lobo recoloreado».

- Lobo de Zarza: cuerpo ligero, pelaje mezclado con hojas y espinas reales del entorno.
- Cachorro de la Senda Verde: menor tamaño, marcas de barro y musgo, actitud alerta más que cómica.
- Lobo Gris del Páramo: silueta robusta y completamente física.
- Lobo de la Escarcha Quieta: pelaje aislante, aliento frío y cristales discretos, no armadura de hielo genérica.
- Lobo del Claro Dorado: reflejos cálidos y marcas naturales luminosas, sin alas ni iconografía angelical.
- Lobo de Ascua Salvaje: pelaje chamuscado, grietas de brasa y humo leve; el fuego forma parte del cuerpo sin volverlo Elemental.

## Fusiones autorizadas

| ID | Resultado existente | Materiales | Situación con este núcleo |
| --- | --- | --- | --- |
| F001 | Alfa de la Manada | 2 Lobos del mismo elemento | **Disponible para diseño jugable:** LOB-01/M01 + LOB-02/M07, ambos de Naturaleza |
| F002 | Lobo Boreal Ancestral | Lobo de Naturaleza + Lobo de Hielo | Conceptualmente cubierto por LOB-01 o LOB-02 + LOB-04; falta crear la carta de Hielo |
| F003 | Lobo del Alba Salvaje | Lobo de Naturaleza + Lobo de Luz | Conceptualmente cubierto por LOB-01 o LOB-02 + LOB-05; falta crear la carta de Luz |
| F004 | Guardián Colmillo de Marfil | Lobo Neutral + Lobo de Luz | Conceptualmente cubierto por LOB-03/M14 + LOB-05; falta crear la carta de Luz |

LOB-06 no tiene una Fusión específica en F001–F004, pero dos Lobos de Fuego podrían satisfacer F001 cuando exista un segundo Lobo de Fuego. No se crea esa segunda carta únicamente para rellenar la receta.

## Primera receta integrada

F001 es la candidata natural porque ya puede construirse con dos cartas del primer mazo sin alterar elementos, cifras ni habilidades:

- M01 — Lobo de Zarza.
- M07 — Cachorro de la Senda Verde.
- Resultado — Alfa de la Manada de Naturaleza.

F001 ya está integrada en el catálogo y en el duelo con los valores aprobados en su propuesta separada. M07 también ejecuta su robo al ser destruido en el runtime 0.21.0; una Fusión que use su carta física no hereda ese texto base.

La propuesta separada para cerrar esos valores está en [`F001_ALFA_DE_LA_MANADA_PROPUESTA_V0_1.md`](F001_ALFA_DE_LA_MANADA_PROPUESTA_V0_1.md).

## Comprobaciones de coherencia

- M01 y M07 ya eran Naturaleza y no Manipuladores: no se contradice S01.
- M14 ya era Neutral y no Manipulador: encaja como Lobo físico adulto.
- La rama ígnea sigue siendo válida conceptualmente, pero no ocupa uno de los 18 huecos de la baraja inicial.
- Ningún Lobo obtiene equipo de Manipulador por tener patas, hocico o inteligencia animal.
- No se habilita Lobo + Goblin, Lobo + Elemental ni ningún otro cruce sin receta expresa.
