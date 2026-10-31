%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define LINK_ADDRESS 1
#define LINK_WORD    2
#define LINK_NEWLINE 3

char *link_text = NULL;
int linker_lexical_error = 0;

static void save_link_text(void) {
    free(link_text);
    link_text = strdup(yytext);
    if (link_text == NULL) {
        fprintf(stderr, "enlazador: memoria insuficiente\n");
        exit(EXIT_FAILURE);
    }
}
%}

%option noyywrap
%option nodefault
%option yylineno

HEX 0[xX][0-9a-fA-F]+
WORD [0-9a-fA-F]{1,16}

%%

^[ \t]*MEMORIA[^\r\n]*\r?\n     { }
^[ \t]*-+[ \t]*\r?\n             { }
^[ \t]*{HEX}[ \t]*\|             { save_link_text(); return LINK_ADDRESS; }
[ \t]*(0[xX][0-9a-fA-F]+|{WORD})   { save_link_text(); return LINK_WORD; }
\r?\n                             { return LINK_NEWLINE; }
[ \t]+                            { }
.                                  {
    fprintf(stderr, "enlazador: error léxico en línea %d: '%s'\n",
            yylineno, yytext);
    linker_lexical_error = 1;
}

%%
