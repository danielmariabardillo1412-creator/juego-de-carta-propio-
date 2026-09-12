# Cuaderno 2 — Decisiones y reglas

Las entradas marcadas como **vigentes** se mantienen hasta que una decisión posterior las sustituya expresamente.

## Decisiones de arquitectura

### JCP-DEC-001 — Laboratorio separado — vigente

El juego de cartas propio utiliza una copia independiente del motor universal. No sustituye ni modifica el motor jugable actual de Zápiti.

### JCP-DEC-002 — Sistemas antes que arte — vigente

Las cartas usan identificadores y nombres provisionales. No se producen imágenes finales hasta comprobar que las reglas, zonas, flujo y efectos funcionan; así no se desecha trabajo artístico por cambios mecánicos.

### JCP-DEC-003 — Una única ruta de mutación — vigente

Las acciones pasan por `UniversalCardEngine.perform_action()`. Las reglas no modifican estado desde la interfaz, un bot ni una variable oculta del módulo.

### JCP-DEC-004 — Información privada por contrato — vigente

Una acción pública contra una carta oculta utiliza su casilla, no su identificador. Las vistas y los eventos no revelan identidades ocultas. La identidad puede publicarse cuando la propia regla revela o activa la carta.

### JCP-DEC-005 — Estadística efectiva única — vigente

Interfaz y combate consultan `_effective_stats()`. Los bonos no se recalculan mediante fórmulas distintas en varias capas.

### JCP-DEC-006 — Las respuestas son decisiones — vigente

Las Magias reactivas y Trampas no saltan automáticamente. Se abre prioridad para que el jugador decida si gasta la carta.

### JCP-DEC-007 — Respuesta encadenada — vigente

Al declararse un ataque, el defensor recibe prioridad. Tras una activación, la prioridad cambia y el contador de pases vuelve a cero. Dos pases consecutivos cierran la ventana y la cadena se resuelve en orden inverso.

### JCP-DEC-008 — Ataque consumido al declararse — vigente

La criatura marca su ataque como utilizado antes de abrir respuestas. Si G07, T01 u otro efecto cancela el combate, el jugador no recupera ese ataque.

### JCP-DEC-009 — Un único contrato de respuestas — vigente

Ataques y Magias utilizan `pending_response`, con un `kind` y un `context` validados. Prioridad, pases, activación, revelación y consumo de cartas pertenecen a una sola infraestructura; únicamente cambia la resolución final del contexto. Los disparadores futuros deben ampliarla, no copiarla.

### JCP-DEC-010 — Los disparadores no deshacen la acción original — vigente

T04, T05 y T06 responden después de que el hecho disparador sea válido y se haya aplicado. T04 devuelve la postura a guardia, pero el cambio voluntario y el posible disparo de G05 siguen consumidos. T05 destruye un equipo que llegó a vincularse. T06 actúa después del combate y no recalcula daño ni destrucciones ya resueltas.

### JCP-DEC-011 — E04 reutiliza vínculo y compatibilidad — vigente

Cada copia activa de E04 puede trasladar un equipo una vez por turno entre dos criaturas propias. El destino debe cumplir `_can_equip()` igual que al jugar el equipo desde la mano. El traslado crea un vínculo nuevo y, por tanto, permite la respuesta de T05; si T05 destruye el equipo, el uso de E04 no se recupera.

### JCP-DEC-012 — Una carta física porta el Terreno transformado — vigente

La zona de Terreno continúa teniendo capacidad uno. Al jugar un segundo Terreno, la receta consulta en orden la identidad vigente más la definición entrante. Si hay receta, la carta anterior pasa al Cementerio y la entrante conserva en metadatos la identidad, el nombre y los dos componentes ordenados del resultado. Si no hay receta, la entrante sustituye al anterior como Terreno base. No se crean instancias adicionales ni se alteran las 40 cartas físicas de cada jugador.

Los documentos solo fijan por ahora la identidad ambiental de los seis resultados. Hasta que sus efectos se definan expresamente, una forma transformada no hereda el bono de su carta portadora ni recibe efectos inventados.

### JCP-DEC-013 — Compatibilidad mediante anatomía y aptitudes — vigente

No existe una puntuación universal de Inteligencia. El cuerpo de una criatura se representa mediante un perfil anatómico y sus capacidades mediante aptitudes discretas como Bestial, Sapiente, Lector, Canalizador o Manipulador. Una carta puede exigir varias aptitudes y una o más anatomías compatibles; cumplir una capa no permite ignorar la otra.

El dibujo orienta el concepto, pero la regla procede de datos explícitos. Un animal puede utilizar un arma adaptada si su carta posee la aptitud y anatomía requeridas; un humanoide o troll no puede usar un grimorio únicamente por tener manos si carece de Lectura o Canalización. Las auras sin requisitos físicos pueden seguir siendo universales cuando su texto lo establezca.

Esta reserva quedó satisfecha en JCP-DEC-019: M01–M18 ya poseen identidad y anatomía concreta. La separación entre anatomía y aptitudes continúa vigente y ninguna capacidad se deduce silenciosamente de otra.

### JCP-DEC-014 — Corpus de diseño indexado y con procedencia — vigente

Las seis fuentes de Google Drive se conservan como originales editables y cuentan con copias locales normalizadas, manifiesto e índice temático. Cada fase debe consultar únicamente su ruta de fuentes y citar las claves S00–S05 utilizadas. Una ausencia explícita o un dato marcado como futuro no puede completarse por inferencia silenciosa. La integridad local se comprueba automáticamente y la frescura se verifica comparando `modified_time` con Drive al iniciar trabajo de diseño.

### JCP-DEC-015 — Fundamento genérico antes que contenido de Fusión — vigente

Fuentes consultadas: S01, S03 y S04.

El contrato técnico de Fusión se construye separado del estado del duelo y sin recetas reales mientras los materiales M01–M18 y los resultados carezcan de los datos que las propias fuentes dejan pendientes. El servicio puede validar recetas, resolver coincidencias y construir la representación canónica, pero no autoriza inventar nombre, especie, familia, anatomía, coste, ATQ, DEF ni habilidad.

Una Fusión encadenada contiene una lista plana de las cartas físicas originales. La procedencia puede repetir una identidad de Fusión intermedia si dos entidades del mismo tipo participan, pero una carta física jamás puede contarse dos veces. Solo una receta completa y aprobada permitirá después conectar una acción al motor.

### JCP-DEC-016 — Primer núcleo Goblin y F010-N — retirada antes de cierre

Fuentes consultadas: S01, S02, S03 y S04.

M04 pasa a llamarse Goblin Rebuscador y M09 Goblin Pendenciero. Ambos son Goblins Neutrales de anatomía Humanoide y poseen Sapiente y Manipulador. Se preservan sin cambios sus costes, estadísticas y la habilidad aprobada de M09.

La primera variante concreta de F010 se identificó provisionalmente como F010-N: dos Goblins Neutrales visibles del mismo controlador formarían una Banda Goblin.

Esta candidata se retiró al recuperar el orden correcto de trabajo: compendio, criaturas base, asignación a M01–M18 y solo entonces cifras de Fusión. Los nombres Goblin Rebuscador y Goblin Pendenciero, así como coste, estadísticas y habilidad de F010-N, no son decisiones vigentes y no permanecen en el motor.

### JCP-DEC-017 — Compendio antes que asignación — vigente

Fuentes consultadas: S03 y S04.

Las 60 entradas de familia y las 125 recetas conceptuales se organizan primero como compendio. Las criaturas M01–M18 solo recibirán identidad después de preparar las criaturas base de una familia y contrastar su elemento, anatomía, aptitudes y función con los esqueletos ya existentes.

No se inventan combinaciones libres. Una pareja solo se fusiona si S04 o una decisión posterior registra una receta concreta. La V0.1 limita cada receta a dos materiales, pero no impone un límite universal de Fusiones por turno ni un coste universal adicional de Energía.

### JCP-DEC-018 — Límite de Fusión para la primera prueba — provisional

La primera baraja generalista utilizará una acción de Fusión como máximo por jugador y turno. El límite se aplica a la acción y no a las entidades que pueden coexistir. No añade coste universal de Energía y no modifica el contrato conceptual de S04; es un parámetro de prueba para evitar cadenas explosivas mientras se valida el traslado de materiales, equipo y casillas.

Esta decisión deberá confirmarse, ampliarse o retirarse después de las primeras partidas. Hasta entonces no se presenta como regla universal definitiva para todos los formatos.

### JCP-DEC-019 — Identidades de la baraja inicial en runtime — vigente

Fuentes consultadas: S01, S02, S03 y S04.

M01–M18 adoptan los nombres y las cinco familias de `BARAJA_INICIAL_FANTASIA_GENERALISTA_V0_1`. Se conservan exactamente su curva, ATQ, DEF, elemento, habilidad funcional y reparto de once Manipuladores procedentes de S01.

Los Lobos son Cuadrúpedos y Bestiales; los Goblins y Trolls son Humanoides Sapientes y Manipuladores; las manifestaciones Elementales declaran individualmente anatomía y aptitudes; M17 es un Dragón Alado Bestial no Manipulador y M18 un Dragón Alado Sapiente y Manipulador. M12 y M15 son Canalizadores. Ninguna criatura recibe Lector.

Una criatura jugable ya no puede conservar `unassigned`, carecer de familia ni repetir etiquetas identitarias. La decisión está implementada y verificada en Godot 4.7.

### JCP-DEC-020 — Primer catálogo real de tres Fusiones — vigente

Fuentes consultadas: S01, S02, S03 y S04.

El catálogo específico registra tres recetas no ordenadas: F001-NAT para dos Lobos de Naturaleza, F010-NEU para dos Goblins Neutrales y F067-AGU para dos Elementales de Agua. Sus perfiles completos proceden de los documentos individuales aprobados.

Las recetas se resuelven mediante el servicio genérico y perfiles derivados de las definiciones e instancias reales. Esta decisión de catálogo no autorizaba todavía una acción del jugador, consumo de materiales, ocupación de casilla ni efectos durante una partida; JCP-DEC-023 habilitó después F010 y JCP-DEC-025 completó F001/F067. Las demás recetas permanecen sin registrar. El catálogo está verificado en Godot 4.7.

### JCP-DEC-021 — Destinos de una Fusión y sus materiales — vigente para prototipo

Fuentes consultadas: S01 y S04, más recuperación de la conversación original de diseño.

Las entidades de Fusión no son cartas físicas. La destrucción hace desaparecer la entidad y envía sus materiales contenidos y vínculos al Cementerio. Un efecto de devolución hace desaparecer la entidad, devuelve los materiales físicos a la mano y envía sus vínculos al Cementerio. Una separación expresa es distinta: devuelve los materiales al campo únicamente si existen casillas suficientes; entran boca arriba y cuentan como llegados ese turno.

Una Fusión nueva aparece boca arriba en ataque o guardia a elección del jugador, cuenta como entrada ese turno y no puede atacar inmediatamente. Ninguna de estas transiciones recupera la acción de Fusión consumida. Una carta que ya llegó al Cementerio no regresa automáticamente.

### JCP-DEC-022 — Las cartas pueden sustituir reglas y contener efectos latentes — vigente

Fuentes consultadas: S00, S01, S03 y S04, más recuperación de la conversación original de diseño.

Las reglas generales son comportamientos por defecto. Una carta, habilidad, receta o estado puede sustituir una parte concreta mediante una excepción escrita y determinista; aquello que no sustituya continúa aplicándose. El motor no inventa excepciones desde el nombre o la ilustración.

Algunas cartas podrán tener efectos latentes con pista visible, condición exacta oculta, resultado determinista y revelación posterior en un códice. El secreto debe seguir ofreciendo decisiones cuando ya sea conocido. Un texto que prometa una reacción importante debe tener traducción mecánica presente o latente; el texto puramente ambiental puede carecer de efecto cuando no promete una capacidad jugable.

`docs/diseno/PRINCIPIOS_EXCEPCIONES_Y_EFECTOS_LATENTES_V0_1.md` conserva el contrato completo. «Venganza del Bosque» es solo un ejemplo pendiente de diseño y no una carta aprobada.

### JCP-DEC-023 — F010 como primera Fusión jugable — vigente para prototipo

F010-NEU se habilita como única receta ejecutable dentro del duelo. La acción `fuse_creatures` exige M04 Goblin Rebuscador y M09 Goblin Pendenciero propios, boca arriba y en la fila de criaturas; puede realizarse una vez por turno durante una fase principal propia y no tiene coste universal de Energía.

La primera carta física indicada actúa como portadora de la identidad generada y continúa ocupando una casilla. La otra pasa a la zona pública `fusion_materials`, enlazada recíprocamente con la portadora. Esta representación conserva exactamente las 80 cartas físicas y permite que estadísticas, coste, familia, anatomía y aptitudes procedan de Banda Goblin en vez de heredarse accidentalmente de la carta portadora.

La Formación entra boca arriba en ataque o guardia a elección del jugador, y cuenta como recién llegada. Los equipos de ambos materiales se revalidan contra su perfil Humanoide, Sapiente y Manipulador: los compatibles se religan a la portadora y los incompatibles van al Cementerio.

Su habilidad `activate_fusion_ability` se usa una vez por turno y por Banda durante una fase principal propia: paga 1 de Energía y concede +1 ATQ hasta final del turno a una criatura propia boca arriba, incluida ella misma. La destrucción y la devolución aplican JCP-DEC-021. En esta fase F001/F067 todavía quedaban en catálogo; JCP-DEC-025 las habilita posteriormente.

### JCP-DEC-024 — Equilibrio por valor total y función — vigente

El ajuste de cartas se delega en una comparación sistemática del catálogo completo. ATQ y DEF no se fijan de forma aislada: se ponderan junto con coste, materiales, casillas, tiempo de preparación, fiabilidad, efecto, flexibilidad y contrajuego real.

Cada tramo de coste contendrá perfiles atacantes, defensivos, equilibrados, de utilidad y de alto riesgo. Puede haber diferencias deliberadas de potencia aparente cuando una condición o función las compense, pero ninguna carta debe convertirse en elección obligatoria ni quedar sin utilidad razonable.

Que existan Magias y Trampas capaces de destruir una amenaza forma parte del contrajuego, pero no justifica por sí solo una potencia ilimitada: también se compara disponibilidad, coste, ventana y resultado del intercambio. `docs/diseno/MODELO_DE_EQUILIBRIO_DE_CARTAS_V0_1.md` define el procedimiento de comparación y ajuste mediante pruebas.

### JCP-DEC-025 — F001 y F067 jugables; elección antes de respuestas — vigente para prototipo

Fuentes consultadas: S01, S02, S03 y S04, junto con las propuestas aprobadas de F001 y F067.

F001-NAT y F067-AGU se habilitan mediante la misma acción, representación física, límite por turno, equipo y destinos de F010. No se crean reductores especiales para sus materiales. El conjunto jugable de esta fase queda limitado a las tres identidades registradas en `fusion_catalog.gd`.

El liderazgo de F001 se dispara al declarar el primer ataque de otra criatura propia en cada turno de su controlador. Concede +1 ATQ exclusivamente durante ese combate y queda consumido aunque una respuesta cancele el ataque. Cada Alfa conserva su propio uso; varias copias pueden acumular sus disparos si el jugador ha comprometido los materiales necesarios.

F067 exige una elección obligatoria de su controlador antes del primer combate en el que participa cada turno. Si ambos combatientes fueran Elementales Mayores pendientes de elegir, decide primero el atacante y después el defensor. Terminadas las elecciones, se abre la ventana ordinaria de respuestas con prioridad del defensor. El bono elegido es +1 ATQ o +1 DEF solo para ese combate, no cambia postura ni permanece en metadatos como estadística temporal.

### JCP-DEC-026 — La prueba vertical usa el contrato real del motor — vigente

Una Fusión no se considera integrada solo por superar pruebas directas del módulo. Debe poder validarse y confirmarse a través de `UniversalCardEngine`, conservar vistas y eventos públicos coherentes y reproducir exactamente el snapshot completo desde semilla y registro de acciones.

Los resultados de `validate_action()` conservan el contrato estricto de tres claves —`ok`, `code` y `message`—. Los datos auxiliares usados para construir una acción no pueden escapar en esa respuesta. La prueba vertical de las ocho Fusiones iniciales queda como regresión obligatoria al ampliar recetas o modificar combate, Fusiones, zonas, eventos, vistas o replay.

### JCP-DEC-027 — F011 Banda de Antorchas como cuarta Fusión — vigente para prototipo

F011-NF se forma con un Goblin Neutral y un Goblin de Fuego propios y visibles, en cualquier orden, mediante el mismo ciclo físico y límite por turno de las Fusiones anteriores. Es una Formación Goblin Neutral/Fuego, Humanoide, Sapiente y Manipuladora, de coste de referencia 3 y cifras 3/2.

Cada vez que declara un ataque obtiene +1 ATQ solo durante ese combate. Si en ese momento controla además otro Goblin boca arriba, obtiene también +1 DEF durante ese combate. La propia Banda no cuenta como «otro Goblin» y una criatura colocada no activa ni revela indirectamente la condición. El disparo ocurre antes de elecciones y respuestas y se registra como evento público. Su recorrido vertical usa robos y despliegues naturales y conserva replay exacto.

### JCP-DEC-028 — F012 Cuadrilla del Matorral como quinta Fusión — vigente para prototipo

F012-NN se forma con un Goblin Neutral y un Goblin de Naturaleza propios y visibles, en cualquier orden, mediante el ciclo físico común. Es una Formación Goblin Neutral/Naturaleza, Humanoide, Sapiente y Manipuladora, de coste de referencia 3 y cifras 2/4.

La primera vez en cada turno global que es atacada reduce 1 ATQ al atacante solo durante ese combate. El uso se consume al declarar, aunque una respuesta cancele después el ataque. La penalización se aplica antes de elecciones y respuestas, puede acumularse con T02 y amplía el límite validado de `attacker_attack_delta` a −5…+5 sin permitir estadísticas finales negativas. Su recorrido vertical usa energía, robos, mareo de invocación y replay exacto.

### JCP-DEC-029 — F068 Elemental de Vapor y duración por turno del propietario — vigente para prototipo

F068-FA se forma con un Elemental de Fuego y uno de Agua propios y visibles, en cualquier orden. Es una Integración Elemental Fuego/Agua, Amorfa, sin aptitudes inventadas, de coste de referencia 3 y cifras 2/4.

Si existe alguna criatura enemiga boca arriba, la acción de Fusión debe elegir una como objetivo. Si no existe ninguna, la Fusión puede entrar y el efecto no se aplica. El objetivo recibe −1 ATQ, con mínimo cero; varias aplicaciones pueden acumular hasta −5.

La duración no se expresa como un número global supuesto: el objetivo conserva un contador de un final de turno de su propietario. La penalización permanece durante todo su siguiente turno, incluida la fase Final, y expira al cerrarlo. Si la criatura abandona el campo antes, la penalización se limpia. Aplicación y expiración generan eventos públicos y forman parte del replay exacto.

### JCP-DEC-030 — F018 Troll Bicéfalo y reemplazo de destrucción — vigente para prototipo

F018-NEU se forma con dos Trolls Neutrales propios, visibles y de definiciones distintas entre M11, M13 y M16, en cualquier orden. Dos copias físicas de un mismo Troll no satisfacen la receta. Es una Integración Troll/Humanoide Neutral, Sapiente y Manipuladora, de coste de referencia 6 y cifras 6/6.

La primera vez en cada turno global que fuera a ser destruido como resultado del cálculo de combate, esa destrucción se reemplaza: permanece en el campo y pasa a guardia. El uso solo se consume cuando evita una destrucción real. La postura forzada no es un cambio voluntario, no consume el cambio de postura de la criatura y no dispara G05 ni permite T04. El daño de combate ya calculado no se revierte.

Al no ser destruido, su controlador no puede activar T06 por el propio Troll. Si el otro combatiente sí fue destruido, su controlador puede activar T06 y destruir después al Troll superviviente, porque la regeneración solo reemplaza destrucción de combate. El uso, la postura y los eventos forman parte del estado determinista y del replay.

### JCP-DEC-031 — F005 y ataque adicional — vigente para prototipo

Fuentes: S01 y S04, comprobadas en Drive sin cambios respecto al manifiesto, y baraja inicial local aprobada. Se mantienen nombre, pareja M17 + M18, coste 8 y cifras 8/8. Para el prototipo se fija explícitamente un perfil Dracónico de Fuego, Alado y Bestial, sin Manipulador; no se heredan automáticamente las aptitudes de M18. Este perfil resultante es una decisión provisional de implementación, no un dato recuperado de S04; su anatomía visual definitiva queda pendiente.

Tras destruir realmente al otro combatiente y sobrevivir, F005 obtiene un ataque adicional para ese turno global, una sola vez. El permiso se consume al declarar el segundo ataque, aunque sea cancelado. No borra el ataque ya realizado ni habilita cambios de postura, ataques fuera de turno o durante el turno de entrada. Las respuestas posteriores al combate se resuelven antes de volver a atacar. Igualdad, ataque directo y destrucción evitada no disparan el efecto. El permiso no pasa al siguiente turno ni sobrevive a la salida del campo.

### JCP-DEC-032 — Cobertura ejecutable de M01–M18 — vigente para prototipo

Fuentes: S01 y S03, comprobadas en Drive sin cambios respecto al manifiesto, y baraja inicial local aprobada. M01, M02, M03, M04, M08, M11, M14 y M17 no tienen habilidad. M05 obtiene +1 ATQ al declarar durante ese combate; M06 obtiene +1 DEF al revelarse por recibir un ataque; M07 roba una carta al ser destruido; y M10 obtiene +1 ATQ mientras está en guardia.

M09 paga 1 de Energía una vez por turno durante una fase principal propia para obtener +1 ATQ hasta final del turno. M12, al entrar boca arriba, debe elegir un apoyo rival oculto si existe: solo su controlador conoce la identidad y la carta no se revela ni activa. M15 debe elegir otra criatura propia si existe y le concede +1 ATQ/+1 DEF hasta final del turno; puede entrar sin objetivo cuando está sola.

M13 puede redirigir hacia sí, una vez por turno global, un ataque declarado contra otra criatura propia. El ataque ya queda consumido; el defensor puede aceptar o rechazar la redirección antes de elecciones de Fusión y antes de abrir la ventana normal de respuestas. Si acepta, trampas y combate reciben a M13 como objetivo. La oferta pública no filtra la identidad de una criatura original oculta.

La primera vez de cada turno global que M16 destruya una criatura en combate recupera 1 de Energía, sin superar su máximo. La primera vez que M18 destruya en combate y sobreviva obtiene un ataque adicional ese turno, con las mismas restricciones temporales de segundo ataque de F005 pero como habilidad independiente. Los materiales no conservan habilidades base mientras una identidad de Fusión ocupa su portador. Los marcadores de habilidad se validan y se limpian al fusionar o abandonar el campo.

### JCP-DEC-033 — Mesa manual local y relevo privado — vigente para prototipo

La primera interfaz utiliza `UniversalCardEngine` como única frontera: presenta `get_player_state()`, eventos filtrados y `get_legal_actions()`, y envía únicamente acciones legales mediante `perform_action()`. No consulta el estado privado bruto ni vuelve a implementar reglas en controles visuales.

La mesa es local para dos personas. Al cambiar la prioridad o seleccionar la vista del otro jugador, tablero, acciones y registro quedan detrás de una cortina hasta que el siguiente jugador confirma que puede mirar. La mano rival conserva su recuento público pero no sus identidades. El registro de M13 publica casillas, no el identificador interno del objetivo original oculto.

La presentación incorpora componentes reutilizables de carta y casilla. Seleccionar una carta prioriza sus acciones legales y abre una ficha mecánica obtenida de la vista; las variantes que solo difieren en objetivo, postura o elección se agrupan y se confirman en un segundo paso. El primer paso no muta el juego y el segundo envía una acción legal exacta. Las relaciones por casilla se derivan de la vista para respuestas y objetivos que no publican identificadores.

La mesa ofrece una ranura local. Guardar usa el formato tipado, checksum y escritura atómica de UCE. Cargar no inyecta estado: valida el paquete y reconstruye la sesión desde semilla y registro de acciones, aceptándola solo si la instantánea completa coincide; después exige revelar de nuevo la vista. Ganador y motivo proceden del estado público. Esta interfaz no modifica semántica ni formato de persistencia/replay.

### JCP-DEC-034 — Reserva creativa posterior a la primera partida básica

La prioridad inmediata continúa siendo terminar una primera partida técnica cómoda. El comentalista futuro será texto reactivo alimentado por eventos resueltos, con variantes temáticas y humor contextual, pero sin voz ni autoridad para cambiar resultados. Toda consecuencia que narre deberá existir antes como mecánica registrada; los ejemplos actuales no fijan cartas ni penalizaciones.

Las transformaciones futuras de Terreno podrán proceder de Magias, Trampas, objetos, criaturas o Fusiones, además de la combinación entre Terrenos. Cada transformación será una receta explícita y determinista; afinidades, nombres o ilustraciones no bastan para activarla. Bosques quemados, ceniza y zonas de Obsidiana permanecen como espacios de diseño para la fase compleja posterior.

### JCP-DEC-035 — Derrota por robo con baraja vacía — vigente en 0.22.0

S01 fija que, si un jugador debe robar una carta y su baraja está vacía, pierde la partida. El intento de robo normal termina inmediatamente antes de entrar en Principal 1: no crea carta, no permite continuar el turno y declara ganador al rival. El evento público identifica al jugador agotado y los ganadores. La corrección cambia la semántica de replay, por lo que el módulo pasa a `0.22.0-deck-exhaustion` aunque la estructura del estado no cambie.

### JCP-DEC-036 — Ataque durante el turno de invocación — vigente en 0.23.0

S01 fija que una criatura invocada normalmente boca arriba en ataque puede declarar un ataque durante ese mismo turno. El jugador inicial no puede atacar durante el primer turno de la partida. Una criatura colocada boca abajo continúa sin poder cambiar de postura ese turno; una Fusión recién formada cuenta como entrada distinta y no puede atacar inmediatamente. Las menciones históricas a un «mareo de invocación» general quedan sustituidas por esta regla más precisa.

### JCP-DEC-037 — Exactitud de las acciones anunciadas — vigente en 0.24.0

Toda acción devuelta por `get_legal_actions()` debe superar inmediatamente `validate_action()` sobre el mismo estado. El estrés automático se incorpora como puerta técnica reproducible para buscar desacuerdos y bloqueos. La corrección no añade reglas de diseño: aplica las ya vigentes de S01 para postura posterior al ataque y de JCP-DEC-026 para impedir Fusiones encadenadas durante esta primera prueba.

## Reglas jugables consolidadas

- Duelo de dos jugadores, 30 vidas y energía creciente hasta 10.
- Se roba al entrar en Robo, salvo el primer turno del jugador inicial.
- Una criatura entra visible en ataque o colocada oculta en guardia.
- Una invocación normal boca arriba puede atacar al entrar; el jugador inicial no ataca en el primer turno y una Fusión recién formada tampoco ataca inmediatamente. Ninguna criatura ataca dos veces por defecto.
- El combate compara simultáneamente ATQ del atacante contra DEF del objetivo y ATQ del objetivo contra DEF del atacante.
- La igualdad no destruye: hace falta superar estrictamente la DEF.
- Una criatura rival impide atacar directamente.
- Un defensor en guardia absorbe el sobrante; el daño diferencial solo atraviesa al derrotar una criatura en ataque.
- G01: +2 ATQ hasta fin de turno.
- G02: +2 DEF hasta fin de turno.
- G03: devuelve una criatura enemiga visible de coste impreso 2 o menos y destruye sus vínculos.
- G04: las criaturas propias en guardia obtienen +1 DEF.
- G05: la primera transición voluntaria propia de guardia a ataque por turno concede +1 ATQ ese turno.
- G06: cuando una criatura propia es atacada, obtiene +2 DEF durante ese combate.
- G07: cuando una criatura propia es atacada, vuelve a la mano y el ataque queda cancelado.
- T01: cuando ataca una criatura enemiga de coste 2 o menos, se destruye y el ataque queda cancelado.
- T02: cuando una criatura propia es atacada, el atacante recibe -2 ATQ durante ese combate, con mínimo cero.
- T03: cuando el rival activa una Magia principal, puede anularse antes de aplicar su efecto; la Magia y T03 van al cementerio.
- T04: después de que una criatura enemiga cambie voluntariamente de guardia a ataque, puede devolverse a guardia; el cambio del turno continúa consumido.
- T05: después de que el rival vincule un equipo, puede destruirse esa carta y limpiarse su vínculo.
- T06: después de perder una criatura en combate, puede destruirse al combatiente enemigo si continúa en campo.
- E04: una vez por turno y por copia activa, traslada un equipo ya vinculado a otra criatura propia visible que cumpla sus requisitos.
- E01, E03 y E06 requieren la aptitud Manipulador; esa aptitud no presupone Sapiente, Lector ni Canalizador.
- Todo equipo vinculado debe seguir cumpliendo sus requisitos anatómicos y de aptitud; si una futura transformación los elimina, la transición deberá resolver el vínculo antes de validar el nuevo estado.
- Bosque + Lago = Bosque Inundado; Lago + Bosque = Humedal Fértil.
- Bosque + Volcán = Bosque Ardiente; Volcán + Bosque = Bosque Volcánico.
- Lago + Volcán = Caldera de Vapor; Volcán + Lago = Llanura de Obsidiana.
- Sin receta ordenada, el Terreno entrante sustituye al vigente.
- Una carta reactiva preparada este turno no puede activarse aún.
- Las respuestas resueltas terminan reveladas e inactivas en el cementerio.
- F010-NEU: dos Goblins Neutrales propios y visibles forman Banda Goblin; máximo una acción de Fusión normal por turno en esta prueba.
- F011-NF: un Goblin Neutral y uno de Fuego forman Banda de Antorchas; al atacar combate como 4/2 o como 4/3 si controla otro Goblin visible.
- F012-NN: un Goblin Neutral y uno de Naturaleza forman Cuadrilla del Matorral; una vez por turno, al ser atacada, resta 1 ATQ al atacante durante ese combate.
- F068-FA: un Elemental de Fuego y uno de Agua forman Elemental de Vapor; al entrar penaliza temporalmente a una criatura enemiga visible.
- M05, M06, M07, M09, M10, M12, M13, M15, M16 y M18 ejecutan sus textos aprobados; las demás criaturas M no tienen habilidad.
- M12 conserva privada la identidad inspeccionada y M13 resuelve su decisión de redirección antes de trampas.
- Banda Goblin entra boca arriba en ataque o guardia, cuenta como recién llegada y usa una sola casilla aunque contenga dos cartas físicas.
- Banda Goblin puede pagar 1 de Energía una vez por turno durante una fase principal propia para dar +1 ATQ hasta final del turno a una criatura propia visible.
- Destruir Banda Goblin envía ambos materiales y vínculos al Cementerio; devolverla a la mano devuelve ambos materiales y destruye sus vínculos.

## Reglas escritas con implementación parcial o pendiente

- Los efectos propios de los Terrenos transformados siguen pendientes. F001-NAT, F005-FUE, F010-NEU, F011-NF, F012-NN, F018-NEU, F067-AGU y F068-FA están integradas y verificadas conjuntamente.
- El servicio puro representa que una Fusión contiene sus materiales físicos y genera una entidad que no pertenece al mazo principal; las ocho Fusiones demuestran ya ese ciclo dentro del estado del duelo.
- Al destruirse una Fusión, desaparece la entidad generada y todos sus materiales físicos contenidos pasan al Cementerio.
- El servicio soporta recetas no ordenadas por defecto, materiales visibles y coincidencia únicamente con recetas registradas; F001, F005, F010, F011, F012, F018, F067 y F068 están habilitadas como acciones jugables.
- El servicio aplana los materiales físicos de una Fusión encadenada; las cadenas de Fusiones continúan deshabilitadas en la primera acción jugable.
- No se implementará una receta concreta hasta que sus materiales existentes tengan familia/anatomía y el resultado tenga coste, ATQ, DEF y habilidad definidos. El catálogo V0.1 declara expresamente esos valores como pendientes.
- Los personajes especiales siguen siendo conceptos abiertos; no se les asignarán cifras ni habilidades por inferencia.
- El narrador solo describirá resultados ya calculados por el motor y mostrará también su explicación mecánica; no decidirá resultados ni inventará excepciones. Faltan todavía las frases y eventos concretos.
- Las excepciones escritas y los efectos latentes forman parte de la arquitectura futura, pero ninguna latencia concreta está todavía implementada.

### JCP-DEC-038 — Flujo visual directo de la mesa — vigente para prototipo

Inicio y Robo ordinarios se resuelven automáticamente; las cartas comunes se juegan seleccionando carta y después casilla u objetivo; las cinco posiciones de cada fila son equivalentes; y el lateral deja de duplicar estas acciones. La mesa ofrece controles explícitos de Combate y fin de turno, Fusión por selección de materiales, historial plegado, equipo bajo portador y tratamiento diferenciado de transformación o sustitución de Terreno. Esta decisión traduce S00/S01 a interfaz y no cambia las reglas del duelo.

### JCP-DEC-039 — Lenguaje visual de duelo y selección de ataque — vigente para prototipo

Fuentes consultadas: S00 y S01; referencias visuales aportadas por el diseñador el 2026-09-11.

La mesa utiliza el lenguaje espacial general de un juego de cartas enfrentado sin copiar identidad gráfica: cámara casi cenital, inclinación suave, cuadrícula casi paralela, ambas manos rectas y completamente visibles y filas permanentes enfrentadas. La perspectiva no reduce ninguna pieza: cartas, casillas y zonas laterales tienen el mismo tamaño para ambos jugadores. Una línea divide los territorios sin emblema central y contiene las fases. Territorio, materiales de Fusión, Baraja y Cementerio ocupan zonas laterales independientes y enfrentadas; la ficha ampliada permanece en el lateral informativo. Las casillas conservan proporción vertical de carta. Ataque se representa en vertical y guardia en horizontal; una criatura oculta conserva reverso y puede ser objetivo público por su casilla sin revelar identidad.

La interfaz no presenta todos los apoyos como equivalentes: un equipo o una Magia instantánea dirigida obliga a elegir criatura y no puede aparcarse en Apoyo; la instantánea va al Cementerio tras resolverse. Las Magias persistentes ocupan Apoyo boca arriba y las Trampas o respuestas preparadas lo hacen boca abajo. Son visualizaciones de las acciones legales ya definidas por S01, no reglas importadas de otro juego.

Seleccionar una criatura propia fuera de Combate no permite que un clic prematuro sobre el rival sustituya silenciosamente la selección: conserva al atacante y explica que debe entrarse en Combate. Dentro de Combate, se elige atacante y después criatura rival resaltada; cuando el campo rival está vacío, la cabecera de Vida rival funciona como objetivo de ataque directo. Las casillas continúan siendo equivalentes y su elección sigue siendo estética.

### JCP-DEC-040 — Greybox representativo antes de la prueba humana — vigente para prototipo

Fuentes consultadas: S00 y S01, decisiones JCP-DEC-033/038/039 y referencias visuales aportadas por el diseñador; decisión de trabajo confirmada el 2026-09-12.

Las pruebas automáticas pueden seguir validando motor y reglas sin arte final, pero una prueba humana de claridad, comodidad y ritmo debe realizarse sobre una disposición suficientemente representativa de la futura experiencia. Por tanto, la sesión humana completa queda pospuesta hasta disponer de un **greybox de interfaz final**: sin ilustraciones, animaciones, audio ni ornamentación definitiva, pero con la jerarquía, proporciones, posiciones y flujo que se pretende conservar.

El tablero y las cartas dominan visualmente; la mano propia permanece abajo y la rival arriba; Vida y Energía se integran en las cabeceras; Territorio, Baraja, Cementerio y materiales de Fusión son zonas compactas; la banda de fases queda fuera del centro jugable; y el lateral se limita a ficha de carta, decisiones contextuales e historial subordinado. Las casillas vacías no repiten texto administrativo salvo cuando deben comunicar un destino legal.

Esta decisión **no cambia ninguna regla del duelo**. La interfaz continúa consumiendo únicamente vistas, eventos filtrados y acciones legales de `UniversalCardEngine`; no puede calcular reglas por su cuenta ni acceder al estado privado bruto. Las herramientas de diagnóstico y modo local 2P pueden permanecer disponibles, pero no deben dirigir la lectura normal de la partida.

El contrato completo está en `docs/diseno/GREYBOX_INTERFAZ_FINAL_V0_1.md`. La fase no se considera cerrada por estar escrita: necesita parser/runtime en Godot 4.7, puertas proporcionales de interfaz e inspección de una captura real por el diseñador antes de iniciar la sesión humana completa.

### JCP-DEC-041 — Benchmark modular antes de fijar medidas del greybox — vigente para prototipo

Antes de seguir afinando el greybox por ensayo visual, se documenta un benchmark de varios juegos de cartas digitales y físicos en `docs/diseno/CUADERNO_BENCHMARK_INTERFAZ_TCG_V0_1.md`. Yu-Gi-Oh! y Magic son referencias importantes, pero no exclusivas: también se estudian Legends of Runeterra, Shadowverse, Pokémon TCG, Marvel Snap, Flesh and Blood, Disney Lorcana, Shadowverse: Evolve y Eternal, y se dejan otras referencias en reserva.

El método es **modular**: cada producto se usa solo para el problema que resuelve especialmente bien —campo, orientación, mano, objetivos, prioridad, cadena, adjuntos, Fusión/identidades apiladas, turno o legibilidad—. No se copiará una interfaz completa ni su identidad visual. La siguiente revisión del greybox debe derivar tamaños y espaciados de una unidad de carta común, conservar las reglas propias y adoptar únicamente patrones funcionales aceptados.

Como candidatos de trabajo, no como reglas de duelo, quedan registrados: relación de carta 63:88; resaltado de cartas jugables; selección carta→destino; equipo visualmente unido al portador; mini-cadena temporal para respuestas; preview de carta bajo demanda; fase/energía/fin de turno de lectura inmediata; y una posible previsión `si se resolviera ahora` calculada solo con información pública y por la autoridad del motor. La implementación visual V0.1 ya escrita se considera un **andamio provisional** hasta contrastarla con esta base.

### JCP-DEC-042 — Feedback comunitario filtrado por viabilidad — vigente para prototipo

Antes de congelar el estándar del greybox, el benchmark comercial se contrasta con feedback de jugadores en `docs/diseno/CUADERNO_BENCHMARK_COMUNIDAD_Y_FOROS_V0_1.md`. Las sugerencias de foros no se adoptan por popularidad: deben resolver un problema aplicable a JCP, ser viables con UI 2D/2.5D y datos del motor, respetar privacidad/replay/determinismo y no introducir una carga desproporcionada para un proyecto pequeño.

Se excluyen como requisito de esta fase cinemáticas 3D, monstruos animados que salen de la carta y VFX complejos. Sí se consideran de alto valor: efectos activos con fuente/duración, texto de carta estructurado, usos restantes visibles, reducción de clics sin decisión real, inspección del tablero durante decisiones y un punto de commit claro que permita cancelar selección antes de `perform_action()` pero no rebobinar acciones resueltas.

La idea comunitaria `¿por qué no puedo?` se acepta como **dirección futura**, no como código inmediato: si se implementa, la explicación deberá proceder de UCE o de los mismos códigos de validación, nunca de una segunda copia de reglas en la interfaz. Ninguna sugerencia comunitaria altera por sí sola las reglas del duelo.