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

%%

programa:       { geraCodigo(out, NULL, "INPP"); }
                PROGRAM IDENT
                ABRE_PARENTESES lista_idents FECHA_PARENTESES PONTO_E_VIRGULA
                bloco PONTO
                { geraCodigo(out, NULL, "PARA"); };

lista_idents:   lista_idents VIRGULA IDENT |
                IDENT;

bloco:          parte_declara_vars
                parte_declara_procedures
                comando_composto;

parte_declara_vars: VAR declara_vars | ;

declara_vars:   declara_vars declara_var |
                declara_var;

declara_var:    { num_vars = 0; }
                lista_id_var DOIS_PONTOS tipo {
                    if (define_tipo_ts(ts, token.nome) != 0) {
                        yyerror("'%s' não é tipo de váriavel válido", token.nome);
                        YYERROR;
                    }
                }
                PONTO_E_VIRGULA {
                    geraCodigo(out, NULL, "AMEM %d", num_vars);
                };

lista_id_var:   lista_id_var VIRGULA var |
                var;

var:            IDENT {
                    insere_ts(ts, token.nome, CAT_VS, nivel_lexico);
                    num_vars++;
                };

tipo:           IDENT;

parte_declara_procedures: procedure PONTO_E_VIRGULA parte_declara_procedures | ;

procedure:      PROCEDURE IDENT {
                    insere_ts(ts, token.nome, CAT_PROC, nivel_lexico);
                } PONTO_E_VIRGULA {
                    nivel_lexico++;
                } bloco;

comando_composto: T_BEGIN comandos T_END {
                    #ifdef DEBUG
                        imprime_ts(ts);
                    #endif

                    unsigned int removidos = remove_nivel_ts(ts, nivel_lexico);

                    if (removidos > 0) {
                        geraCodigo(out, NULL, "DMEM %d", removidos);
                    }

                    nivel_lexico--;
                };

comandos:       ;

%%

main(int argc, char* argv[]) {
    unsigned int i, err;

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