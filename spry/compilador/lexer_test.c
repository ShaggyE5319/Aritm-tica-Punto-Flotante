#include <stdio.h>
#include <stdlib.h>
#include "spry_tokens.h"

extern int yylex(void);
extern char *yytext;
extern FILE *yyin;

YYSTYPE yylval;
YYLTYPE yylloc;

static const char *nombre_token(int token) {
    switch (token) {
        case KW_PROGRAMA:       return "KW_PROGRAMA";
        case KW_INICIO:         return "KW_INICIO";
        case KW_FIN:            return "KW_FIN";
        case KW_TIPO:           return "KW_TIPO";
        case KW_TDA:            return "KW_TDA";
        case KW_ARREGLO:        return "KW_ARREGLO";
        case KW_MATRIZ:         return "KW_MATRIZ";
        case KW_CONSTANTE:      return "KW_CONSTANTE";
        case KW_DE:             return "KW_DE";
        case KW_NUEVO:          return "KW_NUEVO";
        case KW_PUBLICO:        return "KW_PUBLICO";
        case KW_PRIVADO:        return "KW_PRIVADO";
        case KW_VOID:           return "KW_VOID";
        case KW_REPETIR:        return "KW_REPETIR";
        case KW_DESDE:          return "KW_DESDE";
        case KW_HASTA:          return "KW_HASTA";
        case KW_PASO:           return "KW_PASO";
        case KW_MIENTRAS:       return "KW_MIENTRAS";
        case KW_SI:             return "KW_SI";
        case KW_SINO:           return "KW_SINO";
        case KW_SEGUN:          return "KW_SEGUN";
        case KW_CASO:           return "KW_CASO";
        case KW_PREDETERMINADO: return "KW_PREDETERMINADO";
        case KW_ROMPER:         return "KW_ROMPER";
        case KW_FUNCION:        return "KW_FUNCION";
        case KW_PROCEDIMIENTO:  return "KW_PROCEDIMIENTO";
        case KW_RETORNAR:       return "KW_RETORNAR";
        case KW_LEER:           return "KW_LEER";
        case KW_ESCRIBIR:       return "KW_ESCRIBIR";
        case KW_MOSTRAR:        return "KW_MOSTRAR";
        case KW_HACIA:          return "KW_HACIA";
        case TIPO_ENTERO:       return "TIPO_ENTERO";
        case TIPO_DECIMAL:      return "TIPO_DECIMAL";
        case TIPO_LOGICO:       return "TIPO_LOGICO";
        case TIPO_CARACTER:     return "TIPO_CARACTER";
        case TIPO_CADENA:       return "TIPO_CADENA";
        case TIPO_MEMORIA:      return "TIPO_MEMORIA";
        case LIT_ENTERO:        return "LIT_ENTERO";
        case LIT_HEXADECIMAL:   return "LIT_HEXADECIMAL";
        case LIT_DECIMAL:       return "LIT_DECIMAL";
        case LIT_BOOLEANO:      return "LIT_BOOLEANO";
        case LIT_CARACTER:      return "LIT_CARACTER";
        case LIT_CADENA:        return "LIT_CADENA";
        case IDENTIFICADOR:     return "IDENTIFICADOR";
        case OP_INC:            return "OP_INC";
        case OP_DEC:            return "OP_DEC";
        case OP_SHL:            return "OP_SHL";
        case OP_SHR:            return "OP_SHR";
        case OP_IGUAL:          return "OP_IGUAL";
        case OP_DIFERENTE:      return "OP_DIFERENTE";
        case OP_MENOR_IGUAL:    return "OP_MENOR_IGUAL";
        case OP_MAYOR_IGUAL:    return "OP_MAYOR_IGUAL";
        case OP_AND:            return "OP_AND";
        case OP_OR:             return "OP_OR";
        case OP_ASIG_SUMA:      return "OP_ASIG_SUMA";
        case OP_ASIG_RESTA:     return "OP_ASIG_RESTA";
        case OP_ASIG_MULT:      return "OP_ASIG_MULT";
        case OP_ASIG_DIV:       return "OP_ASIG_DIV";
        case OP_ASIG_MOD:       return "OP_ASIG_MOD";
        case OP_SUMA:           return "OP_SUMA";
        case OP_RESTA:          return "OP_RESTA";
        case OP_MULT:           return "OP_MULT";
        case OP_DIV:            return "OP_DIV";
        case OP_MOD:            return "OP_MOD";
        case OP_ASIGNACION:     return "OP_ASIGNACION";
        case OP_MENOR:          return "OP_MENOR";
        case OP_MAYOR:          return "OP_MAYOR";
        case OP_NOT:            return "OP_NOT";
        case OP_BIT_NOT:        return "OP_BIT_NOT";
        case OP_BIT_AND:        return "OP_BIT_AND";
        case OP_BIT_OR:         return "OP_BIT_OR";
        case OP_BIT_XOR:        return "OP_BIT_XOR";
        case OP_PREGUNTA:       return "OP_PREGUNTA";
        case OP_DOS_PUNTOS:     return "OP_DOS_PUNTOS";
        case OP_PREPROCESADOR:  return "OP_PREPROCESADOR";
        case DELIM_PAR_IZQ:     return "DELIM_PAR_IZQ";
        case DELIM_PAR_DER:     return "DELIM_PAR_DER";
        case DELIM_LLAVE_IZQ:   return "DELIM_LLAVE_IZQ";
        case DELIM_LLAVE_DER:   return "DELIM_LLAVE_DER";
        case DELIM_COR_IZQ:     return "DELIM_COR_IZQ";
        case DELIM_COR_DER:     return "DELIM_COR_DER";
        case DELIM_COMA:        return "DELIM_COMA";
        case DELIM_PUNTO_COMA:  return "DELIM_PUNTO_COMA";
        case DELIM_PUNTO:       return "DELIM_PUNTO";
        case TOKEN_ERROR:       return "TOKEN_ERROR";
        default:                return "DESCONOCIDO";
    }
}

int main(int argc, char **argv) {
    if (argc > 2) {
        fprintf(stderr, "Uso: %s [archivo.imp]\n", argv[0]);
        return EXIT_FAILURE;
    }

    if (argc == 2) {
        if (spry_lexer_abrir_archivo(argv[1]) != 0) {
            return EXIT_FAILURE;
        }
    } else {
        yyin = stdin;
        spry_lexer_reiniciar("<stdin>");
    }

    int tok;
    while ((tok = yylex()) != TOKEN_EOF) {
        printf("%d:%d\t%s\t%s\n",
               yylloc.first_line,
               yylloc.first_column,
               nombre_token(tok),
               yytext);
        if (tok == IDENTIFICADOR || tok == LIT_CADENA) {
            free(yylval.texto);
        }
    }

    spry_lexer_cerrar_archivo();
    return (spry_errores_lexicos == 0) ? EXIT_SUCCESS : EXIT_FAILURE;
}
