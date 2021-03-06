%{
#include <stdio.h>
#include <string.h>
#include "defs.h"
#include "compilador.tab.h"
#include "compilador.h"

int line = 1, column = 1;

#define YY_USER_ACTION \
     token.nome = yytext; \
     token.linha = line; \
     token.coluna = column; \
     token.tam = column + yyleng - 1; \
     column += yyleng;
%}

%option noinput
%option nounput

pulo_linha [\n]

descarte [\t ]+

ident [a-zAZ][a-zAZ1-9]*

numero [0-9]+

comentario "(*".*"*)"

%%

{pulo_linha} { line++; column = 1; }

{descarte}

{comentario}

program { return PROGRAM; }

label { return LABEL; }

var { return VAR; }

procedure { return PROCEDURE; }

function { return FUNCTION; }

begin { return T_BEGIN; }

end { return T_END; }

true { return T_TRUE; }

false { return T_FALSE; }

while { return WHILE; }

do { return DO; }

if { return IF; }

then { return THEN; }

else { return ELSE; }

write { return WRITE; }

read { return READ; }

goto { return GOTO; }

:= { return ATRIBUICAO; }

\; { return PONTO_E_VIRGULA; }

\: { return DOIS_PONTOS; }

\, { return VIRGULA; }

\. { return PONTO; }

\( { return ABRE_PARENTESES; }

\) { return FECHA_PARENTESES; }

\+    { op = OP_SOMA; return OPERADOR_DISJ; }
\-    { op = OP_SUBT; return OPERADOR_DISJ; }
or    { op = OP_DISJ; return OPERADOR_DISJ; }

\*    { op = OP_MULT; return OPERADOR_CONJ; }
div   { op = OP_DIVI; return OPERADOR_CONJ; }
and   { op = OP_CONJ; return OPERADOR_CONJ; }

\=   { rel = REL_IGUAL;         return RELACAO; }
\<\> { rel = REL_DIFERENTE;     return RELACAO; }
\<   { rel = REL_MENOR;         return RELACAO; }
\<\= { rel = REL_MENOR_IGUAL;   return RELACAO; }
\>   { rel = REL_MAIOR;         return RELACAO; }
\>\= { rel = REL_MAIOR_IGUAL;   return RELACAO; }

{ident} { return IDENT; }

{numero} { return NUMERO; }

%%
