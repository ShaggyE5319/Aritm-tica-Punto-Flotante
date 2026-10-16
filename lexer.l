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

extern char* token_val;
extern int token_type;
%}

%option noyywrap

%%

";".*                   { /* Ignorar comentarios */ }
[ \t]+                  { /* Ignorar espacios */ }
\r?\n                   { return TOKEN_NEWLINE; }
","                     { return TOKEN_COMMA; }

"ORG"|"org"             { token_val = strdup(yytext); return TOKEN_DIRECTIVE; }

"ADD"|"SUB"|"MUL"|"DIV"|"MOD"|"ADDI"|"SUBI"|"MULI"|"INC"|"DEC"|"AND"|"OR"|"XOR"|"NOT"|"CMP"|"SHL"|"SHR"|"ANDI"|"ORI"|"TEST"|"LOAD"|"STORE"|"MOV"|"LOADA"|"STORER"|"PUSH"|"POP"|"LDI"|"LDP"|"JMP"|"JZ"|"JNZ"|"JG"|"JL"|"CALL"|"RET"|"HLT"|"IN"|"OUT"|"NET_SEND"|"NET_RECV"|"WAIT_I"|"INT_EN" {
    token_val = strdup(yytext);
    return TOKEN_INSTRUCTION;
}

\$?[rR](1[0-5]|[0-9])   { token_val = strdup(yytext); return TOKEN_REGISTER; }
"SP"|"sp"               { token_val = strdup("R13"); return TOKEN_REGISTER; }
"LR"|"lr"               { token_val = strdup("R14"); return TOKEN_REGISTER; }

[a-zA-Z_][a-zA-Z0-9_]*: { token_val = strdup(yytext); return TOKEN_LABEL_DEF; }

"#"?0x[0-9a-fA-F]+      { token_val = strdup(yytext); return TOKEN_NUMBER; }
"#"?[0-9]+              { token_val = strdup(yytext); return TOKEN_NUMBER; }

[a-zA-Z_][a-zA-Z0-9_]*  { token_val = strdup(yytext); return TOKEN_LABEL_REF; }

.                       { printf("Error Léxico: '%s'\n", yytext); }

%%

