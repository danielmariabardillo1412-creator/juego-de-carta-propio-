# Auditoría de reconciliación entre Drive y contenido local V0.1

Fecha: 2026-09-15. Estado: **auditoría cerrada; decisiones de contenido abiertas**.

Esta pasada compara el corpus oficial de diseño con el contenido creado localmente entre el 9 y el 11 de septiembre. No corrige cartas, no borra propuestas y no convierte ninguna propuesta nueva en canon.

## Fuente oficial comprobada

Carpeta de Drive: `JUEGO_CARTAS_PROPIO` (`1m54Q-WmufRhdVleWMq6mTwUbP3Nzxqcl`). Se comprobó directamente que contiene los seis elementos esperados y que todos declaran esa carpeta como padre. Sus fechas de modificación coinciden con `docs/fuentes_diseno/SOURCE_MANIFEST.json`; la comprobación local de caché termina 6/6.

| Clave | Documento e ID | Autoridad |
| --- | --- | --- |
| S00 | `00_ESTADO_Y_METODO_DE_TRABAJO` — `1zj5HK8ZTlIjGlBPezB-AdAufm2VI83e-Xv_mBNZnS34` | Método, estado y disciplina de diseño. |
| S01 | `01_MECANICAS_BASICAS_EN_DISCUSION` — `1xpD7h8yYE-KiSRHxJ_MADk5J3fwG1HeJ5yftbre-RPs` | Mecánicas, zonas, compatibilidad, Terrenos y esqueletos funcionales del primer mazo. |
| S02 | `02_TABLA_PRESUPUESTO_DE_CARTAS_V0_1` — `1_IQTmvl9pOBa3erD9jsuEA0XaJJ5y2vgDSfosndaEU8` | Presupuesto provisional; no sustituye pruebas. |
| S03 | `03_BIBLIA_DE_FAMILIAS_Y_COMBINACIONES_V0_1` — `1TVwhTVJsh05xG_Zf8HGxG11apnLkm7G01ylIe3Py_as` | Catálogo, taxonomía, afinidades e identidad. |
| S04 | `04_LIBRO_DE_FUSIONES_V0_1` — `1Gu55n80M9Nk7c4t8h73ygAltNZttdu5Tnk8Glr3vvf4` | Contrato y 125 recetas conceptuales de Fusión. |
| S05 | `05_PERSONAJES_ESPECIALES_Y_CARTAS_DE_AMIGOS_V0_1` — `1rnWDSLhZMo1C2EImQzRnw75h1WG9i4C-3l8IyiK60iE` | P01–P05 y P06 reservado. |

La carpeta `Juego de cartas original — Diseño y reglas` no fue utilizada como autoridad para esta auditoría.

## Taxonomía recuperada de S03

- **Familia/linaje:** identidad tribal o biológica concreta, como Lobo, Goblin, Dragón o Esqueleto.
- **Superfamilia:** agrupación transversal que permite apoyo amplio, como Bestial, Humanoide, No-muerto, Constructo, Infernal o Celestial.
- **Elemento:** afinidad energética. No equivale a especie, moralidad, anatomía ni disciplina.
- **Anatomía:** forma y compatibilidad física, por ejemplo Humanoide, Cuadrúpedo, Alado, Serpentino, Amorfo, Espectral o Colosal.
- **Disciplina:** rol aprendido, como Guerrero, Chamán, Mago, Explorador o Guardián.
- **Aptitud:** capacidad concreta, como Manipulador, Sapiente, Lector o Canalizador. `Bestial` aparece además en S01 como etiqueta discreta de comportamiento; no debe confundirse con la superfamilia Bestial.
- **Propiedad derivada:** resultado, estado o identidad producida, como Obsidiana, Magma, Vapor, Tóxico/Venenoso, Mutado, Corrompido, Purificado, Congelado, Electrificado, Calcinado, Inundado o Fértil. No se convierte automáticamente en elemento base.

Elementos base: **Neutral, Naturaleza, Fuego, Agua, Tierra, Aire, Hielo, Electricidad, Luz y Oscuridad**.

## Catálogo completo ya existente

Las 60 entradas de S03 son: Humanos; Elfos; Enanos; Goblins; Orcos; Trolls; Ogros; Kobolds; Gnomos; Lobos; Felinos; Osos; Rapaces/Aves de presa; Serpientes; Reptiles; Arácnidos; Insectoides; Murciélagos y bestias nocturnas; Licántropos; Minotauros; Centauros; Pueblos reptilianos; Dragones; Grifos; Fénix; Hidras; Basiliscos/Cocatrices; Unicornios/Pegasos y corceles mágicos; Quimeras; Gigantes; Cíclopes; Esqueletos; Reanimados/Cadavéricos; Espectros no-muertos; Vampiros; Liches; Demonios; Diablillos/Imps; Ángeles/Celestiales alados; Guardianes celestiales; Espíritus; Feéricos; Dríades y espíritus vegetales; Elementales; Golems; Armaduras vivientes; Gárgolas; Efigies/Tótems animados; Treants/Árboles vivientes; Plantas monstruosas; Hongos/Esporas; Pueblos marinos; Sirenas; Bestias marinas; Serpientes marinas; Kraken/Leviatanes; Abisales; Limos/Oozes; Mímicos; Horrores/Aberraciones.

El índice local no omitió ninguna de esas 60 entradas, pero sí resumió de forma incompleta o desactualizada muchas afinidades de la ampliación V0.4. Las afinidades que no quedaron bien reflejadas son:

| Familia | Afinidad V0.4 omitida o distinta en el índice local |
| --- | --- |
| Enanos | Fuego, Luz |
| Goblins | Oscuridad |
| Orcos | Oscuridad |
| Trolls | Hielo |
| Lobos | Luz; el índice añadió Fuego como excepcional, que necesita justificación concreta fuera de la matriz nativa V0.4 |
| Felinos | Fuego |
| Serpientes | Electricidad |
| Arácnidos | Agua |
| Insectoides | Electricidad; el índice puso Oscuridad, que no figura como afinidad nativa V0.4 |
| Murciélagos/bestias nocturnas | Naturaleza |
| Licántropos | Naturaleza, Oscuridad, Neutral, Hielo no se transcribieron como matriz |
| Minotauros | Oscuridad |
| Centauros | Luz |
| Grifos | Electricidad |
| Fénix | Aire |
| Hidras | Fuego |
| Basiliscos/Cocatrices | Fuego |
| Corceles mágicos | Agua |
| Gigantes | Aire; el índice incluyó Neutral, ausente de la matriz V0.4 |
| Cíclopes | Tierra, Neutral, Fuego, Aire no se transcribieron como matriz |
| Esqueletos | Hielo, Tierra |
| Reanimados | Agua, Tierra; Tóxico/Mutado son derivados, no sustituyen afinidades base |
| Espectros no-muertos | Aire |
| Vampiros | Neutral, Aire, Hielo |
| Liches | Oscuridad, Hielo, Neutral, Fuego no se transcribieron como matriz |
| Demonios | Tierra, Aire |
| Diablillos/Imps | Oscuridad, Fuego, Aire, Neutral no se transcribieron como matriz |
| Ángeles/Celestiales alados | Aire, Fuego, Electricidad |
| Guardianes celestiales | Luz, Tierra, Aire, Naturaleza no se transcribieron como matriz |
| Feéricos | Agua |
| Dríades/espíritus vegetales | Tierra, Agua, Luz |
| Gárgolas | Aire |
| Efigies/Tótems | Tierra, Naturaleza, Luz, Oscuridad no se transcribieron como matriz |
| Treants | Agua, Luz |
| Plantas monstruosas | Luz, Oscuridad |
| Hongos/Esporas | Tierra, Agua |
| Pueblos marinos | Luz, Oscuridad, Electricidad |
| Sirenas | Aire, Luz, Oscuridad y su identidad separada requieren conservarse |
| Serpientes marinas | Electricidad |
| Kraken/Leviatanes | Agua, Oscuridad, Hielo, Electricidad no se transcribieron como matriz |
| Abisales | Electricidad, Hielo |
| Limos/Oozes | Neutral |
| Mímicos | Neutral, Oscuridad, Tierra, Luz no se transcribieron como matriz |
| Horrores/Aberraciones | Oscuridad, Neutral, Hielo, Electricidad no se transcribieron como matriz |

Familias prioritarias: Lobos, Dragones, Goblins, Orcos, Trolls, Elfos, Enanos, Golems, Esqueletos, Reanimados, Vampiros, Demonios, Espíritus, Feéricos, Elementales, Pueblos marinos/Abisales y Flora viviente.

Familias semilla: Humanos, Ogros, Kobolds, Gnomos, Osos, Rapaces, Arácnidos, Licántropos, Minotauros, Centauros, Grifos, Fénix, Hidras, Basiliscos, Corceles mágicos, Liches, Diablillos, Celestiales, Gárgolas, Limos, Mímicos y demás entradas aún poco desarrolladas.

Restricciones de identidad: No-muertos e Infernales no tienen Luz nativa; Celestiales no tienen Oscuridad nativa normal. Esas formas requieren receta, transformación o historia específica. Dragones, Espíritus, Elementales y Golems admiten una amplitud excepcional. La matriz permite posibilidades; **no obliga a fabricar variantes de relleno**.

## Contrato de Fusiones recuperado de S04

- Una Fusión verdadera contiene sus materiales; no los sacrifica ni los manda al Cementerio al formarse.
- La receta es determinista y manda sobre semejanzas genéricas. No toda combinación tiene resultado.
- V0.1 contiene 125 recetas internas de dos materiales, normalmente no ordenadas.
- Una entidad fusionada puede participar en otra receta solo cuando esa receta posterior la admita.
- V0.2 reserva cruces entre familias; V0.3, tres o más materiales/ascensiones; V0.4, Magias, equipo, estados y Terrenos.
- No hay coste universal adicional de Energía ni límite universal de Fusiones por turno. Una receta concreta sí puede imponerlos.
- Los nombres de F001–F125 ya estaban en Drive; no son nombres locales nuevos.

## Terrenos, elementos y compatibilidad recuperados de S01

- R01 Bosque, R02 Lago y R03 Volcán, sus efectos y seis transformaciones ordenadas ya existían: Bosque Inundado, Humedal Fértil, Bosque Ardiente, Bosque Volcánico, Caldera de Vapor y Llanura de Obsidiana.
- Un elemento presente, una criatura o un ataque no transforma por sí solo un Terreno. Debe actuar una carta, habilidad, receta o efecto explícito.
- Se permiten mejoras apiladas sin límite artificial de una sola mejora. Anatomía, aptitudes, peso, requisitos, estados y texto determinan compatibilidad y sobrecarga.
- La compatibilidad física y la elemental son capas separadas. Una transformación o Fusión conserva vínculos todavía legales y envía al Cementerio los incompatibles, salvo excepción escrita.
- Si no existe regla general ni receta elemental, las mejoras funcionan sin una reacción adicional inventada.

## Personajes especiales de S05

Se encontraron completos P01–P05 y P06 reservado:

- P01 DMB — **Vagabundo**, Neutral, rutas/evolución y excepción limitada a incompatibilidad elemental.
- P02 Fran — **Señor de las Cartas / Rey de las Cartas**, identidad de naipes y rutas de preparación, información, recuperación o manipulación pendientes.
- P03 Steve — **Invocador de Bestias**, centrado en un bulldog francés; humor no equivale a debilidad.
- P04 El Asturiano — **Señor de la Tormenta / Señor del Trueno**, Electricidad con posible Aire y Fusión nominal futura con Fran.
- P05 Michael — **Maese del Risco**, Tierra/Aire, riesgo/recompensa y rutas de montaña.
- P06 queda reservado. Ninguno pertenece al primer mazo ni tiene cifras definitivas.

## Inventario del contenido local reciente

1. Índice local de 60 familias y tomo inicial.
2. Libros de Lobos, Goblins, Elementales, Trolls y Dragones.
3. Nombres e identidades de M01–M18: Lobo de Zarza, Ondina del Remanso, Núcleo de Escoria, Goblin Rebuscador, Goblin Portaantorchas, Muro de Marea, Cachorro de la Senda Verde, Oleada Errante, Goblin Pendenciero, Goblin Trampero del Matorral, Troll Quebrapuertas, Oráculo del Espejo de Agua, Troll Guarda del Puente, Lobo Gris del Páramo, Troll Chamán del Musgo, Troll Cobrador del Paso, Dragón de la Caldera y Dragón Rojo de las Dos Coronas.
4. Nombres locales de G01–G07, T01–T06 y E01–E06; sus funciones y cifras proceden de S01.
5. Perfil jugable local de F001, F005, F010, F011, F012, F018, F067 y F068. Sus nombres y recetas proceden de S04; sus cifras y habilidades jugables son extensiones locales.
6. Principios locales de excepciones, efectos latentes, comentalista y ciclo de devolución/separación de Fusiones.
7. Modelo, auditorías y línea base de equilibrio. Son instrumentos de evaluación, no nuevas fuentes de canon.

### Inventario nominal y clasificación

| IDs | Nombres locales | Estado frente a Drive |
| --- | --- | --- |
| M01–M03 | Lobo de Zarza; Ondina del Remanso; Núcleo de Escoria | `EXTENSIÓN_COMPATIBLE`: S01 aporta cifras/función/elemento; nombre, familia y anatomía son locales. |
| M04–M06 | Goblin Rebuscador; Goblin Portaantorchas; Muro de Marea | `EXTENSIÓN_COMPATIBLE` con la misma separación. |
| M07–M09 | Cachorro de la Senda Verde; Oleada Errante; Goblin Pendenciero | `EXTENSIÓN_COMPATIBLE` con la misma separación. |
| M10–M12 | Goblin Trampero del Matorral; Troll Quebrapuertas; Oráculo del Espejo de Agua | `EXTENSIÓN_COMPATIBLE` con la misma separación. |
| M13–M15 | Troll Guarda del Puente; Lobo Gris del Páramo; Troll Chamán del Musgo | `EXTENSIÓN_COMPATIBLE`; Canalizador de M15 necesita ratificación como aptitud añadida. |
| M16–M18 | Troll Cobrador del Paso; Dragón de la Caldera; Dragón Rojo de las Dos Coronas | `EXTENSIÓN_COMPATIBLE`; anatomía prensil y Sapiente de M18 requieren ratificación. |
| G01–G07 | Furia de la Manada; Piel de Piedra; Travesura de Trasgo; Bastión de Raíces; Llamada a la Carga; Marea Protectora; Retirada entre la Niebla | `NUEVA_IDEA_SIN_CONTRADICCIÓN` en los nombres; funciones `YA_EXISTÍA_EN_DRIVE` en S01. |
| T01–T06 | Foso de Caza; Enredaderas Traicioneras; Silencio del Chamán; Sendero Embarrado; Manos Rebuscadoras; Último Zarpazo | `NUEVA_IDEA_SIN_CONTRADICCIÓN` en los nombres; funciones `YA_EXISTÍA_EN_DRIVE` en S01. |
| E01–E06 | Espada del Aventurero; Coraza de Cuero Endurecido; Escudo del Puente; Banco de Herramientas Goblin; Coraza del Bastión; Martillo del Bastión | `EXTENSIÓN_COMPATIBLE`: S01 ya contenía las seis funciones y nombres provisionales más genéricos. |
| R01–R03 | Bosque; Lago; Volcán | `YA_EXISTÍA_EN_DRIVE`. |
| LOB-04/05 | Lobo de la Escarcha Quieta; Lobo del Claro Dorado | `NUEVA_IDEA_SIN_CONTRADICCIÓN`; materializan afinidades y recetas ya previstas sin cifras. |
| LOB-06 | Lobo de Ascua Salvaje | `REQUIERE_DECISIÓN_HUMANA`; rama excepcional permitida en texto antiguo, pero fuera de afinidad nativa V0.4. |
| GOB-03/04 | Goblin Rompefilas; Goblin Guardaespaldas | `NUEVA_IDEA_SIN_CONTRADICCIÓN`; nombres/conceptos sin cifras. |
| ELM-06 | Custodio del Brote | `NUEVA_IDEA_SIN_CONTRADICCIÓN`; Elemental de Naturaleza permitido, sin cifras. |
| F001/F005/F010/F011/F012/F018/F067/F068 | Alfa de la Manada; Dragón Bicéfalo Elemental; Banda Goblin; Banda de Antorchas; Cuadrilla del Matorral; Troll Bicéfalo; Elemental Mayor; Elemental de Vapor | Nombre/receta `YA_EXISTÍA_EN_DRIVE`; perfil jugable `EXTENSIÓN_COMPATIBLE` y provisional. |

## Tabla de reconciliación

| Contenido reciente | Fuente Drive | Estado | Conflicto |
| --- | --- | --- | --- |
| Catálogo de 60 familias | S03 | `YA_EXISTÍA_EN_DRIVE` | No en las familias; sí hay transcripción incompleta de afinidades. |
| Taxonomía de capas | S01/S03 | `YA_EXISTÍA_EN_DRIVE` | No; debe evitarse la ambigüedad doble de Bestial. |
| Matriz resumida del índice local | S03 V0.4 | `CONFLICTO_CON_DRIVE` | Sí: omisiones y sustituciones indicadas arriba. No se corrige automáticamente en esta pasada. |
| Libros locales de cinco familias | S03/S04 | `EXTENSIÓN_COMPATIBLE` | No en su estructura; contienen nombres, anatomías y aptitudes aún revisables. |
| LOB-01–LOB-05 y sus conceptos | S01/S03/S04 | `EXTENSIÓN_COMPATIBLE` | No; nombres y anatomía son locales. |
| LOB-06 Lobo de Ascua Salvaje como criatura base de Fuego | S03 inicial y matriz V0.4 | `REQUIERE_DECISIÓN_HUMANA` | La Biblia permite una rama excepcional, pero Fuego no es afinidad nativa V0.4 y falta una justificación/receta concreta. |
| GOB-01–GOB-06 | S01/S03/S04 | `EXTENSIÓN_COMPATIBLE` | No; falta reflejar Oscuridad en la matriz familiar, sin necesidad de crear ahora un Goblin oscuro. |
| ELM-01–ELM-06 | S01/S03/S04 | `EXTENSIÓN_COMPATIBLE` | No; las anatomías y aptitudes individuales son propuestas locales. |
| Núcleo Troll M11/M13/M15/M16 | S01/S03/S04 | `EXTENSIÓN_COMPATIBLE` | No en nombres/familia; la aptitud Sapiente común necesita ratificación individual. |
| Núcleo Dragón M17/M18 | S01/S03/S04 | `EXTENSIÓN_COMPATIBLE` | No; anatomía y Sapiente de M18 son propuestas locales. |
| Costes, ATQ/DEF, elementos, Manipulador y habilidades M01–M18 | S01 | `YA_EXISTÍA_EN_DRIVE` | No; el contenido local los asignó a identidades nuevas. |
| Nombres M01–M18 | S01 (identidad aplazada) | `NUEVA_IDEA_SIN_CONTRADICCIÓN` | No en general; quedan revisables antes del Atlas. |
| Funciones G01–G07 y T01–T06 | S01 | `YA_EXISTÍA_EN_DRIVE` | No. |
| Nombres G01–G07 y T01–T06 | S01 (sin nombres definitivos) | `NUEVA_IDEA_SIN_CONTRADICCIÓN` | No; deben conservarse como propuestas. |
| E01–E06 | S01 | `EXTENSIÓN_COMPATIBLE` | No: función ya existente, nombre temático local. |
| R01–R03 y seis Terrenos derivados | S01 | `YA_EXISTÍA_EN_DRIVE` | No. |
| F001/F005/F010/F011/F012/F018/F067/F068: nombre y receta | S04 | `YA_EXISTÍA_EN_DRIVE` | No. |
| Esas ocho Fusiones: cifras y habilidades | S04 las deja pendientes | `EXTENSIÓN_COMPATIBLE` | No demostrado; son hipótesis jugables y no canon definitivo. |
| Coste de referencia de una Fusión | S04 no fija coste final | `REQUIERE_DECISIÓN_HUMANA` | No si es un valor de perfil; sí sería conflicto si se interpreta como pago universal de Energía. |
| Límite provisional de una Fusión por jugador y turno | S04, regla operativa 5 | `CONFLICTO_CON_DRIVE` | Sí: S04 declara que no existe límite universal. El runtime no se modifica en esta auditoría. |
| Fusión previa como material futuro | S04 reglas 7–9/V0.3 | `YA_EXISTÍA_EN_DRIVE` | No. |
| Ciclo local de devolución/separación de Fusión | S04 no lo cierra | `NUEVA_IDEA_SIN_CONTRADICCIÓN` | No contradice destrucción/contenimiento, pero requiere ratificación antes de canon. |
| Excepciones escritas y comentalista descriptivo | S01/S03/S04 | `EXTENSIÓN_COMPATIBLE` | No. |
| Efectos latentes y “Venganza del Bosque” | fuentes parciales + conversación recuperada | `REQUIERE_DECISIÓN_HUMANA` | No contradicen Drive, pero su detalle no está fijado en S00–S05. |
| P01–P05 y P06 reservado | S05 | `YA_EXISTÍA_EN_DRIVE` | No; son contenido deliberado del usuario y no debe sustituirse. |

No se hallaron duplicados de recetas bajo nombres nuevos entre las ocho Fusiones locales: todas conservan los IDs y nombres de S04. Por tanto, no se asigna `DUPLICADO` a ninguna entrada concreta.

## Decisiones humanas necesarias antes de ampliar el Atlas

1. Resolver si el límite local de una Fusión por turno se elimina para obedecer S04 o se convierte deliberadamente en una nueva regla que sustituya esa fuente.
2. Decidir si LOB-06 queda como forma base excepcional de Fuego con historia explícita, pasa a transformación/receta o se reserva sin canon.
3. Ratificar anatomías, disciplinas y aptitudes individuales añadidas a M01–M18; en especial, evitar asignar Sapiente por especie a todos los Goblins o Trolls.
4. Aclarar si `coste de referencia` de las Fusiones es solo valoración del perfil o tendrá alguna función futura distinta del pago de la Fusión normal.
5. Ratificar nombres M/G/T/E antes de arte y Atlas. Sus funciones no se reabren por ese proceso.
6. Decidir qué parte del ciclo local de devolución/separación y de los efectos latentes se incorporará al corpus oficial.

## Resultado

Se conserva todo el contenido reciente. La ampliación del Atlas queda detenida hasta resolver la reconciliación. No se modificaron motor, UCE, mesa, interfaz, reglas implementadas, cartas, recetas implementadas, estadísticas, habilidades ni balance.
