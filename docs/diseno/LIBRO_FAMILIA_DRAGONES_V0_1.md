# Libro de familia — Dragones V0.1

Estado: **familia semilla incluida en la baraja inicial de fantasía generalista**.

## Identidad

- Familia: Dragón.
- Superfamilia: Dracónico.
- Afinidad de la primera rama: Fuego.
- Fantasía jugable: amenazas tardías de gran presencia y Fusiones dracónicas excepcionales.
- M17 es Cuadrúpedo/Alado y no Manipulador.
- M18 es Sapiente, Alado y Manipulador gracias a sus garras delanteras prensiles.

## Núcleo inicial

| ID | Nombre | Elemento | Función |
| --- | --- | --- | --- |
| M17 | Dragón de la Caldera | Fuego | Atacante final puramente físico. |
| M18 | Dragón Rojo de las Dos Coronas | Fuego | Jefe resistente capaz de obtener un segundo ataque. |

## Fusiones de S04

- F005 — Dragón Bicéfalo Elemental: dos Dragones del mismo elemento. Disponible como F005-FUE con M17 + M18.
- F006 — Dragón de la Tormenta Carmesí: Fuego + Aire. Pendiente.
- F007 — Dragón de la Marea Glacial: Agua + Hielo. Pendiente.
- F008 — Dragón del Eclipse: Luz + Oscuridad. Pendiente.
- F009 — Dragón de la Cordillera Celeste: Tierra + Aire. Pendiente.

Los cinco nombres de Fusión proceden del libro antiguo S04 y se conservan. Los nombres M17 y M18 son propuestas nuevas.

## Corte runtime F005 — 0.20.0

M17 + M18 forman Dragón Bicéfalo Elemental de Fuego, coste de referencia 8, 8/8. Una vez por turno global, destruir en combate y sobrevivir concede un ataque adicional para ese mismo turno. Se consume al declarar aunque se cancele; T06 puede destruir al dragón antes de que vuelva a atacar.

Perfil provisional explícito de esta entidad: Dracónico, Alado y Bestial, sin Manipulador. No se heredan automáticamente las garras prensiles ni las aptitudes de M18. S04 no fija ese detalle corporal; la identidad visual definitiva queda pendiente (JCP-DEC-031).

Desde 0.21.0, M18 ejecuta de forma independiente su propio ataque adicional tras destruir en combate y sobrevivir. Comparte la semántica de consumo con F005, pero la Fusión no hereda la habilidad de la carta portadora. M17 permanece sin habilidad por diseño.
