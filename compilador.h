#ifndef _COMPILADOR_H_
#define _COMPILADOR_H_

#include "defs.h"
#include "tabsimbolos.h"

struct {
    char *nome;
    int linha;
    int coluna;
    int tam;
} token;

int num_vars;
int nivel_lexico;

tab_simbolos_t *ts;

FILE *out;

#endif