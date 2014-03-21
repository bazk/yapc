%{
#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include "defs.h"
#include "compilador.h"
#include "tabsimbolos.h"
#include "utils.h"

#define CHECK_TYPE(a, b, TIPO) if (a != TIPO || b != TIPO) { \
    yyerror("operador '%s' não pode operar sobre '%s' e '%s'", \
        OP_STR(op), TIPO_STR(a), TIPO_STR(b)); \
    YYERROR; }

extern int yylex();
%}
%define parse.error verbose

%token PROGRAM ABRE_PARENTESES FECHA_PARENTESES
%token VIRGULA PONTO_E_VIRGULA DOIS_PONTOS PONTO
%token T_BEGIN T_END VAR IDENT ATRIBUICAO
%token PROCEDURE
%token NUMERO
%token OPERADOR_CONJ OPERADOR_DISJ
%token T_TRUE T_FALSE

%%

programa:       { geraCodigo(out, NULL, "INPP"); }
                PROGRAM IDENT
                ABRE_PARENTESES lista_idents FECHA_PARENTESES PONTO_E_VIRGULA
                bloco PONTO
                { geraCodigo(out, NULL, "PARA"); };

lista_idents:   lista_idents VIRGULA IDENT |
                IDENT;

bloco:          parte_declara_vars
                declara_procs
                comando_composto;

parte_declara_vars: VAR { desloc_counter = 0; } declara_vars | ;

declara_vars:   declara_var declara_vars | declara_var;

declara_var:    { num_vars = 0; }
                lista_var DOIS_PONTOS tipo PONTO_E_VIRGULA
                { geraCodigo(out, NULL, "AMEM %d", num_vars); };

lista_var:      var VIRGULA lista_var | var;

var:            IDENT {
                    simbolo_t *simb = insere_ts(ts, token.nome, CAT_VS, nivel_lexico);
                    simb->params.desloc = desloc_counter++;
                    num_vars++;
                };

tipo:           IDENT {
                    if (define_tipo_ts(ts, token.nome) != 0) {
                        yyerror("'%s' não é tipo de variável válido", token.nome);
                        YYERROR;
                    }
                };

declara_procs:  declara_proc PONTO_E_VIRGULA declara_procs | ;

declara_proc:   PROCEDURE IDENT {
                    insere_ts(ts, token.nome, CAT_PROC, nivel_lexico);
                } param_formais PONTO_E_VIRGULA {
                    nivel_lexico++;
                } bloco;

param_formais:  ABRE_PARENTESES lista_params FECHA_PARENTESES | ;

lista_params:   lista_params PONTO_E_VIRGULA param | param;

param:          lista_param_vars DOIS_PONTOS param_tipo;

lista_param_vars: param_var VIRGULA lista_param_vars | param_var;

param_var:      IDENT;

param_tipo:     IDENT;

comando_composto: T_BEGIN comandos T_END {
                    unsigned int removidos = remove_nivel_ts(ts, nivel_lexico);

                    if (removidos > 0) {
                        geraCodigo(out, NULL, "DMEM %d", removidos);
                    }

                    nivel_lexico--;
                };

comandos:       comandos PONTO_E_VIRGULA comando | comando;

comando:        atribuicao | ;

atribuicao:     IDENT {
                    l_elem = busca_ts(ts, token.nome, CAT_VS, nivel_lexico);

                    if (l_elem == NULL) {
                        yyerror("variável '%s' não foi definida", token.nome);
                        YYERROR;
                    }
                } ATRIBUICAO expressao {
                    tipos_var e = (tipos_var) pilha_pop(E);

                    if (l_elem->params.tipo != e) {
                        yyerror("expressão retornou tipo '%s' e não pode ser atribuída à variável '%s' do tipo '%s'",
                            TIPO_STR(e), l_elem->nome, TIPO_STR(l_elem->params.tipo));
                        YYERROR;
                    }

                    geraCodigo(out, NULL, "ARMZ %d, %d", l_elem->nivel_lexico, l_elem->params.desloc);
                };

expressao:      expressao OPERADOR_DISJ { pilha_push(O, (void*) op); } termo {
                    tipos_var e = (tipos_var) pilha_pop(E);
                    tipos_var t = (tipos_var) pilha_pop(T);
                    tipos_op op = (tipos_op) pilha_pop(O);

                    switch (op) {
                        case OP_SOMA: CHECK_TYPE(e, t, TIPO_INTEGER); geraCodigo(out, NULL, "SOMA"); break;
                        case OP_SUBT: CHECK_TYPE(e, t, TIPO_INTEGER); geraCodigo(out, NULL, "SUBT"); break;
                        case OP_DISJ: CHECK_TYPE(e, t, TIPO_BOOLEAN); geraCodigo(out, NULL, "DISJ"); break;
                        default:      yyerror("operador inválido ('%s')", OP_STR(op)); YYERROR; break;
                    }

                    pilha_push(E, (void*) e);
                } |
                termo { pilha_push(E, pilha_pop(T)); };

termo:          termo OPERADOR_CONJ { pilha_push(O, (void*) op); } fator {
                    tipos_var t = (tipos_var) pilha_pop(T);
                    tipos_var f = (tipos_var) pilha_pop(F);
                    tipos_op op = (tipos_op) pilha_pop(O);

                    switch (op) {
                        case OP_MULT: CHECK_TYPE(t, f, TIPO_INTEGER); geraCodigo(out, NULL, "MULT"); break;
                        case OP_DIVI: CHECK_TYPE(t, f, TIPO_INTEGER); geraCodigo(out, NULL, "DIVI"); break;
                        case OP_CONJ: CHECK_TYPE(t, f, TIPO_BOOLEAN); geraCodigo(out, NULL, "CONJ"); break;
                        default:      yyerror("operador inválido ('%s')", OP_STR(op)); YYERROR; break;
                    }

                    pilha_push(T, (void*) t);
                } |
                fator { pilha_push(T, pilha_pop(F)); };

fator:          ABRE_PARENTESES expressao { pilha_push(F, pilha_pop(E)); } FECHA_PARENTESES |
                IDENT {
                    simbolo_t *simb = busca_ts(ts, token.nome, CAT_VS, nivel_lexico);

                    if (simb == NULL) {
                        yyerror("variável '%s' não foi definida", token.nome);
                        YYERROR;
                    }

                    pilha_push(F, (void*) simb->params.tipo);
                    geraCodigo(out, NULL, "CRVL %d, %d", simb->nivel_lexico, simb->params.desloc);
                } |
                NUMERO {
                    pilha_push(F, (void*) TIPO_INTEGER);
                    geraCodigo(out, NULL, "CRCT %s", token.nome);
                } |
                T_TRUE {
                    pilha_push(F, (void*) TIPO_BOOLEAN);
                    geraCodigo(out, NULL, "CRCT %d", 1);
                } |
                T_FALSE {
                    pilha_push(F, (void*) TIPO_BOOLEAN);
                    geraCodigo(out, NULL, "CRCT %d", 0);
                };

%%

int main(int argc, char* argv[]) {
    unsigned int err = 0;

    extern FILE *yyin;

    if (argc != 2) {
        printf("usage:\n\tcompilador FILE\n\n");
        exit(-1);
    }

    yyin = fopen(argv[1], "r");
    if (yyin == NULL) {
        printf("error: cannot open file %s.\n", argv[1]);
        exit(-2);
    }

    out = fopen("MEPA", "w");
    if (out == NULL) {
        printf("error: cannot open MEPA file for output.\n");
        exit(-3);
    }

    nivel_lexico = 0;
    ts = inicializa_ts();

    E = pilha_inicializa();
    T = pilha_inicializa();
    F = pilha_inicializa();
    O = pilha_inicializa();

    err = yyparse();

    pilha_destroi(E);
    pilha_destroi(T);
    pilha_destroi(F);
    pilha_destroi(O);

    destroi_ts(ts);

    fclose(yyin);
    fclose(out);

    exit(err);
}