%{
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "complejos.tab.h"

static double leer_numero(const char *texto) {
    char *fin;
    double valor = strtod(texto, &fin);
    if (fin == texto) {
        fprintf(stderr, "Error: numero complejo invalido: %s\n", texto);
        return NAN;
    }
    return valor;
}

static void quitar_espacios(char *texto) {
    char *origen = texto;
    char *destino = texto;
    while (*origen != '\0') {
        if (*origen != ' ' && *origen != '\t') {
            *destino++ = *origen;
        }
        origen++;
    }
    *destino = '\0';
}

static Complex leer_rectangular(const char *texto) {
    char copia[256];
    char *i;
    char *signo = NULL;
    size_t indice;

    snprintf(copia, sizeof(copia), "%s", texto);
    quitar_espacios(copia);
    i = strrchr(copia, 'i');
    if (i != NULL) {
        *i = '\0';
    }
    for (indice = 1; copia[indice] != '\0'; indice++) {
        if (copia[indice] == '+' || copia[indice] == '-') {
            signo = &copia[indice];
        }
    }
    if (signo == NULL) {
        return (Complex){0.0, leer_numero(copia)};
    }
    int signo_negativo = signo[0] == '-';
    *signo = '\0';
    return (Complex){
        leer_numero(copia),
        leer_numero(signo + 1) * (signo_negativo ? -1.0 : 1.0)
    };
}

static Complex leer_par(const char *texto) {
    double real;
    double imaginaria;
    if (sscanf(texto, " ( %lf , %lf )", &real, &imaginaria) != 2) {
        return (Complex){NAN, NAN};
    }
    return (Complex){real, imaginaria};
}

static Complex leer_polar(const char *texto) {
    double modulo;
    double angulo;
    if (sscanf(texto, " %lf @ %lf", &modulo, &angulo) != 2) {
        return (Complex){NAN, NAN};
    }
    return (Complex){modulo * cos(angulo), modulo * sin(angulo)};
}
%}

DIGITO       [0-9]
DECIMAL      (({DIGITO}+(\.{DIGITO}*)?)|(\.{DIGITO}+))([eE][+-]?{DIGITO}+)?
NUMERO       [+-]?{DECIMAL}

%%

[ \t\r]+                         ;
"//"[^\n]*                       ;
{NUMERO}[ \t]*[+-][ \t]*{DECIMAL}i {
    yylval.complejo = leer_rectangular(yytext);
    return LITERAL_COMPLEJO;
}
{NUMERO}[ \t]*i {
    yylval.complejo = leer_rectangular(yytext);
    return LITERAL_COMPLEJO;
}
\([ \t]*{NUMERO}[ \t]*,[ \t]*{NUMERO}[ \t]*\) {
    yylval.complejo = leer_par(yytext);
    return LITERAL_COMPLEJO;
}
{NUMERO}[ \t]*@[ \t]*{NUMERO} {
    yylval.complejo = leer_polar(yytext);
    return LITERAL_COMPLEJO;
}
{NUMERO} {
    yylval.complejo = (Complex){leer_numero(yytext), 0.0};
    return LITERAL_COMPLEJO;
}
\n                               { return '\n'; }
[-+*/()]                         { return yytext[0]; }
.                                {
    fprintf(stderr, "Error lexico: caracter inesperado '%s'\n", yytext);
}

%%

int yywrap(void) {
    return 1;
}
