import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
COMPILADOR = ROOT / "compilador"
EJEMPLOS = ROOT / "gramatica" / "ejemplos"


@unittest.skipUnless(
    shutil.which("flex") and shutil.which("gcc"),
    "Se requiere flex y gcc para probar el lexer FLEX",
)
class PruebasLexerFlexSpry(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmpdir = tempfile.TemporaryDirectory()
        cls.build = Path(cls.tmpdir.name)
        cls.lex_c = cls.build / "lex.spry.c"
        cls.binario = cls.build / "spry_lexer"

        subprocess.run(
            ["flex", "-o", str(cls.lex_c), str(COMPILADOR / "spry.l")],
            check=True,
        )
        subprocess.run(
            [
                "gcc", "-std=c11", "-Wall", "-Wextra",
                "-DSPRY_STANDALONE", "-I", str(COMPILADOR),
                "-o", str(cls.binario),
                str(cls.lex_c), str(COMPILADOR / "lexer_test.c"),
            ],
            check=True,
        )

    @classmethod
    def tearDownClass(cls):
        cls.tmpdir.cleanup()

    def tokenizar(self, codigo):
        proc = subprocess.run(
            [str(self.binario)],
            input=codigo,
            text=True,
            capture_output=True,
        )
        tokens = [tuple(linea.split("\t")) for linea in proc.stdout.splitlines()]
        return proc.returncode, tokens, proc.stderr

    def test_ejemplos_validos_e_invalido(self):
        for ruta in sorted(EJEMPLOS.glob("*.imp")):
            proc = subprocess.run(
                [str(self.binario), str(ruta)],
                text=True,
                capture_output=True,
            )
            if ruta.name == "lexico_invalido.imp":
                self.assertNotEqual(proc.returncode, 0)
            else:
                self.assertEqual(proc.returncode, 0, proc.stderr)
                self.assertGreater(len(proc.stdout.splitlines()), 0)

    def test_operadores_y_prefijos_identificador(self):
        rc, tokens, err = self.tokenizar(
            "entero entero_x = a-1 + b&c | d^e; programa1 += 2;"
        )
        self.assertEqual(rc, 0, err)
        self.assertEqual(
            [t[1] for t in tokens],
            [
                "TIPO_ENTERO", "IDENTIFICADOR", "OP_ASIGNACION",
                "IDENTIFICADOR", "OP_RESTA", "LIT_ENTERO", "OP_SUMA",
                "IDENTIFICADOR", "OP_BIT_AND", "IDENTIFICADOR", "OP_BIT_OR",
                "IDENTIFICADOR", "OP_BIT_XOR", "IDENTIFICADOR", "DELIM_PUNTO_COMA",
                "IDENTIFICADOR", "OP_ASIG_SUMA", "LIT_ENTERO", "DELIM_PUNTO_COMA",
            ],
        )

    def test_memoria_y_arreglos(self):
        rc, tokens, err = self.tokenizar(
            "leer x desde {0x23}; arreglo v[1] de entero = {35};"
        )
        self.assertEqual(rc, 0, err)
        tipos = [t[1] for t in tokens]
        self.assertEqual(tipos.count("DELIM_LLAVE_IZQ"), 2)
        self.assertEqual(tipos.count("DELIM_LLAVE_DER"), 2)
        self.assertIn("LIT_HEXADECIMAL", tipos)

    def test_errores_lexicos(self):
        casos = [
            "entero h = 0x;",
            "entero n = 123abc;",
            "caracter c = '';",
            "caracter c = 'ab';",
            'mostrar "sin cerrar\n',
            "entero x = 1; /* sin cerrar",
        ]
        for codigo in casos:
            with self.subTest(codigo=codigo):
                rc, tokens, err = self.tokenizar(codigo)
                self.assertNotEqual(rc, 0)
                self.assertIn("Error lexico", err)
                self.assertIn("TOKEN_ERROR", [t[1] for t in tokens])

    def test_compatibilidad_imp_anterior(self):
        ruta = ROOT / "programas" / "suma_imperativa.imp"
        proc = subprocess.run(
            [str(self.binario), str(ruta)],
            text=True,
            capture_output=True,
        )
        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertIn("TIPO_ENTERO", proc.stdout)
        self.assertIn("KW_MIENTRAS", proc.stdout)
        self.assertIn("KW_MOSTRAR", proc.stdout)


if __name__ == "__main__":
    unittest.main()
