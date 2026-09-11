# Reglas de continuidad del laboratorio

Estas instrucciones se aplican a todo el proyecto `juego_cartas_propio/engine`.

## Antes de modificar código

1. Leer `docs/cuadernos/README.md`.
2. Leer completos los cuatro cuadernos indicados allí.
3. Confirmar en `01_ESTADO_ACTUAL.md` cuál es la última fase cerrada y cuál está abierta.
4. Leer `docs/fuentes_diseno/README.md`, ejecutar `tools/check_design_source_cache.ps1` y seguir su ruta temática para la fase activa. No cargar las seis fuentes completas sin necesidad.
5. Si la fase depende de diseño, comparar en Google Drive la fecha de modificación de las fuentes seleccionadas con `docs/fuentes_diseno/SOURCE_MANIFEST.json`. Sincronizar primero cualquier fuente más reciente.
6. No tocar `C:/Users/danie/OneDrive/Documentos/zapity/active`: el juego nuevo se desarrolla aislado hasta que exista autorización expresa para integrarlo.

## Durante cada fase

- Trabajar por sistemas pequeños y verificables; no adelantar arte ni integración.
- Registrar inmediatamente una decisión que cambie reglas, contratos públicos, privacidad, persistencia o arquitectura.
- Si se descubre que un apunte anterior es falso, corregirlo y dejar constancia de la corrección en la bitácora; no conservar dos versiones contradictorias como si ambas fueran vigentes.
- Toda decisión de diseño debe citar las claves S00–S05 consultadas. Si las fuentes no fijan un dato, marcarlo como pendiente de diseño en vez de inferirlo.
- No declarar cerrada una fase con pruebas parciales.

## Antes de entregar una fase

1. Ejecutar las pruebas proporcionales al cambio y, si se modifica el módulo principal, repetir todas las suites específicas, el diagnóstico y el experimento integral.
2. Actualizar `01_ESTADO_ACTUAL.md`.
3. Añadir una entrada a `03_BITACORA_DE_TRABAJO.md`.
4. Actualizar resultados, riesgos y siguiente paso en `04_PRUEBAS_RIESGOS_Y_PENDIENTES.md`.
5. Actualizar `02_DECISIONES_Y_REGLAS.md` si cambió alguna decisión o regla.
6. Comprobar que `JUEGO_CARTAS_PROPIO.md` no contradice los cuadernos.
7. Si cambia la mesa jugable, comprobar y regenerar el acceso directo `C:/Users/danie/OneDrive/Desktop/Juego de Cartas Propio - Pruebas.lnk`; debe abrir explícitamente `res://demo/juego_cartas_table.tscn` desde este proyecto de F.
