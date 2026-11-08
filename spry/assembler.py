import re
from pathlib import Path

import isa
from preprocesador import preprocess


def _registro(token):
    match = re.fullmatch(r"\$?R([0-9]|1[0-5])", token.upper())
    if not match:
        raise ValueError(f"Registro inválido: {token}")
    return int(match.group(1))


def _numero(token):
    if token.startswith("#"):
        token = token[1:]
    return int(token, 0)


def _valor(token, etiquetas):
    return etiquetas[token.upper()] if token.upper() in etiquetas else _numero(token)


def _limpiar(linea):
    return linea.split(";", 1)[0].strip()


def _origen(texto):
    for linea in texto.splitlines():
        tokens = _limpiar(linea).split()
        if tokens and tokens[0].upper() == "ORG":
            if len(tokens) != 2:
                raise ValueError("ORG requiere una única dirección")
            return _numero(tokens[1])
    return None


def assemble(texto, base=0x200, source_dir=None):
    """Convierte mnemonics y etiquetas a palabras de 64 bits."""
    texto = preprocess(texto, base_dir=source_dir)
    lineas = [_limpiar(linea) for linea in texto.splitlines()]
    lineas = [linea for linea in lineas if linea]
    etiquetas = {}
    pc = base
    instrucciones = []
    for linea in lineas:
        if linea.upper().startswith("ORG"):
            tokens = linea.split()
            if len(tokens) != 2:
                raise ValueError("ORG requiere una única dirección")
            pc = _numero(tokens[1])
            continue
        if ":" in linea:
            etiqueta, linea = linea.split(":", 1)
            etiquetas[etiqueta.strip().upper()] = pc
            linea = linea.strip()
            if not linea:
                continue
        instrucciones.append((pc, linea))
        pc += 8

    palabras = []
    for pc, linea in instrucciones:
        linea = linea.replace(",", " ")
        tokens = linea.split()
        if not tokens:
            continue
        nombre = tokens[0].upper()
        argumentos = tokens[1:]
        if nombre == "LDP":
            nombre = "LDI"
        if nombre == ".QUAD" or nombre == ".WORD":
            if len(argumentos) != 1:
                raise ValueError(f"{nombre} requiere un operando")
            valor = _numero(argumentos[0])
            palabras.append(valor & 0xFFFFFFFFFFFFFFFF)
            continue
        if not any(datos["nombre"] == nombre for datos in isa.OPCODES.values()):
            raise ValueError(f"Opcode desconocido en 0x{pc:X}: {nombre}")
        opcode, info = next(
            (codigo, datos) for codigo, datos in isa.OPCODES.items()
            if datos["nombre"] == nombre
        )
        formato = info["formato"]
        palabra = opcode << 48
        if formato == isa.FORMATO_1_CONTROL:
            if argumentos:
                raise ValueError(f"{nombre} no acepta operandos")
        elif formato == isa.FORMATO_2_UNARIO:
            if len(argumentos) != 1:
                raise ValueError(f"{nombre} requiere un registro")
            palabra |= _registro(argumentos[0]) << 42
        elif formato == isa.FORMATO_3_TIPO_R:
            if nombre in ("FUNPACK",):
                if len(argumentos) != 1:
                    raise ValueError(f"{nombre} requiere un registro")
                rd, rs1, rs2 = 0, _registro(argumentos[0]), 0
            elif nombre in ("FSQRT", "FITOF", "MOV"):
                if len(argumentos) != 2:
                    raise ValueError(f"{nombre} requiere dos registros")
                rd, rs1, rs2 = _registro(argumentos[0]), _registro(argumentos[1]), 0
            elif nombre in ("CMP", "TEST"):
                if len(argumentos) == 2:
                    rd, rs1, rs2 = 0, _registro(argumentos[0]), _registro(argumentos[1])
                elif len(argumentos) == 3:
                    rd, rs1, rs2 = map(_registro, argumentos)
                else:
                    raise ValueError(f"{nombre} requiere dos o tres registros")
            else:
                if len(argumentos) != 3:
                    raise ValueError(f"{nombre} requiere tres registros")
                rd, rs1, rs2 = map(_registro, argumentos[:3])
            palabra |= (rd << 40) | (rs1 << 36) | (rs2 << 32)
        elif formato == isa.FORMATO_4_INMEDIATO:
            if len(argumentos) != 2:
                raise ValueError(f"{nombre} requiere registro e inmediato")
            rd = _registro(argumentos[0])
            inmediato = _valor(argumentos[1], etiquetas)
            if not -32768 <= inmediato <= 0xFFFF:
                raise ValueError(f"Inmediato fuera de 16 bits: {inmediato}")
            palabra |= (rd << 42) | ((inmediato & 0xFFFF) << 26)
        elif formato == isa.FORMATO_5_MEMORIA:
            if len(argumentos) != 2:
                raise ValueError(f"{nombre} requiere registro y dirección")
            reg = _registro(argumentos[0])
            direccion = _valor(argumentos[1].strip("[]"), etiquetas)
            palabra |= (reg << 42) | ((direccion & 0xFFF) << 30)
        elif formato == isa.FORMATO_6_SALTO:
            if len(argumentos) != 1:
                raise ValueError(f"{nombre} requiere un destino")
            destino = _valor(argumentos[0], etiquetas)
            palabra |= (destino & 0xFFF) << 32
        palabras.append(palabra)
    return palabras


def assemble_file(ruta, base=0x200):
    ruta = Path(ruta)
    texto = ruta.read_text(encoding="utf-8")
    return assemble(
        texto,
        base=base,
        source_dir=ruta.parent,
    )
