#ifndef _DEFS_H_
#define _DEFS_H_

#define TAM_TOKEN 16
#define TS_CHUNK_SIZE 2
#define PILHA_CHUNK_SIZE 2

typedef enum {
    TIPO_INDEFINIDO = 0,
    TIPO_INTEGER,
    TIPO_BOOLEAN
} tipos_var;

static inline char *TIPO_STR(tipos_var o) {
    static char *strings[] = {"?", "integer", "boolean"};
    return strings[o];
}

typedef enum {
    OP_SOMA = 0,
    OP_SUBT,
    OP_DISJ,
    OP_MULT,
    OP_DIVI,
    OP_CONJ
} tipos_op;

static inline char *OP_STR(tipos_op o) {
    static char *strings[] = {"+", "-", "||", "*", "/", "&&"};
    return strings[o];
}

#endif