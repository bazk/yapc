#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <unistd.h>

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

void yywarning(const char *s, ...) {
    FILE *fp;
    char buf[256];
    va_list args;
    unsigned int count = 1;

    va_start(args, s);

    fprintf(stderr, "%d:%d: warning: ", token.linha, token.coluna);
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
        fprintf(fp, "     ");
    }

    vfprintf(fp, format, args);
    fprintf(fp, "\n");

    va_end(args);
}

pilha_t *pilha_inicializa() {
    pilha_t *p = (pilha_t*) malloc(sizeof(pilha_t));
    p->items = (int*) malloc(PILHA_CHUNK_SIZE * sizeof(int));
    p->it = 0;
    return p;
}

void pilha_destroi(pilha_t *p) {
    free(p->items);
    free(p);
}

void pilha_push(pilha_t *p, int i) {
    p->items[p->it] = i;
    p->it++;

    if ((p->it % PILHA_CHUNK_SIZE) == 0) {
        p->items = (int*) realloc(
                p->items,
                (p->it + TS_CHUNK_SIZE) * sizeof(int));
    }
}

int pilha_pop(pilha_t *p) {
    if (p->it == 0) {
        fprintf(stderr, "warning: pop empty stack\n");
        return -1;
    }

    return p->items[--p->it];
}

int pilha_peek(pilha_t *p) {
    if (p->it == 0) {
        fprintf(stderr, "warning: peeking empty stack\n");
        return -1;
    }

    return p->items[p->it];
}

void pilha_limpa(pilha_t *p) {
    p->it = 0;
}

int pilha_tamanho(pilha_t *p) {
    return p->it;
}
