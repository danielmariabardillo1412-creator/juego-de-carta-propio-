# Plan de pruebas UCE-02

## Entorno

- Godot 4.7 compatible.
- Ejecutar desde la raíz extraída del paquete.
- No modificar código antes de la primera ejecución.

## Comandos obligatorios

```bash
godot --headless --path . --script res://tests/run_uce_01_smoke.gd
godot --headless --path . --script res://tests/run_uce_02_cards.gd
```

En Windows, sustituir `godot` por la ruta o nombre real del ejecutable.

## Resultado esperado

```text
UCE-01 PASS: 27 checks
UCE-02 PASS: 58 checks
```

Ambos procesos deben terminar con código 0, sin `SCRIPT ERROR`, errores de parser ni mensajes en stderr atribuibles al proyecto.

## Fallo bloqueante

Cualquier fallo de UCE-01 o UCE-02 bloquea la siguiente fase. No comenzar RNG, shuffle ni reparto hasta corregir y repetir ambas suites.

## Informe requerido

Conservar:

- Comando exacto.
- Versión exacta de Godot.
- stdout completo.
- stderr completo.
- Código de salida.
- Archivos modificados, si el agente realizó alguna corrección.
