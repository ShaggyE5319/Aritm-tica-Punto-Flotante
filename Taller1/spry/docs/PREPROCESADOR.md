# Preprocesador Spry

El archivo [`preprocesador.l`](../preprocesador/preprocesador.l) contiene el preprocesador
Flex/C. Reconoce:

- `#include "archivo.h"` con includes anidados mediante una pila de
  `YY_BUFFER_STATE` limitada a diez niveles.
- `#define NOMBRE valor`, con sustitución de identificadores antes de emitir
  el texto.

Para generarlo con Flex y un compilador C:

```text
cd spry
flex -o preprocesador\preprocesador_lex.c preprocesador\preprocesador.l
gcc preprocesador\preprocesador_lex.c -o bin\preprocesador.exe
```

Se puede ejecutar sobre un archivo o sobre la entrada estándar:

```text
bin\preprocesador.exe programas\ejemplos\prueba.asm
bin\preprocesador.exe < programas\ejemplos\prueba.asm
```

Tres ejemplos listos para probar desde la terminal:

```text
bin\preprocesador.exe preprocesador\programa_macro.asm
bin\preprocesador.exe programas\ejemplos\prueba.asm
```

Resultados esperados:

- `ejemplo_define.asm`: muestra la sustitución de `REGISTRO` y `CANTIDAD`.
- `ejemplo_include.asm`: incluye [`constantes.h`](../preprocesador/constantes.h) y sustituye
  `VALOR_BASE` y `PI`.
- `ejemplo_anidado.asm`: incluye dos niveles (`ejemplo_nivel1.h` y
  `ejemplo_nivel2.h`) y demuestra la restauración de buffers.

Las constantes de límites, tamaños y capacidad están centralizadas en
[`constantes.h`](../preprocesador/constantes.h), que se incluye durante la compilación del
scanner y también puede ser consumido por los archivos Spry.

La integración principal está en [`assembler.py`](../assembler.py): `assemble`
preprocesa texto y `assemble_file` resuelve los includes relativos al archivo
de entrada. Esto permite que [`enlazador_cargador.py`](../enlazador_cargador.py)
cargue directamente fuentes Spry con macros, incluso en entornos Windows que
no tengan Flex instalado; el módulo [`preprocesador.py`](../preprocesador/preprocesador.py)
aporta esa misma funcionalidad como respaldo nativo de Python.
