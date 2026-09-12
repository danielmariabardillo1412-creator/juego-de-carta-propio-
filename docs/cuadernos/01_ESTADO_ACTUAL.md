# Cuaderno 1 — Estado actual

Última actualización: **2026-09-12**  
Módulo: **`zapiti.juego_cartas_propio`**  
Versión: **`0.24.0-stress-hardening`**  
Estado: **prototipo de reglas con mesa visual de duelo local; motor con último RUNTIME PASS en Godot 4.7 estable; fase visual greybox V0.1 abierta y aún pendiente de verificación runtime**

## Límites del trabajo

- Proyecto vigente: `F:/Taller de Juegos Zapity/juego_cartas_propio/engine`.
- Zápiti activo: `F:/Taller de Juegos Zapity/zapity`.
- El proyecto activo no se modifica durante este laboratorio.
- La integración con Zápiti se estudiará únicamente cuando el segundo juego sea estable.
- El arte, las imágenes definitivas y la presentación 3D quedan para después de validar los sistemas.
- Las seis fuentes de diseño de Drive disponen de copia local normalizada, índice temático y manifiesto de revisión en `docs/fuentes_diseno/`.
- La baraja inicial de fantasía aporta al runtime 40 nombres y cinco familias. Sus ocho Fusiones iniciales y todos los textos de criatura M01–M18 están integrados.
- La auditoría de trazabilidad S01 enlaza cada regla básica cerrada con su implementación y prueba; no quedan discrepancias cerradas conocidas después de 0.22/0.23.

## Base del motor

- Motor universal con acciones atómicas, estado portátil, eventos, vistas, acciones legales, semilla determinista, replay, persistencia y sincronización.
- Dos jugadores.
- Vida inicial: 30.
- Energía: aumenta de 1 a 10 y se recarga al comenzar el turno.
- Fases: Inicio, Robo, Principal 1, Combate, Principal 2 y Final.
- Barajas físicas independientes de 40 cartas y mano inicial de cinco.

## Sistemas jugables terminados

- Zonas de baraja, mano, criaturas, materiales de Fusión, apoyo, vínculos, terreno y cementerio.
- Privacidad de manos, barajas, criaturas colocadas y apoyos preparados.
- Invocación visible en ataque y colocación oculta en guardia.
- Una invocación normal por turno, costes de energía y cinco casillas de criatura/apoyo.
- Cambio de postura limitado. Una invocación normal boca arriba puede atacar al entrar, excepto durante el primer turno del jugador inicial; una Fusión recién formada no puede.
- Combate simultáneo por comparaciones estrictas `ATQ > DEF`.
- Ataque directo solo cuando no existen criaturas rivales.
- Daño sobrante condicionado por la postura y derrota inmediata a cero vidas.
- Magias principales G01, G02 y G03.
- Persistentes G04 y G05.
- Equipos E01, E02, E03, E05 y E06; E04 traslada un equipo entre criaturas propias compatibles una vez por turno.
- Los vínculos creados por E04 pueden recibir la respuesta opcional de T05.
- Anatomía y aptitudes son capas independientes. M01–M18 ya poseen nombre, familia, superfamilia, anatomía concreta y aptitudes en el catálogo runtime.
- Las capacidades Bestial, Sapiente, Lector, Canalizador y Manipulador son etiquetas discretas; no existe una estadística numérica universal de inteligencia.
- E01, E03 y E06 exigen Manipulador mediante requisitos genéricos. Los equipos pueden añadir requisitos anatómicos y varios requisitos de aptitud sin crear código especial por carta.
- Un vínculo deja de validar si su portador pierde una aptitud o anatomía necesaria.
- Terrenos base R01, R02 y R03 en una única zona por jugador.
- Seis transformaciones ordenadas: R01+R02 Bosque Inundado, R02+R01 Humedal Fértil, R01+R03 Bosque Ardiente, R03+R01 Bosque Volcánico, R02+R03 Caldera de Vapor y R03+R02 Llanura de Obsidiana.
- Si no existe una receta para el Terreno vigente más el entrante, el nuevo sustituye al anterior.
- La carta entrante actúa como soporte físico de la identidad transformada y la anterior pasa al Cementerio; siempre se conservan las 40 cartas propias.
- Las vistas públicas exponen una `terrain_identity` estable. Los efectos propios de las formas transformadas aún no están definidos y no se simulan.
- Ventana genérica de respuestas para ataques, Magias y disparadores posteriores, prioridad alterna y cierre por dos pases consecutivos.
- Cadena de respuestas en orden LIFO.
- G06, G07, T01 y T02 funcionales.
- T03 puede anular G01, G02 o G03 antes de que apliquen su efecto; ambas cartas terminan en el cementerio.
- T04 puede devolver a guardia una criatura enemiga que cambió voluntariamente de guardia a ataque.
- T05 puede destruir el equipo que el rival acaba de vincular.
- T06 puede destruir al combatiente enemigo superviviente después de perder una criatura propia en combate.
- Una respuesta no puede activarse el turno en que se prepara.
- El objetivo oculto no se revela durante la ventana; se revela antes del cálculo si el combate continúa.
- Los ataques cancelados quedan consumidos.
- Existe un servicio puro que valida catálogos y perfiles de Fusión y alimenta la acción del duelo.
- Las recetas admiten dos materiales, orden opcional, coincidencia por identidad o taxonomía, prioridad por especificidad y rechazo de ambigüedades.
- Los materiales deben estar visibles, pertenecer al mismo controlador y no reutilizar una misma carta física.
- Una entidad generada conserva una lista plana y única de las cartas físicas originales; las Fusiones intermedias solo quedan como procedencia y no crean cartas físicas nuevas.
- La destrucción futura puede recuperar de forma validada todos los materiales físicos contenidos.
- El catálogo específico registra F001-NAT, F010-NEU y F067-AGU como primer conjunto real y probado.
- Las recetas utilizan perfiles de las cartas M reales, aceptan orden inverso y conservan los dos identificadores físicos dentro de cada entidad generada.
- F010-NEU está integrada como primera Fusión jugable: dos Goblins Neutrales propios y visibles forman Banda Goblin boca arriba, en ataque o guardia, sin coste universal de Energía.
- La entidad generada ocupa una casilla mediante una carta portadora; el segundo material queda en una zona pública de contenidos y no puede reutilizarse.
- La acción de Fusión normal se limita provisionalmente a una por jugador y turno. La criatura resultante cuenta como recién llegada y no puede atacar ese turno.
- Banda Goblin es una Formación Goblin 3/3 de coste de referencia 3. Una vez por turno, en fase principal propia, paga 1 de Energía para dar +1 ATQ hasta final del turno a una criatura propia visible.
- Los equipos de ambos materiales se vuelven a comprobar: los compatibles se vinculan a Banda Goblin y los incompatibles van al Cementerio.
- Si Banda Goblin es destruida, ambos materiales y sus vínculos van al Cementerio. Si un efecto la devuelve a la mano, ambos materiales vuelven a la mano y sus vínculos van al Cementerio.
- Las vistas y eventos publican la identidad generada y preservan los 80 objetos físicos del duelo.
- F001-NAT y F067-AGU comparten ya el ciclo físico completo de F010 y están habilitadas como acciones del duelo.
- Alfa de la Manada de Naturaleza es una Integración 3/2 de coste de referencia 3. La primera vez en cada turno propio que otra criatura propia declara un ataque, le concede +1 ATQ solo durante ese combate.
- Elemental Mayor de Agua es una Integración 4/4 de coste de referencia 4. Antes del primer combate en que participa cada turno, su controlador elige +1 ATQ o +1 DEF para ese combate.
- La elección de F067 detiene obligatoriamente el combate antes de las respuestas, pertenece al controlador del Elemental tanto al atacar como al defender y después devuelve la prioridad normal al defensor.
- Los modificadores de F001/F067 viajan dentro del contexto validado del combate, tienen límites estructurales y no se convierten en bonos de turno completo.
- Seis recorridos verticales sobre `UniversalCardEngine` cubren las ocho Fusiones, sus efectos, destrucción, conservación física, vistas, eventos y replay.
- F011-NF Banda de Antorchas es una Formación Goblin Neutral/Fuego 3/2 de coste de referencia 3. Al atacar obtiene +1 ATQ durante ese combate; si controla otro Goblin boca arriba, obtiene además +1 DEF.
- F012-NN Cuadrilla del Matorral es una Formación Goblin Neutral/Naturaleza 2/4 de coste de referencia 3. Una vez por turno al ser atacada reduce 1 ATQ al atacante durante ese combate, incluso antes de respuestas.
- F068-FA Elemental de Vapor es una Integración Elemental Fuego/Agua 2/4 de coste de referencia 3. Al entrar elige una criatura enemiga boca arriba y le resta 1 ATQ hasta que termine el siguiente turno de su controlador; sin objetivo visible, la Fusión entra y el efecto no se aplica.
- F018-NEU Troll Bicéfalo es una Integración Troll Neutral 6/6 de coste de referencia 6. Exige dos Trolls distintos y la primera vez por turno que fuera a ser destruido en combate evita esa destrucción y pasa a guardia; T06 puede destruirlo después si el rival derrotado habilita la trampa.

## Fuera de alcance o incompleto

- Efectos mecánicos propios de los Terrenos transformados.
- Separación voluntaria de una Fusión y excepciones que alteren destinos o compatibilidad; su contrato está documentado, pero no implementado.
- Personajes especiales.
- Narrador/locutor: el principio está definido, pero falta cerrar su catálogo de frases, eventos cubiertos y presentación exacta.
- S01 aplazaba la anatomía concreta; los libros de familia y la baraja inicial ya han completado esa decisión de diseño para M01–M18.
- Construcción de mazos y equilibrio definitivo.
- Bots específicos para este reglamento.
- Red, animaciones, audio y arte final. La mesa técnica ya cubre detalle mecánico, objetivos, final y guardado/carga; queda validar comodidad con personas y desarrollar la capa artística.

## Última verificación cerrada

- Último cierre total anterior: veintidós suites del juego y **1.357 comprobaciones superadas**. La batería contiene ahora una suite adicional de IA; después del rediseño de interacción se repitieron las puertas afectadas: mesa manual 65/65, rival automático 9/9, vertical de criaturas 38/38 y vertical de ocho Fusiones 82/82.
- Nueve suites generales del motor: **441 comprobaciones superadas**.
- Diagnóstico escalonado del motor: **15/15**.
- Experimento integral: **80/80**.
- Estrés reproducible acumulado: **12.135 partidas y 1.044.565 acciones limpias** tras corregir dos discrepancias entre acciones anunciadas y validación. La última ampliación aportó 10.025 partidas y 907.265 acciones sin fallos.
- Auditoría estática posterior a la interacción directa y la IA: **25.392 comprobaciones**, 95 archivos GDScript, cero fallos.
- Godot: **4.7.stable.official.5b4e0cb0f**.
- No hubo errores de parser ni runtime en esa ejecución.

La comprobación de integridad del paquete encuentra cero archivos ausentes y siete hashes distintos respecto al manifiesto histórico de la baseline. El manifiesto no se regenerará hasta completar la puerta runtime de la nueva versión.

## Organización de contenido recuperada

- El índice del compendio reúne 60 familias o espacios de diseño y señala cuáles tienen recetas en S04.
- El primer tomo desarrolla Lobos, Goblins, Elementales, Trolls y Dragones.
- La baraja inicial propone 18 criaturas, 7 Magias, 6 Trampas, 6 equipos/objetos y 3 Terrenos con nombre propio, conservando las funciones de S01.
- F001, F005, F010, F011, F012, F018, F067 y F068 tienen un primer perfil jugable en papel. El resto de las 125 recetas de S04 continúa conceptual.
- La auditoría exacta obtiene 96,00 % de manos iniciales con criatura y 63,93 % con criatura de coste 1.
- Para la primera prueba se propone una acción de Fusión por jugador y turno, sin coste universal de Energía.
- Se recuperó de la conversación original el contrato de efectos latentes: pistas visibles, condiciones deterministas, revelación posterior en códice y coherencia entre promesa narrativa y mecánica.
- Las reglas generales admiten excepciones escritas de cartas, habilidades, recetas y estados; todavía no se implementa ninguna excepción de Fusión ni latencia concreta.
- El equilibrio se evaluará por valor total —cifras, coste, preparación, fiabilidad, efecto y contrajuego— y por comparación con todo el tramo de coste, no mediante valores aislados.

F005 Dragón Bicéfalo Elemental está integrada: M17 + M18, coste de referencia 8, 8/8 y un ataque adicional por turno tras destruir en combate y sobrevivir. El permiso se consume al declarar, caduca al cambiar de turno y respeta las ventanas de respuesta. Su perfil Alado/Bestial sin Manipulador es provisional explícito (JCP-DEC-031).

M05, M06, M07, M10, M16 y M18 resuelven automáticamente sus bonos, robo, recuperación de Energía o ataque adicional. M09 dispone de una acción pagada de fase principal; M12 inspecciona un apoyo rival sin revelar su identidad; M15 elige otra criatura propia al entrar; y M13 ofrece redirigir un ataque antes de la ventana normal de trampas. Las ocho criaturas restantes no tienen habilidad por diseño. Ninguna Fusión ejecuta la habilidad base de su carta física portadora.

La escena principal es una mesa local funcional con cámara casi cenital y una inclinación 2,5D suave: el tablero solo converge ligeramente y sus líneas permanecen próximas al paralelismo, sin punto de fuga hacia el horizonte. Cartas, casillas y zonas laterales conservan exactamente la misma escala para ambos jugadores; las dos manos se presentan completas y en fila recta. Hay cinco casillas con proporción de carta para criatura y cinco para apoyo por lado. Una línea limpia separa ambos territorios y aloja la banda de fases; no existe emblema central. Territorio, materiales de Fusión, Baraja y Cementerio ocupan espacios laterales separados y enfrentados. Las cartas poseen marco visual provisional, ventana de ilustración, reverso oculto, color por tipo/elemento y orientación de postura: ataque vertical y guardia horizontal. La interacción principal ocurre sobre la mesa: se selecciona una carta y después su casilla u objetivo; la interfaz solo ilumina destinos compatibles y explica por separado equipo, Magia instantánea, persistente, Trampa, Terreno y criatura. Las criaturas preguntan ataque visible o guardia oculta, y Magias/objetos dirigidos obligan a escoger criatura. El lateral muestra una ficha grande de la selección. Un botón principal nombra siempre el cambio real de fase o el final del turno. El Jugador 2 usa por defecto un rival automático local; el modo de dos personas conserva cortina y cambio de vista. La interfaz consume exclusivamente vistas, eventos filtrados y acciones legales de `UniversalCardEngine`; no lee el estado privado bruto.

El robo normal con baraja vacía ya no bloquea la partida: aplica la decisión cerrada de S01, derrota al jugador que debía robar, declara al rival ganador y termina con un evento público reproducible.

La invocación normal boca arriba permite atacar ese mismo turno, como fija S01. La excepción es el primer turno de la partida para el jugador inicial. Colocar boca abajo no permite revelarse ese turno y formar una Fusión mantiene su prohibición de ataque inmediato.

La revisión de `FLUJO_DE_PARTIDA_E_INTERACCION_V0_1.md` quedó aprobada e implementada. Inicio y Robo ordinarios son automáticos; la banda muestra las seis fases; existen controles separados para Combate y terminar turno con confirmación; las cartas se distinguen provisionalmente por tipo/elemento; las zonas auxiliares parecen montones; el historial comienza plegado; los equipos se rotulan bajo su portador; y dos criaturas compatibles pueden seleccionarse directamente para abrir la elección de Fusión. Una transformación conocida de Terreno se aplica mostrando su resultado y una sustitución sin receta avisa antes de perder el Terreno anterior.

Última puerta proporcional de la mesa anterior: manual 78/78, flujo de ataque visual 11/11, IA básica 9/9, vertical de criaturas 38/38, vertical de ocho Fusiones 82/82, escena headless PASS, tres capturas 1600×900 PASS y auditoría estática 26.333 comprobaciones sobre 97 GDScript. Estos resultados **no se atribuyen todavía** al nuevo greybox V0.1.

## Fase visual abierta — greybox representativo V0.1

El 2026-09-12 se cambió el orden de la prueba humana: antes de jugar una sesión completa se construirá una representación suficientemente cercana a la disposición final del juego, aunque siga sin ilustraciones, animaciones, audio ni arte definitivo. El objetivo es que una prueba humana mida el flujo que realmente se pretende conservar y no una pantalla de diagnóstico destinada a ser sustituida.

- Contrato visual: `docs/diseno/GREYBOX_INTERFAZ_FINAL_V0_1.md`.
- Rama de trabajo aislada: `chatgpt/greybox-ui-v1`.
- `demo/juego_cartas_table_greybox.gd` hereda la mesa funcional y cambia solo presentación y jerarquía visual.
- `demo/duel_table_backdrop_greybox.gd` sustituye la cuadrícula técnica por una superficie enfrentada con guías discretas.
- `demo/juego_cartas_table.tscn` apunta provisionalmente a la capa greybox dentro de esta rama.
- La banda de fases se desplaza al borde superior del tablero; deja de ocupar el centro jugable.
- Vida y Energía permanecen integradas en las cabeceras de ambos jugadores.
- El lateral pasa a ser contextual: ficha de carta y decisiones; historial, cambio de vista y cortina 2P quedan subordinados.
- Las casillas vacías conservan su forma pero dejan de repetir `VACÍA`; el texto fuerte aparece cuando son un destino legal como `JUGAR AQUÍ` o `ATAQUE DIRECTO`.
- No se ha modificado `UniversalCardEngine`, el módulo `juego_cartas_propio_module.gd`, el catálogo, reglas, replay ni persistencia.

**Estado de esta fase:** implementación escrita, pero **no cerrada**. Desde esta conexión no se ha ejecutado Godot 4.7 ni se ha inspeccionado una captura runtime de la nueva escena. Antes de declarar el greybox válido deben pasar parser/runtime y las puertas de mesa, ataque e IA, y el diseñador debe revisar una captura real. Solo después se reanuda la partida humana completa.