# Plan de prueba completo — F05

## Entorno objetivo

Godot 4.7 estable en Windows, ejecución desde la carpeta que contiene `project.godot`.

## Vía recomendada

```bat
RUN_FULL_AUDIT_WINDOWS.bat "C:\ruta\Godot_v4.7-stable_win64.exe"
```

El launcher no se detiene al primer fallo y guarda stdout, stderr y códigos de salida en `diagnostic_logs/`.

## Orden interno

1. Integridad del manifiesto y hashes.
2. Auditoría estática.
3. Diagnóstico por etapas.
4. `run_uce_01_smoke.gd`.
5. `run_uce_02_cards.gd`.
6. `run_uce_03_random_deal.gd`.
7. `run_uce_f01_foundations.gd`.
8. `run_uce_f02_cards_hardening.gd`.
9. `run_uce_f03_session_flow.gd`.
10. `run_uce_f04_persistence_sync.gd`.
11. `run_uce_f05_interfaces_ai.gd`.
12. `full/run_complete_engine_experiment.gd`.
13. Escena principal.

## Baseline ya conocida

```text
UCE-01 PASS: 27 checks
UCE-02 PASS: 58 checks
```

UCE-03 y F01–F05 no deben darse por aprobadas hasta ver su salida real en Godot. Cada suite imprime su contador efectivo al terminar.

## Disciplina de corrección

1. Ejecutar el ZIP intacto y conservar el fallo original.
2. Registrar versión exacta de Godot, comando, stdout, stderr y exit code.
3. Clasificar: parser, carga, contrato, lógica, persistencia, privacidad o diagnóstico.
4. Aplicar la corrección mínima.
5. Enumerar exactamente los archivos cambiados.
6. Repetir **toda** la auditoría.
7. Devolver un ZIP completo, no parches sueltos.

## Criterio de puerta

F05 solo se considera verificada cuando todas las suites y la escena principal terminan con exit 0, stderr limpio o explicado, sin `SCRIPT ERROR`, y el diagnóstico no registra etapas FAIL.
