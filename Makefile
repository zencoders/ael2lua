CC=g++
LEX=flex
PROGRAM=ael
YACC=yacc
YFLAGS=-d

OBJS=ael.tab.o lex.yy.o

SRCS=ael.tab.c lex.yy.cc

all: $(PROGRAM)

.c.o: $(SRCS)
	$(CC) -g -c $*.c -o $@ -O

ael.tab.c: ael.y
	bison --verbose --debug $(YFLAGS) ael.y

lex.yy.cc: ael.l
	flex --c++ ael.l

ael: $(OBJS)
	$(CC) -g $(OBJS) -o $@ -lfl

clean:; rm -f $(OBJS) core *~ \#* *.o $(PROGRAM) \
	y.* lex.yy.* ael.tab.*

