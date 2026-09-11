# Changelog

## Juego de cartas propio 0.24.0 — Endurecimiento por estrés — 2026-09-11

- Añadidas dos puertas reproducibles: partidas rápidas contra el módulo de reglas y partidas completas mediante `UniversalCardEngine`, vistas, snapshots y replay.
- El primer barrido encontró que una criatura que ya había atacado aparecía indebidamente con cambio de postura legal en Principal 2. La enumeración comparte ahora la prohibición `JCP_POSITION_AFTER_ATTACK`.
- El segundo barrido encontró que una Fusión previa podía aparecer como material legal de otra receta aunque las Fusiones encadenadas están deshabilitadas. El constructor jugable filtra ahora esos materiales antes de anunciar la acción.
- Tras las correcciones, la primera puerta completó 2.110 partidas y una ampliación independiente añadió 10.025: acumulado limpio de 12.135 partidas y 1.044.565 acciones.
- La ampliación larga por sí sola recorrió 4.323 Fusiones, 37.057 ataques, 13.322 respuestas activadas, 55 derrotas por baraja vacía y 470 empates simultáneos válidos; terminó sin fallo del motor.
- Corregido el coordinador duradero: el wrapper de consola de Godot puede devolver un código no representativo; la autoridad es el informe JSON PASS/FAIL producido por el proceso real.
- Regresiones específicas ampliadas: posturas 69/69 y acción de Fusión 72/72. Cierre completo: 22 suites específicas 1.357/1.357; UCE 441/441; diagnóstico 15/15; experimento 80/80; escena principal PASS; auditoría estática 24.709/93.
- El formato de estado no cambia, pero sí el conjunto de acciones anunciado; el módulo pasa a `0.24.0-stress-hardening`.

## Juego de cartas propio 0.23.0 — Ataque al invocar — 2026-09-11

- Corregida otra discrepancia entre S01 y el motor: una criatura invocada normalmente boca arriba en ataque puede atacar durante ese mismo turno.
- Se conserva la prohibición expresa de ataque durante el primer turno del jugador inicial. Una criatura colocada boca abajo no puede cambiar de postura ese turno y una Fusión recién formada continúa sin poder atacar inmediatamente.
- Las acciones legales y la validación directa comparten el mismo predicado, con rechazos diferenciados para primer turno y Fusión recién formada.
- Invocación sube de 16 a 32 comprobaciones. Las preparaciones artificiales de efectos se sitúan expresamente en una ronda posterior para no eludir accidentalmente la regla del primer turno.
- Cierre completo: 22 suites específicas 1.341/1.341; UCE 441/441; diagnóstico 15/15; experimento 80/80; escena principal PASS; auditoría estática final 23.969/91 tras añadir la sonda de equilibrio.
- La semántica de acciones y replay vuelve a cambiar; el módulo pasa a `0.23.0-summon-attack`.
- Añadidas una matriz de trazabilidad de S01 y una sonda reproducible de cifras F001/F067. No cambian reglas ni estadísticas: separan decisiones cerradas, riesgos medidos y materias abiertas.

## Juego de cartas propio 0.22.0 — Derrota por baraja agotada — 2026-09-11

- Corregido el bloqueo al intentar realizar el robo normal con la baraja vacía. La fuente S01 ya fijaba que ese jugador pierde la partida.
- El motor declara al rival ganador, usa el motivo `deck_empty`, entra en fase final y publica `player_deck_exhausted`; no genera un robo ficticio ni rechaza el avance.
- La mesa traduce el motivo como «baraja agotada al intentar robar».
- La suite de fases recorre las dos barajas completas y verifica final, ganador, ausencia de acciones, evento público y replay exacto; sube de 39 a 48 comprobaciones.
- Cierre completo: 22 suites específicas 1.325/1.325; UCE 441/441; diagnóstico 15/15; experimento 80/80; escena principal PASS; auditoría estática 23.779/90.
- El formato de estado no cambia, pero la semántica de una partida guardada sí; el módulo pasa a `0.22.0-deck-exhaustion` para impedir replays cruzados con la regla incompleta.

## Mesa manual local sobre 0.21.0 — 2026-09-11

- La escena principal pasa a una mesa local con ambos campos, baraja, mano privada, zonas, vida, Energía, fase, prioridad, acciones legales y registro de eventos filtrado.
- Añadidos componentes reutilizables de carta y casilla; seleccionar una carta la destaca y prioriza sus acciones relacionadas sin alterar el conjunto legal.
- Las variantes por objetivo, postura o elección se agrupan en una intención y se confirman en un segundo paso. Respuestas preparadas y criaturas rivales se relacionan mediante sus casillas visibles.
- Añadida cortina de relevo al cambiar de jugador o prioridad, bloqueo de acciones mientras está oculta, seguimiento opcional y reinicio por semilla.
- La carta seleccionada abre una ficha mecánica construida desde la vista filtrada. La mesa presenta ganador y motivo al terminar por rendición o vida agotada.
- Añadida una ranura local de guardado/carga: escritura atómica, checksum tipado y reconstrucción determinista por replay; una carga siempre vuelve detrás de la cortina.
- Corregida una fuga en eventos de M13: oferta, rechazo y redirección publican la casilla original y no el identificador de una criatura oculta.
- Nueva suite de mesa PASS 55/55, incluido un recorrido completo por daño; la suite activa se mantiene en 39/39. Total específico 1.316/1.316 en 22 suites.
- UCE 441/441, diagnóstico 15/15, experimento 80/80, escena principal PASS y render visual 1280×720 comprobado. Auditoría estática 23.709/90; fuentes 6/6; integridad histórica con cero ausentes y siete diferencias conocidas.
- Documentada para la fase compleja la dirección del comentalista textual y de transformaciones explícitas de Terreno; los ejemplos no se convierten todavía en cartas ni reglas.
- El módulo conserva versión 0.21.0 porque la mesa consume la persistencia y el replay universales sin alterar reglas ni formato.

## Juego de cartas propio 0.21.0 — Habilidades M01–M18 — 2026-09-11

- Cerrada la matriz de las dieciocho criaturas: ocho cartas sin habilidad por diseño y diez textos ejecutables sin atribuir a M18 la habilidad independiente de F005.
- Integradas las habilidades automáticas de M05, M06, M07, M10, M16 y M18; la acción pagada de M09; la inspección privada de M12; el objetivo de entrada de M15; y la redirección previa a trampas de M13.
- Las Fusiones no heredan la habilidad de su carta portadora. Se validan los nuevos marcadores de uso y se limpian al fusionar o abandonar el campo.
- Añadidas tres suites: 25 comprobaciones automáticas, 37 de acciones/objetivos/privacidad y 38 verticales UCE con replay exacto.
- Veintiuna suites específicas PASS 1.259/1.259. UCE 441/441, diagnóstico 15/15, experimento 80/80 y escena principal PASS.
- Auditoría estática PASS 22.462 comprobaciones sobre 87 archivos; fuentes locales 6/6 y frescura de S01/S03 comprobada en Drive. Manifiesto histórico: cero ausentes y siete diferencias conocidas.

## Juego de cartas propio 0.20.0 — Dragón Bicéfalo Elemental — 2026-09-10

- Integrada F005-FUE, octava y última Fusión de la baraja inicial: M17 + M18, coste 8, 8/8 y un ataque adicional por turno tras destruir en combate y sobrevivir.
- El permiso se consume al declarar incluso si se cancela; no borra el ataque realizado, no salta respuestas y expira por turno o salida del campo.
- Perfil corporal provisional explícito, sin herencia automática de Manipulador. M18 no recibe todavía su habilidad individual.
- Dieciocho suites específicas PASS 1159/1159, incluidas 131 pruebas de efectos de Fusiones y 82 verticales con replay exacto. UCE 441/441, diagnóstico 15/15, experimento 80/80, escena principal PASS.
- Auditoría estática PASS 21.328 comprobaciones sobre 84 archivos; fuentes locales 6/6 y frescura de S01/S04 comprobada en Drive.

## Juego de cartas propio 0.19.0 — Troll Bicéfalo — 2026-09-10

- Registrada y habilitada F018-NEU: dos Trolls Neutrales distintos forman Troll Bicéfalo 6/6; dos copias del mismo Troll no cumplen la receta.
- La primera vez por turno que fuera a ser destruido en combate, reemplaza esa destrucción y pasa forzosamente a guardia sin convertirla en un cambio voluntario.
- Si destruye al otro combatiente, T06 puede destruirlo después; su regeneración no protege frente a efectos ajenos al combate.
- Añadidas validación de metadatos, evento público, límite por turno, prueba de T06 y recorrido vertical con replay exacto.
- Dieciocho suites específicas PASS con 1102; nueve generales con 441; diagnóstico 15/15; experimento 80/80; escena principal PASS.
- Auditoría estática PASS con 21.036 comprobaciones sobre 84 archivos GDScript; fuentes locales PASS 6/6.

## Juego de cartas propio 0.18.0 — Elemental de Vapor — 2026-09-10

- Registrada y habilitada F068-FA: Elemental de Fuego + Elemental de Agua forman Elemental de Vapor 2/4.
- Si existe un enemigo boca arriba, la Fusión lo elige al entrar y le aplica −1 ATQ, con mínimo cero, hasta cerrar el siguiente turno de su controlador.
- La duración cuenta finales de turno del propietario en vez de depender de una alternancia global supuesta; abandonar el campo limpia la penalización.
- Aplicación y expiración poseen eventos públicos, validación de metadatos, vista efectiva y replay exacto.
- Corregida la expectativa de fases del recorrido vertical tras los reinicios; el motor había rechazado correctamente una acción del jugador equivocado.
- Dieciocho suites específicas PASS con 1065; nueve generales con 441; diagnóstico 15/15; experimento 80/80; escena principal PASS.
- Auditoría estática PASS con 20.774 comprobaciones sobre 84 archivos GDScript; fuentes locales PASS 6/6.

## Juego de cartas propio 0.17.0 — Cuadrilla del Matorral — 2026-09-10

- Registrada y habilitada F012-NN: Goblin Neutral + Goblin de Naturaleza forman Cuadrilla del Matorral 2/4.
- La primera vez por turno que es atacada resta 1 ATQ al atacante durante ese combate; el uso se consume en la declaración y puede acumularse con respuestas posteriores.
- El contexto admite modificadores base de ATQ del atacante entre −5 y +5 y el cálculo final conserva el mínimo cero.
- Añadido un recorrido vertical natural de F012 con energía, mareo de invocación, vista pública, evento, consistencia y replay exacto. La suite se renombra a `run_juego_cartas_propio_fusions_vertical.gd`.
- Dieciocho suites específicas PASS con 1032; nueve generales con 441; diagnóstico 15/15; experimento 80/80; escena principal PASS.
- Auditoría estática PASS con 20.509 comprobaciones sobre 84 archivos GDScript; fuentes locales PASS 6/6.

## Puerta vertical de cuatro Fusiones — 2026-09-10

- La prueba vertical incorpora una segunda partida natural para F011 con robos, despliegues, espera de entrada, combate 4/3 condicionado y Cementerio.
- Vista pública, evento `fusion_torch_band_triggered`, consistencia interna y replay exacto quedan cubiertos para Banda de Antorchas.
- Dieciocho suites específicas PASS con 1003; nueve generales con 441; diagnóstico 15/15; experimento 80/80; escena principal PASS.
- Auditoría estática PASS con 20.340 comprobaciones sobre 84 archivos GDScript; fuentes locales PASS 6/6.

## Juego de cartas propio 0.16.0 — Banda de Antorchas — 2026-09-09

- Registrada y habilitada F011-NF: Goblin Neutral + Goblin de Fuego forman Banda de Antorchas 3/2.
- Al atacar obtiene +1 ATQ durante ese combate y +1 DEF adicional si controla otro Goblin boca arriba; el disparo se publica antes de respuestas.
- F011 comparte representación física, equipo, destinos, vistas y límite de Fusión con el primer trío.
- Dieciocho suites específicas PASS con 990; nueve generales con 441; diagnóstico 15/15; experimento 80/80; escena principal PASS.
- Auditoría estática PASS con 20.238 comprobaciones sobre 84 archivos GDScript.

## Juego de cartas propio 0.15.1 — prueba vertical del primer trío — 2026-09-09

- Añadida una partida vertical determinista que forma F001, F010 y F067 mediante `UniversalCardEngine` y recorre sus efectos, combate, destinos físicos, vistas, eventos, consistencia y replay exacto.
- Corregido el contrato de `_validate_fuse_creatures()`: ya no devuelve la clave auxiliar `value`, que el motor rechazaba mediante `MODULE_DECISION_KEYS_INVALID`.
- La semilla fija 53927 reúne los seis materiales necesarios entre los seis primeros robos de cada jugador y evita búsquedas lentas durante la regresión.
- Dieciocho suites específicas PASS con 973; nueve generales con 441; diagnóstico 15/15; experimento 80/80; escena principal PASS.
- Auditoría estática PASS con 20.120 comprobaciones sobre 84 archivos GDScript.

## Juego de cartas propio 0.15.0 — tres Fusiones jugables — 2026-09-09

- Habilitadas F001-NAT y F067-AGU mediante el mismo ciclo de materiales, portador, equipo y destinos ya probado con F010.
- F001 concede +1 ATQ durante el primer combate de cada turno declarado por otra criatura propia; el disparo se consume al declarar y no mejora al propio Alfa.
- F067 abre una elección obligatoria de +1 ATQ o +1 DEF antes de su primer combate de cada turno, controlada por su propietario tanto al atacar como al defender.
- Si ambos combatientes requieren elección, decide primero el atacante y después el defensor; posteriormente se abre la ventana normal de respuestas con prioridad defensora.
- Los cuatro modificadores de combate quedan acotados y validados dentro del contexto pendiente y no filtran objetivos ocultos en la vista pública.
- Añadida la suite de efectos de Fusión con 40 comprobaciones; la suite de ciclo pasa a 58.
- Diecisiete suites específicas PASS con 952; nueve generales con 441; diagnóstico 15/15; experimento 80/80; escena principal PASS.
- Auditoría estática PASS con 19.850 comprobaciones sobre 83 archivos GDScript; fuentes locales PASS 6/6.

## Juego de cartas propio 0.14.0 — F010 jugable — 2026-09-09

- Añadida `fuse_creatures` como acción real durante las fases principales, con una Fusión normal por turno y sin coste universal de Energía.
- F010-NEU es la única receta habilitada: M04 y M09 forman Banda Goblin 3/3 en ataque o guardia y cuentan como recién llegados.
- Añadida la zona pública `fusion_materials`; una carta física porta la identidad generada y la segunda queda contenida sin crear cartas nuevas.
- Estadísticas, coste, taxonomía, anatomía y aptitudes de Banda Goblin alimentan vistas, combate, equipo y restricciones de cartas.
- Los equipos de ambos materiales se revalidan: los compatibles se religan y los incompatibles van al Cementerio.
- Destruir la Fusión envía ambos materiales y vínculos al Cementerio; devolverla a la mano recupera ambos materiales y destruye los vínculos.
- Añadida `activate_fusion_ability`: una vez por turno, Banda Goblin paga 1 de Energía para dar +1 ATQ temporal a una criatura propia visible.
- F001-NAT y F067-AGU permanecen en catálogo y son rechazadas expresamente dentro del duelo; cadenas y separación voluntaria siguen pendientes.
- Nueva suite F010 PASS con 56 comprobaciones; dieciséis suites específicas PASS con 910, nueve generales con 441, diagnóstico 15/15 y experimento 80/80.
- Auditoría estática PASS con 19.265 comprobaciones sobre 82 archivos GDScript; fuentes locales PASS 6/6.

## Primer catálogo real de Fusión — 2026-09-09

- Añadido `fusion_catalog.gd` como capa específica del juego sobre el servicio genérico.
- Registradas F001-NAT, F010-NEU y F067-AGU como primer corte controlado del catálogo.
- Los perfiles de material se construyen desde las definiciones e instancias reales de M01–M18.
- La búsqueda continúa siendo pura: no consume cartas, no ocupa casillas y no modifica el duelo.
- Añadida una suite específica para orden inverso, entidades generadas, materiales contenidos, visibilidad, propietarios, reutilización física y parejas sin receta.
- Suite de catálogo PASS con 37 comprobaciones; fundamento PASS con 46 e identidades PASS con 157.
- Las quince suites específicas suman 850 comprobaciones; las nueve generales, 441. Diagnóstico 15/15 y experimento integral 80/80.
- Auditoría estática PASS con 18.523 comprobaciones sobre 81 archivos GDScript.

## Juego de cartas propio 0.13.0 — 2026-09-09

- Asignados a M01–M18 los nombres de la primera baraja generalista de fantasía.
- Registradas las familias Lobo, Goblin, Elemental, Troll y Dragón, junto con sus superfamilias.
- Sustituida la anatomía `unassigned` por perfiles concretos Humanoide, Cuadrúpedo, Amorfo o Alado.
- Añadidas las aptitudes Bestial, Sapiente, Canalizador y Manipulador únicamente a las identidades que las justifican.
- Conservados costes, ATQ, DEF, elementos, efectos funcionales y el reparto previo de once Manipuladores.
- Endurecida la validación para rechazar criaturas jugables sin anatomía, sin familia o con etiquetas identitarias repetidas.
- Ampliada la suite de compatibilidad con nombres, reparto familiar y casos hostiles; ejecución runtime pendiente porque Godot no está disponible en `PATH`.
- Auditoría estática PASS con 18.107 comprobaciones.

## Compendio de criaturas y Fusiones — 2026-09-09

- Recuperadas y organizadas las 60 entradas del catálogo fantástico de S03.
- Indexadas las 125 recetas conceptuales de S04 y las treinta familias o grupos con cobertura.
- Creado un primer tomo detallado para Lobos, Goblins y Elementales.
- Aclarado que no existe Fusión por mera coincidencia de elemento o familia: toda combinación exige receta registrada.
- Aclarado el límite vigente: dos materiales por receta V0.1, sin coste adicional ni límite universal de Fusiones por turno.
- Retirada antes de cierre la candidata prematura que asignaba nombres a M04 y M09; no quedan cambios de contenido en el motor.

## Infraestructura de Fusiones — 2026-09-08

- Añadido un servicio puro y todavía desconectado del duelo para validar catálogos y buscar recetas de dos materiales.
- Implementadas recetas ordenadas o no ordenadas, prioridad por especificidad y rechazo de empates ambiguos.
- Exigidos materiales visibles del mismo controlador y cartas físicas no repetidas.
- Añadida una identidad generada canónica que conserva todas las cartas físicas originales de una cadena sin convertir las entidades intermedias en cartas.
- Preparada la liberación validada de materiales para la futura destrucción de una Fusión.
- No se añadió ninguna receta real ni se inventaron identidades o cifras pendientes en S01, S03 y S04.
- Añadida suite de fundamento de Fusiones con 46 comprobaciones; total específico actualizado a 752.

## Juego de cartas propio 0.12.0 — 2026-09-08

- Sustituidos los booleanos especiales de Manipulador por listas genéricas de aptitudes y requisitos.
- Añadidos perfiles anatómicos y requisitos anatómicos reutilizables, manteniendo `unassigned` mientras una criatura no tenga identidad concreta.
- Rechazada una escala numérica de inteligencia: Sapiente, Lector, Canalizador y Manipulador son capacidades independientes.
- Los vínculos de equipo se revalidan y un estado no puede conservar una pieza incompatible con su portador.
- Conservado sin cambios el reparto aprobado de once criaturas Manipuladoras y los requisitos de E01, E03 y E06.
- Añadida suite de compatibilidad con 96 comprobaciones; total específico actualizado a 706.

## Juego de cartas propio 0.11.0 — 2026-09-08

- Implementadas las seis recetas ordenadas iniciales de Terreno definidas en las fuentes de diseño.
- Jugar un segundo Terreno transforma el anterior cuando existe receta; de lo contrario, lo sustituye.
- La carta entrante conserva la nueva identidad en la única zona de Terreno y la anterior pasa al Cementerio, sin crear cartas físicas adicionales.
- Las formas transformadas publican identificador, nombre y componentes ordenados, y el estado valida que la carta portadora coincida con la receta.
- Los efectos mecánicos de las formas transformadas permanecen expresamente pospuestos y no heredan por accidente el bono del Terreno base.
- Añadida suite de combinaciones con 114 comprobaciones; total específico actualizado a 610.

## Juego de cartas propio 0.10.0 — 2026-09-08

- Implementada la activación de E04 mediante la acción canónica `relocate_equipment`.
- E04 traslada equipos entre criaturas propias visibles y compatibles, una vez por artefacto y turno.
- El traslado conserva los requisitos de Manipulador y es atómico cuando el objetivo no es válido.
- Un vínculo creado por E04 abre la misma ventana opcional de T05 que un equipo jugado desde la mano.
- Añadida suite de artefactos con 36 comprobaciones; total específico actualizado a 496.

## Juego de cartas propio 0.9.0 — 2026-09-08

- Ampliado `pending_response` con contextos validados de cambio de postura, equipo vinculado y destrucción en combate.
- Implementada T04 como reversión opcional de una transición enemiga voluntaria de guardia a ataque.
- Implementada T05 como destrucción opcional del equipo que el rival acaba de vincular.
- Implementada T06 como destrucción opcional del combatiente enemigo superviviente tras perder una criatura propia en combate.
- Conservadas la prioridad alterna, los dos pases, la cadena LIFO, la restricción del turno de preparación y la vista pública saneada.
- Añadida suite de disparadores con 53 comprobaciones; total específico actualizado a 460.

## Juego de cartas propio 0.8.0 — 2026-09-08

- Generalizada la ventana de respuestas mediante `pending_response` y contextos tipados de ataque o Magia.
- Conservadas prioridad alterna, dos pases, cadena LIFO, privacidad y consumo de respuestas en una sola infraestructura.
- Implementada T03 como negación opcional de G01–G03 antes de su resolución.
- Añadida suite de respuestas a Magias; total específico actualizado a 407 comprobaciones.

## Juego de cartas propio 0.7.0 — 2026-09-08

- Añadido el módulo independiente del segundo juego sin modificar Zápiti activo.
- Implementadas fases, energía, vida, barajas, zonas, privacidad, invocación, posturas y combate.
- Implementadas cartas de campo y primera capa de efectos G01–G07, T01–T02, E01–E06 y R01–R03 con las limitaciones documentadas.
- Añadida ventana opcional de respuestas a ataques, prioridad alterna, dos pases y cadena LIFO.
- Añadidas ocho suites con 377 comprobaciones; diagnóstico 15/15 y experimento integral 80/80.
- Creados cuatro cuadernos vivos y reglas obligatorias de continuidad en `AGENTS.md`.

## Complete Experimental — 2026-07-31

- Integradas las correcciones verificadas de UCE-02.
- Conservados B01, B02 y B03 como baseline acumulativa.
- Núcleo ampliado con validación de configuración/estado, deduplicación, acciones legales y digest.
- Añadidos jugadores, turnos, fases, puntuación, paths, condiciones y efectos.
- Añadidos constructor, consultas y operaciones de cartas.
- Añadidos persistencia, replay, almacenamiento atómico y sincronización.
- Añadidos catálogo de juegos y adaptador de bots.
- Añadido High Card Arena y demo ejecutable.
- Añadida suite completa experimental.

## Diagnostic Hardening — 2026-07-31

- Añadido bootstrap diagnóstico como escena principal.
- Añadido runner escalonado con checkpoints y reportes persistentes.
- Añadidos lanzadores Windows para diagnóstico y auditoría completa.
- Corregido request id fijo del adaptador de bots.
- Sustituido guardado JSON ordinario por codificación JSON tipada (schema v2).
- Endurecida máquina de fases: grafo cerrado, historial y entry_count.
- Endurecida validación integral de High Card Arena.
- Añadida propagación segura de errores de inicialización.
- Endurecida validación de paquetes de sincronización.
- Endurecida demo ante límite de acciones y fallo de guardado.
- Ampliada auditoría estática con escenas, scripts sin extends y marcadores de contexto dañado.

## Complete experiment — diagnostic hardening 3

- Added package SHA-256 verification before Godot execution.
- Added staged runtime diagnostics and external full-audit launcher.
- Added cross-file preload contract audit.
- Fixed bot request-id reuse.
- Added typed save encoding preserving integers/floats.
- Closed phase graph/history invariants.
- Hardened High Card Arena initialization and validation.
- Isolated validation/reduction action objects.
- Upgraded replay to compare complete runtime snapshots.
- Hardened save version/lifecycle and atomic file rollback reporting.
- Added mutation-hostile fixture and expanded integral tests.

## Foundation Hardening F01 — 2026-07-31

- `module_version()` pasa a ser obligatorio y estable durante la sesión.
- Añadidos `identifier_rules.gd`, `module_protocol.gd` y `runtime_snapshot.gd`.
- Endurecidos schemas de acciones, eventos, decisiones, transiciones y acciones legales.
- Reservado el namespace de eventos `engine_*` para el núcleo.
- Añadidos límites de datos puros por profundidad, nodos, colecciones y Strings.
- Commit de acciones convertido en validación de candidatura completa antes de mutación.
- Snapshot ampliado con schema/version e índice exacto de request ids.
- Añadida validación pública `validate_internal_consistency()`.
- Digest canónico actualizado con etiquetas explícitas de tipo.
- Catálogo de módulos endurecido con contrato e identidad/version congeladas.
- Save schema incrementado a v3 por el nuevo runtime snapshot.
- Añadida suite F01 con 49 checks y cinco fixtures hostiles.

## Systems Hardening F02–F05 — 2026-07-31

### F02 — Cartas y zonas

- Separada la visibilidad de identidad y de conteo.
- Añadida revelación parcial de bordes de pila sin IDs ocultos estables.
- Endurecidos mazos, instancias, metadatos y límites.
- Añadidos movimientos masivos, reordenación y reparto desigual atómicos.
- Añadido digest de inventario y conservación total de cartas.

### F03 — Sesión y flujo

- Endurecidos jugadores, equipos, asientos y metadatos públicos.
- Corregido el conteo de rondas cuando el jugador inicial no ocupa la silla cero.
- Añadida ancla explícita de ronda y retirada segura de jugadores.
- Cerrados y validados los grafos de fases, historial y conteos de entrada.
- Añadidos objetivos y liderazgo de puntuación explícitos.

### F04 — Persistencia y sincronización

- Save schema actualizado a v4 con JSON tipado y canónico.
- Alineados límites de codec y almacenamiento.
- Añadida validación de flotantes canónicos.
- Endurecidas rutas, commit, backup, recuperación y rollback.
- Replay ampliado al snapshot completo y primera diferencia estructural.
- Sync schema v2 con viewer válido, identidad/version y digests.

### F05 — Interfaces y bots

- Movido el contrato de acciones legales desde IA al núcleo.
- Añadida validación opcional de viewer en el protocolo del motor.
- Rechazados viewers desconocidos en High Card Arena y sincronización.
- Bots obligados a seleccionar exactamente una acción canónica.
- Añadidas políticas hostiles para acciones inventadas, malformadas y mutación.
- Corregida la divergencia entre ronda genérica y ronda del juego demostrador.
- Endurecidas privacidad, zonas, orden de jugadores actuados y finales de partida.
- Corregida una declaración local duplicada en la suite integral experimental.
- Ampliado el diagnóstico y el launcher Windows con F02–F05.
