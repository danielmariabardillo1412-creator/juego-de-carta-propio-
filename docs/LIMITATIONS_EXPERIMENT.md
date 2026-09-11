# Límites del experimento

Este paquete pretende responder a una pregunta concreta: “¿puede construirse de una vez una arquitectura completa que, sobre el papel, forme un motor coherente?”

## Incluido

- ciclo completo de una partida;
- determinismo;
- información oculta;
- turnos/fases/puntuación;
- reglas enchufables;
- acciones legales;
- guardado y replay;
- sincronización;
- bot básico;
- juego demostrador.

## No incluido

- transporte de red real (WebSocket/ENet/Steam);
- interfaz visual de producción;
- reloj de turnos en tiempo real;
- matchmaking y cuentas;
- editor gráfico de reglas;
- migraciones entre versiones futuras de cada juego;
- criptografía contra un servidor hostil;
- rendimiento probado con miles de cartas;
- reglas de Zápiti portadas al nuevo motor.

## Riesgo principal

El paquete completo no ha sido ejecutado todavía en Godot. Puede contener errores de parser, firmas de API de Godot incorrectas o fallos de integración. Por eso la build F05 mantiene el estado `STATIC_REVIEW_PASS / RUNTIME_UNTESTED`: la arquitectura y sus contratos se han reforzado, pero solo Godot puede certificar parser, API y comportamiento real.
