%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "booleanos.tab.h"

static int necesita_fin_linea = 0;
%}

%%

[ \t\r]+                 ;
"//"[^\n]*               ;
"or"                     { necesita_fin_linea = 1; return OR; }
"and"                    { necesita_fin_linea = 1; return AND; }
"not"                    { necesita_fin_linea = 1; return NOT; }
"true"                   { necesita_fin_linea = 1; yylval.booleano = 1; return BOOLEANO; }
"false"                  { necesita_fin_linea = 1; yylval.booleano = 0; return BOOLEANO; }
"=="                     { necesita_fin_linea = 1; return IGUAL_IGUAL; }
"!="                     { necesita_fin_linea = 1; return DIFERENTE; }
"<="                     { necesita_fin_linea = 1; return MENOR_IGUAL; }
">="                     { necesita_fin_linea = 1; return MAYOR_IGUAL; }
"="                      { necesita_fin_linea = 1; return IGUAL; }
"<"                      { necesita_fin_linea = 1; return MENOR; }
">"                      { necesita_fin_linea = 1; return MAYOR; }
"+"                      { necesita_fin_linea = 1; return '+'; }
"-"                      { necesita_fin_linea = 1; return '-'; }
"*"                      { necesita_fin_linea = 1; return '*'; }
"/"                      { necesita_fin_linea = 1; return '/'; }
"("                      { necesita_fin_linea = 1; return '('; }
")"                      { necesita_fin_linea = 1; return ')'; }
[0-9]+(\.[0-9]+)?       { necesita_fin_linea = 1; yylval.numero = strtod(yytext, NULL); return NUMERO; }
[A-Za-z]                { necesita_fin_linea = 1; yylval.identificador = strdup(yytext); return IDENTIFICADOR; }
";"                      { necesita_fin_linea = 0; return FIN_LINEA; }
\n                       { necesita_fin_linea = 0; return FIN_LINEA; }
.                        {
    fprintf(stderr, "Error lexico: caracter inesperado '%s'\n", yytext);
    return yytext[0];
}
<<EOF>>                  {
    if (necesita_fin_linea) {
        necesita_fin_linea = 0;
        return FIN_LINEA;
    }
    return 0;
}

%%

int yywrap(void) {
    return 1;
}
