#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "defs.h"
#include "utils.h"
#include "tabsimbolos.h"

#ifdef DEBUG
#define DEBUG_TS
#endif

tab_simbolos_t *inicializa_ts() {
    tab_simbolos_t *ts = (tab_simbolos_t*) malloc(sizeof(tab_simbolos_t));
    ts->simbolos = (simbolo_t*) malloc(TS_CHUNK_SIZE * sizeof(simbolo_t));
    ts->it = 0;
    return ts;
}

void destroi_ts(tab_simbolos_t *ts) {
    free(ts->simbolos);
    free(ts);
}

void imprime_ts(tab_simbolos_t *ts) {
    unsigned int i;

    fprintf(stderr, "================================================================================\n");
    fprintf(stderr, "NOME    CAT     NL      PARAMS\n");
    for (i=0; i<ts->it; i++) {
        fprintf(stderr, "%s\t%s\t%d\t", ts->simbolos[i].nome, CAT_STR(ts->simbolos[i].cat),
            ts->simbolos[i].nivel_lexico);

        fprintf(stderr, "{");

        if (ts->simbolos[i].cat == CAT_VS) {
            fprintf(stderr, "desloc=%d, ", ts->simbolos[i].params.desloc);
            fprintf(stderr, "tipo=%s", TIPO_STR(ts->simbolos[i].params.tipo));
        }
        else if (ts->simbolos[i].cat == CAT_PROC) {
            fprintf(stderr, "rot=%s", ts->simbolos[i].params.rot);
        }
        else if (ts->simbolos[i].cat == CAT_PARAM) {
            fprintf(stderr, "desloc=%d, ", ts->simbolos[i].params.desloc);
            fprintf(stderr, "tipo=%s, ", TIPO_STR(ts->simbolos[i].params.tipo));
            fprintf(stderr, "by=%s, ", BY_STR(ts->simbolos[i].params.by));
            fprintf(stderr, "proc=%s", ts->simbolos[i].params.proc->nome);
        }

        fprintf(stderr, "}\n");
    }
    fprintf(stderr, "================================================================================\n\n");
}

simbolo_t *insere_ts(tab_simbolos_t *ts, char *nome, categorias_simb cat, unsigned int nivel_lexico) {
    strncpy(ts->simbolos[ts->it].nome, nome, TAM_TOKEN);
    ts->simbolos[ts->it].cat = cat;
    ts->simbolos[ts->it].nivel_lexico = nivel_lexico;

    ts->it++;

    if ((ts->it % TS_CHUNK_SIZE) == 0) {
        ts->simbolos = (simbolo_t*) realloc(
                ts->simbolos,
                (ts->it + TS_CHUNK_SIZE) * sizeof(simbolo_t));
    }

#ifdef DEBUG_TS
    fprintf(stderr, "insere_ts(%s, %s, %d)\n", nome, CAT_STR(cat), nivel_lexico);
    imprime_ts(ts);
#endif

    return &ts->simbolos[ts->it-1];
}

int define_tipo_ts(tab_simbolos_t *ts, char *token_tipo, categorias_simb cat) {
    tipos_var tipo;
    int i = (ts->it-1);

    if (strncmp(token_tipo, "integer", TAM_TOKEN) == 0) {
        tipo = TIPO_INTEGER;
    }
    else if (strncmp(token_tipo, "boolean", TAM_TOKEN) == 0) {
        tipo = TIPO_BOOLEAN;
    }
    else {
        return 1;
    }

    while ((i >= 0) && (ts->simbolos[i].params.tipo == TIPO_INDEFINIDO)) {
        if (ts->simbolos[i].cat != cat)
            break;

        ts->simbolos[i].params.tipo = tipo;
        i--;
    }

#ifdef DEBUG_TS
    fprintf(stderr, "define_tipo_ts(%s, %s)\n", token_tipo, CAT_STR(cat));
    imprime_ts(ts);
#endif

    return 0;
}

void define_desloc_params_ts(tab_simbolos_t *ts) {
    int i = (ts->it-1), j = 0;

    while ((i >= 0) && (ts->simbolos[i].cat == CAT_PARAM)) {
        ts->simbolos[i].params.desloc = -4 - j++;
        i--;
    }

#ifdef DEBUG_TS
    fprintf(stderr, "define_desloc_params_ts()\n");
    imprime_ts(ts);
#endif
}

simbolo_t *busca_var_ts(tab_simbolos_t *ts, char *nome, unsigned int nivel_lexico) {
#ifdef DEBUG_TS
    fprintf(stderr, "busca_var_ts(%s, %d)\n", nome, nivel_lexico);
#endif

    for (int i = (ts->it-1); i >= 0; i--) {
        if (ts->simbolos[i].nivel_lexico != nivel_lexico)
            continue;

        if (ts->simbolos[i].cat == CAT_PROC) {
            nivel_lexico--;
            continue;
        }

        if (strncmp(ts->simbolos[i].nome, nome, TAM_TOKEN) == 0) {
            return &ts->simbolos[i];
        }
    }

    return NULL;
}

int busca_indice_proc_ts(tab_simbolos_t *ts, char *nome, unsigned int nivel_lexico) {
#ifdef DEBUG_TS
    fprintf(stderr, "busca_indice_proc_ts(%s, %d)\n", nome, nivel_lexico);
#endif

    for (int i = (ts->it-1); i >= 0; i--) {
        if ( (ts->simbolos[i].cat == CAT_PROC) &&
             (ts->simbolos[i].nivel_lexico <= nivel_lexico) &&
             (strncmp(ts->simbolos[i].nome, nome, TAM_TOKEN) == 0) ) {
            return i;
        }
    }

    return -1;
}

simbolo_t *busca_por_indice_ts(tab_simbolos_t *ts, int indice) {
#ifdef DEBUG_TS
    fprintf(stderr, "busca_por_indice_ts(%d)\n", indice);
#endif

    if ((indice < 0) || (indice >= ts->it)) {
        return NULL;
    }

    return &ts->simbolos[indice];;
}

unsigned int remove_nivel_ts(tab_simbolos_t *ts, categorias_simb cat, unsigned int nivel_lexico) {
    int i = (ts->it-1), count = 0;

    while ((i >= 0) && (ts->simbolos[i].nivel_lexico >= nivel_lexico)) {
        if ((ts->simbolos[i].cat & cat) == 0)
            break;

        count++;
        i--;
    }

    ts->it = ++i;

#ifdef DEBUG_TS
    fprintf(stderr, "remove_nivel_ts(%d, %d)\n", cat, nivel_lexico);
    imprime_ts(ts);
#endif

    return count;
}