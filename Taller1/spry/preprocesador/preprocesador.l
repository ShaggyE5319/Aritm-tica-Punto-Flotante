%option noyywrap nodefault
%option yylineno

%{
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "constantes.h"

extern FILE *yyin;

typedef struct {
    char name[PREPROCESADOR_MAX_NAME];
    char value[PREPROCESADOR_MAX_VALUE];
} Macro;

typedef struct {
    YY_BUFFER_STATE buffer;
    FILE *file;
    char directory[PREPROCESADOR_MAX_PATH];
} BufferFrame;

static Macro macros[PREPROCESADOR_MAX_MACROS];
static size_t macro_count = 0;
static BufferFrame include_stack[PREPROCESADOR_MAX_INCLUDE_DEPTH];
static int include_depth = 0;
static char current_directory[PREPROCESADOR_MAX_PATH] = ".";

static void fail(const char *message) {
    fprintf(stderr, "preprocesador: %s\n", message);
    exit(EXIT_FAILURE);
}

static const char *macro_value(const char *name) {
    size_t i;
    for (i = 0; i < macro_count; ++i)
        if (strcmp(macros[i].name, name) == 0)
            return macros[i].value;
    return NULL;
}

static void define_macro(const char *line) {
    char name[PREPROCESADOR_MAX_NAME], value[PREPROCESADOR_MAX_VALUE] = "";
    const char *cursor = line;
    size_t length;

    while (isspace((unsigned char)*cursor)) ++cursor;
    if (strncmp(cursor, "#define", 7) != 0 || !isspace((unsigned char)cursor[7]))
        fail("directiva #define invalida");
    cursor += 7;
    while (isspace((unsigned char)*cursor)) ++cursor;
    length = 0;
    while (cursor[length] && !isspace((unsigned char)cursor[length]) &&
           length + 1 < sizeof(name))
        ++length;
    if (length == 0 || length + 1 == sizeof(name))
        fail("nombre de macro demasiado largo o vacio");
    memcpy(name, cursor, length);
    name[length] = '\0';
    cursor += length;
    while (isspace((unsigned char)*cursor)) ++cursor;
    strncpy(value, cursor, sizeof(value) - 1);
    value[sizeof(value) - 1] = '\0';
    value[strcspn(value, "\r\n")] = '\0';

    for (size_t i = 0; i < macro_count; ++i) {
        if (strcmp(macros[i].name, name) == 0) {
            strncpy(macros[i].value, value, sizeof(macros[i].value) - 1);
            macros[i].value[sizeof(macros[i].value) - 1] = '\0';
            return;
        }
    }
    if (macro_count == PREPROCESADOR_MAX_MACROS)
        fail("se alcanzo el limite de macros");
    strncpy(macros[macro_count].name, name, PREPROCESADOR_MAX_NAME - 1);
    macros[macro_count].name[PREPROCESADOR_MAX_NAME - 1] = '\0';
    strncpy(macros[macro_count].value, value, PREPROCESADOR_MAX_VALUE - 1);
    macros[macro_count].value[PREPROCESADOR_MAX_VALUE - 1] = '\0';
    ++macro_count;
}

static void replace_identifiers(const char *line) {
    const char *cursor = line;
    while (*cursor) {
        if (isalpha((unsigned char)*cursor) || *cursor == '_') {
            char name[PREPROCESADOR_MAX_NAME];
            size_t length = 0;
            while ((isalnum((unsigned char)cursor[length]) ||
                    cursor[length] == '_') && length + 1 < sizeof(name))
                ++length;
            memcpy(name, cursor, length);
            name[length] = '\0';
            fputs(macro_value(name) ? macro_value(name) : name, stdout);
            cursor += length;
        } else {
            putchar(*cursor++);
        }
    }
}

static void directory_of(const char *path, char *directory) {
    const char *slash = strrchr(path, '/');
    const char *backslash = strrchr(path, '\\');
    if (backslash && (!slash || backslash > slash)) slash = backslash;
    if (!slash) {
        strcpy(directory, ".");
        return;
    }
    size_t length = (size_t)(slash - path);
    if (length >= PREPROCESADOR_MAX_PATH) fail("ruta demasiado larga");
    memcpy(directory, path, length);
    directory[length] = '\0';
}

static void include_file(const char *name) {
    char path[PREPROCESADOR_MAX_PATH];
    FILE *file;
    if (include_depth == PREPROCESADOR_MAX_INCLUDE_DEPTH)
        fail("se alcanzo el limite de inclusion");
    if (name[0] == '/' || (strlen(name) > 1 && name[1] == ':'))
        snprintf(path, sizeof(path), "%s", name);
    else
        snprintf(path, sizeof(path), "%s/%s", current_directory, name);
    file = fopen(path, "r");
    if (!file) {
        char message[PREPROCESADOR_MAX_PATH + 64];
        snprintf(message, sizeof(message), "no se pudo abrir '%s': %s",
                 path, strerror(errno));
        fail(message);
    }
    include_stack[include_depth].buffer = YY_CURRENT_BUFFER;
    include_stack[include_depth].file = yyin;
    strncpy(include_stack[include_depth].directory, current_directory,
            PREPROCESADOR_MAX_PATH - 1);
    ++include_depth;
    strncpy(current_directory, path, PREPROCESADOR_MAX_PATH - 1);
    directory_of(path, current_directory);
    yyin = file;
    yy_switch_to_buffer(yy_create_buffer(file, PREPROCESADOR_BUFFER_SIZE));
}
%}

ID [A-Za-z_][A-Za-z0-9_]*

%%

^[ \t]*#[ \t]*include[ \t]*\"([^\"\r\n]+)\"[ \t]*\r?\n {
    char name[PREPROCESADOR_MAX_PATH];
    if (sscanf(yytext, "%*[^\"]\"%1023[^\"]", name) != 1)
        fail("directiva #include invalida");
    include_file(name);
}
^[ \t]*#[ \t]*define[ \t]+{ID}([ \t]+[^\r\n]*)?\r?\n {
    define_macro(yytext);
}
{ID}                         { replace_identifiers(yytext); }
\r?\n                        { ECHO; }
.                            { ECHO; }

<<EOF>> {
    if (include_depth == 0) {
        yyterminate();
    } else {
        yy_delete_buffer(YY_CURRENT_BUFFER);
        fclose(yyin);
        --include_depth;
        yy_switch_to_buffer(include_stack[include_depth].buffer);
        yyin = include_stack[include_depth].file;
        strcpy(current_directory, include_stack[include_depth].directory);
    }
}

%%

int main(int argc, char **argv) {
    if (argc > 2) {
        fprintf(stderr, "Uso: %s [archivo]\n", argv[0]);
        return EXIT_FAILURE;
    }
    if (argc == 2) {
        yyin = fopen(argv[1], "r");
        if (!yyin) {
            perror(argv[1]);
            return EXIT_FAILURE;
        }
        directory_of(argv[1], current_directory);
    }
    yylex();
    if (argc == 2) fclose(yyin);
    return EXIT_SUCCESS;
}
