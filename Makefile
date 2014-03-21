CFLAGS = -std=c99

all: compilador

debug: CFLAGS += -DDEBUG -g -Wall
debug: compilador

compilador: lex.yy.c compilador.tab.c tabsimbolos.o utils.o compilador.h
	gcc $(CFLAGS) lex.yy.c compilador.tab.c tabsimbolos.o utils.o -o compilador -lfl -ly -lc

lex.yy.c: compilador.l compilador.h
	flex compilador.l

compilador.tab.c: compilador.y compilador.h
	bison compilador.y -d -v

utils.o: utils.c utils.h
	gcc $(CFLAGS) -c utils.c -o utils.o

tabsimbolos.o: tabsimbolos.c tabsimbolos.h
	gcc $(CFLAGS) -c tabsimbolos.c -o tabsimbolos.o

clean:
	rm -f compilador lex.yy.c compilador.tab.* compilador.o
