"""Analizador léxico del vocabulario propuesto para el lenguaje imperativo."""
from dataclasses import dataclass
import re


RESERVADAS = {"type", "program", "int", "float", "while", "if", "else", "write"}

_TOKEN = re.compile(
    r"(?P<ESPACIO>[ \t\r\n]+)"
    r"|(?P<COMENTARIO_LINEA>//[^\n]*)"
    r"|(?P<COMENTARIO_BLOQUE>/\*[\s\S]*?\*/)"
    r"|(?P<REAL>(?:[0-9]+\.[0-9]*|\.[0-9]+)(?:[eE][+-]?[0-9]+)?)"
    r"|(?P<ENTERO>[0-9]+)"
    r"|(?P<ID>[A-Za-z_][A-Za-z_0-9]*)"
    r"|(?P<OPERADOR>==|!=|<=|>=|[+*/=<>&!-])"
    r"|(?P<DELIMITADOR>[(){}\[\],;.])"
)


@dataclass(frozen=True)
class Token:
    categoria: str
    lexema: str
    linea: int
    columna: int


def analizar(texto):
    """Devuelve tokens con categoría y ubicación; descarta espacios/comentarios."""
    tokens = []
    pos, linea, columna = 0, 1, 1
    while pos < len(texto):
        match = _TOKEN.match(texto, pos)
        if not match:
            raise SyntaxError(f"Carácter inesperado {texto[pos]!r} en línea {linea}, columna {columna}")
        lexema = match.group()
        categoria = match.lastgroup
        if categoria not in ("ESPACIO", "COMENTARIO_LINEA", "COMENTARIO_BLOQUE"):
            if categoria == "ID" and lexema in RESERVADAS:
                categoria = "RESERVADA"
            tokens.append(Token(categoria, lexema, linea, columna))
        saltos = lexema.count("\n")
        if saltos:
            linea += saltos
            columna = len(lexema.rsplit("\n", 1)[-1]) + 1
        else:
            columna += len(lexema)
        pos = match.end()
    return tokens
