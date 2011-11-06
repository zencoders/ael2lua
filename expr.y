%{
#include <stdlib.h>
#include <stdio.h>
#include <stddef.h>
#include <cstring>
#include <string>
#include <sstream>
#include <iostream>
#include <fstream>

#undef yyFlexLexer
#define yyFlexLexer expFlexLexer
#include <FlexLexer.h>
#include "common.h"

using namespace std;

#define YYSTYPE char*

expFlexLexer explexer;

int expFlexLexer::explex(void)
{
    this->yylex();
}

int explex(void)
{
    return explexer.yylex();
}

int expparse(void);
void experror(char*);
FILE* expin;
FILE* expout;
stringstream output;

#ifndef yywrap
int yywrap() { return 1; }
#endif

%}

%error-verbose
%locations

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
%token WORD
%token COLLECTED_WORD
%token VARBEGIN
%token EXPRINIT
%token RSBRA
%token NOTEQ
%token EQUAL
%token GT
%token LT
%token GTEQ
%token LTEQ
%token PLUS
%token MINUS
%token MULT
%token DIV
%token MOD
%token LOGNOT
%token LIKEOP
%token CONDQUEST
%token NUM
%token VAR
%token NOVAR_WORD

%token END 0 "end of file"

%%

file: base_expr
    {
        $$ = $1;
        output << $$;
    }
    | END
    ;

base_expr:
    coll_words
    | operand_expr
    | LPAREN operand_expr RPAREN
    ;

coll_words:
          coll_word
          {
                $$ = alloc_string($1);
          }
          | coll_words coll_word
          {
                stringstream ss;
                ss << $1 << " .. ";
                char* group = alloc_string((char*)ss.str().data());
                $$ = grow_string(group, $2);
                destroy_string($1);
                destroy_string($2);
          }
          ;

coll_word:
         VAR
         {
            $$ = extract_variable($1);
         }
         | NUM
         | NOVAR_WORD
         {
            stringstream ss;
            ss << "\"" << $1 << "\"";
            $$ = alloc_string((char*) ss.str().data());
            free($1);
         }
         ;

operand_expr : unary_expr
    | binary_expr
    | conditional_op
    ;
binary_expr: base_expr binary_op base_expr 
           { 
                stringstream ss;
                ss << $1 << " " << $2 << " " << $3;
                $$ = alloc_string((char*)ss.str().data());
                destroy_string($1);
                destroy_string($2);
                destroy_string($3);
           };
unary_expr: unary_op base_expr
          {
                stringstream ss;
                ss << $1 << $2;
                $$ = alloc_string((char*) ss.str().data());
                destroy_string($1);
                destroy_string($2);
          }
          ;
conditional_op : base_expr CONDQUEST base_expr COLON base_expr 
          {
                stringstream ss;
                ss << "if " << $1 << " then " << $3 << " else " << $5 << " end";
                $$ = alloc_string((char*) ss.str().data());
                destroy_string($1);
                destroy_string($3);
                destroy_string($5);
          }
          ;
binary_op: logical_binary_op
         {
            $$ = $1;
         }
         | arith_binary_op
         {
            $$ = $1;
         }
         ;
logical_binary_op : PIPE { $$ = alloc_string((char*)"|"); }
                  | AND { $$ = alloc_string((char*)"&"); }
                  | EQUAL { $$ = alloc_string((char*)"=="); }
                  | NOTEQ { $$ = alloc_string((char*)"!="); }
                  | LT { $$ = alloc_string((char*)"<"); }
                  | GT { $$ = alloc_string((char*)">"); }
                  | GTEQ { $$ = alloc_string((char*)">="); }
                  | LTEQ { $$ = alloc_string((char*)"<="); }
                  ;
arith_binary_op : PLUS { $$ = alloc_string((char*)"+"); }
                | MINUS { $$ = alloc_string((char*)"-"); }
                | MULT { $$ = alloc_string((char*)"*"); }
                | DIV { $$ = alloc_string((char*)"/"); }
                | MOD { $$ = alloc_string((char*)"%"); }
                ;
unary_op : logical_unary_op { $$ = $1; }
    | arith_unary_op { $$ = $1; }
    ;
logical_unary_op : LOGNOT { $$ = alloc_string((char*) "!"); };
arith_unary_op : MINUS { $$ = alloc_string((char*) "-"); };


%%

string analyze_expression(const string& s)
{
    stringstream input;
    input << s;
    explexer.switch_streams(&input, &output);
    expparse();
    string to_ret = output.str();
    output.str("");
    return to_ret;
}

void experror( char* s )
{
    //fprintf( stderr, "ERROR: %s\n", s);
    fprintf(stderr,"ERROR : %s", s );
    expparse();
}

