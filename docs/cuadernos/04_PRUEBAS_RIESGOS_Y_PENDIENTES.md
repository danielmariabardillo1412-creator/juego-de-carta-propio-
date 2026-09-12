# Cuaderno 4 — Pruebas, riesgos y pendientes

Última ejecución completa: **2026-09-11 — PASS**

## Fase visual abierta 2026-09-12 — PENDIENTE DE CONSOLIDACIÓN Y VERIFICACIÓN

- Rama: `chatgpt/greybox-ui-v1`.
- La escena `demo/juego_cartas_table.tscn` apunta en esta rama a `demo/juego_cartas_table_greybox.gd`, que hereda la mesa funcional anterior y cambia únicamente presentación y jerarquía visual.
- Se añadió `demo/duel_table_backdrop_greybox.gd` y el contrato `docs/diseno/GREYBOX_INTERFAZ_FINAL_V0_1.md`.
- Antes de seguir puliendo esa implementación por ensayo visual se creó `docs/diseno/CUADERNO_BENCHMARK_INTERFAZ_TCG_V0_1.md`. El greybox escrito queda considerado **andamio provisional** hasta consolidar las medidas, estados e interacciones que se acepten de ese benchmark.
- El benchmark comercial ya cubre Yu-Gi-Oh!/Master Duel, MTG Arena, Legends of Runeterra, Shadowverse, Pokémon TCG, Marvel Snap, Flesh and Blood, Disney Lorcana, Shadowverse: Evolve, Eternal, Hearthstone, GWENT, Duel Links y Pokémon TCG Pocket. Las referencias se usan por problema concreto y no como una interfaz a copiar.
- Se añadió `docs/diseno/CUADERNO_BENCHMARK_COMUNIDAD_Y_FOROS_V0_1.md` para contrastar esa base con feedback de jugadores en Reddit, Steam Community y BoardGameGeek. Solo pasan al diseño candidatas realistas para UI 2D/2.5D y datos del motor; cinemáticas 3D y VFX complejos quedan fuera del alcance actual.
- Las joyas comunitarias de mayor interés son: efectos activos con fuente/duración, texto estructurado, usos restantes visibles, menos clics sin elección real, inspección del tablero durante decisiones, cancelación antes del commit y una futura explicación `¿por qué no puedo?` procedente de UCE.
- `UniversalCardEngine`, `juego_cartas_propio_module.gd`, catálogo, reglas, replay y persistencia no se han modificado durante esta investigación.
- Los resultados PASS del 2026-09-11 siguen siendo la última autoridad cerrada del motor y de la mesa anterior; **no se atribuyen al greybox V0.1 ni a los benchmarks documentales**.
- Esta conexión no dispone del Godot 4.7 local del proyecto ni de ejecución gráfica del PC, por lo que todavía no existe una captura runtime revisada de esta versión.

Puertas mínimas antes de cerrar la fase:

1. cruzar benchmark comercial + benchmark comunitario + reglas propias y clasificar cada propuesta como **obligatoria antes de prueba humana**, **deseable después del greybox** o **futura**;
2. consolidar el resultado en un estándar de interfaz: proporción de carta, unidad `U`, tamaños relativos, gramática de estados, mano/campo/HUD, respuesta/cadena, equipo, Terreno, Fusión, texto y comportamiento pre-commit;
3. trasladar únicamente la síntesis aceptada a `GREYBOX_INTERFAZ_FINAL_V0_1.md` y adaptar el andamio de código a ese estándar;
4. cargar `demo/juego_cartas_table.tscn` en Godot 4.7 sin error de parser/runtime;
5. `run_juego_cartas_propio_manual_table.gd`;
6. `run_juego_cartas_propio_table_attack_flow.gd`;
7. `run_juego_cartas_propio_basic_ai.gd`;
8. vertical de criaturas 38/38 y vertical de ocho Fusiones 82/82 como regresión proporcional de interacción;
9. captura gráfica de la mesa —preferentemente 1600×900— y revisión humana de jerarquía, proporciones, mano, campo, lateral, fases, destinos legales y claridad de decisiones;
10. si la captura revela problemas estructurales, corregirlos con el estándar como autoridad y repetir las puertas afectadas antes de iniciar una partida humana completa.

## Cola vigente desde 2026-09-12

Esta cola sustituye temporalmente el orden anterior que empezaba directamente por una partida humana completa o por pulir el primer greybox a ojo.

1. Consolidar ambos cuadernos de benchmark en tres grupos: imprescindible para la primera prueba humana, siguiente corte de UX y futuro/aparcado.
2. Cerrar los parámetros restantes del estándar: lateral/overlay, densidad de mano, mini-cadena, previsión pública, texto estructurado, señales de usos y punto de commit.
3. Convertir la síntesis aceptada en un estándar de interfaz con proporciones y estados cerrados, evitando números aislados sin relación entre sí.
4. Actualizar `GREYBOX_INTERFAZ_FINAL_V0_1.md` y adaptar el andamio actual a ese estándar.
5. Verificar parser/runtime y pruebas proporcionales del greybox consolidado.
6. Abrir la escena gráficamente, obtener una captura real y revisar si representa suficientemente la futura experiencia sin arte definitivo.
7. Corregir solo problemas estructurales reproducibles; no volver al diseño por retoques arbitrarios.
8. Solo entonces realizar una sesión humana completa y registrar problemas observables de comodidad, claridad y ritmo.
9. Mantener las pruebas verticales de criaturas y de las ocho Fusiones como puertas al tocar interacción, combate o catálogo.
10. Tras estabilizar layout, valorar una fase propia para `¿por qué no puedo?` y `EFECTOS ACTIVOS`, ampliando UCE si hace falta sin duplicar reglas en la UI.
11. Recoger en partidas los indicadores definidos por la auditoría métrica de F001/F067 antes de ajustar cifras.
12. Después: alcance mínimo del narrador/locutor, prueba pequeña de efectos latentes, bots específicos, red, arte definitivo e integración con Zapity.

## Investigación documental de comunidad — 2026-09-12

- No se ejecutaron pruebas runtime porque no cambió código ni contrato ejecutable.
- La investigación comunitaria no se considera evidencia cuantitativa de preferencias universales: son patrones cualitativos repetidos en discusiones de jugadores y se filtran por aplicabilidad a JCP.
- JCP-DEC-042 impide que una sugerencia de foro altere por sí sola reglas del duelo.
- Cualquier implementación de `¿por qué no puedo?` debe obtener la causa desde UCE o desde los mismos códigos de validación; una segunda lógica de reglas en UI sería un fallo de arquitectura.
- Cualquier vista `EFECTOS ACTIVOS` debe respetar el mismo saneado de información que las vistas existentes: no puede revelar cartas preparadas, identidad privada de M12, materiales ocultos o procedencias no públicas.
- Cancelar antes del commit es una operación puramente de interfaz; no puede transformarse en undo de acciones ya resueltas sin una decisión expresa sobre privacidad/replay/multijugador.

## Ejecución larga completada — PASS

- Run id: `long_20260911_073150`; estado e informe final persistentes en `diagnostic_logs/`.
- Ocho lotes completaron 10.000/10.000 partidas, semillas 1.000.000–1.009.999, con ocho perfiles incluidos agotamiento acelerado, prioridad de Fusión, caos de equipo y juego oculto/reactivo.
- La muestra posterior completó 25/25 partidas por `UniversalCardEngine`, semillas 1.010.000–1.010.024, con dos replays completos exactos.
- Resultado del run: 10.025 partidas, 907.265 acciones y cero fallos del motor. Acumulado de las dos puertas posteriores a correcciones: 12.135 partidas y 1.044.565 acciones.
- El `FAIL` transitorio del coordinador fue falso: los ocho JSON declaraban PASS. Se corrigió para usar los informes del proceso real en vez del código no representativo del wrapper de consola.

## Pruebas específicas del juego

Ejecutar desde la raíz del laboratorio con Godot 4.7:

```text
godot --headless --path . --script res://tests/run_juego_cartas_propio_phases.gd
godot --headless --path . --script res://tests/run_juego_cartas_propio_zones.gd
godot --headless --path . --script res://tests/run_juego_cartas_propio_summon.gd
godot --headless --path . --script res://tests/run_juego_cartas_propio_postures.gd
godot --headless --path . --script res://tests/run_juego_cartas_propio_combat.gd
godot --headless --path . --script res://tests/run_juego_cartas_propio_field_cards.gd
godot --headless --path . --script res://tests/run_juego_cartas_propio_effects.gd
godot --headless --path . --script res://tests/run_juego_cartas_propio_reactions.gd
godot --headless --path . --script res://tests/run_juego_cartas_propio_spell_reactions.gd
godot --headless --path . --script res://tests/run_juego_cartas_propio_trigger_reactions.gd
godot --headless --path . --script res://tests/run_juego_cartas_propio_artifacts.gd
godot --headless --path . --script res://tests/run_juego_cartas_propio_terrain_combinations.gd
godot --headless --path . --script res://tests/run_juego_cartas_propio_compatibility_profiles.gd
godot --headless --path . --script res://tests/run_juego_cartas_propio_fusion_foundation.gd
godot --headless --path . --script res://tests/run_juego_cartas_propio_fusion_catalog.gd
godot --headless --path . --script res://tests/run_juego_cartas_propio_fusion_action.gd
godot --headless --path . --script res://tests/run_juego_cartas_propio_fusion_combat_effects.gd
godot --headless --path . --script res://tests/run_juego_cartas_propio_fusions_vertical.gd
godot --headless --path . --script res://tests/run_juego_cartas_propio_creature_automatic_abilities.gd
godot --headless --path . --script res://tests/run_juego_cartas_propio_creature_active_abilities.gd
godot --headless --path . --script res://tests/run_juego_cartas_propio_creature_abilities_vertical.gd
godot --headless --path . --script res://tests/run_juego_cartas_propio_manual_table.gd
godot --headless --path . --script res://tests/run_juego_cartas_propio_basic_ai.gd
godot --headless --path . --script res://tests/run_juego_cartas_propio_table_attack_flow.gd
```

Último cierre total: **1.357/1.357 comprobaciones** en veintidós suites antes de ampliar la interfaz. La batería contiene ahora veinticuatro suites; las afectadas por esta fase se han ejecutado por separado.

Comprobación del corpus de diseño:

```powershell
powershell -ExecutionPolicy Bypass -File tools/check_design_source_cache.ps1
```

Regresiones generales: **441/441 comprobaciones** en las nueve suites UCE.

## Puertas generales

```text
godot --headless --path . --script res://tests/diagnostics/run_engine_diagnostics.gd
godot --headless --path . --script res://tests/full/run_complete_engine_experiment.gd
```

Resultado vigente:

- diagnóstico: **15 PASS, 0 FAIL, 0 SKIP, 0 WARN**;
- experimento integral: **80 comprobaciones superadas**.

## Riesgos conocidos

1. La cadena actual admite varias activaciones, pero las cartas implementadas no producen aún una contrarespuesta útil del jugador fuente. Al añadirla habrá que probar alternancia múltiple y objetivos que desaparezcan.
2. Una Magia pendiente permanece internamente en la mano hasta resolverse o ser anulada; la vista pública solo expone su definición. Una futura interfaz no debe volver a presentarla como carta desconocida después del evento de activación.
3. T04 revierte la postura, pero no deshace el cambio voluntario ni el disparo previo de G05. Esta semántica está consolidada; cualquier cambio futuro exige una decisión expresa.
4. T05 deja que el equipo llegue a vincularse antes de destruirlo; ningún otro jugador puede ejecutar acciones ordinarias mientras la respuesta está pendiente.
5. T06 se resuelve después del combate y no recalcula el daño ya aplicado.
6. E04 se contabiliza una vez por copia activa y turno. Si el diseño final pretende un único uso global aunque haya dos copias, habrá que cambiar la regla expresamente.
7. Solo existe un Terreno físico activo por jugador. Las seis identidades transformadas funcionan, pero sus efectos mecánicos siguen pendientes de definición y por ahora no aplican bonos.
8. La mesa permite colocación directa, objetivos simples y elección directa de los dos materiales de Fusión. Redirecciones y otras decisiones excepcionales con varias piezas aún recurren al panel lateral; no existe adaptación a red.
9. Las definiciones y valores son provisionales; una prueba correcta demuestra coherencia con la regla actual, no equilibrio competitivo.
10. Las ocho Fusiones actuales comparten materiales, casilla, equipo, vistas, eventos y destinos. Las habilidades base ya están cubiertas, pero no se heredan por la carta portadora de una Fusión.
11. Las criaturas ya tienen anatomía concreta, pero E02 y E05 siguen sin restricciones anatómicas. Añadirlas requerirá una decisión separada sobre qué cuerpos pueden vestir cada protección sin invalidar la baraja didáctica.
12. El narrador/locutor tiene límites claros —solo describe resultados calculados—, pero carece todavía de un catálogo cerrado de mensajes y eventos.
13. Las copias locales pueden quedar obsoletas si se modifica Drive. Antes de una fase de diseño debe compararse `modified_time` y resincronizar únicamente las fuentes afectadas.
14. F001, F005, F010, F011, F012, F018, F067 y F068 son jugables. F005 no hereda habilidades ni aptitudes por unión: su perfil Alado/Bestial sin Manipulador es provisional explícito, no una afirmación sobre el diseño histórico.
15. La versión 0.13.0 endurece el esquema de criaturas. Guardados de una versión anterior que conserven definiciones con anatomía `unassigned` no deben cargarse como si fueran estados 0.13.0 válidos; la política de migración se abordará cuando exista persistencia de partidas de usuario.
16. `MANIFEST.json` continúa congelado en la baseline universal. La comprobación actual informa siete hashes distintos y ningún archivo ausente; debe regenerarse únicamente después de superar las puertas runtime de la nueva versión.
17. Las conversaciones originales contienen decisiones más detalladas sobre efectos latentes y excepciones que quedaron resumidas en S00/S01. Ya existe un contrato local recuperado, pero las cartas concretas deberán diseñarse y probarse antes de considerarlas jugables.
18. Una excepción de carta no puede mutar reglas de forma implícita: debe declarar alcance, duración, destinos, información visible y prioridad para conservar replay, privacidad y determinismo.
19. La representación actual usa el primer material enviado por la acción como portador físico. La mesa presenta la identidad de Fusión; los futuros componentes de carta deben conservarla y no inducir a pensar que el material mantiene su identidad individual.
20. La separación voluntaria y las Fusiones encadenadas están deliberadamente deshabilitadas. No deben inferirse a partir del servicio puro hasta diseñar capacidad de casillas, selección, eventos y excepciones.
21. La elección de F067 añade un paso obligatorio previo a respuestas. La mesa la recibe como acción legal; los bots futuros también deberán resolver `choose_fusion_combat_bonus` y no tratarla como una ventana que admita pasar.
22. F012 permite un modificador base negativo antes de respuestas. Las futuras penalizaciones deben respetar el límite −5…+5 y el cálculo final continúa acotando ATQ a cero.
23. F068 añade un objetivo opcional solo cuando no existe enemigo visible y un efecto que cruza turnos. Toda futura retirada, transformación o control temporal debe limpiar o reasignar explícitamente esa duración.
24. F018 guarda el turno global de su regeneración. Su paso forzado a guardia no activa reglas de cambio voluntario y T06 puede destruirlo después; cualquier nueva prevención debe distinguir destrucción de combate de destrucción por efecto.
25. La mesa mantiene privada la identidad inspeccionada por M12; cualquier presentación futura debe conservar que el evento público solo indica que hubo inspección.
26. M13 introduce una decisión obligatoria del defensor antes de las respuestas ordinarias. Interfaz y bots deben ofrecer aceptar o rechazar y, si se redirige, reconstruir las opciones de trampa contra el nuevo objetivo.
27. La primera prueba humana detectó que la antigua lista no comunicaba una mesa. El flujo visual aprobado ya resuelve fases administrativas, acciones duplicadas, casillas equivalentes, historial y fin rápido; sigue pendiente una partida humana completa sobre una interfaz representativa para medir claridad real.
28. La derrota por baraja agotada está cerrada y probada mediante un recorrido largo. Las futuras cartas que eviten, sustituyan o castiguen el robo deberán declarar expresamente si alteran este desenlace.
29. Ataque inmediato no significa entrada universal sin restricciones: solo la invocación normal boca arriba lo permite. El primer turno inicial, la colocación oculta y la Fusión recién formada conservan sus prohibiciones específicas.
30. La matriz de trazabilidad cubre las decisiones cerradas del núcleo S01, pero no convierte sus apartados abiertos en requisitos implementables. Toda ampliación deberá conservar esa separación.
31. El greybox V0.1 hereda una mesa grande y sobreescribe construcción visual; cualquier incompatibilidad de herencia, acceso a miembros o llamada `super` debe detectarse en Godot antes de considerarlo una base válida.
32. Una interfaz visualmente más limpia no puede ocultar decisiones obligatorias, prioridad, privacidad ni destinos legales. La reducción de texto es solo de presentación; las mismas acciones deben seguir siendo alcanzables y verificables.
33. El benchmark debe reutilizar **principios funcionales**, no la identidad de un producto. Copiar marcos, iconos distintivos, ornamentación, composición reconocible o assets ajenos convertiría una referencia legítima en una dependencia visual que no se desea.
34. Si las medidas vuelven a fijarse como números de píxeles independientes, reaparecerán incoherencias entre mano, campo, guardia, preview y resoluciones. La siguiente implementación debe derivarlas de la proporción de carta y de una unidad común `U`, con excepciones explícitas y justificadas.
35. Una futura vista `EFECTOS ACTIVOS` puede convertirse en fuga de información si deduce fuentes ocultas. Debe construirse desde una vista saneada del jugador correspondiente y mostrar únicamente causa/duración que las reglas permitan conocer.
36. La función `¿por qué no puedo?` sería peligrosa si la UI reimplementa validación: produciría mensajes que pueden divergir de `get_legal_actions()`/`validate_action()`. Debe pertenecer al contrato de UCE o derivarse de sus mismos códigos.
37. El deseo comunitario de “menos prompts” no autoriza automatizar decisiones opcionales. Solo se eliminan confirmaciones redundantes o pasos sin elección real; prioridad, respuestas y elecciones reglamentarias continúan perteneciendo al jugador.
38. El cancelado pre-commit debe permanecer puramente local. Un undo posterior a una acción resuelta puede revelar o borrar información y necesitaría una arquitectura separada para replay/PvP; no se incluye en el greybox.
39. Las sugerencias de foros son evidencia cualitativa y sesgada hacia quienes participan. Se usarán para descubrir problemas y soluciones candidatas, no como encuesta representativa ni como autoridad superior a las pruebas humanas propias.
40. Añadir cada mejora de QoL simultáneamente podría volver a sobrecargar la mesa. La consolidación debe fijar qué entra en la primera prueba y qué se pospone aunque sea una buena idea.

## Cola ordenada — histórica hasta 2026-09-11

1. Realizar una sesión humana completa con `FLUJO_DE_PARTIDA_E_INTERACCION_V0_1.md` ya implementado y registrar problemas observables de comodidad, claridad o ritmo.
2. Corregir únicamente los problemas reproducibles de esa sesión antes de ampliar arte o contenido.
3. Mantener las pruebas verticales de criaturas y de las ocho Fusiones como puertas al tocar interfaz, combate o catálogo.
4. Recoger en partidas los indicadores definidos por la auditoría métrica de F001/F067; la sonda bruta desaconseja restringir o reducir antes de observar preparación, respuestas y permanencia.
5. Cerrar en una fase separada el alcance mínimo del narrador/locutor y sus mensajes mecánicos accesibles.
6. Diseñar una prueba posterior y pequeña de efectos latentes —Terreno, destrucción y Fusión— sin incorporarla al primer trío.
7. Solo después: bots específicos, red, arte definitivo e integración con Zapity.

## Verificación proporcional de la mesa visual — 2026-09-11

- Rediseño estructural 2,5D posterior a la primera prueba humana: mesa manual 78/78, flujo de ataque 11/11, rival automático 9/9, vertical de criaturas 38/38 y vertical de ocho Fusiones 82/82.
- Selección prematura de objetivo antes de Combate, objetivo oculto por casilla y limpieza posterior al ataque quedan cubiertos por la suite nueva.
- Escena principal headless: PASS; tres capturas gráficas reproducibles a 1600×900: PASS; fuentes locales 6/6; auditoría estática: 26.333 comprobaciones sobre 97 GDScript, cero fallos.

- Revisión de flujo aprobada: mesa manual 70/70, rival automático 9/9, vertical de criaturas 38/38 y vertical de ocho Fusiones 82/82.
- Inicio/Robo automáticos, final rápido, lateral no duplicado, historial plegado, tarjetas por tipo/elemento, montones auxiliares, equipo bajo portador, Fusión directa y aviso de Terreno cubiertos por parser/runtime o recorrido visual.
- Escena principal headless: PASS; captura gráfica reproducible a 1280×720: PASS; auditoría estática: 25.703 comprobaciones sobre 95 GDScript, cero fallos.

- Mesa manual actual: 65/65, incluidas veinte casillas permanentes, señales reales de selección/colocación y elección central de ataque o guardia.
- Rival automático básico: 9/9; completa un turno real, no entra en bucle, conserva la vista humana y devuelve el control.
- Vertical de criaturas: 38/38.
- Vertical de ocho Fusiones: 82/82.
- Escena principal headless: PASS.
- Captura gráfica reproducible a 1280×720: PASS, revisada sin recortes críticos.
- Auditoría estática: 25.392 comprobaciones sobre 95 archivos GDScript, cero fallos.
- No se modificó el módulo principal ni se atribuye a esta fase un nuevo cierre total de las veintidós suites.

## Ejecución completa 0.24.0 y estrés automático — 2026-09-11

- Barrido limpio acumulado posterior a correcciones: 12.135 partidas y 1.044.565 acciones reproducibles.
- La ampliación larga aportó 10.000 partidas contra el módulo y 25 mediante UCE: 907.265 acciones, dos replays completos, 55 finales por baraja vacía y 470 empates simultáneos.
- Cobertura dinámica destacada: 931 Fusiones, 7.770 ataques, 2.767 respuestas activadas, 379 elecciones de F067, 83 redirecciones de M13 y 275 traslados de equipo.
- El barrido descubrió y permitió corregir dos falsos legales: cambio de postura después de atacar y uso anunciado de una Fusión previa como material cuando las cadenas están deshabilitadas.
- Veintidós suites específicas: 1.357/1.357; posturas 69/69; acción de Fusión 72/72; mesa manual 55/55.
- Nueve suites UCE: 441/441; diagnóstico 15/15; experimento integral 80/80; escena principal headless PASS.
- Auditoría estática: 24.709 comprobaciones sobre 93 archivos GDScript, cero fallos. Fuentes locales 6/6.
- Integridad histórica: 100 archivos comprobados, cero ausentes, siete diferencias conocidas y cero errores; manifiesto sin regenerar.

## Ejecución completa 0.23.0 y ataque al invocar — 2026-09-11

- Veintidós suites específicas: 1.341/1.341; invocación 32/32; fases y finales 48/48; mesa manual 55/55.
- Se comprueban ataque inmediato normal, prohibición del primer turno inicial y prohibición de la Fusión recién formada mediante acciones legales y validación directa.
- Nueve suites UCE: 441/441; diagnóstico 15/15; experimento integral 80/80; escena principal headless PASS.
- Auditoría estática final: 23.969 comprobaciones sobre 91 archivos GDScript, cero fallos. Fuentes locales 6/6.
- Integridad histórica: 100 archivos comprobados, cero ausentes, siete diferencias conocidas y cero errores; manifiesto sin regenerar.

## Ejecución completa 0.22.0 y derrota por baraja agotada — 2026-09-11

- Veintidós suites específicas: 1.325/1.325; fases y finales 48/48; mesa manual 55/55.
- El recorrido de agotamiento consume las barajas completas, termina al intentar el robo obligatorio, declara ganador, publica el evento y reproduce exactamente la instantánea.
- Nueve suites UCE: 441/441; diagnóstico 15/15; experimento integral 80/80; escena principal headless PASS.
- Auditoría estática: 23.779 comprobaciones sobre 90 archivos GDScript, cero fallos. Fuentes locales 6/6.
- Integridad histórica: 100 archivos comprobados, cero ausentes, siete diferencias conocidas y cero errores; manifiesto sin regenerar.

## Mesa manual local sobre 0.21.0 — 2026-09-11

- Veintidós suites específicas: 1.316/1.316; mesa manual 55/55 y habilidades activas 39/39 tras cerrar la fuga de M13.
- Nueve suites UCE: 441/441; diagnóstico 15/15; experimento integral 80/80; escena principal headless PASS.
- Render determinista de la escena principal: 1280×720, OpenGL 3.3, un fotograma revisado sin desbordamientos críticos.
- Auditoría estática: 23.709 comprobaciones sobre 90 archivos GDScript, cero fallos. Fuentes locales 6/6.
- Integridad histórica: 100 archivos comprobados, cero ausentes, siete diferencias conocidas y cero errores; manifiesto sin regenerar.
- La escena principal cambia de bootstrap diagnóstico a mesa local con componentes seleccionables, acciones contextuales, detalle, resultado y ranura persistente. El diagnóstico sigue ejecutándose directamente mediante su suite y escena dedicada.

## Ejecución completa 0.21.0 y habilidades M01–M18 — 2026-09-11

- Veintiuna suites específicas: 1.259/1.259; automáticas 25/25, activas 37/37 y verticales de criaturas 38/38 con replay exacto.
- Catálogo de Fusión 59/59; acción 70/70; efectos de combate 131/131; vertical de ocho Fusiones 82/82.
- Nueve suites UCE: 441/441; diagnóstico 15/15; experimento integral 80/80; escena principal headless PASS.
- Auditoría estática: 22.462 comprobaciones sobre 87 archivos GDScript, cero fallos. Fuentes locales: 6/6; S01 y S03 sin cambios en Drive.
- Integridad histórica: 100 archivos comprobados, cero ausentes y siete diferencias conocidas; no se regeneró el manifiesto.

## Ejecución completa 0.20.0 y octava Fusión — 2026-09-10

- Dieciocho suites específicas: 1159/1159.
- Catálogo: 59/59; acción: 70/70; efectos de combate: 131/131; vertical de ocho Fusiones: 82/82 con replay exacto.
- Nueve suites UCE: 441/441; diagnóstico 15/15; experimento integral 80/80; escena principal headless PASS.
- Auditoría estática: 21.328 comprobaciones sobre 84 archivos GDScript, cero fallos. Fuentes locales: 6/6; S01 y S04 sin cambios en Drive.
- F005 probada contra tercer ataque, entrada, igualdad, ataque directo, destrucción mutua, regeneración de Troll, cancelación G07, prioridad T06, limpieza, expiración y marcadores corruptos.
- El perfil corporal de F005 queda provisional y la habilidad propia de M18 necesita una fase separada. Las ocho Fusiones no equivalen a la baraja completa ni a una interfaz jugable.

## Ejecución completa 0.19.0 y séptima Fusión — 2026-09-10

- Dieciocho suites específicas: 1102/1102.
- Catálogo: 50/50; acción: 70/70; efectos de combate: 94/94; vertical de siete Fusiones: 71/71 con replay exacto.
- Nueve suites generales: 441/441.
- Diagnóstico: 15/15; experimento integral: 80/80; escena principal headless: PASS.
- Auditoría estática: 21.036 comprobaciones sobre 84 archivos GDScript, cero fallos. Fuentes locales: 6/6.
- Godot: 4.7.stable.official.5b4e0cb0f desde `C:/Godot/4.7`.

## Verificación documental de 2026-09-09

- Fuentes locales: PASS 6/6; IDs y fechas S01–S04 coincidentes con Drive.
- Auditoría estática más reciente: PASS, 18.004 comprobaciones sobre 79 archivos GDScript.
- Runtime Godot: no necesario; la candidata de código fue retirada y el módulo regresó exactamente a su versión funcional 0.12.0.
- La baraja documental contiene exactamente 18 M, 7 G, 6 T, 6 E y 3 R, más ocho entidades de Fusión externas al mazo.
- Los únicos cambios vigentes de esta fase son documentación, identidades propuestas, auditoría matemática y organización de contenido.

## Verificación de identidades runtime 0.13.0 — 2026-09-09

- Frescura: IDs y fechas S01–S04 coinciden exactamente con `SOURCE_MANIFEST.json`.
- Fuentes locales: PASS 6/6.
- Auditoría estática: PASS, 18.107 comprobaciones sobre 79 archivos GDScript.
- Suite modificada: `run_juego_cartas_propio_compatibility_profiles.gd`.
- Runtime: pendiente; no se encontró `godot`, `godot4` ni `godot.exe` en `PATH`.
- El cierre histórico de 752/752 específicas, 441/441 generales, 15/15 diagnóstico y 80/80 integral pertenece a 0.12.0 y no se atribuye a 0.13.0.

## Verificación del catálogo F010 — 2026-09-09

- Frescura: IDs y fechas S01–S04 coinciden exactamente con `SOURCE_MANIFEST.json`.
- Fuentes locales: PASS 6/6.
- Auditoría estática final: PASS, 18.523 comprobaciones sobre 81 archivos GDScript.
- Suite nueva: `run_juego_cartas_propio_fusion_catalog.gd`.
- Runtime: PASS con F001, F010 y F067; suite de catálogo 37/37, fundamento 46/46 e identidades 157/157.
- Integridad de paquete: FAIL esperado por manifiesto histórico, con 7 hashes distintos, 0 ausentes y 0 errores de lectura.

## Ejecución completa 0.13.0 y catálogo inicial — 2026-09-09

- Quince suites específicas: 850/850.
- Nueve suites generales: 441/441.
- Diagnóstico: 15/15.
- Experimento integral: 80/80.
- Scripts de prueba: 26; fallos: 0. Escena principal headless: PASS.
- Godot: 4.7.stable.official.5b4e0cb0f.

## Ejecución completa 0.14.0 y F010 jugable — 2026-09-09

- Dieciséis suites específicas: 910/910.
- Suite F010: 56/56; zonas ampliadas: 62/62.
- Nueve suites generales: 441/441.
- Diagnóstico: 15/15; experimento integral: 80/80; escena principal headless: PASS.
- Auditoría estática: 19.265 comprobaciones sobre 82 archivos GDScript, cero fallos.
- Fuentes locales: 6/6.
- Integridad histórica: 100 archivos revisados, 0 ausentes, 7 hashes distintos y 0 errores; `MANIFEST.json` no se regeneró.
- Godot: 4.7.stable.official.5b4e0cb0f desde `C:/Godot/4.7`.

## Ejecución completa 0.15.0 y tres Fusiones jugables — 2026-09-09

- Diecisiete suites específicas: 952/952.
- Acción/ciclo de Fusión: 58/58; efectos de combate F001/F067: 40/40.
- Nueve suites generales: 441/441.
- Diagnóstico: 15/15; experimento integral: 80/80; escena principal headless: PASS.
- Auditoría estática: 19.850 comprobaciones sobre 83 archivos GDScript, cero fallos.
- Fuentes locales: 6/6.
- Godot: 4.7.stable.official.5b4e0cb0f desde `C:/Godot/4.7`.

## Ejecución completa 0.15.1 y prueba vertical — 2026-09-09

- Dieciocho suites específicas: 973/973.
- Prueba vertical de las tres Fusiones: 21/21, con replay exacto del snapshot runtime.
- Nueve suites generales: 441/441.
- Diagnóstico: 15/15.
- Experimento integral: 80/80; escena principal headless: PASS.
- Auditoría estática: 20.120 comprobaciones sobre 84 archivos GDScript, cero fallos.
- Godot: 4.7.stable.official.5b4e0cb0f desde `C:/Godot/4.7`.

## Ejecución completa 0.16.0 y cuarta Fusión — 2026-09-09

- Dieciocho suites específicas: 990/990.
- Catálogo: 39/39; acción de Fusión: 61/61; efectos de combate: 52/52; prueba vertical del primer trío: 21/21.
- Nueve suites generales: 441/441.
- Diagnóstico: 15/15; experimento integral: 80/80; escena principal headless: PASS.
- Auditoría estática: 20.238 comprobaciones sobre 84 archivos GDScript, cero fallos.
- Godot: 4.7.stable.official.5b4e0cb0f desde `C:/Godot/4.7`.

## Puerta vertical ampliada de 0.16.0 — 2026-09-10

- Dieciocho suites específicas: 1003/1003.
- Prueba vertical de las cuatro Fusiones: 34/34, incluidos F011, consistencia interna y replay exacto.
- Nueve suites generales: 441/441.
- Diagnóstico: 15/15; experimento integral: 80/80; escena principal headless: PASS.
- Auditoría estática: 20.340 comprobaciones sobre 84 archivos GDScript, cero fallos. Fuentes locales: 6/6.
- Godot: 4.7.stable.official.5b4e0cb0f desde `C:/Godot/4.7`.

## Ejecución completa 0.17.0 y quinta Fusión — 2026-09-10

- Dieciocho suites específicas: 1032/1032.
- Catálogo: 42/42; acción: 64/64; efectos de combate: 62/62; vertical de cinco Fusiones: 47/47 con replay exacto.
- Nueve suites generales: 441/441.
- Diagnóstico: 15/15; experimento integral: 80/80; escena principal headless: PASS.
- Auditoría estática: 20.509 comprobaciones sobre 84 archivos GDScript, cero fallos. Fuentes locales: 6/6.
- Godot: 4.7.stable.official.5b4e0cb0f desde `C:/Godot/4.7`.

## Ejecución completa 0.18.0 y sexta Fusión — 2026-09-10

- Dieciocho suites específicas: 1065/1065.
- Catálogo: 45/45; acción: 67/67; efectos y duración: 77/77; vertical de seis Fusiones: 59/59 con replay exacto.
- Nueve suites generales: 441/441.
- Diagnóstico: 15/15; experimento integral: 80/80; escena principal headless: PASS.
- Auditoría estática: 20.774 comprobaciones sobre 84 archivos GDScript, cero fallos. Fuentes locales: 6/6.
- Godot: 4.7.stable.official.5b4e0cb0f desde `C:/Godot/4.7`.

## Criterio de cierre de una fase

Una fase no está cerrada hasta que:

- el estado valida antes y después de cada acción;
- las acciones rechazadas son atómicas;
- vistas y eventos respetan privacidad;
- replay y persistencia siguen pasando;
- todas las suites afectadas y las puertas generales terminan realmente en PASS;
- los cuatro cuadernos quedan actualizados.