# Lenguaje imperativo SPRY

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

```
