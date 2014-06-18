#ifndef _DEFS_H_
#define _DEFS_H_

#define TAM_TOKEN 16
#define TS_CHUNK_SIZE 32
#define PILHA_CHUNK_SIZE 16

typedef enum {
    CAT_VS = 1,
    CAT_PF = 2,
    CAT_PROC = 4,
    CAT_FUNC = 8,
    CAT_LABEL = 16
} categorias_simb;

static inline char *CAT_STR(categorias_simb cat) {
    if ((cat & CAT_VS) != 0)
        return "VS";

    if ((cat & CAT_PF) != 0)
        return "PF";

    if ((cat & CAT_PROC) != 0)
        return "PROC";

    if ((cat & CAT_FUNC) != 0)
        return "FUNC";

    if ((cat & CAT_LABEL) != 0)
        return "LABEL";

    return "?";
}

typedef enum {
    BY_VAR,
    BY_REF
} pass_by;

static inline char *BY_STR(pass_by b) {
    static char *strings[] = {"BY_VAR", "BY_REF"};
    return strings[b];
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

static inline tipos_var TIPO_FROM_STR(char *s) {
    if (strncmp(s, "integer", TAM_TOKEN) == 0) {
        return  TIPO_INTEGER;
    }

    if (strncmp(s, "boolean", TAM_TOKEN) == 0) {
        return TIPO_BOOLEAN;
    }

    return TIPO_INDEFINIDO;
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
