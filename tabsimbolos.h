#ifndef _TABSIMBOLOS_H_
#define _TABSIMBOLOS_H_

#include "defs.h"

struct simbolo;

typedef struct {
    tipos_var tipo;
    pass_by by;
} param_def_t;

typedef struct {
    // CAT_VS || CAT_PF || CAT_FUNC
    int desloc;
    tipos_var tipo;

    // CAT_PF
    pass_by by;

    // CAT_PROC || CAT_FUNC || CAT_LABEL
    char rot[4];

    // CAT_PROC || CAT_FUNC
    int num_params;
    param_def_t *signature;
} params_t;

typedef struct simbolo {
    int idx;
    char nome[TAM_TOKEN];
    categorias_simb cat;
    int nivel_lexico;
    params_t params;
} simbolo_t;

typedef struct {
    int it;
    simbolo_t *simbolos;
} tab_simbolos_t;

tab_simbolos_t *inicializa_ts();
void destroi_ts(tab_simbolos_t *ts);

void imprime_ts(tab_simbolos_t *ts);

simbolo_t *insere_ts(tab_simbolos_t *ts, char *nome, categorias_simb cat, int nivel_lexico);

void define_tipo_ts(tab_simbolos_t *ts, tipos_var tipo, categorias_simb cat);
void define_desloc_params_ts(tab_simbolos_t *ts);

simbolo_t *busca_ts(tab_simbolos_t *ts, char *nome, categorias_simb cat, int nivel_lexico);
simbolo_t *busca_por_idx_ts(tab_simbolos_t *ts, int idx);

void remove_nivel_ts(tab_simbolos_t *ts, int nivel_lexico);

int count_ts(tab_simbolos_t *ts, categorias_simb cat, int nivel_lexico);

#endif