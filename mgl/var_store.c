#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct var {
    char *name;
    char *value;
    struct var *next;
} *var_list, *last_var;

void add_var(char *name, char *value) {
    struct var *v = (struct var*)malloc(sizeof(struct var));
    v->next = NULL;
    v->name = name;
    v->value = value;

    if (!var_list) {
        var_list = last_var = v;
    } else {
        last_var->next = v;
        last_var = v;
    }
}

char *find_var(char *name) {
    struct var *v;

    for (v = var_list; v != NULL; v = v->next) {
        if (strcmp(name, v->name) == 0) {
            return strdup(v->value);
        }
    }

    fprintf(stderr, "Fatal Error: Var $%s not defined!\n", name);
    exit(-1);
}

