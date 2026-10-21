
; ---------------------------------------------------------------------------
; FP_UNPACK: separa una palabra binary64.
; Entrada : R0 = bits 63..0.
; Salida  : R1..R6 según la convención anterior.
; Destruye: R7..R12.
; ---------------------------------------------------------------------------
FP_UNPACK:
    LDI   R8, 0             
    LOAD  R7, [0x100]       
    AND   R1, R0, R7        
    LDI   R7, 63            
    SHR   R1, R1, R7        

    LOAD  R7, [0x108]       
    AND   R2, R0, R7        
    LDI   R7, 52            
    SHR   R2, R2, R7        

    LOAD  R7, [0x110]       
    AND   R4, R0, R7        

    LDI   R6, 0             
    CMP   R6, R2, R8        
    JZ    FP_UNPACK_EXP_ZER

    LOAD  R7, [0x108]       
    LDI   R8, 52            
    SHR   R7, R7, R8        
    CMP   R6, R2, R7        
    JZ    FP_UNPACK_EXP_MAX

    LOAD  R7, [0x118]       
    OR    R5, R4, R7        
    LOAD  R7, [0x120]       
    SUB   R3, R2, R7        
    LDI   R6, 1             
    JMP   FP_UNPACK_DONE

FP_UNPACK_EXP_ZERO:
    CMP   R6, R4, R8        
    JZ    FP_UNPACK_ZERO
    MOV   R5, R4            
    LOAD  R3, [0x130]       
    LDI   R6, 2             
    JMP   FP_UNPACK_DONE

FP_UNPACK_EXP_MAX:
    CMP   R6, R4, R8        
    JZ    FP_UNPACK_INFINIT
    LDI   R6, 4             
    LDI   R5, 0             
    JMP   FP_UNPACK_DONE

FP_UNPACK_ZERO:
    LOAD  R3, [0x130]      
    LDI   R5, 0           
    LDI   R6, 0           
    JMP   FP_UNPACK_DONE

FP_UNPACK_INFINITY:
    LDI   R3, 1024         
    LDI   R5, 0            
    LDI   R6, 3            

FP_UNPACK_DONE:
    RET                    

; ---------------------------------------------------------------------------
; FP_PACK_NORMAL: esquema de empaquetado de un resultado normalizado.
; Entrada : R1=signo, R3=E real, R5=significando de 53 bits.
; Salida  : R0=palabra binary64. Requiere redondeo round-to-nearest-even.
; ---------------------------------------------------------------------------
FP_PACK_NORMAL:
    CALL  FP_ROUND53        
    LOAD  R7, [0x120]       
    ADD   R2, R3, R7        
    LDI   R7, 52            
    SHL   R2, R2, R7        
    LOAD  R7, [0x110]       
    AND   R5, R5, R7        
    OR    R0, R2, R5        
    LDI   R7, 63            
    SHL   R1, R1, R7        
    OR    R0, R0, R1        
    RET

; ---------------------------------------------------------------------------
; FP_ADD / FP_MUL: estructura de software para las operaciones IEEE-754.
; ---------------------------------------------------------------------------
FP_ADD:
    PUSH  R0                
    MOV   R0, R1            
    CALL  FP_UNPACK         
    MOV   R9, R1            
    MOV   R10, R3           
    MOV   R11, R5           
    POP   R0                
    CALL  FP_UNPACK         

    RET

FP_MUL:
  
    RET

; ---------------------------------------------------------------------------
; FP_SQRT_HERON: sqrt(x) mediante y[n+1] = (y[n] + x/y[n]) * 0.5.
; Entrada : R0=x binary64, R2=iteraciones máximas (>0).
; Salida  : R0=aproximación binary64.
; Requiere: FP_ADD, FP_DIV y FP_MUL completos; 0.5 está en [0x128].
; ---------------------------------------------------------------------------
FP_SQRT_HERON:
    PUSH  R0                 
    CALL  FP_SQRT_INITIAL   
    MOV   R12, R0            
    POP   R0                 

FP_SQRT_LOOP:
    LDI   R7, 0              
    CMP   R6, R2, R7         
    JZ    FP_SQRT_DONE
    PUSH  R0                 
    MOV   R1, R12            
    CALL  FP_DIV             
    MOV   R9, R0             
    POP   R0                 
    MOV   R1, R12            
    MOV   R0, R1             
    MOV   R1, R9             
    CALL  FP_ADD             
    LOAD  R1, [0x128]        
    CALL  FP_MUL             
    MOV   R12, R0            
    DEC   R2                 
    JMP   FP_SQRT_LOOP

FP_SQRT_DONE:
    MOV   R0, R12            
    RET
