# Lenguaje imperativo propio SPRY

SPRY es ahora un lenguaje fuente propio, no una simulación directa de
ensamblador. Conserva un vocabulario propio y separa el código fuente de la
arquitectura de máquina.

## Gramática y categorías principales

| Categoría léxica | Lexemas |
|---|---|
| Reservada | `programa`, `inicio`, `fin`, `tipo` |
| Tipo | `entero`, `decimal`, `logico` |
| Control | `repetir`, `mientras`, `si`, `sino` |
| Entrada/salida | `leer`, `mostrar`, `desde`, `hacia` |
| Identificador | nombres de variables |
| Dirección inmediata | `{35}`, `{0x23}` |

Las instrucciones terminan en `;` y los bloques usan llaves. `leer` carga desde
RAM y `escribir` guarda en RAM:

```text
entero valor = 1;
leer valor desde {35};
escribir valor hacia {0x23};
mostrar valor;
```

`lexico_imperativo.py` define el vocabulario léxico preliminar descrito en el
informe. Reconoce las palabras reservadas `type`, `program`, `int`, `float`,
`while`, `if`, `else` y `write`; identificadores, enteros, reales, operadores,
delimitadores y comentarios `//` y `/* ... */`. También conserva línea y columna
de cada token. Los operadores de dos caracteres (`==`, `!=`, `<=`, `>=`) se
reconocen antes que los de uno.

`compilador_imperativo.py` compila solo un subconjunto ejecutable de ese diseño:
variables escalares `int`, asignación, `while`, `if`/`else`, `write`, operaciones
enteras `+`, `-`, `*`, `/` y las seis comparaciones. Usa estas palabras reservadas:


| Palabra       | Uso                                                 |
| ------------- | --------------------------------------------------- |
| `int`         | Declara e inicializa una variable entera.           |
| `while`       | Repite un bloque mientras se cumpla una condición. |
| `if` / `else` | Ejecuta uno de dos bloques según una condición.   |
| `write`       | Envía el valor al puerto de salida 2.              |

También admite asignaciones, `+`, `-`, `*`, `/` y comparaciones `==`, `!=`, `<`,
`>`, `<=`, `>=`. Los bloques se delimitan con llaves; las instrucciones terminan
con `;`. Las variables deben declararse antes de usarse. Se permiten hasta diez
variables y cada expresión aritmética admite como máximo un operador. Aunque el
analizador léxico reconoce `type`, `program`, `float` y la notación de arreglos,
matrices y reales, todavía no existe soporte de compilación para esas estructuras.
El ejemplo `Vector3` del informe es una propuesta ilustrativa y el compilador
actual no puede procesarlo.

## Estado exacto de las fases

En esta etapa no se implementa todavía el análisis sintáctico con YACC/Bison ni
el análisis semántico independiente del compilador SPRY. El lexer disponible
clasifica tokens y el módulo Python los consume con métodos recursivos propios
para reconocer sentencias y generar ensamblador. Esta etapa debe describirse
como traducción educativa directa y no como una gramática YACC completa.

## Diseño formal disponible

La especificación formal E-BNF de la primera parte está en
[`gramatica/SPRY.ebnf`](../gramatica/SPRY.ebnf), y la especificación léxica en
[`gramatica/LEXICO_SPRY.ebnf`](../gramatica/LEXICO_SPRY.ebnf). Los archivos pueden
cargarse directamente en el Railroad Diagram Generator de BottleCaps.

```
