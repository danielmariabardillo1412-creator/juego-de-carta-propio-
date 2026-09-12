# Cuaderno 3 — Bitácora de trabajo

## 2026-09-12 — Benchmark comunitario y foros de UX

- El diseñador pidió ampliar el benchmark con feedback de jugadores reales, buscando mejoras de interfaz y calidad de vida que un proyecto pequeño pueda implementar. Se excluyen como requisito de esta fase las peticiones de grandes animaciones 3D, monstruos que salgan de la carta, escenarios reconstruidos por VFX o producción equivalente a un equipo de animación.
- Se revisaron discusiones de Reddit, Steam Community y BoardGameGeek alrededor de Master Duel, Hearthstone, MTG Arena y deckbuilders digitales, priorizando patrones repetidos sobre comentarios aislados.
- Se creó `docs/diseno/CUADERNO_BENCHMARK_COMUNIDAD_Y_FOROS_V0_1.md` y se registró JCP-DEC-042. El documento clasifica cada idea por valor, coste técnico y fase recomendada.
- Las propuestas comunitarias de mejor relación valor/trabajo son: consultar efectos activos con fuente y duración; texto de carta estructurado y cláusula actual resaltada; usos restantes visibles; menos ventanas cuando no hay una elección real; poder inspeccionar el tablero durante una decisión; y cancelar/reseleccionar libremente antes del punto de commit.
- La propuesta `¿por qué no puedo?` se conserva como dirección de alto valor, pero no se implementará copiando reglas en la UI: requerirá una consulta no mutante de UCE o reutilizar los mismos códigos de validación del motor.
- Se reafirma que una acción puede corregirse mientras solo existe selección local; después de enviarse a `UniversalCardEngine.perform_action()` no se ofrece undo ordinario, porque podría romper privacidad, replay, determinismo y futuro multijugador.
- Las animaciones futuras se plantean como feedback 2D corto, opcional y prescindible para entender la regla. Se reserva desde el diseño una opción de reducción de movimiento/velocidad, sin depender de cinemáticas.
- La segunda pasada del benchmark comercial añadió además Hearthstone, GWENT, Duel Links y Pokémon TCG Pocket, y corrigió la geometría de la casilla de criatura para que una carta 63:88 pueda rotar a Guardia sin invadir la vecina.
- No se modificó código, motor, catálogo, reglas, replay ni persistencia. No corresponde ejecutar ni atribuir nuevos resultados runtime; el último PASS cerrado continúa siendo el del 2026-09-11.

## 2026-09-12 — Cuaderno de benchmark de interfaces TCG

- Antes de seguir afinando la mesa por ensayo visual, el diseñador pidió reunir primero en un único cuaderno las soluciones maduras de otros juegos de cartas y usar esa base para evitar decenas de correcciones ya resueltas por la industria.
- Se creó `docs/diseno/CUADERNO_BENCHMARK_INTERFAZ_TCG_V0_1.md` y se registró JCP-DEC-041.
- La investigación no se limita a Yu-Gi-Oh! y Magic. Se documentaron piezas aprovechables de Yu-Gi-Oh!, MTG Arena, Legends of Runeterra, Shadowverse, Pokémon TCG/TCG Live, Marvel Snap, Flesh and Blood, Disney Lorcana, Shadowverse: Evolve y Eternal; Hearthstone, Gwent, Duel Links, Pokémon TCG Pocket y otros quedan anotados para una segunda pasada si aportan una solución mejor.
- El método queda fijado como benchmark modular: elegir de cada producto únicamente el problema que resuelve especialmente bien —campo, orientación, mano, selección, respuestas, cadena, adjuntos, Fusión, turno o lectura— y reconstruirlo con identidad propia. No se copian assets, marcos, iconos, ornamentación ni una interfaz completa.
- El cuaderno propone como candidato de proporción base 63:88 y una unidad común `U` derivada del ancho de carta. Para 1600×900 se anota una primera escala de trabajo de 72×101 px en campo, 101×72 en guardia, ~86×120 en mano y ~180×251 en preview; son medidas de síntesis pendientes de consolidación, no valores definitivos de código.
- También quedan recogidas las ideas de cartas jugables resaltadas, carta→destino, equipo unido al portador, Fusión como entidad única con materiales inspeccionables, mini-cadena temporal de respuestas, fase/energía/fin de turno de lectura inmediata y una posible previsión `si se resolviera ahora` calculada solo con información pública por el motor.
- La implementación greybox V0.1 ya escrita se mantiene en la rama como andamio, pero no se seguirá puliendo a ojo. El siguiente corte visual debe derivarse de la síntesis del nuevo cuaderno y después pasar las puertas runtime ya previstas.
- No se modificó código, motor, reglas, catálogo, replay ni persistencia en esta revisión documental; por tanto no corresponde atribuir nuevos resultados runtime.

## 2026-09-12 — Greybox representativo de interfaz final V0.1

- El diseñador detuvo la sesión humana completa porque la mesa anterior, aunque funcional y probada, seguía siendo demasiado cercana a una herramienta de laboratorio para medir con sentido la experiencia que se pretende conservar. Se fija que las pruebas humanas de claridad, comodidad y ritmo comenzarán después de disponer de un greybox representativo de la distribución final, todavía sin arte definitivo.
- Se creó `docs/diseno/GREYBOX_INTERFAZ_FINAL_V0_1.md` y se registró JCP-DEC-040. La referencia a juegos comerciales sirve solo para jerarquía visual y lenguaje espacial; no se copian identidad gráfica, assets ni reglas ajenas.
- Trabajo aislado en la rama `chatgpt/greybox-ui-v1`. `demo/juego_cartas_table_greybox.gd` hereda la mesa actual para reutilizar intacta toda su lógica, acciones, privacidad, IA, guardado/carga y flujo; únicamente sustituye construcción y jerarquía visual. `demo/juego_cartas_table.tscn` apunta a esta capa dentro de la rama.
- Se añadió `demo/duel_table_backdrop_greybox.gd`: fondo casi cenital con dos territorios, eje limpio y guías de filas discretas en vez de una cuadrícula técnica dominante.
- El HUD superior conserva solo controles de partida; la banda de seis fases sale del centro jugable y pasa al borde superior del tablero. Vida y Energía continúan integradas en las cabeceras de ambos jugadores.
- El lateral queda como apoyo contextual: ficha ampliada, decisiones y acciones excepcionales. Guardado/carga, historial y herramientas locales 2P se conservan pero se subordinan visualmente. No se elimina funcionalidad de diagnóstico necesaria para pruebas.
- Las casillas vacías mantienen silueta y códigos C1–C5/A1–A5, pero dejan de repetir `VACÍA`. Cuando una casilla es un destino legal sigue mostrando `JUGAR AQUÍ` o `ATAQUE DIRECTO`, conservando además el contrato esperado por las pruebas existentes.
- No se modificaron `UniversalCardEngine`, `juego_cartas_propio_module.gd`, catálogo, reglas, replay ni persistencia. El módulo continúa en `0.24.0-stress-hardening`.
- **Verificación pendiente:** desde esta conexión no existe acceso al Godot 4.7 local ni a la ejecución gráfica del PC. La fase no se declara PASS. Deben ejecutarse parser/runtime, mesa manual, flujo de ataque, IA básica y las regresiones verticales proporcionales; después se revisará una captura real antes de iniciar la partida humana completa.

## 2026-09-11 — Rediseño 2,5D de mesa y corrección del ataque visual

- Tras revisar de nuevo las referencias aportadas por el diseñador se retiraron las dos grandes cajas planas. El tablero es ahora un trapecio original en perspectiva, pero la profundidad no altera la escala de juego: cartas, casillas y zonas laterales de ambos jugadores tienen idéntico tamaño. Ambas manos aparecen completas y en fila recta. Las casillas tienen silueta de carta; se conservan marco provisional, reverso, color semántico y ficha ampliada lateral a 1600×900.
- Se eliminó el emblema decorativo central. Una línea sencilla separa ambos territorios y Territorio, materiales de Fusión, Baraja y Cementerio ocupan casillas laterales independientes y enfrentadas.
- La perspectiva profunda tipo pista se corrigió a una cámara casi cenital: trapecio muy leve, líneas casi paralelas y banda de fases sobre la separación central. Las piezas siguen frontales y a escala idéntica.
- Se corrigió el flujo confuso de ataque: un clic sobre el rival antes de Combate ya no pierde al atacante, el mensaje conduce a `IR A COMBATE`, los objetivos legales se resaltan y la Vida rival actúa como destino cuando corresponde un ataque directo.
- Las criaturas ocultas se atacan mediante identificador público de casilla, sin filtrar su identidad. Se corrigió además una lectura secundaria de equipo para que la nueva representación oculta no provoque errores de runtime.
- La guía contextual diferencia equipo dirigido, Magia instantánea, Magia persistente, Trampa preparada, Terreno y criatura para que una casilla de Apoyo no parezca un destino universal.
- Puerta proporcional limpia: mesa 78/78 —incluidas igualdad exacta de escala, proporción de casillas, zonas laterales separadas y guía de los cuatro contratos de apoyo—, flujo de ataque 11/11, IA 9/9, criaturas 38/38, ocho Fusiones 82/82, escena headless PASS, fuentes 6/6, tres capturas 1600×900 PASS y auditoría estática 26.333/26.333 sobre 97 GDScript.

## 2026-09-11 — Flujo visual aprobado y mesa preparada para prueba humana

- El diseñador aprobó las cinco decisiones de `FLUJO_DE_PARTIDA_E_INTERACCION_V0_1.md` y confirmó que elegir una casilla es preferencia visual, no táctica.
- Inicio y Robo ordinarios pasan automáticamente antes de la primera decisión. La mesa añade banda de seis fases, controles explícitos de Combate y terminar turno con confirmación, y apertura automática del turno siguiente.
- El lateral deja de duplicar cartas, objetivos y cambios de fase. Las cartas comunes se juegan sobre casillas/objetivos; dos criaturas compatibles abren directamente la elección de Fusión; el historial comienza plegado.
- Se añadieron marcos provisionales por tipo y elemento, pilas auxiliares visibles, equipo rotulado bajo el portador y previsualización diferenciada para transformaciones o sustituciones de Terreno. La referencia a Yu-Gi-Oh/Magic se limita a legibilidad de mesa y no copia identidad visual.
- Se actualizó la captura reproducible para el comienzo automático. Puertas ejecutadas: mesa 70/70 —incluida transformación de Terreno desde la mesa—, IA 9/9, criaturas 38/38, ocho Fusiones 82/82, escena headless PASS, render 1280×720 PASS y auditoría estática 25.703/25.703.
- Se regeneró el acceso directo del escritorio contra la escena y proyecto vigentes de F. Siguiente fase: partida humana completa y corrección de problemas reproducibles de uso.

## 2026-09-11 — Pausa de implementación y contrato de interacción V0.1

- Tras comprobar la mesa, el diseñador pidió detener los retoques sucesivos y reconstruir primero cómo debe jugarse desde los datos existentes.
- Se verificaron S00 y S01 en Drive: ID y fecha de modificación coinciden exactamente con `SOURCE_MANIFEST.json`; la caché local sigue íntegra 6/6.
- Los papeles confirman cinco espacios de criaturas y cinco de apoyo, pero descartan movimiento táctico por casillas: los huecos son visuales y equivalentes.
- También confirman una invocación normal por turno, varias acciones legales en cada fase principal, Magias/Trampas sin Energía, equipo/Terrenos gratuitos por defecto y seis fases reglamentarias.
- Se creó `docs/diseno/FLUJO_DE_PARTIDA_E_INTERACCION_V0_1.md`, marcado como borrador sin autorización de código. Define mesa, comienzo automático, fases, interacción por tipo de carta, ataque, respuestas, IA, lateral y cinco decisiones pendientes.
- No se modificó código en esta revisión documental.

## 2026-09-11 — Interacción directa, fases legibles y rival automático

- Una segunda prueba humana mostró tres fallos de uso: las cartas se jugaban desde una lista lateral, el cambio de fase no explicaba cuándo terminaba el turno y el Jugador 2 exigía relevar físicamente la vista aunque no hubiera otra persona.
- La interacción normal pasa a carta → casilla. Las criaturas ofrecen antes de entrar las acciones legales de ataque visible o guardia oculta; apoyos persistentes/ocultos y Terrenos se colocan desde sus zonas, y Magias u objetos dirigidos aceptan pulsar la criatura objetivo. Las casillas compatibles muestran `JUGAR AQUÍ`.
- La casilla visual elegida se conserva durante la sesión aunque las zonas compactas del motor sean mecánicamente equivalentes. Fusiones y selecciones múltiples continúan disponibles en el panel lateral hasta diseñar una interacción dedicada.
- El botón principal indica `Comenzar robo`, `Ir a Principal 1`, `Ir a Combate`, `Ir a Principal 2`, `Ir a Final` o `Terminar turno`; no se modificó la estructura reglamentaria de seis fases ni el permiso de ejecutar varias acciones legales en una fase principal.
- Se añadió un rival automático básico, activado por defecto en modo gráfico. Juega mediante `get_legal_actions()` y `perform_action()`, conserva al humano como Jugador 1 y solo le devuelve prioridad cuando corresponde una respuesta real. Desactivarlo recupera el modo local de dos personas con cortina.
- Una captura del uso real reveló que pulsar dos veces la misma carta cancelaba la selección sin una señal suficientemente visible y que el lateral seguía dominando la interacción. La selección ya no se cancela al repetir el clic; sin carta, el lateral oculta jugadas de mano, y con carta solo conserva decisiones generales o complejas. Las casillas compatibles muestran una instrucción amarilla inequívoca.
- La elección posterior a la casilla dejó también el lateral: ahora aparece como ventana central sobre el tablero y distingue expresamente `ATAQUE · Visible` de `GUARDIA · Oculta`.
- Pruebas: mesa directa 65/65 —ahora emite las señales reales de la carta, la quinta casilla y la elección central—, nueva suite de IA 9/9, vertical de criaturas 38/38, vertical de ocho Fusiones 82/82, arranque principal PASS y auditoría estática 25.392/95. El módulo permanece en `0.24.0-stress-hardening` porque no cambiaron reglas.
- El acceso directo del escritorio se regeneró después de detectar que no se había actualizado con la mesa. Ahora nombra explícitamente `res://demo/juego_cartas_table.tscn`, conserva como raíz el proyecto vigente de F y su mantenimiento queda añadido al protocolo obligatorio de entrega.
- Tras corregir la selección se volvió a regenerar el acceso directo a las 19:51; su descripción identifica selección directa, casillas resaltadas y rival IA.

## 2026-09-11 — Primera mesa visual de duelo

- La primera observación humana mostró que la mesa era técnicamente operable, pero se leía como un panel de diagnóstico y no permitía reconocer de un vistazo dónde estaba cada carta.
- Se sustituyeron los dos resúmenes apilados por una mesa simétrica: rival arriba, jugador abajo, cinco casillas de criaturas y cinco de apoyos siempre visibles por lado, y Territorios enfrentados en el centro con estado `VACÍO` explícito.
- Vida y Energía se muestran junto a cada jugador; baraja, Cementerio, equipos y materiales quedan como recuentos espaciales del campo. La mano rival conserva reversos sin identidad y las manos largas disponen de desplazamiento horizontal.
- El panel lateral conserva acciones legales, selección, detalle, guardado/carga y últimos sucesos. El motor, las reglas, la privacidad y la persistencia no cambiaron.
- `card_tile.gd` recibió un aspecto provisional de carta y selección. Se añadió `tools/capture_manual_table.gd` para inspecciones repetibles a 1280×720 y se guardó la vista revisada en `artifacts/manual_table_preview.png`.
- Verificación proporcional de esa primera iteración: mesa 59/59, vertical de criaturas 38/38, vertical de ocho Fusiones 82/82, escena principal headless PASS y auditoría estática 24.879/94. Caché de fuentes 6/6. El módulo conservó `0.24.0-stress-hardening`.

## 2026-09-11 — Endurecimiento por 12.135 partidas automáticas 0.24.0

- Se añadieron `run_jcp_rule_stress.gd` y `run_jcp_stress_matches.gd`, ambos reproducibles por semilla y con informes independientes por lote.
- El primer piloto detectó que Principal 2 anunciaba cambio de postura para una criatura que acababa de atacar; la validación lo rechazaba. Se añadió el mismo filtro a acciones legales y una regresión de recorrido completo.
- El segundo piloto detectó que el catálogo podía reconstruir una receta a partir de la identidad física portadora de una Fusión anterior. Las Fusiones encadenadas siguen deshabilitadas y ahora tampoco se anuncian como legales.
- Después de corregirlos se completó una primera puerta de 2.110 partidas y 137.300 acciones.
- El run duradero `long_20260911_073150` añadió 10.000 partidas rápidas y 25 mediante UCE: 907.265 acciones, 4.323 Fusiones, 37.057 ataques, 13.322 respuestas activadas, 55 derrotas por baraja vacía y 470 empates simultáneos válidos. Sus ocho lotes y la muestra UCE terminaron en PASS.
- El coordinador marcó inicialmente un falso `FAIL` porque comprobaba el código del wrapper `*_console.exe` en lugar del JSON del proceso hijo. Se corrigió la autoridad de cierre y se regeneró el estado agregado como PASS.
- Acumulado posterior a correcciones: 12.135 partidas y 1.044.565 acciones limpias. Cierre completo: 22 suites específicas 1.357/1.357; UCE 441/441; diagnóstico 15/15; experimento 80/80; escena principal PASS; auditoría estática 24.709/93; fuentes 6/6. Integridad histórica: 100 comprobados, cero ausentes, siete diferencias conocidas y cero errores.
- Versión vigente: `0.24.0-stress-hardening`.

## 2026-09-11 — Corrección de ataque al invocar 0.23.0

- La auditoría posterior encontró que S01 permite atacar durante el turno de una invocación normal boca arriba, pero el motor y el resumen vigente aplicaban una prohibición general.
- Acciones legales y validación permiten ahora ese ataque. Se mantiene la excepción del primer turno para el jugador inicial y la prohibición de ataque inmediato para una Fusión recién formada.
- Invocación pasa de 16 a 32 comprobaciones. Dos suites que construían combates artificiales se marcaron como ronda posterior para no confundirlos con el primer turno real.
- Cierre repetido desde cero: 22 suites específicas 1.341/1.341; UCE 441/441; diagnóstico 15/15; experimento 80/80; escena principal PASS. Tras añadir la sonda no mutante de equilibrio, auditoría estática final 23.969/91.
- Versión vigente: `0.23.0-summon-attack`.
- Se creó `AUDITORIA_TRAZABILIDAD_REGLAS_BASICAS_S01_V0_1.md`: separa reglas cerradas verificadas de decisiones abiertas y enlaza cada bloque del núcleo con sus suites.
- La sonda `run_jcp_balance_probe.gd` mide el catálogo runtime sin duplicar cifras manualmente. F001 cambia un 16,98 % de umbrales básicos y F067 confirma potencia bruta y riesgo de bloqueo; la auditoría métrica conserva ambas cartas sin cambios hasta disponer de partidas.

## 2026-09-11 — Cierre de derrota por baraja agotada 0.22.0

- La revisión posterior a la mesa completa detectó que el motor rechazaba el avance cuando debía robar de una baraja vacía y dejaba la partida sin desenlace.
- S01 contiene dos formulaciones inequívocas de la regla cerrada: el jugador que debe robar sin cartas en su mazo pierde.
- El avance a Robo comprueba ahora la baraja antes de extraer: declara al rival ganador, entra en `FINISHED`, registra `deck_empty` y emite `player_deck_exhausted`.
- La suite de fases recorre 40 cartas por jugador y reproduce el historial completo; pasa 48/48. Las 22 suites específicas pasan 1.325/1.325, UCE 441/441, diagnóstico 15/15, experimento 80/80, escena principal PASS y auditoría estática 23.779/90.
- La semántica de replay cambia y los guardados de 0.21 no deben mezclarse; la versión vigente es `0.22.0-deck-exhaustion`.

## 2026-09-11 — Mesa manual local y cierre de privacidad

- Se añadió `demo/juego_cartas_table.tscn` como escena principal y `juego_cartas_table.gd` como cliente local de UCE. Presenta ambos lados, recuento de baraja, mano privada, zonas, vida, Energía, fase, prioridad, acciones legales y últimos eventos visibles.
- `card_tile.gd` aporta componentes reutilizables para cartas y casillas. Al seleccionar una carta, se destaca y sus acciones legales aparecen primero; las zonas vacías se compactan para mantener ambos campos visibles a 1280×720.
- Las acciones que solo varían por objetivo, postura o elección se agrupan. Un primer botón abre las opciones y solo la confirmación envía la acción exacta a UCE. La selección reconoce también Trampas y objetivos representados mediante casillas.
- La mesa sigue automáticamente la prioridad y activa una cortina en cada relevo; mientras está oculta no permite ejecutar acciones. Puede alternarse la vista manualmente y reiniciar con una semilla editable.
- La inspección visual determinista a 1280×720 confirmó que cabecera, tablero, acciones y registro son legibles; la longitud del tablero usa desplazamiento en lugar de recortar información.
- Al conectar el registro se detectó que los eventos públicos de M13 conservaban el identificador del objetivo original oculto. Se sustituyó por su casilla y se añadieron dos regresiones de no filtración; la suite activa pasa a 39/39.
- La nueva suite de mesa supera 37/37 y recorre Inicio, Robo, Principal 1 e invocación, además de vistas, componentes, selección, agrupación, relaciones por casilla, controles legales, relevo, cortina y reinicio. Una comparación heterogénea detectada por la prueba se corrigió con comprobación explícita de tipos.
- Se añadió ficha mecánica de carta, resultado con ganador y motivo, y una ranura local con escritura atómica, checksum y carga mediante replay exacto. Una carga protege la vista con la cortina.
- La suite de mesa sube a 55/55 e incluye guardado/carga, rendición y un recorrido completo por combate hasta vida cero. Cierre completo: 22 suites específicas 1.316/1.316; UCE 441/441; diagnóstico 15/15; experimento 80/80; escena principal PASS; auditoría estática 23.709/90; fuentes 6/6. Manifiesto histórico sin regenerar: cero ausentes, siete diferencias conocidas y cero errores.
- El módulo conserva `0.21.0-creature-abilities`: la interfaz reutiliza reglas, guardado y replay universales. Siguiente fase: sesión humana de comodidad y, después, equilibrio, contenido, comentalista textual y arte.
- Se reserva para después de esa base el comentalista textual basado en eventos y las transformaciones explícitas de Terreno por Magias, Trampas, objetos, criaturas o Fusiones. Los ejemplos narrativos aportados quedan documentados como inspiración, no como reglas ya aprobadas.

## 2026-09-11 — Habilidades de criaturas M01–M18 — fase cerrada 0.21.0

- Tras el parón se comprobó que el código y las dos suites directas estaban guardados; solo faltaba terminar el recorrido vertical. La búsqueda dinámica de semillas se sustituyó por semillas deterministas documentadas para evitar bloqueos innecesarios.
- S01 y S03 se comprobaron en Drive y mantienen exactamente las fechas del manifiesto; caché local 6/6.
- Integradas M05, M06, M07, M10, M16 y M18 como habilidades automáticas; M09 como acción pagada; M12 como inspección privada; M15 como entrada con objetivo condicionado; y M13 como decisión de redirección anterior a trampas.
- Las ocho criaturas restantes conservan «sin habilidad». Una identidad de Fusión suprime la habilidad base de su portador y limpia los marcadores individuales al formarse.
- La consulta vertical de eventos privados tenía invertidos `after_sequence` y `viewer_id`; se corrigió la prueba. También se añadió una regresión que demuestra que, tras redirigir con M13, la ventana normal de trampas apunta al guardián.
- Cierre: 21 suites específicas 1.259/1.259; habilidades automáticas 25, activas 37 y verticales 38. Nueve suites UCE 441/441; diagnóstico 15/15; experimento 80/80; escena principal headless PASS. Auditoría estática 22.462/87 archivos, fuentes 6/6. Manifiesto histórico: cero ausentes y siete diferencias conocidas; no se regeneró.
- Próxima fase: mesa mínima para partidas manuales, presentando acciones legales, elecciones y privacidad antes de abordar arte definitivo, locutor o integración con Zapity.

## 2026-09-10 — F005 Dragón Bicéfalo Elemental — fase cerrada 0.20.0

- Trabajo realizado únicamente en el laboratorio de F; Zapity principal y las copias históricas no se han modificado.
- S01 y S04 comprobadas en Drive: fechas idénticas al manifiesto. Caché local 6/6.
- Añadida la octava receta, M17 + M18, con nombre conservado, coste 8 y cifras 8/8. Perfil provisional explícito y semántica de ataque en JCP-DEC-031.
- El permiso de segundo ataque se concede una sola vez por turno después de una destrucción real con supervivencia. No borra el ataque realizado; se consume al declarar, expira por turno y se limpia al salir del campo.
- Pruebas nuevas de receta inversa, cifras, acciones legales, mareo de entrada, tercer ataque rechazado, igualdad, destrucción mutua, regeneración de Troll, cancelación G07, prioridad T06, limpieza, expiración y metadatos corruptos.
- El recorrido vertical formó F005 legalmente, ejecutó ambos ataques y reconstruyó el replay exacto. Se corrigió una expectativa de prueba que omitía `base_attack` y `base_defense` de la vista pública. La batería completa se repitió tras esa corrección y terminó sin fallos.
- Cierre: 18 suites específicas 1159/1159; catálogo 59, acción 70, combate de Fusiones 131 y vertical 82. Nueve suites UCE 441/441; diagnóstico 15/15; experimento 80/80; escena principal headless PASS. Auditoría estática 21.328/84 archivos, fuentes 6/6. Manifiesto histórico: cero ausentes y siete diferencias conocidas; no se regeneró.
- Archivos de código: `fusion_catalog.gd`, `juego_cartas_propio_module.gd` y suites de catálogo, efectos de combate y recorrido vertical. Actualizados los cuatro cuadernos, fuente única, README, changelog, descripción del juego, baraja inicial y libro de Dragones.
- No se considera implementada la habilidad individual de M18. Siguiente fase: auditar cobertura de habilidades M01–M18 antes de ampliar contenido o arte.

## 2026-09-10 — Comprobación de continuidad tras el traslado

- Confirmados ambos proyectos en F, la ausencia del antiguo laboratorio en C y el destino de `active` hacia el Zapity principal de F.
- Corregida en `01_ESTADO_ACTUAL.md` la cifra de auditoría estática que seguía en 20.774: la comprobación actual devuelve 21.036, sin fallos. Caché de fuentes: 6/6.
- Añadida una indicación de rutas en `C:/Users/danie/OneDrive/Documentos/ChatGPT/zapity/AGENTS.md`, porque esta tarea todavía abre ese directorio vacío de código.
- No hay una fase de código abierta: se mantiene 0.19.0 con siete Fusiones y F005 como siguiente fase. No se repitieron las pruebas runtime del traslado al no cambiar código.

## 2026-09-10 — Reubicación verificada en F

- El Zapity principal recuperado desde el antiguo disco E se trasladó dentro del mismo volumen a `F:/Taller de Juegos Zapity/zapity`.
- El laboratorio independiente se copió y verificó archivo por archivo en `F:/Taller de Juegos Zapity/juego_cartas_propio`; sus 172 archivos conservaron tamaño y SHA-256 exactos antes de retirar la copia de OneDrive.
- Las dieciocho suites específicas se ejecutaron desde la nueva ruta y conservaron 1102/1102; la escena principal de Zapity abrió en Godot 4.7 desde su nueva ubicación.
- El acceso `Documentos/zapity/active`, antes dirigido a `E:/zapity dev`, se reorientó al Zapity principal de F.

## 2026-09-10 — F018 Troll Bicéfalo y cierre posterior a la recuperación

- El módulo avanza a `0.19.0-seven-fusions`; dos Trolls Neutrales de definiciones distintas entre M11, M13 y M16 forman F018-NEU, Integración 6/6 de coste de referencia 6.
- La primera destrucción de combate que sufriría cada turno queda reemplazada y F018 pasa a guardia. El uso solo se consume al prevenir una destrucción real y la postura forzada no se trata como cambio voluntario.
- Si F018 destruye al rival y sobrevive por regeneración, el propietario rival puede resolver T06 después y destruirlo; la prevención no se extiende a efectos.
- Se añadieron validación de metadatos, evento público, pruebas de límite por turno, receta distinta, interacción con T06 y un quinto recorrido vertical con replay exacto.
- Catálogo 50/50, acción 70/70, efectos de combate 94/94 y vertical de siete Fusiones 71/71.
- Dieciocho suites específicas: 1102/1102; nueve generales: 441/441; diagnóstico 15/15; experimento 80/80; escena principal headless PASS.
- Auditoría estática: PASS, 21.036 comprobaciones sobre 84 archivos GDScript. Fuentes locales: PASS 6/6.

## 2026-09-10 — Recuperación tras reinicios y cierre de F068

- Se localizaron dos raíces: `Documentos/ChatGPT/zapity` contiene solo un repositorio vacío, mientras el proyecto real permanece intacto en `Documentos/zapity/juego_cartas_propio/engine`.
- El disco conservaba una fase interrumpida: código `0.18.0-six-fusions` y F068 escritos, pero cuadernos todavía en 0.17.0.
- F068-FA registra Elemental de Fuego + Elemental de Agua como Integración 2/4. Su acción elige un enemigo boca arriba cuando existe y aplica −1 ATQ hasta cerrar el siguiente turno de ese controlador.
- La duración se conserva mediante un final de turno pendiente del propietario, se limpia al abandonar el campo y publica eventos de aplicación y expiración.
- La vertical de F068 contenía una expectativa desplazada: desde Combate faltaban tres avances, no cuatro, para cambiar de turno. El motor rechazaba correctamente el cuarto con `JCP_WRONG_ACTOR`; la prueba fue corregida.
- Catálogo 45/45, acción 67/67, efectos de combate y duración 77/77, vertical de seis Fusiones 59/59.
- Dieciocho suites específicas: 1065/1065; nueve generales: 441/441; diagnóstico 15/15; experimento 80/80; escena principal headless PASS.
- Auditoría estática: PASS, 20.774 comprobaciones sobre 84 archivos GDScript. Fuentes locales: PASS 6/6.

## 2026-09-10 — F012 Cuadrilla del Matorral jugable y vertical

- El módulo avanza a `0.17.0-five-fusions`; F012-NN registra Goblin Neutral + Goblin de Naturaleza, sin orden, como Formación 2/4 de coste de referencia 3.
- La primera vez por turno global que es atacada resta 1 ATQ al atacante durante ese combate y consume el uso en la declaración. El contexto admite ahora `attacker_attack_delta` entre −5 y +5.
- El portador limpia los marcadores de habilidades de Fusiones anteriores al generar una entidad nueva.
- Catálogo 42/42, acción 64/64 y efectos de combate 62/62. La vertical usa semilla 550, respeta coste y mareo de invocación y reconstruye exactamente el replay de F012.
- La suite vertical pasa a 47/47; las dieciocho suites específicas suman 1032/1032. Nueve generales: 441/441; diagnóstico 15/15; experimento 80/80; escena principal headless PASS.
- Auditoría estática: PASS, 20.509 comprobaciones sobre 84 archivos GDScript. Fuentes locales: PASS 6/6.
- La suite vertical se renombra a `run_juego_cartas_propio_fusions_vertical.gd` porque ya no representa solo el primer trío.

## 2026-09-10 — F011 completa la puerta vertical

- La suite vertical existente incorpora una segunda partida determinista con semilla 243: M09 comienza en mano y M05/M04 llegan mediante robos normales.
- F011 se forma y espera su turno de entrada, aparece en la vista pública, combate como 4/3 junto a otro Goblin visible, sobrevive por igualdad y destruye a M12.
- El registro contiene `fusion_torch_band_triggered`, la consistencia interna pasa y `ReplayService` reconstruye exactamente el snapshot runtime.
- La suite vertical pasa de 21 a 34 comprobaciones. Las dieciocho suites específicas suman 1003/1003; nueve generales 441/441; diagnóstico 15/15; experimento 80/80; escena principal headless PASS.
- Auditoría estática: PASS, 20.340 comprobaciones sobre 84 archivos GDScript. Fuentes locales: PASS 6/6.

## 2026-09-09 — F011 Banda de Antorchas jugable

- El módulo avanza a `0.16.0-four-fusions` y el catálogo registra F011-NF: Goblin Neutral + Goblin de Fuego, sin orden.
- Banda de Antorchas es una Formación Goblin Neutral/Fuego 3/2 de coste de referencia 3, Humanoide, Sapiente y Manipuladora.
- Al atacar recibe +1 ATQ durante ese combate; recibe también +1 DEF si controla otro Goblin boca arriba. El requisito visible evita filtrar la identidad de criaturas colocadas.
- El efecto reutiliza los modificadores acotados del contexto de combate y emite `fusion_torch_band_triggered` antes de respuestas.
- Catálogo 39/39, acción 61/61 y efectos de combate 52/52. Las dieciocho suites específicas suman 990/990; nueve generales 441/441; diagnóstico 15/15; experimento 80/80; escena principal headless PASS.
- Auditoría estática: PASS, 20.238 comprobaciones sobre 84 archivos GDScript.

## 2026-09-09 — Prueba vertical del primer trío

- El módulo avanza a `0.15.1-three-fusions-vertical`.
- Se añadió la suite vertical, hoy llamada `run_juego_cartas_propio_fusions_vertical.gd`, que usa `UniversalCardEngine` y una semilla fija para jugar las tres Fusiones dentro de una única secuencia natural.
- La secuencia cubre robo, invocación, límite de Fusión, habilidad de F010, liderazgo de F001, elección defensiva de F067, combate, destrucción de F010, materiales en Cementerio, vistas públicas, eventos, consistencia interna y replay exacto.
- La primera ejecución descubrió que `_validate_fuse_creatures()` devolvía una clave auxiliar `value`; el motor rechazaba correctamente esa forma con `MODULE_DECISION_KEYS_INVALID`. El validador devuelve ahora exclusivamente `ok`, `code` y `message`.
- La suite vertical supera 21/21. Las dieciocho suites específicas suman 973/973; nueve generales 441/441; diagnóstico 15/15; experimento 80/80; escena principal headless PASS.
- Auditoría estática: PASS, 20.120 comprobaciones sobre 84 archivos GDScript.

## 2026-09-09 — F001 y F067 completan el primer trío jugable

- Fuentes consultadas: S01, S02, S03 y S04; caché local PASS 6/6 y frescura ya contrastada en esta sesión.
- El módulo avanza a `0.15.0-three-fusions` y habilita F001-NAT, F010-NEU y F067-AGU mediante el mismo ciclo físico.
- F001 dispara +1 ATQ durante el primer combate declarado por otra criatura propia en cada turno de su controlador. El uso se consume en la declaración, incluso si después se cancela el combate.
- F067 abre una elección obligatoria de +1 ATQ o +1 DEF antes de su primer combate de cada turno. El controlador decide tanto al atacar como al defender; si ambos lados debieran elegir, el orden es atacante y después defensor.
- Una vez cerradas las elecciones de F067 se abre la ventana normal de respuestas con prioridad del defensor. Se verificó expresamente la continuidad hacia G06.
- El contexto pendiente conserva cuatro modificadores delimitados —ATQ/DEF de atacante y objetivo— sin convertirlos en bonos permanentes ni revelar el identificador de un objetivo oculto.
- Se añadió `run_juego_cartas_propio_fusion_combat_effects.gd`, PASS 40/40; la suite de acción pasa a 58/58.
- Diecisiete suites específicas: 952/952; nueve generales: 441/441; diagnóstico 15/15; experimento 80/80; escena principal headless PASS.
- Auditoría estática: PASS, 19.850 comprobaciones sobre 83 archivos GDScript.

## 2026-09-09 — Criterio delegado de equilibrio

- Se fija que ATQ y DEF no se decidirán carta por carta de memoria, sino comparando el catálogo por coste, rol, preparación, fiabilidad, efectos y contrajuego.
- La variedad admite perfiles atacantes, defensivos, equilibrados, de utilidad y de alto riesgo, además de diferencias moderadas de potencia cuando tengan una compensación real.
- La mera existencia de Magias o Trampas de destrucción no se considera compensación suficiente sin estudiar disponibilidad, coste, ventana y resultado del intercambio.
- Se crea `docs/diseno/MODELO_DE_EQUILIBRIO_DE_CARTAS_V0_1.md` y se registra JCP-DEC-024.
- Para F067 se adopta como dirección técnica una elección de ATQ o DEF por su controlador antes del primer combate correspondiente, limitada a ese combate; la infraestructura de elección debe conservar prioridad y determinismo.

## 2026-09-09 — F010-NEU se integra en el duelo

- El módulo avanzó a `0.14.0-f010-fusion-action`.
- Se añadió `fuse_creatures` como acción de fase principal, con máximo provisional de una Fusión normal por turno y elección de ataque o guardia.
- Banda Goblin se representa mediante una carta física portadora y una zona pública `fusion_materials`; la identidad generada conserva ambos materiales sin crear una carta adicional.
- Estadísticas, coste, familia, anatomía y aptitudes de la entidad generada alimentan vistas, combate, equipo y comprobaciones de cartas.
- Los equipos de ambos materiales se revalidan y se religan si siguen siendo compatibles.
- Se implementaron los destinos acordados: destrucción a Cementerio para materiales y vínculos; devolución a mano para materiales y a Cementerio para vínculos.
- Se conectó la habilidad de Banda Goblin: una vez por turno, en fase principal propia, paga 1 de Energía y concede +1 ATQ temporal a una criatura propia visible.
- F001-NAT y F067-AGU se rechazan con código específico aunque permanezcan disponibles en el catálogo puro. Las cadenas y la separación voluntaria siguen deshabilitadas.
- La nueva suite `run_juego_cartas_propio_fusion_action.gd` supera 56 comprobaciones; `run_juego_cartas_propio_zones.gd` se amplió a ocho zonas por jugador.
- Las dieciséis suites específicas superan 910/910; las nueve generales 441/441; diagnóstico 15/15; experimento integral 80/80; escena principal headless PASS.
- Auditoría estática: PASS, 19.265 comprobaciones sobre 82 archivos GDScript. Fuentes locales: PASS 6/6.
- Godot utilizado: el portable preexistente `C:/Godot/4.7`, versión `4.7.stable.official.5b4e0cb0f`. La copia temporal redundante ya no existe.
- El manifiesto histórico continúa sin regenerarse: 100 archivos comprobados, 0 ausentes, 7 hashes distintos y 0 errores.

## 2026-09-09 — Cierre runtime de identidades y primer catálogo

- Se descargó Godot 4.7 estable desde la distribución oficial a una carpeta temporal externa al proyecto y se verificó su SHA-256 antes de ejecutarlo.
- Identidades y compatibilidad: PASS, 157 comprobaciones.
- Catálogo F001/F010/F067: PASS, 37 comprobaciones.
- Fundamento genérico de Fusiones: 46/46.
- Las quince suites específicas suman 850/850; las nueve generales, 441/441.
- Diagnóstico: 15 PASS, 0 FAIL, 0 SKIP, 0 WARN.
- Experimento integral: 80/80.
- Escena principal headless: PASS; ejecuta el diagnóstico completo y termina sin errores.
- Auditoría estática: PASS, 18.523 comprobaciones sobre 81 archivos GDScript.
- 0.13.0, JCP-DEC-019 y JCP-DEC-020 pasan a estado vigente. La acción de Fusión sigue sin integrarse en el duelo.

## 2026-09-09 — F010-NEU entra en el catálogo puro

Fuentes consultadas: S01, S02, S03 y S04; sus IDs y fechas siguen coincidiendo con el manifiesto local.

- Se añadió `games/juego_cartas_propio/fusion_catalog.gd` sin modificar el estado ni las acciones del duelo.
- F010-NEU es la única receta activa: Goblin Neutral + Goblin Neutral = Banda Goblin, Formación 3/3 de coste de referencia 3.
- Los perfiles se derivan de cartas físicas reales, conservan controlador, visibilidad, taxonomía, anatomía, aptitudes y el identificador físico contenido.
- La nueva suite cubre contrato, ambos órdenes, construcción, liberación futura, material oculto, propietarios distintos, carta repetida, tipo incorrecto y pareja F011 todavía no registrada.
- Auditoría estática: PASS, 18.439 comprobaciones sobre 81 archivos GDScript.
- La integridad de paquete detecta siete hashes desactualizados y cero archivos ausentes porque `MANIFEST.json` continúa describiendo la baseline anterior; se aplaza su regeneración hasta cerrar runtime.
- Godot sigue ausente; parser y runtime quedan pendientes y F010 no se declara jugable dentro del duelo.

## 2026-09-09 — M01–M18 reciben identidad runtime

Fuentes consultadas: S01, S02, S03 y S04; sus IDs y fechas siguen coincidiendo con el manifiesto local.

- El módulo avanzó a `0.13.0-card-identities`.
- Las 18 criaturas recibieron los nombres, familias, superfamilias, anatomías y aptitudes de la baraja inicial.
- Se conservaron estadísticas, elementos, efectos funcionales y exactamente once Manipuladores.
- La validación rechaza ahora anatomía `unassigned`, familias ausentes y etiquetas identitarias repetidas en criaturas jugables.
- La suite de compatibilidad comprueba nombres, reparto 3/4/5/4/2 entre las cinco familias y diferencias físicas entre los dos Dragones.
- Auditoría estática: PASS, 18.107 comprobaciones sobre 79 archivos GDScript.
- Godot no está instalado ni disponible en `PATH`; parser y runtime de 0.13.0 quedan pendientes y la fase no se declara cerrada.

## 2026-09-09 — Baraja inicial de fantasía y auditoría

Fuentes consultadas: S01, S02, S03 y S04.

- Se asignaron nombres e identidad a las 40 cartas funcionales del mazo generalista sin cambiar su distribución, curva, estadísticas, efectos, elementos ni reparto de Manipulador.
- Las 18 criaturas se reparten entre Lobos, Goblins, Elementales, Trolls y Dragones.
- Se añadieron libros iniciales de Trolls y Dragones y se retiraron asignaciones M incompatibles de los borradores anteriores de Lobos, Goblins y Elementales.
- La baraja puede construir F001, F005, F010, F011, F012, F018, F067 y F068 mediante todas las parejas que satisfacen literalmente sus recetas de S04.
- La mano inicial contiene al menos una criatura en el 96,00 % de los casos y al menos una criatura de coste 1 en el 63,93 %.
- Con diez cartas vistas existe un 66,70 % de probabilidad de reunir alguna pareja de Fusión, antes de considerar despliegue y Energía.
- Se propone para la primera prueba un máximo de una acción de Fusión por jugador y turno.
- El orden recomendado de implementación es F010, F001 y F067; no hubo cambios de código ni de catálogo runtime.

## 2026-09-09 — Libro inicial de Elementales

Fuentes consultadas: S01, S02, S03 y S04; S03 y S04 mantienen en Drive las revisiones del manifiesto.

- Se propusieron seis Elementales base sobre M02, M03, M06, M08, M12 y M15, sin reutilizar códigos asignados en los libros de Lobos o Goblins.
- El núcleo combina anatomías Amorfa y Humanoide y asigna Sapiente, Manipulador y Canalizador solo donde el concepto lo justifica.
- Quedan conceptualmente disponibles F067 Elemental Mayor, F068 Elemental de Vapor y F075 Elemental de Brote Profundo.
- Se redactó F067-AGU: coste 4, 4 ATQ / 4 DEF y elección de +1 ATQ o +1 DEF en su primer combate de cada turno.
- No hubo cambios de código ni de catálogo runtime.

## 2026-09-09 — Libro inicial de Goblins

Fuentes consultadas: S01, S02, S03 y S04; S03 y S04 mantienen en Drive las revisiones del manifiesto.

- Se propusieron seis Goblins base sobre M04, M05, M09, M10, M11 y M13 sin alterar sus cifras, elementos o habilidades.
- Las seis criaturas son Humanoides, Sapientes y Manipuladoras; Lector y Canalizador permanecen sin asignar.
- El núcleo permite construir conceptualmente F010, F011 y F012. F013 sigue pendiente de un Goblin de Oscuridad.
- Se redactó F010-NEU como primera Formación: coste 3, 3 ATQ / 3 DEF y una mejora temporal de ATQ mediante gasto de Energía.
- No hubo cambios de código ni de catálogo runtime.

## 2026-09-09 — Libro inicial de Lobos

Fuentes consultadas: S01, S03 y S04; S03 y S04 mantienen en Drive las revisiones del manifiesto.

- Se propuso un núcleo de seis criaturas Lobo con nombres de trabajo y conceptos visuales sin producir arte.
- M01 se propone como Lobo de Zarza, M07 como Cachorro de la Senda Verde, M14 como Lobo Gris del Páramo y M17 como Lobo de Ascua Salvaje.
- Se preservan exactamente costes, estadísticas, habilidades, elementos y ausencia de Manipulador.
- Se reservaron un Lobo de Hielo y uno de Luz como cartas futuras sin inventarles cifras.
- F001 Alfa de la Manada queda identificada como primera receta potencialmente jugable mediante M01 + M07.
- Se redactó una propuesta separada para F001-NAT: coste 3, 3 ATQ / 2 DEF y una mejora de +1 ATQ durante el primer ataque aliado de cada turno.
- No hubo cambios de código ni de catálogo runtime.

## 2026-09-09 — Primeras identidades y primera receta concreta

Fuentes revisadas: S01, S02, S03 y S04. Sus fechas de modificación en Drive coincidían con el manifiesto local.

- Se comprobó que la pausa anterior no dejó procesos ni cambios parciales: la auditoría documental estaba terminada.
- M04 recibió la identidad Goblin Rebuscador y M09 la identidad Goblin Pendenciero.
- Ambos conservan sus valores y Manipulador, y reciben familia Goblin, anatomía Humanoide y aptitud Sapiente.
- Se añadió F010-N como variante Neutral de la Banda Goblin conceptual de S04.
- La receta queda en un catálogo puro separado del duelo y fija coste 4, 3 ATQ / 4 DEF y una mejora temporal de liderazgo.
- Se documentaron concepto y dirección visual sin producir arte.
- La comprobación de fuentes pasó 6/6 y la auditoría estática pasó 18.110 comprobaciones.
- Las suites runtime no pudieron ejecutarse porque Godot no está instalado ni disponible en `PATH`; la candidata no se declara cerrada.

## 2026-09-09 — Corrección de secuencia y compendio

- El usuario recordó correctamente que S03 ya contenía una lista amplia de familias y S04 reglas y recetas concretas.
- Se recuperaron 60 entradas fantásticas y 125 recetas; entre ellas F001 Alfa de la Manada, F010 Banda Goblin y F067–F076 para Elementales.
- Se retiraron del código los nombres y cifras inventados para M04, M09 y F010-N antes de declararlos aprobados.
- Se creó un índice general y un primer tomo dedicado a Lobos, Goblins y Elementales.
- El módulo vuelve a 0.12.0 sin cambios de contenido ni necesidad de una nueva ejecución runtime.

## 2026-09-08 — Apertura del segundo juego

- Se creó `games/juego_cartas_propio/juego_cartas_propio_module.gd` sobre una copia independiente del motor universal.
- Se fijaron dos jugadores, vida, energía, fases, 40 definiciones y dos barajas reproducibles.
- Se mantuvo intacto el proyecto activo de Zápiti.

## 2026-09-08 — Zonas, privacidad e invocación

- Se añadieron las zonas completas de cada jugador y la conservación de 40 cartas propias.
- Se implementaron invocación, colocación oculta, costes, capacidad y límite de invocación normal.
- Se protegieron las identidades ocultas en vistas, acciones y eventos.

## 2026-09-08 — Posturas y combate

- Se incorporaron cambios de postura, restricciones temporales y ataque por casilla anónima.
- Se implementó doble comparación estricta, destrucción, cementerio, sobrante, ataque directo y final por vida cero.
- Se separó la estadística impresa de la estadística efectiva.

## 2026-09-08 — Cartas de campo y efectos iniciales

- Se añadieron apoyos preparados, persistentes, artefactos, equipos, vínculos y terrenos.
- Se implementaron G01–G05, G03 con rotura de vínculos, E01–E03, E05–E06 y R01–R03.
- Se registró el texto funcional provisional de Magias, Trampas, Objetos y Terrenos.

## 2026-09-08 — Respuestas a ataques

Archivos principales:

- `games/juego_cartas_propio/juego_cartas_propio_module.gd`
- `tests/run_juego_cartas_propio_reactions.gd`
- `JUEGO_CARTAS_PROPIO.md`

Cambios:

- Se añadió `pending_attack` al estado canónico.
- Se creó una ventana con prioridad alterna y dos pases consecutivos.
- Se extrajo la resolución del ataque para que ataques con y sin respuestas compartan exactamente el mismo combate.
- Se añadió cadena LIFO y vista pública saneada.
- Se implementaron G06, G07, T01 y T02.
- Se preservó la ocultación del objetivo durante la ventana.
- Las respuestas resueltas pasan al cementerio y dejan de estar activas.

Verificación:

- combate: 53;
- efectos: 66;
- cartas de campo: 47;
- fases: 39;
- posturas: 50;
- respuestas: 48;
- invocación: 16;
- zonas: 58;
- total específico: 377;
- diagnóstico: 15/15;
- experimento integral: 80/80.

## 2026-09-08 — Sistema de cuadernos

- Se detectó que `docs/CURRENT_STATE.md` y otros documentos F01–F05 describían una baseline de julio y no el estado vigente del segundo juego.
- Se crearon cuatro cuadernos vivos con autoridad separada para estado, decisiones, bitácora y pruebas/pendientes.
- Se añadió `AGENTS.md` para convertir su lectura y actualización en parte obligatoria del flujo de trabajo.

## 2026-09-08 — Respuestas genéricas y T03

Archivos principales:

- `games/juego_cartas_propio/juego_cartas_propio_module.gd`
- `tests/run_juego_cartas_propio_reactions.gd`
- `tests/run_juego_cartas_propio_spell_reactions.gd`

Cambios:

- `pending_attack` fue sustituido por `pending_response` con contextos validados de ataque o Magia.
- Ataques y Magias comparten acciones de prioridad, dos pases, cadena LIFO, vista pública y consumo de respuestas.
- Las Magias esperan sin aplicar su efecto mientras la ventana está abierta.
- T03 anula G01–G03 y envía la Magia y la Trampa al cementerio.
- Si el defensor pasa, conserva T03 oculta y la Magia se resuelve normalmente.
- La vista pública muestra la definición activada, pero no el identificador interno de la carta que continúa temporalmente en la mano.

Verificación:

- nueva suite de respuestas a Magias: 30;
- nueve suites específicas: 407;
- diagnóstico: 15/15;
- experimento integral: 80/80.

## 2026-09-08 — Disparadores T04, T05 y T06

Archivos principales:

- `games/juego_cartas_propio/juego_cartas_propio_module.gd`
- `tests/run_juego_cartas_propio_trigger_reactions.gd`
- documentación principal y cuatro cuadernos vivos

Cambios:

- `pending_response` admite ahora contextos validados de cambio de postura, equipo vinculado y destrucción en combate.
- T04 revierte opcionalmente a guardia una transición enemiga voluntaria a ataque, sin devolver el cambio ya consumido.
- T05 destruye opcionalmente el equipo recién vinculado y limpia `linked_to`.
- T06 abre su decisión después del combate y destruye al combatiente enemigo superviviente si sigue en campo.
- Los tres efectos reutilizan prioridad alterna, dos pases, cadena LIFO, consumo al cementerio y restricción del turno de preparación.
- Se añadieron eventos públicos específicos para las tres resoluciones.

Verificación:

- nueva suite de disparadores: 53;
- diez suites específicas: 460/460;
- nueve suites generales UCE: 441/441;
- diagnóstico: 15/15;
- experimento integral: 80/80;
- ejecución completa: 21 runners, todos en PASS.

## 2026-09-08 — Activación de E04

Archivos principales:

- `games/juego_cartas_propio/juego_cartas_propio_module.gd`
- `tests/run_juego_cartas_propio_artifacts.gd`
- documentación principal y cuatro cuadernos vivos

Cambios:

- Se añadió la acción canónica `relocate_equipment` a validación, reducción y acciones legales.
- Cada E04 visible y activo puede trasladar un equipo una vez por turno.
- El destino reutiliza `_can_equip()`, por lo que los requisitos de Manipulador son idénticos a los del equipamiento inicial.
- Los intentos incompatibles o repetidos se rechazan sin mutar el estado ni avanzar su versión.
- El nuevo vínculo abre la respuesta de T05; si el equipo es destruido, E04 permanece activo pero gastado durante ese turno.

Verificación:

- nueva suite de artefactos: 36;
- once suites específicas: 496/496;
- nueve suites generales UCE: 441/441;
- diagnóstico: 15/15;
- experimento integral: 80/80;
- ejecución completa: 22 runners, todos en PASS.

## 2026-09-08 — Combinaciones ordenadas de Terreno

Archivos principales:

- `games/juego_cartas_propio/juego_cartas_propio_module.gd`
- `tests/run_juego_cartas_propio_terrain_combinations.gd`
- documentación principal y cuatro cuadernos vivos

Cambios:

- Se contrastaron las reglas con `01_MECANICAS_BASICAS_EN_DISCUSION` y la biblia de familias de Google Drive.
- Se implementaron las seis recetas ordenadas iniciales; invertir los componentes produce una identidad distinta.
- La carta entrante porta la forma resultante en la única zona de Terreno y la carta anterior pasa al Cementerio.
- Cuando no existe receta, el Terreno entrante sustituye al vigente y recupera identidad base.
- Se añadieron eventos `terrain_transformed` y `terrain_replaced` y una identidad pública estable con nombre y componentes.
- La validación rechaza metadatos parciales, recetas incoherentes y cartas portadoras incompatibles.
- No se inventaron efectos para las formas transformadas; mientras sigan pospuestos, tampoco heredan el bono de la definición física entrante.

Verificación:

- nueva suite de Terrenos: 114;
- doce suites específicas: 610/610;
- nueve suites generales UCE: 441/441;
- diagnóstico: 15/15;
- experimento integral: 80/80;
- ejecución completa: 23 runners, todos en PASS.

## 2026-09-08 — Auditoría previa de Fusiones y personajes especiales

Fuentes revisadas:

- `04_LIBRO_DE_FUSIONES_V0_1`
- `05_PERSONAJES_ESPECIALES_Y_CARTAS_DE_AMIGOS_V0_1`

Hallazgos:

- El libro define con claridad entidad generada, materiales contenidos, destrucción, casilla única, visibilidad de materiales y recetas no ordenadas por defecto.
- El catálogo es conceptual: no fija todavía coste, ATQ, DEF ni habilidades finales de los resultados.
- Las criaturas provisionales M01–M18 del módulo solo tienen elemento y capacidad de Manipulador; todavía no tienen familia ni anatomía con las que resolver las recetas del libro.
- Los personajes especiales conservan conceptos y compatibilidades futuras, pero sus propias fuentes marcan cifras, habilidades y recetas concretas como pendientes.
- Se decidió no inventar una Fusión jugable ni introducir entidades muertas en el estado. El siguiente corte debe cerrar primero las identidades mínimas de materiales y una receta completa.

## 2026-09-08 — Perfiles de anatomía y aptitudes

Archivos principales:

- `games/juego_cartas_propio/juego_cartas_propio_module.gd`
- `tests/run_juego_cartas_propio_compatibility_profiles.gd`
- documentación principal y cuatro cuadernos vivos

Cambios:

- Se contrastó la implementación con la nota autoritativa de Aptitudes, Anatomía y Narrador.
- Se descartó una estadística numérica de inteligencia y se separaron anatomía, aptitudes de la criatura y requisitos del objeto.
- Manipulador dejó de ser un booleano especial: las criaturas poseen listas de aptitudes y los objetos listas de requisitos.
- Se prepararon los perfiles Humanoide, Cuadrúpedo, Alado, Serpentino, Amorfo, Espectral y Colosal sin asignarlos arbitrariamente a M01–M18.
- Se conservó exactamente el reparto previo de once Manipuladores y los requisitos de E01, E03 y E06.
- `_can_equip()` comprueba todos los requisitos de aptitud y, cuando existan, las anatomías permitidas.
- La validación rechaza etiquetas desconocidas o repetidas, campos booleanos heredados y equipos que permanecen vinculados a un portador incompatible.
- Se registró que el narrador/locutor continúa incompleto en catálogo y presentación, aunque su límite reglamentario sí está definido.

Verificación:

- nueva suite de compatibilidad: 96;
- trece suites específicas: 706/706;
- nueve suites generales UCE: 441/441;
- diagnóstico: 15/15;
- experimento integral: 80/80;
- ejecución completa: 24 runners, todos en PASS.

## 2026-09-08 — Corpus local e índice de fuentes de diseño

Archivos principales:

- `docs/fuentes_diseno/README.md`
- `docs/fuentes_diseno/SOURCE_MANIFEST.json`
- copias normalizadas S00–S05
- `tools/check_design_source_cache.ps1`
- `AGENTS.md`

Cambios:

- Se inventarió directamente la carpeta de Drive y se confirmó que contiene cinco documentos y una hoja de cálculo.
- Se descargaron localmente los textos completos, los valores y las fórmulas, conservando ID, enlace, revisión o fecha observada.
- Se creó una ruta de lectura por fase para evitar cargar el corpus completo y mezclar documentos ajenos en búsquedas generales.
- Se distinguió la autoridad editable de Drive, la memoria de implementación de los cuadernos y la caché local de consulta.
- Se documentó el hallazgo: S01 define perfiles y aptitudes, pero aplaza expresamente las anatomías concretas de M01–M18 hasta diseñar nombre, especie e identidad visual.
- Se añadió una comprobación de integridad que exige las seis fuentes, IDs únicos, tamaño mínimo y presencia en el índice.

Fuentes contrastadas: S00, S01, S02, S03, S04 y S05.

## 2026-09-08 — Fundamento genérico de Fusiones

Fuentes revisadas: S01, S03 y S04. Sus revisiones de Drive coincidían con el manifiesto local al iniciar la fase.

Archivos principales:

- `games/juego_cartas_propio/fusion_recipe_service.gd`
- `tests/run_juego_cartas_propio_fusion_foundation.gd`
- documentación principal y cuatro cuadernos vivos

Cambios:

- Se creó un servicio puro que no modifica el duelo ni activa contenido real.
- Se validan recetas V0.1 de dos materiales, ordenadas o no ordenadas, perfiles de material e identidades resultantes completas.
- La búsqueda elige la receta más específica y rechaza empates en lugar de resolverlos arbitrariamente.
- Se exigen materiales visibles, del mismo controlador y sin cartas físicas repetidas.
- La construcción vuelve a comprobar la receta, el mapeo y los perfiles para que una coincidencia manipulada no pueda generar una entidad.
- Las cadenas conservan una lista plana y única de cartas físicas originales; la procedencia mantiene incluso dos Fusiones intermedias de igual identidad.
- No se añadieron recetas reales porque S01 aplaza las identidades de M01–M18 y S04 no fija estadísticas ni habilidad de los resultados.

Verificación:

- nueva suite de Fusiones: 46/46;
- catorce suites específicas: 752/752;
- nueve suites generales UCE: 441/441;
- diagnóstico: 15/15;
- experimento integral: 80/80;
- comprobación local de fuentes: 6/6.

## 2026-09-09 — Recuperación de excepciones y efectos latentes

Fuentes revisadas: S00, S01, S03, S04, revisiones de Drive y conversación original «Diseño juego cartas».

Hallazgos y decisiones:

- La carpeta fuente de Drive contiene exactamente los seis documentos inventariados y sus fechas coinciden con `SOURCE_MANIFEST.json`.
- La conversación original conservaba detalles sobre efectos latentes que quedaron reducidos en las fuentes a menciones generales.
- Se restauró el principio de que las reglas son comportamientos por defecto y pueden ser sustituidas parcialmente por cartas, habilidades, recetas o estados escritos.
- Se recuperó el modelo de latencia determinista: pista previa, condición exacta, efecto despertado, contrajuego, revelación en códice y explicación mecánica/narrativa.
- «Venganza del Bosque» permanece como ejemplo y no se convirtió en carta ni recibió cifras inventadas.
- Se cerraron por decisión actual los destinos base de devolución y separación de una Fusión, además de su entrada boca arriba y sin ataque inmediato.

Archivos modificados: documento de principios y cuatro cuadernos vivos. No se modificó código ni se requirieron pruebas runtime.