# Gramática de SPRY

Este directorio contiene el diseño formal de la primera fase del Taller #2:
gramática completa del lenguaje propio SPRY.

## Archivos

- `SPRY.ebnf`: gramática sintáctica completa.
- `LEXICO_SPRY.ebnf`: gramática de categorías léxicas y literales.
- `ejemplos/`: programas representativos en fuente SPRY.

## Uso con Railroad Diagram Generator

Abrir https://www.bottlecaps.de/rr/ui

1. Pulsar **Edit Grammar**.
2. Seleccionar `SPRY.ebnf` o `LEXICO_SPRY.ebnf`.
3. Generar los diagramas de sintaxis.
4. Exportar o guardar el diagrama integrado a la documentación.

La sintaxis usa `::=`, `"terminal"`, `[opcional]`, `{repeticion}` y `|`.

## Inicio de análisis

La regla inicial sintáctica es `Unidad`.

La regla inicial léxica es `UnidadLexica`.

## Compatibilidad con el proyecto

La gramática admite el programa completo:

```text
programa Nombre;
inicio
    entero numero = 1;
    mientras (numero < 10) {
        numero = numero + 1;
    }
    mostrar numero;
fin;
```

También admite bloques imperativos sin envoltura, por compatibilidad con los
archivos actuales `.imp`:

```text
entero numero = 1;
mostrar numero;
```

Las instrucciones actuales `leer` y `escribir` se consideran operaciones de
memoria:

```text
leer numero desde {35};
escribir numero hacia {0x23};
```
