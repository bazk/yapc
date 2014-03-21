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

int num_vars, desloc_counter;
int nivel_lexico;

tab_simbolos_t *ts;

simbolo_t *l_elem;

FILE *out;

#endif