# Calculadora de números complejos de Spry

Esta calculadora es independiente del resto del proyecto. Todo lo necesario
para construirla está en esta carpeta; por tanto, se puede eliminar la carpeta
`Calculadora` original sin afectar a Spry.

## Construcción y ejecución

Desde la carpeta `spry`, con FLEX, BISON y GCC disponibles:

```bat
compilar.bat
```

El `compilar.bat` principal construye todo el toolchain de Spry, incluida la
calculadora. No inicia la calculadora automáticamente. Después de compilar,
puede ejecutarla con:

```bat
bin\calculadora_complejos.exe
```

También puede usar `calculadora.bat` desde `spry` como acceso directo para
ejecutar una calculadora ya compilada.

Se escribe una expresión por línea. La salida muestra las representaciones
equivalentes que aplican al resultado.

## Formas reconocidas

El patrón léxico usa estas definiciones regulares:

```text
DIGITO  = [0-9]
DECIMAL = ((DIGITO+(\.DIGITO*)|\.DIGITO+)([eE][+-]?DIGITO+)?)
NUMERO  = [+-]?DECIMAL
```

Con ellas, las extensiones regulares de los literales son:

```text
NUMERO [+-] NUMERO i       -> a+bi o a-bi
NUMERO i                   -> bi
NUMERO                     -> a
( NUMERO , NUMERO )        -> (a,b)
NUMERO @ NUMERO            -> r@angulo, en radianes
```

Por ejemplo:

```text
3+4i
3-4i
4i
3
(3,4)
5@0.927295218
(1+2i)*(3-4i)
```

El lexer reconoce las seis formas, superando las cinco solicitadas. El parser
implementa suma, resta, multiplicación, división, paréntesis y menos unario.
Cada resultado se reporta en forma algebraica, par ordenado y polar; si además
es real o imaginario puro, se muestra también esa forma.
