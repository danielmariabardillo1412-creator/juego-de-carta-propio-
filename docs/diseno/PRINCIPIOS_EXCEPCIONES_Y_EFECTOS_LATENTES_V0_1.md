# Principios de excepciones y efectos latentes V0.1

Estado: **dirección de diseño vigente; contenido concreto pendiente**.

Fuentes recuperadas: S00, S01, S03, S04 y la conversación original de diseño que dio lugar a esas fuentes. Este documento restaura detalles que quedaron resumidos al trasladar la conversación a Drive. No crea todavía cartas, cifras ni condiciones jugables nuevas.

## Regla por defecto y excepción expresa

Las reglas generales describen qué ocurre cuando ninguna carta, habilidad, receta o estado dispone otra cosa. No son prohibiciones que impidan diseñar excepciones futuras.

- Una excepción debe estar escrita en una carta, habilidad, receta o estado registrado.
- La excepción modifica solo aquello que declara; el resto de la regla general continúa aplicándose.
- El motor no deduce excepciones a partir del nombre, la ilustración o una interpretación libre.
- La misma combinación de condiciones produce siempre el mismo resultado.
- Las excepciones deben aparecer en las acciones legales, eventos, vistas y explicación mecánica para que puedan probarse y reproducirse.

Ejemplos futuros no vinculantes:

- Una Magia puede adaptar temporalmente un equipo incompatible y permitir que una Fusión lo conserve.
- Una Trampa puede sustituir la destrucción completa de una Fusión por su separación parcial, dejando en el campo uno de sus materiales con equipo.
- Una carta puede cambiar el destino normal de materiales, vínculos o entidades generadas.

Estos ejemplos prueban el contrato de extensibilidad; no autorizan esas cartas hasta que se diseñen y registren individualmente.

## Ciclo de vida base de una Fusión

Mientras ninguna excepción escrita lo sustituya:

- Al fusionar, la entidad generada aparece boca arriba en ataque o guardia a elección del jugador, cuenta como entrada ese turno y no puede atacar inmediatamente.
- Los materiales quedan contenidos, no están en el campo ni en el Cementerio y no pueden reutilizarse.
- El equipo compatible que el jugador conserve se vincula al resultado; el incompatible o descartado va al Cementerio.
- Si la Fusión es destruida, la entidad desaparece, sus materiales van al Cementerio y sus vínculos siguen la destrucción normal del portador.
- Si un efecto devuelve la Fusión a la mano, la entidad desaparece, sus materiales físicos vuelven a la mano y sus vínculos van al Cementerio.
- Una separación expresa es una mecánica distinta: devuelve los materiales al campo si existen casillas suficientes. Entran boca arriba, cuentan como llegados ese turno y no recuperan la acción de Fusión ya utilizada.
- Las cartas que ya llegaron al Cementerio no regresan por fusionar, devolver o separar, salvo recuperación escrita explícitamente.

## Efectos latentes

Una carta con efecto latente posee una interacción determinista adicional que se descubre mediante condiciones temáticas y mecánicas concretas. No es una tirada aleatoria ni una licencia para improvisar resultados.

Un diseño latente completo debe declarar internamente:

1. efecto normal visible;
2. pista visible de que existe una latencia;
3. condición exacta de despertar;
4. efecto despertado;
5. duración y destinos;
6. contrajuego posible;
7. información que el códice revela después del descubrimiento;
8. explicación reglamentaria y mensaje narrativo del resultado.

Antes de descubrirse, la carta puede mostrar un símbolo y una pista temática sin revelar la receta completa. Después del primer descubrimiento, el códice puede enseñar la condición exacta para que el jugador la utilice deliberadamente.

El secreto aporta sorpresa inicial, pero la carta debe seguir siendo interesante cuando la comunidad conozca la condición. La profundidad duradera procede de preparar, ocultar, provocar, impedir o explotar la interacción.

## Coherencia entre ambientación y mecánica

Un nombre, ilustración o texto destacado que prometa una reacción importante debe tener una traducción mecánica real, presente o latente. No todo texto ambiental necesita convertirse en regla: bromas, carácter, procedencia y detalles de mundo pueden ser solo ambientación cuando no prometen una capacidad jugable.

La prueba práctica es esta:

- Si el texto sugiere una acción, amenaza, memoria o transformación concreta, debe existir una mecánica coherente o una latencia diseñada.
- Si solo describe personalidad, historia o atmósfera, puede permanecer como ambientación sin efecto.
- Ninguna mecánica oculta se activa por interpretación narrativa libre; siempre depende de condiciones registradas.

## Ejemplo de diseño, no carta aprobada

«Venganza del Bosque» conserva su función de ejemplo histórico. Podría ofrecer una mejora normal y contener una pista de que el bosque responde cuando el rival lo destruye o transforma hostilmente. Su despertar podría beneficiar a Naturaleza, generar guardianes o producir una recuperación ambiental.

No se fijan todavía nombre definitivo, tipo, cifras, número de supervivientes, resultado, duración ni interacción exacta. También deberá distinguirse la agresión rival de la destrucción provocada deliberadamente por su propio controlador; una latencia de venganza puede castigar ese intento de autoactivación o favorecer al oponente.

## Alcance inicial recomendado

Los efectos latentes no se aplican a todas las cartas. La primera prueba futura debería utilizar pocas latencias y cubrir sistemas distintos —por ejemplo Terreno, destrucción y Fusión— antes de ampliar el catálogo.

El porcentaje orientativo recuperado de la conversación fue 15–25 %, pero no es una cuota cerrada. La selección dependerá de que cada latencia añada descubrimiento, contrajuego y una decisión que justifique su coste de aprendizaje y pruebas.

## Dirección futura del comentalista textual

El comentalista será una capa de texto, no una voz. Recibirá eventos y resultados ya resueltos por el motor y elegirá una frase coherente con la carta, criatura, compatibilidad, postura, efecto y contexto. Puede aportar humor y personalidad —por ejemplo, un Troll incapaz de usar un libro podría intentar comérselo—, pero la frase nunca decidirá por sí misma que el objeto se pierde ni inventará una penalización.

Cada consecuencia mecánica deberá existir primero como regla o efecto registrado. Después, el comentalista podrá disponer de varias frases para el mismo resultado sin alterar replay, privacidad ni acciones legales. Los ejemplos de libros incompatibles, protecciones improvisadas o reacciones cómicas quedan reservados como inspiración, no como cartas aprobadas.

## Transformaciones futuras de Terreno por efectos

Los Terrenos podrán cambiar no solo por jugar otro Terreno, sino también por Magias, Trampas, objetos, criaturas o efectos de Fusión expresamente diseñados. Un Bosque quemado podría convertirse en Bosque de Ceniza, Bosque Quemado u otra identidad; un Volcán combinado con un efecto adecuado podría generar una zona de Obsidiana. El nombre y resultado exactos siguen pendientes.

Estas transformaciones deberán declarar fuente, identidad de origen, condición, resultado, duración, acumulación, efecto mecánico y contrajuego. El motor no deducirá «fuego quema bosque» únicamente por afinidad o texto narrativo. Las recetas descubiertas podrán alimentar códice, efectos latentes, bonificaciones de criatura y frases del comentalista cuando se diseñe esa capa compleja.
