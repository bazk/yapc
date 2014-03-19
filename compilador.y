%{
#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include "compilador.h"
#include "tabsimbolos.h"

int num_vars;
int nivel_lexico = 0;

FILE *mepa_fp;

tab_simbolos_t *ts;

void geraCodigo(const char* label, const char* format, ...) {
    va_list args;
    va_start(args, format);

    if (label) {
        fprintf(mepa_fp, "%s: ", label);
    }
    else {
        fprintf(mepa_fp, "    ");
    }

    vfprintf(mepa_fp, format, args);
    fprintf(mepa_fp, "\n");

    va_end(args);
}

int imprimeErro(const char* erro) {
    fprintf(stderr, "Erro na linha %d - %s\n", nl, erro);
    exit(-1);
}

%}

%token PROGRAM ABRE_PARENTESES FECHA_PARENTESES
%token VIRGULA PONTO_E_VIRGULA DOIS_PONTOS PONTO
%token T_BEGIN T_END VAR IDENT ATRIBUICAO

%%

programa:       { geraCodigo(NULL, "INPP"); }
                PROGRAM IDENT
                ABRE_PARENTESES lista_idents FECHA_PARENTESES PONTO_E_VIRGULA
                bloco PONTO
                {
                    /*int i, dmem_count = 0;
                    for (i=(ts_it-1); i>=0; i--) {
                        if (ts[ts_it].params.nivel_lexico < nivel_lexico)
                            break;

                        dmem_count++;
                    }

                    if (dmem_count > 0) {
                        geraCodigo(NULL, "DMEM %d", dmem_count);
                    }*/

                    geraCodigo(NULL, "PARA");
                };

bloco:          parte_declara_vars
                comando_composto;

parte_declara_vars: VAR declara_vars | ;

declara_vars:   declara_vars declara_var |
                declara_var;

declara_var:    { num_vars = 0; }
                lista_id_var DOIS_PONTOS tipo PONTO_E_VIRGULA
                { geraCodigo(NULL, "AMEM %d", num_vars); };

lista_id_var:   lista_id_var VIRGULA var |
                var;

var:            IDENT {
                    insere_ts(ts, token, CAT_VS, nivel_lexico);
                    num_vars++;
                };

lista_idents:   lista_idents VIRGULA IDENT |
                IDENT;

tipo:           IDENT;

comando_composto: T_BEGIN comandos T_END;

comandos:       comandos PONTO_E_VIRGULA comando | comando;

comando:        IDENT;

%%

main(int argc, char* argv[]) {
    unsigned int i, err;

    extern FILE *yyin;

    if (argc != 2) {
        printf("Usage:\n\tcompilador FILE\n\n");
        exit(-1);
    }

    yyin = fopen(argv[1], "r");
    if (yyin == NULL) {
        printf("Error: cannot open file %s.\n", argv[1]);
        exit(-2);
    }

    mepa_fp = fopen("MEPA", "w");
    if (mepa_fp == NULL) {
        printf("Error: cannot open MEPA file for writing.\n");
        exit(-3);
    }

    ts = inicializa_ts();
    nl = 1;

    err = yyparse();

    imprime_ts(ts);
    destroi_ts(ts);

    fclose(yyin);
    fclose(mepa_fp);

    if (err != 0) {
        printf("Erro de sintaxe na linha %d!\n", nl);
        exit(err);
    }

    exit(0);
}