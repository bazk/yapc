%{
#include<stdio.h>
#include<string.h>

#include "compilador.h"
#include "compilador.tab.h"

#ifdef DEBUG
     #define IMPRIME(STR) printf("%02d %s    # %s \n", nl, STR, token);
#else
     #define IMPRIME(STR) {};
#endif
%}

pulo_linha [\n]

descarte [\t ]+

ident [a-zAZ][a-zAZ1-9]*

numero [0-9]+

comentario "(*".*"*)"

%%

{pulo_linha} { nl++; }

{descarte}

{comentario}

program {
     simbolo = simb_program;
     strncpy(token, yytext, TAM_TOKEN);
     IMPRIME("program ");
     return PROGRAM;
}

var {
     simbolo = simb_var;
     strncpy (token, yytext, TAM_TOKEN);
     IMPRIME("var  ");
     return VAR;
}

begin {
     simbolo = simb_begin;
     strncpy (token, yytext, TAM_TOKEN);
     IMPRIME("begin ");
     return T_BEGIN;
}

end {
     simbolo = simb_end;
     strncpy (token, yytext, TAM_TOKEN);
     IMPRIME("end  ");
     return T_END;
}

:= {
     simbolo = simb_atribuicao;
     strncpy (token, yytext, TAM_TOKEN);
     IMPRIME(" atribuicao  ");
     return ATRIBUICAO;
}

\; {
     simbolo = simb_ponto_e_virgula;
     strncpy (token, yytext, TAM_TOKEN);
     IMPRIME(" pt_virgula  ");
     return PONTO_E_VIRGULA;
}

\: {
     simbolo = simb_dois_pontos;
     strncpy (token, yytext, TAM_TOKEN);
     IMPRIME(" dois pontos ");
     return DOIS_PONTOS;
}

\, { simbolo = simb_virgula;
     strncpy (token, yytext, TAM_TOKEN);
     IMPRIME(" virgula  ");
     return VIRGULA;
}


\. {
     simbolo = simb_ponto;
     strncpy (token, yytext, TAM_TOKEN);
     IMPRIME(" ponto  ");
     return PONTO;
}

\(  {
     simbolo = simb_abre_parenteses;
     strncpy (token, yytext, TAM_TOKEN);
     IMPRIME(" abre_parenteses  ");
     return ABRE_PARENTESES;
}

\)  {
     simbolo = simb_fecha_parenteses;
     strncpy (token, yytext, TAM_TOKEN);
     IMPRIME(" fecha_parenteses ");
     return FECHA_PARENTESES;
}

{ident} {
     simbolo = simb_identificador;
     strncpy (token, yytext, TAM_TOKEN);
     IMPRIME(" ident  ");
     return IDENT;
}

%%
