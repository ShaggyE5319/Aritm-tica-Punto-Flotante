JMP MAIN

MAIN:
    LDI R0, VECTOR_A
    LDI R1, VECTOR_B
    LDI R2, 4
    LDI R3, 0
    LDI R4, 0
LOOP:
    CMP R5, R3, R2
    JZ DONE
    MOV R6, R3
    MULI R6, 8
    ADD R6, R6, R0
    LOADR R7, R6, R5
    MOV R6, R3
    MULI R6, 8
    ADD R6, R6, R1
    LOADR R8, R6, R5
    MUL R7, R7, R8
    ADD R4, R4, R7
    INC R3
    JMP LOOP
DONE:
    MOV R0, R4
    HLT

VECTOR_A:
    .quad 1
    .quad 2
    .quad 3
    .quad 4
VECTOR_B:
    .quad 5
    .quad 6
    .quad 7
    .quad 8
