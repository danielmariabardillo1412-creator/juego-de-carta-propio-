# Entrega al agente de pruebas

Proyecto único: `Universal_Card_Engine_Lab`

Build: `systems-hardening-f05`

Esta carpeta sustituye completamente builds anteriores. No mezclar archivos.

## Ejecución

Desde la raíz:

```bat
RUN_FULL_AUDIT_WINDOWS.bat "RUTA_COMPLETA_AL_GODOT_4.7.exe"
```

## Reglas

- Verificar primero el SHA-256 del ZIP.
- Ejecutar sin modificar nada.
- Conservar el primer fallo de cada comando.
- No refactorizar ni añadir funciones.
- Corregir únicamente causas mínimas.
- Tras cualquier cambio, repetir todo el launcher.
- Devolver informe, ZIP completo corregido y lista exacta de archivos modificados.

## Cobertura del launcher

- integridad del paquete;
- auditoría estática;
- diagnóstico interno;
- UCE-01, UCE-02, UCE-03;
- F01, F02, F03, F04, F05;
- suite integral;
- escena principal.

El contador mostrado por cada suite es la autoridad. No fabricar resultados si una suite no llega a arrancar.
