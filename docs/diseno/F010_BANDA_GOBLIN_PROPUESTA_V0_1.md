# F010 — Banda Goblin Neutral

Estado: **integrada y verificada en el duelo**.

Fuentes:

- S01 aporta M04 y M09 con sus valores, elemento y Manipulador.
- S02 aporta el presupuesto provisional.
- S03 fija la familia Goblin y sus afinidades.
- S04 fija F010 como Formación de dos Goblins del mismo elemento.

## Receta concreta

- Identificador conceptual: F010-NEU.
- Receta no ordenada: M04 Goblin Rebuscador + M09 Goblin Pendenciero.
- Condiciones: materiales propios, visibles y físicamente distintos.
- Momento: fase principal propia.
- Coste adicional de Energía: ninguno.
- Límite propio por turno: ninguno.
- Resultado: Banda Goblin Neutral.
- Modo narrativo: Formación. Los dos cuerpos siguen siendo individuos coordinados dentro de una única entidad reglamentaria.

## Perfil propuesto del resultado

- Coste de referencia: 3.
- ATQ: 3.
- DEF: 3.
- Familia: Goblin.
- Superfamilia: Humanoide.
- Elemento: Neutral.
- Anatomía: Humanoide.
- Aptitudes: Sapiente y Manipulador.
- Propiedades derivadas: ninguna.

Habilidad propuesta:

> Una vez por turno, durante una fase principal propia, puedes pagar 1 de Energía: una criatura que controles obtiene +1 ATQ hasta el final del turno.

## Razón de diseño

- Conserva la decisión de gasto de Energía que enseña M09, pero la coordinación de la Banda permite dirigir el impulso a cualquier criatura propia.
- 3 ATQ / 3 DEF representa la suma organizada de dos Goblins modestos sin convertir la primera Formación en jefe.
- Coste 3 la deja fuera de G03 y T01, que solo alcanzan criaturas de coste 2 o menos.
- Con la tabla S02 original, 3 ATQ, 3 DEF y una habilidad menor ocupan aproximadamente el presupuesto de coste 3. La valoración posterior más prudente de DEF puede dejarla algo por encima; el requisito de dos materiales compensa provisionalmente esa diferencia.
- La bonificación no se restringe todavía a Goblins para que sea comprobable dentro del mazo generalista. Si resulta demasiado universal, la primera corrección será limitar el objetivo a Goblin o Humanoide.

## Reglas de materiales y destrucción

- M04 y M09 dejan de ocupar sus casillas y quedan contenidos en la Formación.
- La Banda ocupa una única casilla de criatura.
- Si es destruida, la entidad desaparece y ambas cartas físicas van al Cementerio.
- Los materiales no se consideran destruidos individualmente al producirse ese traslado, salvo decisión futura expresa.
- Los equipos de los materiales deben reunirse y conservarse solo si la Banda puede utilizarlos legalmente.

## Riesgos que deben medirse

1. La Banda concentra dos cartas en una entidad, liberando una casilla pero exponiendo ambos materiales a una sola retirada.
2. Manipulador permite conservar armas y escudos compatibles; esto puede elevar su poder por encima de sus cifras impresas.
3. Dos copias de las cartas base permiten formar más de una Banda durante la partida, pero la primera prueba limita provisionalmente la acción de Fusión normal a una por jugador y turno.
4. La habilidad puede acumularse con G01, G05 y otras mejoras temporales.

## Estado de implementación

F010-NEU se construye desde M04 y M09 mediante la acción común de Fusión. Ocupa una casilla, conserva ambos materiales, revalida equipo y ejecuta su habilidad de Energía una vez por turno. Destrucción y devolución aplican los destinos generales ya probados. F011 y F012 ya comparten esta infraestructura; F013 sigue fuera hasta una integración posterior controlada.
