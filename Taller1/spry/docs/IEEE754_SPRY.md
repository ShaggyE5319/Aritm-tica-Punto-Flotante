# IEEE-754 binary64 en Spry 1.0

Se añadieron las rutinas documentadas en [`ieee754_spry.asm`](../programas/ieee754_spry.asm).
El formato implementado es binary64:

```text
signo (1) | exponente almacenado (11, bias 1023) | fracción (52)
```

## Convención de registros

| Registro | Uso |
| --- | --- |
| `R0` | palabra binary64 de entrada/salida |
| `R1` | signo, o segundo operando según la rutina |
| `R2` | exponente almacenado / contador de iteraciones |
| `R3` | exponente real |
| `R4` | fracción de 52 bits |
| `R5` | significando de 53 bits |
| `R6` | clasificación: cero, normal, subnormal, infinito o NaN |
| `R7-R12` | temporales |
| `R13` | puntero de pila |
| `R14-R15` | reservados para temporales de bajo nivel |

## Estado actual de la ISA

El emulador actual solo define operaciones enteras (`ADD`, `SUB`, `MUL`,
`DIV`, shifts y lógica). No define instrucciones de punto flotante, ni un
ensamblador que traduzca etiquetas/mnemonics a las palabras hexadecimales que
consume el cargador. Por ello:

* `FP_UNPACK` es una rutina de bits basada en instrucciones existentes.
* `FP_PACK_NORMAL` muestra el empaquetado y el punto de integración del
  redondeo.
* `FP_ADD`, `FP_MUL` y `FP_DIV` son puntos de extensión de software. Para que
  Herón sea ejecutable deben completarse con manejo de NaN, infinitos,
  subnormales, overflow/underflow y `round-to-nearest-even`.
* `FP_SQRT_HERON` sí contiene el control iterativo y la fórmula solicitada,
  pero depende de esas tres primitivas.

## Extensión ejecutable de la CPU

La CPU ahora incorpora los opcodes binarios `0x0061` a `0x0067`:

| Instrucción | Operación |
| --- | --- |
| `FADD rd, ra, rb` | suma binary64 |
| `FSUB rd, ra, rb` | resta binary64 |
| `FMUL rd, ra, rb` | multiplicación binary64 |
| `FDIV rd, ra, rb` | división binary64 |
| `FSQRT rd, ra` | raíz por Herón, 12 iteraciones |
| `FHERON rd, ra, rc` | raíz por Herón usando `Rrc` como contador |
| `FITOF rd, ra` | convierte entero sin signo de `Rra` a binary64 |
| `FUNPACK ra` | coloca los campos en `R1..R6` |

Las operaciones guardan los bits IEEE-754 directamente en el registro destino.
Los tres casos de prueba se pueden cargar desde el menú como cualquier
programa: el cargador detecta automáticamente si el archivo contiene
hexadecimal o mnemonics. Durante la ejecución la CPU imprime cada resultado en
hexadecimal y como valor decimal Python `float` para poder verificarlo.

El archivo [`brun.asm`](../programas/brun.asm) estima la constante de Brun `B2` sumando
los pares de primos gemelos hasta `p = 1000`. Usa `MOD` para la prueba de
primalidad, `FITOF` para convertir cada primo a binary64 y `FDIV/FADD` para
la suma de recíprocos. La ejecución produce `1.5180324635595912`; este valor
es una suma truncada y, por tanto, todavía no es el límite convergente
`B2 ≈ 1.902160583104`.

Los casos ejecutables son:

1. [`brun.asm`](../programas/brun.asm): suma de recíprocos de pares de primos gemelos.
2. [`raiz_8.asm`](../programas/raiz_8.asm): `sqrt(8.0)` mediante 12 iteraciones de
   Herón; el resultado queda en `R14` y `R15`.
3. [`suma_flotante.asm`](../programas/suma_flotante.asm): `1.5 + 2.25 = 3.75`; el
   resultado queda en `R10`.

Para ejecutarlos, inicia `main.py`, elige la opción **1**, escribe el nombre
del archivo, y luego elige la opción **5**. Cada archivo termina en `HLT`, por
lo que puede ejecutarse de forma independiente después de cada carga.

Ejemplo de resultados del demo:

```text
FADD 2.0 + 8.0       = 10.0
FMUL 2.0 * 8.0       = 16.0
FHERON sqrt(8.0)     = 2.82842712474619
FUNPACK sqrt(8.0)    = signo 0, exponente 1024, clase normal
```

Para probarlo, ejecuta `main.py`, selecciona **1**, escribe
`demo_fpu.asm`, y después selecciona **5**. También se puede invocar el
`EnlazadorCargador` desde Python, como hacen las pruebas de validación.

Las direcciones `0x100` a `0x128` son una tabla de constantes y deben cargarse
como palabras de 64 bits antes de invocar las rutinas. El programa no debe
ocupar esas posiciones. La pila usa el rango alto de RAM, como establece
`CPU._push`.

La tabla también usa `0x130` para el entero con signo `-1022`
(`0xFFFFFFFFFFFFFC02`), necesario para clasificar subnormales y ceros sin
depender de un `LDI` de 16 bits.

## Importante sobre `LDI`

`LDI` solo codifica un inmediato de 16 bits. Las máscaras de 64 bits se cargan
con `LOAD` desde la tabla de constantes; intentar construirlas con un solo
`LDI` no produciría el valor IEEE-754 correcto.

## Carga en el emulador

`EnlazadorCargador` acepta únicamente una palabra hexadecimal de 64 bits por
línea. Este `.asm` es deliberadamente fuente legible y no se puede pasar
directamente a la opción **Cargar archivo binario**. Hace falta un ensamblador
que resuelva etiquetas, codifique los formatos de `isa.py` y, si se desea
ejecutar FPU real, añadir los opcodes o una biblioteca de subrutinas
enteras para `FP_ADD`, `FP_MUL` y `FP_DIV`.
