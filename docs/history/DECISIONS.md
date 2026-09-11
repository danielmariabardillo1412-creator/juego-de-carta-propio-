# Decisiones técnicas vivas

## UCE-DEC-001 — Dos motores, no una sustitución

El motor universal será independiente. El motor actual de Zápiti se conserva y, en una fase futura, ambos se expondrán mediante adaptadores.

## UCE-DEC-002 — El núcleo no conoce reglas de cartas

En UCE-01 el motor solo conoce acciones, estados opacos, eventos y ciclo de vida. Palos, rangos, turnos, zonas y puntuaciones pertenecerán a capas posteriores o módulos de juego.

## UCE-DEC-003 — Un único punto de mutación

Toda modificación confirmada pasa por `UniversalCardEngine.perform_action()`. Las vistas no pueden modificar el estado comprometido.

## UCE-DEC-004 — Transición atómica

El módulo recibe una copia del estado. El motor solo sustituye el estado comprometido después de validar completamente el resultado y todos sus eventos.

## UCE-DEC-005 — Semilla explícita

UCE-01 rechaza semillas negativas y no inventa una semilla temporal. Esto evita partidas no reproducibles y obliga a que el llamador conserve la autoridad sobre la aleatoriedad.

## UCE-DEC-006 — Duck typing validado

GDScript no proporciona interfaces formales suficientes para este uso. Se utiliza un contrato pequeño verificado en tiempo de ejecución, sin obligar a que los juegos hereden una jerarquía rígida.

## UCE-DEC-007 — Estado portátil de datos puros

El estado comprometido, los payloads de acciones y los payloads de eventos se limitan a tipos portátiles: null, booleanos, enteros, flotantes finitos, cadenas, arrays y diccionarios con claves String. Esto hace reales la copia profunda, la trazabilidad y la futura persistencia.

## UCE-DEC-008 — Módulos de reglas sin estado oculto

`validate_action()` y `reduce()` deben comportarse como funciones deterministas respecto al estado y la acción recibidos. La aleatoriedad, contadores y cualquier autoridad mutable deben vivir en el estado explícito, no en variables ocultas del objeto módulo. Esta condición todavía no puede imponerse automáticamente y deberá probarse mediante replay en una fase posterior.

## UCE-DEC-009 — Definición e instancia son conceptos distintos

Una definición describe un tipo de carta. Una instancia representa una copia física concreta dentro de la partida. Esto permite duplicados, varios mazos y juegos coleccionables sin adulterar la identidad.

## UCE-DEC-010 — Colocación total y exclusiva

Toda instancia debe pertenecer exactamente a una zona. Para retirar una carta del juego se utilizará una zona explícita, por ejemplo `out_of_play`, en vez de dejar referencias flotantes.

## UCE-DEC-011 — Las zonas son colecciones ordenadas

El orden forma parte del estado. Esta decisión permite representar mazos, pilas, manos ordenadas y descartes. UCE-02 no decide todavía qué extremo es la parte superior; cada operación o módulo debe hacerlo explícito.

## UCE-DEC-012 — La visibilidad pertenece a la zona

La identidad de una carta se muestra o se oculta según la zona y el espectador. La carta no contiene un estado global `face_up` en esta fase porque esa propiedad no cubre manos privadas, visibilidad por equipos ni información selectiva.

## UCE-DEC-013 — Movimiento inmutable

`CardState.move_card()` devuelve un estado nuevo. Si cualquier validación falla, el estado recibido permanece intacto.

## UCE-DEC-014 — Identificadores técnicos sin espacios

Los identificadores de definiciones, instancias y zonas son cadenas estables, sin espacios ni caracteres de control. Los nombres visibles pertenecen a atributos o metadatos.

## UCE-DEC-015 — RNG propio y especificado

El motor no utiliza `RandomNumberGenerator` como formato de persistencia. UCE-03 define `lcg31-v1`, cuyos parámetros y estado son explícitos, para poder reproducir partidas en Godot, Python u otros lenguajes.

## UCE-DEC-016 — RNG como datos puros

Cada operación recibe un snapshot RNG y devuelve otro. Ningún singleton ni objeto mutable oculto conserva la autoridad aleatoria. Esto permite snapshots, comparación y replay.

## UCE-DEC-017 — Rangos sin sesgo de módulo

`next_int()` utiliza rejection sampling. Aunque sea más costoso en casos concretos, evita favorecer ciertos resultados cuando el rango no divide exactamente el periodo del generador.

## UCE-DEC-018 — Shuffle separado del reparto

Barajar y repartir son operaciones distintas. Un juego puede repartir un mazo ya ordenado, usar una pila preconfigurada o aplicar otro orden sin estar obligado a consumir RNG.

## UCE-DEC-019 — Extremo del mazo explícito

Las operaciones de reparto deben declarar `START` o `END`. El núcleo no impone que el principio o el final del array sea la parte superior del mazo.

## UCE-DEC-020 — Reparto con preflight atómico

Antes del primer movimiento se validan fuente, destinos, cantidad y capacidad total. Un reparto imposible devuelve error sin producir un reparto parcial.
