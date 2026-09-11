UNIVERSAL CARD ENGINE — FUENTE ÚNICA F05

NOTA: este archivo documenta la baseline histórica F05. El estado vigente del
juego propio se encuentra en docs/cuadernos/01_ESTADO_ACTUAL.md.

Build: systems-hardening-f05
Estado previo: STATIC_REVIEW_PASS / RUNTIME_UNTESTED

Esta carpeta incluye el motor completo acumulativo:
- F01 cimientos;
- F02 cartas/mazos/zonas;
- F03 jugadores/turnos/fases/puntuación;
- F04 persistencia/replay/sincronización;
- F05 interfaces/acciones legales/bots.

NO mezclar con carpetas anteriores.

Ejecutar en Windows:
RUN_FULL_AUDIT_WINDOWS.bat "RUTA_COMPLETA_AL_GODOT_4.7.exe"

Los resultados se guardan en diagnostic_logs.
El launcher continúa tras los fallos para maximizar la evidencia.
