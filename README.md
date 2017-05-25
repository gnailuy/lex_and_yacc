A copy of the MGL program from Lex & Yacc by John R. Levine et al.

with some minor updates.

```
make
./mgl sample_menu.mgl sample_menu.mgl.c
gcc -o sample_menu.out sample_menu.mgl.c -Icurses -Itermcap -lcurses
```

