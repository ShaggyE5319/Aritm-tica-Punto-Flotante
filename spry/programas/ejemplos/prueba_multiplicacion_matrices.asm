JMP MAIN

MAIN:
    LDI R0, MATRIX_A
    LDI R1, MATRIX_B
    LDI R2, RESULT
    LDI R3, 0
    LDI R12, 2
ROW:
    CMP R14, R3, R12
    JZ FIN
    LDI R5, 0
COL:
    CMP R14, R5, R12
    JZ NEXT_ROW
    LDI R6, 0
    LDI R7, 0
INNER:
    CMP R14, R6, R12
    JZ STORE_RESULT
    MUL R8, R3, R12
    ADD R8, R8, R6
    MULI R8, 8
    ADD R8, R8, R0
    LOADR R9, R8, R14
    MUL R10, R6, R12
    ADD R10, R10, R5
    MULI R10, 8
    ADD R10, R10, R1
    LOADR R11, R10, R14
    MUL R9, R9, R11
    ADD R7, R7, R9
    INC R6
    JMP INNER
STORE_RESULT:
    MUL R8, R3, R12
    ADD R8, R8, R5
    MULI R8, 8
    ADD R8, R8, R2
    STORER R8, R8, R7
    INC R5
    JMP COL
NEXT_ROW:
    INC R3
    JMP ROW
FIN:
    LOAD R8, RESULT_00
    LOAD R9, RESULT_01
    LOAD R10, RESULT_10
    LOAD R11, RESULT_11
    HLT

MATRIX_A:
    .quad 1
    .quad 2
    .quad 3
    .quad 4
MATRIX_B:
    .quad 5
    .quad 6
    .quad 7
    .quad 8
RESULT:
RESULT_00:
    .quad 0
RESULT_01:
    .quad 0
RESULT_10:
    .quad 0
RESULT_11:
    .quad 0
