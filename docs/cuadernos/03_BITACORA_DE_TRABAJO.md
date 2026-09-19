# Cuaderno 3 — Bitácora de trabajo

## 2026-09-15 — Primera línea base de equilibrio sin retocar cartas

- Se contrastaron S01, S02 y S04 con sus fechas de Drive; la caché local pasó 6/6. S01 exige revisar la composición solo tras problemas prácticos de partidas, S02 se declara presupuesto provisional y S04 fija la preparación de Fusiones. El único guardado humano disponible era una partida `RUNNING` del 2026-09-11 con cero acciones; no se atribuyó a ella evidencia de equilibrio.
- `tools/run_jcp_stress_matches.gd` recibió el modo optativo `--balance`: vida normal de 30, políticas repartidas entre ambos jugadores iniciales, métricas por carta vista/jugada y guardado de avances cada dos partidas. El modo normal de estrés no cambia. Se descartó una primera ejecución exploratoria con política correlacionada con la paridad de semilla; la tanda emparejada final usó semillas 1000–1015.
- `tools/report_jcp_saved_match.gd` resume un guardado local, incluidos desenlace, acciones, cartas jugadas y Fusiones, sin publicar mano, baraja ni log completo. Se comprobó que lee el guardado antiguo y que lo marca correctamente como no terminado; no se ha fingido una prueba humana completa.
- La tanda final completó 16 duelos de 30 vidas, 5.623 acciones, 427 ataques, 24 Fusiones y 106 respuestas activadas sin fallo. El informe bruto y la interpretación están en `diagnostic_logs/jcp_stress_balance_paired_20260915.json` y `docs/diseno/LINEA_BASE_EQUILIBRIO_MAZO_2026_09_15.md`. La muestra de bots no permite afirmar potencia causal por carta; M01–M18, G01–G07, T01–T06, E01–E06 y R01–R03 permanecen intactas. Ninguna regla, IA de mesa, UCE o geometría cambió. Esta fase de medición sigue abierta hasta recibir partidas humanas terminadas.

## 2026-09-14 — Activaciones legibles antes de continuar

- La partida humana mostró que una respuesta mágica o trampa podía cambiar un ataque sin dejar tiempo para identificarla. Se contrastó S01: preparar boca abajo no es activar; la activación sí publica identidad y permite respuestas sucesivas. E03 no era un fallo de regla: exige Manipulador y no puede jugarse en Combate.
- Se preservó `demo/juego_cartas_table.gd` antes del cambio en `artifacts/backup_pre_activation_reveal_20260914/`. La mesa toma únicamente eventos filtrados de UCE y presenta Magias/Trampas activadas una a una con `CardTile` ampliada, texto funcional, pausa de cuatro segundos y «Siguiente ahora». El catálogo estático aporta el texto de un ID ya publicado; no se consulta la mano rival oculta. Se evita volver a anunciar una Magia principal cuando se resuelve después de su activación.
- La cola detiene el pase trivial y el siguiente paso de la IA hasta cerrar la ficha; no modifica el orden de resolución del motor. Una nueva prueba gráfica verifica privacidad, dos anuncios en orden, temporizador, ficha G06 real, captura 1600×900 y pase automático aplazado. Puertas y riesgo del arnés de ventanas en cuaderno 4. Reglas, geometría, E03 y motor no cambiaron.

## 2026-09-14 — Diálogos sin variantes duplicadas y respuesta sin clic inútil

- Las capturas humanas mostraron tres filas para invocar una sola criatura y cuatro para una sola Fusión: eran producto cartesiano de Ataque/Guardia y objetivos de entrada, no resultados distintos. S01 confirma doble comparación estricta y fase de Combate con ataques sucesivos; S04 confirma identidad de Fusión por receta. Se preservaron esas reglas.
- Respaldo de `demo/juego_cartas_table.gd` previo en `artifacts/backup_pre_choice_response_20260914/`. La mesa agrupa las acciones legales por postura, pide objetivo en un segundo paso solo cuando procede y evita repetir nombre/coste/materiales por combinación. El botón «Cerrar combate» pasa a «Pasar ataques» para describir su función sin presentar un modo que haya que activar para cada carta.
- Una respuesta del rival puede devolver prioridad al humano sin ninguna reacción propia disponible; antes exigía pulsar «Pasar respuesta» aun sin decisión. Solo en duelo con IA se pasa automáticamente ese caso mediante la acción UCE existente. Los combates muestran comparaciones, supervivencia y daño; un ataque anulado comunica que su uso se gastó. No se modificaron el motor, recetas, estructura de fases ni geometría. Pruebas y riesgo de foco gráfico en cuaderno 4.
- El acceso directo del escritorio se regeneró y comprobó hacia Godot 4.7, la escena explícita y el proyecto vigente en F.

## 2026-09-14 — Menú de combate y postura junto a la criatura

- El diseñador aprobó mostrar Atacar y Cambiar postura en la criatura, no en el rail. S01 documenta límites de cambio voluntario que podían interpretarse en conflicto con «solo una carta lo impediría»; se pidió aclaración. El diseñador precisó que hablaba de elegir postura antes de invocar y de modificarla desde la criatura en el tablero, no de reescribir esos límites. Se conservaron S01 y el motor intactos.
- Copia física previa de `demo/juego_cartas_table.gd` en `artifacts/backup_pre_creature_context_20260914/`. La mesa dibuja un menú cercano a la criatura seleccionada: Atacar activa resaltado de objetivos y Cambiar postura ejecuta la acción UCE disponible. Cuando una acción no es legal queda deshabilitada con explicación emergente. La invocación Ataque/Guardia, clic rápido de ataque visible, arrastre de Fusión, dimensiones, perspectiva y guardado permanecen como estaban. El botón de postura deja de estar en la lista lateral.
- Se adaptó la prueba gráfica de ataque a elegir Atacar y se añadió prueba gráfica de postura: bloqueo de turno de entrada, cambio en turno posterior y un único envío UCE. Una captura 1600×900 muestra el menú junto a carta real. Resultados finales en cuaderno 4.

## 2026-09-14 — Repartos nuevos al iniciar partida

- La observación humana se contrastó con S01 y el código: ambos jugadores tenían el mismo mazo generalista de 40 cartas; UCE ya lo barajaba de forma independiente, pero la mesa abría y reiniciaba siempre con `210921`. No se modificó el constructor de mazos ni el motor.
- Antes de cambiar la mesa se copió `demo/juego_cartas_table.gd` a `artifacts/backup_pre_random_starts_20260914/`. La apertura y «Nueva partida» eligen ahora semilla fresca; Herramientas conserva la semilla vigente y añade «Jugar semilla» para reproducirla. Las suites que dependen de un reparto concreto fijan la semilla al instanciar la mesa; un test nuevo cubre tres reinicios, cambio real de mano, tamaño de ambos mazos y repetición exacta.
- El cambio es solo de inicio/UI; no altera S01, reglas, contenido, UCE, IA, privacidad ni geometría. Las puertas ejecutadas y riesgos se registran en el cuaderno 4.

## 2026-09-14 — Frontal provisional con cifras visibles

- La prueba humana mostró que en la mano solo figuraban nombre y tipo: el componente solo recibía ATQ/DEF cuando la carta ya estaba en campo. Se leyó S01/S02 y se reutilizaron los valores impresos de la definición visible, sin introducir cifras ni costes nuevos.
- Antes del cambio visual se copiaron `demo/card_tile.gd` y `demo/juego_cartas_table.gd` en `artifacts/backup_pre_card_front_20260914/`. `card_tile.gd` presenta nombre, elemento, coste numérico, área de imagen vacía, tipo y ATQ/DEF en la mano y preview; la ficha grande muestra el texto de efecto. `juego_cartas_table.gd` entrega datos impresos en mano y efectivos cuando existen en campo, y añade ATQ/DEF al detalle textual anterior a la invocación. El coste de referencia de Fusión queda diferenciado.
- Se añadió aserción con criatura real de la mano para coste/ATQ/DEF/efecto y se corrigió una expectativa de texto obsoleta en la prueba de flujo de ataque. Las capturas de 1600×900 muestran el frontal nuevo sin alterar la malla ni la mano rival oculta. Resultados y límites en cuaderno 4.

## 2026-09-14 — Arrastre de materiales y coste visible de Fusión

- El diseñador aprobó una Fusión que comience en la criatura del campo y se suelte sobre otra compatible, manteniendo dos clics como alternativa. Se comprobó S04 y el contrato vigente: la Fusión normal cuesta 0 Energía, aunque la entidad resultante tenga un coste de referencia para equilibrio. No se diseñaron ni añadieron variantes más caras.
- `card_tile.gd` emite arrastre/entrega de material de campo y solo admite parejas derivadas de acciones legales; `juego_cartas_table.gd` ilumina la pareja y presenta nombre del resultado, postura, objetivo si procede y pago 0 antes de ejecutar el comando UCE. Cancelar o soltar fuera no muta. Se preserva la geometría. Punto previo de seguridad físico: `artifacts/backup_pre_fusion_drag_20260914/`; respaldo geométrico original en la etiqueta `mesa_perspectiva_ok_v1` intacto.
- La prueba gráfica de Fusión recorre arrastre real, iluminación, rechazo de material inválido, cancelación, alternativa por dos clics y confirmación; guarda captura 1600×900. Los resultados de la puerta proporcional se registran en el cuaderno 4.

## 2026-09-13 — Corrección del bloqueo al terminar turno

- La captura de la prueba humana mostraba «Puedes responder» con «TERMINAR TURNO» inhabilitado; además, el selector de criatura bloqueaba el mismo mando. Se retiró esa dependencia de la selección. Confirmar el fin de turno descarta cualquier intención incompleta y avanza solo con las acciones legales de fase. Durante una respuesta con prioridad propia el mando ofrece «Pasar respuesta», y con prioridad rival indica espera, sin saltarse la resolución del motor.
- `run_juego_cartas_propio_creature_ux.gd` ahora prueba la cancelación de una selección a medias al terminar; la nueva `run_jcp_table_end_turn_response.gd` prepara una trampa real, declara un ataque y comprueba que el botón pasa una respuesta legal. Esta decisión JCP-DEC-053 sustituye el bloqueo de JCP-DEC-050; no se cambió UCE ni ninguna regla.

## 2026-09-13 — Segunda prueba humana: ataque sin botón y mejoras legibles

- El diseñador confirmó que la ruta «Ir a Combate» seguía siendo demasiado compleja. Se leyó S01 para conservar sus reglas de fases y cartas: la transición Principal 1 → Combate ahora ocurre al pulsar primero la criatura propia y luego el objetivo rival; acto seguido se declara el ataque legal mediante UCE. El botón superior pasa a «Pasar sin atacar» y salta a Principal 2 solo a petición del jugador. No se modifica una sola regla de combate.
- La selección y los mensajes diferencian equipo vinculado (por ejemplo E02 +1 DEF al portador), magia persistente global G04 (+1 DEF automático a todas las criaturas propias en Guardia), G05 disparada por cambio de postura y el artefacto E04, que solo mueve un equipo ya vinculado. Un clic en criatura con G04/G05/E04 seleccionadas ya no sustituye silenciosamente la carta: informa que esas cartas no se asignan. El resultado de jugar G04 se comunica como activo aunque aún no haya criaturas en Guardia.
- Pruebas GUI con eventos de ratón: ataque desde Principal 1 sin botón, primera ronda sin ataque, E02 vinculada a objetivo y G04 colocada en Apoyo con bono automático de DEF. Se preserva la caché de acciones legales y la geometría aprobada. Resultados completos y límites, en cuaderno 4.

## 2026-09-13 — Prueba humana: latencia y descubrimiento de acciones

- Se reprodujo la latencia al seleccionar cinco cartas iniciales: aproximadamente 2,0–2,7 segundos por cambio. La causa era que un refresco consultaba decenas de veces las mismas acciones legales de UCE; cada consulta aislada costaba unos 56 ms. `demo/juego_cartas_table.gd` ahora usa una caché estricta por versión de estado y espectador, sin alterar UCE. Sonda posterior: 45–49 ms por selección. La sonda reproducible queda en `tools/profile_table_selection.gd`.
- Se enviaron clics gráficos reales dentro de Godot. G01 no se ejecuta al seleccionarla: exige pulsar un objetivo propio; al hacerlo, aumenta el ATQ de M01 de 2 a 4 y pasa al Cementerio. Un ataque legal también se ejecuta por clic atacante → rival tras entrar en Combate y superar el primer turno. Las pruebas están en `tests/run_jcp_table_spell_gui.gd` y `tests/run_jcp_table_attack_gui.gd`. Esto no descarta un fallo en la magia concreta descrita por el diseñador, todavía sin nombre.
- Los mensajes de éxito y de clic prematuro eran casi invisibles porque solo se mostraban arriba los errores y el resto quedaba como tooltip. Se hicieron visibles, y el rail explica cuándo un apoyo es persistente o respuesta preparada, cómo entrar en Combate y cómo elegir dos materiales compatibles para Fusión. No se tocó geometría, motor, reglas, IA ni catálogo. Resultados de suites en cuaderno 4.
- Se regeneró y verificó el acceso directo del escritorio para que abra la escena explícita de la mesa en F con Godot 4.7. El capturador gráfico produjo cinco imágenes reales de 1600×900, incluidas cartas en Ataque y Guardia; se comprobó que las instrucciones permanecen en el HUD/rail y no desplazan casillas ni fases.
- La nueva prueba `tests/run_jcp_table_fusion_gui.gd` progresa una partida real hasta dos materiales compatibles (M01 y M07), pulsa ambos controles gráficos, comprueba que el segundo clic abre una elección sin mutación prematura y confirma una Fusión mediante su opción. La suite vertical del motor sigue siendo independiente.

## 2026-09-13 — UX A/B de invocación de criatura

- Se comprobaron el estado Git y el respaldo de perspectiva (`mesa_perspectiva_ok_v1` y copia física de diecisiete archivos), se leyeron `AGENTS.md`, índice y los cuatro cuadernos, y se confirmó la caché de diseño 6/6. Se preservó el estado de fondo negro previo a UX en un punto Git separado: `mesa_fondo_negro_preux` (`89bf866`). No hubo pull, descarga ni merge y el respaldo de perspectiva no se sobrescribió.
- `demo/table_interaction_state.gd` encapsula fuente, acciones UCE candidatas, destinos legales, modo y cancelabilidad. `demo/card_tile.gd` inicia el drag desde la mano y `demo/creature_drop_slot.gd` valida la entrega. `demo/juego_cartas_table.gd` lleva tanto clic-clic como drag a la misma selección de casilla y solo ejecuta la acción UCE al elegir Ataque/Guardia —o la casilla si solo hay un modo—. Escape, clic vacío y drag fallido cancelan. El bloqueo original de Terminar turno mientras faltaba un paso se sustituyó después en JCP-DEC-053. Ningún otro tipo de carta recibió nueva UX en aquella pasada.
- La prueba de eventos GUI reales detectó que `PlayerSupportRow` interceptaba los clics de la mano pese a ser visualmente transparente; se ajustó únicamente su filtro de ratón, sin moverlo ni alterar la plantilla. El menú contextual se recolocó en el hueco entre territorios para no tapar cartas. Se añadieron pruebas de lógica y entrada gráfica y se adaptó la aserción antigua que esperaba el selector central de postura: la invocación ahora tiene una fase intermedia junto a la casilla. Las capturas de selección, menú y carta confirmada se generaron a 1600×900. Resultados finales y límites, en el cuaderno 4.
- Las criaturas con varias acciones UCE distintas para el mismo modo, como una habilidad de entrada que exige objetivo, no se introducen artificialmente en este menú de dos modos: conservan el flujo anterior hasta abordar la UX de habilidades. La puerta final de suites se repitió tras esta salvaguarda.
- Una aserción GUI adicional descubrió que los contenedores del campo consumían el clic en vacío antes de `_unhandled_input`; se movió la cancelación a `_input` y se distingue un botón real bajo el puntero de una superficie vacía. La prueba gráfica de clic vacío pasó sin mutación; el resto de botones no se intercepta.

## 2026-09-13 — Respaldo de la perspectiva y tapete casi negro

- Antes de editar se comprobó `git status`, se leyeron `AGENTS.md` y los cuatro cuadernos, se consultó el índice temático y la caché local de diseño pasó 6/6. Este cambio de color procede solo del encargo del diseñador; S00/S01 no fijan colores. Los dieciséis archivos locales de la mesa y sus pruebas/capturas se confirmaron en `9f4ddd4` y se etiquetaron `mesa_perspectiva_ok_v1` sin pull, descarga ni merge.
- Se creó `artifacts/backup_mesa_perspectiva_ok_v1/` con diecisiete archivos (cinco scripts de mesa, escena, cuatro cuadernos, prueba, capturador y cinco capturas) y se comparó el SHA-256 de cada copia con su origen. Conserva el estado geométrico anterior al cambio de color.
- `demo/duel_table_backdrop.gd` solo sustituye tres colores de relleno verde por casi negro; no cambia una coordenada, vértice, banda, línea, hitbox ni lógica. `field_template_layer.gd`, `juego_cartas_table.gd`, `projected_field_piece.gd` y `card_tile.gd` permanecen idénticos al respaldo Git. Se regeneraron las cinco capturas reales 1600×900, incluidas Ataque y Guardia. Las fases siguen arriba, no en el centro.
- Se actualizan los cuatro cuadernos por JCP-DEC-049; los resultados exactos de prueba y riesgos continúan en el cuaderno 4. El acceso directo del escritorio se regeneró y comprobó contra Godot 4.7, la raíz de F y la escena explícita de la mesa. El fondo negro queda como base temporal, no como arte final.

## 2026-09-12 — Malla geométrica única basada en 1280×720

- Se conservaron todos los cambios locales previos, sin pull, descarga ni merge. Se leyeron `AGENTS.md`, el índice y los cuatro cuadernos; la caché de seis fuentes continúa íntegra. La geometría viene exclusivamente de las cuatro bandas y veinte centros medidos entregados por el diseñador. S00/S01 se consultaron solo para mantener zonas y fases reglamentarias.
- `demo/field_template_layer.gd` registra literalmente las coordenadas 1280×720, aplica una escala uniforme según el rectángulo disponible y centra C3. Dibuja las cuatro bandas de la malla. `demo/juego_cartas_table.gd` ya no usa anchos de fila elegidos por separado: coloca los controles de las cuatro filas sobre esa capa y da a cada visual de casilla/carta un cuadrilátero interpolado de la banda medida. Las zonas Fusión/Territorio/Baraja/Cementerio extrapolan los mismos bordes. Manos, cabecera, fase compacta, rail, fondo externo, UCE y señales se conservan.
- La prueba de mesa compara literalmente las cuatro bandas y veinte centros con la referencia, exige escala uniforme, C3 centrada, apertura progresiva y verifica que cada pieza coincide con la banda o sus flancos. En la primera captura la costura central del fondo cruzaba la tercera banda; una traslación común mínima la dejó entre bandos sin tocar el fondo ni alterar proporciones. Se repitieron capturas 1600×900 con criatura real en Ataque y Guardia, no solo mesa vacía. Resultados exactos en el cuaderno 4.

## 2026-09-12 — Proyección real del campo y fase fuera del centro

- Se conservaron los cambios locales previos sin pull ni merge. Lectura de `AGENTS.md`, índice y cuatro cuadernos; caché de diseño 6/6. Fuente visual: corrección expresa del diseñador; S00/S01 solo delimitan las zonas y las seis fases mecánicas. No se cambió el fondo trapezoidal, la posición general, rail, colores ni tamaños base.
- `demo/projected_field_piece.gd` dibuja superficies trapezoidales con plano, borde y sombra discretos. `demo/juego_cartas_table.gd` las usa para las veinte casillas, cada carta efectivamente jugada en Ataque o Guardia y las ocho zonas laterales. Los botones y `CardTile` se conservan como hitboxes invisibles: señales, selección, objetivos y datos visibles continúan por la ruta anterior. La mano propia y rival no se proyectan. La banda de fases sale del centro; el HUD superior muestra solo la fase actual.
- `tests/run_juego_cartas_propio_manual_table.gd` comprueba proyección, número de zonas y ausencia de la banda central. `tools/capture_manual_table.gd` añade escenarios de partida con una criatura real en Ataque y otra oculta en Guardia; comprueba estado y componente proyectado antes de guardar sus capturas. La primera revisión gráfica mostró rótulos desplazados; se corrigió el origen horizontal del texto y se repitieron las imágenes.
- Cinco suites PASS y cinco capturas reales 1600×900 revisadas; los resultados y riesgos constan en el cuaderno 4. No se tocaron UCE, reglas, IA, privacidad, replay, persistencia ni Fusión.

## 2026-09-12 — Perspectiva interna de filas y zonas

- Se trabajó sobre la copia local con cambios anteriores sin confirmar; no hubo pull, descarga remota ni merge. Se leyeron las instrucciones y cuadernos. `docs/diseno/GREYBOX_INTERFAZ_FINAL_V0_1.md`, `docs/diseno/CUADERNO_BENCHMARK_INTERFAZ_TCG_V0_1.md` y `demo/juego_cartas_table_greybox.gd` no existen localmente, por lo que no se les atribuyó contenido. Encargo explícito del diseñador como fuente de geometría; S00/S01 solo delimitan zonas y autoridad mecánica; caché local de seis fuentes coherente.
- `demo/juego_cartas_table.gd`: el tapete exterior y los tamaños nominales se conservaron. Las cinco casillas de cada fila usan un ancho específico según su profundidad (549/570/590/625 px, de rival lejano a propio cercano), y las zonas laterales se sitúan respecto a ese mismo ancho. `tests/run_juego_cartas_propio_manual_table.gd` comprueba las cuatro distribuciones y ambos flancos, además de las métricas previas.
- Capturas reales de vista inicial, selección y elección en 1600×900 revisadas: lado propio más abierto, rival más recogido, zonas laterales alineadas y sin clipping observado. Cinco suites proporcionales PASS; detalles en el cuaderno 4. No se modificaron motor, reglas, catálogo, IA, privacidad, combate, Fusión, replay, persistencia ni interacción.

## 2026-09-12 — Perspectiva oblicua de jugador sentado

- Se continuó sobre los cambios locales no confirmados de la iteración de métricas, sin descartarlos ni hacer pull o merge. Los documentos `GREYBOX_INTERFAZ_FINAL_V0_1.md` y `CUADERNO_BENCHMARK_INTERFAZ_TCG_V0_1.md` siguen ausentes localmente; se siguió solo el encargo explícito y las fuentes S00/S01 para conservar límites mecánicos.
- `demo/duel_table_backdrop.gd` sustituye la cuadrícula técnica por un tapete trapezoidal con borde cercano, fondo rival estrecho y tres costuras suaves. `demo/juego_cartas_table.gd` conserva las medidas nominales de JCP-DEC-044, pero escala visualmente filas rivales mediante envoltorios neutros (la primera captura reveló que Godot anulaba la escala aplicada directamente a hijos de `Container`). El HUD rival se estrechó; el propio mantiene más presencia.
- La cabecera principal queda reducida a mandos de partida. Vistas, cortina y semilla se pliegan bajo Herramientas. Estado breve contextual, rail sin pared de instrucciones y selección con preview se conservan. No se modificaron reglas, motor, catálogo, privacidad, replay, persistencia, IA ni flujo de Fusión.
- `tests/run_juego_cartas_propio_manual_table.gd` cubre la escala visual y el acceso a Herramientas. Capturas y resultados exactos de esta pasada quedan en el cuaderno 4.

## 2026-09-12 — Métricas greybox locales a 1600×900

- El repositorio local estaba limpio antes de editar. Los archivos `docs/diseno/GREYBOX_INTERFAZ_FINAL_V0_1.md`, `docs/diseno/CUADERNO_BENCHMARK_INTERFAZ_TCG_V0_1.md` y `demo/juego_cartas_table_greybox.gd` no existen en esta copia ni en el taller local; no se hizo pull ni se atribuyó contenido a ellos. Se reutilizó la escena y la mesa actuales.
- `demo/card_tile.gd` y `demo/juego_cartas_table.gd` adoptan las métricas de JCP-DEC-044: campo 72×101/101×72 en envolvente 101×101, hueco 11, manos 86×120 con paso decreciente, preview 180×251, auxiliares 60×90 y rail 274. Las guías vacías dejan de repetir `VACÍA`. Guardar/Cargar bajan al pie del rail para que el título y la selección sean legibles.
- `tests/run_juego_cartas_propio_manual_table.gd` incorpora comprobaciones explícitas de tamaños y pasos de mano. El render real se capturó a 1600×900 con vista inicial, selección y elección. No se modificó `UniversalCardEngine`, el módulo de reglas, catálogo, replay ni persistencia.
- Pruebas y acceso directo: véase la sección de verificación greybox en el cuaderno 4. Fuente consultada para este corte de presentación: encargo del diseñador, índice local de S00/S01 y caché de fuentes 6/6.

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
- Se conectó la habilidad de Banda Goblin: una vez por turno, en fase principal propia, paga 1 de Energía para dar +1 ATQ temporal a una criatura propia visible.
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
- Fundamento genérico de Fusiones: PASS, 46 comprobaciones.
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

## 2026-09-15 — Auditoría de la fuente oficial y reconciliación previa al Atlas

Fuentes leídas y contrastadas: S01 en Terrenos, efectos elementales, mejoras apiladas, compatibilidad y transformaciones; S03, S04 y S05 completos. Se verificó además la carpeta oficial de Drive y sus seis hijos S00–S05 contra el manifiesto y la caché local.

Hallazgos:

- La carpeta correcta es `JUEGO_CARTAS_PROPIO` (`1m54Q-WmufRhdVleWMq6mTwUbP3Nzxqcl`), no la carpeta antigua de nombre parecido.
- El índice local contiene las 60 entradas de S03, pero su columna de afinidades no refleja completa la matriz V0.4 y contiene dos diferencias directas: Oscuridad en Insectoides y Neutral en Gigantes.
- Los nombres y recetas de F001–F125 ya procedían de S04. Las cifras y habilidades de las ocho Fusiones jugables son extensiones locales, no valores de S04.
- El límite local provisional de una Fusión por jugador y turno contradice la declaración de S04 de que no existe un límite universal.
- Los nombres de M01–M18, G01–G07, T01–T06 y parte de E01–E06 son propuestas locales compatibles en general; anatomías, disciplinas y aptitudes adicionales deben ratificarse individualmente.
- S05 contiene P01 Vagabundo, P02 Señor/Rey de las Cartas, P03 Invocador de Bestias, P04 Señor de la Tormenta/Trueno, P05 Maese del Risco y P06 reservado.

Archivos creados o modificados en esta auditoría:

- `docs/diseno/AUDITORIA_RECONCILIACION_DRIVE_CONTENIDO_LOCAL_V0_1.md`;
- `docs/fuentes_diseno/README.md`;
- los cuatro cuadernos vivos.

No se modificaron motor, UCE, mesa, interfaz, reglas implementadas, cartas, cifras, habilidades, balance ni Fusiones implementadas. El Atlas nuevo queda detenido.

## 2026-09-15 — Resincronización del repositorio existente con el proyecto local

- Se revisaron `AGENTS.md`, el índice de cuadernos, los cuatro cuadernos, el estado local/remoto y las exclusiones antes de preparar el envío. El local estaba tres commits por delante de `origin/main`, sin divergencia.
- Antes de modificar `main` remoto se creó y comprobó `backup/pre_sync_local_actual_20260915` en GitHub, apuntando al antiguo `b0cc5dad3b2d35193c4626be966518964ccaf3f8`.
- Se incorporan el trabajo local vigente y los documentos recientes de fuentes, reconciliación, balance, mesa, pruebas y cuadernos. Se ignoran las copias físicas `artifacts/backup_*`, `.godot`, importaciones PNG y temporales; se versionan los `.gd.uid` estables.
- La importación con Godot 4.7 pasó. Las 26 suites específicas del juego pasaron; las diez suites de interacción gráfica pasaron en modo gráfico (dos no eran válidas bajo `--headless` por depender del renderizado). Pasaron además nueve suites UCE, diagnóstico 15/15, experimento integral 80/80 y caché de fuentes 6/6.
- Se registra el envío a `main` mediante el commit `chore: resync repository with current local project`, sin pull, merge, eliminación de historial, modificación de Zapity principal ni cambio de reglas. El SHA final se obtiene del propio `main` publicado.


## 2026-09-19 — PREH-VIS-01 / ONB-01: vertical slice antes de la prueba humana

Motivo:

- Tras cerrar UX #1–#12 y congelar H1–H7, se detectó que entregar la mesa a una persona externa seguía siendo una prueba inválida: las cartas y el tablero conservaban aspecto de greybox y faltaba onboarding.
- Se bloqueó explícitamente UX #13 hasta construir una presentación mínima que separase incomprensión visual de fallos reales de interacción.

Cambios principales:

- `demo/card_art_placeholder.gd`: arte procedural determinista por tipo/elemento y monograma de identidad.
- `demo/card_tile.gd`: usa la identidad gráfica provisional y marca cartas con efecto en mano.
- `demo/prehuman_onboarding.gd`: guía de seis páginas sobre reglas/vocabulario sin secuencia procedural de clics.
- `demo/juego_cartas_table.gd`: botón `GUÍA`, integración del onboarding y aislamiento cuando la mesa se instancia dentro de tests/herramientas.
- `demo/field_template_layer.gd`: rótulos `APOYOS RIVAL`, `CRIATURAS RIVAL`, `TUS CRIATURAS`, `TUS APOYOS`, anclados antes de las zonas laterales sin añadir nodos que alteren la malla.
- `tests/run_jcp_table_presentation_preflight.gd`: nueva puerta de presentación.
- `tools/capture_manual_table.gd` y workflow: captura reproducible de onboarding y mesa como artefacto CI.

Incidencias corregidas durante el PR:

- El primer arte procedural no compiló bajo warnings estrictos por inferencia `Variant`; se tiparon explícitamente las variables.
- El primer posicionamiento de rótulos invadía FUSIÓN/TERRITORIO; se pasó a calcular su posición desde `side_corners()`.
- El onboarding autoabierto bloqueó `ATTACK_GUI` bajo `xvfb`; se cambió para autoabrirse solo cuando la mesa es la escena principal real y la herramienta de capturas lo abre de forma explícita.

Cierre:

- PR #10 fusionado por squash.
- `main @ afa92a02d7a1397ff8e0481408f11e173c61a1aa`.
- workflow `35437896191`: seis jobs SUCCESS.
- `PRESENTATION_PREFLIGHT PASS: 11 checks`.
- `HUMAN_PREFLIGHT PASS: 11 checks` con H4=4 / R03+R02 y el resto de fixtures conservados.
- `GEOMETRY_HITBOX PASS: 18`, `CLICK_BUDGET PASS: 18`, `FUSION_GUI PASS`; fusion-vertical SUCCESS.
- Capturas finales revisadas: onboarding legible, bandas sin solapamientos y cartas distinguibles a nivel provisional.

Siguiente: ejecutar prueba humana; no ampliar arte final ni balancear antes de observarla.
