# Especificación portable RNG — lcg31-v1

## Propósito

Generador determinista para barajado reproducible, snapshots, pruebas y replay. No es criptográficamente seguro.

## Estado serializado

```json
{
  "algorithm": "lcg31-v1",
  "state": 1,
  "draws": 0
}
```

## Constantes

- Modulus: `2147483648` (`2^31`)
- Multiplier: `1103515245`
- Increment: `12345`

## Transición

```text
next_state = (1103515245 * state + 12345) mod 2147483648
```

El valor devuelto por `next_raw()` es `next_state`. Después se incrementa `draws`.

## Vector conocido para semilla 1

```text
1103527590
377401575
662824084
1147902781
2035015474
```

## Entero acotado

Para `max_exclusive > 0`:

```text
limit = modulus - (modulus mod max_exclusive)
repetir:
    raw = next_raw()
hasta raw < limit
resultado = raw mod max_exclusive
```

## Shuffle

Fisher-Yates desde el último índice hasta el segundo:

```text
for i = count - 1 down to 1:
    j = next_int(i + 1)
    swap(values[i], values[j])
```

Semilla 1 y entrada `[a,b,c,d,e,f]` producen:

```text
[c,d,b,e,f,a]
```

Semilla 44 produce:

```text
[e,c,f,d,a,b]
```

## Restricción de seguridad

Este algoritmo no debe utilizarse como única garantía de imparcialidad en juegos con dinero, premios o adversarios no confiables. Para multijugador competitivo se añadirá posteriormente autoridad de servidor, semillas acordadas o un protocolo commit-reveal.
