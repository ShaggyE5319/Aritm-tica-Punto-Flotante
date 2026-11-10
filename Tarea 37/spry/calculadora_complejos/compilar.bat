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
bison -d -o complejos.tab.c complejos.y
if errorlevel 1 goto :failed
flex -o lex.complejos.c complejos.l
if errorlevel 1 goto :failed
gcc -std=c11 -Wall -Wextra -Wno-unused-function -o bin\calculadora_complejos.exe complejos.tab.c lex.complejos.c -lm
if errorlevel 1 goto :failed

echo Calculadora generada en bin\calculadora_complejos.exe
popd
exit /b 0

:failed
echo [Error] No se pudo construir la calculadora.
popd
exit /b 1
