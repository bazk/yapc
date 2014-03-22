#ifndef _UTILS_H_
#define _UTILS_H_

#include "defs.h"

typedef struct {
    unsigned int it;
    int *items;
} pilha_t;

void yyerror(const char *s, ...);
void geraCodigo(FILE *fp, const char* label, const char* format, ...);

pilha_t *pilha_inicializa();
void pilha_destroi(pilha_t *p);
void pilha_push(pilha_t *p, int i);
int pilha_pop(pilha_t *p);
int pilha_peek(pilha_t *p);
void pilha_limpa(pilha_t *p);

#endif