%{
#include <stdlib.h>
#include <stdio.h>
#include <stddef.h>
#include <stdarg.h>
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
string analyze_expression(const string& s);

int expFlexLexer::explex(void)
{
    this->yylex();
}

int explex(void)
{
    return explexer.yylex();
}

int expparse(void);
void experror(const char*,...);
FILE* expin;
FILE* expout;
stringstream output;

#ifndef yywrap
int yywrap() { return 1; }
#endif

%}

%error-verbose
%locations

%right EQ
%token RPAREN
%token LPAREN
%right KET
%right BRA
%right ASSIGN
%token SEMICOLON
%left COMMA
%right ARROW
%left PIPE
%left COLON
%left AT
%left AND
%token WORD
%token COLLECTED_WORD
%token EXPRINIT
%token RSBRA
%left NOTEQ
%left EQUAL
%left GT
%left LT
%left GTEQ
%left LTEQ
%left MULT
%left DIV
%left MOD
%left PLUS
%left MINUS
%right LOGNOT
%left LIKEOP
%right CONDQUEST
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
    {
        $$ = $1;
    }
    | operand_expr
    {
        $$ = $1;
    }
    | LPAREN operand_expr RPAREN
    {
        stringstream ss;
        ss << "(" << $2 << ")";
        $$ = alloc_string((char*) ss.str().data());
        destroy_string($1);
    }
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
         {
            stringstream ss;
            string s = string($1);
            if(s.size() > 0 && s[0] != '\"' && s[s.size()-1] != '\"')
                ss << "\"" << $1 << "\"";
            else
                ss << $1;
            $$ = alloc_string((char*) ss.str().data());
            free($1);
         }
         | NOVAR_WORD
         {
            stringstream ss;
            string s = string($1);
            if((s.size() > 0 && s[0] != '\"' && s[s.size()-1] != '\"') &&
                (s.find("=") == string::npos) &&
                (s.find(">") == string::npos) &&
                (s.find("<") == string::npos) &&
                (s.find(">=") == string::npos) &&
                (s.find("<=") == string::npos) &&
                (s.find("==") == string::npos)
            )
                ss << "\"" << $1 << "\"";
            else
                ss << $1;
            $$ = alloc_string((char*) ss.str().data());
            free($1);
         }
         ;

operand_expr : unary_expr { $$ = $1; }
    | binary_expr { $$ = $1; }
    | conditional_op { $$ = $1; }
    | assign_expr { $$ = $1; }
    ;

assign_expr: NOVAR_WORD EQ base_expr
           {
                stringstream ss;
                ss << $1 << "=" << $3;
                $$ = alloc_string((char*)ss.str().data());
                free($1);
                destroy_string($3);
           }

binary_expr: base_expr binary_op base_expr 
           { 
                $$ = extract_binary_expr($1, $2, $3);
                destroy_string($1);
                destroy_string($2);
                destroy_string($3);
           };
unary_expr: unary_op base_expr
          {
                $$ = extract_unary_expr($1, $2);
                destroy_string($1);
                destroy_string($2);
          }
          ;
conditional_op : base_expr CONDQUEST base_expr COLON base_expr 
          {
                $$ = extract_conditional_op($1, $3, $5);
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
         | special_binary_op
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
special_binary_op : AT 
                  { 
                    $$ = alloc_string((char*) "@"); 
                  }
                  | COLON
                  {
                    $$ = alloc_string((char*) ":");
                  };
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

void
experror(const char *s, ...)
{
  va_list ap;
  va_start(ap, s);

  if(explloc.first_line)
    fprintf(stderr, "%d.%d-%d.%d: error: ", explloc.first_line, explloc.first_column,
        explloc.last_line, explloc.last_column);
  vfprintf(stderr, s, ap);
  fprintf(stderr, "\n");

}

