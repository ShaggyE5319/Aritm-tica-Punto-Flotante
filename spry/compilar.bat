@echo off

echo    COMPILANDO TOOLCHAIN SPRY 1.0 (ENSAMBLADOR Y ENLAZADOR-CARGADOR)

setlocal
pushd "%~dp0"
if not exist bin mkdir bin

where flex >nul 2>nul
if errorlevel 1 goto :flex_missing

echo [1/4] Compilando preprocesador FLEX...
pushd preprocesador
flex -o preprocesador_lex.c preprocesador.l
if errorlevel 1 goto :failed
gcc preprocesador_lex.c -o ..\bin\preprocesador.exe
if errorlevel 1 goto :failed
popd
echo  - bin\preprocesador.exe generado con exito.

echo [2/4] Generando analizador lexico del ensamblador...
pushd ensamblador
flex -o lexer_lex.c lexer.l
if errorlevel 1 goto :failed
popd

echo [3/4] Compilando ensamblador propio...
pushd ensamblador
gcc -c lexer_lex.c -o lexer_lex.o
if errorlevel 1 goto :failed
g++ -std=c++17 -static-libgcc -static-libstdc++ ensamblador.cpp lexer_lex.o -o ..\bin\ensamblador.exe
if errorlevel 1 goto :failed
popd
echo  - bin\ensamblador.exe generado con exito.

echo [4/4] Generando lexer FLEX del enlazador-cargador...
pushd enlazador
flex -o enlazador_lex.c enlazador.l
if errorlevel 1 goto :failed
gcc -c enlazador_lex.c -o enlazador_lex.o
if errorlevel 1 goto :failed
g++ -std=c++17 -static-libgcc -static-libstdc++ enlazador.cpp enlazador_lex.o -o ..\bin\enlazador.exe
if errorlevel 1 goto :failed
popd
echo  - bin\enlazador.exe generado con exito.

echo Proceso finalizado correctamente.
echo Para ejecutar el ensamblador:
echo   bin\ensamblador.exe programas\ejemplos\prueba.asm programas\ejemplos\salida_nueva.hex
echo Para ejecutar el enlazador:
echo   bin\enlazador.exe programas\ejemplos\salida_nueva.hex 0x200
popd
exit /b 0

:flex_missing
echo [Error] Flex no se encontro en el PATH del sistema.
popd
exit /b 1

:failed
echo [Error] La compilacion fallo.
popd
exit /b 1