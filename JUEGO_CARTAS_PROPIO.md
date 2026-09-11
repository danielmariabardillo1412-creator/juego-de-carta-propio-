# Juego de cartas propio — laboratorio

Este proyecto es una copia independiente del motor universal. No sustituye el motor ni modifica el proyecto activo de Zápiti. La intención es desarrollar aquí un segundo juego y estudiar su integración únicamente cuando el prototipo sea estable.

La memoria operativa vigente está en [`docs/cuadernos/README.md`](docs/cuadernos/README.md). Esos cuatro cuadernos deben leerse al retomar el proyecto y actualizarse al cerrar cada fase.

La correspondencia entre las decisiones cerradas de S01, el motor y sus pruebas está resumida en [`docs/diseno/AUDITORIA_TRAZABILIDAD_REGLAS_BASICAS_S01_V0_1.md`](docs/diseno/AUDITORIA_TRAZABILIDAD_REGLAS_BASICAS_S01_V0_1.md).

## Alcance construido

- duelo de dos jugadores;
- 30 puntos de vida iniciales;
- energía creciente de 1 a 10;
- fases Inicio, Robo, Principal 1, Combate, Principal 2 y Final;
- cambio determinista de turno y ronda;
- rendición y ganador;
- 40 definiciones provisionales sin imágenes;
- las 18 criaturas ya poseen nombre, familia, superfamilia, anatomía y aptitudes concretas en el catálogo runtime;
- dos barajas físicas independientes de 40 cartas;
- mano inicial de cinco cartas y omisión del primer robo del jugador inicial;
- robo automático al entrar en la fase de Robo;
- baraja, mano, criaturas, materiales contenidos de Fusión, apoyos, terreno y cementerio por jugador;
- ocultación de manos y barajas ante rivales y espectadores;
- invocación normal de criaturas durante las fases principales;
- pago del coste de energía, cinco espacios y una invocación normal por turno;
- colocación de criaturas boca abajo en guardia;
- ocultación real de su identidad en vistas y eventos para rival, público, red y futuras repeticiones;
- revelación a ataque y un único cambio de postura por criatura y turno;
- combate por doble comparación simultánea de ataque contra defensa;
- revelación automática de objetivos ocultos antes del cálculo;
- destrucción y traslado al cementerio, daño sobrante condicionado por la postura y ataques directos;
- una acción de ataque por criatura y turno; una invocación normal boca arriba puede atacar al entrar, salvo durante el primer turno del jugador inicial;
- derrota inmediata al alcanzar cero puntos de vida;
- preparación oculta de Trampas y Magias reactivas;
- ventana opcional de respuesta al declarar un ataque, con prioridad alterna y cierre tras dos pases consecutivos;
- cadena de respuestas resuelta en orden inverso (última activada, primera resuelta);
- un único contrato de respuesta con contextos validados para ataques y Magias;
- el objetivo oculto conserva su identidad durante la respuesta y solo se revela antes del cálculo de combate;
- G06 concede +2 DEF durante el combate y G07 devuelve a la mano la criatura atacada y cancela el ataque;
- T01 destruye al atacante de coste 2 o menos y T02 le resta 2 ATQ durante el combate;
- T03 anula una Magia principal rival antes de aplicar su efecto y envía ambas cartas al cementerio;
- T04 devuelve a guardia una criatura enemiga que acaba de cambiar voluntariamente a ataque;
- T05 destruye el equipo u objeto que el rival acaba de vincular;
- T06 puede destruir al combatiente enemigo superviviente después de que una criatura propia sea destruida en combate;
- los disparadores de T04–T06 comparten la misma prioridad, pases, cadena y consumo que las respuestas a ataques y Magias;
- una respuesta no puede activarse durante el mismo turno en que fue preparada;
- los ataques cancelados quedan consumidos y las respuestas resueltas terminan en el cementerio;
- Magias persistentes y artefactos visibles en la fila de apoyo;
- equipos vinculados públicamente sin ocupar espacios de apoyo;
- E04 como artefacto activo que traslada un equipo entre criaturas propias compatibles una vez por turno;
- los traslados conservan los requisitos del equipo y crean un nuevo vínculo al que T05 puede responder;
- requisitos de Manipulador para armas y escudos que lo exigen;
- perfiles de compatibilidad separados en anatomía y aptitudes discretas, sin puntuación numérica de inteligencia;
- requisitos reutilizables de aptitud y anatomía para equipos presentes y futuros;
- validación de vínculos que dejan de ser compatibles tras un cambio de perfil;
- un Terreno visible por jugador, con sustitución o transformación ordenada al jugar otro;
- seis combinaciones iniciales: Bosque Inundado, Humedal Fértil, Bosque Ardiente, Bosque Volcánico, Caldera de Vapor y Llanura de Obsidiana;
- identidad pública estable para Terrenos transformados sin crear cartas físicas adicionales;
- G01 y G02 como mejoras temporales acumulables de ATQ y DEF;
- G03 devuelve criaturas visibles de coste 2 o menos y rompe sus equipos;
- efectos numéricos de G04, G05, E01, E02, E03, E05, E06 y los tres Terrenos;
- estadísticas efectivas únicas para interfaz, reglas y cálculo de combate;
- textos funcionales registrados para las 7 Magias, 6 Trampas, 6 Objetos y 3 Terrenos;
- contrato puro de Fusiones con recetas de dos materiales, orden opcional, prioridad por especificidad y rechazo de ambigüedades;
- validación de materiales visibles del mismo controlador, sin reutilizar una misma carta física;
- representación canónica de entidades generadas y conservación plana de las cartas físicas originales en Fusiones encadenadas;
- liberación verificable de todos los materiales físicos para la futura destrucción de una Fusión;
- F001-NAT, F010-NEU, F011-NF, F012-NN, F018-NEU, F067-AGU y F068-FA registradas y probadas en un catálogo específico y puro;
- las ocho Fusiones iniciales conectadas al duelo mediante `fuse_creatures`, una vez por turno en fase principal, sin coste universal de Energía;
- Banda Goblin ocupa una casilla, contiene dos materiales físicos, entra boca arriba en ataque o guardia y cuenta como recién llegada;
- equipo compatible heredado por Banda Goblin, destrucción de materiales y vínculos al Cementerio y devolución de materiales a la mano con rotura de vínculos;
- habilidad de Banda Goblin: paga 1 de Energía una vez por turno para dar +1 ATQ temporal a una criatura propia visible;
- liderazgo de F001: +1 ATQ durante el primer combate del turno declarado por otra criatura propia;
- adaptación de F067: su controlador elige +1 ATQ o +1 DEF antes de su primer combate de cada turno, antes de abrir respuestas;
- asalto de F011: al atacar obtiene +1 ATQ durante el combate y también +1 DEF si controla otro Goblin boca arriba;
- defensa de F012: una vez por turno, al ser atacada, reduce 1 ATQ al atacante durante ese combate;
- entrada de F068: elige una criatura enemiga boca arriba, le resta 1 ATQ y conserva la penalización hasta terminar el siguiente turno de su controlador;
- regeneración de F018: la primera vez por turno que fuera a ser destruido en combate evita esa destrucción y pasa forzosamente a guardia;
- F005 Dragón Bicéfalo Elemental: M17 + M18, 8/8 y un ataque adicional por turno tras destruir en combate y sobrevivir; se consume al declarar incluso si se cancela y no se salta respuestas;
- habilidades base completas: M05, M06, M07, M10, M16 y M18 automáticas; M09 con acción pagada; M12 con inspección privada; M15 con objetivo de entrada; y M13 con redirección anterior a trampas;
- las Fusiones no ejecutan la habilidad individual de la carta física que actúa como portadora;
- contrato documental de excepciones escritas y efectos latentes deterministas, todavía sin cartas latentes implementadas;
- mesa visual de duelo como escena principal, con perspectiva original, mano recta visible, línea territorial central, cartas provisionales reconocibles, reversos, ataque vertical/guardia horizontal, interacción carta → casilla u objetivo resaltado, ficha ampliada, fases nombradas, rival automático básico, veinte casillas permanentes y Baraja/Cementerio/Fusión/Territorio en zonas laterales separadas;
- sin red, animaciones ni arte definitivo.

## Fuentes de diseño

El índice local por fases está en [`docs/fuentes_diseno/README.md`](docs/fuentes_diseno/README.md). Contiene copias normalizadas de las seis fuentes y un manifiesto de sincronización para consultar solo los bloques pertinentes sin perder la procedencia.

Los documentos originales continúan siendo la fuente editable en Google Drive:

- [Estado y método de trabajo](https://docs.google.com/document/d/1zj5HK8ZTlIjGlBPezB-AdAufm2VI83e-Xv_mBNZnS34/edit)
- [Mecánicas básicas en discusión](https://docs.google.com/document/d/1xpD7h8yYE-KiSRHxJ_MADk5J3fwG1HeJ5yftbre-RPs/edit)
- [Tabla de presupuesto de cartas](https://docs.google.com/spreadsheets/d/1_IQTmvl9pOBa3erD9jsuEA0XaJJ5y2vgDSfosndaEU8/edit)
- [Biblia de familias y combinaciones](https://docs.google.com/document/d/1TVwhTVJsh05xG_Zf8HGxG11apnLkm7G01ylIe3Py_as/edit)
- [Libro de fusiones](https://docs.google.com/document/d/1Gu55n80M9Nk7c4t8h73ygAltNZttdu5Tnk8Glr3vvf4/edit)
- [Personajes especiales](https://docs.google.com/document/d/1rnWDSLhZMo1C2EImQzRnw75h1WG9i4C-3l8IyiK60iE/edit)

## Verificación

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
```

El último cierre total de las veintidós suites obtuvo 1.357 comprobaciones específicas antes de ampliar la interfaz. La batería contiene ahora veinticuatro suites. Tras el rediseño se repitieron las puertas afectadas: mesa 78/78, flujo visual de ataque 11/11, rival automático 9/9, vertical de criaturas 38/38 y vertical de ocho Fusiones 82/82. Los recorridos verticales incluyen privacidad, combate, Terrenos, destinos físicos, eventos, vistas e igualdad exacta de replay. Las nueve suites generales conservan su último cierre de 441 comprobaciones, el diagnóstico general 15 etapas y el experimento integral 80 comprobaciones.

La puerta automática de estrés usa semillas reproducibles y hasta ocho conductas de selección. El cierre 0.24 acumula 12.135 partidas y 1.044.565 acciones limpias después de descubrir y corregir dos acciones anunciadas que luego eran rechazadas. La ampliación larga aportó 10.025 partidas y 907.265 acciones, incluidas 25 sesiones por UCE. El informe está en [`docs/diseno/AUDITORIA_ESTRES_AUTOMATICO_V0_1.md`](docs/diseno/AUDITORIA_ESTRES_AUTOMATICO_V0_1.md).

La primera baraja generalista de fantasía está definida en [`docs/diseno/BARAJA_INICIAL_FANTASIA_GENERALISTA_V0_1.md`](docs/diseno/BARAJA_INICIAL_FANTASIA_GENERALISTA_V0_1.md): 40 cartas distintas repartidas entre Lobos, Goblins, Elementales, Trolls y Dragones, con las dieciocho criaturas y ocho Fusiones iniciales integradas. El flujo aprobado [`docs/diseno/FLUJO_DE_PARTIDA_E_INTERACCION_V0_1.md`](docs/diseno/FLUJO_DE_PARTIDA_E_INTERACCION_V0_1.md) ya se traduce en selección carta-casilla, fases administrativas automáticas, controles explícitos de combate/fin, Fusión por materiales, IA y lateral informativo. La presentación usa color y estructura provisionales; las imágenes definitivas continúan fuera de esta capa.

Si un jugador debe realizar su robo normal y su baraja está vacía, pierde inmediatamente: el rival queda declarado ganador, la fase pasa a final, se publica el agotamiento y el resultado forma parte del replay exacto.

Las reglas por defecto, sus futuras excepciones explícitas y el modelo recuperado de efectos latentes se documentan en [`docs/diseno/PRINCIPIOS_EXCEPCIONES_Y_EFECTOS_LATENTES_V0_1.md`](docs/diseno/PRINCIPIOS_EXCEPCIONES_Y_EFECTOS_LATENTES_V0_1.md). «Venganza del Bosque» continúa siendo un ejemplo de diseño, no contenido aprobado.

El criterio para comparar cifras, coste, preparación, efectos y contrajuego está en [`docs/diseno/MODELO_DE_EQUILIBRIO_DE_CARTAS_V0_1.md`](docs/diseno/MODELO_DE_EQUILIBRIO_DE_CARTAS_V0_1.md). Las cifras iniciales se tratarán como hipótesis para pruebas, no como equilibrio definitivo.
