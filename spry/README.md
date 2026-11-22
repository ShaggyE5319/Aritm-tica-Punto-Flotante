# SPRY

Proyecto completo del lenguaje y la arquitectura SPRY.

## Estructura

- `assembler.py`, `compilador_imperativo.py`, `lexico_imperativo.py`: compilación del lenguaje fuente.
- `isa.py`, `cpu.py`, `memoria.py`: ISA, emulador y memoria hexadecimal de 4 KB.
- `ensamblador.cpp`, `lexer.l`, `lexer_lex.c`: ensamblador C++ y analizador léxico FLEX.
- `enlazador/`, `preprocesador/`: etapas auxiliares.
- `programas/`: fuentes ASM, archivos `.imp`, programas de ejemplo y archivos heredados conservados.
- `programas/fuentes_raiz/`: archivos ASM y HEX trasladados desde la raíz anterior.
- `pruebas/`: pruebas unitarias Python.
- `docs/`: documentación técnica.
- `bin/`: ejecutables generados.
- `booleanos/`, `calculadora_complejos/`: evaluadores desarrollados con FLEX/BISON.
- `librerias/`: estructuras y rutinas ASM.
- `compilar.bat`, `calculadora.bat`: comandos de compilación y ejecución.

La memoria conserva 4096 bytes, las direcciones continúan usando hexadecimal
de 12 bits y las instrucciones ocupan palabras de 64 bits.

## Estado de las fases del compilador

El lexer propio produce tokens. El análisis sintáctico con YACC/Bison, el
análisis semántico independiente y la generación de código mediante una gramática
completa todavía no forman parte de esta entrega. El actual
`compilador_imperativo.py` consume lexemas como un traductor educativo directo
a ensamblador.

## Pruebas y verificacion

Ejecute todos los comandos desde `spry`.

### Compilar todos los componentes

```bat
compilar.bat
```

Debe terminar con código de salida `0` y generar los ejecutables de `bin\`.

### Probar el lenguaje y la arquitectura

```bat
python -m unittest pruebas.test_lenguaje_spry pruebas.test_estructuras
```

Resultado esperado: 8 pruebas aprobadas.

### Compilar el lenguaje fuente SPRY

```bat
python compilador_imperativo.py programas\suma_imperativa.imp -o salida_imperativa.asm
python -c "from assembler import assemble_file; print(len(assemble_file('salida_imperativa.asm'))) "
```

Debe generar `salida_imperativa.asm` y ensamblar 18 palabras de 64 bits.

### Ejecutar el programa fuente

```bat
python -c "from memoria import MemoriaRAM; from cpu import CPU; from enlazador_cargador import EnlazadorCargador; m=MemoriaRAM(); c=CPU(m); l=EnlazadorCargador(m,c); l.cargar_programa(r'salida_imperativa.asm'); c.correr_automatico(); print(c.io_ports.get(2), c.halted)"
```

Resultado esperado: `55 True`, correspondiente al puerto de salida 2 y a HLT.

### Ejecutar el ensamblador C++

```bat
bin\ensamblador.exe programas\ejemplos\prueba.asm salida_verificacion.hex
type salida_verificacion.hex
```

El resultado debe mostrar palabras de 16 dígitos hexadecimales, una por cada
instrucción, con direcciones que avanzan en bloques de `8`.

### Ejecutar y cargar en hexadecimal

```bat
bin\enlazador.exe salida_verificacion.hex 0x010
```

Debe validar la dirección, cargar el contenido desde `0x010` y mostrar el
volcado hexadecimal de la RAM.

### Probar Fibonacci

```bat
python -c "from memoria import MemoriaRAM; from cpu import CPU; from enlazador_cargador import EnlazadorCargador; m=MemoriaRAM(); c=CPU(m); l=EnlazadorCargador(m,c); l.cargar_programa(r'programas\ejemplos\fibonacci.asm'); c.correr_automatico(); print(c.regs[1], c.regs[2])"
```

El contenido relevante debe finalizar con el resultado Fibonacci 13 en `R2`.

### Probar los evaluadores independientes

```bat
bin\evaluador_booleano.exe bin\entrada.txt bin\salida_archivo.txt
type bin\salida_archivo.txt
```

Para números complejos:

```bat
bin\calculadora_complejos.exe
3+4i
(1+2i)*(3-4i)
```
