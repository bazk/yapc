#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "defs.h"
#include "tabsimbolos.h"

tab_simbolos_t *inicializa_ts() {
    tab_simbolos_t *ts = (tab_simbolos_t*) malloc(sizeof(tab_simbolos_t));
    ts->simbolos = (simbolo_t*) malloc(TS_CHUNK_SIZE * sizeof(simbolo_t));
    ts->it = 0;
}

void destroi_ts(tab_simbolos_t *ts) {
    free(ts->simbolos);
    free(ts);
}

void imprime_ts(tab_simbolos_t *ts) {
    unsigned int i;

    printf("ID\tNOME\tCAT\tNL\tTIPO\n");
    for (i=0; i<ts->it; i++) {
        printf("%d\t%s\t%d\t%d\t%d\n", i, ts->simbolos[i].nome, ts->simbolos[i].cat,
            ts->simbolos[i].nivel_lexico, ts->simbolos[i].params.tipo);
    }
    printf("\n");
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

    return &ts->simbolos[ts->it-1];
}

int define_tipo_ts(tab_simbolos_t *ts, char *token_tipo) {
    tipos_var tipo;
    int i = (ts->it-1);

    if (strncmp(token_tipo, "integer", TAM_TOKEN) == 0) {
        tipo = TIPO_INTEGER;
    }
    else if (strncmp(token_tipo, "real", TAM_TOKEN) == 0) {
        tipo = TIPO_REAL;
    }
    else {
        return 1;
    }

    while ((i >= 0) && (ts->simbolos[i].params.tipo == TIPO_INDEFINIDO)) {
        if (ts->simbolos[i].cat == CAT_VS)
            ts->simbolos[i].params.tipo = tipo;
        i--;
    }

    return 0;
}

simbolo_t *busca_ts(tab_simbolos_t *ts, char *nome, categorias_simb cat, unsigned int nivel_lexico) {
    unsigned int i;

    for (i = (ts->it-1); i >= 0; i++) {
        if ( (ts->simbolos[i].cat == cat) &&
             (ts->simbolos[i].nivel_lexico == nivel_lexico) &&
             (strncmp(ts->simbolos[i].nome, nome, TAM_TOKEN) == 0) ) {
            return &ts->simbolos[i];
        }
    }

    return NULL;
}

unsigned int remove_nivel_ts(tab_simbolos_t *ts, unsigned int nivel_lexico) {
    int i = (ts->it-1), count = 0;

    while ((i >= 0) && (ts->simbolos[i].nivel_lexico >= nivel_lexico)) {
        if (ts->simbolos[i].cat == CAT_VS)
            count++;

        i--;
    }

    ts->it = ++i;
    return count;
}