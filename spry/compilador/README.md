# Lexer FLEX de SPRY

Lexer en FLEX para el lenguaje SPRY basado en `gramatica/SPRY.ebnf` y `gramatica/LEXICO_SPRY.ebnf`, pensado para conectarse con el parser en Bison (`spry.y`).

## Archivos

- `spry.l`: reglas léxicas en FLEX (palabras reservadas, tipos, literales, operadores, delimitadores, comentarios y seguimiento de línea/columna).
- `spry_tokens.h`: definición de tokens, `YYSTYPE` y `YYLTYPE` para probar el lexer sin Bison (`-DSPRY_STANDALONE`).
- `lexer_test.c`: programa pequeño para probar el lexer desde consola.

## Cómo compilar

### Con Bison (`spry.y`)

```bash
bison -d -o spry.tab.c spry.y
flex -o lex.spry.c spry.l
gcc -std=c11 -Wall -Wextra -o spry_parser spry.tab.c lex.spry.c
```

### Solo el lexer (para pruebas)

```bash
flex -o lex.spry.c spry.l
gcc -std=c11 -Wall -Wextra -DSPRY_STANDALONE -o spry_lexer lex.spry.c lexer_test.c
./spry_lexer ../gramatica/ejemplos/euclides.imp
```

Los signos `+`/`-` y las llaves `{`/`}` se devuelven como tokens separados para que el parser maneje expresiones unarias (`a-1`) y direcciones de memoria (`{35}`) sin conflictos con inicializaciones de arreglos.
