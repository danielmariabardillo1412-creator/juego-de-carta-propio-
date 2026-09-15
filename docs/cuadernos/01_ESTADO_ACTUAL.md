# Cuaderno 1 — Estado actual

Última actualización: **2026-09-15**
Módulo: **`zapiti.juego_cartas_propio`**  
Versión: **`0.24.0-stress-hardening`**  
Estado: **prototipo de reglas con mesa visual de duelo local; RUNTIME PASS en Godot 4.7 estable**

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

La escena principal es una mesa local de duelo con fondo trapezoidal oblicuo de jugador sentado. La geometría vigente del campo procede de una única plantilla medida de 1280×720: cuatro bandas y veinte centros que se escalan uniformemente al tablero y se trasladan como conjunto para mantener C3 centrada. Ya no se utilizan anchos de fila ajustados a ojo. Las casillas vacías, cartas jugadas en Ataque y Guardia y ocho zonas laterales se recortan sobre esas bandas o su extrapolación; los controles nominales quedan invisibles como hitboxes. La mano propia sigue frontal y la rival legible al fondo. Hay cinco casillas de criatura y cinco de apoyo por lado. Las métricas nominales de interacción conservan 72×101 en Ataque, 101×72 en Guardia, mano 86×120, ficha lateral 180×251 y zonas auxiliares 60×90; la silueta visible del campo la decide la plantilla. El rail derecho conserva 274 px de referencia. Las guías vacías indican A1/C1, etc., y resaltan `JUGAR AQUÍ` o `ATAQUE DIRECTO` cuando corresponde. La cabecera mantiene fase actual, Combate, fin de turno, rival IA y nueva partida; las herramientas 2P, vistas y semilla permanecen plegadas. El centro conserva solo la separación territorial, sin banda de fases. Al seleccionar una carta, el rail muestra ficha, destinos y decisiones excepcionales. La interacción principal sigue siendo carta y después casilla u objetivo y consume exclusivamente vistas, eventos filtrados y acciones legales de `UniversalCardEngine`. El Jugador 2 usa por defecto un rival automático local; dos personas pueden recuperar cortina y cambio de vista.

UX incremental A/B (JCP-DEC-050, corregida por JCP-DEC-053): la criatura jugable de la mano se selecciona sin mutación; solo sus C1–C5 legales se destacan. Clic o arrastre hasta casilla conducen al mismo estado. Si UCE ofrece Ataque y Guardia, un menú pequeño junto a la casilla pide el modo y solo esa elección confirma la invocación; si hay uno solo, se confirma al elegir casilla. Escape, clic vacío o arrastre inválido cancelan sin mutar. Terminar turno ya no se bloquea por una selección incompleta: al confirmar la descarta sin jugarla. Durante una respuesta propia el control permite «Pasar respuesta»; espera cuando la prioridad es rival. El nuevo estado de interacción no contiene reglas ni cambia la geometría congelada.

El robo normal con baraja vacía ya no bloquea la partida: aplica la decisión cerrada de S01, derrota al jugador que debía robar, declara al rival ganador y termina con un evento público reproducible.

La invocación normal boca arriba permite atacar ese mismo turno, como fija S01. La excepción es el primer turno de la partida para el jugador inicial. Colocar boca abajo no permite revelarse ese turno y formar una Fusión mantiene su prohibición de ataque inmediato.

La revisión de `FLUJO_DE_PARTIDA_E_INTERACCION_V0_1.md` quedó aprobada e implementada con el ajuste de interacción JCP-DEC-052. Inicio y Robo ordinarios son automáticos; la fase actual se indica en el HUD; el ataque se inicia desde las cartas sin botón previo y terminar turno conserva confirmación. Las cartas se distinguen provisionalmente por tipo/elemento; las zonas auxiliares parecen montones; el historial comienza plegado; los equipos se rotulan bajo su portador; y dos criaturas compatibles pueden seleccionarse directamente para abrir la elección de Fusión. Una transformación conocida de Terreno se aplica mostrando su resultado y una sustitución sin receta avisa antes de perder el Terreno anterior.

La verificación vigente de esta mesa se registra con resultados de ejecución propios en el cuaderno 4. Siguiente fase: partida humana completa sobre esta base y corrección de problemas observables antes de ampliar arte, cartas o comentalista.

Pruebas humanas del 2026-09-13 (JCP-DEC-051/052): se detectó latencia al cambiar de carta y falta de instrucciones/resultados visibles. La mesa reutiliza acciones legales de UCE por versión y jugador; una sonda pasó de aproximadamente 2,0–2,7 s por selección a unos 43–49 ms en la misma máquina. Desde Principal 1, seleccionar una criatura propia y pulsar el objetivo rival abre Combate y declara el ataque sin botón previo; la limitación del primer turno permanece. El botón superior solo permite pasar sin atacar o cerrar el Combate. Los equipos como E02 se vinculan a la criatura elegida y activan su bonificación; G04 afecta automáticamente a todas las criaturas propias en Guardia, G05 espera su disparador y E04 solo traslada equipos ya vinculados. La magia dirigida sigue exigiendo objetivo y la Fusión dos materiales propios compatibles. La interfaz explica estas diferencias y muestra resultados. No se modificaron reglas, geometría, IA ni catálogo.

UX de Fusión del 2026-09-14 (JCP-DEC-054): arrastrar una criatura propia sobre otra compatible ilumina la pareja legal y abre el mismo selector que dos clics. El selector nombra la Fusión resultante y distingue Ataque, Guardia y objetivo cuando procede; cancelar no muta. Muestra **0 Energía** de pago para la Fusión normal vigente, distinto del coste de referencia impreso en el perfil del resultado. Las posibles variantes más caras aún no están diseñadas ni implementadas. La legalidad continúa procediendo de UCE y no se alteran recetas, reglas ni geometría.

Frontal provisional del 2026-09-14 (JCP-DEC-055): las criaturas de la mano y la ficha ampliada muestran elemento, coste numérico de Energía, ATQ y DEF impresos antes de jugarlas. La ficha ampliada incorpora su efecto y la vista textual repite las cifras; la zona central sigue reservada para una ilustración futura. Una criatura ya en campo usa estadísticas efectivas; una Fusión muestra explícitamente `REF` para el coste de referencia, que no es el pago de la Fusión normal. Se conservan tamaños, perspectiva, geometría, reglas y privacidad. Los símbolos alternativos para representar coste y el arte definitivo siguen abiertos.

Inicio aleatorio de partidas del 2026-09-14 (JCP-DEC-056): al abrir la mesa y al pulsar «Nueva partida» se elige una semilla nueva. El motor mezcla por separado las dos copias del mismo mazo didáctico de 40 cartas; no cambia su composición ni garantiza una Fusión temprana. La semilla actual se guarda visible en Herramientas y «Jugar semilla» permite repetir un reparto concreto. Las pruebas automáticas fijan su semilla explícitamente. No se altera el RNG determinista de UCE, el catálogo ni las reglas.

Acciones locales de criatura del 2026-09-14 (JCP-DEC-057): un clic en una criatura propia de campo abre junto a ella «Atacar» y «Pasar a Guardia/Ataque». Atacar ilumina sus objetivos; el cambio de postura se ejecuta por la acción legal de UCE y deja de duplicarse en el rail. El clic rápido criatura → objetivo visible sigue disponible. La postura de entrada sigue eligiéndose antes de invocar. Los límites actuales del cambio voluntario de S01 continúan vigentes; la aclaración del diseñador no autorizó modificarlos en esta pasada. Las cartas que prohíban Guardia son diseño futuro, no efectos implementados.

Claridad de decisiones y respuesta del 2026-09-14 (JCP-DEC-058): cuando una invocación con habilidad de entrada o una Fusión ofrece varias acciones UCE para el mismo resultado, el diálogo muestra primero una sola elección Ataque/Guardia; solo después pide objetivo si ese modo tiene varios objetivos legales. Así tres o cuatro acciones técnicas no aparentan ser tres o cuatro cartas/resultados distintos. En duelo con IA, una ventana de respuesta propia sin ninguna reacción utilizable se pasa automáticamente mediante `pass_reaction` de UCE; con reacción real disponible sigue siendo decisión humana. El resultado de combate se explica con ATQ frente a DEF en ambos sentidos y daño a Vida; igualdad no destruye ni quita Vida por sí sola. La fase mecánica Combate sigue permitiendo ataques individuales de varias criaturas, iniciados desde cada carta, y su botón visible dice «Pasar ataques». No cambian reglas, recetas ni fases del motor.

Presentación de activaciones del 2026-09-14 (JCP-DEC-059): al activarse públicamente una Magia o Trampa, la mesa muestra su frontal ampliado y texto funcional durante cuatro segundos, con avance manual opcional. Varias activaciones se muestran en orden y la IA y el pase automático esperan a que termine cada ficha. Se incluyen Magias principales, persistentes y reactivas cuando su evento público las identifica; una carta únicamente preparada boca abajo no se anuncia. La identidad procede del evento filtrado y el texto del catálogo común, sin inspeccionar manos rivales. Esta capa no altera costes, efecto, cadena, fases ni reglas. Captura y pruebas en el cuaderno 4.

Puerta específica de métricas greybox del 2026-09-12: mesa 89/89, ataque 11/11, IA 9/9, criaturas 38/38 y ocho Fusiones 82/82 en Godot 4.7. La escena carga sin error y se han regenerado tres capturas reales de 1600×900. No se repitieron en este corte las puertas generales del motor ni la auditoría estática histórica. El acceso directo del escritorio vuelve a apuntar explícitamente a la escena de este proyecto en F.

Puerta posterior de perspectiva oblicua del 2026-09-12: mesa 96/96, ataque 11/11, IA 9/9, criaturas 38/38 y ocho Fusiones 82/82 en Godot 4.7. Escena principal y tres capturas 1600×900 sin errores. Solo cambió la presentación; el acceso directo se regeneró. No se atribuye a esta pasada una nueva ejecución completa de las suites generales del motor.

Puerta de perspectiva interna del 2026-09-12: mesa 120/120, ataque 11/11, IA 9/9, criaturas 38/38 y ocho Fusiones 82/82 en Godot 4.7. Tres capturas reales 1600×900 revisadas; acceso directo vigente y comprobado. El ajuste solo separa los anchos de las filas y alinea a ellos sus zonas laterales. Siguen pendientes la prueba humana completa y el layout responsive; no se atribuye a esta pasada una nueva ejecución de las suites generales del motor.

Puerta de proyección real de piezas del 2026-09-12: la representación de las casillas, cartas jugadas y zonas auxiliares ya no es un rectángulo frontal de UI. La fase se ha retirado del centro. Pruebas y capturas con criatura real en Ataque y Guardia: véase el cuaderno 4.

Puerta de plantilla medida del 2026-09-12: se abandona el ancho independiente por fila. Las cuatro bandas, veinte centros, casillas, cartas colocadas y zonas laterales derivan de la misma malla 1280×720. Mesa **207/207**, ataque **11/11**, IA **9/9**, criaturas **38/38** y fusiones **82/82**; capturas de Ataque/Guardia reales a 1600×900 en el cuaderno 4. Continúan abiertos la validación humana y la legibilidad en otras resoluciones.

Pasada de fondo neutro del 2026-09-13 (JCP-DEC-049): la geometría anterior queda congelada como base válida en el commit local `9f4ddd4` y la etiqueta `mesa_perspectiva_ok_v1`, además de la copia física `artifacts/backup_mesa_perspectiva_ok_v1/`. Solo cambian los tres rellenos verdes del tapete por grises casi negros temporales. La plantilla, perspectiva, casillas, manos, rail, cabecera, fases y comportamiento no cambian. Las capturas de 1600×900 con campo vacío, criatura real en Ataque y criatura real en Guardia están en `artifacts/`; resultados de esta puerta en el cuaderno 4.

Fase abierta de equilibrio del primer mazo (JCP-DEC-060): no hay todavía un guardado humano de partida completa; el único guardado local hallado es una partida `RUNNING` del 2026-09-11 con cero acciones. Se ha añadido instrumentación optativa de duelos completos de 30 vidas al simulador de estrés, con resultados por carta vista/jugada y checkpoints, y un lector local de guardados que resume acciones sin publicar manos ni barajas. Estas herramientas no cambian el mazo, las reglas, la IA de la mesa ni UCE. Las estadísticas, costes y efectos de las 40 cartas siguen provisionales: el equilibrio no se declara cerrado a partir de bots. La medición y la solicitud de partidas humanas terminadas son el siguiente paso; resultados exactos en el cuaderno 4.

Auditoría de fuentes del 2026-09-15 (JCP-DEC-061): se verificó directamente la carpeta oficial de Drive `JUEGO_CARTAS_PROPIO` (`1m54Q-WmufRhdVleWMq6mTwUbP3Nzxqcl`) y sus seis fuentes S00–S05. IDs, títulos, padres y fechas coinciden con `docs/fuentes_diseno/SOURCE_MANIFEST.json`; la caché local pasa 6/6. S03 confirma el catálogo de 60 familias, diez elementos base, capas taxonómicas, prioridades, semillas y matriz V0.4; S04 conserva 125 recetas conceptuales y S05 contiene P01–P05 más P06 reservado. El contenido local reciente se conserva como propuesta, pero el Atlas no debe ampliarse hasta resolver la reconciliación documentada en `docs/diseno/AUDITORIA_RECONCILIACION_DRIVE_CONTENIDO_LOCAL_V0_1.md`. Hallazgos abiertos principales: el índice local resumió mal varias afinidades, el límite local de una Fusión por turno contradice S04 y algunas anatomías/aptitudes/nombres requieren ratificación. Esta pasada no modifica código, reglas, cartas, cifras, habilidades, balance ni Fusiones implementadas.

Resincronización de GitHub del 2026-09-15 (JCP-DEC-062): el árbol vigente de `main` en `danielmariabardillo1412-creator/juego-de-carta-propio-` corresponde al proyecto local actual de `F:/Taller de Juegos Zapity/juego_cartas_propio/engine`, incluidos los documentos recientes, pruebas y cuadernos. El estado remoto anterior (`b0cc5dad3b2d35193c4626be966518964ccaf3f8`) queda recuperable en la rama remota `backup/pre_sync_local_actual_20260915`; no se elimina historial ni se crea otro repositorio. No se publican `.godot`, importaciones PNG regenerables, temporales ni copias físicas `artifacts/backup_*`. Los sidecars `.gd.uid` sí se conservan como identificadores estables de recursos de Godot. Esta operación de repositorio no altera Zapity principal ni añade desarrollo o reglas de juego.
