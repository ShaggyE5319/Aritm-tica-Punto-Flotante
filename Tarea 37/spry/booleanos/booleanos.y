%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_VARIABLES 256

typedef struct {
    char nombre;
    double valor;
} Variable;

static FILE *archivo_salida;
static int errores = 0;
static Variable variables[MAX_VARIABLES];
static size_t cantidad_variables = 0;

int yylex(void);
void yyerror(const char *mensaje);
extern FILE *yyin;

static double obtener_variable(const char *nombre) {
    size_t i;
    for (i = 0; i < cantidad_variables; i++) {
        if (variables[i].nombre == nombre[0]) {
            return variables[i].valor;
        }
    }
    fprintf(stderr, "Error semantico: variable '%s' no definida\n", nombre);
    errores++;
    return 0.0;
}

static void asignar_variable(const char *nombre, double valor) {
    size_t i;
    for (i = 0; i < cantidad_variables; i++) {
        if (variables[i].nombre == nombre[0]) {
            variables[i].valor = valor;
            return;
        }
    }
    if (cantidad_variables == MAX_VARIABLES) {
        fprintf(stderr, "Error semantico: se alcanzo el limite de variables\n");
        errores++;
        return;
    }
    variables[cantidad_variables++] = (Variable){nombre[0], valor};
}

static double dividir(double izquierda, double derecha) {
    if (derecha == 0.0) {
        fprintf(stderr, "Error semantico: division por cero\n");
        errores++;
        return 0.0;
    }
    return izquierda / derecha;
}
%}

%define parse.error verbose

%union {
    int booleano;
    double numero;
    char *identificador;
}

%token <booleano> BOOLEANO
%token <numero> NUMERO
%token <identificador> IDENTIFICADOR
%token OR AND NOT
%token IGUAL IGUAL_IGUAL DIFERENTE MENOR MAYOR MENOR_IGUAL MAYOR_IGUAL
%token FIN_LINEA

%type <booleano> expresion disyuncion conjuncion factor_booleano relacion
%type <numero> aritmetica termino_numerico factor_numerico

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
    | IDENTIFICADOR IGUAL aritmetica FIN_LINEA
        {
            asignar_variable($1, $3);
            free($1);
        }
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
    : disyuncion { $$ = $1; }
    ;

disyuncion
    : disyuncion OR conjuncion { $$ = $1 || $3; }
    | conjuncion { $$ = $1; }
    ;

conjuncion
    : conjuncion AND factor_booleano { $$ = $1 && $3; }
    | factor_booleano { $$ = $1; }
    ;

factor_booleano
    : NOT factor_booleano { $$ = !$2; }
    | '(' expresion ')' { $$ = $2; }
    | BOOLEANO { $$ = $1; }
    | relacion { $$ = $1; }
    ;

relacion
    : aritmetica IGUAL_IGUAL aritmetica { $$ = $1 == $3; }
    | aritmetica DIFERENTE aritmetica { $$ = $1 != $3; }
    | aritmetica MENOR aritmetica { $$ = $1 < $3; }
    | aritmetica MAYOR aritmetica { $$ = $1 > $3; }
    | aritmetica MENOR_IGUAL aritmetica { $$ = $1 <= $3; }
    | aritmetica MAYOR_IGUAL aritmetica { $$ = $1 >= $3; }
    ;

aritmetica
    : aritmetica '+' termino_numerico { $$ = $1 + $3; }
    | aritmetica '-' termino_numerico { $$ = $1 - $3; }
    | termino_numerico { $$ = $1; }
    ;

termino_numerico
    : termino_numerico '*' factor_numerico { $$ = $1 * $3; }
    | termino_numerico '/' factor_numerico { $$ = dividir($1, $3); }
    | factor_numerico { $$ = $1; }
    ;

factor_numerico
    : '(' aritmetica ')' { $$ = $2; }
    | NUMERO { $$ = $1; }
    | IDENTIFICADOR
        {
            $$ = obtener_variable($1);
            free($1);
        }
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
