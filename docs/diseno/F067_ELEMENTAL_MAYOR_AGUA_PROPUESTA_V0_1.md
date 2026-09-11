# F067 — Elemental Mayor de Agua

Estado: **integrada y verificada en el duelo**.

Fuentes:

- S01 aporta M06 y M08 con valores, habilidades y elemento Agua.
- S02 aporta el presupuesto provisional.
- S03 fija la familia Elemental.
- S04 fija F067: dos Elementales del mismo elemento producen un Elemental superior de ese elemento.

## Receta concreta

- Identificador conceptual: F067-AGU.
- Receta no ordenada: M06 Muro de Marea + M08 Oleada Errante.
- Condiciones: materiales propios, visibles y físicamente distintos.
- Momento: fase principal propia.
- Coste adicional de Energía: ninguno.
- Límite propio por turno: ninguno.
- Resultado: Elemental Mayor de Agua.
- Modo narrativo: Integración. Dos masas acuáticas forman una única manifestación Amorfa.

## Perfil propuesto del resultado

- Coste de referencia: 4.
- ATQ: 4.
- DEF: 4.
- Familia: Elemental.
- Elemento: Agua.
- Anatomía: Amorfo.
- Aptitudes adicionales: ninguna.
- Propiedades derivadas: ninguna; ser de Agua no equivale a Vapor, Niebla o Hielo.

Habilidad propuesta:

> Al comenzar el primer combate en el que participe cada turno, su controlador elige: obtiene +1 ATQ o +1 DEF durante ese combate.

## Razón de diseño

- M06 aporta resistencia reactiva y M08 presión ofensiva; el resultado puede adoptar una de las dos funciones en su primer combate de cada turno.
- La elección expresa adaptación del agua sin cambiar postura, familia o elemento.
- 4 ATQ / 4 DEF coincide con una criatura ordinaria de coste 4 ya existente, M14. La flexibilidad adicional se justifica provisionalmente por los dos materiales y debe medirse como valor real de Fusión.
- Limitar la elección al primer combate evita que ataques adicionales o cadenas futuras repitan el bono sin control.
- No requiere interacción de equipo: al ser Amorfo y no Manipulador, no puede aprovechar E01, E03 o E06.

## Reglas de materiales y destrucción

- M06 y M08 quedan contenidos y liberan sus dos casillas.
- El Elemental Mayor ocupa una única casilla.
- Al destruirse, la entidad desaparece y M06/M08 pasan al Cementerio.
- El traslado de M06 al Cementerio como material contenido no activa su habilidad de revelación, que solo funciona al ser revelado durante un ataque.
- Los equipos incompatibles de los materiales no se conservan. En esta pareja ninguno puede usar los equipos que requieren Manipulador.

## Riesgos que deben medirse

1. La elección de ATQ o DEF introduce una decisión durante combate y deberá integrarse sin romper la ventana general de respuestas.
2. DEF efectiva 5 puede producir bloqueos frecuentes bajo Lago o G04.
3. La entidad concentra dos cartas y puede ser vulnerable a retirada, pero G03 no la alcanza por tener coste 4.
4. Varias parejas de Elementales de Agua podrían satisfacer F067; la receta debe producir la misma identidad mientras no se añadan requisitos específicos.

## Estado de implementación

F067-AGU se construye desde cualquier pareja válida de Elementales de Agua del catálogo. Antes de su primer combate de cada turno, su controlador debe elegir ATQ o DEF; la decisión se ofrece tanto al atacar como al defender, se aplica solo a ese combate y precede a la ventana normal de respuestas. La suite comprueba ambas bonificaciones, ambos controladores, privacidad y continuidad hacia G06.
