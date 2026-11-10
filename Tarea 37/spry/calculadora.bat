@echo off
setlocal
pushd "%~dp0"

if not exist bin\calculadora_complejos.exe (
    echo La calculadora no esta compilada. Ejecute compilar.bat primero.
    popd
    exit /b 1
)

bin\calculadora_complejos.exe
set "codigo=%ERRORLEVEL%"
popd
exit /b %codigo%
