#ifndef SPRY_TOKENS_H
#define SPRY_TOKENS_H

typedef struct YYLTYPE {
    int first_line;
    int first_column;
    int last_line;
    int last_column;
} YYLTYPE;

typedef union YYSTYPE {
    long long entero;
    double decimal;
    int booleano;
    char caracter;
    char *texto;
} YYSTYPE;

extern YYSTYPE yylval;
extern YYLTYPE yylloc;
extern int spry_errores_lexicos;
extern const char *spry_archivo_actual;

void spry_lexer_reiniciar(const char *nombre_archivo);
int spry_lexer_abrir_archivo(const char *ruta);
void spry_lexer_cerrar_archivo(void);

enum SpryToken {
    TOKEN_EOF = 0,

    KW_PROGRAMA = 258,
    KW_INICIO,
    KW_FIN,
    KW_TIPO,
    KW_TDA,
    KW_ARREGLO,
    KW_MATRIZ,
    KW_CONSTANTE,
    KW_DE,
    KW_NUEVO,
    KW_PUBLICO,
    KW_PRIVADO,
    KW_VOID,

    KW_REPETIR,
    KW_DESDE,
    KW_HASTA,
    KW_PASO,
    KW_MIENTRAS,
    KW_SI,
    KW_SINO,
    KW_SEGUN,
    KW_CASO,
    KW_PREDETERMINADO,
    KW_ROMPER,

    KW_FUNCION,
    KW_PROCEDIMIENTO,
    KW_RETORNAR,
    KW_LEER,
    KW_ESCRIBIR,
    KW_MOSTRAR,
    KW_HACIA,

    TIPO_ENTERO,
    TIPO_DECIMAL,
    TIPO_LOGICO,
    TIPO_CARACTER,
    TIPO_CADENA,
    TIPO_MEMORIA,

    LIT_ENTERO,
    LIT_HEXADECIMAL,
    LIT_DECIMAL,
    LIT_BOOLEANO,
    LIT_CARACTER,
    LIT_CADENA,
    IDENTIFICADOR,

    OP_INC,
    OP_DEC,
    OP_SHL,
    OP_SHR,
    OP_IGUAL,
    OP_DIFERENTE,
    OP_MENOR_IGUAL,
    OP_MAYOR_IGUAL,
    OP_AND,
    OP_OR,
    OP_ASIG_SUMA,
    OP_ASIG_RESTA,
    OP_ASIG_MULT,
    OP_ASIG_DIV,
    OP_ASIG_MOD,

    OP_SUMA,
    OP_RESTA,
    OP_MULT,
    OP_DIV,
    OP_MOD,
    OP_ASIGNACION,
    OP_MENOR,
    OP_MAYOR,
    OP_NOT,
    OP_BIT_NOT,
    OP_BIT_AND,
    OP_BIT_OR,
    OP_BIT_XOR,
    OP_PREGUNTA,
    OP_DOS_PUNTOS,
    OP_PREPROCESADOR,

    DELIM_PAR_IZQ,
    DELIM_PAR_DER,
    DELIM_LLAVE_IZQ,
    DELIM_LLAVE_DER,
    DELIM_COR_IZQ,
    DELIM_COR_DER,
    DELIM_COMA,
    DELIM_PUNTO_COMA,
    DELIM_PUNTO,

    TOKEN_ERROR
};

#endif
