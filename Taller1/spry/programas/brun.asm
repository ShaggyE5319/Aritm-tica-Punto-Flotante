
        LOAD  R2, ZERO
        LDI   R12, 10000
        LDI   R14, 3
        LDI   R15, 0

BRUN_LOOP:
        CMP   R11, R14, R12      
        JG    BRUN_DONE
        MOV   R0, R14            
        CALL  IS_PRIME
        CMP   R11, R1, R15
        JZ    BRUN_NEXT          

        MOV   R0, R14            
        ADDI  R0, 2
        CALL  IS_PRIME
        CMP   R11, R1, R15
        JZ    BRUN_NEXT          

        FITOF R5, R14            
        MOV   R0, R14
        ADDI  R0, 2
        FITOF R6, R0             
        LOAD  R9, ONE            
        FDIV  R7, R9, R5         
        FDIV  R8, R9, R6         
        FADD  R2, R2, R7         
        FADD  R2, R2, R8         

BRUN_NEXT:
        MOV   R0, R14
        ADDI  R0, 2              
        MOV   R14, R0
        JMP   BRUN_LOOP

BRUN_DONE:
        OUT   R2, 2              
        HLT

IS_PRIME:
        LDI   R1, 1              
        LDI   R3, 2               
        LDI   R7, 0               

PRIME_LOOP:
        MUL   R4, R3, R3          
        CMP   R6, R4, R0
        JG    PRIME_RETURN        
        MOD   R5, R0, R3          
        CMP   R6, R5, R7
        JZ    PRIME_COMPOSITE     
        INC   R3
        JMP   PRIME_LOOP

PRIME_COMPOSITE:
        LDI   R1, 0
PRIME_RETURN:
        RET

ZERO:
        .quad 0x0000000000000000
ONE:
        .quad 0x3FF0000000000000
