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
%}

%define parse.error verbose

%token PROGRAM ABRE_PARENTESES FECHA_PARENTESES
%token VIRGULA PONTO_E_VIRGULA DOIS_PONTOS PONTO
%token T_BEGIN T_END VAR IDENT ATRIBUICAO
%token PROCEDURE
%token NUMERO
%token MAIS MENOS ASTERISCO BARRA AND OR

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
                    geraCodigo(out, NULL, "ARMZ %d, %d", l_elem->nivel_lexico, l_elem->params.desloc);
                };

expressao:      expressao MAIS termo { geraCodigo(out, NULL, "SOMA"); } |
                expressao MENOS termo { geraCodigo(out, NULL, "SUBT"); } |
                expressao OR termo { geraCodigo(out, NULL, "DISJ"); } |
                termo;

termo:          termo ASTERISCO fator { geraCodigo(out, NULL, "MULT"); } |
                termo BARRA fator { geraCodigo(out, NULL, "DIVI"); } |
                termo AND fator { geraCodigo(out, NULL, "CONJ"); } |
                fator;

fator:          ABRE_PARENTESES expressao FECHA_PARENTESES |
                IDENT {
                    simbolo_t *simb = busca_ts(ts, token.nome, CAT_VS, nivel_lexico);

                    if (simb == NULL) {
                        yyerror("variável '%s' não foi definida", token.nome);
                        YYERROR;
                    }

                    geraCodigo(out, NULL, "CRVL %d, %d", simb->nivel_lexico, simb->params.desloc);
                } |
                NUMERO {
                    geraCodigo(out, NULL, "CRCT %s", token.nome);
                };

%%

int main(int argc, char* argv[]) {
    unsigned int err;

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

    err = yyparse();

    destroi_ts(ts);

    fclose(yyin);
    fclose(out);

    exit(err);
}