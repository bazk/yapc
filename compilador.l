%{
#include <stdio.h>
#include <string.h>
#include "defs.h"
#include "compilador.tab.h"
#include "compilador.h"

int yycolumn = 1;

#define YY_USER_ACTION \
     token.nome = yytext; \
     token.linha = yylineno; \
     token.coluna = yycolumn; \
     token.tam = yycolumn + yyleng - 1; \
     yycolumn += yyleng;
%}

%option yylineno

pulo_linha [\n]

descarte [\t ]+

ident [a-zAZ][a-zAZ1-9]*

numero [0-9]+

comentario "(*".*"*)"

%%

{pulo_linha} { yycolumn = 1; }

{descarte}

{comentario}

program { return PROGRAM; }

var { return VAR; }

procedure { return PROCEDURE; }

begin { return T_BEGIN; }

end { return T_END; }

:= { return ATRIBUICAO; }

\; { return PONTO_E_VIRGULA; }

\: { return DOIS_PONTOS; }

\, { return VIRGULA; }

\. { return PONTO; }

\( { return ABRE_PARENTESES; }

\) { return FECHA_PARENTESES; }

{ident} { return IDENT; }

%%
