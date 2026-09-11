# F001 — Alfa de la Manada de Naturaleza

Estado: **integrada y verificada en el duelo**.

Fuentes:

- S01 aporta M01 y M07 con sus valores y habilidad.
- S02 aporta el presupuesto provisional y advierte que DEF necesita pruebas.
- S03 fija la identidad de familia Lobo.
- S04 fija F001: dos Lobos del mismo elemento producen un Lobo superior del elemento compartido.

## Receta concreta

- Identificador conceptual: F001-NAT.
- Receta no ordenada: M01 Lobo de Zarza + M07 Cachorro de la Senda Verde.
- Condiciones generales: ambos materiales deben ser propios, visibles y no representar la misma carta física.
- Momento: fase principal propia.
- Coste adicional de Energía: ninguno.
- Límite propio por turno: ninguno. Se conserva la regla general vigente; solo la disponibilidad real de materiales limita su uso.
- Resultado: Alfa de la Manada de Naturaleza.
- Modo narrativo: Integración. Los dos materiales originan un Lobo superior único; no es una Formación de varios cuerpos.

## Perfil propuesto del resultado

- Coste de referencia: 3.
- ATQ: 3.
- DEF: 2.
- Familia: Lobo.
- Superfamilia: Bestial.
- Elemento: Naturaleza.
- Anatomía: Cuadrúpedo.
- Aptitudes: Bestial.
- Propiedades derivadas: ninguna.

Habilidad propuesta:

> La primera vez en cada uno de tus turnos que otra criatura que controles declare un ataque, esa criatura obtiene +1 ATQ durante ese combate.

## Razón de diseño

- M01 aporta la presión ofensiva; M07 aporta la idea de que la pérdida de un miembro guía o llama al resto de la manada.
- El resultado gana presencia respecto a los materiales, pero no alcanza estadísticas de jefe.
- La habilidad expresa liderazgo y funciona en el mazo generalista aunque las otras criaturas todavía no sean Lobos.
- Exigir «otra criatura» evita que el Alfa sea únicamente un atacante con mejora propia y deja espacio para una futura identidad tribal más fuerte.
- La mejora solo dura ese combate y solo ocurre una vez por turno, por lo que no equivale a un bono permanente de mesa.
- Según la aproximación prudente usada en S01, 3 ATQ y 2 DEF consumen alrededor de 9 PB; queda margen aproximado para una habilidad menor. El requisito externo de dos materiales justifica que la entidad sea algo mejor que una criatura ordinaria de coste 3, pero debe comprobarse en partidas.

## Riesgos que deben medirse

1. Concentrar dos cartas en una casilla puede ser ventaja o vulnerabilidad según la frecuencia de destrucción y retirada.
2. Al destruirse el Alfa, M01 y M07 van al Cementerio como materiales contenidos. M07 no se considera destruido en ese momento y no roba una carta salvo que una regla futura lo indique expresamente.
3. La habilidad puede potenciar criaturas de cualquier familia. Si vuelve demasiado genérica la Fusión, se restringirá a Bestiales o Lobos tras probar el mazo generalista.
4. Coste 3 hace que G03 y T01, limitadas a coste 2 o menos, no retiren o destruyan directamente al Alfa.

## Estado de implementación

F001-NAT se construye desde M01 y M07 en cualquier orden mediante la acción común de Fusión. Su liderazgo concede +1 ATQ durante el primer combate del turno declarado por otra criatura propia, se consume al declarar aunque el combate sea cancelado y no mejora al propio Alfa. La suite comprueba identidad, ciclo físico, límite y efecto de combate.
