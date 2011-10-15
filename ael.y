%{
#include <stdlib.h>
#include <stdio.h>
#include <stddef.h>
#define YYSTYPE char *

char mode[20];
char state[20];
char format[20];
%}

%token EQ
%token RPAREN
%token LPAREN
%token KET
%token BRA
%token ASSIGN
%token SEMICOLON
%token COMMA
%token ARROW
%token PIPE
%token COLON
%token AT
%token AND
%token IF
%token ELSE
%token WHILE
%token CASE
%token DEFAULT
%token PATTERN
%token CONTEXT
%token ABSTRACT
%token MACRO
%token GLOBALS
%token LOCAL
%token IGNOREPAT
%token REGEXTEN
%token HINT
%token RANDOM
%token IFTIME
%token SWITCH
%token SWITCHES
%token ESWITCHES
%token INCLUDES
%token GOTO
%token JUMP
%token FOR
%token BREAK
%token RETURN
%token CONTINUE
%token CATCH
%token WORD
%token COLLECTED_WORD

%%

file: objects;

objects: 
        object
    |   objects object
    ;

object:
        context 
    |   macro 
    |   globals
    |   SEMICOLON
    ;

context:  
            CONTEXT WORD BRA elements KET
        |   CONTEXT WORD BRA KET
        |   CONTEXT DEFAULT BRA elements KET
        |   CONTEXT DEFAULT BRA KET
        |   ABSTRACT CONTEXT WORD BRA elements KET
        |   ABSTRACT CONTEXT WORD BRA KET
        |   ABSTRACT CONTEXT DEFAULT BRA elements KET
        |   ABSTRACT CONTEXT DEFAULT BRA KET
        ;

macro:      MACRO WORD LPAREN arglist RPAREN BRA macro_statements KET
        |   MACRO WORD LPAREN arglist RPAREN BRA  KET
        |   MACRO WORD LPAREN RPAREN BRA macro_statements KET
        |   MACRO WORD LPAREN RPAREN BRA  KET
        ;


globals:    GLOBALS BRA global_statements KET
        |   GLOBALS BRA KET
        ;

global_statements:      global_statement
                   |    global_statements global_statement
                   ;

global_statement: WORD EQ COLLECTED_WORD SEMICOLON;


arglist:    WORD
         |  arglist COMMA WORD
         ;

elements:   element
         |  elements element
         ;

element:    extension
         |  includes
         |  switches
         |  eswitches
         |  ignorepat
         |  WORD EQ  COLLECTED_WORD SEMICOLON
         |  LOCAL WORD EQ  COLLECTED_WORD SEMICOLON
         |  SEMICOLON
         ;

ignorepat: IGNOREPAT ARROW WORD SEMICOLON;


extension:      WORD ARROW statement
           |    REGEXTEN WORD ARROW statement
           |    HINT LPAREN word3_list RPAREN WORD ARROW statement
           |    REGEXTEN HINT LPAREN word3_list RPAREN WORD ARROW statement
           ;

statements:     statement
            |   statements statement
            ;

if_head: IF LPAREN  COLLECTED_WORD RPAREN;

random_head: RANDOM LPAREN COLLECTED_WORD RPAREN;

ifTime_head:    IFTIME LPAREN word3_list COLON word3_list COLON word3_list PIPE word3_list PIPE word3_list PIPE word3_list RPAREN
           |    IFTIME LPAREN WORD PIPE word3_list PIPE word3_list PIPE word3_list RPAREN
           ;

word3_list: WORD
       |    WORD WORD
       |    WORD WORD WORD
       ;

switch_head: SWITCH LPAREN COLLECTED_WORD RPAREN  BRA;


statement: BRA statements KET
       | WORD EQ  COLLECTED_WORD SEMICOLON
       | LOCAL WORD EQ  COLLECTED_WORD SEMICOLON
       | GOTO target SEMICOLON
       | JUMP jumptarget SEMICOLON
       | WORD COLON
       | FOR LPAREN  COLLECTED_WORD SEMICOLON  COLLECTED_WORD SEMICOLON COLLECTED_WORD RPAREN statement
       | WHILE LPAREN  COLLECTED_WORD RPAREN statement
       | switch_head KET
       | switch_head case_statements KET
       | AND macro_call SEMICOLON
       | application_call SEMICOLON
       | application_call EQ  COLLECTED_WORD SEMICOLON
       | BREAK SEMICOLON
       | RETURN SEMICOLON
       | CONTINUE SEMICOLON
       | random_head statement
       | random_head statement ELSE statement
       | if_head statement
       | if_head statement ELSE statement
       | ifTime_head statement
       | ifTime_head statement ELSE statement
       | SEMICOLON
       ;

target: WORD
       | WORD PIPE WORD
       | WORD PIPE WORD PIPE WORD
       | DEFAULT PIPE WORD PIPE WORD
       | WORD COMMA WORD
       | WORD COMMA WORD COMMA WORD
       | DEFAULT COMMA WORD COMMA WORD
       ;

jumptarget: WORD
               | WORD COMMA WORD
               | WORD COMMA WORD AT WORD
               | WORD AT WORD
               | WORD COMMA WORD AT DEFAULT
               | WORD AT DEFAULT
               ;

macro_call: WORD LPAREN eval_arglist RPAREN
       | WORD LPAREN RPAREN
       ;

application_call_head: WORD  LPAREN;

application_call: application_call_head eval_arglist RPAREN
       | application_call_head RPAREN
       ;

eval_arglist:  COLLECTED_WORD
       | eval_arglist COMMA  COLLECTED_WORD
       | /* nothing */
       | eval_arglist COMMA  /* nothing */
       ;

case_statements: case_statement
       | case_statements case_statement
       ;


case_statement: CASE WORD COLON statements
       | DEFAULT COLON statements
       | PATTERN WORD COLON statements
       | CASE WORD COLON
       | DEFAULT COLON
       | PATTERN WORD COLON
       ;

macro_statements: macro_statement
       | macro_statements macro_statement
       ;

macro_statement: statement
       | CATCH WORD BRA statements KET
       ;

switches: SWITCHES BRA switchlist KET
       | SWITCHES BRA KET
       ;

eswitches: ESWITCHES BRA switchlist KET
       | ESWITCHES BRA  KET
       ;

switchlist: WORD SEMICOLON
       | switchlist WORD SEMICOLON
       ;

includeslist: includedname SEMICOLON
       | includedname PIPE word3_list COLON word3_list COLON word3_list PIPE word3_list PIPE word3_list PIPE word3_list SEMICOLON
       | includedname PIPE WORD PIPE word3_list PIPE word3_list PIPE word3_list SEMICOLON
       | includeslist includedname SEMICOLON
       | includeslist includedname PIPE word3_list COLON word3_list COLON word3_list PIPE word3_list PIPE word3_list PIPE word3_list SEMICOLON
       | includeslist includedname PIPE WORD PIPE word3_list PIPE word3_list PIPE word3_list SEMICOLON
       ;

includedname: WORD
        | DEFAULT
        ;

includes: INCLUDES BRA includeslist KET
       | INCLUDES BRA KET
       {
            printf("\t includes block!\n");
       }
       ;

%%

#include <stdio.h>
#include <ctype.h>
#include <string.h>

char *progname;

main( argc, argv )
char *argv[];
{
    progname = argv[0];
    printf("%s - Started \n",argv[0]);
    strcpy(format,"%g\n");
    yyparse();
}

yyerror( s )
char *s;
{
    fprintf( stderr, "ERROR: %s\n", s);
    yyparse();
}

