# 00_ESTADO_Y_METODO_DE_TRABAJO

> Copia local de consulta. Fuente editable: https://docs.google.com/document/d/1zj5HK8ZTlIjGlBPezB-AdAufm2VI83e-Xv_mBNZnS34/edit
> ID de Drive: `1zj5HK8ZTlIjGlBPezB-AdAufm2VI83e-Xv_mBNZnS34`  
> Revisión observada: `ANLCKQkVR2a-DVEQfcuNlWcGUeduNHxrDYY3Rav6S9OIrdMiLFgWdJaX63TJ5uWODI1wOl_OoVR_Ul82eYb7NhfTm8Go2SJaw11HuoKZTpo`  
> Modificación observada en Drive: `2026-08-06T18:13:32.228Z`  
> Sincronización local: `2026-09-08`

## Contenido original normalizado

JUEGO DE CARTAS PROPIO

ESTADO Y MÉTODO DE TRABAJO

Estado del proyecto: DISEÑO INICIAL

Fecha de apertura: 6 de agosto de 2026

1. IDENTIDAD DEL PROYECTO

Este juego se diseñará como un proyecto independiente de Zápiti.

No se desarrollará dentro del proyecto actual de Zápiti mientras este siga incompleto. El motor universal de cartas de Zápiti podrá utilizarse más adelante como base técnica, referencia o sistema compartido, pero la integración se estudiará cuando ambos proyectos tengan una estructura estable.

2. OBJETIVO DE ESTA CARPETA

Construir el juego completamente sobre papel antes de iniciar su implementación en el PC.

La carpeta debe contener, de forma progresiva:

- mecánicas básicas;

- estructura del turno;

- combate;

- recursos e invocación;

- tipos y familias de cartas;

- magia, trampas, objetos y terrenos;

- fusiones y compatibilidades;

- efectos latentes;

- clases, elementos y etiquetas;

- cartas individuales;

- nombres, estadísticas, habilidades y textos;

- mazos de prueba;

- auditorías y decisiones finales.

3. MÉTODO DE TRABAJO

Cada mecánica se discutirá por separado, comenzando por las más básicas.

Para cada tema se registrarán:

- objetivo de la mecánica;

- propuestas consideradas;

- ventajas;

- riesgos;

- contradicciones con otras reglas;

- decisión provisional;

- cuestiones pendientes;

- resultado de pruebas cuando existan.

No se dará por cerrada una regla solo porque parezca buena en una primera conversación.

4. AUDITORÍA

Cuando exista suficiente material se realizará una auditoría para:

- detectar contradicciones;

- fusionar propuestas equivalentes;

- eliminar ideas redundantes o malas;

- separar reglas básicas de contenido avanzado;

- comprobar la viabilidad técnica;

- establecer una versión consolidada del reglamento.

5. ESTADOS DE LAS DECISIONES

ABIERTO: todavía se está discutiendo.

PROVISIONAL: existe una opción preferida, pero falta probarla o compararla.

CERRADO PARA PROTOTIPO: se utilizará en la primera implementación, aunque podría cambiar tras las pruebas.

DESCARTADO: no se utilizará, salvo que aparezcan nuevos argumentos.

6. ORDEN INICIAL DE DISEÑO

1. Puntos de vida y condiciones de derrota.

2. Estadísticas de las criaturas.

3. Combate básico.

4. Tablero y zonas de cartas.

5. Mano inicial, robo y tamaño de mazo.

6. Turnos y fases.

7. Recurso y límites para jugar cartas poderosas.

8. Tipos básicos de carta.

9. Magias, trampas y objetos.

10. Terrenos y transformaciones.

11. Fusiones.

12. Efectos latentes.

13. Clases, elementos y familias.

14. Primeras cartas y mazos de prueba.

7. PRINCIPIOS YA ACEPTADOS

- No habrá cambios climáticos aleatorios.

- Todo fenómeno o transformación procederá de cartas, habilidades o consecuencias deterministas.

- No habrá tablero con casillas ni movimiento táctico.

- El juego tendrá filas de criaturas y de cartas de apoyo.

- Las fusiones serán deterministas.

- Los efectos latentes podrán ser beneficiosos, perjudiciales o de doble filo.

- El narrador explicará resultados, pero no decidirá reglas.

- La primera versión debe ser limitada y comprobable.

8. SIGUIENTE TAREA

Discutir y cerrar provisionalmente el sistema de puntos de vida y las condiciones básicas de derrota.

9. ESTRUCTURA ACTUAL DE LA CARPETA

00_ESTADO_Y_METODO_DE_TRABAJO

Documento de control: identidad, separación de Zápiti, método, auditorías y orden de diseño.

01_MECANICAS_BASICAS_EN_DISCUSION

Documento vivo donde se estudia una mecánica cada vez. Actualmente contiene vida, derrota, daño y aclaraciones recientes.

02_TABLA_PRESUPUESTO_DE_CARTAS_V0_1

Hoja de cálculo provisional para estimar estadísticas, habilidades, penalizaciones y coste de energía.

https://docs.google.com/spreadsheets/d/1_IQTmvl9pOBa3erD9jsuEA0XaJJ5y2vgDSfosndaEU8/edit

10. CRITERIO DE USO DE LA TABLA

La tabla es una herramienta de partida, no un sistema automático de equilibrio. Una carta puede cumplir el presupuesto y seguir rota por sus combinaciones, facilidad de búsqueda, protección, interacción con terreno, trampas o fusiones.

Se utilizará este ciclo:

1. calcular una primera versión;

2. comparar con cartas del mismo coste;

3. simular partidas;

4. registrar resultados;

5. modificar valores;

6. auditar el conjunto completo.

11. SIGUIENTES BLOQUES DE TRABAJO

1. Terminar de discutir puntos de vida, protección y daño.

2. Definir el flujo básico del turno.

3. Definir el recurso y los límites de invocación.

4. Definir zonas, mano inicial, robo y tamaño de mazo.

5. Solo después empezar a diseñar cartas concretas.

