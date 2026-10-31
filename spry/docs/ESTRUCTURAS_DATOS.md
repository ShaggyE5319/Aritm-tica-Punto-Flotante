# Librería de estructuras de datos SPRY

## Análisis

La ISA de SPRY trabaja con palabras de 64 bits y direccionamiento por byte.
Por ello, una lista se representa como un bloque contiguo de palabras y una
matriz se representa en orden por filas (*row-major*). El sistema no tiene
asignador dinámico: el programa cliente reserva las direcciones de memoria y
entrega la dirección base a la librería.

El preprocesador existente resuelve `#include` relativos al archivo que los
contiene y el ensamblador procesa las etiquetas después de expandir los
includes. La librería aprovecha ese mecanismo sin modificarlo ni alterar el
orden de las instrucciones del cliente.

## Diseño

Los archivos están en [`../librerias/`](../librerias/):

- [`listas.asm`](../librerias/listas.asm): operaciones sobre arreglos lineales.
- [`matrices.asm`](../librerias/matrices.asm): operaciones sobre matrices
  row-major.
- [`estructuras.h`](../librerias/estructuras.h): constantes compartidas.

Las rutinas usan `CALL` y `RET`. `R13` queda reservado para la pila. Los
registros `R7` a `R12` son temporales de las librerías. Las rutinas pueden
modificar `R1` y otros registros temporales; el programa cliente debe guardar
los valores que necesite conservar.

### API de listas

| Rutina | Entradas | Salida | Descripción |
| --- | --- | --- | --- |
| `VEC_SUM` | `R0=base`, `R1=longitud` | `R0=sum` | Suma las palabras del vector. |
| `VEC_FILL` | `R0=base`, `R1=longitud`, `R2=valor` | memoria | Llena el vector con un valor. |
| `VEC_COPY` | `R0=origen`, `R1=longitud`, `R2=destino` | memoria | Copia un vector. |
| `VEC_MERGE_SORT` | `R0=origen`, `R1=longitud`, `R2=buffer` | `R0=base ordenada` | Ordena ascendentemente mediante mezclas. |

### API de matrices

| Rutina | Entradas | Salida | Descripción |
| --- | --- | --- | --- |
| `MAT_FILL` | `R0=base`, `R1=filas`, `R2=columnas`, `R3=valor` | memoria | Llena la matriz. |
| `MAT_SUM` | `R0=base`, `R1=filas`, `R2=columnas` | `R0=sum` | Suma todos sus elementos. |
| `MAT_TRANSPOSE` | `R0=origen`, `R1=filas`, `R2=columnas`, `R3=destino` | memoria | Escribe la transpuesta. |

`MAT_FILL` reutiliza `VEC_FILL` y `MAT_SUM` reutiliza `VEC_SUM`; así se
mantiene una única implementación para el recorrido lineal. La transpuesta
calcula las posiciones con `((fila * columnas) + columna) * 8` y
`((columna * filas) + fila) * 8`.

## Implementación e inclusión

El archivo cliente debe saltar primero a su punto de entrada, incluir las
librerías y definir después la etiqueta `MAIN`:

```asm
JMP MAIN
#include "../../librerias/estructuras.h"
#include "../../librerias/listas.asm"
#include "../../librerias/matrices.asm"

MAIN:
    ; programa cliente
```

El salto inicial es necesario porque `#include` es inclusión textual: las
rutinas quedan en el mismo programa y no se ejecutan automáticamente antes de
`MAIN`. Las etiquetas tienen prefijos `VEC_` y `MAT_` para reducir colisiones
con las etiquetas del cliente.

Para probar el ejemplo:

```text
python -c "from assembler import assemble_file; print(len(assemble_file('programas/ejemplos/estructuras_datos.asm')))"
```

También se puede cargar [`estructuras_datos.asm`](../programas/ejemplos/estructuras_datos.asm)
con el cargador habitual. La librería solo añade código cuando el cliente la
incluye; los programas existentes no cambian.

## Pruebas de funcionamiento

Las pruebas ejecutables están en [`../pruebas/test_estructuras.py`](../pruebas/test_estructuras.py)
y cargan los programas mediante el mismo `EnlazadorCargador` y `CPU` del sistema:

1. [`prueba_mezcla.asm`](../programas/ejemplos/prueba_mezcla.asm): ordena
   `[9, 2, 7, 1, 8, 3, 6, 4]` y verifica
   `[1, 2, 3, 4, 6, 7, 8, 9]`.
2. [`prueba_producto_punto.asm`](../programas/ejemplos/prueba_producto_punto.asm):
   calcula `1*5 + 2*6 + 3*7 + 4*8 = 70`.
3. [`prueba_multiplicacion_matrices.asm`](../programas/ejemplos/prueba_multiplicacion_matrices.asm):
   multiplica dos matrices `2x2` y verifica `[19, 22, 43, 50]`.
4. [`prueba_transpuesta.asm`](../programas/ejemplos/prueba_transpuesta.asm):
   transforma `[[1,2,3],[4,5,6]]` en `[[1,4],[2,5],[3,6]]`.

Desde la raíz del repositorio se ejecutan con:

```text
python -m unittest spry.pruebas.test_estructuras -v
```

La prueba de mezcla usa `VEC_MERGE_SORT`; las otras tres validan problemas
independientes sobre vectores y matrices sin cambiar los programas existentes.
