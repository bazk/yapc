#ifndef _DEFS_H_
#define _DEFS_H_

#define TAM_TOKEN 16
#define TS_CHUNK_SIZE 2
#define PILHA_CHUNK_SIZE 2

typedef enum {
    CAT_VS = 1,
    CAT_PROC = 2,
    CAT_PARAM = 4
} categorias_simb;

static inline char *CAT_STR(categorias_simb cat) {
    if ((cat & CAT_VS) != 0)
        return "VS";

    if ((cat & CAT_PROC) != 0)
        return "PROC";

    if ((cat & CAT_PARAM) != 0)
        return "PARAM";

    return "?";
}

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

typedef enum {
    REL_IGUAL = 0,
    REL_DIFERENTE,
    REL_MENOR,
    REL_MENOR_IGUAL,
    REL_MAIOR,
    REL_MAIOR_IGUAL
} tipos_rel;

static inline char *REL_STR(tipos_rel o) {
    static char *strings[] = {"=", "<>", "<", "<=", ">", ">="};
    return strings[o];
}

#endif