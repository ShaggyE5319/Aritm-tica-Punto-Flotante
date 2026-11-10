
FORMATO_1_CONTROL = 1    
FORMATO_2_UNARIO = 2      
FORMATO_3_TIPO_R = 3      
FORMATO_4_INMEDIATO = 4  
FORMATO_5_MEMORIA = 5    
FORMATO_6_SALTO = 6      

OPCODES = {
    0x0011: {"nombre": "ADD", "formato": FORMATO_3_TIPO_R, "cat": "Aritmética"},
    0x0012: {"nombre": "SUB", "formato": FORMATO_3_TIPO_R, "cat": "Aritmética"},
    0x0013: {"nombre": "MUL", "formato": FORMATO_3_TIPO_R, "cat": "Aritmética"},
    0x0014: {"nombre": "DIV", "formato": FORMATO_3_TIPO_R, "cat": "Aritmética"},
    0x0015: {"nombre": "MOD", "formato": FORMATO_3_TIPO_R, "cat": "Aritmética"},
    0x0016: {"nombre": "ADDI", "formato": FORMATO_4_INMEDIATO, "cat": "Aritmética"},
    0x0017: {"nombre": "SUBI", "formato": FORMATO_4_INMEDIATO, "cat": "Aritmética"},
    0x0018: {"nombre": "MULI", "formato": FORMATO_4_INMEDIATO, "cat": "Aritmética"},
    0x0019: {"nombre": "INC", "formato": FORMATO_2_UNARIO, "cat": "Aritmética"},
    0x001A: {"nombre": "DEC", "formato": FORMATO_2_UNARIO, "cat": "Aritmética"},

    0x0021: {"nombre": "AND", "formato": FORMATO_3_TIPO_R, "cat": "Lógica"},
    0x0022: {"nombre": "OR", "formato": FORMATO_3_TIPO_R, "cat": "Lógica"},
    0x0023: {"nombre": "XOR", "formato": FORMATO_3_TIPO_R, "cat": "Lógica"},
    0x0024: {"nombre": "NOT", "formato": FORMATO_2_UNARIO, "cat": "Lógica"},
    0x0025: {"nombre": "CMP", "formato": FORMATO_3_TIPO_R, "cat": "Lógica"},
    0x0026: {"nombre": "SHL", "formato": FORMATO_3_TIPO_R, "cat": "Lógica"},
    0x0027: {"nombre": "SHR", "formato": FORMATO_3_TIPO_R, "cat": "Lógica"},
    0x0028: {"nombre": "ANDI", "formato": FORMATO_4_INMEDIATO, "cat": "Lógica"},
    0x0029: {"nombre": "ORI", "formato": FORMATO_4_INMEDIATO, "cat": "Lógica"},
    0x002A: {"nombre": "TEST", "formato": FORMATO_3_TIPO_R, "cat": "Lógica"},

    0x0031: {"nombre": "LOAD", "formato": FORMATO_5_MEMORIA, "cat": "Memoria"},
    0x0032: {"nombre": "STORE", "formato": FORMATO_5_MEMORIA, "cat": "Memoria"},
    0x0033: {"nombre": "MOV", "formato": FORMATO_3_TIPO_R, "cat": "Memoria"},
    0x0034: {"nombre": "LOADR", "formato": FORMATO_3_TIPO_R, "cat": "Memoria"},
    0x0035: {"nombre": "STORER", "formato": FORMATO_3_TIPO_R, "cat": "Memoria"},
    0x0036: {"nombre": "PUSH", "formato": FORMATO_2_UNARIO, "cat": "Memoria"},
    0x0037: {"nombre": "POP", "formato": FORMATO_2_UNARIO, "cat": "Memoria"},
    0x0038: {"nombre": "LDI", "formato": FORMATO_4_INMEDIATO, "cat": "Memoria"},

    0x0041: {"nombre": "JMP", "formato": FORMATO_6_SALTO, "cat": "Control"},
    0x0042: {"nombre": "JZ", "formato": FORMATO_6_SALTO, "cat": "Control"},
    0x0043: {"nombre": "JNZ", "formato": FORMATO_6_SALTO, "cat": "Control"},
    0x0044: {"nombre": "JG", "formato": FORMATO_6_SALTO, "cat": "Control"},
    0x0045: {"nombre": "JL", "formato": FORMATO_6_SALTO, "cat": "Control"},
    0x0046: {"nombre": "CALL", "formato": FORMATO_6_SALTO, "cat": "Control"},
    0x0047: {"nombre": "RET", "formato": FORMATO_1_CONTROL, "cat": "Control"},
    0x1200: {"nombre": "HLT", "formato": FORMATO_1_CONTROL, "cat": "Control"},

    0x0051: {"nombre": "IN", "formato": FORMATO_4_INMEDIATO, "cat": "E/S"},
    0x0052: {"nombre": "OUT", "formato": FORMATO_4_INMEDIATO, "cat": "E/S"},
    0x0053: {"nombre": "NET_SEND", "formato": FORMATO_2_UNARIO, "cat": "E/S"},
    0x0054: {"nombre": "NET_RECV", "formato": FORMATO_2_UNARIO, "cat": "E/S"},
    0x0055: {"nombre": "WAIT_IO", "formato": FORMATO_1_CONTROL, "cat": "E/S"},
    0x0056: {"nombre": "INT_EN", "formato": FORMATO_1_CONTROL, "cat": "E/S"}
    ,
    0x0061: {"nombre": "FADD", "formato": FORMATO_3_TIPO_R, "cat": "FPU"},
    0x0062: {"nombre": "FSUB", "formato": FORMATO_3_TIPO_R, "cat": "FPU"},
    0x0063: {"nombre": "FMUL", "formato": FORMATO_3_TIPO_R, "cat": "FPU"},
    0x0064: {"nombre": "FDIV", "formato": FORMATO_3_TIPO_R, "cat": "FPU"},
    0x0065: {"nombre": "FSQRT", "formato": FORMATO_3_TIPO_R, "cat": "FPU"},
    0x0066: {"nombre": "FUNPACK", "formato": FORMATO_3_TIPO_R, "cat": "FPU"},
    0x0067: {"nombre": "FHERON", "formato": FORMATO_3_TIPO_R, "cat": "FPU"},
    0x0068: {"nombre": "FITOF", "formato": FORMATO_3_TIPO_R, "cat": "FPU"}
}

def extraer_campos(instruccion_64):
    """
    Decodifica una instrucción de 64 bits extrayendo el Opcode y los campos 
    comunes según los desplazamientos de bits definidos en la arquitectura.
    """
    opcode = (instruccion_64 >> 48) & 0xFFFF
    info = OPCODES.get(opcode, {"nombre": "DESCONOCIDO", "formato": 0, "cat": "Desconocida"})
    
    campos = {"opcode": opcode, "nombre": info["nombre"], "formato": info["formato"], "cat": info["cat"]}
    
    fmt = info["formato"]
    
    if fmt == FORMATO_2_UNARIO: 
        campos["modo"] = (instruccion_64 >> 46) & 0x3
        campos["reg"] = (instruccion_64 >> 42) & 0xF
        
    elif fmt == FORMATO_3_TIPO_R:
        campos["modos"] = (instruccion_64 >> 44) & 0xF
        campos["rd"] = (instruccion_64 >> 40) & 0xF
        campos["rs1"] = (instruccion_64 >> 36) & 0xF
        campos["rs2"] = (instruccion_64 >> 32) & 0xF
        
    elif fmt == FORMATO_4_INMEDIATO: 
        campos["modo"] = (instruccion_64 >> 46) & 0x3
        campos["rd"] = (instruccion_64 >> 42) & 0xF
        campos["inmediato"] = (instruccion_64 >> 26) & 0xFFFF
        
    elif fmt == FORMATO_5_MEMORIA:
        campos["modo"] = (instruccion_64 >> 46) & 0x3
        campos["reg"] = (instruccion_64 >> 42) & 0xF
        campos["direccion"] = (instruccion_64 >> 30) & 0xFFF
        
    elif fmt == FORMATO_6_SALTO: 
        campos["condicion"] = (instruccion_64 >> 44) & 0xF
        campos["direccion"] = (instruccion_64 >> 32) & 0xFFF
        
    return campos