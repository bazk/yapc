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

int rotcounter = 0;
#define NOVO_ROTULO rotcounter++

extern int yylex();
%}

%define parse.error verbose

%token PROGRAM ABRE_PARENTESES FECHA_PARENTESES
%token VIRGULA PONTO_E_VIRGULA DOIS_PONTOS PONTO
%token T_BEGIN T_END VAR IDENT ATRIBUICAO
%token PROCEDURE FUNCTION
%token NUMERO
%token OPERADOR_CONJ OPERADOR_DISJ
%token T_TRUE T_FALSE
%token RELACAO
%token WHILE DO
%token IF THEN ELSE
%token READ WRITE

%precedence LOWER_THAN_ELSE
%precedence ELSE

%%

programa:       { nivel_lexico = -1; geraCodigo(out, NULL, "INPP"); }
                PROGRAM IDENT
                ABRE_PARENTESES lista_idents FECHA_PARENTESES PONTO_E_VIRGULA
                bloco PONTO
                { geraCodigo(out, NULL, "PARA"); };

lista_idents:   lista_idents VIRGULA IDENT |
                IDENT;

bloco:          { nivel_lexico++; }
                parte_declara_vars
                {
                    int rot = NOVO_ROTULO;
                    pilha_push(pilha_rot_jump, rot);
                    geraCodigo(out, NULL, "DSVS R%02d", rot);
                }
                declara_funcs_procs
                {
                    char label[4];
                    sprintf(label, "R%02d", pilha_pop(pilha_rot_jump));
                    geraCodigo(out, label, "NADA");
                }
                comando_composto {
                    remove_nivel_ts(ts, CAT_PROC | CAT_FUNC, nivel_lexico);

                    int removidos = remove_nivel_ts(ts, CAT_VS, nivel_lexico);

                    if (removidos > 0) {
                        geraCodigo(out, NULL, "DMEM %d", removidos);
                    }

                    remove_nivel_ts(ts, CAT_PF, nivel_lexico);

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
                    tipos_var tipo = TIPO_FROM_STR(token.nome);

                    if (tipo == TIPO_INDEFINIDO) {
                        yyerror("'%s' não é um tipo válido", token.nome);
                        YYERROR;
                    }

                    define_tipo_ts(ts, tipo, CAT_VS);
                };

declara_funcs_procs: declara_func_proc PONTO_E_VIRGULA declara_funcs_procs | %empty;

declara_func_proc: declara_func | declara_proc;

declara_proc:   PROCEDURE IDENT {
                    cur_proc = insere_ts(ts, token.nome, CAT_PROC, nivel_lexico);
                    cur_proc->params.num_params = 0;

                    sprintf(cur_proc->params.rot, "R%02d", NOVO_ROTULO);
                    geraCodigo(out, cur_proc->params.rot, "ENPR %d", nivel_lexico+1);
                } declara_param_formais PONTO_E_VIRGULA bloco fim_proc_func;

declara_func:   FUNCTION IDENT {
                    cur_proc = insere_ts(ts, token.nome, CAT_FUNC, nivel_lexico);
                    cur_proc->params.num_params = 0;

                    sprintf(cur_proc->params.rot, "R%02d", NOVO_ROTULO);
                    geraCodigo(out, cur_proc->params.rot, "ENPR %d", nivel_lexico+1);
                } declara_param_formais DOIS_PONTOS IDENT {
                    cur_proc->params.tipo = TIPO_FROM_STR(token.nome);

                    if (cur_proc->params.tipo == TIPO_INDEFINIDO) {
                        yyerror("'%s' não é um tipo válido", token.nome);
                        YYERROR;
                    }
                } PONTO_E_VIRGULA bloco fim_proc_func;

declara_param_formais: param_formais {
                    define_desloc_params_ts(ts);

                    cur_proc->params.signature = (param_def_t*) malloc(cur_proc->params.num_params * sizeof(param_def_t));

                    for (int i = 0; i < cur_proc->params.num_params; i++) {
                        simbolo_t *p = busca_por_idx_ts(ts, cur_proc->idx + i + 1);

                        if (p == NULL) {
                            yyerror("erro interno: parâmetros faltando na tabela de simbolos");
                            YYERROR;
                        }

                        cur_proc->params.signature[i].tipo = p->params.tipo;
                        cur_proc->params.signature[i].by = p->params.by;
                    }

                    imprime_ts(ts);
                }

param_formais:  ABRE_PARENTESES lista_params FECHA_PARENTESES | %empty;

lista_params:   lista_params PONTO_E_VIRGULA param | param;

param:          VAR { passing_by = BY_REF; } lista_param_vars DOIS_PONTOS param_tipo |
                { passing_by = BY_VAR; } lista_param_vars DOIS_PONTOS param_tipo;

lista_param_vars: param_var VIRGULA lista_param_vars | param_var;

param_var:      IDENT {
                    simbolo_t *param = insere_ts(ts, token.nome, CAT_PF, nivel_lexico+1);
                    param->params.by = passing_by;
                    cur_proc->params.num_params++;
                };

param_tipo:     IDENT {
                    tipos_var tipo = TIPO_FROM_STR(token.nome);

                    if (tipo == TIPO_INDEFINIDO) {
                        yyerror("'%s' não é um tipo válido", token.nome);
                        YYERROR;
                    }

                    define_tipo_ts(ts, tipo, CAT_PF);
                };

fim_proc_func:  %empty {
                    geraCodigo(out, NULL, "RTPR %d, %d", nivel_lexico+1, cur_proc->params.num_params);
                }

comando_composto: T_BEGIN comandos T_END;

comandos:       comandos PONTO_E_VIRGULA comando | comando;

comando:        NUMERO DOIS_PONTOS comando_sem_rotulo | comando_sem_rotulo;

comando_sem_rotulo:
                comando_composto |
                comando_repetitivo |
                comando_condicional |
                write |
                read |
                left_elem |
                %empty;

left_elem:      IDENT { strncpy(l_token, token.nome, TAM_TOKEN); } atr_ou_chamada;

atr_ou_chamada: ATRIBUICAO atribuicao |
                chamada_de_procedimento;

atribuicao:     expressao {
                    simbolo_t *l_elem = busca_ts(ts, l_token, CAT_VS | CAT_PF | CAT_FUNC, nivel_lexico);
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

                    if ((l_elem->cat == CAT_PF) && (l_elem->params.by == BY_REF))
                        geraCodigo(out, NULL, "ARMI %d, %d", l_elem->nivel_lexico, l_elem->params.desloc);
                    else if (l_elem->cat == CAT_FUNC)
                        geraCodigo(out, NULL, "ARMZ %d, %d", l_elem->nivel_lexico+1, l_elem->params.desloc);
                    else
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
                    single_var = 0;
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
                    single_var = 0;
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
                    single_var = 0;
                } |
                fator { pilha_push(T, pilha_pop(F)); };

fator:          ABRE_PARENTESES expressao { pilha_push(F, pilha_pop(E)); } FECHA_PARENTESES |
                IDENT var_ou_func |
                NUMERO {
                    pilha_push(F, TIPO_INTEGER);
                    geraCodigo(out, NULL, "CRCT %s", token.nome);
                    single_var = 0;
                } |
                T_TRUE {
                    pilha_push(F, TIPO_BOOLEAN);
                    geraCodigo(out, NULL, "CRCT %d", 1);
                    single_var = 0;
                } |
                T_FALSE {
                    pilha_push(F, TIPO_BOOLEAN);
                    geraCodigo(out, NULL, "CRCT %d", 0);
                    single_var = 0;
                };

var_ou_func:    {
                    simbolo_t *simb = busca_ts(ts, token.nome, CAT_VS | CAT_PF | CAT_FUNC, nivel_lexico);

                    if (simb == NULL) {
                        yyerror("variável/função '%s' não foi definida", token.nome);
                        YYERROR;
                    }

                    if (simb->cat == CAT_FUNC) {
                        geraCodigo(out, NULL, "AMEM 1"); // for the return value
                    }

                    pilha_push(pilha_cham_proc, simb->idx);
                    pilha_push(pilha_cham_proc, 0);
                } lista_parametros {
                    int param_id = pilha_pop(pilha_cham_proc);
                    int simb_id = pilha_pop(pilha_cham_proc);

                    simbolo_t *simb = busca_por_idx_ts(ts, simb_id);

                    if (simb == NULL) {
                        yyerror("erro interno: function not found by id");
                        YYERROR;
                    }

                    if (simb->cat == CAT_FUNC) {
                        if (simb->params.num_params != param_id) {
                            yyerror("função '%s' aceita %d parâmetros, foram passados %d",
                                simb->nome, simb->params.num_params, param_id);
                            YYERROR;
                        }

                        geraCodigo(out, NULL, "CHPR %s, %d", simb->params.rot, nivel_lexico);
                    }
                    else {
                        if (param_id > 0) {
                            yyerror("'%s' não é uma função", simb->nome);
                            YYERROR;
                        }

                        if (pilha_tamanho(pilha_cham_proc) > 0) {
                            if ((simb->cat == CAT_PF) && (simb->params.by == BY_REF)) {
                                geraCodigo(out, NULL, "CRVL %d, %d", simb->nivel_lexico, simb->params.desloc);
                            }
                            else {
                                int param_id = pilha_pop(pilha_cham_proc);
                                int proc_id = pilha_pop(pilha_cham_proc);

                                simbolo_t *proc = busca_por_idx_ts(ts, proc_id);

                                if (proc == NULL) {
                                    yyerror("erro interno: procedure not found by id");
                                    YYERROR;
                                }

                                if (param_id >= proc->params.num_params) {
                                    yyerror("o procedimento/função '%s' aceita %d parâmetros, foram passados %d",
                                        proc->nome, proc->params.num_params, param_id);
                                    YYERROR;
                                }

                                if (proc->params.signature[param_id].by == BY_REF)
                                    geraCodigo(out, NULL, "CREN %d, %d", simb->nivel_lexico, simb->params.desloc);
                                else
                                    geraCodigo(out, NULL, "CRVL %d, %d", simb->nivel_lexico, simb->params.desloc);

                                pilha_push(pilha_cham_proc, proc_id);
                                pilha_push(pilha_cham_proc, param_id);
                            }
                        }
                        else {
                            if ((simb->cat == CAT_PF) && (simb->params.by == BY_REF))
                                geraCodigo(out, NULL, "CRVI %d, %d", simb->nivel_lexico, simb->params.desloc);
                            else
                                geraCodigo(out, NULL, "CRVL %d, %d", simb->nivel_lexico, simb->params.desloc);
                        }
                    }

                    pilha_push(F, simb->params.tipo);
                };

write:          WRITE lista_parametros_write;

lista_parametros_write:
                ABRE_PARENTESES lista_expressoes_write FECHA_PARENTESES |
                ABRE_PARENTESES FECHA_PARENTESES |
                %empty;

lista_expressoes_write:
                lista_expressoes_write VIRGULA expressao_write | expressao_write;

expressao_write: expressao {
                    tipos_var e = (tipos_var) pilha_pop(E);

                    if (e != TIPO_INTEGER) {
                        yyerror("procedimento 'write' não pode operar sobre '%s'", TIPO_STR(e));
                        YYERROR;
                    }

                    geraCodigo(out, NULL, "IMPR");
                };

read:           READ lista_parametros_read;

lista_parametros_read:
                ABRE_PARENTESES lista_variaveis_read FECHA_PARENTESES |
                ABRE_PARENTESES FECHA_PARENTESES |
                %empty;

lista_variaveis_read:
                lista_variaveis_read VIRGULA variavel_read | variavel_read;

variavel_read:  IDENT {
                    simbolo_t *simb = busca_ts(ts, token.nome, CAT_VS | CAT_PF, nivel_lexico);

                    if (simb == NULL) {
                        yyerror("variável '%s' não foi definida", token.nome);
                        YYERROR;
                    }

                    if (simb->params.tipo != TIPO_INTEGER) {
                        yyerror("procedimento 'read' não pode operar sobre '%s'", TIPO_STR(simb->params.tipo));
                        YYERROR;
                    }

                    geraCodigo(out, NULL, "LEIT");

                    if ((simb->cat == CAT_PF) && (simb->params.by == BY_REF))
                        geraCodigo(out, NULL, "ARMI %d, %d", simb->nivel_lexico, simb->params.desloc);
                    else if (simb->cat == CAT_FUNC)
                        geraCodigo(out, NULL, "ARMZ %d, %d", simb->nivel_lexico+1, simb->params.desloc);
                    else
                        geraCodigo(out, NULL, "ARMZ %d, %d", simb->nivel_lexico, simb->params.desloc);
                };

chamada_de_procedimento: {
                    simbolo_t *proc = busca_ts(ts, l_token, CAT_PROC, nivel_lexico);

                    if (proc == NULL) {
                        yyerror("procedimento '%s' não foi definido", l_token);
                        YYERROR;
                    }

                    pilha_push(pilha_cham_proc, proc->idx);
                    pilha_push(pilha_cham_proc, 0);
                }
                lista_parametros {
                    int param_id = pilha_pop(pilha_cham_proc);
                    int proc_id = pilha_pop(pilha_cham_proc);

                    simbolo_t *proc = busca_por_idx_ts(ts, proc_id);

                    if (proc == NULL) {
                        yyerror("erro interno: procedure not found by id");
                        YYERROR;
                    }

                    if (proc->params.num_params != param_id) {
                        yyerror("procedimento '%s' aceita %d parâmetros, foram passados %d",
                            proc->nome, proc->params.num_params, param_id);
                        YYERROR;
                    }

                    geraCodigo(out, NULL, "CHPR %s, %d", proc->params.rot, nivel_lexico);
                };

lista_parametros:
                ABRE_PARENTESES lista_exp_proc FECHA_PARENTESES |
                ABRE_PARENTESES FECHA_PARENTESES |
                 %empty;

lista_exp_proc:  lista_exp_proc VIRGULA expressao_proc | expressao_proc;

expressao_proc: { single_var = 1; } expressao {
                    tipos_var e = (tipos_var) pilha_pop(E);
                    int param_id = pilha_pop(pilha_cham_proc);
                    int proc_id = pilha_pop(pilha_cham_proc);

                    simbolo_t *proc = busca_por_idx_ts(ts, proc_id);

                    if (proc == NULL) {
                        yyerror("erro interno: procedure not found by id");
                        YYERROR;
                    }

                    if (param_id >= proc->params.num_params) {
                        yyerror("o procedimento '%s' aceita %d parâmetros, foram passados %d",
                            proc->nome, proc->params.num_params, param_id);
                        YYERROR;
                    }

                    if ((proc->params.signature[param_id].by == BY_REF) && (single_var != 1)) {
                        yyerror("expressão não pode ser passada por referência no parametro número %d do procedimento '%s'",
                            param_id, proc->nome);
                        YYERROR;
                    }

                    if (proc->params.signature[param_id].tipo != e) {
                        yyerror("parametro número %d do procedimento '%s' não aceita tipo '%s'",
                            param_id, proc->nome, TIPO_STR(e));
                        YYERROR;
                    }

                    pilha_push(pilha_cham_proc, proc_id);
                    pilha_push(pilha_cham_proc, param_id+1);
                };

comando_repetitivo:
                WHILE {
                    int rot = NOVO_ROTULO;

                    char label[4];
                    sprintf(label, "R%02d", rot);
                    geraCodigo(out, label, "NADA");

                    pilha_push(pilha_rot_loop, rot);
                } expressao {
                    tipos_var e = (tipos_var) pilha_pop(E);

                    if (e != TIPO_BOOLEAN) {
                        yyerror("expressão deve retornar 'boolean', retornou '%s'", TIPO_STR(e));
                        YYERROR;
                    }

                    int rot = NOVO_ROTULO;
                    geraCodigo(out, NULL, "DSVF R%02d", rot);
                    pilha_push(pilha_rot_loop, rot);
                } DO comando_sem_rotulo {
                    int exit_rot = pilha_pop(pilha_rot_loop);
                    int loop_rot = pilha_pop(pilha_rot_loop);

                    geraCodigo(out, NULL, "DSVS R%02d", loop_rot);

                    char label[4];
                    sprintf(label, "R%02d", exit_rot);
                    geraCodigo(out, label, "NADA");
                };

comando_condicional: if_then else {
                    int exit_rot = pilha_pop(pilha_rot_cond);

                    char label[4];
                    sprintf(label, "R%02d", exit_rot);
                    geraCodigo(out, label, "NADA");
                };

if_then:        IF expressao {
                    tipos_var e = (tipos_var) pilha_pop(E);

                    if (e != TIPO_BOOLEAN) {
                        yyerror("expressão deve retornar 'boolean', retornou '%s'", TIPO_STR(e));
                        YYERROR;
                    }

                    int exit_rot = NOVO_ROTULO, else_rot = NOVO_ROTULO;

                    pilha_push(pilha_rot_cond, else_rot);
                    pilha_push(pilha_rot_cond, exit_rot);

                    geraCodigo(out, NULL, "DSVF R%02d", else_rot);
                } THEN comando_sem_rotulo {
                    int exit_rot = pilha_pop(pilha_rot_cond);
                    int else_rot = pilha_pop(pilha_rot_cond);

                    geraCodigo(out, NULL, "DSVS R%02d", exit_rot);

                    char label[4];
                    sprintf(label, "R%02d", else_rot);
                    geraCodigo(out, label, "NADA");

                    pilha_push(pilha_rot_cond, exit_rot);
                };

else:           ELSE comando_sem_rotulo |
                %prec LOWER_THAN_ELSE %empty;

%%

int main(int argc, char* argv[]) {
    int err = 0;

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
    pilha_rot_jump = pilha_inicializa();
    pilha_rot_loop = pilha_inicializa();
    pilha_rot_cond = pilha_inicializa();
    pilha_cham_proc = pilha_inicializa();

    err = yyparse();

    pilha_destroi(E);
    pilha_destroi(ES);
    pilha_destroi(T);
    pilha_destroi(F);
    pilha_destroi(O);
    pilha_destroi(R);
    pilha_destroi(pilha_rot_jump);
    pilha_destroi(pilha_rot_loop);
    pilha_destroi(pilha_rot_cond);
    pilha_destroi(pilha_cham_proc);

    destroi_ts(ts);

    fclose(yyin);
    fclose(out);

    exit(err);
}