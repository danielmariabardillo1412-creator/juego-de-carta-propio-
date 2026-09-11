# Flujo de partida e interacción V0.1

Estado: **APROBADO E IMPLEMENTADO COMO BASE DE PRUEBA HUMANA**  
Fecha: **2026-09-11**

## Autoridad y alcance

Este documento traduce a interacción visible las reglas ya fijadas en S00 y S01. No añade reglas de cartas ni altera combate, Energía, Fusiones o destinos.

Fuentes comprobadas:

- S00 `00_ESTADO_Y_METODO_DE_TRABAJO`: filas de criaturas y apoyos, sin movimiento táctico por casillas.
- S01 `01_MECANICAS_BASICAS_EN_DISCUSION`: orientación, ocultación, zonas, invocación, Energía, fases, respuestas, equipo, Terrenos y Fusiones.
- Las fechas de Drive de S00 y S01 coinciden con `SOURCE_MANIFEST.json` el 2026-09-11.

## Principio visual

La mesa puede usar una disposición familiar y sencilla, cercana en legibilidad a los juegos de cartas físicos conocidos, sin copiar marcos, símbolos, nombres ni presentación protegida.

- Rival arriba y jugador abajo.
- Cinco espacios de criaturas por lado.
- Cinco espacios de apoyo por lado.
- Un Territorio por jugador.
- Baraja y Cementerio visibles como montones laterales.
- Mano del jugador en la parte inferior; mano rival como reversos.
- Equipos y objetos vinculados se muestran junto o debajo de su criatura, no en la fila de apoyo.
- Materiales de Fusión se consultan desde la entidad fusionada.

Los espacios no forman un tablero táctico. Elegir centro, esquina o cualquier otro hueco solo organiza la mesa; no concede alcance, movimiento, flanqueo ni bonificaciones salvo que una futura carta lo indique expresamente.

## Flujo principal de una partida

### 1. Comienzo del turno

La interfaz anuncia claramente `TURNO DEL JUGADOR` o `TURNO DEL RIVAL`.

Inicio y Robo son fases reglamentarias, pero sus operaciones ordinarias son automáticas:

1. aumentar y rellenar Energía;
2. restaurar ataques y usos por turno;
3. resolver efectos obligatorios de Inicio;
4. robar una carta, excepto el jugador inicial en su primer turno;
5. entrar en Principal 1.

La interfaz puede mostrar brevemente estas fases en una banda o animación, pero no debe exigir pulsar dos botones vacíos para llegar a la primera decisión.

### 2. Principal 1

El jugador puede realizar, en el orden que quiera y mientras cada acción siga siendo legal:

- su única invocación o colocación normal de criatura del turno;
- invocaciones adicionales concedidas por efectos;
- Magias de fase principal;
- preparación de Trampas y Magias reactivas;
- Magias persistentes y apoyos independientes;
- equipos y objetos;
- Terrenos y transformaciones de Terreno;
- cambios de postura legales;
- habilidades;
- Fusiones.

No existe un número general de «jugadas» por turno. Los límites proceden de Energía, mano, espacios, una invocación normal, preparación, objetivos, condiciones y texto de carta.

Controles principales:

- `IR A COMBATE`;
- `TERMINAR TURNO`, disponible para quien no quiera combatir ni usar Principal 2;
- indicador permanente `Invocación normal: disponible/usada`;
- Energía disponible y máxima.

### 3. Combate

Para atacar:

1. pulsar una criatura propia visible en ataque;
2. la interfaz marca criaturas enemigas válidas;
3. pulsar el objetivo;
4. si el rival no controla criaturas, se marca el retrato o zona de vida para ataque directo;
5. se abre la ventana de respuestas correspondiente;
6. tras las respuestas se revela una guardia oculta si procede y se calcula el combate.

Cada criatura puede declarar normalmente un ataque por turno. El jugador puede finalizar Combate aunque queden ataques disponibles.

Controles principales:

- `IR A PRINCIPAL 2`;
- `TERMINAR TURNO` si la interfaz confirma que se renuncia a Principal 2.

### 4. Principal 2

Permite las mismas familias de acciones que Principal 1. La invocación normal solo aparece disponible si no se utilizó antes. Una criatura que atacó no puede pasar voluntariamente a guardia ese turno.

Control principal: `TERMINAR TURNO`.

### 5. Final

Se resuelven automáticamente efectos de Final, expiraciones, mantenimientos y consecuencias obligatorias. Después el control pasa al rival. El jugador no debe pulsar otro botón vacío una vez confirmada la finalización.

## Interacción por tipo de carta

### Criatura desde la mano

1. Pulsar la criatura.
2. Mostrar ficha ampliada y coste.
3. Resaltar los cinco huecos libres equivalentes.
4. Pulsar el hueco deseado.
5. Elegir en una ventana central:
   - `ATAQUE · boca arriba y vertical`;
   - `GUARDIA · boca abajo y horizontal`.
6. Confirmar y pagar Energía.

La misma criatura no se deselecciona por un segundo clic accidental. `Esc`, clic fuera o un botón `CANCELAR` terminan la selección.

### Magia de fase principal

1. Pulsar la Magia en la mano.
2. Resaltar exclusivamente sus objetivos legales.
3. Pulsar objetivo.
4. Mostrar una confirmación corta si el efecto implica una pérdida importante o una incompatibilidad.
5. Resolver y enviar la carta al Cementerio.

### Trampa o Magia reactiva

1. Pulsar la carta.
2. Resaltar espacios de apoyo libres.
3. Elegir espacio.
4. Colocarla boca abajo.
5. No permitir activarla el mismo turno salvo excepción escrita.

Cuando se cumpla su condición durante una respuesta, la interfaz pregunta `ACTIVAR` o `PASAR`; no obliga a cambiar toda la vista al rival si ese rival está controlado por IA.

### Magia persistente o apoyo independiente

1. Pulsar la carta.
2. Elegir un espacio de apoyo libre.
3. Entrar boca arriba y comenzar a funcionar inmediatamente.

### Equipo u objeto vinculado

1. Pulsar el equipo.
2. Resaltar criaturas compatibles.
3. Pulsar portador.
4. Si es incompatible, no ofrecerlo como destino; si una regla permite intentarlo con riesgo, mostrar advertencia antes de confirmar.
5. Mostrar la carta vinculada junto o debajo del portador.

El Banco de herramientas y otros artefactos independientes sí ocupan apoyo.

### Terreno

1. Pulsar el Terreno.
2. Resaltar la franja `TU TERRITORIO`.
3. Pulsarla para jugar.
4. Si ya existe uno, mostrar una previsualización: transformación conocida o sustitución.
5. Confirmar únicamente cuando vaya a sustituirse y perderse una carta sin receta; las recetas conocidas pueden mostrarse y resolverse directamente.

Las reglas actuales permiten jugar más de un Terreno en una fase principal. Esto posibilita las combinaciones ordenadas. No existe todavía un límite de un Terreno por turno.

### Cambio de postura

1. Pulsar una criatura propia.
2. Si el cambio es legal, mostrar `CAMBIAR A ATAQUE` o `CAMBIAR A GUARDIA` junto a ella.
3. Representar ataque en vertical y guardia en horizontal.
4. No confundir pasar a guardia con volver a ocultarse: una criatura revelada permanece boca arriba.

### Fusión

Flujo recomendado para discutir antes de implementar:

1. Pulsar una criatura propia y entrar en `MODO FUSIÓN`.
2. Resaltar únicamente segundos materiales que formen una receta válida.
3. Pulsar el segundo material.
4. Mostrar resultado, materiales contenidos, equipo compatible/incompatible y habilidad.
5. Elegir hueco resultante y postura permitida.
6. Confirmar.

Las Fusiones generadas no pertenecen a la mano ni a un mazo adicional. Los materiales quedan contenidos y consultables.

## Respuestas y prioridad

- El motor decide si existe una respuesta legal.
- La interfaz solo interrumpe cuando el jugador tiene una decisión real.
- La pregunta muestra el hecho al que responde, las cartas válidas y `PASAR`.
- Dos pases consecutivos cierran la cadena.
- Las respuestas se resuelven en orden inverso.
- Durante una respuesta no se muestran acciones ordinarias de fase principal.

## Rival automático

- El modo normal de prueba es humano contra IA básica.
- El humano conserva siempre la vista del Jugador 1.
- La IA utiliza las mismas acciones legales que una persona.
- Se detiene cuando el humano recibe una ventana de respuesta real.
- El modo local de dos personas se activa expresamente y entonces utiliza cortina de privacidad.

## Función del lateral

El lateral no es el mando principal de la partida.

Debe contener:

- ficha completa de la carta seleccionada;
- explicación de por qué una acción no es legal;
- historial legible o futuro comentalista;
- botones Guardar, Cargar y opciones;
- decisiones avanzadas que todavía no tengan interacción espacial propia.

No debe listar permanentemente todas las acciones legales ni obligar a jugar cartas desde texto.

## Información mínima siempre visible

- jugador activo;
- fase actual;
- Vida de ambos jugadores;
- Energía disponible/máxima del jugador activo;
- invocación normal disponible/usada;
- ataques disponibles de cada criatura;
- número de cartas de ambas manos y barajas;
- Cementerios;
- prioridad solo cuando exista una respuesta;
- botón principal correspondiente al momento real.

## Diferencias conscientes respecto a las referencias

- No hay movimiento ni alcance por casillas.
- El combate usa doble comparación de ATQ contra DEF.
- Cualquier criatura protege contra ataques directos.
- Magias y Trampas no consumen Energía por regla general.
- Las Fusiones son entidades generadas y conservan materiales contenidos.
- Cada jugador posee su propio Territorio.

## Decisiones de interfaz confirmadas

El diseñador confirmó el 2026-09-11 las cinco propuestas: `TERMINAR TURNO` puede saltar fases con confirmación; la Fusión se inicia seleccionando directamente sus dos criaturas; el historial comienza plegado; los equipos se muestran bajo su portador; y una receta conocida de Terreno se resuelve automáticamente mostrando el resultado, mientras una sustitución ordinaria exige confirmación.

La base visual toma de los juegos de cartas físicos conocidos únicamente claridad de organización: no copia arte, marcos, símbolos ni identidad. La elección de cualquiera de las cinco casillas es estética y no táctica.

Tras la prueba visual del diseñador se concreta además que las piezas deben leerse como cartas y no como botones: marco, zona de ilustración provisional, reverso oculto, orientación de postura y ficha ampliada. La composición utiliza una cámara casi cenital con inclinación 2,5D muy suave y líneas próximas al paralelismo; no emplea un punto de fuga profundo. La escala de cartas, casillas y zonas laterales es idéntica para ambos jugadores y las dos manos aparecen rectas y completamente visibles. El centro solo contiene la línea de separación territorial y las fases; Territorio, materiales de Fusión, Baraja y Cementerio se distribuyen en casillas laterales independientes. En Combate se pulsa primero la criatura propia y después el objetivo resaltado; fuera de Combate, pulsar prematuramente al rival conserva al atacante y conduce al control `IR A COMBATE`. El ataque directo selecciona la cabecera de Vida rival cuando no hay criaturas defensoras.

Los destinos visibles dependen del contrato de la carta. Equipo y Magia instantánea dirigida seleccionan criatura; la instantánea se resuelve y va al Cementerio. Persistentes ocupan Apoyo boca arriba y Trampas/respuestas se preparan boca abajo. No se ilumina Apoyo como destino genérico para una carta que exige portador u objetivo.
