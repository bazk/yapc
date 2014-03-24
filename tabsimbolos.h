#ifndef _TABSIMBOLOS_H_
#define _TABSIMBOLOS_H_

#include "defs.h"

struct simbolo;

typedef union {
    struct { // CAT_VS && CAT_PARAM
        int desloc;
        tipos_var tipo;
        pass_by by;
        struct simbolo *proc;
    };
    struct { // CAT_PROC
        char rot[4];
        int num_params;
    };
} params_t;

typedef struct simbolo {
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
void define_desloc_params_ts(tab_simbolos_t *ts);

simbolo_t *busca_var_ts(tab_simbolos_t *ts, char *nome, unsigned int nivel_lexico);
int busca_indice_proc_ts(tab_simbolos_t *ts, char *nome, unsigned int nivel_lexico);
simbolo_t *busca_por_indice_ts(tab_simbolos_t *ts, int indice);

unsigned int remove_nivel_ts(tab_simbolos_t *ts, categorias_simb cat, unsigned int nivel_lexico);

#endif