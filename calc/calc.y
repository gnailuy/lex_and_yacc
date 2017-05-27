%{
#include "calc.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex();
int yyerror();
%}

%union {
    double dval;
    struct symtab* symp;
}

%token <symp> NAME
%token <dval> NUMBER
%left '-' '+'
%left '*' '/'
%nonassoc UMINUS

%type <dval> expression

%%

statement_list: statement '\n'
    |           statement_list statement '\n'
    ;

statement:  NAME '=' expression         { $1->value = $3; }
    |       expression                  { printf("= %g\n", $1); }
    ;

expression: expression '+' expression   { $$ = $1 + $3; }
    |       expression '-' expression   { $$ = $1 - $3; }
    |       expression '*' expression   { $$ = $1 * $3; }
    |       expression '/' expression   {
                            if ($3 == 0) {
                                yyerror("devide by zero");
                            } else {
                                $$ = $1 / $3;
                            }
                        }
    |       '-' expression %prec UMINUS { $$ = -$2; }
    |       '(' expression ')'          { $$ = $2; }
    |       NUMBER
    |       NAME                        { $$ = $1->value; }
    |       NAME '(' expression ')'     {
                            if ($1->funcptr) {
                                $$ = ($1->funcptr)($3);
                            } else {
                                printf("%s is not a function\n", $1->name);
                                $$ = 0.0;
                            }
                        }
    ;

%%

struct symtab* symlook(char* s) {
    struct symtab* sp;
    for (int i = 0; i < NSYMS; i++) {
        sp = &symtab[i];
        if (sp->name && !strcmp(sp->name, s)) {
            return sp;
        } else if (!sp->name) {
            sp->name = strdup(s);
            return sp;
        }
    }
    yyerror("too many symbols");
    exit(1);
}

void addfunc(char* name, double (*func)()) {
    struct symtab* sp = symlook(name);
    sp->funcptr = func;
}

int main(int argc, char* argv[]) {
    extern double sqrt(), exp(), log();

    addfunc("sqrt", sqrt);
    addfunc("exp", exp);
    addfunc("log", log);
    yyparse();
}

