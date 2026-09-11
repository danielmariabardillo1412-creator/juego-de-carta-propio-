# Plan de pruebas UCE-01

## Objetivo

Comprobar que el núcleo aplica únicamente acciones válidas, mantiene atomicidad y no filtra eventos privados.

## Entorno mínimo

- Godot 4.7, preferiblemente la misma build usada por Zápiti.
- Ejecución headless desde la raíz del proyecto.

## Comando

```bash
godot --headless --path . --script res://tests/run_uce_01_smoke.gd
```

En Windows, sustituir `godot` por la ruta o nombre real del ejecutable.

## Resultado esperado

- Exit code: 0
- stdout: `UCE-01 PASS: 27 checks`
- Sin `SCRIPT ERROR`
- Sin parser errors
- stderr vacío, salvo mensajes propios del entorno gráfico que el agente justifique como inocuos

## Si falla

Entregar sin reinterpretar ni resumir en exceso:

1. comando exacto;
2. versión exacta de Godot;
3. stdout completo;
4. stderr completo;
5. stack trace o parser error completo;
6. archivos modificados por el agente, si modificó alguno;
7. explicación separada entre hecho observado e hipótesis.

No refactorizar el proyecto ni añadir cartas, barajas o reglas para resolver esta prueba.
