#ifndef _TABSIMBOLOS_H_
#define _TABSIMBOLOS_H_

#include "defs.h"

typedef union {
    struct {
        int desloc;
        tipos_var tipo;
    };
    struct {
        char rot[4];
    };
} params_t;

typedef struct {
    char nome[TAM_TOKEN];
    categorias_simb cat;
    int nivel_lexico;
    params_t params;
} simbolo_t;

typedef struct {
    unsigned int it;
    simbolo_t *simbolos;
} tab_simbolos_t;

tab_simbolos_t *inicializa_ts();
void destroi_ts(tab_simbolos_t *ts);

void imprime_ts(tab_simbolos_t *ts);

simbolo_t *insere_ts(tab_simbolos_t *ts, char *nome, categorias_simb cat, unsigned int nivel_lexico);
int define_tipo_ts(tab_simbolos_t *ts, char *token_tipo, categorias_simb cat);
simbolo_t *busca_ts(tab_simbolos_t *ts, char *nome, categorias_simb cat, unsigned int nivel_lexico);
unsigned int remove_nivel_ts(tab_simbolos_t *ts, unsigned int nivel_lexico);

#endif