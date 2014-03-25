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
    fprintf(stderr, "================================================================================\n");
    fprintf(stderr, "ID NOME CAT     NL      PARAMS\n");
    for (int i=0; i<ts->it; i++) {
        fprintf(stderr, "%2d %s\t%s\t%d\t", ts->simbolos[i].idx, ts->simbolos[i].nome, CAT_STR(ts->simbolos[i].cat),
            ts->simbolos[i].nivel_lexico);

        fprintf(stderr, "{");

        if (ts->simbolos[i].cat == CAT_VS) {
            fprintf(stderr, "desloc=%d, ", ts->simbolos[i].params.desloc);
            fprintf(stderr, "tipo=%s", TIPO_STR(ts->simbolos[i].params.tipo));
        }
        else if (ts->simbolos[i].cat == CAT_PF) {
            fprintf(stderr, "desloc=%d, ", ts->simbolos[i].params.desloc);
            fprintf(stderr, "tipo=%s, ", TIPO_STR(ts->simbolos[i].params.tipo));
            fprintf(stderr, "by=%s", BY_STR(ts->simbolos[i].params.by));
        }
        else if (ts->simbolos[i].cat == CAT_PROC) {
            fprintf(stderr, "rot=%s, ", ts->simbolos[i].params.rot);
            fprintf(stderr, "num_params=%d", ts->simbolos[i].params.num_params);
        }
        else if (ts->simbolos[i].cat == CAT_FUNC) {
            fprintf(stderr, "desloc=%d, ", ts->simbolos[i].params.desloc);
            fprintf(stderr, "tipo=%s, ", TIPO_STR(ts->simbolos[i].params.tipo));
            fprintf(stderr, "rot=%s, ", ts->simbolos[i].params.rot);
            fprintf(stderr, "num_params=%d", ts->simbolos[i].params.num_params);
        }

        if ((ts->simbolos[i].cat == CAT_PROC) || (ts->simbolos[i].cat == CAT_FUNC)) {
            fprintf(stderr, ", params=[ ");
            if (ts->simbolos[i].params.signature == NULL) {
                fprintf(stderr, "NULL ");
            }
            else {
                for (int j=0; j<ts->simbolos[i].params.num_params; j++) {
                    if (ts->simbolos[i].params.signature[j].by == BY_REF)
                        fprintf(stderr, "&");
                    fprintf(stderr, "%s ", TIPO_STR(ts->simbolos[i].params.signature[j].tipo));
                }
            }
            fprintf(stderr, "]");
        }

        fprintf(stderr, "}\n");
    }
    fprintf(stderr, "================================================================================\n\n");
}

simbolo_t *insere_ts(tab_simbolos_t *ts, char *nome, categorias_simb cat, int nivel_lexico) {
    ts->simbolos[ts->it].idx = ts->it;
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

void define_tipo_ts(tab_simbolos_t *ts, tipos_var tipo, categorias_simb cat) {
#ifdef DEBUG_TS
    fprintf(stderr, "define_tipo_ts(%s, %s)\n", TIPO_STR(tipo), CAT_STR(cat));
#endif

    for (int i = (ts->it-1); i >= 0; i--) {
        if ((ts->simbolos[i].params.tipo == TIPO_INDEFINIDO) &&
            ((ts->simbolos[i].cat & cat) != 0))
            ts->simbolos[i].params.tipo = tipo;
    }

#ifdef DEBUG_TS
    imprime_ts(ts);
#endif
}

void define_desloc_params_ts(tab_simbolos_t *ts) {
    int j = 0;

    for (int i = (ts->it-1); i >= 0; i--) {
        if ( (ts->simbolos[i].cat != CAT_PF) &&
             (ts->simbolos[i].cat != CAT_FUNC) )
            break;

        ts->simbolos[i].params.desloc = -4 - j++;
    }

#ifdef DEBUG_TS
    fprintf(stderr, "define_desloc_params_ts()\n");
    imprime_ts(ts);
#endif
}

simbolo_t *busca_ts(tab_simbolos_t *ts, char *nome, categorias_simb cat, int nivel_lexico) {
#ifdef DEBUG_TS
    fprintf(stderr, "busca_ts(%s, %d, %d)\n", nome, cat, nivel_lexico);
#endif

    for (int i = (ts->it-1); i >= 0; i--) {
        if (ts->simbolos[i].nivel_lexico > nivel_lexico) {
            yywarning("simbolo com nivel lexico maior do que o informado na busca");
            break;
        }

        if (((ts->simbolos[i].cat & cat) != 0) &&
            (strncmp(ts->simbolos[i].nome, nome, TAM_TOKEN) == 0)) {
            return &ts->simbolos[i];
        }
    }

    return NULL;
}

simbolo_t *busca_por_idx_ts(tab_simbolos_t *ts, int idx) {
#ifdef DEBUG_TS
    fprintf(stderr, "busca_por_idx_ts(%d)\n", idx);
#endif

    if ((idx < 0) || (idx >= ts->it)) {
        yywarning("busca_por_idx_ts chamado com idx inválido");
        return NULL;
    }

    return &ts->simbolos[idx];;
}

int remove_nivel_ts(tab_simbolos_t *ts, categorias_simb cat, int nivel_lexico) {
    int count = 0;

    for (int i = (ts->it-1); i >= 0; i--) {
        if ((ts->simbolos[i].nivel_lexico < nivel_lexico) ||
            ((ts->simbolos[i].cat & cat) == 0))
            break;

        count++;
    }

    ts->it -= count;

#ifdef DEBUG_TS
    fprintf(stderr, "remove_nivel_ts(%d, %d)\n", cat, nivel_lexico);
    imprime_ts(ts);
#endif

    return count;
}