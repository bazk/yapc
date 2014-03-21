#ifndef _COMPILADOR_H_
#define _COMPILADOR_H_

#include "defs.h"
#include "utils.h"
#include "tabsimbolos.h"

struct {
    char *nome;
    int linha;
    int coluna;
    int tam;
} token;

int num_vars, desloc_counter;
int nivel_lexico;

tipos_op op;
pilha_t *O;

tab_simbolos_t *ts;

simbolo_t *l_elem;

pilha_t *E, *T, *F;

FILE *out;

#endif