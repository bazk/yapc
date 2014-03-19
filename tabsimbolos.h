#ifndef _TABSIMBOLOS_H_
#define _TABSIMBOLOS_H_

#include "compilador.h"

#define TS_CHUNK_SIZE 2

typedef enum {
    CAT_VS
} categorias_simb;

typedef enum {
    TIPO_INTEGER
} tipos_var;

typedef union {
    struct {
        int desloc;
        tipos_var tipo;
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
simbolo_t *insere_ts(tab_simbolos_t *ts, char *nome, categorias_simb cat, unsigned int nivel_lexico);
simbolo_t *busca_ts(tab_simbolos_t *ts, char *nome, categorias_simb cat, unsigned int nivel_lexico);

#endif