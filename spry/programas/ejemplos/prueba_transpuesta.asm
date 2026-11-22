JMP MAIN
#include "../../librerias/matrices.asm"
#include "../../librerias/listas.asm"

MAIN:
    LDI R0, ORIGEN
    LDI R1, 2
    LDI R2, 3
    LDI R3, DESTINO
    CALL MAT_TRANSPOSE
    LOAD R8, DESTINO_0
    LOAD R9, DESTINO_1
    LOAD R10, DESTINO_2
    LOAD R11, DESTINO_3
    LOAD R12, DESTINO_4
    LOAD R14, DESTINO_5
    HLT

ORIGEN:
    .quad 1
    .quad 2
    .quad 3
    .quad 4
    .quad 5
    .quad 6
DESTINO:
DESTINO_0:
    .quad 0
DESTINO_1:
    .quad 0
DESTINO_2:
    .quad 0
DESTINO_3:
    .quad 0
DESTINO_4:
    .quad 0
DESTINO_5:
    .quad 0
