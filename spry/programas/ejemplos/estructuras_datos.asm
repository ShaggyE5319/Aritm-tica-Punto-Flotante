; Ejemplo de inclusion y uso de las librerias de listas y matrices.
; Las rutinas se incluyen despues del salto inicial para no ejecutarlas
; durante el arranque del programa.
JMP MAIN
#include "../../librerias/estructuras.h"
#include "../../librerias/listas.asm"
#include "../../librerias/matrices.asm"

MAIN:
    LDI R0, 0xC00
    LDI R1, 4
    LDI R2, 7
    CALL VEC_FILL
    CALL VEC_SUM
    OUT R0, 2
    HLT
