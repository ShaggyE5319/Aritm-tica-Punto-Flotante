%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define TOKEN_INSTRUCTION 1
#define TOKEN_REGISTER    2
#define TOKEN_NUMBER      3
#define TOKEN_LABEL_DEF   4
#define TOKEN_LABEL_REF   5
#define TOKEN_DIRECTIVE   6
#define TOKEN_COMMA       7
#define TOKEN_NEWLINE     8
#define TOKEN_DATA_DIRECTIVE 9
#define TOKEN_LBRACKET    10
#define TOKEN_RBRACKET    11
#define TOKEN_COLON       12

extern char* token_val;
int lexical_error = 0;

static void set_token(const char *value) {
    token_val = strdup(value);
    if (token_val == NULL) {
        fprintf(stderr, "Error léxico: memoria insuficiente\n");
        exit(EXIT_FAILURE);
    }
}

static void report_lexical_error(const char *value) {
    fprintf(stderr, "Error léxico en la línea %d: símbolo no reconocido '%s'\n",
            yylineno, value);
    lexical_error = 1;
}
%}

%option noyywrap
%option nodefault
%option yylineno
%option caseless

DIGIT       [0-9]
HEX_DIGIT   [0-9a-f]
ID          [a-z_][a-z0-9_]*
REGISTER    \$?[r]([0-9]|1[0-5])
NUMBER      \#?(0x{HEX_DIGIT}+|{DIGIT}+)
INSTRUCTION ADD|SUB|MUL|DIV|MOD|ADDI|SUBI|MULI|INC|DEC|AND|OR|XOR|NOT|CMP|SHL|SHR|ANDI|ORI|TEST|LOAD|STORE|MOV|LOADA|LOADR|STORER|PUSH|POP|LDI|LDP|JMP|JZ|JNZ|JG|JL|CALL|RET|HLT|IN|OUT|NET_SEND|NET_RECV|WAIT_I|WAIT_IO|INT_EN|FADD|FSUB|FMUL|FDIV|FSQRT|FUNPACK|FHERON|FITOF

%%

";".*                   { /* Comentario de línea. */ }
[ \t\f\v]+              { /* Separadores horizontales. */ }
\r?\n                   { return TOKEN_NEWLINE; }
","                     { set_token(yytext); return TOKEN_COMMA; }
"["                     { set_token(yytext); return TOKEN_LBRACKET; }
"]"                     { set_token(yytext); return TOKEN_RBRACKET; }
":"                     { set_token(yytext); return TOKEN_COLON; }

"ORG"                   { set_token(yytext); return TOKEN_DIRECTIVE; }
".QUAD"|".WORD"         { set_token(yytext); return TOKEN_DATA_DIRECTIVE; }

{INSTRUCTION} {
    set_token(yytext);
    return TOKEN_INSTRUCTION;
}

"SP"                    { set_token("R13"); return TOKEN_REGISTER; }
"LR"                    { set_token("R14"); return TOKEN_REGISTER; }
{REGISTER}              { set_token(yytext); return TOKEN_REGISTER; }
{NUMBER}                { set_token(yytext); return TOKEN_NUMBER; }
{ID}":"                 { set_token(yytext); return TOKEN_LABEL_DEF; }
{ID}                    { set_token(yytext); return TOKEN_LABEL_REF; }

.                       { report_lexical_error(yytext); }

%%
