# Greybox de interfaz final V0.1

Estado: **aprobado como dirección de trabajo para pruebas humanas**  
Fecha: **2026-09-12**  
Fuentes consultadas: **S00, S01**, cuadernos vivos y referencias visuales aportadas por el diseñador.

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

## Lenguaje sin arte

Una carta provisional debe seguir pareciendo una carta: silueta, marco, zona de ilustración vacía o simbólica, nombre y datos mecánicos mínimos. No se necesita producir ilustraciones para validar tamaño, lectura, objetivos o ritmo de interacción.

Las casillas vacías no deben llenar la pantalla con la palabra «VACÍA». Conservan una guía discreta y solo ganan texto fuerte cuando son un destino legal (`JUGAR AQUÍ`, `ATAQUE DIRECTO`, etc.).

Baraja, Cementerio, Fusión y Territorio se representan como zonas compactas laterales con recuento o identidad, sin convertirse en paneles administrativos.

## Flujo de interacción conservado

- carta de mano → casilla u objetivo legal;
- criatura propia en Combate → criatura rival o Vida rival cuando el ataque directo sea legal;
- dos materiales compatibles → elección de Fusión;
- decisiones obligatorias o variantes de postura → ventana contextual sobre el tablero;
- carta seleccionada → ficha ampliada en el lateral;
- `UniversalCardEngine` sigue siendo la única frontera de reglas.

## Primera implementación V0.1

La primera iteración introduce una capa visual derivada de la mesa existente:

- `demo/juego_cartas_table_greybox.gd` hereda la mesa funcional y sustituye únicamente presentación;
- `demo/duel_table_backdrop_greybox.gd` reduce la cuadrícula técnica y deja guías de duelo discretas;
- `demo/juego_cartas_table.tscn` apunta a la capa greybox;
- el módulo de reglas y `UniversalCardEngine` no se modifican;
- las herramientas 2P continúan disponibles en el lateral;
- la banda de fases sube al borde superior del tablero;
- las casillas vacías dejan de mostrar «VACÍA» salvo cuando la lógica necesita anunciar un destino.

## Criterio para comenzar pruebas humanas

La V0.1 no se considera visualmente cerrada por compilar. Debe abrirse en Godot y revisarse con captura real. El diseñador comprobará, como mínimo:

- si el tablero domina la escena;
- si mano/campo/Baraja/Cementerio se localizan sin leer instrucciones largas;
- si una carta seleccionada y sus destinos se entienden a primera vista;
- si el lateral acompaña en vez de dominar;
- si las fases y los controles de turno no estorban al campo;
- si la disposición parece suficientemente cercana a la futura experiencia como para que una partida humana aporte datos útiles.

Si la captura no cumple esto, se corrige el greybox antes de evaluar equilibrio, ritmo o comodidad de una partida completa.
