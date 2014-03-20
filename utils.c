#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>

#include "defs.h"
#include "compilador.h"
#include "compilador.tab.h"
#include "utils.h"

extern FILE *yyin;

void yyerror(const char *s, ...) {
    FILE *fp;
    char buf[256];
    va_list args;
    unsigned int count = 1;

    va_start(args, s);

    fprintf(stderr, "%d:%d: error: ", token.linha, token.coluna);
    vfprintf(stderr, s, args);
    fprintf(stderr, "\n");

    // print the line from the source file
    fp = fdopen(dup(fileno(yyin)), "r");
    if (fp != NULL) {
        rewind(fp);
        while (fgets(buf, sizeof(buf), fp) != NULL) {
            if (count++ == token.linha) {
                fprintf(stderr, buf);
                break;
            }
        }

        for (count=0; count<(token.coluna-1); count++)
            fprintf(stderr, " ");
        fprintf(stderr, "^\n");

        fclose(fp);
    }

    va_end(args);
}

void geraCodigo(FILE *fp, const char* label, const char* format, ...) {
    va_list args;
    va_start(args, format);

    if (label) {
        fprintf(fp, "%s: ", label);
    }
    else {
        fprintf(fp, "    ");
    }

    vfprintf(fp, format, args);
    fprintf(fp, "\n");

    va_end(args);
}