JMP MAIN
#include "../../librerias/listas.asm"

MAIN:
    LDI R0, DATOS
    LDI R1, 8
    LDI R2, TEMP
    CALL VEC_MERGE_SORT
    HLT

DATOS:
    .quad 9
    .quad 2
    .quad 7
    .quad 1
    .quad 8
    .quad 3
    .quad 6
    .quad 4
TEMP:
    .quad 0
    .quad 0
    .quad 0
    .quad 0
    .quad 0
    .quad 0
    .quad 0
    .quad 0
