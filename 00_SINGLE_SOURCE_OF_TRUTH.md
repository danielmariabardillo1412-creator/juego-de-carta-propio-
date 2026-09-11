# Fuente única del laboratorio

La carpeta `F:/Taller de Juegos Zapity/juego_cartas_propio/engine` es la única fuente vigente del segundo juego de cartas.

Reglas:

1. Una entrega nueva sustituye la carpeta completa anterior.
2. No se copian archivos sueltos entre builds.
3. No se mezclan B01, B02, B03, F01 ni ZIP experimentales.
4. El código de Zápiti existente es referencia externa y no forma parte del núcleo universal.
5. Los informes y cuadernos deben indicar los archivos modificados y las verificaciones realmente ejecutadas.
6. Tras cualquier corrección se repiten todas las suites, no solo la que falló.
7. Antes y después de cada fase se sigue el protocolo de `AGENTS.md` y `docs/cuadernos/README.md`.

Módulo vigente: **`0.24.0-stress-hardening`**.

Estado: **RUNTIME PASS en Godot 4.7 estable**. El ejecutable oficial portable preexistente se mantiene fuera del proyecto, en `C:/Godot/4.7`; la copia temporal redundante fue eliminada.

La baseline F05 del motor universal se conserva debajo del módulo, pero sus documentos de julio son antecedentes. El estado jugable actual y la siguiente operación autorizada se consultan en `docs/cuadernos/01_ESTADO_ACTUAL.md` y `docs/cuadernos/04_PRUEBAS_RIESGOS_Y_PENDIENTES.md`.

El corpus de diseño está inventariado en `docs/fuentes_diseno/README.md`. Sus copias locales permiten búsquedas acotadas y `SOURCE_MANIFEST.json` registra qué revisión de Drive se consultó; no sustituyen los originales editables.
