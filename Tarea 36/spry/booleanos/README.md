# Evaluador de expresiones booleanas

El evaluador usa Flex para el análisis léxico y Bison/Yacc para la gramática:

```text
ExpB  -> ExpB or TermB | TermB
TermB -> TermB and FactB | FactB
FactB -> not FactB | (ExpB) | true | false
```

## Construcción y uso

Desde esta carpeta, con Flex, Bison y GCC disponibles:

```bat
booleano.bat
```

La forma interactiva no requiere crear un archivo de entrada:

```bat
bin\evaluador_booleano.exe
true or false and false
not (true and false)
^Z
type bin\salida.txt
```

En Windows, `^Z` representa `Ctrl+Z` y después se presiona Enter. El modo
interactivo siempre genera `bin\salida.txt` en la carpeta de Spry.

Para procesar un archivo fuente existente, se proporcionan ambos nombres:

```bat
bin\evaluador_booleano.exe bin\entrada.txt bin\salida_archivo.txt
```

El archivo de ejemplo `bin\entrada.txt` contiene:

```text
true or false and false
not (true and false)
false
```

Por tanto, ejecutando el comando desde la carpeta `spry`, los resultados se
guardan en `bin\salida_archivo.txt`.

Cada línea del archivo fuente contiene una expresión. También se puede usar
`;` para separar expresiones. El archivo destino contiene un resultado
`true` o `false` por línea. `and` tiene precedencia sobre `or`, y `not` sobre
ambos.
