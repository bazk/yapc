CFLAGS =

all: compilador

debug: CFLAGS += -DDEBUG -g
debug: compilador

compilador: lex.yy.c compilador.tab.c tabsimbolos.o compilador.h
	gcc $(CFLAGS) lex.yy.c compilador.tab.c tabsimbolos.o -o compilador -lfl -ly -lc

lex.yy.c: compilador.l compilador.h
	flex compilador.l

compilador.tab.c: compilador.y compilador.h
	bison compilador.y -d -v

tabsimbolos.o: tabsimbolos.h tabsimbolos.c
	gcc $(CFLAGS) -c tabsimbolos.c -o tabsimbolos.o

clean:
	rm -f compilador lex.yy.c compilador.tab.* compilador.o
