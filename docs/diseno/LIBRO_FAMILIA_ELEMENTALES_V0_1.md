# Libro de familia — Elementales V0.1

Estado: **propuesta de criaturas base para revisión**.

Procedencia:

- S01 fija los esqueletos M01–M18, sus elementos, habilidades y Manipulador.
- S03 define Elemental como familia profunda de múltiples afinidades.
- S04 fija F067–F076 y las propiedades derivadas de sus combinaciones.
- Los seis nombres base, anatomías concretas y conceptos visuales se proponen ahora; no estaban escritos previamente.

## Identidad de la familia

- Familia: Elemental.
- Afinidades principales: Fuego, Agua, Tierra, Aire, Hielo y Electricidad.
- Afinidades adicionales cuando tengan identidad propia: Luz, Oscuridad y Naturaleza.
- Anatomía variable: Amorfo, Humanoide, Alado, Serpentino o Colosal según la manifestación concreta.
- Aptitudes variables: un cuerpo elemental puede ser consciente o manipulador, pero la familia no concede automáticamente Sapiente, Manipulador o Canalizador.
- Fantasía jugable: manifestaciones puras y combinaciones deterministas que producen Vapor, Magma, Niebla, Tormenta, Permafrost y otras propiedades.
- Regla visual: cada criatura necesita silueta y comportamiento propios; no se resuelve la familia mediante el mismo cuerpo recoloreado diez veces.

## Primer núcleo de seis criaturas

Estos esqueletos no están utilizados por los libros propuestos de Lobos o Goblins.

| Clave conceptual | Nombre de trabajo | Elemento | M compatible | Anatomía y aptitudes propuestas | Valores conservados y función |
| --- | --- | --- | --- | --- | --- |
| ELM-01 | Ondina del Remanso | Agua | M02 | Humanoide; Sapiente, Manipulador | Coste 1; 1 ATQ / 2 DEF; sin habilidad. Manifestación menor y estable capaz de emplear objetos. |
| ELM-02 | Núcleo de Escoria | Fuego | M03 | Amorfo; sin aptitudes adicionales | Coste 1; 0 ATQ / 3 DEF; sin habilidad. Masa térmica compacta, defensiva y sin extremidades. |
| ELM-03 | Muro de Marea | Agua | M06 | Amorfo; sin aptitudes adicionales | Coste 1; 0 ATQ / 2 DEF; al ser revelado durante un ataque obtiene +1 DEF durante ese combate. Emboscada defensiva de agua comprimida. |
| ELM-04 | Oleada Errante | Agua | M08 | Amorfo; sin aptitudes adicionales | Coste 2; 3 ATQ / 1 DEF; sin habilidad. Corriente ofensiva que pierde cohesión tras golpear. |
| ELM-05 | Oráculo del Espejo de Agua | Agua | M12 | Humanoide; Sapiente, Manipulador, Canalizador | Coste 3; 3 ATQ / 2 DEF; al entrar boca arriba mira un apoyo rival oculto. Usa reflejos y corrientes para observar, sin convertirse automáticamente en Lector. |
| ELM-06 | Custodio del Brote | Naturaleza | Futuro | Humanoide; Sapiente, Manipulador, Canalizador | Valores pendientes. Se reserva para una futura baraja Elemental; M15 pasa al Troll Chamán del Musgo en la baraja inicial. |

## Presentación futura

- Ondina del Remanso: figura pequeña formada por agua lenta y piedras de río; manos definidas para justificar Manipulador.
- Núcleo de Escoria: esfera o montón de roca fundida solidificada, sin rostro humano obligatorio.
- Muro de Marea: lámina de agua que solo revela su volumen completo cuando recibe el ataque.
- Oleada Errante: silueta diagonal y veloz, más parecida a una corriente viva que a una persona acuática.
- Oráculo del Espejo de Agua: forma humanoide cuya superficie refleja escenas fragmentadas del campo rival.
- Custodio del Brote: cuerpo de raíces húmedas, hojas nuevas y savia luminosa; Naturaleza no equivale a Feérico ni Treant.

## Fusiones autorizadas y cobertura

| ID | Resultado existente | Materiales | Situación con este núcleo |
| --- | --- | --- | --- |
| F067 | Elemental Mayor | 2 Elementales del mismo elemento | **Disponible:** varias parejas de Agua; la primera propuesta usa M06 + M08 |
| F068 | Elemental de Vapor | Elemental de Fuego + Elemental de Agua | **Disponible conceptualmente:** M03 + cualquiera de M02/M06/M08/M12 |
| F069 | Elemental de Magma | Fuego + Tierra | Pendiente de un Elemental de Tierra |
| F070 | Elemental de Niebla | Agua + Aire | Pendiente de un Elemental de Aire |
| F071 | Elemental de Tormenta | Aire + Electricidad | Pendiente de Aire y Electricidad |
| F072 | Elemental de Mar Tormentoso | Agua + Electricidad | Pendiente de un Elemental de Electricidad |
| F073 | Elemental de Permafrost | Tierra + Hielo | Pendiente de Tierra y Hielo |
| F074 | Elemental del Eclipse | Luz + Oscuridad | Pendiente de Luz y Oscuridad |
| F075 | Elemental de Brote Profundo | Naturaleza + Agua | Pendiente de un Elemental de Naturaleza jugable |
| F076 | Elemental de Cristal Radiante | Tierra + Luz | Pendiente de Tierra y Luz |

El núcleo permite estudiar tres rutas distintas sin fabricar todas las afinidades de antemano: superior del mismo elemento, combinación de elementos opuestos para Vapor y combinación orgánica de Naturaleza/Agua.

## Recetas integradas

F067 fue la candidata inicial y ya está integrada:

- M06 — Muro de Marea.
- M08 — Oleada Errante.
- Resultado — Elemental Mayor de Agua.
- Modo: Integración amorfa.

F068 también está integrada; F075 permanece conceptual. Compartir Fuego y Agua no crea Vapor fuera de la familia Elemental: la receta exige explícitamente dos Elementales.

Desde 0.21.0, M06 aplica su defensa al revelarse por un ataque y M12 inspecciona privadamente un apoyo rival oculto al entrar boca arriba. M02, M03 y M08 permanecen sin habilidad por diseño.

## Comprobaciones de coherencia

- Los elementos y la aptitud Manipulador de cada M permanecen como en S01.
- Las anatomías Humanoide y Amorfo explican qué criaturas pueden sostener objetos.
- Canalizador se asigna únicamente a dos manifestaciones cuyo concepto usa control consciente de energía.
- Oráculo no recibe Lector: observar reflejos mágicos no implica comprender escritura.
- Ninguna propiedad derivada aparece sin la receta correspondiente.
- No se reutiliza ningún código M ya propuesto para Lobos o Goblins.
