%{
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#ifndef COMPLEX_TYPE_DEFINED
#define COMPLEX_TYPE_DEFINED
typedef struct Complex {
    double real;
    double imaginaria;
} Complex;
#endif

void yyerror(const char *mensaje);
int yylex(void);

static Complex suma(Complex a, Complex b) {
    return (Complex){a.real + b.real, a.imaginaria + b.imaginaria};
}

static Complex resta(Complex a, Complex b) {
    return (Complex){a.real - b.real, a.imaginaria - b.imaginaria};
}

static Complex producto(Complex a, Complex b) {
    return (Complex){
        a.real * b.real - a.imaginaria * b.imaginaria,
        a.real * b.imaginaria + a.imaginaria * b.real
    };
}

static Complex cociente(Complex a, Complex b) {
    double denominador = b.real * b.real + b.imaginaria * b.imaginaria;
    return (Complex){
        (a.real * b.real + a.imaginaria * b.imaginaria) / denominador,
        (a.imaginaria * b.real - a.real * b.imaginaria) / denominador
    };
}

static void imprimir_numero(double valor) {
    printf("%.10g", valor);
}

static void imprimir_resultado(Complex z) {
    double modulo = hypot(z.real, z.imaginaria);
    double angulo = atan2(z.imaginaria, z.real);

    printf("  algebraica: ");
    imprimir_numero(z.real);
    if (z.imaginaria < 0) {
        printf(" - ");
        imprimir_numero(-z.imaginaria);
    } else {
        printf(" + ");
        imprimir_numero(z.imaginaria);
    }
    printf("i\n");

    printf("  par ordenado: (");
    imprimir_numero(z.real);
    printf(", ");
    imprimir_numero(z.imaginaria);
    printf(")\n");

    printf("  polar: ");
    imprimir_numero(modulo);
    printf("@");
    imprimir_numero(angulo);
    printf(" rad\n");

    if (fabs(z.real) < 1e-10) {
        printf("  imaginaria pura: ");
        imprimir_numero(z.imaginaria);
        printf("i\n");
    }
    if (fabs(z.imaginaria) < 1e-10) {
        printf("  real: ");
        imprimir_numero(z.real);
        printf("\n");
    }
}
%}

%code requires {
#ifndef COMPLEX_TYPE_DEFINED
#define COMPLEX_TYPE_DEFINED
typedef struct Complex {
    double real;
    double imaginaria;
} Complex;
#endif
}

%union {
    Complex complejo;
}

%token <complejo> LITERAL_COMPLEJO
%type <complejo> expresion

%left '+' '-'
%left '*' '/'
%right MENOS_UNARIO

%%

lineas
    : lineas expresion '\n' { imprimir_resultado($2); }
    | lineas '\n'
    | /* vacia */
    | lineas error '\n' { yyerrok; }
    ;

expresion
    : expresion '+' expresion { $$ = suma($1, $3); }
    | expresion '-' expresion { $$ = resta($1, $3); }
    | expresion '*' expresion { $$ = producto($1, $3); }
    | expresion '/' expresion
        {
            if (fabs($3.real) < 1e-15 && fabs($3.imaginaria) < 1e-15) {
                yyerror("division por cero");
                $$ = (Complex){NAN, NAN};
            } else {
                $$ = cociente($1, $3);
            }
        }
    | '(' expresion ')' { $$ = $2; }
    | '-' expresion %prec MENOS_UNARIO
        { $$ = (Complex){-$2.real, -$2.imaginaria}; }
    | LITERAL_COMPLEJO { $$ = $1; }
    ;

%%

void yyerror(const char *mensaje) {
    fprintf(stderr, "Error: %s\n", mensaje);
}

int main(void) {
    printf("Calculadora de numeros complejos SPRY\n");
    printf("Formas: a+bi, a-bi, bi, a, (a,b), r@angulo\n");
    printf("Escriba una expresion por linea; Ctrl+Z y Enter para salir.\n\n");
    return yyparse();
}
