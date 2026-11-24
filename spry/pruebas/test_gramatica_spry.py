import re
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from lexico_imperativo import analizar


GRAMATICA = ROOT / "gramatica"


def revisar_gramatica(ruta, inicio):
    texto = ruta.read_text(encoding="utf-8")
    reglas = {}
    coincidencias = list(re.finditer(
        r"(?ms)^([A-Za-z_][A-Za-z0-9_]*)\s*::=\s*(.*?)(?=^[A-Za-z_][A-Za-z0-9_]*\s*::=|\Z)",
        texto,
    ))
    for coincidencia in coincidencias:
        reglas[coincidencia.group(1)] = coincidencia.group(2).strip()

    usados = set()
    identificador = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
    for nombre, produccion in reglas.items():
        sin_terminales = re.sub(r'"[^"]*"', " ", produccion)
        usados.update(
            coincidencia.group(0)
            for coincidencia in identificador.finditer(sin_terminales)
        )

    indefinidos = sorted(usados - set(reglas))
    return reglas, indefinidos


class PruebasGramaticaSpry(unittest.TestCase):
    def test_reglas_sintacticas_completas(self):
        reglas, indefinidos = revisar_gramatica(
            GRAMATICA / "SPRY.ebnf",
            "Unidad",
        )
        self.assertIn("Unidad", reglas)
        self.assertEqual(indefinidos, [])

    def test_reglas_lexicas_completas(self):
        reglas, indefinidos = revisar_gramatica(
            GRAMATICA / "LEXICO_SPRY.ebnf",
            "UnidadLexica",
        )
        self.assertIn("UnidadLexica", reglas)
        self.assertEqual(indefinidos, [])

    def test_ejemplos_reconocidos_por_el_lexer(self):
        ejemplos = GRAMATICA / "ejemplos"
        for ruta in sorted(ejemplos.glob("*.imp")):
            if ruta.name == "lexico_invalido.imp":
                continue
            with self.subTest(ruta=ruta.name):
                tokens = analizar(ruta.read_text(encoding="utf-8"))
                self.assertGreater(len(tokens), 0)

    def test_token_direccion_inmediata(self):
        tokens = analizar("leer valor desde {35};")
        categorias = [token.categoria for token in tokens]
        self.assertIn("MEMORIA_INMEDIATA", categorias)

    def test_tokenes_nuevos(self):
        tokens = analizar('decimal x = 3.14; arreglo v[5] de entero; verdadero')
        categorias = [token.categoria for token in tokens]
        self.assertIn("TIPO", categorias)
        self.assertIn("REAL", categorias)
        self.assertIn("RESERVADA", categorias)
        self.assertIn("LITERAL_BOOLEANO", categorias)

    def test_flujo_lexico_valido_e_invalido(self):
        valido = analizar("""
            programa Ejemplo;
            entero numero = 0x23;
            mientras (numero >= 1) {
                numero = numero - 1;
            }
            leer numero desde {35};
            mostrar numero;
            // comentario válido
        """)
        self.assertTrue(valido)

        with self.assertRaises(SyntaxError):
            analizar("entero valor = 3@#;")

    def test_archivos_de_lexico(self):
        ejemplos = GRAMATICA / "ejemplos"
        valido = ejemplos / "lexico_valido.imp"
        invalido = ejemplos / "lexico_invalido.imp"

        self.assertGreater(len(analizar(valido.read_text(encoding="utf-8"))), 0)
        with self.assertRaises(SyntaxError):
            analizar(invalido.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
