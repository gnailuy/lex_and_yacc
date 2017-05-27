LEX = lex -I
YACC = yacc

CC = gcc -DYYDEBUG=1

calc: y.tab.o lex.yy.o
	$(CC) -o calc y.tab.o lex.yy.o -ly -ll -lm

lex.yy.o: lex.yy.c y.tab.h

lex.yy.o y.tab.o: calc.h

y.tab.c y.tab.h: calc.y
	$(YACC) -d calc.y

lex.yy.c: calc.lex
	$(LEX) calc.lex

clean:
	-rm lex.yy.c lex.yy.o y.tab.c y.tab.h y.tab.o

distclean: clean
	-rm calc
