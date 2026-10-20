@echo off

echo    COMPILANDO TOOLCHAIN SPRY 1.0 (ENSAMBLADOR Y ENLAZADOR-CARGADOR)


where flex >nul 2>nul
if %errorlevel% neq 0 (
    echo [Aviso] Flex no se encontro en el PATH del sistema.
    echo Si ya tienes lex.yy.c generado, se intentara compilar directamente.
) else (
    echo [1/3] Generando analizador lexico con Flex...
    flex lexer.l
)

if exist lex.yy.c (
    echo [2/3] Compilando ensamblador propio (ensamblador.cpp + lex.yy.c)...
    g++ -std=c++17 ensamblador.cpp lex.yy.c -o ensamblador.exe
    if %errorlevel% equ 0 (
        echo  - ensamblador.exe generado con exito.
    ) else (
        echo  - Error al compilar ensamblador.exe
    )
) else (
    echo [Aviso] No existe lex.yy.c. Ejecuta 'flex lexer.l' antes de compilar el ensamblador.
)

echo [3/3] Compilando Enlazador-Cargador en C++ (enlazador.cpp)...
g++ -std=c++17 enlazador.cpp -o enlazador.exe
if %errorlevel% equ 0 (
    echo  - enlazador.exe generado con exito.
) else (
    echo  - Error al compilar enlazador.exe
)

echo Proceso finalizado.
echo Para ejecutar el Enlazador:
echo   enlazador.exe
echo   enlazador.exe [archivo.bin] [direccion_base]
