# Sistema de diagnóstico

## Capas

### 1. Integridad del paquete

`RUN_PACKAGE_INTEGRITY_WINDOWS.bat` ejecuta `tools/verify_manifest.ps1` y compara tamaño y SHA-256 de todos los archivos controlados por `MANIFEST.json`.

Distingue una descarga/extracción corrupta de un fallo real del motor.

### 2. Auditoría estática

`tools/static_audit.py` revisa:

- preloads y recursos de escenas;
- delimitadores y cadenas;
- indentación y espacios finales;
- JSON;
- escena principal;
- indicadores de contexto truncado;
- scripts sin `extends`;
- inferencias inseguras conocidas;
- llamadas directas a métodos inexistentes mediante aliases `preload`;
- dependencia invertida desde el núcleo hacia IA;
- declaraciones locales duplicadas adyacentes;
- presencia y ejecución en el launcher de las suites F01–F05.

No sustituye al parser de Godot.

### 3. Bootstrap mínimo

`demo/diagnostic_bootstrap.gd` carga dinámicamente el runner. Antes de hacerlo escribe `uce_bootstrap_latest.txt`. Si el runner no carga, sale con un código distinto y stderr queda capturado externamente.

### 4. Diagnóstico escalonado dentro de Godot

Etapas:

1. environment;
2. resource_scan;
3. action_envelope_isolation;
4. module_construction;
5. engine_construction;
6. engine_start;
7. initial_views;
8. external_interfaces;
9. rejected_action_atomicity;
10. complete_match;
11. state_integrity;
12. persistence;
13. replay;
14. sync;
15. determinism.

Cada etapa escribe un checkpoint. Una dependencia rota produce `SKIP`; una etapa independiente puede continuar.

Reportes:

- `res://diagnostic_logs/uce_diagnostic_latest.json`;
- `res://diagnostic_logs/uce_diagnostic_latest.txt`;
- `user://uce_diagnostics/uce_diagnostic_latest.json`;
- `user://uce_diagnostics/uce_diagnostic_latest.txt`.

### 5. Lanzador externo

`RUN_FULL_AUDIT_WINDOWS.bat` continúa después de cada fallo y conserva un log por comando. Esto captura parser errors, crashes, stderr y código de salida incluso cuando GDScript no llega a ejecutarse.

## Uso

```bat
RUN_FULL_AUDIT_WINDOWS.bat "C:\ruta\Godot_v4.7-stable_win64.exe"
```

## Interpretación

- `PASS`: la etapa se ejecutó y cumplió sus invariantes.
- `FAIL`: la etapa se ejecutó y encontró una causa concreta.
- `SKIP`: no se ejecutó porque faltaba una dependencia previa.
- ausencia de JSON + log externo con parser error: el diagnóstico interno no llegó a cargar.
