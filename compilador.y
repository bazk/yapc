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

#define CHECK_TYPE_R(a, b, TIPO) if (a != TIPO || b != TIPO) { \
    yyerror("relação '%s' não pode operar sobre '%s' e '%s'", \
        REL_STR(rel), TIPO_STR(a), TIPO_STR(b)); \
    YYERROR; }

extern int yylex();
%}

%define parse.error verbose

%expect 1

%token PROGRAM ABRE_PARENTESES FECHA_PARENTESES
%token VIRGULA PONTO_E_VIRGULA DOIS_PONTOS PONTO
%token T_BEGIN T_END VAR IDENT ATRIBUICAO
%token PROCEDURE
%token NUMERO
%token OPERADOR_CONJ OPERADOR_DISJ
%token T_TRUE T_FALSE
%token RELACAO
%token WHILE DO
%token IF THEN ELSE

%%

programa:       { geraCodigo(out, NULL, "INPP"); }
                PROGRAM IDENT
                ABRE_PARENTESES lista_idents FECHA_PARENTESES PONTO_E_VIRGULA
                bloco_principal PONTO
                { geraCodigo(out, NULL, "PARA"); };

lista_idents:   lista_idents VIRGULA IDENT |
                IDENT;

bloco_principal: parte_declara_vars
                { geraCodigo(out, NULL, "DSVS main"); }
                declara_procs
                { geraCodigo(out, "main", "NADA"); }
                comando_composto {
                    unsigned int removidos = remove_nivel_ts(ts, nivel_lexico);

                    if (removidos > 0) {
                        geraCodigo(out, NULL, "DMEM %d", removidos);
                    }
                };

bloco:          { nivel_lexico++; }
                parte_declara_vars
                declara_procs
                comando_composto {
                    unsigned int removidos = remove_nivel_ts(ts, nivel_lexico);

                    if (removidos > 0) {
                        geraCodigo(out, NULL, "DMEM %d", removidos);
                    }

                    nivel_lexico--;
                };

parte_declara_vars: VAR { desloc_counter = 0; } declara_vars | %empty;

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

declara_procs:  declara_proc PONTO_E_VIRGULA declara_procs | %empty;

declara_proc:   PROCEDURE IDENT {
                    simbolo_t *simb = insere_ts(ts, token.nome, CAT_PROC, nivel_lexico);
                    sprintf(simb->params.rot, "p%d", rotcounter_proc++);

                    geraCodigo(out, simb->params.rot, "ENPR %d", (nivel_lexico+1));
                } param_formais PONTO_E_VIRGULA bloco {
                    geraCodigo(out, NULL, "RTPR %d, %d", (nivel_lexico+1), 0);
                };

param_formais:  ABRE_PARENTESES lista_params FECHA_PARENTESES | %empty;

lista_params:   lista_params PONTO_E_VIRGULA param | param;

param:          lista_param_vars DOIS_PONTOS param_tipo;

lista_param_vars: param_var VIRGULA lista_param_vars | param_var;

param_var:      IDENT;

param_tipo:     IDENT;

comando_composto: T_BEGIN comandos T_END;

comandos:       comandos PONTO_E_VIRGULA comando | comando;

comando:        NUMERO DOIS_PONTOS comando_sem_rotulo | comando_sem_rotulo;

comando_sem_rotulo:
                comando_composto |
                comando_repetitivo |
                comando_condicional |
                IDENT { strncpy(l_token, token.nome, TAM_TOKEN); } atr_ou_chamada |
                %empty;

atr_ou_chamada: ATRIBUICAO expressao atribuicao |
                lista_parametros chamada_de_procedimento;

atribuicao:     %empty {
                    simbolo_t *l_elem = busca_ts(ts, l_token, CAT_VS, nivel_lexico);
                    tipos_var e = (tipos_var) pilha_pop(E);

                    if (l_elem == NULL) {
                        yyerror("variável '%s' não foi definida", l_token);
                        YYERROR;
                    }

                    if (l_elem->params.tipo != e) {
                        yyerror("expressão retornou tipo '%s' e não pode ser atribuída à variável '%s' do tipo '%s'",
                            TIPO_STR(e), l_elem->nome, TIPO_STR(l_elem->params.tipo));
                        YYERROR;
                    }

                    geraCodigo(out, NULL, "ARMZ %d, %d", l_elem->nivel_lexico, l_elem->params.desloc);
                }

expressao:      expressao_simples RELACAO { pilha_push(R, rel); } expressao_simples {
                    tipos_var ea = (tipos_var) pilha_pop(ES);
                    tipos_var eb = (tipos_var) pilha_pop(ES);
                    tipos_rel rel = (tipos_rel) pilha_pop(R);

                    if (rel == REL_IGUAL || rel == REL_DIFERENTE) {
                        if (ea != eb) {
                            yyerror("relação '%s' não pode operar sobre '%s' e '%s'",
                                REL_STR(rel), TIPO_STR(ea), TIPO_STR(eb));
                            YYERROR;
                        }
                    }
                    else {
                        if (ea != TIPO_INTEGER || ea != eb) {
                            yyerror("relação '%s' não pode operar sobre '%s' e '%s'",
                                REL_STR(rel), TIPO_STR(ea), TIPO_STR(eb));
                            YYERROR;
                        }
                    }

                    switch (rel) {
                        case REL_IGUAL:         geraCodigo(out, NULL, "CMIG"); break;
                        case REL_DIFERENTE:     geraCodigo(out, NULL, "CMDG"); break;
                        case REL_MENOR:         geraCodigo(out, NULL, "CMME"); break;
                        case REL_MENOR_IGUAL:   geraCodigo(out, NULL, "CMEG"); break;
                        case REL_MAIOR:         geraCodigo(out, NULL, "CMMA"); break;
                        case REL_MAIOR_IGUAL:   geraCodigo(out, NULL, "CMAG"); break;
                        default:      yyerror("relação inválida ('%s')", REL_STR(op)); YYERROR; break;
                    }

                    pilha_push(E, TIPO_BOOLEAN);
                } |
                expressao_simples { pilha_push(E, pilha_pop(ES)); };

expressao_simples: expressao_simples OPERADOR_DISJ { pilha_push(O, op); } termo {
                    tipos_var es = (tipos_var) pilha_pop(ES);
                    tipos_var t = (tipos_var) pilha_pop(T);
                    tipos_op op = (tipos_op) pilha_pop(O);

                    switch (op) {
                        case OP_SOMA: CHECK_TYPE(es, t, TIPO_INTEGER); geraCodigo(out, NULL, "SOMA"); break;
                        case OP_SUBT: CHECK_TYPE(es, t, TIPO_INTEGER); geraCodigo(out, NULL, "SUBT"); break;
                        case OP_DISJ: CHECK_TYPE(es, t, TIPO_BOOLEAN); geraCodigo(out, NULL, "DISJ"); break;
                        default:      yyerror("operador inválido ('%s')", OP_STR(op)); YYERROR; break;
                    }

                    pilha_push(ES, es);
                } |
                termo { pilha_push(ES, pilha_pop(T)); };

termo:          termo OPERADOR_CONJ { pilha_push(O, op); } fator {
                    tipos_var t = (tipos_var) pilha_pop(T);
                    tipos_var f = (tipos_var) pilha_pop(F);
                    tipos_op op = (tipos_op) pilha_pop(O);

                    switch (op) {
                        case OP_MULT: CHECK_TYPE(t, f, TIPO_INTEGER); geraCodigo(out, NULL, "MULT"); break;
                        case OP_DIVI: CHECK_TYPE(t, f, TIPO_INTEGER); geraCodigo(out, NULL, "DIVI"); break;
                        case OP_CONJ: CHECK_TYPE(t, f, TIPO_BOOLEAN); geraCodigo(out, NULL, "CONJ"); break;
                        default:      yyerror("operador inválido ('%s')", OP_STR(op)); YYERROR; break;
                    }

                    pilha_push(T, t);
                } |
                fator { pilha_push(T, pilha_pop(F)); };

fator:          ABRE_PARENTESES expressao { pilha_push(F, pilha_pop(E)); } FECHA_PARENTESES |
                IDENT {
                    simbolo_t *simb = busca_ts(ts, token.nome, CAT_VS, nivel_lexico);

                    if (simb == NULL) {
                        yyerror("variável '%s' não foi definida", token.nome);
                        YYERROR;
                    }

                    pilha_push(F, simb->params.tipo);
                    geraCodigo(out, NULL, "CRVL %d, %d", simb->nivel_lexico, simb->params.desloc);
                } |
                NUMERO {
                    pilha_push(F, TIPO_INTEGER);
                    geraCodigo(out, NULL, "CRCT %s", token.nome);
                } |
                T_TRUE {
                    pilha_push(F, TIPO_BOOLEAN);
                    geraCodigo(out, NULL, "CRCT %d", 1);
                } |
                T_FALSE {
                    pilha_push(F, TIPO_BOOLEAN);
                    geraCodigo(out, NULL, "CRCT %d", 0);
                };

lista_expressoes: expressao VIRGULA lista_expressoes | expressao;

lista_parametros: ABRE_PARENTESES lista_expressoes FECHA_PARENTESES | %empty;

chamada_de_procedimento: %empty {
                    simbolo_t *proc = busca_ts(ts, l_token, CAT_PROC, nivel_lexico);

                    if (proc == NULL) {
                        yyerror("procedimento '%s' não foi definido", l_token);
                        YYERROR;
                    }

                    geraCodigo(out, NULL, "CHPR %s, %d", proc->params.rot, nivel_lexico);
                };

comando_repetitivo:
                WHILE {
                    char label[4];
                    sprintf(label, "l%d", rotcounter_loop);

                    geraCodigo(out, label, "NADA");

                    pilha_push(pilha_rot_loop, (int) rotcounter_loop);
                } expressao {
                    tipos_var e = (tipos_var) pilha_pop(E);

                    if (e != TIPO_BOOLEAN) {
                        yyerror("expressão deve retornar 'boolean', retornou '%s'", TIPO_STR(e));
                        YYERROR;
                    }

                    geraCodigo(out, NULL, "DSVF f%d", rotcounter_loop++);
                } DO comando_sem_rotulo {
                    int loop_rot = (int) pilha_pop(pilha_rot_loop);

                    geraCodigo(out, NULL, "DSVS l%d", loop_rot);

                    char label[4];
                    sprintf(label, "f%d", loop_rot);
                    geraCodigo(out, label, "NADA");
                };

comando_condicional:
                IF expressao {
                    tipos_var e = (tipos_var) pilha_pop(E);

                    if (e != TIPO_BOOLEAN) {
                        yyerror("expressão deve retornar 'boolean', retornou '%s'", TIPO_STR(e));
                        YYERROR;
                    }

                    pilha_push(pilha_rot_cond, (int) rotcounter_cond);
                    geraCodigo(out, NULL, "DSVF e%d", rotcounter_cond);
                    rotcounter_cond++;
                } THEN comando_sem_rotulo {
                    int cond_rot = (int) pilha_pop(pilha_rot_cond);

                    geraCodigo(out, NULL, "DSVS s%d", cond_rot);

                    char label[4];
                    sprintf(label, "e%d", cond_rot);
                    geraCodigo(out, label, "NADA");

                    pilha_push(pilha_rot_cond, cond_rot);
                } condicional_else {
                    int cond_rot = (int) pilha_pop(pilha_rot_cond);

                    char label[4];
                    sprintf(label, "s%d", cond_rot);
                    geraCodigo(out, label, "NADA");
                };

condicional_else: ELSE comando_sem_rotulo | %empty;

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
    rotcounter_proc = 0;
    rotcounter_cond = 0;
    rotcounter_loop = 0;

    ts = inicializa_ts();

    E = pilha_inicializa();
    ES = pilha_inicializa();
    T = pilha_inicializa();
    F = pilha_inicializa();
    O = pilha_inicializa();
    R = pilha_inicializa();
    pilha_rot_loop = pilha_inicializa();
    pilha_rot_cond = pilha_inicializa();

    err = yyparse();

    pilha_destroi(E);
    pilha_destroi(ES);
    pilha_destroi(T);
    pilha_destroi(F);
    pilha_destroi(O);
    pilha_destroi(R);
    pilha_destroi(pilha_rot_loop);
    pilha_destroi(pilha_rot_cond);

    destroi_ts(ts);

    fclose(yyin);
    fclose(out);

    exit(err);
}