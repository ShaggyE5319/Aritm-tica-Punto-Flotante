# Módulo de análisis léxico de Spry

El módulo léxico del compilador de la máquina Spry está implementado en
[`lexer.l`](../ensamblador/lexer.l) mediante FLEX. El lexer se genera durante la
compilación y entrega tokens al ensamblador de dos pasadas. El
[`enlazador.l`](../enlazador/enlazador.l) aplica el mismo enfoque al formato textual
de objetos hexadecimal.

## Vocabulario

El lexer del compilador reconoce las instrucciones enteras y de control:

```text
ADD SUB MUL DIV MOD ADDI SUBI MULI INC DEC
AND OR XOR NOT CMP SHL SHR ANDI ORI TEST
LOAD STORE MOV LOADA LOADR STORER PUSH POP LDI LDP
JMP JZ JNZ JG JL CALL RET HLT
IN OUT NET_SEND NET_RECV WAIT_I WAIT_IO INT_EN
```

También reconoce las instrucciones FPU ya definidas por la ISA:

```text
FADD FSUB FMUL FDIV FSQRT FUNPACK FHERON FITOF
```

Los registros válidos son `R0` a `R15`, con o sin prefijo `$`, además de `SP`
y `LR`. Estos dos últimos se normalizan a `R13` y `R14`, respectivamente.
Las palabras reservadas no distinguen mayúsculas de minúsculas.

Las directivas y símbolos reconocidos son:

```text
ORG .QUAD .WORD
IDENTIFICADOR IDENTIFICADOR:
```

Los literales numéricos admiten decimal, hexadecimal y el prefijo opcional
`#`, por ejemplo `42`, `0x2A`, `#42` y `#0x2A`. Los separadores son coma,
corchetes y dos puntos. Los comentarios empiezan con `;` y terminan al final de
la línea.

## Categorías gramaticales

| Token | Categoría | Ejemplo |
|---|---|---|
| `TOKEN_INSTRUCTION` | Mnemónico | `ADD`, `FADD`, `HLT` |
| `TOKEN_REGISTER` | Registro | `R3`, `$r12`, `SP` |
| `TOKEN_NUMBER` | Literal numérico | `42`, `0x2A`, `#42` |
| `TOKEN_LABEL_DEF` | Definición de etiqueta | `LOOP:` |
| `TOKEN_LABEL_REF` | Referencia a etiqueta | `LOOP` |
| `TOKEN_DIRECTIVE` | Directiva de ubicación | `ORG` |
| `TOKEN_DATA_DIRECTIVE` | Directiva de datos | `.QUAD`, `.WORD` |
| `TOKEN_COMMA` | Separador de operandos | `,` |
| `TOKEN_LBRACKET` / `TOKEN_RBRACKET` | Direccionamiento | `[R1]` |
| `TOKEN_NEWLINE` | Fin de sentencia | salto de línea |

Los espacios y comentarios no producen tokens. Un carácter fuera del
vocabulario produce un error léxico y hace que el ensamblador rechace la
pasada.

## Definiciones y extensiones regulares

Las definiciones principales de [`lexer.l`](../ensamblador/lexer.l) son:

```text
DIGIT       [0-9]
HEX_DIGIT   [0-9a-f]
ID          [a-z_][a-z0-9_]*
REGISTER    \$?[r]([0-9]|1[0-5])
NUMBER      \#?(0x{HEX_DIGIT}+|{DIGIT}+)
```

Las instrucciones se agrupan en la extensión regular `INSTRUCTION`. Las
palabras reservadas aparecen antes de `ID`, y la definición de etiqueta antes
de la referencia general, para conservar la clasificación correcta.

El lexer del enlazador reconoce líneas de objeto con la forma:

```text
0x020 | 0038000000000000
```

y entrega tokens de dirección, palabra y fin de línea al cargador C++.

## Flujo integrado

```text
fuente ASM
  -> preprocesador FLEX
  -> lexer FLEX del compilador
  -> ensamblador C++
  -> objeto hexadecimal
  -> lexer FLEX del enlazador
  -> enlazador-cargador C++
  -> RAM / CPU
```

La construcción se ejecuta con [`compilar.bat`](../compilar.bat). No se
modifican los opcodes, el tamaño de la memoria, los registros ni los valores
sensibles de la máquina.
