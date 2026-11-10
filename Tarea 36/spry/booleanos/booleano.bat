@echo off
setlocal
pushd "%~dp0"

where flex >nul 2>nul
if errorlevel 1 (
    echo [Error] FLEX no se encontro en el PATH.
    popd
    exit /b 1
)
where bison >nul 2>nul
if errorlevel 1 (
    echo [Error] BISON no se encontro en el PATH.
    popd
    exit /b 1
)
where gcc >nul 2>nul
if errorlevel 1 (
    echo [Error] GCC no se encontro en el PATH.
    popd
    exit /b 1
)

if not exist bin mkdir bin
bison -d -o booleanos.tab.c booleanos.y
if errorlevel 1 goto :failed
flex -o lex.booleanos.c booleanos.l
if errorlevel 1 goto :failed
gcc -std=c11 -Wall -Wextra -Wno-unused-function -o bin\evaluador_booleano.exe booleanos.tab.c lex.booleanos.c
if errorlevel 1 goto :failed

del /q booleanos.tab.c booleanos.tab.h lex.booleanos.c >nul 2>nul
echo Evaluador booleano generado en bin\evaluador_booleano.exe
popd
exit /b 0

:failed
echo [Error] No se pudo construir el evaluador booleano.
popd
exit /b 1
