import contextlib
import io
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from assembler import assemble_file
from cpu import CPU
from enlazador_cargador import EnlazadorCargador
from memoria import MemoriaRAM


EXAMPLES = ROOT / "programas" / "ejemplos"


def ejecutar(nombre):
    ruta = EXAMPLES / nombre
    memoria = MemoriaRAM()
    cpu = CPU(memoria)
    salida = io.StringIO()
    with contextlib.redirect_stdout(salida):
        cargador = EnlazadorCargador(memoria, cpu)
        if not cargador.cargar_programa(str(ruta)):
            raise AssertionError(f"No se pudo cargar {ruta}")
        cpu.correr_automatico()
    return cpu, len(assemble_file(ruta))


class PruebasEstructuras(unittest.TestCase):
    def test_mezcla_ordena_vector(self):
        cpu, palabras = ejecutar("prueba_mezcla.asm")
        resultado = [
            cpu.ram.leer_palabra_64(cpu.regs[0] + indice * 8)
            for indice in range(8)
        ]
        self.assertEqual(resultado, [1, 2, 3, 4, 6, 7, 8, 9])
        self.assertGreater(palabras, 0)

    def test_producto_punto(self):
        cpu, _ = ejecutar("prueba_producto_punto.asm")
        self.assertEqual(cpu.regs[0], 70)

    def test_multiplicacion_de_matrices(self):
        cpu, _ = ejecutar("prueba_multiplicacion_matrices.asm")
        self.assertEqual([cpu.regs[indice] for indice in range(8, 12)],
                         [19, 22, 43, 50])

    def test_transpuesta(self):
        cpu, _ = ejecutar("prueba_transpuesta.asm")
        resultado = [cpu.regs[indice] for indice in (8, 9, 10, 11, 12, 14)]
        self.assertEqual(resultado, [1, 4, 2, 5, 3, 6])


if __name__ == "__main__":
    unittest.main()
