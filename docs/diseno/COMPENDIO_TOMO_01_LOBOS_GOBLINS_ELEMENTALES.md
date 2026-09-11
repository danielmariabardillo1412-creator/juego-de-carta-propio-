# Compendio — Tomo 01: Baraja inicial de fantasía

Estado: **ampliado con la primera baraja generalista de fantasía**. S03 y S04 aportan las familias y recetas; los nombres de las 40 cartas quedan propuestos en [`BARAJA_INICIAL_FANTASIA_GENERALISTA_V0_1.md`](BARAJA_INICIAL_FANTASIA_GENERALISTA_V0_1.md).

## Lobos

- Superfamilia: Bestial.
- Anatomía habitual: Cuadrúpedo, aunque cada carta debe declararla.
- Afinidades base: Naturaleza, Neutral y Hielo. Fuego se reserva para ramas concretas o transformadas.
- Nivel previsto: familia prioritaria capaz de convertirse en baraja completa.
- Primer libro de criaturas base: [`LIBRO_FAMILIA_LOBOS_V0_1.md`](LIBRO_FAMILIA_LOBOS_V0_1.md).

| ID | Fusión | Receta autorizada | Resultado |
| --- | --- | --- | --- |
| F001 | Alfa de la Manada | 2 Lobos del mismo elemento | Lobo superior del elemento compartido; liderazgo y coordinación |
| F002 | Lobo Boreal Ancestral | Lobo de Naturaleza + Lobo de Hielo | Lobo Naturaleza/Hielo |
| F003 | Lobo del Alba Salvaje | Lobo de Naturaleza + Lobo de Luz | Lobo Naturaleza/Luz, no Celestial automáticamente |
| F004 | Guardián Colmillo de Marfil | Lobo Neutral + Lobo de Luz | Lobo Neutral/Luz de orientación protectora |

## Goblins

- Superfamilia: Humanoide.
- Anatomía habitual: Humanoide.
- Afinidades base: Neutral, Naturaleza y Fuego.
- Ramas: saqueadores, guerreros, chamanes, exploradores y jinetes.
- Sus Fusiones básicas son principalmente **Formaciones**: las cartas pasan a representar una unidad coordinada, no un cuerpo híbrido.
- Primer libro de criaturas base: [`LIBRO_FAMILIA_GOBLINS_V0_1.md`](LIBRO_FAMILIA_GOBLINS_V0_1.md).
- Primera Formación propuesta: [`F010_BANDA_GOBLIN_PROPUESTA_V0_1.md`](F010_BANDA_GOBLIN_PROPUESTA_V0_1.md).

| ID | Fusión | Receta autorizada | Resultado |
| --- | --- | --- | --- |
| F010 | Banda Goblin | 2 Goblins del mismo elemento | Formación Goblin que conserva el elemento compartido |
| F011 | Banda de Antorchas | Goblin Neutral + Goblin de Fuego | Formación Neutral/Fuego de saqueadores incendiarios |
| F012 | Cuadrilla del Matorral | Goblin Neutral + Goblin de Naturaleza | Formación Neutral/Naturaleza de exploradores y tramperos |
| F013 | Saqueadores de la Brasa Negra | Goblin de Fuego + Goblin de Oscuridad | Formación Fuego/Oscuridad de humo, incendio y emboscada |

Los nombres «Goblin Rebuscador» y «Goblin Pendenciero» no proceden de las fuentes. El nuevo libro de familia los recupera como propuestas revisables y añade cuatro criaturas base más; todavía no son contenido del motor.

## Elementales

- Familia profunda y laboratorio principal de propiedades derivadas.
- Afinidades base disponibles cuando tengan identidad propia: Fuego, Agua, Tierra, Aire, Hielo, Electricidad, Luz, Oscuridad y Naturaleza.
- La anatomía no es universal: cada Elemental debe declarar si es Humanoide, Amorfo, Alado u otra forma.
- Primer libro de criaturas base: [`LIBRO_FAMILIA_ELEMENTALES_V0_1.md`](LIBRO_FAMILIA_ELEMENTALES_V0_1.md).
- Primera Integración propuesta: [`F067_ELEMENTAL_MAYOR_AGUA_PROPUESTA_V0_1.md`](F067_ELEMENTAL_MAYOR_AGUA_PROPUESTA_V0_1.md).

| ID | Fusión | Receta autorizada | Resultado o propiedad derivada |
| --- | --- | --- | --- |
| F067 | Elemental Mayor | 2 Elementales del mismo elemento | Elemental superior del elemento compartido |
| F068 | Elemental de Vapor | Fuego + Agua | Fuego/Agua; Vapor |
| F069 | Elemental de Magma | Fuego + Tierra | Fuego/Tierra; Magma |
| F070 | Elemental de Niebla | Agua + Aire | Agua/Aire; Niebla provisional |
| F071 | Elemental de Tormenta | Aire + Electricidad | Aire/Electricidad; Tormenta provisional |
| F072 | Elemental de Mar Tormentoso | Agua + Electricidad | Agua/Electricidad; posible Conductividad/Electrificado futuro |
| F073 | Elemental de Permafrost | Tierra + Hielo | Tierra/Hielo; Permafrost provisional |
| F074 | Elemental del Eclipse | Luz + Oscuridad | Luz/Oscuridad; Eclipse provisional |
| F075 | Elemental de Brote Profundo | Naturaleza + Agua | Naturaleza/Agua; vida vegetal alimentada por agua elemental |
| F076 | Elemental de Cristal Radiante | Tierra + Luz | Tierra/Luz; Cristal radiante provisional |

## Trolls

- Primer libro: [`LIBRO_FAMILIA_TROLLS_V0_1.md`](LIBRO_FAMILIA_TROLLS_V0_1.md).
- Núcleo jugable: M11, M13, M15 y M16.
- Primera Fusión disponible: F018 — Troll Bicéfalo Neutral.

## Dragones

- Primer libro: [`LIBRO_FAMILIA_DRAGONES_V0_1.md`](LIBRO_FAMILIA_DRAGONES_V0_1.md).
- Núcleo jugable: M17 y M18, ambos de Fuego.
- Primera Fusión disponible: F005 — Dragón Bicéfalo Elemental de Fuego.
- Se conservan los nombres antiguos de F005–F009.

## Qué se puede y qué no se puede hacer

- Dos Lobos del mismo elemento pueden producir F001; dos criaturas Bestiales cualesquiera no.
- Dos Goblins del mismo elemento pueden producir F010; Goblin + Lobo no tiene receta actual.
- Fuego + Agua solo produce F068 cuando ambos materiales son Elementales. Dos criaturas cualesquiera de esos elementos no generan Vapor automáticamente.
- Una criatura no cambia de elemento, familia o forma por combatir con otra. Toda transformación requiere carta, habilidad o receta explícita.
- Las recetas de este tomo siguen sin cifras ni habilidades finales. Primero se crean las criaturas base; después se activan solo las Fusiones que realmente puedan construirse con ellas.

## Estado del primer conjunto

La baraja inicial ya reúne 40 cartas con nombre y función, además de ocho Fusiones construibles. El siguiente paso es revisar nombres y realizar una prueba en papel antes de elegir una única receta para la primera implementación controlada.
