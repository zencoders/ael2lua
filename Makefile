CC=g++
LEX=flex
PROGRAM=ael
YACC=bison
YFLAGS=-d

OBJS=ael.tab.o lex.yy.o expr.tab.o lex.exp.o common.o utilities.o

SRCS=ael.tab.c lex.yy.cc expr.tab.c lex.exp.cc common.c utilities.cc

all: $(PROGRAM)

.c.o: $(SRCS)
	$(CC) -g -c $*.c -o $@ -O

ael.tab.c: ael.y
	$(YACC) --verbose --debug $(YFLAGS) ael.y

expr.tab.c: expr.y
	$(YACC) -p exp --verbose --debug $(YFLAGS) expr.y

lex.yy.cc: ael.l
	$(LEX) --c++ ael.l

lex.exp.cc: expr.l
	$(LEX) --c++ expr.l

ael: $(OBJS)
	$(CC) -g $(OBJS) -o $@ -lfl

clean:; rm -f $(OBJS) core *~ \#* *.o $(PROGRAM) \
	y.* lex.yy.* ael.tab.* expr.tab.* lex.exp.*

