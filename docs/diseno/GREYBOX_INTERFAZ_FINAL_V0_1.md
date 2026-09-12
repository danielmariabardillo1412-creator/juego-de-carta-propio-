# Greybox de interfaz final V0.1

Estado: **dirección aprobada y estándar métrico V0.2 escrito; pendiente de parser/runtime y captura real**  
Fecha: **2026-09-12**  
Fuentes consultadas: **S00, S01**, cuadernos vivos y `CUADERNO_BENCHMARK_INTERFAZ_TCG_V0_1.md`.

## Objetivo

Las pruebas humanas no se harán sobre una pantalla de diagnóstico que vaya a ser descartada después. Antes de evaluar comodidad, claridad o ritmo, la mesa debe representar razonablemente la distribución e interacción que tendrá el juego final, aunque todavía no exista arte definitivo.

Este documento no modifica reglas, acciones legales, privacidad, replay ni persistencia. Define únicamente la capa visual e interactiva de prueba.

## Qué significa «greybox final»

El greybox debe fijar desde ahora:

- posición relativa de rival, campo, mano propia y mano rival;
- cinco espacios de criatura y cinco de apoyo por jugador;
- posición de Territorio, Baraja, Cementerio y materiales de Fusión;
- posición y jerarquía de Vida y Energía;
- ubicación de la banda de fases;
- ubicación de controles de Combate y fin de turno;
- comportamiento de selección, objetivos y destinos iluminados;
- ubicación de la carta ampliada y decisiones contextuales;
- proporciones aproximadas de cartas, casillas y paneles.

Puede seguir siendo provisional:

- ilustraciones;
- fondos artísticos;
- marcos finales;
- animaciones;
- partículas;
- audio;
- tipografías finales;
- ornamentación.

La sustitución futura de placeholders por arte no debe obligar a rediseñar el flujo de juego.

## Jerarquía visual obligatoria

1. **El tablero y las cartas son protagonistas.** La mesa ocupa la mayor parte de la pantalla.
2. **La mano propia se reconoce inmediatamente** y permanece en la parte inferior; la rival, en la superior.
3. **Campo enfrentado:** apoyos y criaturas mantienen lectura espacial equivalente para ambos jugadores.
4. **HUD de jugador integrado:** Vida y Energía se leen en la cabecera de cada lado sin recurrir a un panel técnico.
5. **Fases fuera del centro jugable:** se muestran como una banda compacta de estado, no como una fila de botones que corte el tablero.
6. **Lateral secundario:** muestra carta seleccionada, explicación y decisiones excepcionales; no duplica acciones que ya se realizan sobre la mesa.
7. **Diagnóstico fuera de la lectura normal:** historial, cambio manual de vista y cortina 2P siguen disponibles, pero quedan visualmente subordinados.

## Estándar métrico V0.2

La primera validación gráfica se calibra para **1600 × 900**. No se pretende convertir esos píxeles en una regla absoluta: sirven como referencia concreta para dejar de ajustar cada elemento de forma independiente. Cuando se cierre la mesa de escritorio, otras resoluciones derivarán estas medidas de la misma unidad y, por debajo de un mínimo legible, usarán una composición responsive separada.

### Unidad y proporción de carta

- proporción base: **63:88**;
- `1 U = 72 px` a 1600 × 900;
- carta de campo en Ataque: **72 × 101 px**;
- carta en Guardia: **101 × 72 px**;
- carta de mano: **86 × 120 px**;
- preview contextual: **180 × 251 px**.

La pequeña redondez respecto a la relación matemática exacta procede únicamente de trabajar en píxeles enteros.

### Casilla de campo y cinco columnas

Una criatura debe poder girar de Ataque a Guardia sin tocar la casilla vecina. Por ello, la **envolvente de cada posición de campo es 101 × 101 px**, aunque la guía vacía conserve silueta vertical de carta.

- envolvente de casilla: **101 × 101 px**;
- separación entre columnas: **11 px**;
- altura de cada fila: **105 px**;
- núcleo de cinco columnas: `5 × 101 + 4 × 11 = 549 px`;
- zonas auxiliares: **60 × 90 px**;
- separación núcleo ↔ zona auxiliar: **16 px**;
- ancho funcional aproximado con una zona auxiliar a cada lado: **701 px**.

Esto permite Ataque/Guardia a escala idéntica para ambos jugadores y deja margen suficiente para que el tablero siga dominando a 1600 × 900.

### Mano

La mano permanece recta. La carta no se reduce en cuanto crece el número de cartas; primero se reduce la separación y después aparece solape horizontal controlado:

- 1–5 cartas: paso de **94 px**;
- 6–7 cartas: **76 px**;
- 8–9 cartas: **60 px**;
- 10 o más: **48 px**.

La altura reservada es **124 px**. Este corte no introduce todavía una reducción adicional de escala: si una prueba real demuestra que manos extremas necesitan otra etapa, se añadirá después con una regla explícita y no mediante ajustes aislados.

### HUD, fase y lateral

- cabecera de cada jugador: **33 px** de alto;
- banda de fases: **26 px** de alto;
- rail contextual de escritorio: **274 px** de ancho mínimo;
- el reparto de referencia a 1600 px reserva aproximadamente el 80 % del contenido horizontal al tablero y el resto al contexto.

El rail no es una segunda mesa. Debe contener preview, información de la selección y decisiones excepcionales; Guardar/Cargar, historial y herramientas 2P quedan subordinados.

### Orden vertical de lectura

De arriba abajo:

1. HUD rival;
2. mano rival;
3. cinco apoyos rivales;
4. cinco criaturas rivales;
5. eje/banda de fase compacta;
6. cinco criaturas propias;
7. cinco apoyos propios;
8. mano propia;
9. HUD propio.

Baraja, Cementerio, Territorio y materiales de Fusión se anclan lateralmente a las filas de campo; no crean otra columna administrativa independiente.

## Lenguaje sin arte

Una carta provisional debe seguir pareciendo una carta: silueta, marco, zona de ilustración vacía o simbólica, nombre y datos mecánicos mínimos. No se necesita producir ilustraciones para validar tamaño, lectura, objetivos o ritmo de interacción.

Las casillas vacías no deben llenar la pantalla con la palabra «VACÍA». Conservan una guía discreta y solo ganan texto fuerte cuando son un destino legal (`JUGAR AQUÍ`, `ATAQUE DIRECTO`, etc.).

Baraja, Cementerio, Fusión y Territorio se representan como zonas compactas laterales con recuento o identidad, sin convertirse en paneles administrativos.

## Gramática mínima para esta fase

Solo entra lo imprescindible para que la mesa pueda probarse; las mejoras de QoL comunitarias siguen aparcadas por JCP-DEC-043.

- carta seleccionada: borde fuerte y estado seleccionado existente;
- destino legal: contorno destacado en su propia casilla/carta;
- Ataque: vertical;
- Guardia: horizontal;
- carta oculta: reverso sin identidad;
- ataque directo: cabecera/Vida rival como destino;
- equipo: relación visible con su portador mediante la presentación ya existente;
- decisiones de postura/Fusión que no caben naturalmente en campo: overlay contextual existente.

No se añaden todavía `EFECTOS ACTIVOS`, `¿por qué no puedo?`, tooltips avanzados, contadores adicionales ni historial enriquecido.

## Flujo de interacción conservado

- carta de mano → casilla u objetivo legal;
- criatura propia en Combate → criatura rival o Vida rival cuando el ataque directo sea legal;
- dos materiales compatibles → elección de Fusión;
- decisiones obligatorias o variantes de postura → ventana contextual sobre el tablero;
- carta seleccionada → ficha ampliada en el lateral;
- `UniversalCardEngine` sigue siendo la única frontera de reglas.

## Implementación métrica actual

La rama `chatgpt/greybox-ui-v1` aplica este estándar sin tocar el motor:

- `demo/card_tile.gd` unifica campo, Guardia, mano y preview con la proporción 63:88;
- `demo/juego_cartas_table_greybox.gd` usa envolventes 101 × 101, separación de 11 px, filas de 105 px, zonas laterales 60 × 90 y mano con densidad progresiva;
- `demo/juego_cartas_table_greybox.gd` reserva un rail contextual compacto y una cabecera de 33 px;
- `demo/duel_table_backdrop_greybox.gd` mantiene una superficie casi cenital con guías discretas;
- `demo/juego_cartas_table.tscn` continúa apuntando a la capa greybox dentro de esta rama;
- el módulo de reglas y `UniversalCardEngine` no se modifican.

La existencia del código **no equivale a PASS**. Todavía debe comprobarse parser/runtime en Godot 4.7 y verse una captura real a 1600 × 900.

## Criterio para comenzar pruebas humanas

La V0.1 no se considera visualmente cerrada por compilar. Debe abrirse en Godot y revisarse con captura real. El diseñador comprobará, como mínimo:

- si el tablero domina la escena;
- si mano/campo/Baraja/Cementerio se localizan sin leer instrucciones largas;
- si una carta en Guardia cabe limpia dentro de su posición sin invadir la vecina;
- si una mano inicial de cinco cartas y una mano más densa mantienen lectura suficiente;
- si una carta seleccionada y sus destinos se entienden a primera vista;
- si el lateral acompaña en vez de dominar;
- si las fases y los controles de turno no estorban al campo;
- si la disposición parece suficientemente cercana a la futura experiencia como para que una partida humana aporte datos útiles.

Si la captura no cumple esto, se corrige el greybox antes de evaluar equilibrio, ritmo o comodidad de una partida completa.
