; Libreria de matrices para SPRY.
; Las matrices usan almacenamiento row-major de palabras de 64 bits.
; Convencion general: R0 base, R1 filas, R2 columnas.
; Las rutinas documentan entradas, salidas y registros temporales.

MAT_FILL:
    MOV R4, R3
    MUL R3, R1, R2
    MOV R1, R3
    MOV R2, R4
    JMP VEC_FILL

MAT_SUM:
    MUL R3, R1, R2
    MOV R1, R3
    JMP VEC_SUM

MAT_TRANSPOSE:
    ; R0 origen, R1 filas, R2 columnas, R3 destino.
    LDI R4, 0
    LDI R5, 0
    LDI R6, 8
MAT_TRANSPOSE_ROW:
    CMP R7, R4, R1
    JZ MAT_TRANSPOSE_DONE
    LDI R8, 0
MAT_TRANSPOSE_COL:
    CMP R9, R8, R2
    JZ MAT_TRANSPOSE_NEXT_ROW
    MUL R10, R4, R2
    ADD R10, R10, R8
    MULI R10, 8
    ADD R10, R10, R0
    LOADR R11, R10, R7
    MUL R12, R8, R1
    ADD R12, R12, R4
    MULI R12, 8
    ADD R12, R12, R3
    STORER R11, R12, R11
    INC R8
    JMP MAT_TRANSPOSE_COL
MAT_TRANSPOSE_NEXT_ROW:
    INC R4
    JMP MAT_TRANSPOSE_ROW
MAT_TRANSPOSE_DONE:
    RET
