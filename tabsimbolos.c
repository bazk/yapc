#include <stdio.h>
#include <stdlib.h>
#include <string.h>

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

    printf("ID\tNOME\tCAT\tNIVEL LEX.\n");
    for (i=0; i<ts->it; i++) {
        printf("%d\t%s\t%d\t%d\n", i, ts->simbolos[i].nome, ts->simbolos[i].cat, ts->simbolos[i].nivel_lexico);
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