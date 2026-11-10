%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static FILE *archivo_salida;
static int errores = 0;

int yylex(void);
void yyerror(const char *mensaje);
extern FILE *yyin;
%}

%define parse.error verbose

%union {
    int booleano;
}

%token <booleano> BOOLEANO
%token OR AND NOT
%token FIN_LINEA

%type <booleano> expresion termino factor

%left OR
%left AND
%right NOT

%%

programa
    : /* vacio */
    | programa linea
    ;

linea
    : FIN_LINEA
    | expresion FIN_LINEA
        {
            fprintf(archivo_salida, "%s\n", $1 ? "true" : "false");
            fflush(archivo_salida);
        }
    | error FIN_LINEA
        {
            errores++;
            yyerrok;
        }
    ;

expresion
    : expresion OR termino { $$ = $1 || $3; }
    | termino { $$ = $1; }
    ;

termino
    : termino AND factor { $$ = $1 && $3; }
    | factor { $$ = $1; }
    ;

factor
    : NOT factor { $$ = !$2; }
    | '(' expresion ')' { $$ = $2; }
    | BOOLEANO { $$ = $1; }
    ;

%%

void yyerror(const char *mensaje) {
    fprintf(stderr, "Error sintactico: %s\n", mensaje);
}

int main(int argc, char **argv) {
    const char *ruta_fuente = NULL;
    const char *ruta_destino = "bin\\salida.txt";

    if (argc == 1) {
        /* Las expresiones se leen de la consola y se guardan en salida.txt. */
    } else if (argc == 3) {
        ruta_fuente = argv[1];
        ruta_destino = argv[2];
    } else {
        fprintf(
            stderr,
            "Uso: %s o %s archivo_fuente archivo_destino\n",
            argv[0], argv[0]
        );
        return EXIT_FAILURE;
    }

    if (ruta_fuente != NULL) {
        yyin = fopen(ruta_fuente, "r");
        if (yyin == NULL) {
            fprintf(stderr, "No se pudo abrir el archivo fuente '%s': no existe\n", ruta_fuente);
            return EXIT_FAILURE;
        }
    } else {
        yyin = stdin;
    }

    archivo_salida = fopen(ruta_destino, "w");
    if (archivo_salida == NULL) {
        perror("No se pudo abrir el archivo destino");
        if (ruta_fuente != NULL) {
            fclose(yyin);
        }
        return EXIT_FAILURE;
    }

    int resultado = yyparse();
    if (ruta_fuente != NULL) {
        fclose(yyin);
    }
    fclose(archivo_salida);

    if (resultado != 0 || errores != 0) {
        remove(ruta_destino);
        return EXIT_FAILURE;
    }
    printf("Resultados guardados en %s\n", ruta_destino);
    return EXIT_SUCCESS;
}
