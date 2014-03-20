#ifndef _UTILS_H_
#define _UTILS_H_

#include "defs.h"

void yyerror(const char *s, ...);
void geraCodigo(FILE *fp, const char* label, const char* format, ...);

#endif