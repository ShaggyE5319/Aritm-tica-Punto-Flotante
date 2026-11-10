
import math
import struct

import isa


class CPU:
    MASK_64 = 0xFFFFFFFFFFFFFFFF
    SIGN_64 = 0x8000000000000000

    def __init__(self, memoria_ram):
        self.ram = memoria_ram
        self.regs = [0] * 16          
        self.pc = 0x200               
        self.ir = 0x0000000000000000  
        self.mar = 0x000              
        self.mdr = 0                  
        
        
        self.fr = {
            'Z': 0,  
            'N': 0,  
            'C': 0,  
            'V': 0,  
            'I': 0    
        }
        self.io_ports = {}
        self.net_queue = []
        self.halted = False

    def _guardar_resultado(self, registro, resultado, actualizar_banderas=True):
        """Guarda un resultado de 64 bits y actualiza sus banderas."""
        valor = resultado & self.MASK_64
        self.regs[registro] = valor
        if actualizar_banderas:
            self.actualizar_banderas_aritmeticas(valor)
        return valor

    def _inmediato_con_signo(self, inmediato):
        return inmediato - 0x10000 if inmediato & 0x8000 else inmediato

    def _push(self, valor):
        nuevo_sp = self.regs[13] - 8
        if nuevo_sp < 0xE00:
            raise IndexError("Stack Overflow: la pila excede el espacio reservado.")
        self.regs[13] = nuevo_sp
        self.ram.escribir_palabra_64(nuevo_sp, valor)

    def _pop(self):
        sp = self.regs[13]
        if sp > 0xFF7:
            raise IndexError("Stack Underflow: la pila está vacía.")
        valor = self.ram.leer_palabra_64(sp)
        self.regs[13] = sp + 8
        return valor

    def _valor_con_signo(self, valor):
        valor &= self.MASK_64
        return valor - (1 << 64) if valor & self.SIGN_64 else valor

    @staticmethod
    def _bits_a_float(bits):
        return struct.unpack(">d", struct.pack(">Q", bits & CPU.MASK_64))[0]

    @staticmethod
    def _float_a_bits(valor):
        return struct.unpack(">Q", struct.pack(">d", float(valor)))[0]

    def _fpu_unpack(self, bits):
        """Devuelve los campos IEEE-754 binary64 sin convertir a precisión simple."""
        bits &= self.MASK_64
        signo = (bits >> 63) & 1
        exponente = (bits >> 52) & 0x7FF
        fraccion = bits & 0x000FFFFFFFFFFFFF
        if exponente == 0:
            clase = 0 if fraccion == 0 else 2
            exponente_real = -1022
            significando = fraccion
        elif exponente == 0x7FF:
            clase = 3 if fraccion == 0 else 4
            exponente_real = 1024
            significando = 0
        else:
            clase = 1
            exponente_real = exponente - 1023
            significando = (1 << 52) | fraccion
        return signo, exponente, exponente_real, fraccion, significando, clase

    def _fpu_binary(self, nombre, a_bits, b_bits):
        a = self._bits_a_float(a_bits)
        b = self._bits_a_float(b_bits)
        if nombre == "FADD":
            resultado = a + b
        elif nombre == "FSUB":
            resultado = a - b
        elif nombre == "FMUL":
            resultado = a * b
        else:
            if b == 0.0 and a == 0.0:
                resultado = math.nan
            elif b == 0.0:
                resultado = math.copysign(math.inf, a * b)
            else:
                resultado = a / b
        return self._float_a_bits(resultado)

    def _fpu_heron(self, x_bits, iteraciones):
        x = self._bits_a_float(x_bits)
        if math.isnan(x) or x < 0.0:
            return self._float_a_bits(math.nan)
        if math.isinf(x) or x == 0.0:
            return x_bits & self.MASK_64
        y = max(x, 1.0)
        for _ in range(max(1, iteraciones)):
            y = 0.5 * (y + x / y)
        return self._float_a_bits(y)

    def _actualizar_flags_logicas(self, resultado):
        res_64 = resultado & self.MASK_64
        self.fr['Z'] = 1 if res_64 == 0 else 0
        self.fr['N'] = 1 if (res_64 & 0x8000000000000000) else 0

    def actualizar_banderas_aritmeticas(self, resultado, operando_a=None,
                                        operando_b=None, operacion=None):
        """Actualiza Z/N y, cuando aplica, C/V para una operación de 64 bits."""
        res_64 = resultado & self.MASK_64
        self._actualizar_flags_logicas(res_64)

        if operacion == "ADD":
            self.fr['C'] = 1 if operando_a + operando_b > self.MASK_64 else 0
            signos_iguales = ((operando_a ^ operando_b) & self.SIGN_64) == 0
            signo_cambio = ((operando_a ^ res_64) & self.SIGN_64) != 0
            self.fr['V'] = 1 if signos_iguales and signo_cambio else 0
        elif operacion == "SUB":
            self.fr['C'] = 1 if operando_a >= operando_b else 0
            signos_distintos = ((operando_a ^ operando_b) & self.SIGN_64) != 0
            signo_cambio = ((operando_a ^ res_64) & self.SIGN_64) != 0
            self.fr['V'] = 1 if signos_distintos and signo_cambio else 0
        elif operacion == "MUL":
            producto_unsigned = operando_a * operando_b
            producto_signed = self._valor_con_signo(operando_a) * self._valor_con_signo(operando_b)
            self.fr['C'] = 1 if producto_unsigned > self.MASK_64 else 0
            self.fr['V'] = 1 if not (-1 << 63) <= producto_signed < (1 << 63) else 0
        elif operacion in ("LOGIC", "SHIFT"):
            self.fr['C'] = 0
            self.fr['V'] = 0

    def ciclo_fetch(self):
        """Fase de búsqueda: lee de la RAM la instrucción a la que apunta el PC."""
        self.mar = self.pc
        self.mdr = self.ram.leer_palabra_64(self.mar)
        self.ir = self.mdr
        self.pc += 8  

    def decodificar_y_ejecutar(self):
        """Decodifica la instrucción actual y ejecuta la operación correspondiente."""
        campos = isa.extraer_campos(self.ir)
        nombre = campos["nombre"]
        opcode = campos["opcode"]
        
        print(f"[CPU] Ejecutando PC=0x{self.mar:X} -> {nombre} (Opcode: 0x{opcode:04X})")

        if nombre == "HLT":
            print("[CPU] ¡Instrucción HLT detectada! Deteniendo el procesador.")
            self.halted = True
            return False

        elif nombre in ("ADD", "SUB", "MUL", "DIV", "MOD", "AND", "OR", "XOR", "SHL", "SHR"):
            rd, rs1, rs2 = campos["rd"], campos["rs1"], campos["rs2"]
            val1, val2 = self.regs[rs1], self.regs[rs2]
            if nombre == "ADD": resultado = val1 + val2
            elif nombre == "SUB": resultado = val1 - val2
            elif nombre == "MUL": resultado = val1 * val2
            elif nombre == "DIV": resultado = val1 // val2
            elif nombre == "MOD": resultado = val1 % val2
            elif nombre == "AND": resultado = val1 & val2
            elif nombre == "OR": resultado = val1 | val2
            elif nombre == "XOR": resultado = val1 ^ val2
            elif nombre == "SHL": resultado = val1 << (val2 & 63)
            else: resultado = val1 >> (val2 & 63)
            valor = self._guardar_resultado(rd, resultado)
            if nombre in ("ADD", "SUB", "MUL"):
                self.actualizar_banderas_aritmeticas(
                    valor, val1, val2, nombre
                )
            elif nombre in ("AND", "OR", "XOR"):
                self.actualizar_banderas_aritmeticas(valor, operacion="LOGIC")
            elif nombre in ("SHL", "SHR"):
                self.actualizar_banderas_aritmeticas(valor, operacion="SHIFT")
            print(f"  -> R{rd} = {nombre} (0x{valor:X})")

        elif nombre in ("ADDI", "SUBI", "MULI", "ANDI", "ORI"):
            rd, inmediato = campos["rd"], campos["inmediato"]
            val1 = self.regs[rd]
            operando = self._inmediato_con_signo(inmediato) if nombre in ("ADDI", "SUBI", "MULI") else inmediato
            if nombre == "ADDI": resultado = val1 + operando
            elif nombre == "SUBI": resultado = val1 - operando
            elif nombre == "MULI": resultado = val1 * operando
            elif nombre == "ANDI": resultado = val1 & operando
            else: resultado = val1 | operando
            valor = self._guardar_resultado(rd, resultado)
            if nombre in ("ADDI", "SUBI", "MULI"):
                operacion = {"ADDI": "ADD", "SUBI": "SUB", "MULI": "MUL"}[nombre]
                self.actualizar_banderas_aritmeticas(valor, val1, operando & self.MASK_64, operacion)
            else:
                self.actualizar_banderas_aritmeticas(valor, operacion="LOGIC")
            print(f"  -> R{rd} = {nombre} {operando} = 0x{valor:X}")

        elif nombre in ("INC", "DEC"):
            registro = campos["reg"]
            val1 = self.regs[registro]
            operacion = "ADD" if nombre == "INC" else "SUB"
            operando = 1
            valor = self._guardar_resultado(registro, val1 + (1 if nombre == "INC" else -1))
            self.actualizar_banderas_aritmeticas(valor, val1, operando, operacion)
            print(f"  -> R{registro} = 0x{valor:X}")

        elif nombre == "NOT":
            registro = campos["reg"]
            valor = self._guardar_resultado(registro, ~self.regs[registro])
            self.actualizar_banderas_aritmeticas(valor, operacion="LOGIC")

        elif nombre in ("CMP", "TEST"):
            val1, val2 = self.regs[campos["rs1"]], self.regs[campos["rs2"]]
            if nombre == "CMP":
                self.actualizar_banderas_aritmeticas(val1 - val2, val1, val2, "SUB")
            else:
                self.actualizar_banderas_aritmeticas(val1 & val2, operacion="LOGIC")

        elif nombre == "MOV":
            self._guardar_resultado(campos["rd"], self.regs[campos["rs1"]], False)

        elif nombre in ("FADD", "FSUB", "FMUL", "FDIV"):
            rd, rs1, rs2 = campos["rd"], campos["rs1"], campos["rs2"]
            valor = self._fpu_binary(nombre, self.regs[rs1], self.regs[rs2])
            self.regs[rd] = valor
            print(f"  -> R{rd} = {nombre} R{rs1}, R{rs2} = 0x{valor:016X} ({self._bits_a_float(valor)!r})")

        elif nombre == "FSQRT":
            rd, rs1 = campos["rd"], campos["rs1"]
            valor = self._fpu_heron(self.regs[rs1], 12)
            self.regs[rd] = valor
            print(f"  -> R{rd} = FSQRT R{rs1} = 0x{valor:016X} ({self._bits_a_float(valor)!r})")

        elif nombre == "FHERON":
            rd, rs1, rs2 = campos["rd"], campos["rs1"], campos["rs2"]
            valor = self._fpu_heron(self.regs[rs1], self.regs[rs2] & 0xFFFF)
            self.regs[rd] = valor
            print(f"  -> R{rd} = FHERON R{rs1}, R{rs2} = 0x{valor:016X} ({self._bits_a_float(valor)!r})")

        elif nombre == "FITOF":
            rd, rs1 = campos["rd"], campos["rs1"]
            valor = self._float_a_bits(float(self.regs[rs1]))
            self.regs[rd] = valor
            print(f"  -> R{rd} = FITOF R{rs1} = 0x{valor:016X} ({self._bits_a_float(valor)!r})")

        elif nombre == "FUNPACK":
            campos_fpu = self._fpu_unpack(self.regs[campos["rs1"]])
            self.regs[1], self.regs[2], self.regs[3] = campos_fpu[0:3]
            self.regs[4], self.regs[5], self.regs[6] = campos_fpu[3:6]
            print(
                "  -> FUNPACK: "
                f"signo=R1:{self.regs[1]} exp=R2:{self.regs[2]} "
                f"E=R3:{self.regs[3]} fracción=R4:0x{self.regs[4]:013X} "
                f"significando=R5:0x{self.regs[5]:014X} clase=R6:{self.regs[6]}"
            )

        elif nombre == "LDI":
            rd, inmediato = campos["rd"], campos["inmediato"]
            self.regs[rd] = inmediato & 0xFFFFFFFFFFFFFFFF
            print(f"  -> R{rd} = LDI constante ({inmediato}) = 0x{self.regs[rd]:X}")

        elif nombre == "STORE":
            rs = campos["reg"]
            dir_mem = campos["direccion"]
            val = self.regs[rs]
            self.mar = dir_mem
            self.mdr = val
            self.ram.escribir_palabra_64(self.mar, self.mdr)
            print(f"  -> STORE: R{rs} (0x{val:X}) guardado en RAM [0x{dir_mem:X}]")

        elif nombre == "LOAD":
            rd = campos["reg"]
            dir_mem = campos["direccion"]
            self.mar = dir_mem
            val = self.ram.leer_palabra_64(self.mar)
            self.regs[rd] = val
            print(f"  -> LOAD: Dato 0x{val:X} leído de RAM [0x{dir_mem:X}] y cargado en R{rd}")

        elif nombre in ("LOADR", "STORER"):
            direccion = self.regs[campos["rs1"]] & 0xFFF
            if nombre == "LOADR":
                self.regs[campos["rd"]] = self.ram.leer_palabra_64(direccion)
            else:
                self.ram.escribir_palabra_64(direccion, self.regs[campos["rs2"]])

        elif nombre in ("PUSH", "POP"):
            registro = campos["reg"]
            if nombre == "PUSH": self._push(self.regs[registro])
            else: self.regs[registro] = self._pop()

        elif nombre in ("JMP", "JZ", "JNZ", "JG", "JL"):
            tomar_salto = (
                nombre == "JMP"
                or (nombre == "JZ" and self.fr["Z"] == 1)
                or (nombre == "JNZ" and self.fr["Z"] == 0)
                or (nombre == "JG" and self.fr["Z"] == 0 and self.fr["N"] == self.fr["V"])
                or (nombre == "JL" and self.fr["N"] != self.fr["V"])
            )
            if tomar_salto:
                self.pc = campos["direccion"]

        elif nombre == "CALL":
            self._push(self.pc)
            self.pc = campos["direccion"]

        elif nombre == "RET":
            self.pc = self._pop()

        elif nombre == "IN":
            self.regs[campos["rd"]] = self.io_ports.get(campos["inmediato"], 0)
        elif nombre == "OUT":
            self.io_ports[campos["inmediato"]] = self.regs[campos["rd"]]
            print(f"[OUT {campos['inmediato']}] 0x{self.regs[campos['rd']]:X}")
        elif nombre == "NET_SEND":
            self.net_queue.append(self.regs[campos["reg"]])
        elif nombre == "NET_RECV":
            self.regs[campos["reg"]] = self.net_queue.pop(0) if self.net_queue else 0
        elif nombre == "WAIT_IO":
            self.fr["I"] = 1 if self.io_ports or self.net_queue else 0
        elif nombre == "INT_EN":
            self.fr["I"] = 1

        else:
            print(f"[Error CPU] Instrucción '{nombre}' (Opcode 0x{opcode:04X}) no implementada todavía.")
            self.halted = True
            return False

        return True

    def ejecutar_ciclo(self):
        """Ejecuta un ciclo completo de reloj: Fetch -> Decode -> Execute."""
        if self.halted:
            return False
        try:
            self.ciclo_fetch()
            return self.decodificar_y_ejecutar()
        except (IndexError, KeyError, TypeError, ValueError, ZeroDivisionError) as e:
            print(f"[Error de Ejecución] {e}")
            self.halted = True
            return False

    def correr_automatico(self):
        """Corre el procesador en bucle automático hasta encontrar un HLT o error."""
        while not self.halted:
            activo = self.ejecutar_ciclo()
            if not activo:
                break

    def mostrar_estado(self):
        """Muestra de forma limpia el estado interno de la CPU y los registros."""
        print("\n==================================================")
        print("                 ESTADO DE LA CPU                 ")
        print("==================================================")
        print(f"PC: 0x{self.pc:03X} | IR: 0x{self.ir:016X} | Halted: {self.halted}")
        print(f"MAR: 0x{self.mar:03X} | MDR: 0x{self.mdr:016X}")
        print(f"Banderas (FR) -> Z: {self.fr['Z']} | N: {self.fr['N']} | C: {self.fr['C']} | V: {self.fr['V']} | IO: {self.fr['I']}")
        print("--- Banco de Registros ---")
        for i in range(0, 16, 4):
            print(f"R{i:2d}: 0x{self.regs[i]:016X} | R{i+1:2d}: 0x{self.regs[i+1]:016X} | R{i+2:2d}: 0x{self.regs[i+2]:016X} | R{i+3:2d}: 0x{self.regs[i+3]:016X}")
        print("==================================================")