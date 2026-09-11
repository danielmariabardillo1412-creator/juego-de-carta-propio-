# Plan de pruebas UCE-03

## Entorno objetivo

Godot 4.7 estable, ejecución headless.

## Regresión obligatoria

```bash
godot --headless --path . --script res://tests/run_uce_01_smoke.gd
godot --headless --path . --script res://tests/run_uce_02_cards.gd
```

Resultados esperados:

- `UCE-01 PASS: 27 checks`
- `UCE-02 PASS: 58 checks`

## Suite nueva

```bash
godot --headless --path . --script res://tests/run_uce_03_random_deal.gd
```

Resultado esperado:

- `UCE-03 PASS: 65 checks`
- exit 0
- stderr vacío
- 0 SCRIPT ERROR
- 0 errores de parser

## Cobertura principal

1. Vector conocido del RNG para semilla 1.
2. Estado RNG inmutable y reproducible.
3. Límites válidos e inválidos.
4. Shuffle conocido para semillas 1 y 44.
5. Permutación sin pérdida ni duplicación.
6. Barajado de zona sin mutar el estado original.
7. Reparto round-robin desde START y END.
8. Fallo atómico por cartas insuficientes.
9. Fallo atómico por capacidad insuficiente.
10. Rechazo de destinos duplicados o fuente usada como destino.
11. Integración con UniversalCardEngine.
12. Ocultación de manos en vistas públicas y rivales.
13. Igualdad exacta de estado para dos motores con la misma semilla.

## Regla de corrección

Ejecutar primero sin modificar. Si falla, registrar el error original y aplicar únicamente el cambio mínimo necesario. Después repetir las tres suites.
