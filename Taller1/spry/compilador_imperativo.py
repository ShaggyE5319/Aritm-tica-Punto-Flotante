"""Compilador educativo de un lenguaje imperativo pequeño a ensamblador SPRY."""
import argparse
from pathlib import Path

from lexico_imperativo import analizar


class Compilador:
    def __init__(self, texto):
        self.tokens = [t.lexema for t in analizar(texto)]
        self.i = 0
        self.vars = {}
        self.asm = []
        self.label_id = 0

    def peek(self):
        return self.tokens[self.i] if self.i < len(self.tokens) else None

    def take(self, esperado=None):
        t = self.peek()
        if t is None or (esperado is not None and t != esperado):
            raise SyntaxError(f"Se esperaba {esperado or 'un token'}, se encontró {t or 'fin del archivo'}")
        self.i += 1
        return t

    def label(self, prefijo):
        self.label_id += 1
        return f"{prefijo}_{self.label_id}"

    def reg(self, nombre):
        if nombre not in self.vars:
            raise SyntaxError(f"Variable no declarada: {nombre}")
        return self.vars[nombre]

    def valor(self):
        t = self.take()
        if t.isdigit():
            return ("inmediato", int(t, 10))
        return ("registro", self.reg(t))

    def bloque(self):
        self.take("{")
        while self.peek() != "}":
            if self.peek() is None:
                raise SyntaxError("Bloque sin llave de cierre")
            self.sentencia()
        self.take("}")

    def sentencia(self):
        palabra = self.take()
        if palabra == "int":
            nombre = self.take()
            if not (nombre[0].isalpha() or nombre[0] == "_") or nombre in self.vars:
                raise SyntaxError(f"Nombre de variable inválido o repetido: {nombre}")
            if len(self.vars) >= 10:
                raise SyntaxError("El programa puede declarar hasta 10 variables")
            reg = f"R{len(self.vars) + 1}"
            self.vars[nombre] = reg
            self.take("=")
            tipo, valor = self.valor()
            self.asm.append(f"LDI {reg}, {valor}" if tipo == "inmediato" else f"MOV {reg}, {valor}")
            self.take(";")
        elif palabra == "write":
            tipo, valor = self.valor()
            if tipo == "inmediato":
                self.asm.append(f"LDI R15, {valor}")
                valor = "R15"
            self.asm.append(f"OUT {valor}, 2")
            self.take(";")
        elif palabra == "while":
            inicio, fin = self.label("WHILE"), self.label("END_WHILE")
            self.asm.append(f"{inicio}:")
            self.condicion(fin)
            self.bloque()
            self.asm.extend((f"JMP {inicio}", f"{fin}:"))
        elif palabra == "if":
            fin, alterno = self.label("END_IF"), None
            self.condicion(fin)
            self.bloque()
            if self.peek() == "else":
                alterno = self.label("ELSE")
                self.asm.append(f"JMP {alterno}")
                self.asm.append(f"{fin}:")
                self.take("else")
                self.bloque()
                self.asm.append(f"{alterno}:")
            else:
                self.asm.append(f"{fin}:")
        elif palabra in self.vars:
            destino = self.vars[palabra]
            self.take("=")
            tipo, lhs = self.valor()
            if self.peek() in ("+", "-", "*", "/"):
                op = self.take()
                rhs_tipo, rhs = self.valor()
                self.asm.append(f"MOV R14, {lhs}" if tipo == "registro" else f"LDI R14, {lhs}")
                if rhs_tipo == "inmediato" and op in ("+", "-", "*"):
                    mnemonic = {"+": "ADDI", "-": "SUBI", "*": "MULI"}[op]
                    self.asm.append(f"{mnemonic} R14, {rhs}")
                else:
                    self.asm.append(f"LDI R15, {rhs}" if rhs_tipo == "inmediato" else f"MOV R15, {rhs}")
                    mnemonic = {"+": "ADD", "-": "SUB", "*": "MUL", "/": "DIV"}[op]
                    self.asm.append(f"{mnemonic} R14, R14, R15")
                self.asm.append(f"MOV {destino}, R14")
            else:
                self.asm.append(f"MOV {destino}, {lhs}" if tipo == "registro" else f"LDI {destino}, {lhs}")
            self.take(";")
        else:
            raise SyntaxError(f"Instrucción desconocida: {palabra}")

    def condicion(self, destino_falso):
        tipo_a, a = self.valor()
        op = self.take()
        if op not in ("==", "!=", "<", ">", "<=", ">="):
            raise SyntaxError(f"Operador de comparación inválido: {op}")
        tipo_b, b = self.valor()
        self.asm.append(f"LDI R14, {a}" if tipo_a == "inmediato" else f"MOV R14, {a}")
        self.asm.append(f"LDI R15, {b}" if tipo_b == "inmediato" else f"MOV R15, {b}")
        self.asm.append("CMP R11, R14, R15")
        verdadero = self.label("COND_TRUE")
        saltos_verdaderos = {
            "==": ("JZ",), "!=": ("JNZ",), "<": ("JL",), ">": ("JG",),
            "<=": ("JL", "JZ"), ">=": ("JG", "JZ"),
        }[op]
        self.asm.extend(f"{salto} {verdadero}" for salto in saltos_verdaderos)
        self.asm.extend((f"JMP {destino_falso}", f"{verdadero}:"))

    def compilar(self):
        while self.peek() is not None:
            self.sentencia()
        self.asm.append("HLT")
        return "\n".join(self.asm) + "\n"


def main():
    parser = argparse.ArgumentParser(description="Compila el lenguaje imperativo SPRY a ensamblador")
    parser.add_argument("fuente", type=Path, help="Archivo .imp de entrada")
    parser.add_argument("-o", "--salida", type=Path, help="Archivo .asm de salida")
    args = parser.parse_args()
    salida = args.salida or args.fuente.with_suffix(".asm")
    try:
        ensamblador = Compilador(args.fuente.read_text(encoding="utf-8")).compilar()
        salida.write_text(ensamblador, encoding="utf-8")
    except (OSError, SyntaxError, ValueError) as error:
        parser.error(str(error))
    print(f"Ensamblador SPRY generado: {salida}")


if __name__ == "__main__":
    main()
