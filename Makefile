CC=gcc
LEX=flex
PROGRAM=ael
YACC=yacc
YFLAGS=-d

OBJS=ael.tab.o lex.yy.o

SRCS=ael.tab.c lex.yy.c

all: $(PROGRAM)

.c.o: $(SRCS)
	$(CC) -g -c $*.c -o $@ -O

ael.tab.c: ael.y
	bison $(YFLAGS) ael.y

lex.yy.c: ael.l
	flex ael.l

ael: $(OBJS)
	$(CC) -g $(OBJS) -o $@ -lfl

clean:; rm -f $(OBJS) core *~ \#* *.o $(PROGRAM) \
	y.* lex.yy.* ael.tab.*

#ael: ael.o
	#$(CC) -o ael ael.o -lfl

#ael.o: ael.c y.tab.h
	#$(CC) -c -o ael.o ael.c

#ael.c: ael.l
	#$(LEX) -t ael.l > ael.c

#y.tab.h: ael.y
	#$(YACC) -dvt ael.y

#clean:
	#rm ael.c y.output y.tab.c y.tab.h
