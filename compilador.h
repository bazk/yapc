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
tipos_rel rel;

tab_simbolos_t *ts;

char l_token[TAM_TOKEN];

pilha_t *ES, *E, *T, *F;
pilha_t *R, *O;
pilha_t *pilha_rot_jump, *pilha_rot_loop, *pilha_rot_cond;
pilha_t *pilha_cham_proc;

FILE *out;

simbolo_t *cur_proc;
pass_by passing_by;

unsigned int rotcounter_proc;
unsigned int rotcounter_cond;
unsigned int rotcounter_loop;

#endif