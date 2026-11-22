import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from assembler import assemble
from lexico_imperativo import analizar


class PruebasLenguajeSpry(unittest.TestCase):
    def test_palabras_reservadas_y_categorias_propias(self):
        tokens = analizar("programa inicio entero leer desde mostrar sino")
        self.assertEqual([token.categoria for token in tokens],
                         ["RESERVADA", "RESERVADA", "TIPO",
                          "RESERVADA", "RESERVADA", "RESERVADA", "RESERVADA"])

    def test_direccion_memoria_inmediata_con_llaves(self):
        codigo = """
        ORG 0x200
        LDI R1, 35
        STORE R1, {35}
        LOAD R2, {35}
        HLT
        """
        palabras = assemble(codigo)
        self.assertEqual(len(palabras), 4)
        self.assertEqual((palabras[1] >> 30) & 0xFFF, 35)
        self.assertEqual((palabras[2] >> 30) & 0xFFF, 35)

    def test_compilador_admite_vocabulario_propio(self):
        from compilador_imperativo import Compilador
        fuente = """
        entero valor = 1;
        leer valor desde {35};
        mostrar valor;
        """
        ensamblador = Compilador(fuente).compilar()
        self.assertIn("LOAD R1, {35}", ensamblador)
        self.assertIn("OUT R1, 2", ensamblador)

    def test_cargador_respeta_origen_de_codigo_objeto(self):
        import os
        import tempfile
        from cpu import CPU
        from enlazador_cargador import EnlazadorCargador
        from memoria import MemoriaRAM

        with tempfile.NamedTemporaryFile(mode="w", suffix=".hex", delete=False) as archivo:
            archivo.write("0x010 | 1200000000000000\n")
            ruta = archivo.name

        memoria = MemoriaRAM()
        cpu = CPU(memoria)
        cargador = EnlazadorCargador(memoria, cpu)
        try:
            self.assertTrue(cargador.cargar_programa(ruta))
            self.assertEqual(cpu.pc, 0x010)
        finally:
            os.unlink(ruta)


if __name__ == "__main__":
    unittest.main()
