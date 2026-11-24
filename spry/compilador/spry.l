%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef SPRY_STANDALONE
#include "spry_tokens.h"
#else
#include "spry.tab.h"
#endif

int spry_errores_lexicos = 0;
int spry_columna = 1;
const char *spry_archivo_actual = "<stdin>";
static int comentario_linea = 1;
static int comentario_col = 1;
static FILE *archivo_abierto = NULL;

static char *copiar_texto(const char *s) {
    size_t n = strlen(s);
    char *res = (char *)malloc(n + 1);
    if (res != NULL) {
        memcpy(res, s, n + 1);
    }
    return res;
}

static char leer_escape(const char *lexema) {
    if (lexema[1] == '\\') {
        switch (lexema[2]) {
            case 'n':  return '\n';
            case 't':  return '\t';
            case 'r':  return '\r';
            case '0':  return '\0';
            case '\\': return '\\';
            case '\'': return '\'';
            case '"':  return '"';
            default:   return lexema[2];
        }
    }
    return lexema[1];
}

static void actualizar_pos(const char *texto, int len) {
    yylloc.first_line = yylineno;
    yylloc.first_column = spry_columna;
    for (int i = 0; i < len; i++) {
        if (texto[i] == '\n') {
            spry_columna = 1;
        } else {
            spry_columna++;
        }
    }
    yylloc.last_line = yylineno;
    yylloc.last_column = (spry_columna > 1) ? spry_columna - 1 : 1;
}

#define YY_USER_ACTION actualizar_pos(yytext, yyleng);
%}

%option noyywrap
%option yylineno
%option nounput
%option noinput
%option never-interactive

%x COMENTARIO

DIGITO      [0-9]
HEX         [0-9a-fA-F]
LETRA       [a-zA-Z]
ID          ({LETRA}|_)({LETRA}|{DIGITO}|_)*
EXP         [eE][+-]?{DIGITO}+
REAL        ({DIGITO}+\.{DIGITO}*|\.{DIGITO}+){EXP}?|{DIGITO}+{EXP}

%%

[ \t\r\n]+                  ;
"//".*                      ;

"/*"                        {
                                comentario_linea = yylloc.first_line;
                                comentario_col = yylloc.first_column;
                                BEGIN(COMENTARIO);
                            }
<COMENTARIO>"*/"            { BEGIN(INITIAL); }
<COMENTARIO>[^*\n]+         ;
<COMENTARIO>"*"             ;
<COMENTARIO>\n              ;
<COMENTARIO><<EOF>>         {
                                fprintf(stderr, "Error lexico (%d:%d): comentario sin cerrar\n",
                                        comentario_linea, comentario_col);
                                spry_errores_lexicos++;
                                BEGIN(INITIAL);
                                return TOKEN_ERROR;
                            }

 /* Palabras reservadas */
"programa"                  { return KW_PROGRAMA; }
"inicio"                    { return KW_INICIO; }
"fin"                       { return KW_FIN; }
"tipo"                      { return KW_TIPO; }
"tda"                       { return KW_TDA; }
"arreglo"                   { return KW_ARREGLO; }
"matriz"                    { return KW_MATRIZ; }
"constante"                 { return KW_CONSTANTE; }
"de"                        { return KW_DE; }
"nuevo"                     { return KW_NUEVO; }
"publico"                   { return KW_PUBLICO; }
"privado"                   { return KW_PRIVADO; }
"void"                      { return KW_VOID; }

"repetir"                   { return KW_REPETIR; }
"desde"                     { return KW_DESDE; }
"hasta"                     { return KW_HASTA; }
"paso"                      { return KW_PASO; }
"mientras"                  { return KW_MIENTRAS; }
"si"                        { return KW_SI; }
"sino"                      { return KW_SINO; }
"segun"                     { return KW_SEGUN; }
"caso"                      { return KW_CASO; }
"predeterminado"            { return KW_PREDETERMINADO; }
"romper"                    { return KW_ROMPER; }

"funcion"                   { return KW_FUNCION; }
"procedimiento"             { return KW_PROCEDIMIENTO; }
"retornar"                  { return KW_RETORNAR; }
"leer"                      { return KW_LEER; }
"escribir"                  { return KW_ESCRIBIR; }
"mostrar"                   { return KW_MOSTRAR; }
"hacia"                     { return KW_HACIA; }

 /* Tipos */
"entero"                    { return TIPO_ENTERO; }
"decimal"                   { return TIPO_DECIMAL; }
"logico"                    { return TIPO_LOGICO; }
"caracter"                  { return TIPO_CARACTER; }
"cadena"                    { return TIPO_CADENA; }
"memoria"                   { return TIPO_MEMORIA; }

"verdadero"                 { yylval.booleano = 1; return LIT_BOOLEANO; }
"falso"                     { yylval.booleano = 0; return LIT_BOOLEANO; }

 /* Compatibilidad con los .imp anteriores en ingles */
"program"                   { return KW_PROGRAMA; }
"type"                      { return KW_TIPO; }
"int"                       { return TIPO_ENTERO; }
"float"                     { return TIPO_DECIMAL; }
"while"                     { return KW_MIENTRAS; }
"if"                        { return KW_SI; }
"else"                      { return KW_SINO; }
"write"                     { return KW_MOSTRAR; }

 /* Literales */
0[xX]{HEX}+                 { yylval.entero = strtoll(yytext, NULL, 16); return LIT_HEXADECIMAL; }
0[xX][a-zA-Z0-9_]*          {
                                fprintf(stderr, "Error lexico (%d:%d): hexadecimal invalido '%s'\n",
                                        yylloc.first_line, yylloc.first_column, yytext);
                                spry_errores_lexicos++;
                                return TOKEN_ERROR;
                            }

{REAL}                      { yylval.decimal = strtod(yytext, NULL); return LIT_DECIMAL; }
{DIGITO}+                   { yylval.entero = strtoll(yytext, NULL, 10); return LIT_ENTERO; }

({DIGITO}+(\.{DIGITO}*)?|\.{DIGITO}+)[a-zA-Z_][a-zA-Z0-9_]* {
                                fprintf(stderr, "Error lexico (%d:%d): numero invalido '%s'\n",
                                        yylloc.first_line, yylloc.first_column, yytext);
                                spry_errores_lexicos++;
                                return TOKEN_ERROR;
                            }

\"([^\"\\\n]|\\.)*\"        { yylval.texto = copiar_texto(yytext); return LIT_CADENA; }
\"([^\"\\\n]|\\.)*          {
                                fprintf(stderr, "Error lexico (%d:%d): cadena sin cerrar\n",
                                        yylloc.first_line, yylloc.first_column);
                                spry_errores_lexicos++;
                                return TOKEN_ERROR;
                            }

'([^'\\\n]|\\.)'            { yylval.caracter = leer_escape(yytext); return LIT_CARACTER; }
''                          {
                                fprintf(stderr, "Error lexico (%d:%d): caracter vacio\n",
                                        yylloc.first_line, yylloc.first_column);
                                spry_errores_lexicos++;
                                return TOKEN_ERROR;
                            }
'([^'\\\n]|\\.)+'           {
                                fprintf(stderr, "Error lexico (%d:%d): caracter invalido '%s'\n",
                                        yylloc.first_line, yylloc.first_column, yytext);
                                spry_errores_lexicos++;
                                return TOKEN_ERROR;
                            }
'([^'\\\n]|\\.)*            {
                                fprintf(stderr, "Error lexico (%d:%d): caracter sin cerrar\n",
                                        yylloc.first_line, yylloc.first_column);
                                spry_errores_lexicos++;
                                return TOKEN_ERROR;
                            }

 /* Operadores */
"++"                        { return OP_INC; }
"--"                        { return OP_DEC; }
"<<"                        { return OP_SHL; }
">>"                        { return OP_SHR; }
"=="                        { return OP_IGUAL; }
"!="                        { return OP_DIFERENTE; }
"<="                        { return OP_MENOR_IGUAL; }
">="                        { return OP_MAYOR_IGUAL; }
"&&"                        { return OP_AND; }
"||"                        { return OP_OR; }
"+="                        { return OP_ASIG_SUMA; }
"-="                        { return OP_ASIG_RESTA; }
"*="                        { return OP_ASIG_MULT; }
"/="                        { return OP_ASIG_DIV; }
"%="                        { return OP_ASIG_MOD; }

"+"                         { return OP_SUMA; }
"-"                         { return OP_RESTA; }
"*"                         { return OP_MULT; }
"/"                         { return OP_DIV; }
"%"                         { return OP_MOD; }
"="                         { return OP_ASIGNACION; }
"<"                         { return OP_MENOR; }
">"                         { return OP_MAYOR; }
"!"                         { return OP_NOT; }
"~"                         { return OP_BIT_NOT; }
"&"                         { return OP_BIT_AND; }
"|"                         { return OP_BIT_OR; }
"^"                         { return OP_BIT_XOR; }
"?"                         { return OP_PREGUNTA; }
":"                         { return OP_DOS_PUNTOS; }
"#"                         { return OP_PREPROCESADOR; }

 /* Delimitadores */
"("                         { return DELIM_PAR_IZQ; }
")"                         { return DELIM_PAR_DER; }
"{"                         { return DELIM_LLAVE_IZQ; }
"}"                         { return DELIM_LLAVE_DER; }
"["                         { return DELIM_COR_IZQ; }
"]"                         { return DELIM_COR_DER; }
","                         { return DELIM_COMA; }
";"                         { return DELIM_PUNTO_COMA; }
"."                         { return DELIM_PUNTO; }

{ID}                        { yylval.texto = copiar_texto(yytext); return IDENTIFICADOR; }

.                           {
                                fprintf(stderr, "Error lexico (%d:%d): caracter inesperado '%s'\n",
                                        yylloc.first_line, yylloc.first_column, yytext);
                                spry_errores_lexicos++;
                                return TOKEN_ERROR;
                            }

%%

void spry_lexer_reiniciar(const char *nombre_archivo) {
    spry_errores_lexicos = 0;
    spry_columna = 1;
    yylineno = 1;
    spry_archivo_actual = (nombre_archivo != NULL) ? nombre_archivo : "<stdin>";
    BEGIN(INITIAL);
}

int spry_lexer_abrir_archivo(const char *ruta) {
    if (ruta == NULL) {
        return -1;
    }
    FILE *f = fopen(ruta, "r");
    if (f == NULL) {
        fprintf(stderr, "Error lexico: no se pudo abrir '%s'\n", ruta);
        spry_errores_lexicos++;
        return -1;
    }
    if (archivo_abierto != NULL) {
        fclose(archivo_abierto);
    }
    archivo_abierto = f;
    yyrestart(f);
    spry_lexer_reiniciar(ruta);
    return 0;
}

void spry_lexer_cerrar_archivo(void) {
    if (archivo_abierto != NULL) {
        fclose(archivo_abierto);
        archivo_abierto = NULL;
    }
}
