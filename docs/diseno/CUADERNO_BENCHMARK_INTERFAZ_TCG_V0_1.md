# Cuaderno de benchmark de interfaz TCG V0.1

Estado: **cuaderno de trabajo activo; base previa a consolidar el greybox**  
Fecha: **2026-09-12**  
Ámbito: **interfaz, proporciones, lectura visual e interacción; no cambia reglas del duelo**

## Propósito

Este cuaderno evita diseñar la mesa desde cero y evita perder contexto entre ChatGPT, Codex y futuras sesiones. La idea no es copiar un juego concreto, sino estudiar soluciones que llevan años probadas en distintos juegos de cartas, escoger la mejor respuesta para cada problema y construir una gramática propia para Zápiti/Juego de Cartas Propio.

La regla de trabajo es:

> **No preguntar primero “¿cómo lo inventamos?”, sino “¿quién ha resuelto ya bien este problema y qué principio podemos reutilizar sin copiar su identidad visual?”**

Este documento reúne referencias, ideas candidatas, medidas y una primera síntesis. Mientras siga marcado como cuaderno de trabajo, sus ideas no son automáticamente requisitos. Las decisiones que se acepten se trasladarán después al contrato del greybox y, si corresponde, a `02_DECISIONES_Y_REGLAS.md`.

## Límites legales y de identidad

Se pueden estudiar proporciones habituales, organización funcional del campo, principios de interacción, jerarquía de información y patrones comunes de accesibilidad. No se copiarán ilustraciones, logos, marcos, iconos distintivos, nombres, sonidos, animaciones, ornamentación ni una composición gráfica reconocible como identidad de otro producto.

La interfaz final debe poder explicarse como una solución propia construida con patrones comunes de juegos de cartas. Las referencias se documentan por procedencia para saber de dónde nació cada idea. Este apartado es una pauta prudente de diseño, no asesoramiento jurídico.

## Reglas propias que ninguna referencia puede sustituir

La comparación con otros juegos no autoriza a importar sus reglas. La interfaz tiene que servir a nuestro juego tal como está definido:

- cinco casillas de criatura y cinco de apoyo por jugador;
- las casillas son visualmente elegibles, pero mecánicamente equivalentes;
- ataque vertical y guardia horizontal;
- criatura preparada oculta en guardia;
- Magias instantáneas, persistentes y respuestas/trampas no comparten exactamente el mismo destino;
- equipo se vincula a una criatura, no ocupa una casilla ordinaria de apoyo;
- Terreno tiene una zona propia y puede transformarse por recetas;
- Fusión genera una identidad que ocupa una sola casilla y contiene materiales físicos;
- hay ventanas de respuesta con prioridad alterna y cadena LIFO;
- el ataque directo solo existe si no hay criaturas rivales;
- la privacidad de cartas ocultas se conserva por casilla pública;
- `UniversalCardEngine` sigue siendo la única autoridad de reglas y acciones legales.

## Referencias estudiadas

### 1. Yu-Gi-Oh! / Master Duel — estructura de campo y estados físicos

**Qué resuelve bien para nosotros:**

- separación inmediata entre criaturas/monstruos y Magias/Trampas;
- cinco zonas principales de monstruo y cinco de Magia/Trampa en el reglamento clásico;
- lectura instantánea de postura: vertical = ataque, horizontal = defensa;
- carta boca abajo como estado oculto claramente distinto;
- zonas laterales reconocibles para mazo, cementerio y terreno/campo.

**Qué aprovechamos como principio:**

- orientación de carta como información, no como decoración;
- filas permanentes con huecos de carta;
- mazo/cementerio/terreno visibles como lugares físicos del tablero;
- criaturas y apoyos no deben parecer la misma clase de zona.

**Qué no copiamos:** marco de tablero, símbolos, iconografía, colores, nombres de zonas ni composición exacta de Master Duel.

Fuente principal: reglamento oficial de Yu-Gi-Oh!, sección de Game Mat y posiciones de monstruo.

### 2. Magic: The Gathering Arena — mano, inspección y selección directa

**Qué resuelve bien para nosotros:**

- la mano puede recogerse y expandirse para liberar campo sin perder acceso;
- mantener pulsada/pasar sobre una carta abre una lectura grande;
- se seleccionan atacantes directamente y después se asignan objetivos/bloqueos;
- las zonas como cementerio o biblioteca se inspeccionan mediante una vista secundaria en vez de ocupar media pantalla;
- en móvil reorganiza tamaños y HUD según el espacio disponible en vez de copiar píxel a píxel el escritorio.

**Qué aprovechamos:**

- carta seleccionada = preview grande contextual;
- mano visible pero no dominante;
- selección directa de atacante y objetivo;
- información secundaria bajo demanda;
- layout responsive basado en prioridades.

Fuente principal: artículos oficiales `MTG Arena: State of the Game – January 2021` y FAQ móvil de MTG Arena.

### 3. Legends of Runeterra — respuestas, pila y predicción pública

**Qué resuelve bien para nosotros:**

- diferencia visual y conceptual entre efectos que permiten respuesta y efectos inmediatos;
- la pila muestra qué se resolverá y en qué orden;
- la prioridad de respuesta se comunica como una situación especial, no como una lista técnica permanente;
- `Oracle's Eye` permite previsualizar consecuencias antes de confirmar cuando la información necesaria es pública.

**Qué aprovechamos:**

- cuando se abra una respuesta, la interfaz debe cambiar de modo de forma inequívoca;
- las cartas/efectos ya comprometidos pueden mostrarse en una pequeña cadena ordenada;
- el jugador debe ver quién tiene prioridad sin leer un log;
- candidato fuerte: **vista “si se resolviera ahora”** para combate o cadena usando exclusivamente información pública, sin adivinar trampas ni cartas ocultas.

**Adaptación a nuestro combate:** después de seleccionar atacante y objetivo podría mostrarse discretamente el resultado actual calculable, por ejemplo destrucción/supervivencia/daño sobrante, siempre etiquetado como resultado *si se resolviera ahora*. Una respuesta posterior puede cambiarlo.

Fuentes principales: soporte oficial de Riot para `Oracle's Eye`, notas oficiales de Runeterra y documentación pública del sistema de pila.

### 4. Shadowverse — cartas jugables, jerarquía de carta y detalle bajo demanda

**Qué resuelve bien para nosotros:**

- las cartas de mano que pueden jugarse se iluminan;
- tocar una carta abre una ventana de detalle;
- coste arriba y estadísticas en esquinas inferiores crean una lectura de milisegundos;
- botón de terminar turno claro y separado del campo;
- el tablero principal permanece relativamente limpio.

**Qué aprovechamos:**

- resaltado suave de **carta jugable ahora**;
- coste y estadísticas en posiciones fijas de todas las criaturas;
- detalle completo solo al seleccionar/inspeccionar;
- no llenar la carta pequeña con texto que no puede leerse.

Fuente principal: guía oficial de Shadowverse, apartados Interface, Your Hand y Card Detail Screen.

### 5. Pokémon TCG / TCG Live — asociaciones, adjuntos y roles espaciales

**Qué resuelve bien para nosotros:**

- un Pokémon principal puede tener Energías y Herramientas claramente asociadas a él;
- la zona Activa y la Banca tienen funciones visuales inmediatamente distinguibles;
- estados y contadores se asocian a la carta afectada, no a una lista lateral abstracta;
- el jugador aprende la mesa por posiciones constantes.

**Qué aprovechamos:**

- los equipos deben verse **pegados al portador**: pestaña, carta parcialmente debajo o miniatura vinculada;
- los modificadores persistentes deberían aparecer sobre/junto a la criatura afectada;
- al inspeccionar una criatura, la ficha debe enumerar sus adjuntos sin obligar a buscar otra zona.

**Qué no importamos:** sistema Activo/Banca, Energías ni Premios, porque nuestro combate es diferente.

Fuente principal: reglamento oficial Pokémon TCG y materiales de Pokémon TCG Live.

### 6. Marvel Snap — turno, energía y decisión principal inequívoca

**Qué resuelve bien para nosotros:**

- el estado de turno y energía es extremadamente visible;
- `END TURN` es una decisión principal fácil de localizar;
- la mesa dedica casi todo el espacio a cartas y lugares, no a controles administrativos;
- los elementos que todavía no están disponibles se comunican sin abrir paneles complejos.

**Qué aprovechamos:**

- el botón de terminar turno debe ser estable y reconocible;
- energía y turno deben leerse de un vistazo;
- la acción principal del momento puede tener más peso que las utilidades de Guardar/Cargar/Debug.

**Qué no importamos:** tres localizaciones, turnos simultáneos, Snap/Cubes ni su estructura de partida.

Fuente principal: guía oficial `How to Play` de Marvel Snap.

### 7. Flesh and Blood — carta preparada privada y cadena de combate

**Qué resuelve bien para nosotros:**

- `Arsenal` es una zona privada limitada que guarda una carta boca abajo para uso posterior;
- existe una `Combat Chain` compartida que hace visible el contexto del combate y sus eslabones;
- zonas de equipo están asociadas a su función y no mezcladas con la mano/campo genérico.

**Qué aprovechamos:**

- una respuesta preparada puede tener una presencia espacial inequívoca sin revelar identidad;
- la ventana de respuesta de nuestro juego puede usar una **mini-cadena central temporal** en vez de llenar el lateral de botones;
- los equipos merecen lenguaje propio y vinculación visible al portador.

**Qué no importamos:** pitch, arsenal como mecánica ni anatomía de equipo por zonas corporales.

Fuentes principales: reglas completas y Quickstart oficial de Flesh and Blood.

### 8. Disney Lorcana — estado ready/exerted y cartas apiladas por transformación

**Qué resuelve bien para nosotros:**

- usa orientación para distinguir cartas listas de cartas utilizadas;
- `Shift` coloca una identidad nueva sobre una carta base, conservando físicamente la relación entre ambas;
- su lectura de personaje/acción/objeto/localización muestra que distintos tipos pueden compartir formato sin compartir comportamiento.

**Qué aprovechamos:**

- importante para **Fusiones**: la entidad resultante debe verse como una sola carta activa, pero al inspeccionarla debe ser posible desplegar visualmente los materiales contenidos;
- los materiales no deben parecer criaturas activas adicionales;
- una pequeña insignia `2 materiales` puede indicar que existe contenido sin ocupar el campo.

**Qué no importamos:** Shift como regla, inkwell, lore, exert ni sus categorías de carta.

Fuente principal: `How to Play for TCG Players` y documentación oficial de Shift de Disney Lorcana.

### 9. Shadowverse: Evolve — playmat explícito y capacidad limitada

**Qué resuelve bien para nosotros:**

- playmat oficial con zonas identificadas para líder, mazo, cementerio, campo y áreas especiales;
- el campo posee capacidad limitada y mantiene posiciones estables;
- orientación horizontal/vertical comunica estado de uso;
- recursos máximo/restante están separados pero próximos.

**Qué aprovechamos:**

- reafirma que una mesa con zonas físicas claras no necesita convertirse en una cuadrícula técnica;
- recursos máximo/disponible pueden formar un único widget legible;
- las zonas auxiliares deben ser pequeñas pero consistentes.

Fuente principal: Play Guide oficial de Shadowverse: Evolve.

### 10. Eternal — selección de atacantes/bloqueadores y ventanas rápidas

**Qué resuelve bien para nosotros:**

- selección explícita de unidades atacantes;
- defensor asigna bloqueadores y existe un momento claro previo a la resolución para efectos rápidos;
- diferencia entre unidad lista/no lista y restricciones de ataque.

**Qué aprovechamos:**

- refuerza el patrón **seleccionar participante → confirmar contexto → abrir respuestas → resolver**;
- nuestro combate no necesita una lista de acciones si la propia criatura y los objetivos legales lo comunican.

Fuente principal: reglas avanzadas oficiales de Eternal.

## Referencias a inspeccionar en una segunda pasada

No son necesarias para empezar la síntesis, pero quedan anotadas para no olvidarlas:

- **Hearthstone:** flecha de atacante a objetivo, claridad de estados jugables y extrema reducción de zonas visibles;
- **Gwent:** compresión de muchas cartas en filas horizontales y jerarquía de puntuación;
- **Yu-Gi-Oh! Duel Links:** adaptación de un TCG complejo a menos espacio;
- **Pokémon TCG Pocket:** lectura móvil y animación de mano/inspección;
- **Slay the Spire y otros deckbuilders:** telemetría de intención enemiga y previsualización de consecuencias, útil como referencia secundaria aunque no sean TCG competitivos.

Estas referencias no deben incorporarse por fama; solo si aportan una solución mejor que las ya documentadas.

## Proporción de carta: candidato base

### Formatos físicos de referencia

- formato occidental habitual en Magic/Pokémon y otros TCG: aproximadamente **63 × 88 mm**, relación ancho/alto ≈ **0,716**;
- Yu-Gi-Oh! usa formato más estrecho, aproximadamente **59 × 86 mm**, relación ≈ **0,686**.

Nuestro juego necesita nombre, coste, elemento, ilustración, ATQ/DEF y, en algunos casos, habilidad. Como candidato de interfaz se prefiere **63:88** porque ofrece algo más de anchura de lectura. Esto no significa fabricar físicamente cartas con esa medida: en pantalla se usa la relación.

### Unidad de diseño propuesta

Definir:

`1 U = ancho de una carta vertical de campo`

Entonces:

- carta vertical: `1 U × 1,397 U`;
- carta en guardia: `1,397 U × 1 U`;
- separación normal entre cartas: `0,14–0,18 U`;
- margen interior de una fila: `0,25–0,35 U`;
- carta de mano: `1,15–1,20 U` de ancho, misma proporción;
- preview lateral: `2,4–2,6 U` de ancho, misma proporción;
- montón auxiliar: alrededor de `0,75–0,85 U` de ancho;
- banda de fases: `0,30–0,38 U` de alto;
- cabecera de jugador: `0,38–0,50 U` de alto.

### Candidato inicial para 1600 × 900

No es todavía una decisión cerrada; sirve para evitar números arbitrarios durante la siguiente implementación.

- `U = 72 px`;
- carta de campo: **72 × 101 px**;
- guardia: **101 × 72 px**;
- mano propia: aproximadamente **86 × 120 px**;
- preview: aproximadamente **180 × 251 px**;
- hueco entre cartas de campo: **10–13 px**;
- cabecera/HUD de jugador: **30–34 px**;
- banda de fases: **24–28 px**.

La resolución no debe codificarse como diseño absoluto. A 1280×720, 1920×1080 o pantalla móvil, `U` debe recalcularse manteniendo proporciones y prioridades.

## Anatomía visual candidata de nuestras cartas

### Criatura

Lectura rápida propuesta:

- esquina superior izquierda: coste de Energía;
- franja superior: nombre;
- esquina superior derecha: elemento/familia mediante icono propio futuro;
- centro: ilustración/placeholder;
- zona inferior corta: habilidad o palabras clave resumidas;
- esquina inferior izquierda: ATQ;
- esquina inferior derecha: DEF.

Principio tomado de varios TCG: las cifras que se consultan cada pocos segundos deben ocupar posiciones fijas. El texto completo pertenece a la inspección ampliada, no a la miniatura de campo.

### Magia instantánea

- se reconoce como Magia por marco/icono propio;
- al seleccionarla se resaltan únicamente objetivos legales;
- al confirmarla no “aparca” en Apoyo: aparece temporalmente en la cadena/centro de resolución y después va al Cementerio;
- si abre respuestas, queda visible en la mini-cadena hasta resolverse.

### Magia persistente

- se coloca boca arriba en una casilla de Apoyo;
- conserva icono de persistente claramente distinto de Magia instantánea;
- efecto activo visible mediante un pequeño indicador, no mediante un texto permanente grande.

### Trampa / respuesta preparada

- para su propietario puede existir una indicación discreta de “preparada”; para el rival solo se ve reverso;
- ocupa Apoyo boca abajo;
- cuando puede responder, la interfaz comunica que **hay una decisión disponible** sin revelar una identidad que deba seguir oculta;
- al activarse pasa a la mini-cadena y se revela conforme a la regla vigente.

### Equipo

- no se dibuja como una carta independiente ocupando Apoyo;
- se muestra parcialmente debajo/junto a la criatura portadora o como pestaña de equipo;
- varias piezas pueden apilar pestañas pequeñas;
- seleccionar la criatura muestra la lista completa de equipos;
- trasladar E04 debe hacer visible origen y destinos compatibles.

### Terreno

- zona propia lateral/ambiental;
- cuando está vacío no necesita repetir `VACÍO` en grande;
- una transformación muestra la **identidad ambiental resultante**, no solo el nombre físico de la carta portadora;
- al inspeccionar puede mostrarse `Bosque + Lago → Bosque Inundado`, etc.;
- si una sustitución va a perder el Terreno anterior, la confirmación debe explicarlo antes de ejecutar.

### Fusión

- una Fusión ocupa una sola casilla y se presenta siempre con su identidad generada;
- pequeña insignia de materiales contenidos;
- inspección expandible de materiales, procedencia y equipos vinculados;
- nunca dibujar el segundo material como otra criatura activa;
- durante la selección de materiales, solo criaturas compatibles deben resaltarse como segundo material;
- si varias recetas fueran posibles, la elección de resultado debe ser explícita y contextual.

## Gramática de estados visuales candidata

No depender únicamente del color. Cada estado debería combinar al menos dos señales: borde, brillo, posición, icono, opacidad o animación.

| Estado | Señal propuesta |
| --- | --- |
| carta jugable ahora | halo/borde suave + cursor/hover activo |
| carta no jugable | normal o ligeramente atenuada, sin castigo visual excesivo |
| carta seleccionada | elevación + borde fuerte |
| destino legal | contorno/pulso discreto |
| objetivo de ataque | contorno específico de combate + cursor de objetivo |
| selección de Fusión | marca de material 1 / material 2 |
| respuesta disponible | indicador de prioridad + carta/zona relevante pulsando |
| carta oculta | reverso real, sin nombre/tipo filtrado |
| ataque | vertical |
| guardia | horizontal |
| efecto temporal | pequeña ficha/icono anclado a la carta |
| equipo vinculado | pestaña o mini-carta asociada físicamente |
| carta usada/ataque consumido | icono/atenuación local, no solo texto |

## Mano

Dirección propuesta:

- manos rectas, respetando JCP-DEC-039;
- propia abajo y rival arriba;
- sin abanico angular permanente;
- si hay pocas cartas, separación completa;
- si crece demasiado, solape horizontal progresivo antes de reducirlas hasta ser ilegibles;
- seleccionar una carta la eleva unos píxeles y abre preview lateral;
- cartas jugables pueden recibir halo discreto tipo Shadowverse;
- la mano rival conserva tamaño comparable pero usa reversos y puede comprimir más si crece.

## Campo

Orden visual propuesto de arriba a abajo:

1. HUD rival;
2. mano rival;
3. apoyos rivales;
4. criaturas rivales;
5. eje/banda de fase muy fina;
6. criaturas propias;
7. apoyos propios;
8. mano propia;
9. HUD propio si la resolución exige separarlo de la mano.

Baraja, Cementerio, Terreno y materiales de Fusión quedan a los laterales de las filas que mejor representen su función. No deben formar una segunda interfaz paralela.

## Turno y fases

- fase actual siempre visible, pero la banda no debe cortar el tablero;
- las seis fases pueden mostrarse como pequeños segmentos, resaltando una sola;
- `Ir a Combate`, `Ir a Principal 2`, etc. pueden compartir un botón contextual cuya etiqueta sea la acción real;
- `Terminar turno` debe ser estable y fácil de localizar, inspirado en la claridad de Shadowverse/Marvel Snap;
- Inicio y Robo automáticos no necesitan botones salvo una situación excepcional de regla;
- Guardar, Cargar, semilla, cambiar vista y otras utilidades no pertenecen al HUD principal de una partida normal.

## Ataque y guardia

Flujo candidato definitivo:

1. seleccionar criatura propia;
2. si todavía no estamos en Combate, conservar selección y mostrar `Ir a Combate`;
3. en Combate, resaltar únicamente criaturas rivales atacables;
4. si no existen criaturas rivales, resaltar la Vida/HUD rival como destino directo;
5. al elegir destino, mostrar opcionalmente previsión pública `si se resolviera ahora`;
6. confirmar/abrir respuestas según las reglas;
7. durante prioridad, congelar interacciones ordinarias y mostrar quién decide;
8. resolver;
9. animaciones futuras comunicarán destrucción/daño, pero el greybox debe poder explicarlo ya con texto corto e iconos.

La postura visual sigue siendo vertical/horizontal; no necesitamos inventar un botón permanente `ATQ/DEF` sobre cada criatura.

## Respuestas y cadena

Esta es una de las zonas donde más podemos mejorar sobre la mesa técnica actual.

Candidato inspirado sobre todo en Runeterra/Flesh and Blood:

- cuando no hay respuesta, la cadena no ocupa espacio;
- al abrirse `pending_response`, aparece una franja o pila temporal cerca del centro/eje;
- cada efecto comprometido tiene una miniatura/etiqueta ordenada;
- una marca visible indica **TU RESPUESTA** / **RIVAL DECIDE**;
- acciones legales reactivas se resaltan sobre sus propias cartas cuando sea posible;
- `Pasar` es un botón claro solo mientras existe prioridad;
- al cerrarse por dos pases, la cadena se resuelve visualmente en sentido LIFO;
- el historial conserva después los hechos, pero no es necesario mirar el historial para entender la resolución presente.

## Previsión de resultado público

Candidato de alto valor inspirado en `Oracle's Eye` de Runeterra y en telemetría de otros juegos digitales.

Principios:

- nunca revelar una carta oculta ni inferir si el rival tiene una respuesta;
- usar exclusivamente el estado público actual y las estadísticas efectivas visibles;
- etiquetar claramente que es una previsión **si se resolviera ahora**;
- recalcularla cada vez que una respuesta pública modifica el contexto;
- si el motor no puede garantizar una previsión exacta sin información privada, no mostrarla.

Ejemplo conceptual:

`Lobo 4 ATQ / 3 DEF → Troll 2 ATQ / 3 DEF`  
`Resultado actual: Troll destruido · Lobo sobrevive · 1 daño sobrante si procede según postura`.

No es una nueva regla: es una explicación del cálculo que ya realizaría el motor.

## Lateral contextual

Estado normal:

- preview de carta seleccionada;
- nombre/tipo/coste/ATQ/DEF;
- habilidad completa;
- equipos, materiales de Fusión o identidad de Terreno cuando corresponda.

Estado de decisión excepcional:

- el lateral puede transformarse temporalmente en decisión si no existe una representación natural sobre el tablero;
- no debe volver a convertirse en lista de todas las acciones legales del turno.

Historial:

- plegado por defecto;
- últimos hechos en lenguaje humano;
- diagnóstico completo solo en modo debug.

## Información mínima que debe entenderse en unos segundos

Sin abrir menús, un jugador debería reconocer:

- cuál es su mano;
- cuál es su campo y cuál el rival;
- cuánta Vida tiene cada uno;
- Energía disponible/máxima propia;
- fase y de quién es el turno;
- cuáles de sus cartas son jugables ahora;
- qué carta tiene seleccionada;
- cuáles son los destinos válidos de esa selección;
- dónde están Baraja, Cementerio, Terreno y Fusión;
- si existe una respuesta/decisión pendiente y quién debe actuar.

## Ideas descartadas como base

- cuadrícula técnica dominante;
- perspectiva profunda que reduzca al rival;
- cartas rivales más pequeñas que las propias;
- gran emblema central sin función;
- `VACÍA` repetido veinte veces;
- lista permanente `ACCIONES LEGALES`;
- botones de todas las fases en mitad del campo;
- duplicar una acción en carta, casilla y panel lateral;
- usar texto para comunicar un estado que ya puede mostrar orientación, icono o resaltado;
- mezclar Guardar/Cargar/semilla/IA con las decisiones principales de juego;
- diseñar cada tamaño en píxeles aislados sin una unidad de carta común.

## Primera síntesis candidata de Zápiti/JCP

Si hubiera que construir hoy la siguiente revisión del greybox, la base sería:

1. **Proporción de carta 63:88** y todas las medidas derivadas de `U`.
2. **Geometría de campo cercana al patrón Yu-Gi-Oh** porque nuestro reglamento ya tiene cinco criaturas + cinco apoyos y estados ataque/guardia, no porque se copie su arte.
3. **Mano y preview al estilo de los mejores clientes digitales**: directa, legible, expandible y sin panel técnico.
4. **Cartas jugables resaltadas** como Shadowverse.
5. **Selección carta → destino** como MTG Arena y otros digitales.
6. **Equipo pegado visualmente al portador** tomando como referencia la claridad de adjuntos de Pokémon.
7. **Fusión como una entidad visible con materiales inspeccionables**, aprovechando la idea general de cartas apiladas/transformadas sin copiar Lorcana.
8. **Respuestas en una mini-cadena temporal** inspirada en Runeterra/Flesh and Blood.
9. **Previsión pública opcional de combate/cadena** inspirada en Oracle's Eye, calculada por UCE y sin información oculta.
10. **Fase, energía y terminar turno extremadamente claros**, tomando la sencillez de Shadowverse y Marvel Snap.
11. **Territorio como zona ambiental propia**, no como una caja administrativa.
12. **Debug completamente secundario**.

## Orden de trabajo recomendado

Antes de seguir refinando código visual:

1. revisar este cuaderno y añadir cualquier referencia que aporte una ventaja real;
2. convertir la síntesis aceptada en un estándar de interfaz con medidas y estados cerrados;
3. actualizar `GREYBOX_INTERFAZ_FINAL_V0_1.md` con ese estándar;
4. adaptar la rama greybox a las medidas y gramática aprobadas;
5. ejecutar parser/runtime y pruebas de interfaz;
6. revisar una captura real;
7. solo entonces comenzar la sesión humana completa.

La intención de este orden es evitar veinte o cincuenta microcorrecciones que ya están resueltas por convenciones maduras de TCG.

## Fuentes públicas principales consultadas

- Konami — *Yu-Gi-Oh! Official Rulebook*, Game Mat / Monster Position.
- Wizards of the Coast — *MTG Arena: State of the Game – January 2021* y *MTG Arena Mobile FAQs*.
- Riot Games — soporte de *Legends of Runeterra: Oracle's Eye* y notas de juego sobre velocidades/respuestas.
- Cygames — *Shadowverse Game Guide / Play Guide*.
- The Pokémon Company — *Pokémon Trading Card Game Rules* y documentación de TCG Live.
- Second Dinner — *Marvel Snap: How to Play*.
- Legend Story Studios — *Flesh and Blood Comprehensive Rules* y *Quickstart Rules*.
- Ravensburger — *Disney Lorcana: How to Play for TCG Players* y documentación de Shift.
- Cygames — *Shadowverse: Evolve Play Guide*.
- Dire Wolf Digital — *Eternal Advanced Rules*.

Las fuentes sirven para extraer principios funcionales. Ningún asset externo forma parte del proyecto.