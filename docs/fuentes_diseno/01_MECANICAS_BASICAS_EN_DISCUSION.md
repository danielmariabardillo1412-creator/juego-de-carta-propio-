# 01_MECANICAS_BASICAS_EN_DISCUSION

> Copia local de consulta. Fuente editable: https://docs.google.com/document/d/1xpD7h8yYE-KiSRHxJ_MADk5J3fwG1HeJ5yftbre-RPs/edit
> ID de Drive: `1xpD7h8yYE-KiSRHxJ_MADk5J3fwG1HeJ5yftbre-RPs`  
> Revisión observada: `ANLCKQmWygCZNqOlXuhH-5IiZ6Hcg4dJa-sPmXRLvE11TNo_Zhw_p5V5nnEGwLJiabs6FmK5ePZoe7s7YBtLHbN6z1L6_x6xg5anwo81piQ`  
> Modificación observada en Drive: `2026-08-07T03:17:05.104Z`  
> Sincronización local: `2026-09-08`

## Contenido original normalizado

MECÁNICAS BÁSICAS EN DISCUSIÓN

Estado general: ABIERTO

Este documento no es un reglamento consolidado. Recoge una mecánica cada vez, sus alternativas y la decisión provisional alcanzada.

==================================================

MECÁNICA 01 — PUNTOS DE VIDA Y DERROTA

==================================================

Estado: ABIERTO

1. FUNCIÓN

Los puntos de vida representan la capacidad del jugador para seguir combatiendo. Deben cumplir cuatro objetivos:

- permitir remontadas;

- crear presión para atacar;

- evitar partidas excesivamente largas;

- utilizar una escala fácil de leer y equilibrar.

2. DECISIONES QUE HAY QUE CERRAR

A. Cantidad inicial de vida.

B. Escala de ataque y daño.

C. Cuándo puede atacarse directamente al jugador.

D. Si el exceso de daño al destruir una criatura llega al jugador.

E. Si puede recuperarse vida por encima del valor inicial.

F. Otras condiciones de derrota.

3. ESCALA NUMÉRICA

No se recomienda utilizar cifras decorativas muy grandes durante el diseño, como 2.000 u 8.000, porque dificultan el cálculo y no añaden profundidad.

Hipótesis inicial recomendada para pruebas:

- Vida inicial: 30.

- Criaturas básicas: entre 1 y 6 de ataque.

- Criaturas potentes y fusiones: cifras mayores según coste y habilidades.

La cifra de 30 no está cerrada. Se propone porque ofrece más margen de prueba que 20 sin obligar a manejar cientos o miles de puntos.

4. DAÑO AL JUGADOR

Propuesta inicial:

- Si el rival no controla criaturas capaces de protegerlo, una criatura puede atacarlo directamente.

- Las criaturas y efectos también pueden causar daño directo mediante habilidades.

- El jugador no estará obligado por regla a atacar, pero retrasarse permitirá al rival robar, preparar trampas, fusionar y construir respuestas.

Pendiente:

Decisión posterior: cualquier criatura controlada, visible u oculta, impide los ataques directos contra su jugador, salvo que una carta permita ignorarla o causar daño directo.

5. DAÑO SOBRANTE

Alternativa A — Daño diferencial general:

Si una criatura destruye a otra, la diferencia de ataque daña al jugador defensor.

Ventaja: acelera la partida y hace peligroso dejar criaturas débiles.

Riesgo: puede provocar demasiado daño y hacer que una criatura grande domine la partida.

Alternativa B — Sin daño sobrante:

Destruir una criatura no daña al jugador, salvo que una habilidad lo indique.

Ventaja: permite defenderse con criaturas pequeñas.

Riesgo: puede alargar las partidas y facilitar bloqueos repetitivos.

Alternativa C — Daño sobrante mediante habilidad:

Normalmente no existe daño sobrante. Algunas criaturas tienen Perforación, Arrollar u otra habilidad equivalente.

Ventaja: permite controlar qué cartas atraviesan defensas.

Riesgo: añade una palabra clave más al reglamento.

Decisión posterior: se adopta daño sobrante general cuando una criatura en postura de ataque es destruida; una criatura en postura de guardia evita ese daño, salvo efectos de Perforación u otra excepción escrita.

6. CURACIÓN

Alternativas:

- La vida puede recuperarse hasta el máximo inicial.

- La vida puede superar el máximo inicial.

Recomendación provisional:

La vida puede superar el máximo inicial, pero las curaciones deben estar valoradas como cualquier otra ventaja. Se revisará si aparecen estrategias de bloqueo o partidas interminables.

7. CONDICIONES DE DERROTA

Propuesta inicial:

Un jugador pierde si:

- su vida llega a 0;

- debe robar y su mazo está vacío;

- se rinde.

Pendiente:

Decidir si existirán cartas con condiciones alternativas de victoria o derrota. No se necesitan para el primer prototipo.

8. RIESGOS QUE DEBEN MEDIRSE EN S

- partidas demasiado rápidas;

- partidas demasiado largas;

- daño directo excesivo;

- defensa basada en criaturas pequeñas demasiado eficiente;

- curación infinita;

- una sola criatura grande capaz de cerrar la partida sin apoyo;

- trampas de destrucción demasiado universales.

9. HIPÓTESIS DE PRUEBA V0

- 30 puntos de vida.

- Estadísticas pequeñas.

- Daño sobrante por defecto al destruir una criatura en postura de ataque.

- La postura de guardia evita el daño sobrante, salvo habilidades de Perforación u otra excepción escrita.

- Curación por encima de 30 permitida provisionalmente.

- Derrota por vida 0, agotamiento del mazo o rendición.

Esta hipótesis no se convertirá en regla cerrada hasta discutirla y probarla.

10. ACLARACIONES REGISTRADAS — 6 DE AGOSTO DE 2026, 20:09

- El juego se mantiene separado de Zápiti durante el diseño y la primera implementación. La integración se estudiará después mediante auditoría.

- No existirá clima aleatorio. La lluvia, tormentas, incendios, congelación y cualquier cambio ambiental solo aparecerán por cartas, habilidades o consecuencias deterministas.

- No habrá tablero por casillas ni movimiento táctico. Las criaturas permanecen en filas; atacar representa narrativamente entrar en el campo rival y regresar.

- Las estadísticas, la vida y el presupuesto de las cartas siguen siendo hipótesis de prueba, no reglas cerradas.

- Se ha creado una hoja calculable para diseñar criaturas antes de disponer de cartas reales.

HERRAMIENTA ASOCIADA

02_TABLA_PRESUPUESTO_DE_CARTAS_V0_1

https://docs.google.com/spreadsheets/d/1_IQTmvl9pOBa3erD9jsuEA0XaJJ5y2vgDSfosndaEU8/edit

La hoja incluye:

- presupuesto base por coste de energía;

- ejemplos equilibrados, ofensivos y defensivos;

- valoración provisional de ataque, defensa, habilidades y penalizaciones;

- calculadora editable;

- advertencias sobre supuestos todavía abiertos.

DECISIONES QUE SIGUEN ABIERTAS

- valor definitivo de la vida inicial;

- la protección queda cerrada: cualquier criatura controlada impide ataques directos, salvo excepción escrita;

- calibración numérica del daño sobrante y de las excepciones que atraviesan la guardia;

- valor real de la defensa dentro del presupuesto;

- límite de curación;

- ritmo objetivo de una partida.

La tabla se recalibrará después de las primeras simulaciones. No debe utilizarse como prueba de que una carta está equilibrada por sí sola.

==================================================

MECÁNICA 02 — ORIENTACIÓN, CARTAS OCULTAS Y ACTIVACIÓN

==================================================

Estado: CERRADO PARA PROTOTIPO

Decisión propuesta:

- Criatura boca arriba: desplegada y visible. Puede estar en postura de ataque o en postura de guardia.

- La orientación horizontal representa provisionalmente la postura de guardia.

- Cartas de apoyo colocadas boca abajo: preparadas y ocultas, pero todavía no resueltas.

- Cuando una carta oculta se activa, se gira boca arriba.

- Las trampas solo pueden activarse cuando se cumple su condición.

- Las magias deben prepararse en la zona de apoyo antes de activarse, según la Mecánica 04.

- Las cartas instantáneas van al descarte después de resolverse.

- Las cartas persistentes, objetos y terrenos permanecen boca arriba mientras continúe su efecto.

Aclaración jurídica y de diseño:

La orientación vertical, horizontal, boca arriba y boca abajo se utilizará como lenguaje visual general del juego. No se copiarán marcos, símbolos, nombres, ilustraciones, terminología propia ni texto reglamentario de Yu-Gi-Oh! El reglamento y la presentación serán originales.

Cuestiones pendientes:

- Si una trampa puede activarse el mismo turno en que se coloca.

- Qué tipos de magia pueden colocarse ocultos.

- Si las criaturas pueden colocarse boca abajo en alguna expansión futura.

- Si cambiar entre ataque y defensa consume una acción o está limitado a una vez 

DECISIÓN CONFIRMADA — 6 DE AGOSTO DE 2026, 21:40

- Esta decisión queda sustituida: se recuperan la postura de ataque y la postura de guardia con funciones limitadas.

- Las cartas de apoyo pueden colocarse boca abajo como cartas preparadas y ocultas.

- Una trampa boca abajo no está activa; se revela y activa cuando se cumple su condición.

- Una trampa no puede activarse durante el mismo turno en que fue colocada, salvo texto expreso.

- Las magias de fase principal pueden jugarse boca arriba desde la mano y resolverse inmediatamente durante una fase principal propia. Las magias reactivas deben prepararse previamente en la zona de apoyo.

- Colocar una magia boca abajo no modifica sus ventanas normales de uso.

- Las cartas instantáneas se descartan tras resolverse; objetos, terrenos y efectos persistentes permanecen boca arriba.

- Las criaturas podrán colocarse boca abajo en postura de guardia durante el primer prototipo.

SIGUIENTE MECÁNICA A DISCUTIR

Esta discusión se reabre: se recupera una postura de guardia que evita el daño sobrante y una postura de ataque que permite iniciar combates.

por turno.

ACTUALIZACIÓN — CRIATURAS OCULTAS EN DEFENSA

Estado: CERRADO PARA PROTOTIPO

Reglas acordadas:

- Al invocar una criatura, su controlador elige si entra boca arriba y visible o boca abajo y oculta.

- Si entra visible, se coloca boca arriba con orientación normal.

- Si entra oculta, se coloca boca abajo y en postura de guardia.

- Una criatura boca abajo oculta su nombre, estadísticas, clase, elemento, habilidades y demás información.

- Mientras permanezca boca abajo, sus habilidades están inactivas salvo que indiquen expresamente que se activan al ser revelada, atacada o volteada.

- Una criatura boca abajo no aporta requisitos visibles de clase, elemento, presencia, familia ni fusión, salvo que una carta permita comprobarla o utilizarla expresamente.

- Cuando una criatura boca abajo es atacada, se revela antes de comparar el ataque con la defensa.

- Tras revelarse, permanece boca arriba si sobrevive.

- Una criatura que ya está boca arriba no puede volver a ponerse boca abajo mediante un cambio manual de posición.

- Solo una carta, habilidad, magia o trampa puede volver a ocultar una criatura boca arriba.

- Una criatura que haya atacado no puede cambiar después a postura de guardia durante ese mismo turno.

- El cambio manual entre ataque y guardia vuelve a estar permitido con límites; ocultar o revelar una criatura continúa siendo una acción distinta.

Cuestiones todavía pendientes:

- Si una criatura boca abajo puede revelarse manualmente en un turno posterior.

- Si, al revelarse manualmente, puede iniciar un ataque ese mismo turno.

- Momento exacto en el que se resuelven los efectos de «al ser revelada» respecto al cálculo de combate.

- Qué cartas pueden inspeccionar, seleccionar o destruir criaturas boca abajo sin revelarlas.

Siguiente discusión recomendada:

Definir el proceso completo de ataque contra una criatura boca abajo y el orden de resolución de sus efectos al revelarse.

==================================================

MECÁNICA 03 — REVELACIÓN EN DEFENSA Y CADENA DE RESPUESTAS

==================================================

Estado: CERRADO PARA PROTOTIPO en revelación, ventanas de respuesta y cierre del cálculo de combate.

REVELACIÓN DE CRIATURA OCULTA

- Una criatura colocada boca abajo está oculta y en postura de guardia.

- Cuando es atacada, se revela antes de calcular el combate.

- Al revelarse se coloca boca arriba. El combate utiliza simultáneamente el ATAQUE y la DEFENSA de ambas criaturas.

- Si tiene una habilidad que se activa al ser revelada y se cumplen sus condiciones, dicha habilidad se activa antes de comparar estadísticas.

- Una criatura revelada queda visible y permanece en postura de guardia; revelarla no la cambia automáticamente a ataque.

- Si sobrevive, permanece boca arriba.

CADENA DE RESPUESTAS — HIPÓTESIS INICIAL

1. El atacante declara el ataque y el objetivo.

2. Se abre una ventana de respuesta antes de revelar la criatura objetivo.

3. El defensor puede activar una magia rápida, una trampa o una habilidad válida.

4. El atacante puede responder con otra carta válida.

5. Ambos jugadores alternan respuestas, una cada vez, hasta que los dos pasan consecutivamente.

6. Las respuestas se resuelven desde la última activada hasta la primera.

7. Si el ataque sigue siendo válido, la criatura boca abajo se revela.

8. Se activan y resuelven sus posibles efectos de revelación.

9. Se calcula el combate con doble comparación: ATAQUE del atacante contra DEFENSA del defensor y ATAQUE del defensor contra DEFENSA del atacante.

Un jugador puede activar varias cartas durante una misma cadena, pero no todas simultáneamente: cada activación da al rival la oportunidad de responder. Esto evita que un jugador use dos o tres respuestas sin que el adversario pueda intervenir.

PENDIENTE DE DISCUSIÓN

- Decisión cerrada: revelar una criatura no abre por sí mismo una segunda ventana general. Solo se activan o pueden activarse efectos cuya condición o ventana sea válida en ese momento.

- Decisión cerrada: cuando comienza el cálculo final del combate ya no pueden activarse nuevas cartas o habilidades generales. Las modificaciones de ATAQUE, DEFENSA, protección, destrucción o similares deben haberse activado en una ventana válida anterior. Solo un efecto cuyo texto indique expresamente que actúa durante el cálculo puede constituir una excepción.

- Qué subtipos de magia pueden responder durante el turno rival.

==================================================

MECÁNICA 04 — MAGIAS PREPARADAS Y USO DESDE LA MANO

==================================================

Estado: PROVISIONAL

Decisión registrada:

- Las magias de fase principal pueden jugarse boca arriba desde la mano durante una fase principal propia.

- Las magias normales o persistentes entran en la zona de apoyo boca arriba, se resuelven inmediatamente y después se descartan o permanecen según su duración.

- Solo las magias reactivas y las trampas se preparan boca abajo; mientras permanezcan ocultas todavía no están activas.

- Una magia solo puede activarse cuando su tipo y su condición temporal lo permitan.

- Colocar la magia en el campo ocupa uno de los espacios de apoyo disponibles.

- Un jugador puede aplicar varias magias sobre la misma criatura si todas son legales y dispone de espacios, tiempo de preparación y recursos suficientes.

- Las cartas mágicas persistentes permanecen boca arriba después de resolverse; las instantáneas se envían al descarte.

Motivo de diseño:

Impedir que un jugador acumule varias magias ocultas en la mano y las descargue de golpe sin haberlas preparado, sin ocupar espacio y sin dar señales al rival. La preparación en el campo crea información parcial, farol, riesgo de destrucción y coste de oportunidad.

Riesgo pendiente:

Si todas las magias necesitan esperar un turno completo antes de activarse, el juego puede volverse demasiado lento. Debe discutirse si:

A. Toda magia puede activarse el mismo turno en que se coloca durante la fase principal, pero nunca como respuesta inmediata.

B. Ninguna magia puede activarse el mismo turno en que se coloca.

C. Solo ciertos subtipos pueden activarse el mismo turno en que se colocan.

Recomendación inicial:

Esta recomendación queda sustituida. Las magias de fase principal pueden jugarse y resolverse el mismo turno; las magias reactivas y las trampas deben prepararse y esperar hasta un turno posterior, salvo excepción escrita.

==================================================

NOTA DE DISEÑO FUTURO — MEJORAS APILADAS, ELEMENTOS Y EQUIPO

==================================================

Estado: ABIERTO. No se necesita para cerrar el combate básico.

Principio aceptado:

- Un jugador podrá invertir varias cartas de mejora en una misma criatura. No se impondrá un límite artificial de una sola mejora por criatura.

- Concentrar muchas mejoras será una decisión estratégica del jugador y tendrá el riesgo natural de perder varias cartas si la criatura es destruida, devuelta, robada o anulada.

Coherencia entre ilustración y función:

- La imagen, el nombre, el tipo y el efecto de una carta deberán corresponderse.

- Una armadura física persistente se clasificará normalmente como Objeto o Equipo, no como una magia genérica.

- Una protección creada temporalmente por energía podrá clasificarse como Magia, Aura o Encantamiento.

Datos que podrá tener una mejora:

- tipo: magia, aura, objeto o equipo;

- elemento: fuego, agua, electricidad, luz, oscuridad u otros;

- categoría corporal: arma, armadura, casco, calzado, accesorio u otra;

- peso o carga;

- duración;

- etiquetas de compatibilidad;

- efecto base y posibles reacciones.

Sobrecarga de equipo:

- El número total de cartas no será por sí solo el criterio.

- Equipar espada, armadura, botas y casco puede ser normal.

- Acumular varias armaduras pesadas, varias armas incompatibles o exceso de peso puede provocar estados como Sobrecarga, Lentitud, Desequilibrio o pérdida de ataque.

- Algunas criaturas o equipos podrán beneficiarse expresamente de duplicar una categoría.

Compatibilidad elemental:

- Las mejoras conservarán su elemento y podrán interactuar entre sí y con el elemento de la criatura.

- Una combinación puede producir bonificación, penalización, transformación, cambio elemental o ausencia de reacción.

- Ejemplos conceptuales: agua más electricidad puede generar Conductividad; fuego más agua puede apagar, crear vapor o transformar según la naturaleza exacta de la carta; luz más oscuridad puede generar conflicto, equilibrio o corrupción.

- No se asumirá que toda combinación de elementos opuestos sea siempre negativa. El resultado dependerá de reglas generales y de excepciones escritas.

Arquitectura recomendada:

1. Reglas generales basadas en etiquetas.

2. Estados universales como Mojado, Electrificado, Sobrecargado, Purificado o Corrompido.

3. Recetas especiales para combinaciones importantes.

4. Si una combinación no tiene regla general ni receta, ambas mejoras funcionan normalmente sin reacción adicional.

Límite técnico:

No se diseñará manualmente una reacción exclusiva para cada pareja posible de cartas. Eso produciría una explosión combinatoria difícil de aprender, probar y programar.

Decisiones pendientes para una fase posterior:

- si el equipo utiliza espacios corporales estrictos o un sistema de carga;

- si una criatura puede llevar dos objetos de la misma categoría;

- cuánto dura cada tipo de magia o aura;

- la decisión queda cerrada: las mejoras adjuntas no ocupan espacios de la fila trasera; se muestran vinculadas a su criatura;

- qué reacciones elementales son universales;

- qué transformaciones cambian realmente el elemento o la identidad de una criatura;

- cómo se valoran estas sinergias en la tabla de presupuesto.

==================================================

NOTA DE DISEÑO FUTURO — APTITUDES, ANATOMÍA Y NARRADOR

==================================================

Estado: ABIERTO. Idea aceptada para desarrollar más adelante; no debe ampliar todavía el núcleo del primer prototipo.

PRINCIPIO GENERAL

- Las criaturas no tendrán una estadística numérica universal de Inteligencia.

- La compatibilidad se representará mediante perfiles anatómicos y aptitudes discretas.

- La ilustración y la fantasía de la criatura sugerirán su lógica, pero el motor no deducirá reglas directamente del dibujo.

- La información relevante estará registrada como datos y podrá consultarse en la interfaz, aunque no ocupe un número grande en la cara principal de la carta.

DOS CAPAS DE COMPATIBILIDAD

1. Anatomía o forma corporal: humanoide, cuadrúpedo, serpentino, alado, amorfo, espectral, colosal u otras familias necesarias.

2. Aptitudes: manipular herramientas, leer, canalizar magia, usar grimorios, portar equipo convencional u otras capacidades concretas.

No se asumirá que todos los miembros de una especie tienen la misma aptitud. Un Troll Bruto podría no leer, mientras que un Chamán Troll sí podría utilizar grimorios. Esto permite variedad sin convertir la especie en una regla rígida.

REQUISITOS DE CARTAS

- Los objetos y técnicas podrán declarar requisitos como Mano libre, Manipulación, Lectura, Canalización o una forma corporal compatible.

- Una espada normal podrá requerir capacidad de manipulación y un punto de sujeción adecuado.

- Un grimorio podrá requerir Lectura y, cuando corresponda, Canalización.

- Una criatura sin manos podrá utilizar armas diseñadas para garras, mandíbulas, monturas, arneses o su anatomía específica.

- Las auras y efectos externos no exigirán necesariamente que la criatura comprenda o manipule el objeto.

USO INCOMPATIBLE O ARRIESGADO

- Algunas cartas podrán intentarse sobre objetivos poco compatibles y producir un resultado alternativo determinista.

- Antes de confirmar una acción claramente incompatible, la interfaz deberá mostrar una advertencia para evitar pérdidas accidentales.

- Si el jugador confirma, la carta podrá consumirse, fallar parcialmente, generar una penalización o producir un efecto alternativo descrito por las reglas.

- No toda incompatibilidad debe ser una pérdida completa. Ejemplo conceptual: un troll incapaz de leer un grimorio podría comérselo y recibir Saciado en lugar de aprender magia.

- Estos resultados no serán improvisados por el narrador: deberán estar definidos por reglas generales, etiquetas o recetas concretas.

FUNCIÓN DEL NARRADOR

- El narrador describirá con una frase breve y temática el resultado ya calculado por el motor.

- Junto a la frase narrativa, el registro mostrará la explicación mecánica exacta.

- Ejemplo narrativo: «El troll hojea el grimorio, pierde el interés y se lo come».

- Ejemplo mecánico asociado: «Fallo de compatibilidad: el objetivo no posee Lectura. Grimorio consumido. El troll obtiene Saciado».

- El narrador no decidirá resultados, no inventará excepciones y no sustituirá la información reglamentaria.

RIESGOS DE DISEÑO

- Confiar únicamente en la ilustración sería ambiguo e injusto, especialmente por accesibilidad o por criaturas visualmente difíciles de interpretar.

- Demasiadas aptitudes convertirían el juego en un simulador de inventario y aumentarían mucho la carga de aprendizaje.

- Castigar sin advertencia una interacción razonable produciría frustración más que estrategia.

- Cada resultado alternativo exclusivo aumenta el trabajo de diseño, equilibrio, texto y programación.

ARQUITECTURA RECOMENDADA

1. Un número pequeño de perfiles anatómicos.

2. Un conjunto reducido de aptitudes reutilizables.

3. Requisitos claros en objetos, grimorios y técnicas.

4. Resultados generales de incompatibilidad.

5. Unas pocas recetas especiales con líneas narrativas propias.

6. Registro mecánico exacto junto al comentario de ambientación.

ALCANCE DEL PRIMER PROTOTIPO

- No introducir todavía una escala de inteligencia.

- Probar como máximo dos o tres aptitudes y dos objetos incompatibles para verificar si la idea resulta divertida y comprensible.

- La expansión completa de anatomía, equipo y resultados alternativos se diseñará después de cerrar campo, combate, turno y recursos.

SIGUIENTE DISCUSIÓN DEL NÚCLEO

Definir las zonas del campo y decidir si las mejoras y objetos adjuntos continúan ocupando espacios de la fila de apoyo.

==================================================

AMPLIACIÓN — APTITUDES MODIFICABLES Y CONVERSIÓN DE ROL

==================================================

Estado: ABIERTO. Principio de diseño aceptado; desarrollo detallado aplazado.

CORRECCIÓN DEL ENFOQUE

- Las limitaciones de una criatura serán su estado inicial, no prohibiciones absolutas e irreversibles.

- No se establecerá una regla general de «los animales no pueden aprender» ni «los trolls no pueden usar magia».

- Cada criatura tendrá las aptitudes que correspondan a su versión concreta y estas podrán ganarse, perderse o sustituirse mediante cartas, entrenamiento, transformaciones o estados.

- Las especies, la ilustración y la anatomía orientan la fantasía, pero no determinan por sí solas un destino inmutable.

ETIQUETAS DISCRETAS RECOMENDADAS

- Bestial: actúa principalmente por instinto y no utiliza por defecto técnicas intelectuales complejas.

- Sapiente: puede comprender órdenes, conceptos y efectos complejos.

- Lector: puede utilizar textos, runas o grimorios que exijan lectura.

- Canalizador: puede dirigir energía mágica de manera consciente.

- Manipulador: puede utilizar herramientas u objetos que requieran sujeción y control físico.

Estas etiquetas no forman una escala numérica. Una criatura puede tener unas y no otras. Por ejemplo, un lobo despertado podría ser Sapiente y Canalizador, pero seguir sin ser Manipulador por carecer de manos.

APTITUDES MODIFICABLES

Las cartas podrán conceder aptitudes mediante efectos como:

- Despertar mental: una criatura Bestial obtiene Sapiente.

- Educación acelerada: una criatura Sapiente obtiene Lector.

- Iniciación arcana: una criatura con Lector o Canalizador obtiene acceso a una clase o habilidad mágica.

- Vínculo telepático: permite utilizar temporalmente ciertos textos sin manipulación física convencional.

- Posesión, bendición, mutación o fusión: pueden conceder aptitudes de forma temporal o permanente.

CONVERSIÓN DE ROL O CLASE

- Una criatura podrá adoptar un rol distinto de aquel para el que parecía diseñada inicialmente.

- La conversión no borrará necesariamente sus estadísticas físicas originales.

- Un troll defensivo convertido en mago podría conservar su DEFENSA y regeneración, ganar una habilidad mágica y modificar su ATAQUE o sus opciones de combate.

- Un animal despertado podría convertirse en chamán, familiar arcano o guardián rúnico si se cumplen los requisitos.

- El resultado podrá representarse mediante una carta persistente, una transformación, una clase superpuesta o una fusión concreta. Esta elección se decidirá al diseñar el sistema de clases y transformaciones.

COSTE Y EQUILIBRIO

- Convertir una criatura fuera de su función natural deberá exigir inversión real: varias cartas, energía, tiempo de preparación, una condición concreta o riesgo de interrupción.

- La recompensa puede ser alta porque el jugador ha construido una combinación y ha dedicado recursos a ella.

- No se aplicará una penalización automática solo por crear una combinación poco habitual.

- El presupuesto deberá valorar conjuntamente la resistencia base conservada, las nuevas aptitudes, las habilidades obtenidas y la consistencia con la que se logra la conversión.

EJEMPLO CONCEPTUAL

1. Un Troll Guardián comienza como criatura resistente con Manipulador, pero sin Lector ni Canalizador.

2. «Chispa de Entendimiento» le concede Sapiente y Lector.

3. «Grimorio de Piedra Viva» puede entonces vincularse legalmente a él.

4. El troll obtiene la clase o estado «Arcanista de Piedra», conserva gran parte de su defensa y gana una habilidad ofensiva o de control.

Este ejemplo no es todavía una carta cerrada ni fija estadísticas. Solo demuestra que una limitación inicial puede convertirse en una ruta estratégica.

PAPEL DEL NARRADOR

- El narrador describirá cada etapa de la transformación, no solo los fallos.

- Ejemplo: «Por primera vez, el troll comprende los símbolos. Las runas responden a su fuerza de voluntad».

- El registro mecánico mostrará: «Obtiene Sapiente y Lector. Ahora cumple los requisitos del Grimorio de Piedra Viva».

- Cuando una interacción falle, el narrador podrá hacerlo entretenido; cuando una combinación extraordinaria funcione, también deberá reconocerla.

CRITERIO DE DISEÑO

La lógica del mundo debe crear restricciones comprensibles, pero el juego debe ofrecer herramientas para romperlas de forma deliberada. Las excepciones preparadas por el jugador son parte de la estrategia, no errores del sistema.

ALCANCE

Este sistema se desarrollará después de cerrar campo, combate, turnos, recursos, tipos de carta y reglas básicas de transformación. Por ahora queda preservado como dirección de diseño para clases, equipo, grimorios, fusiones y narrador.

==================================================

AMPLIACIÓN — ESPECIALIZACIÓN, HÍBRIDOS Y «MINIFUSIÓN»

==================================================

Estado: ABIERTO. Dirección de diseño aceptada; pendiente de diseñar junto con clases, transformaciones y presupuesto.

IDEA CENTRAL

- Las cartas no solo aumentarán cifras: podrán enseñar funciones, disciplinas o estilos de combate a una criatura.

- Una criatura inicialmente defensiva podrá convertirse en guerrero, mago, atacante, apoyo o híbrido sin perder necesariamente su cuerpo, especie ni estadísticas físicas originales.

- La especialización podrá concederse mediante magia persistente, entrenamiento, objeto, técnica, transformación o, en casos concretos, una trampa.

- Las limitaciones iniciales de aptitud servirán tanto para restringir como para crear rutas de mejora más valiosas.

EJEMPLOS DE CONVERSIÓN

- Un troll tanque puede aprender a utilizar armas y convertirse en guerrero, conservando su defensa elevada y obteniendo ataque, técnicas o compatibilidad con nuevo equipo.

- El mismo troll puede obtener Lectura y Canalización y convertirse en mago tanque.

- Una criatura ofensiva puede aprender protección, guardia o uso de armadura y transformarse en atacante defensivo.

- Un mago frágil puede entrenarse como combatiente, aunque el resultado no tiene por qué ser igual al de un guerrero natural.

HÍBRIDOS

- No se obligará a que cada criatura tenga una única función cerrada.

- Podrán existir combinaciones como mago tanque, guerrero sanador, defensor controlador o bestia canalizadora.

- Las disciplinas podrán acumularse cuando las cartas, los requisitos y los recursos lo permitan.

- Cada nueva disciplina deberá aportar capacidades concretas, no únicamente una etiqueta decorativa.

DIFERENCIA RESPECTO A LA FUSIÓN

- La especialización se parece a una «minifusión» porque combina una criatura con otras cartas para producir una versión nueva de ella.

- Sin embargo, la criatura base sigue siendo la misma entidad: conserva su identidad, historial, procedencia, posición, vínculos y mejoras que continúen siendo legales.

- Una fusión verdadera podrá combinar varios materiales y crear una entidad distinta con una carta o receta propia; esos materiales quedan contenidos en la fusión mientras esta exista.

- Esta separación permite que ambas mecánicas convivan sin volverse redundantes.

RECOMPENSA Y RIESGO

- Se permitirá construir una criatura con ataque y defensa muy altos si el jugador ha invertido suficientes cartas, energía, turnos y espacios.

- No se impondrá un techo artificial solo porque la combinación resulte poderosa.

- El equilibrio procederá de la preparación, los requisitos, la posibilidad de interrupción, la concentración de recursos, la compatibilidad y el riesgo de perder varias cartas vinculadas.

- Algunas conversiones serán deliberadamente más eficientes sobre ciertas criaturas. Una mejora no tendrá por qué producir el mismo valor en todos los objetivos.

- La tabla de presupuesto deberá valorar el resultado completo y la facilidad de ensamblarlo, no solo el texto aislado de cada carta.

DISEÑO DE LAS CARTAS DE ROL

Una carta de especialización podrá:

- conceder una aptitud, clase o disciplina;

- habilitar armas, grimorios o técnicas antes incompatibles;

- añadir o modificar ATAQUE y DEFENSA;

- conceder habilidades activas, pasivas o reactivas;

- cambiar el elemento o añadir uno secundario;

- crear sinergias especiales con los atributos físicos de la criatura base;

- imponer costes, incompatibilidades o estados derivados.

Ejemplo conceptual, no cerrado:

«Entrenamiento del Rompefilas» — La criatura obtiene Guerrero y Manipulador. Puede utilizar armas pesadas. La primera vez que pase de defensa a ataque, obtiene una bonificación relacionada con su DEFENSA hasta el final del turno.

Este tipo de diseño permite que una criatura originalmente defensiva convierta parte de su fortaleza corporal en presión ofensiva, sin limitarse a sumar una cifra plana.

NARRADOR

- El narrador describirá la adquisición de la nueva función y las combinaciones poco habituales.

- También explicará por qué una disciplina produce un resultado especialmente fuerte, débil o alternativo en una criatura concreta.

- El cálculo seguirá perteneciendo al motor y el registro mostrará las modificaciones exactas.

RIESGOS QUE DEBEN CONTROLARSE

- criaturas que acumulen todas las funciones sin una inversión proporcional;

- conversiones universales que sean siempre mejores que utilizar especialistas naturales;

- demasiadas etiquetas de clase o aptitud;

- bucles al retirar y volver a aplicar especializaciones;

- mejoras que multipliquen estadísticas altas sin un coste adecuado;

- pérdida de legibilidad cuando una criatura acumule demasiados estados y cartas vinculadas.

PRINCIPIO CONSOLIDADO

El juego permitirá que el jugador construya el rol de sus criaturas durante la partida. Las criaturas tendrán una inclinación inicial, pero no quedarán encerradas permanentemente en tanque, atacante, mago o apoyo. La reconversión será una forma de construcción estratégica intermedia entre una mejora normal y una fusión completa.

==================================================

PROPUESTA ABIERTA — COMBATE CON ATAQUE Y DEFENSA ACTIVOS

==================================================

Estado: CERRADO PARA PROTOTIPO. La doble comparación convive con las posturas de ataque y guardia.

PROBLEMA DETECTADO

- Si la personalización, el equipo y la reconversión de rol permiten construir criaturas híbridas, un combate que solo consulta ATAQUE o DEFENSA puede reducir toda esa profundidad a aumentar un único número.

- El problema no es tener únicamente dos estadísticas, sino que una de ellas quede anulada durante cada enfrentamiento.

- Antes de seguir con tablero, clases o fusiones, debe revisarse el núcleo del combate porque afecta al valor real de ATAQUE, DEFENSA y todas las mejoras.

MODELO PROPUESTO: DOBLE COMPARACIÓN SIN VIDA INDIVIDUAL

1. La criatura atacante declara objetivo y utiliza su ATAQUE contra la DEFENSA del objetivo.

2. Al mismo tiempo, la criatura defensora utiliza su ATAQUE como represalia contra la DEFENSA del atacante.

3. Si el ATAQUE del atacante supera la DEFENSA del defensor, el defensor es destruido.

4. Si el ATAQUE del defensor supera la DEFENSA del atacante, el atacante es destruido.

5. Pueden morir una, ambas o ninguna criatura.

6. El empate no destruye por defecto: para superar una defensa es necesario excederla. Esta regla sigue abierta a pruebas.

7. No se acumula daño y las criaturas que sobreviven permanecen intactas.

FUNCIÓN DE LOS ESTADOS VISIBLE Y OCULTO

- Visible: la criatura puede iniciar combates cuando esté en postura de ataque y las reglas del turno lo permitan.

- Oculta: la criatura no puede iniciar ataques normales mientras permanezca boca abajo; su información y habilidades quedan ocultas salvo excepciones escritas.

- En todo enfrentamiento, ATAQUE y DEFENSA de ambas criaturas siguen siendo relevantes.

- Revelar una criatura oculta solo cambia su estado de oculta a visible.

EJEMPLOS CONCEPTUALES

- Tanque 2/8 frente a atacante 6/3: 6 no supera 8 y 2 no supera 3; ambas sobreviven.

- Cañón de cristal 9/2 frente a criatura 4/4: 9 supera 4 y 4 supera 2; ambas son destruidas.

- Troll híbrido 7/8 frente a guerrero 5/5: 7 supera 5, pero 5 no supera 8; solo sobrevive el troll.

VENTAJAS

- ATAQUE y DEFENSA importan siempre.

- Una criatura resistente convertida en atacante aprovecha realmente su antigua función de tanque.

- Los cañones de cristal, tanques, duelistas e híbridos tienen perfiles mecánicos distintos.

- Mantiene destrucción binaria y evita puntos de vida, curación individual y contadores de daño.

RIESGOS

- Las criaturas con mucha DEFENSA y poco ATAQUE pueden provocar bloqueos donde nadie muere.

- Puede aumentar la frecuencia de destrucciones dobles.

- La tabla de presupuesto debe recalibrarse: DEFENSA gana valor también al atacar.

- Debe probarse si hacen falta herramientas como ataque combinado, ruptura de guardia, reducción temporal de DEFENSA o habilidades de asedio; no se añadirán todavía por defecto.

DECISIÓN CONFIRMADA — 6 DE AGOSTO DE 2026, 22:28

- Se adopta para el prototipo la doble comparación de ATAQUE y DEFENSA.

- Esta decisión queda sustituida: se recuperan postura de ataque y postura de guardia.

- La orientación horizontal representa la postura de guardia.

- Las criaturas pueden estar visibles u ocultas; este estado es independiente del combate.

- La protección del jugador queda definida; la revelación manual de criaturas ocultas sigue pendiente.

- La tabla de presupuesto deberá recalibrarse porque DEFENSA participa también cuando una criatura inicia un ataque.

SIGUIENTE DISCUSIÓN DEL NÚCLEO

La siguiente discusión del núcleo será cerrar el cambio entre ataque y guardia, la revelación manual de criaturas ocultas y el orden exacto de las ventanas de respuesta durante el combate.

==================================================

MECÁNICA 05 — PROTECCIÓN, POSTURAS, DAÑO, ATAQUES Y ZONAS

==================================================

Estado: CERRADO PARA PROTOTIPO en protección, ataque por turno y estructura básica del campo; PROVISIONAL en cambio de postura, empate y robo normal.

ACLARACIÓN TOMADA DEL REGLAMENTO DE REFERENCIA

- En Yu-Gi-Oh!, un empate ATK contra ATK destruye ambos monstruos; un empate ATK contra DEF no destruye ninguno.

- En este proyecto no se copiará esa resolución literalmente, porque el combate propio compara simultáneamente ATAQUE contra DEFENSA en ambas direcciones.

- Para el prototipo, igualar una DEFENSA no basta para destruir: solo se destruye cuando el ATAQUE la supera. Por tanto, un empate ATAQUE-DEFENSA deja a la criatura con vida.

- Si el ATAQUE de cada criatura supera la DEFENSA de la otra, ambas son destruidas.

1. PROTECCIÓN DEL JUGADOR

- Mientras un jugador controle al menos una criatura, visible u oculta, no puede ser objetivo de un ataque directo normal.

- El atacante elige qué criatura enemiga ataca.

- Una habilidad, magia o trampa podrá permitir atacar directamente o causar daño directo ignorando las criaturas.

- Una criatura sigue sirviendo como muro aunque ya haya atacado, salvo que un efecto indique lo contrario.

2. POSTURA DE ATAQUE Y POSTURA DE GUARDIA

- Postura de ataque: la criatura se coloca vertical y puede iniciar un ataque normal.

- Postura de guardia: la criatura se coloca horizontal y no puede iniciar un ataque normal.

- Ambas posturas utilizan siempre la doble comparación: ATAQUE contra DEFENSA en las dos direcciones.

- La postura no sustituye ninguna estadística; solo modifica la capacidad de iniciar ataques y el paso del daño sobrante.

- Las criaturas boca abajo se colocan en postura de guardia.

- Cuando una criatura oculta es revelada, permanece en guardia.

- Una criatura que haya atacado no puede pasar después a guardia durante ese turno.

- El cambio voluntario queda cerrado: una criatura no puede cambiar de postura el turno en que entra y, desde un turno posterior, puede cambiar voluntariamente una vez por turno durante la fase principal.

3. DAÑO SOBRANTE

- Si una criatura en postura de ataque es destruida en combate, la diferencia entre el ATAQUE que la destruyó y su DEFENSA se resta de la vida de su controlador.

- Si una criatura en postura de guardia es destruida, el daño sobrante no llega a la vida de su controlador.

- Las habilidades de Perforación u otras excepciones podrán hacer que una guardia deje pasar daño.

- Si las dos criaturas son destruidas y ambas estaban en ataque, los dos jugadores pueden recibir daño sobrante durante el mismo combate.

- Esta última consecuencia debe probarse expresamente porque puede acelerar mucho las partidas.

4. ATAQUES POR TURNO

- Cada criatura puede declarar un ataque normal una vez por turno de su controlador.

- El juego registrará si la criatura ya atacó; no se utiliza una regla general de agotamiento que le impida defender, activar habilidades o proteger al jugador.

- Las cartas podrán conceder ataques adicionales, impedir ataques o imponer recuperación durante uno o más turnos.

5. EFECTOS DE CRIATURA

- Poner una criatura boca arriba no activa automáticamente todos sus efectos.

- Cada efecto indica su propio momento, condición, objetivo y coste.

- Tipos conceptuales para diseñar después: efecto al entrar visible, efecto al ser revelada, efecto continuo, efecto activado voluntariamente y efecto disparado por una condición.

- Una combinación de familia o conjunto solo se activa cuando estén presentes todas las piezas exigidas por su texto.

6. RESPUESTAS DURANTE UN ATAQUE

- Al declararse un ataque se abre una ventana para trampas, magias preparadas y habilidades que sean válidas en ese momento.

- Las cartas deben cumplir su condición específica; una trampa vinculada a otra carta o a un tipo concreto de ataque no puede activarse fuera de esa condición.

- Las respuestas forman una cadena alternada y se resuelven desde la última activada hasta la primera.

- Las magias reactivas deben estar preparadas previamente. Las magias de fase principal solo pueden utilizarse durante una fase principal propia y no pueden irrumpir desde la mano como respuesta.

7. ESTRUCTURA BÁSICA DEL CAMPO

- Cinco espacios de criaturas por jugador.

- Cinco espacios de apoyo por jugador para magias, trampas, objetos y mejoras persistentes.

- Los equipos y objetos vinculados a una criatura no ocupan espacios de apoyo. Se colocan en el área de vínculos de esa criatura.

- Cada jugador dispone de una zona de terreno propia.

- No hay terreno inicial salvo que una carta o regla especial lo coloque.

- Cada jugador puede mantener un terreno; jugar otro sustituye al anterior salvo que una carta permita varios.

- Los terrenos pueden ser destruidos, modificados o transformados mediante cartas y habilidades.

- Los dos terrenos pueden coexistir y producir interacciones deterministas.

8. CARTAS USADAS Y DESTRUIDAS

- No habrá descarte obligatorio de la mano por superar un límite mientras no se decida lo contrario.

- Sí debe existir una zona pública para criaturas destruidas y cartas de un solo uso ya resueltas. El nombre provisional será Cementerio o Zona de usadas.

- Decir «no hay descarte» se interpreta por ahora como «no hay descarte obligatorio por tamaño de mano», no como desaparición de la zona de cartas usadas.

9. INVOCACIÓN

- Cada jugador puede realizar una colocación o invocación normal de criatura por turno.

- Magias, trampas, habilidades e invocaciones especiales podrán permitir criaturas adicionales.

- Una criatura podrá invocar compañeros cuando su texto lo indique.

- Queda pendiente diseñar el coste de criaturas fuertes y comprobar si existe un sistema equivalente a sacrificios, energía o requisitos propios.

10. ROBO CERRADO; RECURSOS TODAVÍA ABIERTOS

- En Yu-Gi-Oh! existe un robo normal de una carta durante la fase de robo, salvo para el primer jugador en su primer turno; las cartas producen robos adicionales.

- Decisión cerrada: cada jugador empieza con cinco cartas y roba una carta automáticamente al comienzo de cada turno, excepto el jugador inicial durante su primer turno.

- Las magias, trampas y habilidades de criaturas pueden producir robos adicionales cuando sus efectos lo indiquen. Las habilidades se consideran efectos de carta y siguen sus propias condiciones, costes y ventanas de activación.

- No hay descarte obligatorio por superar un límite de mano durante el primer prototipo.

- Si un jugador debe robar una carta y su mazo está vacío, pierde la partida.

- El sistema de recursos sigue abierto. La hoja de presupuesto utiliza energía como herramienta provisional de cálculo, pero eso no convierte la energía automática en regla aprobada.

SIGUIENTE DECISIÓN CONCRETA

El cambio voluntario entre ataque y guardia queda cerrado. La siguiente decisión será definir el robo normal de cartas, la mano inicial y la pérdida por mazo vacío.

==================================================

DECISIÓN CONFIRMADA — ATAQUE EL TURNO DE INVOCACIÓN

==================================================

Estado: CERRADO PARA PROTOTIPO

- Una criatura invocada boca arriba en postura de ataque puede declarar un ataque durante ese mismo turno, siempre que no exista otro efecto que se lo impida.

- Una criatura colocada boca abajo entra en postura de guardia y no puede revelarse manualmente para atacar durante el mismo turno en que fue colocada.

- El jugador que comienza la partida no puede declarar ataques durante su primer turno.

- Esta restricción afecta al primer turno del jugador inicial, no al primer turno de cada jugador.

- Los efectos de cartas podrán permitir excepciones expresas, como atacar inmediatamente, impedir atacar o conceder ataques adicionales.

SIGUIENTE DECISIÓN CONCRETA

Cerrar el cambio voluntario entre postura de ataque y postura de guardia.

==================================================

MECÁNICA 06 — CAMBIO ENTRE ATAQUE Y GUARDIA

==================================================

Estado: CERRADO PARA PROTOTIPO.

REGLAS

- Al jugar una criatura normalmente, su controlador elige que entre boca arriba en ataque o boca abajo en guardia.

- Una criatura no puede cambiar voluntariamente de postura durante el turno en que fue jugada.

- Desde un turno posterior de su controlador, puede realizar un único cambio voluntario entre ataque y guardia durante la fase principal.

- Una criatura que ya atacó no puede pasar voluntariamente a guardia durante ese mismo turno.

- Una criatura que pasa de guardia a ataque puede atacar ese turno si no fue jugada ese mismo turno, no ha atacado todavía y ningún efecto se lo impide.

- Una criatura boca abajo puede revelarse manualmente en un turno posterior pasando a boca arriba en ataque. Puede atacar ese turno si cumple las condiciones normales.

- Cambiar de ataque a guardia no vuelve a ocultar la criatura: permanece boca arriba.

- Solo una carta o habilidad específica puede volver a colocar boca abajo una criatura ya revelada.

- Los cambios forzados por efectos pueden ignorar estas restricciones cuando el texto de la carta lo indique.

CRITERIO

Estas reglas se consideran simples y funcionales. No se añadirán costes, acciones adicionales ni excepciones generales mientras las pruebas no demuestren una necesidad real.

SIGUIENTE DISCUSIÓN

Definir el sistema básico de robo: robo automático por turno, mano inicial, primer turno y derrota al intentar robar de un mazo vacío.

==================================================

MECÁNICA 06 — MANO INICIAL Y ROBO NORMAL

==================================================

Estado: CERRADO PARA PROTOTIPO

Reglas confirmadas:

- Cada jugador comienza la partida con cinco cartas en la mano.

- Al comienzo de cada uno de sus turnos, el jugador roba una carta automáticamente.

- El jugador que comienza la partida no roba durante su primer turno.

- Las cartas mágicas, trampas y habilidades de criaturas pueden permitir robos adicionales si su texto lo indica.

- Una habilidad de criatura es un efecto de carta: no constituye un sistema de robo distinto y debe cumplir sus condiciones, costes y momento de activación.

- No existe descarte obligatorio por tamaño máximo de mano en el primer prototipo.

- Si un jugador debe robar una carta y su mazo está vacío, pierde la partida.

Razón de diseño:

- El robo normal garantiza que la partida avance y que un jugador no quede bloqueado permanentemente con una mano inútil.

- Los efectos de robo adicional serán ventajas valoradas dentro del presupuesto de cada carta.

Decisiones todavía pendientes relacionadas:

- tamaño del mazo cerrado provisionalmente en 40 cartas;

- los mazos personalizados no tienen un máximo general de copias de una misma carta, salvo restricciones específicas;

- posibilidad y reglas de cambio de mano inicial;

- sistema de recursos y costes.

SIGUIENTE DISCUSIÓN RECOMENDADA

El tamaño del mazo queda fijado provisionalmente en 40 cartas. La construcción personalizada permite repetir libremente una carta, salvo restricciones específicas. La siguiente discusión será el sistema de recursos y costes.

==================================================

MECÁNICA 07 — TAMAÑO DEL MAZO Y CARTAS ÚNICAS DEL MAZO BASE

==================================================

Estado: CERRADO PARA PROTOTIPO en tamaño, composición del mazo base y libertad de copias en mazos personalizados.

REGLAS CONFIRMADAS

- El mazo principal tendrá 40 cartas.

- El mazo original o preconstruido del juego estará formado por 40 cartas diferentes, sin repetir exactamente la misma carta.

- Esto significa nombres, ilustraciones y efectos propios para cada carta del mazo base; podrán existir familias, versiones relacionadas y cartas con funciones parecidas, pero no copias idénticas dentro de ese mazo.

- Las entidades de Fusión y Ritual no forman parte de las 40 cartas del mazo principal ni se roban. Se generan cuando se cumplen sus requisitos o recetas y desaparecen como entidades generadas cuando dejan de existir, según sus reglas.

CONSTRUCCIÓN PERSONALIZADA

- Cuando el jugador construya su propio mazo, podrá incluir tantas copias de una misma carta como desee hasta completar el mazo, salvo que esa carta o un formato concreto establezcan una restricción.

- El mazo base sin duplicados es una decisión de producto y diseño inicial, no una regla universal que obligue a todos los mazos a ser de carta única.

- No existe un máximo universal de copias de una misma carta en un mazo personalizado.

- Queda descartada la prohibición general de copias ilimitadas. La pérdida de variedad, las manos repetitivas, la falta de criaturas o de objetivos legales y la dependencia de una sola estrategia son riesgos asumidos por quien construye el mazo.

RAZÓN DE DISEÑO

- Cuarenta cartas distintas muestran mejor la variedad de criaturas, magias, trampas, objetos y terrenos del juego.

- El mazo original debe servir para descubrir interacciones y estilos, no para repetir tres veces las cartas más eficientes.

- La ausencia de duplicados reduce la consistencia de combinaciones concretas, por lo que el mazo base necesitará familias, buscadores, cartas flexibles o rutas alternativas cuando diseñemos sus estrategias.

- Para las primeras pruebas físicas no es obligatorio ilustrar cuarenta cartas terminadas: pueden utilizarse prototipos de texto y arte temporal, pero cada entrada representará una carta distinta.

SIGUIENTE DISCUSIÓN

Definir el sistema de recursos y costes: qué limita jugar criaturas, magias, trampas, objetos y habilidades durante un turno.

==================================================

MECÁNICA 08 — PROPUESTA DE ENERGÍA AUTOMÁTICA

==================================================

Estado: PROVISIONAL. Propuesta del diseñador asistente para probar; puede modificarse después de las primeras partidas.

OBJETIVO

- Diferenciar cartas pequeñas, medias y poderosas sin introducir cartas de recurso dentro del mazo.

- Evitar perder por no robar energía o maná.

- Limitar la cantidad de cartas y efectos fuertes que pueden utilizarse en un mismo turno.

- Controlar principalmente el ritmo de entrada de criaturas y otros efectos que indiquen expresamente un coste de energía.

SISTEMA PROPUESTO

1. Cada jugador tiene Energía máxima y Energía disponible.

2. Durante su primer turno dispone de 1 de Energía máxima y 1 disponible.

3. Al comienzo de cada turno propio posterior, la Energía máxima aumenta en 1, hasta un límite provisional de 10.

4. Después del aumento, la Energía disponible se rellena hasta la Energía máxima.

5. La energía no se acumula por encima del máximo. La energía que no se gasta permanece disponible durante el turno rival, pero al comenzar el siguiente turno simplemente se rellena hasta el máximo.

6. La energía es pública para ambos jugadores.

QUÉ GASTA ENERGÍA

- Invocar o colocar una criatura paga el coste impreso de esa criatura.

- Las magias y trampas no pagan energía ni al prepararse ni al activarse, salvo que una carta excepcional indique expresamente un coste propio.

- Jugar un objeto, equipo, mejora persistente o terreno cuesta 0 de energía por regla general. Las cartas excepcionalmente poderosas pueden imponer un coste o penalización propios.

- Las habilidades solo gastan energía cuando su texto indica un coste.

- Atacar, cambiar de postura, revelar manualmente una criatura y realizar la invocación normal del turno no tienen un coste adicional de energía aparte del coste de la carta.

PREPARACIÓN Y RESPUESTAS

- Colocar y activar una magia o trampa no cuesta energía por regla general.

- Los cinco espacios de apoyo, el tiempo de preparación, la mano disponible y las condiciones de cada carta limitan cuántas opciones pueden mantenerse y resolverse.

- La energía no gastada puede seguir utilizándose durante el turno rival únicamente para habilidades u otros efectos que indiquen expresamente un coste de energía; las magias y trampas normales no la necesitan.

- Gastar toda la energía no impide activar magias o trampas válidas, pero sí puede impedir habilidades y otros efectos que exijan energía.

INVOCACIÓN

- Se mantiene una invocación o colocación normal de criatura por turno.

- Tener energía suficiente no permite por sí solo invocar varias criaturas normales.

- Las invocaciones adicionales requieren efectos, habilidades o reglas especiales y normalmente también pagan el coste de la criatura, salvo excepción escrita.

- Las criaturas extraordinarias pueden exigir además materiales, sacrificios, terreno, familia, transformación u otra condición; la energía no sustituye todos los requisitos especiales.

ESCALA INICIAL DE COSTES

- Coste 1: criaturas y efectos básicos.

- Coste 2–3: cartas eficientes de juego temprano y medio.

- Coste 4–5: criaturas fuertes, mejoras importantes y efectos decisivos.

- Coste 6–7: cartas de gran impacto y amenazas avanzadas.

- Coste 8–9: amenazas de juego tardío y efectos de enorme impacto.

- Coste 10: cartas culminantes, transformaciones extremas o efectos decisivos que deben exigir llegar al techo o utilizar aceleración.

- El coste 0 se reservará para pasivas, efectos automáticos o excepciones cuidadosamente controladas.

EJEMPLO DE DECISIÓN

Un jugador con 4 de energía puede:

- invocar una criatura de coste 4; todavía podrá activar magias o trampas preparadas que sean válidas, pero no habilidades que requieran energía;

- invocar una criatura de coste 2 y conservar 2 para habilidades u otros efectos que indiquen expresamente un coste de energía;

- no invocar y conservar los 4 para habilidades reactivas u otros efectos con coste de energía durante el turno rival;

- activar varias magias o trampas válidas sin pagar energía, limitado por su preparación, condiciones, espacios y cadena de respuestas.

VENTAJAS

- Progresión predecible sin cartas de recurso muertas.

- Permite valorar las cartas con una escala común.

- Reduce las explosiones de mano y la activación masiva de mejoras.

- Permite que las magias y trampas formen parte normal del juego desde los primeros turnos sin competir con la invocación de la criatura necesaria para protegerse.

- Conserva la invocación normal única y la estructura de campo ya acordada.

RIESGOS Y PRUEBAS NECESARIAS

- El límite de 10 es intuitivo y ofrece más niveles de diseño, pero puede retrasar demasiado las cartas culminantes; deberá probarse la duración real de las partidas.

- Pagar energía por criaturas y también limitar la invocación normal podría ralentizar demasiado el juego.

- Al no pagar energía, las magias y trampas demasiado universales o eficientes pueden dominar las cadenas; deberán equilibrarse mediante condiciones, preparación, consumo, ocupación de espacios y costes específicos.

- La energía visible al colocar una criatura oculta puede dar información aproximada sobre su potencia, aunque no revela su identidad.

- Debe comprobarse si el segundo jugador necesita alguna compensación adicional o si el robo y la posibilidad de atacar ya son suficientes.

CRITERIO PROVISIONAL

Se recomienda probar este sistema antes que un modelo basado exclusivamente en sacrificios o cartas de recurso. Los sacrificios, materiales y condiciones quedarán como costes especiales de determinadas cartas, no como requisito universal.

AJUSTE CONFIRMADO — TECHO DE ENERGÍA

- El límite provisional de Energía máxima cambia de 7 a 10.

- La progresión sigue siendo de una unidad por turno propio: 1, 2, 3... hasta 10.

- Diez se adopta por legibilidad, familiaridad y mayor espacio para diferenciar costes medios, altos y culminantes.

- No todas las partidas deberán llegar a 10 ni todas las barajas necesitarán cartas de coste 10.

- Alcanzar 10 en el décimo turno propio puede ser demasiado lento; las pruebas determinarán si hacen falta aceleración, una energía inicial distinta o un techo efectivo menor para ciertos formatos.

- Estado: PROVISIONAL PARA PRUEBAS.

AJUSTE CONFIRMADO — MAGIAS Y TRAMPAS SIN COSTE DE ENERGÍA

- Estado: CERRADO PARA PROTOTIPO.

- Preparar una magia o trampa en la zona de apoyo cuesta 0 de energía.

- Activar una magia o trampa válida cuesta 0 de energía por regla general.

- Las trampas y magias reactivas siguen necesitando preparación previa y no pueden activarse el turno en que fueron colocadas, salvo excepción escrita. Las magias de fase principal pueden jugarse y resolverse inmediatamente durante el turno propio.

- Cada carta debe cumplir su ventana, condición, objetivo y demás requisitos.

- Una carta especialmente poderosa puede exigir un coste propio escrito, como descartar una carta, sacrificar una criatura, perder vida, destruir un apoyo, controlar un terreno, retirar una carta o cumplir una combinación; no existe un coste universal de energía para las magias y trampas.

- No se establece un máximo artificial de activaciones por turno. El límite surge de la mano, los cinco espacios de apoyo, el turno de preparación, las condiciones, la cadena de respuestas y el consumo o permanencia de cada carta.

- La energía pasa a controlar principalmente la entrada de criaturas y las habilidades u otros efectos que indiquen expresamente que la utilizan. Objetos, terrenos y equipos son gratuitos por defecto.

- Ejemplo inicial: con 1 de energía, un jugador puede invocar una criatura de coste 1, utilizar magias de fase principal para reforzarla y preparar trampas o magias reactivas para turnos posteriores.

- Riesgo a probar: que las cadenas gratuitas permitan demasiados aumentos o respuestas en un solo enfrentamiento. La primera solución será ajustar cartas, condiciones, tiempos, espacios y costes específicos, no imponer automáticamente energía a toda magia y trampa.

==================================================

AJUSTE CONFIRMADO — OBJETOS, EQUIPOS, MEJORAS Y TERRENOS GRATUITOS

==================================================

Estado: CERRADO PARA PROTOTIPO.

REGLA GENERAL

- Jugar o equipar un objeto, equipo, mejora persistente o terreno cuesta 0 de energía por regla general.

- Estas cartas siguen consumiendo una carta de la mano. Los equipos y objetos vinculados usan el área de vínculos de su portador; los terrenos usan la zona de terreno; únicamente los apoyos independientes ocupan espacios de apoyo.

- Los equipos vinculados a una criatura permanecen expuestos al riesgo de perderse si la criatura es destruida, retirada, devuelta, robada o deja de ser un objetivo legal.

- Reunir un conjunto completo de equipo puede ser difícil por el robo, la preparación, la compatibilidad, los espacios y la posibilidad de interrupción; no se añade un impuesto universal de energía.

COSTES Y PENALIZACIONES ESPECÍFICOS

- Una carta o conjunto excepcionalmente poderoso puede exigir un precio escrito propio.

- Los posibles precios incluyen perder vida, sacrificar una criatura o apoyo, reducir ATAQUE o DEFENSA, impedir atacar, destruir una pieza, descartar otra carta, necesitar un terreno o mantener una condición concreta.

- También pueden existir penalizaciones continuas. Ejemplo conceptual: una Armadura Maldita completa concede una bonificación ofensiva extraordinaria, pero hace perder vida cada turno o reduce progresivamente otra capacidad.

- El coste debe corresponder al efecto concreto; no se aplicará automáticamente a todos los equipos del mismo tipo.

COMBINACIONES Y CONTRAJUEGO

- El jugador puede combinar otras cartas para reducir, redirigir o neutralizar una penalización cuando sus textos y compatibilidades lo permitan.

- Conseguir esa protección adicional forma parte de la construcción estratégica y aumenta la inversión concentrada en la criatura.

- El rival conserva contrajuego mediante destrucción, anulación, retirada, transformación, robo de la criatura o separación de las piezas vinculadas.

- No se garantizará que toda penalización pueda eliminarse fácilmente; algunas serán parte inseparable de la identidad de la carta.

ACLARACIÓN SOBRE RECURSOS

- Por ahora no existe una reserva separada de «puntos de magia». El recurso universal provisional continúa llamándose Energía.

- Una carta futura puede utilizar contadores, cargas o un recurso propio si su mecánica lo necesita, pero eso será una excepción escrita y no un segundo sistema universal añadido ahora.

- Con este ajuste, la Energía controla principalmente la invocación de criaturas y las habilidades o efectos que indiquen expresamente un coste.

- La hoja de presupuesto deberá separar el valor de diseño de una carta de su coste de Energía: una mejora gratuita al jugarse puede seguir siendo muy poderosa y debe equilibrarse por efecto, requisitos, riesgo, permanencia y sinergias.

==================================================

AJUSTE CONFIRMADO — ACTIVACIÓN INMEDIATA DE EQUIPOS Y TERRENOS

==================================================

Estado: CERRADO PARA PROTOTIPO.

- Los objetos, equipos, mejoras persistentes y terrenos se juegan boca arriba durante una fase principal.

- Entran en funcionamiento inmediatamente después de jugarse y resolverse; no necesitan esperar hasta el siguiente turno.

- Al ser visibles, el rival conoce qué efecto ha entrado en juego y puede responder mediante cartas o habilidades válidas.

- Una criatura puede beneficiarse del equipo colocado ese mismo turno y, si puede atacar, utilizar esas mejoras durante el combate posterior.

- No se impone por ahora un límite general de equipos jugados por turno. Los límites naturales son la mano, los espacios, la compatibilidad, los objetivos legales y el riesgo de concentrar varias cartas en una criatura.

- Si las pruebas muestran explosiones demasiado rápidas, se ajustarán las cartas o conjuntos concretos antes de crear una restricción universal.

SIGUIENTE DISCUSIÓN DEL NÚCLEO

Definir la estructura exacta de cada turno: inicio y energía, robo, primera fase principal, combate, segunda fase principal y final.

==================================================

MECÁNICA 09 — ESTRUCTURA DEL TURNO

==================================================

Estado: CERRADO PARA PROTOTIPO.

ORDEN DE FASES

1. Inicio.

2. Robo.

3. Primera fase principal.

4. Combate.

5. Segunda fase principal.

6. Final.

1. INICIO

- Se resuelven los efectos que indiquen «al comienzo de tu turno».

- La Energía máxima aumenta en 1 hasta el máximo provisional de 10 y la Energía disponible se rellena.

- Se restauran los usos de ataque y las habilidades limitadas por turno.

2. ROBO

- El jugador roba una carta automáticamente.

- El jugador inicial omite este robo durante su primer turno.

- Los efectos relacionados con el robo se resuelven según sus condiciones.

3. PRIMERA FASE PRINCIPAL

- El jugador puede realizar su invocación o colocación normal del turno, invocaciones especiales permitidas, cambios de postura, revelaciones manuales, preparación de trampas y magias reactivas, uso de magias de fase principal, equipo, objetos, terrenos, habilidades, transformaciones y futuras fusiones.

- El jugador elige el orden de sus acciones mientras sean legales.

- Puede invocar una criatura y reforzarla inmediatamente con magias, objetos o varias piezas de equipo disponibles.

- Concentrar muchas cartas en la primera criatura es una decisión legal del jugador y asume el riesgo de perder toda la inversión si esa criatura es eliminada.

4. COMBATE

- El jugador declara ataques uno por uno y puede finalizar voluntariamente la fase aunque aún tenga ataques disponibles.

- Cada criatura dispone normalmente de un ataque por turno.

- Cada ataque abre sus ventanas de respuesta y después resuelve revelaciones, efectos, doble comparación y daño sobrante.

5. SEGUNDA FASE PRINCIPAL

- El jugador puede volver a realizar las acciones permitidas en una fase principal.

- Puede utilizar aquí la invocación normal si no la utilizó antes del combate.

- Puede equipar supervivientes, preparar respuestas, jugar terreno o realizar transformaciones posteriores al combate.

- Una criatura que haya atacado no puede pasar voluntariamente a guardia durante ese turno.

6. FINAL

- Se resuelven los efectos de «al final del turno».

- Terminan los modificadores que duren hasta el final del turno.

- Se aplican pérdidas, sacrificios, mantenimientos y otras consecuencias obligatorias indicadas por las cartas.

- El turno pasa al rival.

==================================================

AJUSTE CONFIRMADO — MOMENTO DE USO DE MAGIAS Y TRAMPAS

==================================================

Estado: CERRADO PARA PROTOTIPO en el principio general; los nombres definitivos de los subtipos se decidirán después.

- Magia de fase principal: se juega boca arriba desde la mano durante una fase principal propia, se resuelve inmediatamente y puede reforzar una criatura jugada ese mismo turno.

- Magia persistente: se juega boca arriba durante una fase principal propia, empieza a funcionar inmediatamente y permanece en el campo mientras dure su efecto.

- Magia reactiva: debe colocarse boca abajo previamente; no puede activarse el turno en que fue colocada y solo responde en las ventanas que indique su texto.

- Trampa: debe colocarse boca abajo previamente; no puede activarse el turno en que fue colocada y necesita que se cumpla su condición.

- Ninguna magia de fase principal puede aparecer desde la mano como respuesta sorpresa durante un ataque o durante el turno rival.

- Las excepciones deben estar escritas expresamente en la carta.

SIGUIENTE DISCUSIÓN DEL NÚCLEO

La distinción entre Magia y Trampa se basa principalmente en su forma y momento de uso, no en reservar familias de efectos exclusivas. La siguiente discusión será cerrar el ciclo de vida de una carta: resolución, pérdida del objetivo, destrucción y destino de las cartas vinculadas.

==================================================

PRINCIPIO CONFIRMADO — REDUNDANCIA FUNCIONAL Y VARIANTES DE CARTAS

==================================================

Estado: CERRADO COMO FILOSOFÍA DE DISEÑO.

- Dos o más cartas pueden compartir el mismo efecto básico o una estructura mecánica casi idéntica.

- Magias, trampas, criaturas, equipos y terrenos no necesitan tener efectos exclusivos de su categoría, nombre o ilustración.

- Una misma función puede reaparecer con diferencias de potencia, umbral, objetivo, duración, condición, ventana de activación, coste específico, elemento, familia, compatibilidad o consecuencias adicionales.

- También pueden existir cartas con el mismo resultado mecánico inmediato pero distinta identidad elemental o de conjunto. Esa identidad puede cambiar qué criaturas las utilizan, con qué equipos se combinan, qué terrenos las potencian y qué transformaciones permiten.

- Ejemplo estructural: varias trampas pueden destruir una criatura atacante, pero una puede limitarse a criaturas débiles, otra admitir objetivos más fuertes y otra exigir una condición o producir una consecuencia adicional.

- Ejemplo de equipo: Armadura Maldita y Armadura Divina pueden compartir una mejora parcial, pero sus piezas completas, penalizaciones, elementos, compatibilidades y posibles fusiones de equipo pueden ser diferentes.

- Luz y Oscuridad, o Fuego y Agua, pueden contener cartas con funciones similares sin que sus objetos sean fácilmente compatibles. Hielo y Agua pueden tener compatibilidad mayor cuando las reglas o etiquetas lo indiquen.

- Las cartas casi repetidas pueden servir para dar consistencia, completar familias y permitir barajas elementales distintas. No se tratarán automáticamente como un error de diseño ni como copias exactas de la misma carta.

- En el mazo base de 40 cartas, cada entrada seguirá teniendo nombre, ilustración e identidad propios, pero puede compartir exactamente el mismo efecto y valores con otra carta. No se exige una diferencia mecánica artificial.

- No se modificarán cifras, condiciones o efectos solo para fingir variedad. La identidad visual, narrativa, elemental o de conjunto puede justificar dos cartas mecánicamente iguales.

ACLARACIÓN SOBRE MAGIAS Y TRAMPAS

- Una Magia reactiva y una Trampa pueden producir efectos semejantes o incluso iguales.

- Su diferencia reglamentaria principal será cómo se preparan, cuándo pueden activarse y qué condiciones establece el texto, no una obligación de utilizar efectos distintos.

- No se diseñará una lista artificial de efectos reservados exclusivamente para Magias o exclusivamente para Trampas.

SIGUIENTE DISCUSIÓN DEL NÚCLEO

Cerrar el ciclo de vida de las cartas: qué ocurre cuando una carta se resuelve, pierde su objetivo, es destruida o está vinculada a una criatura que abandona el campo.

==================================================

CORRECCIÓN CONFIRMADA — COPIAS LIBRES Y COSTE ESTRATÉGICO DE LA REPETICIÓN

==================================================

Estado: CERRADO PARA PROTOTIPO.

- El mazo principal personalizado mantiene 40 cartas, pero no tiene un máximo general de copias de una misma carta.

- Un jugador puede incluir cinco, seis o incluso cuarenta copias de una carta si desea asumir las consecuencias de esa construcción.

- Las restricciones de una carta concreta, una lista especial o un formato competitivo podrán imponer límites individuales más adelante; no existe una restricción universal por defecto.

- Repetir muchas veces una carta consume espacio del mazo y reduce la variedad de criaturas, respuestas, objetivos y condiciones disponibles.

- Una mano formada por curaciones, mejoras sin objetivo, equipos incompatibles o respuestas situacionales puede dejar el campo vacío y provocar una derrota. Ese riesgo forma parte de la estrategia de construcción.

- Tener muchas copias en el mazo no genera por sí mismo una penalización. La penalización surge cuando las cartas se usan de una forma que provoque Sobrecarga física, Sobrecarga mágica, incompatibilidad elemental, exceso de peso u otro estado definido.

- Equipar varias piezas iguales o acumular muchas mejoras puede ser legal, pero las reglas de compatibilidad y sobrecarga pueden reducir ATAQUE, DEFENSA, movilidad, capacidad mágica u otras funciones.

- Una carta o habilidad puede romper expresamente esos límites: permitir más equipo del habitual, ignorar una sobrecarga, estabilizar elementos incompatibles o convertir la acumulación en una ventaja.

- Principio general: las reglas establecen el comportamiento normal; el texto explícito de una carta puede crear una excepción controlada.

- El mazo base entregado con el juego continúa formado por 40 cartas distintas como producto inicial. Esta decisión no limita la construcción posterior del jugador.

ACLARACIÓN DE REFERENCIA

- En el Yu-Gi-Oh! oficial existe normalmente un máximo de tres copias de una misma carta, con cartas Limitadas o Semi-Limitadas reducidas a una o dos. Nuestro juego se aparta deliberadamente de esa regla y probará copias libres.

SIGUIENTE DISCUSIÓN DEL NÚCLEO

Cerrar el ciclo de vida de las cartas: resolución, pérdida del objetivo, destrucción y destino de los equipos o mejoras vinculados.

==================================================

ACLARACIÓN CONFIRMADA — PERMANENCIA DE CRIATURAS Y PÉRDIDA DE OBJETIVO

==================================================

Estado: CERRADO PARA PROTOTIPO en la permanencia de criaturas; PROVISIONAL en la cifra de vida.

PERMANENCIA DESPUÉS DEL COMBATE

- Una criatura que participa en un combate no se consume ni abandona el campo por haber atacado o destruido a otra criatura.

- Si sobrevive a la doble comparación, permanece en su espacio con sus equipos, mejoras, estados y vínculos que continúen siendo legales.

- Destruir a la criatura objetivo solo consume el ataque normal disponible de la criatura atacante durante ese turno.

- La misma criatura podrá volver a atacar durante un turno posterior de su controlador.

- No puede atacar inmediatamente a una segunda criatura durante el mismo turno salvo que una carta o habilidad le conceda un ataque adicional.

- Si la represalia del defensor supera la DEFENSA del atacante, el atacante también es destruido conforme a las reglas normales, aunque haya destruido a su objetivo.

SIGNIFICADO DE «PERDER EL OBJETIVO»

- Esta expresión no significa que una criatura desaparezca después de vencer a su adversario.

- Se refiere principalmente a una magia, trampa o habilidad que ha elegido un objetivo y todavía está pendiente de resolverse.

- Si ese objetivo abandona el campo, deja de cumplir los requisitos o se vuelve inaccesible antes de la resolución, el efecto no se aplica a ese objetivo.

- Una carta no elige automáticamente un objetivo nuevo salvo que su texto lo permita.

- Si el efecto tiene varios objetivos, se aplica a los que sigan siendo legales, salvo que el texto exija que todos continúen presentes.

- Los efectos de área o los efectos que no seleccionan un objetivo concreto no fallan por la desaparición de una sola criatura, aunque pueden verse modificados por el estado final del campo.

EJEMPLO BÁSICO

- Una criatura ataca a un enemigo y lo destruye.

- La criatura atacante permanece en el campo si la represalia no la destruye.

- Durante ese turno ya ha gastado su ataque normal.

- En su siguiente turno podrá atacar a otra criatura o directamente al jugador si este no controla ninguna criatura protectora.

CRITERIO DE PRUEBA PARA LOS PUNTOS DE VIDA

- Los 30 puntos de vida continúan siendo una cifra provisional, no una decisión definitiva.

- Una única criatura con 10 de ATAQUE necesita tres ataques directos en tres turnos distintos para reducir 30 puntos de vida a 0, porque normalmente solo ataca una vez por turno.

- Esto coincide aproximadamente con el objetivo de que un jugador completamente expuesto disponga de dos o tres turnos para reconstruir su defensa frente a una amenaza fuerte individual.

- El riesgo de derrota en un solo turno procede principalmente de varias criaturas atacando, ataques adicionales, daño directo o una criatura mejorada hasta cifras extraordinarias.

- No se garantiza que un jugador sobreviva dos o tres turnos frente a un campo enemigo completo ya desarrollado; quedar sin criaturas ante varias amenazas puede justificar una derrota rápida.

- Antes de aumentar la vida inicial se probarán al menos dos escenarios: 30 puntos y, si aparecen derrotas explosivas demasiado frecuentes, 40 puntos.

- También se revisarán el valor máximo habitual de ATAQUE, la facilidad para acumular mejoras y la frecuencia del daño sobrante; subir la vida sin revisar esas variables podría alargar todas las partidas sin resolver la causa real.

SIGUIENTE PARTE DEL CICLO DE VIDA

Definir qué sucede con equipos y mejoras cuando la criatura vinculada es destruida, devuelta a la mano, robada, transformada o utilizada como material de fusión.

==================================================

MECÁNICA 10 — DURACIÓN DE EFECTOS Y ÁREA DE VÍNCULOS

==================================================

Estado: CERRADO PARA PROTOTIPO en duración básica y separación del equipo respecto a la zona de apoyo; PROVISIONAL en la representación física exacta y en los límites anatómicos.

DURACIÓN BÁSICA DE LOS EFECTOS

- Cada carta o habilidad indica su duración. No existe una duración oculta ni una regla que prolongue un efecto por defecto.

- Efecto inmediato: se resuelve una vez y termina. Si procede de una magia o trampa de un solo uso, esa carta pasa después a la zona de usadas.

- Efecto temporal: permanece durante el tiempo escrito, por ejemplo hasta el final del turno, durante un combate o durante un número concreto de turnos; al terminar ese plazo, desaparece.

- Efecto persistente: continúa mientras la carta, equipo, terreno, estado o fuente que lo mantiene siga en juego y conserve sus condiciones.

- Modificación permanente: solo existe cuando el texto indica expresamente que el cambio permanece aunque la fuente abandone el campo. Se reservará para cartas concretas y no se confundirá con un apoyo persistente.

- Una carta rara podrá prolongar, conservar o convertir en persistente un efecto que normalmente sería temporal o de un solo uso. Estas cartas se diseñarán en una fase posterior y exigirán condiciones, riesgos o costes importantes.

PLAN DE DESARROLLO DE CARTAS

- El primer mazo se centrará en criaturas, magias, trampas, equipos y terrenos sencillos, con efectos fáciles de comprobar.

- Una segunda etapa podrá introducir cartas que prolonguen efectos, recuperen apoyos, alteren duraciones o rompan reglas normales mediante costes elevados.

- Después se diseñarán barajas o familias elementales y, más adelante, fusiones, transformaciones y combinaciones avanzadas.

SEPARACIÓN ENTRE APOYOS Y EQUIPO

- Los cinco espacios de apoyo se reservan para magias persistentes, trampas preparadas, artefactos independientes y otros efectos que existan por sí mismos en el campo.

- Una pieza de armadura, arma, casco, libro, grimorio u objeto llevado por una criatura se vincula directamente a esa criatura y no consume un espacio de apoyo.

- Cada criatura dispone conceptualmente de un Área de vínculos donde se colocan sus equipos, objetos, auras y mejoras adjuntas.

- La representación exacta queda aplazada al diseño gráfico y de interfaz. Entre las opciones válidas están apilar las cartas parcialmente detrás de la criatura, mostrar un indicador con el número de vínculos y abrir la pila mediante doble clic o una vista desplegable.

- No se fija todavía una fila, casilla o panel gráfico definitivo para cada criatura. El sistema debe poder mostrar equipos distintos para cada portador sin agrandar innecesariamente el tablero.

- Tampoco se fija un máximo numérico universal de objetos vinculados. Los límites procederán de anatomía, categorías corporales, manos disponibles, peso, compatibilidad y estados de Sobrecarga.

- Un conjunto completo de armadura puede utilizar varias cartas vinculadas al mismo portador sin bloquear las zonas de magia y trampa.

CLASIFICACIÓN DE OBJETOS

- Objeto vinculado: lo porta o utiliza una criatura; se coloca en su Área de vínculos. Ejemplos: espada, casco, peto, botas, grimorio o amuleto.

- Artefacto independiente: funciona por sí mismo en el campo y ocupa un espacio de apoyo. Ejemplos: altar, torre, máquina, tótem o reliquia que afecte a todo el campo.

- Terreno: ocupa la zona de terreno y sigue sus reglas propias.

- El nombre o la apariencia no decide por sí solos la zona; la función escrita de la carta determina si está vinculada, es independiente o es terreno.

SIGUIENTE DISCUSIÓN DEL NÚCLEO

Definir el destino de los equipos y objetos vinculados cuando su portador es destruido, devuelto a la mano, robado, transformado o utilizado como material de fusión.

==================================================

ACLARACIÓN — REPRESENTACIÓN DEL EQUIPO APLAZADA

==================================================

Estado: CERRADO en la relación mecánica; ABIERTO en gráficos e interfaz.

- Cada equipo, objeto o mejora vinculada pertenece a una criatura concreta. Dos criaturas pueden llevar conjuntos completamente diferentes.

- Las cartas vinculadas no ocupan los cinco espacios generales de apoyo.

- No es necesario decidir ahora una zona gráfica separada ni dibujar casillas corporales en el tablero.

- Una posible interfaz digital es mantener las cartas apiladas visualmente detrás de su criatura, mostrar solo una parte o un contador y permitir abrir la colección vinculada mediante doble clic, toque o selección.

- También podrá utilizarse un panel lateral o una vista detallada si resulta más legible durante la implementación.

- La elección entre estas representaciones será una decisión de diseño gráfico y experiencia de usuario, no una modificación de las reglas.

- Para el prototipo de reglas basta con registrar internamente qué cartas están vinculadas a cada criatura y qué efectos, compatibilidades o sobrecargas producen.

SIGUIENTE DISCUSIÓN DEL NÚCLEO

Definir el destino de los equipos y mejoras cuando su portador abandona el campo o cambia de estado relevante.

==================================================

MECÁNICA 11 — DESTRUCCIÓN DEL PORTADOR Y PÉRDIDA DEL EQUIPO

==================================================

Estado: CERRADO PARA PROTOTIPO.

REGLA GENERAL

- Cuando una criatura es destruida, todas las cartas de equipo, objetos y mejoras vinculadas a ella van también al Cementerio o Zona de usadas.

- La destrucción del portador termina inmediatamente las bonificaciones y efectos persistentes que dependían de esos vínculos.

- Equipar varias cartas sobre una misma criatura es una apuesta estratégica: aumenta mucho su poder, pero concentra la inversión y puede provocar una pérdida múltiple.

- No existe una protección automática para el equipo ni una devolución general a la mano o al mazo.

EXCEPCIONES ESCRITAS

- Una magia, trampa, habilidad o texto del propio objeto puede salvar, transferir, recuperar, devolver a la mano, devolver al mazo o mantener una pieza de equipo.

- Algunos objetos especiales pueden establecer un destino distinto al ser destruidos junto con su portador, por ejemplo regresar al mazo y barajarlo.

- Estas excepciones se aplican únicamente cuando el texto lo indique expresamente.

RECUPERACIÓN POSTERIOR

- Podrán existir cartas capaces de recuperar objetos desde el Cementerio o restaurar parte de un conjunto perdido.

- Recuperar un equipo completo será una ventaja fuerte y deberá exigir una inversión, condición, riesgo o coste considerable.

- No se garantiza que una baraja pueda recuperar todas sus piezas; perder el conjunto por una mala protección forma parte del riesgo asumido por el jugador.

CRITERIO DE DISEÑO

- El equipo concede una mejora persistente mientras el portador siga en juego.

- La posibilidad de perder todas las piezas al mismo tiempo es uno de sus principales costes estratégicos y no debe eliminarse mediante una regla general de seguridad.

SIGUIENTE DISCUSIÓN DEL NÚCLEO

Definir qué ocurre con el equipo cuando la criatura no es destruida, sino devuelta a la mano, cambiada de controlador, transformada o utilizada como material de fusión.

==================================================

REGLA CONFIRMADA — REVIVIR NO RECUPERA EQUIPO

==================================================

Estado: CERRADO PARA PROTOTIPO.

- Cuando una criatura es destruida, sus equipos, objetos y mejoras vinculadas se separan de ella y van al Cementerio como cartas independientes.

- Si posteriormente una carta revive esa criatura, solo regresa la carta de criatura.

- La criatura revive con sus valores, habilidades y estado base, sin recuperar automáticamente ningún equipo, mejora, aura, pieza de armadura ni vínculo que tuviera antes de morir.

- Los objetos destruidos permanecen en el Cementerio aunque el portador regrese al campo.

- Revivir no reconstruye la situación anterior al combate ni conserva una «instantánea» del portador equipado.

- Esta regla evita que un jugador equipe por completo una criatura, la sacrifique deliberadamente y la recupere después con toda la inversión intacta.

- Narrativamente, si la criatura fue destruida tras superar su DEFENSA, se considera que el equipo que la protegía también fue roto, perdido o inutilizado durante esa derrota.

RECUPERACIÓN DE OBJETOS

- Recuperar una pieza de equipo del Cementerio requiere una carta, habilidad o efecto específico.

- Recuperar una sola pieza puede existir como efecto normal pero valioso.

- Recuperar varias piezas o un conjunto completo debe ser raro, difícil y exigir un coste, condición o preparación importante.

- Una carta excepcional puede indicar que un objeto vuelve a la mano, se baraja en el mazo, permanece intacto, se transfiere o revive junto al portador. Esa excepción debe estar escrita expresamente.

- Por defecto, revivir una criatura y recuperar su equipo son dos acciones separadas.

PRINCIPIO ESTRATÉGICO

- Equipar una criatura es una inversión permanente mientras sobreviva, pero también una apuesta: cuanto más se concentra sobre un solo portador, mayor es la pérdida si ese portador es destruido.

- Proteger al portador, impedir su destrucción o recuperar después piezas concretas forman parte de la estrategia; el sistema no devuelve gratuitamente la inversión perdida.

==================================================

AJUSTE CONFIRMADO — DEVOLVER UNA CRIATURA A LA MANO Y DESTINO DEL EQUIPO

==================================================

Estado: CERRADO PARA PROTOTIPO.

- Cuando una criatura equipada abandona el campo para volver a la mano, todas las cartas de equipo, objetos y mejoras que dependan de estar vinculadas a ella pierden su portador y van al Cementerio, salvo excepción escrita.

- La criatura vuelve sola a la mano. No arrastra consigo su equipo ni sus mejoras vinculadas.

- Esta regla se aplica aunque la criatura no haya sido destruida. Devolverla a la mano sigue siendo una forma de romper la inversión acumulada sobre ella.

- Por tanto, una carta que devuelve una criatura fuertemente equipada a la mano puede ser una respuesta estratégica muy poderosa, porque elimina temporalmente a la criatura y manda al Cementerio las cartas que llevaba vinculadas.

- Las cartas excepcionales podrán indicar que una pieza vuelve a la mano, se transfiere a otro portador, se baraja en el mazo o sobrevive de otra forma.

- La lógica de referencia coincide con Yu-Gi-Oh!: cuando el monstruo equipado deja el campo, las cartas de equipo pierden su objetivo y se destruyen / envían al Cementerio por la regla del juego.

- Para nuestro reglamento se mantendrá una redacción propia y sencilla: «si el portador abandona el campo, sus cartas vinculadas van al Cementerio, salvo que una carta indique lo contrario».

SIGUIENTE DISCUSIÓN DEL NÚCLEO

Definir qué ocurre con equipos y mejoras cuando una criatura cambia de controlador, se transforma o se utiliza como material de fusión.

==================================================

AJUSTE CONFIRMADO — CAMBIO DE CONTROL Y EQUIPO VINCULADO

==================================================

Estado: CERRADO PARA PROTOTIPO.

- Cambiar el controlador de una criatura no destruye, desequipa ni reinicia automáticamente sus equipos, objetos, auras o mejoras vinculadas.

- La criatura pasa al campo o control del nuevo controlador con todos los vínculos que sigan siendo legales, y continúa recibiendo sus bonificaciones, penalizaciones y efectos.

- La propiedad de las cartas no cambia por el robo de control. La criatura sigue perteneciendo a su dueño original aunque otro jugador la controle temporal o permanentemente.

- Del mismo modo, cada pieza de equipo sigue perteneciendo a su dueño original. En la representación física o digital puede seguir registrada visualmente del lado de su propietario, pero permanece vinculada a la criatura robada y sus efectos se aplican a esa criatura.

- El nuevo controlador no obtiene por defecto la facultad de retirar, apagar, devolver o reorganizar las cartas vinculadas que pertenecen al rival. Para hacerlo necesita una regla, habilidad, magia, trampa u otro efecto que lo permita.

- El propietario original tampoco puede retirar gratuitamente sus equipos solo porque el rival haya tomado el control del portador. Deberá utilizar una carta o efecto válido para destruir, recuperar, transferir o separar esas piezas.

- Si el efecto que roba la criatura termina y esta vuelve a su controlador anterior, conserva los equipos y mejoras que sigan vinculados y sean legales en ese momento.

- Si durante el periodo de control ajeno la criatura es destruida o abandona el campo, se aplican las reglas normales: sus vínculos van al Cementerio salvo excepción escrita.

- Una carta concreta puede imponer una condición de compatibilidad o control que haga que un vínculo deje de ser legal. En ese caso se aplicará el destino indicado por esa carta o por las reglas generales de pérdida de vínculo.

REFERENCIA DE DISEÑO

- En Yu-Gi-Oh! existen cartas de Equipo que permanecen ligadas cuando cambia el control del monstruo equipado; incluso hay efectos que reaccionan expresamente a ese cambio de control. Nuestro juego adopta esa lógica general, pero con redacción y estructura propias.

PRINCIPIO ESTRATÉGICO

- Robar una criatura fuertemente equipada puede ser especialmente poderoso porque el jugador que la roba aprovecha temporalmente la inversión del rival.

- Esa posibilidad aumenta el riesgo de concentrar demasiadas mejoras sobre un único portador y crea contrajuego mediante cartas de recuperación, destrucción, separación o cambio de control.

SIGUIENTE DISCUSIÓN DEL NÚCLEO

Definir qué ocurre con los equipos y mejoras cuando una criatura se transforma o se utiliza como material de fusión.

==================================================

DIRECCIÓN DE DISEÑO — EQUIPO GENÉRICO, ANATOMÍA Y CAMBIOS DE FORMA

==================================================

Estado: PROVISIONAL. Principio aceptado; detalle pendiente para la fase de transformaciones y fusiones.

PRINCIPIO GENERAL

- No se creará una versión distinta de cada armadura para cada especie. El equipo básico debe ser suficientemente reutilizable para no llenar el mazo de cartas que solo sirven para una criatura concreta.

- La compatibilidad se decidirá mediante categorías generales de anatomía, tipo de pieza y requisitos escritos, no mediante listas enormes de especies permitidas.

- El equipo específico para dragones, bestias marinas, espectros u otras familias se reservará para cartas que ofrezcan una recompensa estratégica suficiente para justificar su menor versatilidad.

EQUIPO BÁSICO Y ANATOMÍA

- Las armaduras corporales genéricas podrán equiparse a muchas criaturas mientras posean una forma corporal razonablemente compatible con esa pieza.

- No toda pieza de un conjunto tiene que ser utilizable por toda criatura. Un ser sin extremidades adecuadas puede usar protección corporal pero no botas, guantes o armas que exijan manos.

- Un dragón puede ser compatible con varias piezas si su anatomía proporciona cabeza, cuerpo, extremidades y puntos de apoyo equivalentes, sin exigir fabricar necesariamente un set exclusivo de dragón.

- Una criatura marina con cuerpo incompatible puede usar únicamente las piezas que tengan sentido para su anatomía o equipos específicamente diseñados para formas acuáticas.

- El motor utilizará etiquetas y requisitos; la ilustración orienta la fantasía, pero no será la única fuente de la regla.

TRANSFORMACIÓN, MUTACIÓN Y FUSIÓN

- No se aplicará una regla universal de que transformar o fusionar destruya todo el equipo.

- Después de una transformación, mutación o fusión, se vuelve a comprobar la legalidad de cada vínculo.

- Todo equipo que siga siendo compatible con la nueva anatomía y requisitos continúa vinculado y funcionando.

- Si el cambio elimina una parte corporal o requisito necesario, la pieza deja de ser legal y su destino se decidirá por la regla de pérdida de vínculo o por el texto de la transformación.

- Una fusión puede conservar equipo si la entidad resultante mantiene compatibilidad suficiente. Otras fusiones podrán destruir, absorber, transformar o expulsar piezas si su receta lo indica.

ELEMENTO

- La compatibilidad física y la compatibilidad elemental son capas distintas.

- Una pieza físicamente válida puede seguir equipada tras un cambio elemental, pero su efecto puede cambiar si el nuevo elemento entra en conflicto con ella.

- Ejemplo conceptual: una Armadura Oscura puede funcionar normalmente sobre una criatura Oscura o parcialmente Oscura; si una transformación elimina por completo Oscuridad y convierte al portador únicamente en Luz, la armadura puede causar penalización, daño, desactivarse o destruirse según las reglas elementales o el texto concreto.

- No se fijará todavía una reacción universal Luz/Oscuridad para todo el equipo; las reacciones elementales se cerrarán más adelante mediante etiquetas generales y recetas concretas.

CRITERIO DE DISEÑO

- El equipo genérico debe ser útil en muchas barajas.

- El equipo especializado debe ser menos universal pero suficientemente potente, sinérgico o transformador para que construir alrededor de él resulte una decisión estratégica real.

- La transformación y la fusión no reinician automáticamente una criatura: conservan los vínculos que sigan siendo legales y reevaluan los que hayan dejado de serlo.

SIGUIENTE DECISIÓN PENDIENTE

Decisión cerrada: cualquier pieza que deje de ser compatible por una transformación, mutación o fusión va al Cementerio por defecto, salvo excepción escrita.

==================================================

REGLA CONFIRMADA — PÉRDIDA DE COMPATIBILIDAD TRAS TRANSFORMACIÓN O FUSIÓN

==================================================

Estado: CERRADO PARA PROTOTIPO.

- Una transformación, mutación o fusión no elimina automáticamente todo el equipo de la criatura.

- Tras resolverse el cambio, se revisa cada pieza vinculada por separado.

- Las piezas que sigan siendo compatibles con la nueva anatomía, aptitudes y requisitos continúan equipadas y funcionando.

- Las piezas que dejen de ser compatibles van al Cementerio inmediatamente, salvo que una carta indique otro destino.

- La compatibilidad se evalúa por la parte o función necesaria. Si la criatura conserva torso, puede mantener una pieza de pecho; si conserva cabeza, puede mantener casco; si pierde las extremidades necesarias, las piezas de piernas, botas, guantes, brazales o armas que dependan de ellas dejan de ser legales.

- Perder una o varias piezas de un conjunto puede romper la bonificación de set. Las demás piezas compatibles permanecen equipadas y conservan sus efectos individuales.

- Transformarse puede convertirse así en una decisión estratégica: el jugador puede aceptar perder ciertas mejoras a cambio de obtener una forma o criatura superior.

- La compatibilidad elemental se revisa aparte de la compatibilidad anatómica. Una pieza físicamente válida puede conservarse pero sufrir penalizaciones, daño, desactivación o destrucción si las reglas elementales o su propio texto lo establecen.

- No se diseñará una versión distinta de cada armadura para cada especie. El equipo básico seguirá siendo genérico siempre que la anatomía permita utilizarlo.

EXCEPCIONES FUTURAS DE CARTA

- Podrán existir cartas capaces de adaptar o reconstruir equipo para una anatomía nueva.

- Ejemplo conceptual para una fase posterior: un efecto de Herrero podría transformar dos o más piezas incompatibles de un conjunto en piezas equivalentes compatibles con la nueva forma, permitiendo reconstruir el set.

- Esta posibilidad no es una regla general del juego; será una habilidad o carta concreta con sus propios requisitos, costes y límites.

SIGUIENTE DISCUSIÓN DEL NÚCLEO

Decisión amplia cerrada: una fusión verdadera puede heredar equipo compatible de todas sus criaturas materiales. El controlador decide qué piezas legales conserva el resultado; las incompatibles o voluntariamente no conservadas van al Cementerio.

==================================================

REGLA CONFIRMADA — HERENCIA DE EQUIPO EN FUSIONES Y TAMAÑO DE SETS

==================================================

Estado: CERRADO PARA PROTOTIPO en la herencia básica; PROVISIONAL en categorías exactas de las piezas y recetas avanzadas.

HERENCIA DE EQUIPO EN UNA FUSIÓN

- Cuando una fusión verdadera utiliza varias criaturas equipadas como materiales, el equipo no se destruye automáticamente por el mero hecho de fusionar.

- Se reúne conceptualmente el conjunto de cartas vinculadas a todos los materiales y se comprueba cuáles son compatibles con la criatura resultante.

- El controlador puede conservar en la criatura fusionada las piezas que sigan siendo legales y que quiera heredar. No está obligado a mantener todas las piezas compatibles si estratégicamente prefiere sacrificar alguna.

- Toda pieza incompatible con la anatomía, aptitudes, elemento o requisitos del resultado va al Cementerio por defecto, salvo excepción escrita.

- Toda pieza compatible que el jugador decida no conservar también va al Cementerio por defecto; la fusión no devuelve equipo gratis a la mano.

- Si dos piezas compiten por una misma función, espacio corporal, capacidad de manipulación, carga o condición incompatible, el controlador deberá elegir cuáles conserva, salvo que la fusión o una carta permita mantener ambas.

- Después de elegir el equipo heredado se recalculan bonificaciones individuales, penalizaciones, sobrecargas y bonificaciones de conjunto.

- Las piezas procedentes de criaturas distintas pueden completar juntas un conjunto si pertenecen al mismo set o cumplen la receta correspondiente. Ejemplo: una criatura aporta la parte inferior y otra aporta torso o casco; si el resultado puede usar todas las piezas, el set puede quedar completado tras la fusión.

- Una fusión Luz/Oscuridad puede conservar equipo de ambos elementos cuando la identidad elemental resultante y las reglas de compatibilidad lo permitan. Esa combinación puede generar nuevas bonificaciones, penalizaciones o reacciones cuando se diseñen las recetas elementales.

FUSIÓN DE EQUIPOS COMO MECÁNICA AVANZADA

- Dos conjuntos completos o varias piezas especiales podrán, en cartas o recetas avanzadas, fusionarse o transformarse en una nueva armadura.

- Esto no ocurre por regla general. Requerirá una receta, carta, habilidad o condición concreta.

- Obtener dos sets completos ya supone una inversión alta, por lo que una recompensa excepcional puede estar justificada si el equilibrio y el contrajuego lo permiten.

TAMAÑO DE LOS CONJUNTOS DE ARMADURA

- Se descarta como modelo normal un conjunto de cinco piezas independientes como casco, peto, guantes, pantalones y botas: consume demasiadas cartas del mazo y de la mano.

- Los conjuntos normales de armadura se diseñarán con dos o tres cartas como máximo.

- Varias prendas físicas pueden agruparse en una misma carta de equipo. Por ejemplo, una pieza puede representar conjuntamente protección de piernas y botas, o una categoría amplia de extremidades.

- La división exacta de las tres posibles categorías no se fija todavía. Se decidirá al diseñar los primeros sets reales, priorizando claridad, compatibilidad anatómica y valor estratégico de cada carta.

- Un set incompleto conserva los efectos individuales de sus piezas compatibles, pero no obtiene la bonificación de conjunto completo salvo que su texto indique otra cosa.

SIGUIENTE DISCUSIÓN DEL NÚCLEO

Con la herencia básica de equipo en fusiones resuelta, queda por decidir si necesitamos cerrar ahora alguna regla adicional del ciclo de vida o si el núcleo ya permite pasar a diseñar el primer mazo simple de prueba.

==================================================

REGLA CONFIRMADA — MATERIALES CONTENIDOS EN UNA FUSIÓN VERDADERA

==================================================

Estado: CERRADO PARA PROTOTIPO en el destino de los materiales y en que la entidad de Fusión es generada; ABIERTO únicamente en su representación gráfica exacta.

PRINCIPIO

- Fusionar criaturas no equivale a destruirlas ni sacrificarlas.

- Las criaturas utilizadas como materiales no van al Cementerio al resolverse la fusión.

- Quedan apartadas del campo y vinculadas internamente a la criatura fusionada como materiales contenidos en ella.

- Mientras la fusión permanezca activa, esos materiales no cuentan como criaturas en el campo ni como criaturas del Cementerio y no pueden revivirse, reutilizarse para otra fusión ni recuperarse por efectos que busquen cartas en el Cementerio, salvo excepción escrita.

- La forma física o digital de mostrar esos materiales queda para la interfaz: pueden almacenarse bajo la carta de fusión, en una vista asociada o en una zona especial. La representación no cambia la regla.

DESTRUCCIÓN DE LA FUSIÓN

- Cuando la criatura fusionada es destruida, las criaturas materiales que estaban contenidas en ella pasan al Cementerio.

- Los equipos y mejoras que estuvieran vinculados a la criatura fusionada siguen la regla normal de destrucción del portador y van también al Cementerio, salvo excepción escrita.

- De este modo, los materiales solo pasan a considerarse muertos cuando la fusión que los contiene es destruida.

- La criatura de Fusión resultante no es una carta robable ni una carta almacenada en una reserva de juego. Es una entidad generada por la receta. Cuando deja de existir, esa entidad desaparece; no va a la mano ni al Cementerio como una carta independiente.

REFERENCIA Y DIFERENCIA

- En Yu-Gi-Oh! el Monstruo de Fusión procede del Extra Deck, pero los materiales normalmente se envían al Cementerio al realizar la Invocación por Fusión. Nuestro juego se aparta deliberadamente de esa regla: los materiales permanecen contenidos en la fusión hasta que esta sea destruida.

RAZÓN ESTRATÉGICA

- Esta regla impide fusionar dos criaturas y acto seguido revivirlas desde el Cementerio para reutilizarlas mientras su propia fusión sigue en juego.

- También refuerza la lógica temática: las criaturas materiales no han muerto; continúan formando parte de la nueva entidad.

==================================================

DISTINCIÓN CONFIRMADA — FUSIÓN, SACRIFICIO Y RITUAL

==================================================

Estado: CERRADO COMO PRINCIPIO GENERAL; PROVISIONAL en el diseño detallado de rituales y en la zona final de las entidades rituales.

FUSIÓN

- Fusionar no equivale a sacrificar.

- Las criaturas materiales no mueren ni van al Cementerio al fusionarse; quedan contenidas en la entidad fusionada mientras esta exista.

- Si la fusión es destruida, sus materiales pasan entonces al Cementerio conforme a la regla ya cerrada.

SACRIFICIO

- Sacrificar sí consume la carta utilizada como coste.

- Una criatura sacrificada abandona el campo y va al Cementerio inmediatamente, salvo que una carta establezca expresamente otro destino.

- Una criatura sacrificada no queda contenida dentro de la entidad o efecto que se obtiene a cambio y puede ser tratada posteriormente como carta del Cementerio por efectos legales.

RITUAL — DIRECCIÓN DE DISEÑO

- Un Ritual es una invocación distinta de una Fusión: una carta o efecto de Ritual establece requisitos concretos y, al completarse, genera directamente la entidad ritual correspondiente. La criatura ritual resultante no se roba ni ocupa un hueco del mazo.

- Los requisitos pueden pedir sacrificar criaturas específicas, criaturas de determinados elementos, una cantidad concreta de criaturas u otras condiciones escritas.

- Las criaturas ofrecidas como sacrificio para completar el Ritual van al Cementerio al resolverse correctamente el Ritual.

- La carta de Ritual que mantiene o da existencia a la entidad ritual no se envía automáticamente al Cementerio al completar la invocación; permanece activa y vinculada a esa entidad mientras esta siga existiendo, salvo que su texto diga otra cosa.

- Cuando la entidad ritual sea destruida, la entidad generada desaparece del campo y la carta o fuente de Ritual que la mantenía vinculada pasa al Cementerio, salvo excepción escrita.

- La entidad ritual destruida no pasa por defecto a la mano, al mazo ni al Cementerio como carta normal: deja de existir como entidad generada. Para volver a obtenerla deberá realizarse de nuevo el Ritual, salvo excepción escrita.

PRINCIPIO DE VOCABULARIO

- «Fusionar» significa combinar materiales que continúan formando parte de la nueva entidad.

- «Sacrificar» significa entregar y perder cartas como coste; esas cartas van al Cementerio por defecto.

- «Ritual» significa pagar sacrificios o requisitos mediante una fuente ritual para generar una entidad distinta que no pertenece al mazo principal.

==================================================

REGLA CONFIRMADA — ENTIDADES GENERADAS DE FUSIÓN Y RITUAL

==================================================

Estado: CERRADO COMO ARQUITECTURA BÁSICA; ABIERTO en la presentación física o digital de estas entidades.

PRINCIPIO

- Una criatura de Fusión o una criatura Ritual resultante no necesita existir previamente como carta en la mano, el mazo principal ni una reserva que el jugador deba gestionar.

- El sistema conoce las recetas y resultados posibles. Al cumplirse el detonante, genera la entidad correspondiente en el campo.

- Estas entidades pueden mostrarse visualmente como una carta completa con nombre, ilustración, estadísticas y habilidades, pero esa representación no significa que exista una copia robable de esa carta dentro del mazo.

- Por tanto, las Fusiones y Rituales no ocupan huecos del mazo de 40 cartas y no producen manos muertas por robar una entidad que solo tiene sentido después de completar su condición.

FUSIÓN

- La propia combinación legal de dos o más criaturas es el detonante que genera la criatura fusionada, salvo que una receta concreta exija además otra condición.

- Las criaturas materiales permanecen contenidas dentro de la Fusión mientras esta exista, según la regla ya cerrada.

- Cuando la Fusión es destruida, la entidad fusionada generada desaparece y sus materiales pasan al Cementerio.

- Destruir la Fusión no coloca una supuesta «carta de Fusión» adicional en el Cementerio porque esa carta no formaba parte del mazo.

RITUAL

- La fuente o carta de Ritual sí puede ser una carta normal del mazo y establece qué debe ofrecerse o sacrificarse para completar el Ritual.

- Al resolver correctamente el Ritual, los sacrificios exigidos van al Cementerio y aparece directamente la entidad ritual generada.

- La fuente ritual puede permanecer activa y vinculada a la criatura ritual mientras esta exista, según la regla actual.

- Cuando la criatura ritual es destruida, la entidad ritual generada desaparece y la fuente ritual vinculada va al Cementerio, salvo excepción escrita.

ENTIDADES GENERADAS POR OTROS EFECTOS

- El mismo modelo puede utilizarse más adelante para cartas que generen criaturas auxiliares, copias, invocaciones o seres temporales que no existían como cartas en la mano.

- Que una fuente sea destruida no implica automáticamente que sus criaturas generadas desaparezcan: cada efecto indicará si las entidades creadas dependen de la fuente o continúan como criaturas independientes.

- Esta última distinción pertenece al diseño de cada carta y no modifica las reglas de Fusión o Ritual.

==================================================

REGLA CONFIRMADA — REVELAR NO EQUIVALE A ACTIVAR

==================================================

Estado: CERRADO PARA PROTOTIPO.

CRIATURAS OCULTAS

- Cuando una criatura oculta en postura de guardia es atacada, se revela antes del cálculo del combate.

- El mero hecho de revelarla no genera una segunda ventana general de respuestas.

- Si la criatura no posee ningún efecto relacionado con ser revelada, ser atacada, entrar en combate u otra condición que se cumpla en ese momento, simplemente continúa el combate con sus estadísticas y efectos ya aplicables.

- Si una habilidad dice que se activa al ser revelada, al ser atacada o bajo otra condición que acaba de cumplirse, esa habilidad entra en resolución conforme a su texto antes de continuar con el cálculo de combate.

- Si la habilidad es opcional, el controlador decide si la activa. Si es automática u obligatoria, se aplica cuando corresponda.

- Una habilidad que no tenga una condición válida en ese momento no se activa únicamente porque ahora la carta sea visible.

TRAMPAS Y MAGIAS PREPARADAS

- Revelar o mostrar una carta de apoyo oculta mediante un efecto no equivale a activarla.

- Una Trampa solo puede activarse cuando se cumple su condición y su ventana de uso.

- Una Magia reactiva solo puede activarse cuando su propia ventana y requisitos lo permiten.

- Que el rival conozca el contenido de una carta preparada no la obliga a activarse ni cambia por sí solo sus condiciones.

- Una carta que revele todas las cartas ocultas puede eliminar el factor sorpresa, pero no dispara automáticamente sus efectos salvo que el propio texto de alguna carta establezca una reacción a ser revelada.

PRINCIPIO

- «Revelar» cambia la información disponible y, en una criatura, puede cambiar su estado de oculta a visible.

- «Activar» inicia un efecto porque existe una condición, ventana y decisión o disparador válidos.

- Son acciones reglamentariamente distintas.

==================================================

REGLA CONFIRMADA — CIERRE DE RESPUESTAS AL COMENZAR EL CÁLCULO

==================================================

Estado: CERRADO PARA PROTOTIPO.

- Declarar un ataque abre las ventanas de respuesta que correspondan antes de resolver el combate.

- Durante esas ventanas pueden activarse Trampas, Magias reactivas y habilidades válidas que modifiquen ATAQUE, DEFENSA, destruyan, protejan, anulen o alteren el combate.

- Cuando todas las respuestas válidas se han resuelto y comienza la doble comparación de ATAQUE y DEFENSA, la ventana general queda cerrada.

- A partir de ese momento no puede jugarse una nueva carta simplemente porque el resultado vaya a ser desfavorable.

- Si una modificación previa hace que el atacante sea destruido por la represalia del defensor, se aplica normalmente la destrucción y, cuando corresponda por su postura, el daño sobrante.

- Una excepción solo existe cuando una carta o habilidad indique de forma expresa que puede actuar durante el cálculo de combate o en el momento exacto del resultado correspondiente.

- Haber decidido atacar implica aceptar el resultado una vez cerradas las oportunidades legales de respuesta.

==================================================

REGLA CONFIRMADA — CONTINUIDAD DEL OBJETIVO DE UN ATAQUE

==================================================

Estado: CERRADO PARA PROTOTIPO.

PRINCIPIO SIMPLE

- Un ataque se declara contra un objetivo concreto y, salvo que una carta o habilidad diga lo contrario, continúa contra ese objetivo.

- Durante el turno del atacante, el defensor no puede realizar libremente acciones propias de una fase principal, como fusionar, sacrificar, invocar o transformar por decisión normal. Solo puede intervenir mediante Trampas, Magias reactivas y habilidades cuya condición y ventana sean válidas.

- El atacante tampoco introduce nuevas acciones de fase principal en mitad de la resolución del ataque; el combate se resuelve con las respuestas legales que se hayan activado.

SI EL OBJETIVO ABANDONA EL CAMPO

- Si una respuesta válida destruye al objetivo, lo devuelve a la mano, lo retira del campo o hace que deje de existir antes del cálculo, el combate contra él no se realiza.

- El ataque ya fue declarado y queda consumido para la criatura atacante. No se elige gratuitamente otro objetivo.

- Esto consume únicamente el ataque de esa criatura. No termina automáticamente toda la fase de combate ni el turno: otras criaturas que todavía tengan un ataque disponible pueden atacar después.

SI EL OBJETIVO SE TRANSFORMA

- Una transformación o mutación que mantenga la continuidad de la criatura no cancela el ataque.

- Aunque cambien su nombre, estadísticas, elemento, anatomía, habilidades o representación, sigue siendo el objetivo que estaba siendo atacado y recibe el combate con su estado resultante.

- Ejemplo conceptual: si una criatura objetivo se transforma mediante una habilidad reactiva antes del cálculo, el ataque continúa contra su nueva forma.

- Solo se considera que el objetivo desapareció cuando el propio efecto hace que abandone el campo o indique expresamente que la entidad anterior es sustituida de una forma que rompa la continuidad.

REDIRECCIÓN O INTERPOSICIÓN

- Una Trampa, Magia reactiva o habilidad puede cambiar expresamente el objetivo, interponer otra criatura, esquivar el ataque o anularlo.

- En esos casos se sigue exactamente el efecto de la carta: si otra criatura pasa a recibir el ataque, el combate continúa contra ella; si el efecto anula o evita el ataque, no hay cálculo contra el objetivo original.

CRITERIO

- La regla del ataque debe mantenerse sencilla: declarar objetivo → resolver respuestas legales → comprobar si sigue existiendo un objetivo válido o redirigido → calcular combate.

- Las variaciones proceden de las cartas y habilidades de respuesta, no de añadir una lista general de acciones que el defensor pueda realizar durante el turno rival.

==================================================

DECISIÓN CONFIRMADA — PRIMER MAZO GENERALISTA DE PRUEBA

==================================================

Estado: CERRADO COMO PUNTO DE PARTIDA DEL PRIMER PROTOTIPO; la proporción podrá ajustarse tras las primeras partidas y no obliga a futuras barajas.

OBJETIVO DEL PRIMER MAZO

- El primer mazo de 40 cartas será generalista y didáctico.

- Su función principal será enseñar y probar las reglas básicas del juego: criaturas, combate, Magias, Trampas, equipo/objetos y terrenos.

- No se construirá todavía alrededor de un único elemento, familia o estrategia especializada.

- Una vez comprobado que el núcleo funciona, se diseñarán barajas elementales y otras barajas con identidades, sinergias y estrategias más marcadas.

DISTRIBUCIÓN INICIAL DE 40 CARTAS

- 18 criaturas.

- 7 Magias.

- 6 Trampas.

- 6 equipos u objetos.

- 3 terrenos.

- Total: 40 cartas distintas en el mazo base.

CRITERIO

- Esta distribución busca que el jugador robe criaturas con suficiente frecuencia y, al mismo tiempo, pueda aprender las demás familias de cartas.

- No es una regla universal de construcción. Las barajas personalizadas y las futuras barajas elementales podrán utilizar proporciones completamente distintas.

- La distribución se revisará únicamente si las partidas reales muestran problemas claros de manos sin criaturas, exceso de apoyos, falta de respuestas u otros desequilibrios prácticos.

SIGUIENTE PASO DE DISEÑO

- Diseñar las 18 criaturas del mazo generalista empezando por su curva de coste, perfiles de ATAQUE/DEFENSA y funciones básicas, antes de añadir habilidades complejas.

==================================================

LOTE PROVISIONAL — 18 CRIATURAS DEL MAZO GENERALISTA

==================================================

Estado: PROVISIONAL PARA PRUEBAS. Los nombres, elementos, anatomías y habilidades concretas se diseñarán después.

CRITERIO MATEMÁTICO DE ESTE LOTE

- Curva de costes: 7 criaturas de coste 1; 3 de coste 2; 3 de coste 3; 2 de coste 4; 1 de coste 5; 1 de coste 6; 1 de coste 7. Total: 18.

- Con siete criaturas de coste 1 en un mazo de 40, una mano inicial de cinco cartas tiene aproximadamente un 64 % de probabilidad de contener al menos una criatura de coste 1. Este porcentaje se usa como referencia de prueba, no como objetivo definitivo.

- Se conserva provisionalmente el presupuesto base PB = 3 × coste de Energía + 2.

- La valoración antigua de 1 PB por punto de DEFENSA se considera demasiado generosa tras adoptar la doble comparación. Para construir este lote se usa como aproximación interna más prudente: 1 ATQ ≈ 2 PB y 1 DEF ≈ 1,5 PB. Esta equivalencia no queda cerrada y deberá recalibrarse con partidas reales.

- Las criaturas con habilidad reservan parte de su presupuesto para esa habilidad y, por tanto, reciben menos estadísticas que una criatura equivalente sin habilidad.

ESQUELETO DE CRIATURAS

M01 — Coste 1 — 2 ATQ / 0 DEF — Sin habilidad.

M02 — Coste 1 — 1 ATQ / 2 DEF — Sin habilidad.

M03 — Coste 1 — 0 ATQ / 3 DEF — Sin habilidad.

M04 — Coste 1 — 1 ATQ / 1 DEF — Sin habilidad.

M05 — Coste 1 — 1 ATQ / 1 DEF — Con habilidad pequeña.

M06 — Coste 1 — 0 ATQ / 2 DEF — Con habilidad pequeña.

M07 — Coste 1 — 0 ATQ / 1 DEF — Con habilidad de valor medio.

M08 — Coste 2 — 3 ATQ / 1 DEF — Sin habilidad.

M09 — Coste 2 — 2 ATQ / 2 DEF — Con habilidad pequeña.

M10 — Coste 2 — 1 ATQ / 3 DEF — Con habilidad pequeña.

M11 — Coste 3 — 4 ATQ / 2 DEF — Sin habilidad.

M12 — Coste 3 — 3 ATQ / 2 DEF — Con habilidad menor.

M13 — Coste 3 — 2 ATQ / 2 DEF — Con habilidad estándar.

M14 — Coste 4 — 4 ATQ / 4 DEF — Sin habilidad.

M15 — Coste 4 — 3 ATQ / 3 DEF — Con habilidad estándar.

M16 — Coste 5 — 4 ATQ / 4 DEF — Con habilidad estándar.

M17 — Coste 6 — 7 ATQ / 4 DEF — Sin habilidad.

M18 — Coste 7 — 5 ATQ / 6 DEF — Con habilidad fuerte.

FUNCIÓN DEL LOTE

- El conjunto contiene perfiles ofensivos, defensivos y equilibrados para comprobar la doble comparación sin necesitar todavía nombres o elementos.

- Las criaturas sin habilidad sirven como referencias limpias para medir el valor real de ATQ y DEF.

- Las criaturas con habilidad permitirán comprobar cuánto deben reducirse las estadísticas al reservar parte del presupuesto para efectos.

- No se incluyen todavía criaturas de costes 8, 9 o 10 en el mazo didáctico: primero se comprobará la duración real de las partidas y la velocidad de la Energía.

- Ninguna habilidad concreta queda definida por esta tabla; únicamente se reserva su peso aproximado de diseño.

HABILIDADES PROVISIONALES — PRIMERAS CRIATURAS DIDÁCTICAS

Estado: APROBADAS PARA EL PRIMER PROTOTIPO; sujetas a ajuste numérico tras pruebas.

- M05 — Coste 1 — 1 ATQ / 1 DEF. Al declarar un ataque, obtiene +1 ATQ durante ese combate.

- M06 — Coste 1 — 0 ATQ / 2 DEF. Cuando sea revelada al recibir un ataque, obtiene +1 DEF durante ese combate.

- M07 — Coste 1 — 0 ATQ / 1 DEF. Cuando sea destruida, roba 1 carta.

Criterio didáctico: M05 enseña un disparador al atacar; M06 enseña un efecto de revelación; M07 enseña un efecto al ser destruida. M07 se vigilará especialmente en pruebas por su capacidad de bloquear en guardia y reemplazarse en la mano.

HABILIDADES PROVISIONALES — COSTE 2

Estado: APROBADAS PARA EL PRIMER PROTOTIPO; sujetas a ajuste tras pruebas.

- M09 — Coste 2 — 2 ATQ / 2 DEF. Una vez por turno, durante una fase principal propia, puede pagar 1 de Energía para obtener +1 ATQ hasta el final del turno.

- M10 — Coste 2 — 1 ATQ / 3 DEF. Mientras esté en postura de guardia, obtiene +1 ATQ.

Criterio didáctico: M09 introduce una habilidad activada con coste de Energía; M10 demuestra que el ATQ sigue siendo relevante en postura de guardia por la represalia de la doble comparación.

HABILIDADES PROVISIONALES — COSTE 3

Estado: APROBADAS PARA EL PRIMER PROTOTIPO; sujetas a ajuste tras pruebas.

- M12 — Coste 3 — 3 ATQ / 2 DEF. Al entrar boca arriba, su controlador mira una carta de apoyo boca abajo del rival. Mirarla no la revela públicamente ni la activa.

- M13 — Coste 3 — 2 ATQ / 2 DEF. Una vez por turno, cuando otra criatura que controles sea atacada, puedes hacer que M13 pase a ser el objetivo de ese ataque.

Criterio didáctico: M12 enseña información oculta sin confundir revelar con activar; M13 enseña una habilidad reactiva de criatura y la redirección de ataques.

HABILIDADES PROVISIONALES — COSTES 4 Y 5

Estado: APROBADAS PARA EL PRIMER PROTOTIPO; sujetas a ajuste tras pruebas.

- M15 — Coste 4 — 3 ATQ / 3 DEF. Al entrar boca arriba, otra criatura que controles obtiene +1 ATQ y +1 DEF hasta el final del turno.

- M16 — Coste 5 — 4 ATQ / 4 DEF. La primera vez en cada turno que destruya una criatura en combate, recuperas 1 de Energía.

Criterio didáctico: M15 introduce una criatura de apoyo con mejora temporal; M16 introduce una recompensa posterior al combate y permite medir el valor real de recuperar Energía antes de la segunda fase principal.

HABILIDAD PROVISIONAL — COSTE 7

Estado: APROBADA PARA EL PRIMER PROTOTIPO; su potencia se ajustará tras pruebas.

- M18 — Coste 7 — 5 ATQ / 6 DEF. La primera vez en cada turno que destruya una criatura en combate y sobreviva, obtiene 1 ataque adicional ese turno. Esta habilidad solo puede activarse una vez por turno.

Criterio de equilibrio: M18 puede realizar como máximo dos ataques en un turno gracias a su propia habilidad. Aunque destruya otra criatura con el ataque adicional, no vuelve a activarse. Otros efectos independientes podrían conceder ataques adicionales si su texto lo permite.

CIERRE DEL LOTE DE CRIATURAS

- Las 18 criaturas del primer mazo generalista quedan definidas funcionalmente para el prototipo, con estadísticas y habilidades provisionales sujetas a pruebas.

- El siguiente bloque de diseño serán las 7 Magias del mazo generalista.

==================================================

MAGIAS PROVISIONALES — FASE PRINCIPAL

==================================================

Estado: G01 y G02 APROBADAS PARA EL PRIMER PROTOTIPO; sujetas a ajuste tras pruebas.

- G01 — Magia de fase principal. Una criatura que controles obtiene +2 ATQ hasta el final del turno.

- G02 — Magia de fase principal. Una criatura que controles obtiene +2 DEF hasta el final del turno.

Criterio didáctico: G01 enseña una mejora ofensiva temporal antes del combate; G02 demuestra que aumentar DEF también puede proteger a una criatura que va a atacar, porque la doble comparación utiliza DEF en ambos lados del combate.

- G03 — Magia de fase principal. Devuelve a la mano una criatura enemiga con coste impreso de 2 o menos.

Criterio didáctico: G03 introduce retirada temporal y tempo. Si la criatura devuelta tenía equipos u otras cartas vinculadas que dependían de su presencia, esos vínculos van al Cementerio conforme a la regla general. El límite de coste 2 evita que una Magia básica y gratuita en Energía retire universalmente amenazas de coste alto.

==================================================

MAGIAS PROVISIONALES — PERSISTENTES

==================================================

Estado: G04 APROBADA PARA EL PRIMER PROTOTIPO; su potencia se ajustará tras pruebas.

- G04 — Magia persistente. Mientras permanezca boca arriba, tus criaturas en postura de guardia obtienen +1 DEF.

Criterio didáctico: G04 enseña un efecto persistente que ocupa un espacio de apoyo y sigue activo mientras la carta permanezca en el campo. El aumento se aplica también a criaturas ocultas en postura de guardia sin revelar sus estadísticas base. Riesgo a medir: la bonificación global de DEF puede aumentar los bloqueos y servirá para calibrar el valor real de DEF en la doble comparación.

- G05 — Magia persistente. La primera vez en cada uno de tus turnos que una criatura que controles pase de postura de guardia a postura de ataque, esa criatura obtiene +1 ATQ hasta el final del turno.

Criterio didáctico: G05 enseña un efecto persistente disparado por un cambio de postura. Solo puede beneficiar a una criatura por turno mediante su propio efecto y también reconoce la revelación manual de una criatura oculta cuando esta pasa de guardia a ataque. Sirve para comparar una mejora repetible y condicionada con G01, que concede una bonificación mayor pero de un solo uso.

==================================================

MAGIAS PROVISIONALES — REACTIVAS

==================================================

Estado: G06 APROBADA PARA EL PRIMER PROTOTIPO; su potencia se ajustará tras pruebas.

- G06 — Magia reactiva. Cuando una criatura que controles sea atacada, puedes activarla: esa criatura obtiene +2 DEF durante ese combate.

Criterio didáctico: G06 enseña la preparación previa y la ventana de respuesta tras declarar un ataque. Permite comparar el mismo aumento de DEF con G02: G02 se usa anticipadamente durante una fase principal propia; G06 se reserva como respuesta preparada y oculta. La diferencia de valor procede del momento de uso, no de un coste de Energía distinto

- G07 — Magia reactiva. Cuando una criatura que controles sea atacada, devuelve esa criatura a tu mano.

Criterio didáctico: G07 enseña la pérdida del objetivo de un ataque. El ataque queda consumido, no se redirige automáticamente y no se realiza cálculo de combate contra el objetivo original. La criatura vuelve sola a la mano y sus vínculos que dependan de ella van al Cementerio. No tiene límite de coste: salvar una criatura fuerte implica perder presencia, volver a pagar su Energía y emplear otra invocación normal para recuperarla. Puede reutilizar efectos de entrada de forma intencional.

CIERRE DEL LOTE DE MAGIAS

- Las 7 Magias del primer mazo generalista quedan definidas funcionalmente para el prototipo, sujetas a ajuste tras pruebas.

- El siguiente bloque de diseño son las 6 Trampas..

==================================================

TRAMPAS PROVISIONALES — PRIMER MAZO GENERALISTA

==================================================

Estado: T01–T06 APROBADAS PARA EL PRIMER PROTOTIPO; sujetas a ajuste tras pruebas.

- T01 — Trampa. Cuando una criatura enemiga de coste impreso 2 o menos declare un ataque, destrúyela.

- T02 — Trampa. Cuando una criatura que controles sea atacada, la criatura atacante obtiene −2 ATQ durante ese combate.

- T03 — Trampa. Cuando el rival active una Magia, anula el efecto de esa Magia; después, ambas cartas van al Cementerio.

- T04 — Trampa. Cuando una criatura enemiga pase voluntariamente de postura de guardia a postura de ataque, devuélvela a postura de guardia.

- T05 — Trampa. Cuando el rival vincule un equipo u objeto a una criatura, destruye esa carta vinculada.

- T06 — Trampa. Cuando una criatura que controles sea destruida en combate, destruye la criatura enemiga que combatió contra ella, si sigue en el campo.

Criterio didáctico: T01 enseña destrucción reactiva y ataque comprometido; T02 modificación de estadísticas en respuesta; T03 anulación y cadenas; T04 reacción a cambios voluntarios de postura; T05 contrajuego contra inversión en equipo; T06 un disparador específico posterior a la resolución del combate. T03 no rebobina costes ni acciones anteriores; simplemente impide que el efecto anulado se aplique. T04 solo reacciona a cambios voluntarios para evitar interacciones circulares con cambios forzados. T06 ocurre después de determinar la destrucción del combate y por tanto no reabre la ventana general durante el cálculo.

CIERRE DEL LOTE DE TRAMPAS

- Las 6 Trampas del primer mazo generalista quedan definidas funcionalmente para el prototipo.

- El siguiente bloque de diseño son las 6 cartas de equipo/objeto.

==================================================

EQUIPOS Y OBJETOS PROVISIONALES — PRIMER MAZO GENERALISTA

==================================================

Estado: E01–E06 APROBADOS PARA EL PRIMER PROTOTIPO; sujetos a ajuste tras pruebas.

- E01 — Arma de entrenamiento. Equipo vinculado. El portador obtiene +1 ATQ. Requisito: Manipulador.

- E02 — Protección reforzada. Equipo vinculado. El portador obtiene +1 DEF.

- E03 — Escudo de guardia. Equipo vinculado. Mientras el portador esté en postura de guardia, obtiene +1 ATQ y +1 DEF. Requisito: Manipulador.

- E04 — Banco de herramientas. Artefacto independiente. Una vez por turno, durante una fase principal propia, puedes trasladar un equipo vinculado a una criatura que controles a otra criatura que controles que pueda utilizarlo legalmente.

- E05 — Protección del Bastión. Equipo vinculado — Set Bastión. El portador obtiene +1 DEF.

- E06 — Arma del Bastión. Equipo vinculado — Set Bastión. El portador obtiene +1 ATQ. Requisito: Manipulador.

BONIFICACIÓN DEL SET BASTIÓN

- Mientras E05 y E06 estén vinculadas a la misma criatura, el portador obtiene además +1 ATQ y +1 DEF. Con ambas piezas, la bonificación total del conjunto es +2 ATQ / +2 DEF.

Criterio didáctico: E01 prueba por primera vez un requisito de aptitud mediante Manipulador; E02 sirve como referencia de +1 DEF persistente; E03 prueba el valor conjunto de ATQ y DEF en postura de guardia; E04 distingue un artefacto independiente de un equipo vinculado y permite reorganizar inversión únicamente en fase principal; E05 y E06 prueban un conjunto normal de dos piezas con efectos individuales y bonificación por completarlo.

Riesgo a medir: E03 puede hacer muy resistentes a determinadas criaturas defensivas. No se reduce de antemano; se utilizará para medir el valor real de DEF y de las mejoras persistentes en la doble comparación.

CIERRE DEL LOTE DE EQUIPOS Y OBJETOS

- Las 6 cartas de equipo/objeto del primer mazo generalista quedan definidas funcionalmente para el prototipo.

- Con criaturas, Magias, Trampas y equipos/objetos hay 37 de las 40 cartas funcionalmente diseñadas. El último bloque son los 3 Terrenos.

==================================================

TERRENOS PROVISIONALES — PRIMER MAZO GENERALISTA

==================================================

Estado: R01–R03 APROBADOS COMO BASE FUNCIONAL; las propiedades y efectos avanzados de sus transformaciones se desarrollarán más adelante.

- R01 — Bosque. Elemento: Naturaleza. Tus criaturas de Naturaleza obtienen +1 DEF.

- R02 — Lago. Elemento: Agua. Tus criaturas de Agua obtienen +1 DEF.

- R03 — Volcán. Elemento: Fuego. Tus criaturas de Fuego obtienen +1 ATQ.

REGLA CONFIRMADA — COMBINACIÓN ORDENADA DE TERRENOS

- Cuando un jugador juega un Terreno teniendo ya uno en su zona de terreno, primero se comprueba si existe una receta para la combinación «Terreno actual + Terreno entrante».

- Si existe una receta, el Terreno se transforma en el resultado definido por esa receta. Si no existe, el Terreno nuevo sustituye normalmente al anterior.

- El orden de los Terrenos importa: A + B puede producir un resultado distinto de B + A.

- Recetas iniciales: Bosque + Lago = Bosque Inundado; Lago + Bosque = Humedal Fértil; Bosque + Volcán = Bosque Ardiente; Volcán + Bosque = Bosque Volcánico; Lago + Volcán = Caldera de Vapor; Volcán + Lago = Llanura de Obsidiana.

- Las características mecánicas detalladas de estos Terrenos transformados quedan aplazadas. Por ahora sirven como identidad ambiental y base para futuras cartas, elementos, habilidades y efectos latentes.

- El elemento de una criatura no modifica un Terreno por atacar, defender o estar presente. Un Terreno solo se quema, congela, electrifica, inunda, seca o transforma cuando una carta, habilidad o efecto lo indique expresamente.

- Esta regla sustituye para estas combinaciones la regla anterior de sustitución automática de Terreno.

CIERRE FUNCIONAL DEL PRIMER MAZO

- Con los 3 Terrenos quedan definidas funcionalmente las 40 cartas del primer mazo generalista para revisión y pruebas.

==================================================

AJUSTES DE AUDITORÍA — EQUIPO Y CAMBIO DE POSTURA

==================================================

Estado: APROBADOS PARA EL PRIMER PROTOTIPO.

- E03 — Escudo de guardia exige Manipulador, por tratarse de un objeto que requiere sujeción y control físico.

- E06 — Arma del Bastión exige Manipulador por la misma lógica de compatibilidad que E01.

- E04 — Banco de herramientas solo puede trasladar equipo entre criaturas que controles; no permite reorganizar gratuitamente vínculos de una criatura bajo control rival.

- Cuando una criatura boca abajo se revela manualmente en un turno posterior y pasa a boca arriba en postura de ataque, ese mismo evento cuenta a la vez como revelación y como transición de postura de guardia a postura de ataque para los efectos que comprueben cada condición. La revelación sigue sin abrir por sí misma una ventana general de respuestas.

==================================================

ASIGNACIÓN PROVISIONAL — ELEMENTOS Y MANIPULACIÓN DE LAS 18 CRIATURAS

==================================================

Estado: PROVISIONAL PARA EL PRIMER PROTOTIPO; puede ajustarse al crear nombres, especies e ilustraciones sin cambiar innecesariamente estadísticas o habilidades.

PRINCIPIOS

- Neutral es un elemento real del sistema, no la ausencia de elemento.

- El mazo generalista contiene varios elementos y no está construido alrededor de uno solo.

- Para esta fase solo se fija la aptitud Manipulador, porque E01, E03 y E06 la consultan. Sapiente, Lector, Canalizador y la anatomía detallada se asignarán cuando una carta concreta los necesite o cuando se defina la identidad visual de la criatura.

- No se asume que Fuego signifique siempre ofensiva, Agua siempre defensa o Naturaleza siempre resistencia; el reparto mezcla perfiles para evitar convertir los elementos en simples códigos de estadísticas.

DISTRIBUCIÓN

- M01 — Naturaleza — no Manipulador.

- M02 — Agua — Manipulador.

- M03 — Fuego — no Manipulador.

- M04 — Neutral — Manipulador.

- M05 — Fuego — Manipulador.

- M06 — Agua — no Manipulador.

- M07 — Naturaleza — no Manipulador.

- M08 — Agua — no Manipulador.

- M09 — Neutral — Manipulador.

- M10 — Naturaleza — Manipulador.

- M11 — Neutral — Manipulador.

- M12 — Agua — Manipulador.

- M13 — Neutral — Manipulador.

- M14 — Neutral — no Manipulador.

- M15 — Naturaleza — Manipulador.

- M16 — Neutral — Manipulador.

- M17 — Fuego — no Manipulador.

- M18 — Fuego — Manipulador.

RESUMEN DEL REPARTO

- Neutral: 6 criaturas.

- Naturaleza: 4 criaturas.

- Agua: 4 criaturas.

- Fuego: 4 criaturas.

- Manipulador: 11 criaturas.

- No Manipulador: 7 criaturas.

CRITERIO

- Bosque, Lago y Volcán ya tienen objetivos reales dentro del mazo desde costes bajos hasta costes altos.

- Las criaturas no Manipuladoras permiten comprobar que las restricciones de equipo producen decisiones reales sin volver inútiles las piezas básicas.

- Las Magias, Trampas y equipos que todavía no tengan elemento asignado no se consideran automáticamente Neutrales. Su elemento se fijará junto con su identidad temática cuando sea relevante para una regla, receta o interacción.

