%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int screen_done = 1;
char *act_str;
char *cmd_str;
char *item_str;
char *main_screen = (char *)0;

void warning(char *, char *);
int start_screen(char *);
void add_title(char *);
void add_line(int, int);
int end_screen(char *);
void process_items(void);
void dump_data(char **);
void end_file(void);
void add_main(char *);
int check_name(char *);
void add_var(char *, char *);
char *find_var(char *);

int yylex();
int yyerror();
%}

%union {
    char *string;
    int cmd;
}

%token <string> QSTRING ID COMMENT VAR
%token <cmd> MAIN SCREENY TITLE ITEM COMMAND ACTION EXECUTE EMPTY
%token <cmd> MENU QUIT IGNORE ATTRIBUTE VISIBLE INVISIBLE END

%type <cmd> action line attribute command
%type <string> id qstring

%start mgl

%%

mgl:        defs screens
    |       screens
    ;

defs:       def_var
    |       defs def_var
    ;

def_var:    VAR '=' qstring { add_var($1, $3); }
    ;

screens:    screen
    |       screens screen
    ;

screen:     screen_name screen_contents screen_terminator
    |       screen_name screen_terminator
    ;

screen_name:    SCREENY id  { start_screen($2); }
    |       SCREENY         { start_screen(strdup("default")); }
    |       MAIN SCREENY id {
                if (main_screen != (char *)0) {
                    warning("Overriding pre-defined main screen", (char *)0);
                }
                main_screen = $3;
                start_screen($3);
            }
    |       MAIN SCREENY    {
                if (main_screen != (char *)0) {
                    warning("Overriding pre-defined main screen", (char *)0);
                }
                main_screen = strdup("default");
                start_screen(strdup("default"));
            }
    ;

screen_terminator:  END id  { end_screen($2); }
    |       END             { end_screen(strdup("default")); }
    ;

screen_contents:    titles lines
    ;

titles:     /* empty */
    |       titles title
    ;

title:      TITLE qstring   { add_title($2); }
    ;

lines:      line
    |       lines line
    ;

line:       ITEM qstring command ACTION action attribute {
                item_str = $2;
                add_line($5, $6);
                $$ = ITEM;
            }
    ;

command:    /* empty */     { cmd_str = strdup(""); }
    |       COMMAND id      { cmd_str = $2; }
    ;

action:     EXECUTE qstring {
                act_str = $2;
                $$ = EXECUTE;
            }
    |       MENU id         {
                act_str = (char *)malloc(strlen($2) + 6);
                strcpy(act_str, "menu_");
                strcat(act_str, $2);
                free($2);
                $$ = MENU;
            }
    |       QUIT            { $$ = QUIT; }
    |       IGNORE          { $$ = IGNORE; }
    ;

attribute:  /* empty */         { $$ = VISIBLE; }
    |       ATTRIBUTE VISIBLE   { $$ = VISIBLE; }
    |       ATTRIBUTE INVISIBLE { $$ = INVISIBLE; }
    ;

id:         ID              { $$ = $1; }
    |       QSTRING         {
                warning("String literal inappropriate", (char *)0);
                $$ = $1; /* But use it anyway */
            }
    ;

qstring:    QSTRING         { $$ = $1; }
    |       VAR             { $$ = find_var($1); }
    |       ID              {
                warning("Non-string literal inappropriate", (char *)0);
                $$ = $1; /* But use it anyway */
            }
    ;

%%

char *progname = "mgl";
int lineno = 1;

#define DEFAULT_OUTFILE "screen.out"
char *usage = "%s: usage [infile] [outfile]\n";

int main(int argc, char * argv[]) {
    char *outfile;
    char *infile;
    extern FILE *yyin, *yyout;
    progname = argv[0];

    if (argc > 3) {
        fprintf(stderr, usage, progname);
        exit(1);
    }

    if (argc > 1) {
        infile = argv[1];
        yyin = fopen(infile, "r");
        if (yyin == NULL) {
            fprintf(stderr, "%s: cannot open %s\n",
                progname, infile);
            exit(1);
        }
    }

    if (argc > 2) {
        outfile = argv[2];
    } else {
        outfile = DEFAULT_OUTFILE;
    }

    yyout = fopen(outfile, "w");
    if (yyout == NULL) {
        fprintf(stderr, "%s: cannot open %s\n",
            progname, outfile);
        exit(1);
    }

    yyparse();

    end_file();

    if (!main_screen) {
        warning("Main screen not defined", (char *)0);
        unlink(outfile);
        exit(1);
    }
    add_main(main_screen);

    if (!screen_done) {
        warning("Premature EOF", (char *)0);
        unlink(outfile);
        exit(1);
    }
    exit(0);
}

void warning(char *s, char *t) {
    fprintf(stderr, "%s: %s", progname, s);
    if (t) {
        fprintf(stderr, " %s", t);
    }
    fprintf(stderr, " line %d\n", lineno);
}

