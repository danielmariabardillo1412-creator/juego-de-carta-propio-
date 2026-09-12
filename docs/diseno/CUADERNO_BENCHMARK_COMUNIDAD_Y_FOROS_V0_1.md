# Cuaderno de benchmark — comunidad y foros V0.1

Estado: **cuaderno de investigación activo; anexo del benchmark de interfaz**  
Fecha: **2026-09-12**  
Ámbito: **ideas de UX/QoL propuestas por jugadores y filtradas por viabilidad técnica para JCP**  
Documento relacionado: `docs/diseno/CUADERNO_BENCHMARK_INTERFAZ_TCG_V0_1.md`

## Propósito

Este cuaderno recoge una capa distinta del benchmark anterior. El primero estudia soluciones ya implementadas por juegos comerciales; este estudia **lo que los jugadores dicen que echan de menos, lo que les confunde y las pequeñas mejoras que consideran valiosas**.

No se incorporará una idea porque tenga muchos votos o porque suene espectacular. El filtro obligatorio es:

1. ¿resuelve un problema real que también puede aparecer en JCP?;
2. ¿puede hacerse con nuestra capacidad técnica actual —Godot, UI 2D/2.5D y datos del motor—?;
3. ¿mejora claridad, velocidad o aprendizaje sin añadir otra capa de ruido?;
4. ¿puede respetar privacidad, replay, determinismo y `UniversalCardEngine` como autoridad?;
5. ¿su coste de mantenimiento es razonable para un proyecto pequeño?

Quedan fuera como criterio de esta fase las peticiones basadas en grandes animaciones 3D, invocaciones cinematográficas, monstruos que salen físicamente de la carta, escenarios que se reconstruyen mediante VFX complejos o cualquier otra mejora que requiera un equipo de animación/FX. Pueden ser deseables, pero **no son una dependencia para que el juego sea cómodo, legible y agradable**.

## Fuentes comunitarias consultadas

Se revisaron discusiones de Reddit, Steam Community y BoardGameGeek alrededor de Master Duel, Hearthstone, MTG Arena y deckbuilders digitales. No se toma ningún comentario individual como verdad universal; interesan sobre todo patrones que reaparecen en comunidades distintas.

Referencias especialmente útiles:

- Reddit / Master Duel — *What Quality of Life things would you like in Master Duel?* (2026): https://www.reddit.com/r/masterduel/comments/1ui1j5p/
- Reddit / Master Duel — *What are some Quality of Life features...* (2025): https://www.reddit.com/r/masterduel/comments/1ibzdhz/
- Reddit / Master Duel — *New in game menu reminds you of locks and lingering effects* (2025): https://www.reddit.com/r/masterduel/comments/1iiyhyz/
- Reddit / Master Duel — *Quality of life changes i want* (2022): https://www.reddit.com/r/masterduel/comments/wce5qt/
- Reddit / Master Duel — *The most difficult enemy in this game is reading* (2022): https://www.reddit.com/r/masterduel/comments/tjfpfh/
- Reddit / YuGiOhMasterDuel — *New Master Duel Feature Idea: Telling you why you can't do something* (2022): https://www.reddit.com/r/YuGiOhMasterDuel/comments/w5wlbl/
- Steam / Master Duel — discusiones sobre cadenas, efectos persistentes y claridad de interfaz: https://steamcommunity.com/app/1449850/discussions/0/3189112650394833222/ y https://steamcommunity.com/app/1449850/discussions/0/598515152383435328/
- Reddit / Monster Train — feedback de tooltips y poder consultar el tablero durante selecciones: https://www.reddit.com/r/MonsterTrain/comments/1lg1i9h/
- Reddit / Slay the Spire — feedback móvil sobre selección accidental, lectura y confirmación: https://www.reddit.com/r/slaythespire/comments/1uv18z6/
- BoardGameGeek — feedback UX sobre confirmación antes de revelar información y undo previo: https://boardgamegeek.com/thread/3593333/digital-app-bugs-and-feedback

## Patrón comunitario 1 — «Dime qué me está afectando ahora mismo»

### Problema observado

En Master Duel reaparece constantemente la confusión por **efectos persistentes o heredados que siguen activos aunque la carta fuente ya no sea obvia**. Jugadores piden poder consultar inmunidades, bloqueos, efectos concedidos por materiales y restricciones activas sin reconstruir todo el historial. La recepción del menú de efectos persistentes añadido posteriormente fue muy positiva incluso entre jugadores veteranos.

### Adaptación a JCP

Crear una vista contextual **`EFECTOS ACTIVOS`**, nunca como panel gigante permanente. Puede abrirse desde una criatura, jugador o HUD y listar solo aquello que realmente está influyendo en ese objeto o jugador.

Ejemplos propios:

- `+1 ATQ hasta final del turno · fuente: G01`;
- `+1 DEF en guardia · fuente: G04`;
- `ataque adicional disponible · fuente: M18`;
- `F068: -1 ATQ · expira al final de tu próximo turno`;
- `equipo E01 vinculado`;
- `ataque ya consumido este turno`;
- `Fusión recién formada: no puede atacar este turno`.

Debe mostrar **fuente + efecto + duración**, no solo un icono misterioso.

### Coste estimado

**Medio, valor muy alto.** Gran parte de la información ya existe en estado/vistas. La dificultad real es exponerla de forma saneada y genérica desde UCE sin que la UI reconstruya reglas.

### Prioridad

**ALTA. Candidata para el estándar previo a prueba humana.**

## Patrón comunitario 2 — «¿Por qué no puedo hacer esto?»

### Problema observado

Hay un patrón enorme de mensajes de jugadores que creen haber encontrado un bug porque una acción no aparece o no puede ejecutarse. La comunidad de Master Duel lleva años pidiendo una explicación directa: *“no puedes activar esto porque X efecto/restricción está vigente”*.

### Adaptación a JCP

No basta con desactivar una carta. Cuando el jugador inspeccione una carta o criatura que parece utilizable pero no lo es, debería poder obtener una explicación breve:

- `No puedes atacar: esta Fusión entró este turno.`
- `No puedes atacar directamente: el rival controla una criatura.`
- `No puedes activar esta respuesta: fue preparada este turno.`
- `No puedes equipar E01: la criatura no tiene Manipulador.`
- `No puedes fusionar: ya utilizaste tu acción de Fusión este turno.`

**Regla técnica importante:** la UI no debe inventar estas explicaciones. A medio plazo UCE debería disponer de una consulta no mutante de tipo `explain_action` / `explain_unavailable_action`, basada en los mismos códigos de validación que el motor.

No se necesita explicar cada acción imposible del universo. Se explica la acción razonable que el usuario acaba de intentar o la razón principal por la que una carta seleccionada no ofrece el comportamiento esperado.

### Coste estimado

**Medio-alto, valor enorme.** Requiere ampliar contrato del motor si queremos hacerlo correctamente y sin duplicar reglas.

### Prioridad

**ALTA, pero posterior al layout básico.** Merece una fase propia de motor/interfaz, no un hack dentro del greybox.

## Patrón comunitario 3 — Texto de carta estructurado, no pared de texto

### Problema observado

Una de las peticiones comunitarias más repetidas en Yu-Gi-Oh digital es separar efectos, usar saltos de línea y resaltar la parte relevante. Los jugadores explican que vuelven a leer la misma carta varias veces porque un bloque continuo dificulta identificar qué efecto está actuando.

### Adaptación a JCP

Nuestras cartas no necesitan copiar la redacción compacta del papel. En el **preview grande**:

- cada efecto independiente ocupa su propio bloque;
- palabras funcionales propias pueden tener icono/etiqueta consistente;
- si una carta tiene una habilidad activa y otra automática, se separan;
- durante una resolución puede resaltarse solo la cláusula que se está usando;
- una habilidad de `1/turno` ya consumida puede mostrar una marca discreta junto a ese bloque;
- condiciones importantes pueden tener una línea aparte (`Solo en Principal`, `Una vez por turno`, etc.).

En la carta pequeña solo se mantiene el resumen mínimo; no intentaremos meter todo el reglamento en 72×101 px.

### Coste estimado

**Bajo-medio, valor alto.** Principalmente presentación y modelo de texto.

### Prioridad

**ALTA.**

## Patrón comunitario 4 — Mostrar la procedencia de cada bono, penalización o inmunidad

### Problema observado

Jugadores piden poder pasar sobre una carta y saber qué efecto externo la modificó. No quieren recorrer el log carta por carta para descubrir por qué una criatura sobrevivió, perdió ATQ o está restringida.

### Adaptación a JCP

Cada modificación visible debería poder responder a `¿de dónde viene?`:

- icono `+1 ATQ` → tooltip `M15 · hasta final del turno`;
- pestaña de equipo → nombre de E01/E03/E06;
- penalización F068 → fuente y expiración;
- F001 → bonus solo del combate actual;
- protección F018 → `regeneración ya usada/no usada este turno`.

Esto encaja con `EFECTOS ACTIVOS`; no debe convertirse en otro sistema paralelo.

### Coste estimado

**Medio.**

### Prioridad

**ALTA-MEDIA.**

## Patrón comunitario 5 — Contadores y usos restantes visibles

### Problema observado

En distintas comunidades se pide que una interfaz muestre usos, contadores o cargas restantes en vez de obligar a recordar si algo ya se activó. También aparece la crítica a iconos que permanecen visibles aunque el uso ya se haya consumido.

### Adaptación a JCP

En lugar de texto grande:

- `1` o marca de uso disponible en habilidades una vez por turno;
- marca apagada/check cuando ya se consumió;
- segundo ataque disponible de M18/F005 visible hasta utilizarse;
- E04 muestra si el traslado sigue disponible;
- F018 indica si su reemplazo de destrucción ya se gastó;
- duración temporal visible cuando cruza turnos.

### Coste estimado

**Bajo-medio.**

### Prioridad

**ALTA.** Especialmente porque nuestro juego ya contiene varios efectos `una vez por turno`.

## Patrón comunitario 6 — Menos ventanas y menos clics inútiles

### Problema observado

Jugadores de Master Duel y otras adaptaciones digitales se quejan mucho más de **microinterrupciones repetitivas** que de la falta de espectacularidad. Una decisión que requiere dos o tres clics aunque solo exista una opción legal se siente lenta; las ventanas reactivas que aparecen constantemente también inducen errores.

### Adaptación a JCP

- si existe exactamente **una resolución obligatoria y ninguna elección real**, la interfaz no debe fingir que hay una decisión;
- cuando una carta tenga dos efectos realmente elegibles, mostrarlos simultáneamente en vez de `abrir menú → escoger menú → confirmar`;
- el botón contextual de fase debe llevar directamente al siguiente paso real, evitando `cambiar fase → confirmar la misma fase` salvo que exista una consecuencia irreversible;
- las respuestas opcionales sí deben detener el flujo: no se automatizan porque son decisiones reales;
- `Pasar` solo aparece durante prioridad;
- no repetir en una ventana una elección que ya se hizo sobre el tablero.

### Coste estimado

**Bajo-medio.**

### Prioridad

**ALTA.**

## Patrón comunitario 7 — Poder mirar el tablero mientras decides

### Problema observado

En Monster Train y otros juegos aparecen peticiones de ocultar temporalmente una pantalla de selección para consultar el campo, mazo o contexto antes de elegir. Una modal que tapa precisamente la información necesaria para decidir empeora el juego.

### Adaptación a JCP

Las decisiones excepcionales —F067, redirección M13, Fusión, selección de objetivo— no deberían secuestrar la pantalla. Opciones:

- panel pequeño o banda contextual sin oscurecimiento total;
- botón `ver tablero` que pliega temporalmente la decisión sin cancelarla;
- permitir inspeccionar cartas mientras la decisión está pendiente;
- bloquear solo las acciones que mutarían el estado, no la inspección.

### Coste estimado

**Bajo-medio.**

### Prioridad

**ALTA-MEDIA.**

## Patrón comunitario 8 — Confirmar solo donde importa; cancelar antes de comprometer

### Problema observado

Feedback móvil y de juegos de mesa digitales muestra dos extremos malos: confirmar absolutamente todo, o permitir que un roce revele información/ejecute una acción irreversible. La petición recurrente es un undo/cancel coherente antes del punto de compromiso.

### Adaptación a JCP

Definir claramente un **punto de commit**:

- seleccionar carta, material, casilla u objetivo = reversible;
- `Esc` / botón secundario / `Cancelar` vuelve al estado anterior de selección;
- antes de revelar información privada, sustituir Terreno o terminar turno puede existir confirmación;
- después de enviar la acción válida a `UniversalCardEngine.perform_action()` no existe `undo` de partida normal.

No implementaremos un rebobinado de acciones ya resueltas: complicaría información oculta, prioridad, replay y futuro multijugador. El valor comunitario del undo se conserva donde es seguro: **corregir un clic antes de comprometer la acción**.

### Coste estimado

**Bajo.**

### Prioridad

**ALTA.**

## Patrón comunitario 9 — Animaciones opcionales, rápidas y nunca necesarias para comprender

### Problema observado

La comunidad pide con frecuencia desactivar o acelerar animaciones porque retrasan turnos y pueden empeorar rendimiento. También aparecen quejas de que partículas y transiciones ocultan el estado del tablero.

### Adaptación a JCP

Esto encaja especialmente bien con nuestras limitaciones técnicas:

- no depender de cinemáticas 3D;
- animaciones 2D simples y cortas solo como feedback;
- opción `Reducir movimiento`;
- opción futura de velocidad `Normal / Rápida`;
- ningún dato de regla existe únicamente durante una animación;
- efectos importantes permanecen visibles después mediante estado/icono/historial.

### Coste estimado

**Bajo si se diseña así desde el principio.**

### Prioridad

**MEDIA, pero debe condicionarnos desde ya.**

## Patrón comunitario 10 — Historial útil, no vertedero técnico

### Problema observado

Los jugadores sí consultan logs, pero se quejan cuando el log es la **única** forma de entender el estado actual. También valoran que el historial permita revisar qué efecto concreto se activó.

### Adaptación a JCP

El historial queda plegado, pero sus entradas deberían ser humanas y, si es viable, inspeccionables:

`M15 dio +1/+1 a M09 hasta fin de turno`  
`T05 destruyó E03 vinculado a F010`  
`F067 eligió +1 DEF para este combate`

Al pulsar una entrada podría abrirse el preview de la carta/efecto si esa identidad es pública para el visor. El historial explica el pasado; `EFECTOS ACTIVOS` explica el presente.

### Coste estimado

**Medio.**

### Prioridad

**MEDIA.**

## Patrón comunitario 11 — Tooltips configurables; no tutorial perpetuo

### Problema observado

Jugadores nuevos agradecen que toda mecánica tenga explicación accesible. Jugadores experimentados se quejan cuando los tooltips aparecen constantemente y tapan el campo.

### Adaptación a JCP

Tres niveles de ayuda son suficientes:

- `Primera vez`: explica una mecánica la primera vez que aparece;
- `Siempre`: tooltip completo para quien lo prefiera;
- `Mínima`: solo nombres/iconos y ayuda bajo demanda.

No hace falta construir estos ajustes antes del primer greybox, pero la UI debe evitar diseños que obliguen a una caja de ayuda permanente.

### Coste estimado

**Medio.**

### Prioridad

**MEDIA-BAJA para la primera prueba; ALTA para onboarding futuro.**

## Patrón comunitario 12 — Móvil: evitar selección accidental por scroll/drag

### Problema observado

En Slay the Spire móvil y otros clientes, jugadores describen que desplazar una mano o lista se interpreta como tocar/arrastrar una carta. Es un problema de UX muy concreto y fácil de introducir si el drag es obligatorio.

### Adaptación a JCP

Confirma una decisión ya favorable del benchmark principal:

- tap/clic selecciona;
- drag nunca será la única vía de juego;
- si un gesto supera un umbral de desplazamiento, se interpreta como scroll, no selección;
- después de tocar una carta dirigida aún hay un segundo paso de objetivo, por lo que un toque accidental no ejecuta inmediatamente una acción.

### Coste estimado

**Bajo si se contempla desde el diseño móvil.**

### Prioridad

**FUTURA**, pero no debemos cerrarnos el camino.

## Ideas de comunidad aparcadas para otras fases

No pertenecen al greybox de duelo actual, pero son suficientemente útiles para conservarlas:

- **deckbuilder:** favoritos, etiquetas personales (`starter`, `respuesta`, `fusión`, etc.), búsqueda por texto de carta además de nombre y agrupación de variantes;
- **postpartida:** inspeccionar mazo rival si el formato y privacidad futura lo permiten;
- **replay:** guardar partidas destacadas y poder revisar decisiones;
- **accesibilidad:** tamaño de texto, señales no dependientes solo del color, control por teclado/mando y reducción de movimiento.

No se implementan ahora porque ampliarían alcance antes de cerrar la partida básica.

## Ideas rechazadas o transformadas

### Animaciones/monstruos 3D espectaculares

Deseables si existiera equipo y presupuesto, pero fuera de alcance. No son necesarias para resolver información, interacción ni comodidad.

### Undo después de una acción resuelta

Se transforma en `cancelar antes del commit`. Un undo real tras revelar cartas o respuestas comprometería replay, determinismo y futuro PvP.

### Mostrar toda la información todo el tiempo

Se rechaza. Los foros también muestran que demasiados overlays/tooltips producen el problema contrario. La información permanente será mínima; el detalle se obtiene por selección/hover/inspección.

### Automatizar toda respuesta posible

Se rechaza. Reducir prompts no significa quitar decisiones. Una respuesta opcional puede cambiar la partida y debe seguir perteneciendo al jugador.

## Matriz de valor / coste para nuestro proyecto

| Idea | Valor para jugador | Coste técnico | Fase recomendada |
| --- | --- | --- | --- |
| texto estructurado y cláusula relevante | muy alto | bajo-medio | greybox consolidado |
| contadores/usos visibles | alto | bajo-medio | greybox consolidado |
| cancelar selección antes de commit | alto | bajo | greybox consolidado |
| reducir clics sin elección real | alto | bajo-medio | greybox consolidado |
| inspeccionar tablero durante decisión | alto | bajo-medio | greybox consolidado |
| efectos activos con fuente/duración | muy alto | medio | greybox / siguiente corte |
| procedencia de buffs/debuffs | alto | medio | junto a efectos activos |
| `¿por qué no puedo?` desde UCE | muy alto | medio-alto | fase propia tras layout |
| historial humano/clicable | medio-alto | medio | tras greybox |
| tooltips configurables | medio | medio | onboarding |
| velocidad/reducir movimiento | medio | bajo | cuando haya animaciones |
| deckbuilder favoritos/etiquetas | alto, fuera del duelo | medio | construcción de mazos |
| animaciones 3D/cinemáticas | estética alta | muy alto/no viable ahora | descartado para alcance actual |

## Joyas que merece la pena conservar

Tras filtrar las conversaciones, las cuatro ideas comunitarias con mejor relación valor/trabajo para JCP son:

1. **`¿Qué me está afectando?`** — efectos activos, procedencia y duración accesibles desde la carta/HUD.
2. **`¿Por qué no puedo?`** — explicación del propio motor cuando una acción intuitiva está bloqueada.
3. **Texto estructurado + resaltar exactamente el efecto que se está resolviendo.**
4. **Un punto de commit claro:** todo puede corregirse mientras solo estamos seleccionando; una vez que UCE resuelve, la acción queda cerrada.

Estas cuatro ideas no requieren 3D, animación de personajes ni producción artística avanzada. Son principalmente **calidad de información y flujo**, y precisamente por eso son apropiadas para un proyecto pequeño.

## Consecuencia para el benchmark principal

Este anexo no autoriza todavía código nuevo. Antes de adaptar el greybox, la síntesis final debe cruzar:

- benchmark de productos existentes (`CUADERNO_BENCHMARK_INTERFAZ_TCG_V0_1.md`);
- este benchmark comunitario;
- reglas y privacidad propias de JCP;
- coste real de implementación.

La siguiente consolidación debe distinguir tres grupos:

- **obligatorio en el greybox humano**;
- **deseable después de validar la mesa**;
- **aparcado para una fase futura**.

Así evitamos tanto copiar las limitaciones de los grandes juegos como intentar satisfacer cada deseo de un foro.