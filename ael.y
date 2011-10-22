%{
#define YYSTYPE char*

#include <stdlib.h>
#include <stdio.h>
#include <stddef.h>
#include <cstring>
#include <string>
#include <sstream>
#include <iostream>
#include <fstream>
#include <set>

#include <FlexLexer.h>

using namespace std;

yyFlexLexer lexer;
char format[20];
string box;
bool luaExtAllocated=false;

std::set<char*> garbage;

int yylex(void)
{
    return lexer.yylex();
}

void destroy_string(char* p)
{
    std::set<char*>::iterator it = garbage.find(p);
    if(it != garbage.end())
    {
        free(*it);
        garbage.erase(it);
    }
}

void recycle_garbage()
{
    set<char*>::iterator it;
    for(it = garbage.begin(); it != garbage.end(); it++)
    {
        destroy_string((*it));
    }
    garbage.clear();
}

char* alloc_string(char* d)
{
    char* s = (char*) calloc((strlen(d) + 1),sizeof(char));
    strcpy(s, d);
    garbage.insert(s);
    return s;
}

char* grow_string(char* head, char* tail)
{
    char* s = (char*) calloc((strlen(head) + strlen(tail) + 2), sizeof(char));
    sprintf(s,"%s%s", head, tail);
    destroy_string(head); //IT IS SUPPOSED head ALLOCATED USING MALLOC
    garbage.insert(s);
    return s;
}

char* handleContext(char* name,char* content)
{
    stringstream ss; 
    if (!luaExtAllocated)
    {
        luaExtAllocated = true;
        ss << "extensions = {}"<<endl;
    }
        ss << "extensions." << name << " = "<<endl<<"{"<<endl;
    if (strlen(content)>0)
    {
        ss<<content<<endl;
    }
    ss<<"}" << endl;
    return alloc_string((char*)ss.str().data());
}

char* convertAppcall(char* appcall) 
{
    //TODO
    return appcall;
}

extern "C"
{
    int yyparse(void);
    void yyerror(string);
    FILE* yyin;

    #ifndef yywrap
    int yywrap() { return 1; }    
    #endif
}
%}

%error-verbose

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

%token VARBEGIN
%token VARNAME
%token EXPRINIT
%token RSBRA
%token NOTEQ
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

%token END 0 "end of file"

%%

file: objects { $$ = $1; string s = string($$); recycle_garbage(); cout << s; }
    | END;
objects: 
    objects object 
    { 
        $$ = grow_string($1, $2);
    } 
    | object 
    {
        $$ = alloc_string($1);
    }
    ;

object:
        context { $$ = $1; /*cout << "<object-context> ->" << $$ << endl;*/ }
    |   macro { $$ = $1; }
    |   globals { $$ = $1; }
    |   SEMICOLON { $$ = alloc_string((char*)";"); }
    ;

context:  
    CONTEXT word BRA elements KET
    {
        $$ = handleContext($2,$4);
    }
    | CONTEXT word BRA KET 
    { 
        $$ = handleContext($2,(char*)"");
    }
    |   CONTEXT DEFAULT BRA elements KET
    {
        $$ = handleContext((char*)"default",$4);    
    }
    |   CONTEXT DEFAULT BRA KET
    {
        $$ = handleContext((char*)"default",(char*)"");
    }
    |   ABSTRACT CONTEXT word BRA elements KET
    |   ABSTRACT CONTEXT word BRA KET
    |   ABSTRACT CONTEXT DEFAULT BRA elements KET
    |   ABSTRACT CONTEXT DEFAULT BRA KET
    ;

macro:      MACRO word LPAREN arglist RPAREN BRA macro_statements KET
        |   MACRO word LPAREN arglist RPAREN BRA  KET
        |   MACRO word LPAREN RPAREN BRA macro_statements KET
        |   MACRO word LPAREN RPAREN BRA  KET
        ;


globals:    GLOBALS BRA global_statements KET
        |   GLOBALS BRA KET
        ;

global_statements:      global_statement
                   |    global_statements global_statement
                   ;

global_statement: word EQ implicit_expr_stat SEMICOLON;


arglist:    word
         |  arglist COMMA word
         ;

elements:   element
        {
            $$ = alloc_string($1);
        }
        |  elements element
        {
            $$=grow_string($1,$2);
        }           
        ;
element:    extension
        {
            $$ = $1;
        }
        |  includes
        |  switches
        |  eswitches
        |  ignorepat
        |  word EQ implicit_expr_stat SEMICOLON
        |  LOCAL word EQ implicit_expr_stat SEMICOLON
        |  SEMICOLON { $$ = alloc_string((char*)";"); }
        ;

ignorepat: IGNOREPAT ARROW word SEMICOLON;


extension: word ARROW statement
        {
            stringstream ss;
            ss <<"[\""<<$1<<"\"] = "<<$3;            
            $$ = alloc_string((char*)ss.str().data());
        }
        |    REGEXTEN word ARROW statement
        |    HINT LPAREN word3_list RPAREN word ARROW statement
        |    REGEXTEN HINT LPAREN word3_list RPAREN word ARROW statement
        ;

statements: statement
        {
            $$ = alloc_string($1);
        }
        |   statements statement
        {
            $$ = grow_string($1,$2);
        }
        ;

if_head: IF LPAREN implicit_expr_stat RPAREN;

random_head: RANDOM LPAREN implicit_expr_stat RPAREN;

ifTime_head:    IFTIME LPAREN word3_list COLON word3_list COLON word3_list PIPE word3_list PIPE word3_list PIPE word3_list RPAREN
           |    IFTIME LPAREN word PIPE word3_list PIPE word3_list PIPE word3_list RPAREN
           ;

word3_list: word { $$ = $1; }
       |    word word 
       {
            stringstream ss;
            ss << $1 << " " << $2;
            $$ = alloc_string((char*)ss.str().c_str());
            destroy_string($1);
            destroy_string($2);
       }
       |    word word word
       {
            stringstream ss;
            ss << $1 << " " << $2 << " " << $3;
            $$ = alloc_string((char*)ss.str().c_str());
            destroy_string($1);
            destroy_string($2);
            destroy_string($3);
       }
       ;

switch_head: SWITCH LPAREN implicit_expr_stat RPAREN  BRA;


statement:  BRA statements KET
        {
            stringstream ss;
            ss << "function()"<<endl<<$2<<"end;";
            $$ = alloc_string((char*)ss.str().data());
        }
        | word EQ implicit_expr_stat SEMICOLON
        | LOCAL word EQ implicit_expr_stat SEMICOLON
        | GOTO target SEMICOLON
        | JUMP jumptarget SEMICOLON
        | word COLON
        | FOR LPAREN implicit_expr_stat SEMICOLON implicit_expr_stat SEMICOLON implicit_expr_stat RPAREN statement
        | WHILE LPAREN implicit_expr_stat RPAREN statement
        | switch_head KET
        | switch_head case_statements KET
        | AND macro_call SEMICOLON
        | application_call SEMICOLON
        {
            $$ = grow_string(convertAppcall($1),(char*)";\n");
        }
        | application_call EQ implicit_expr_stat SEMICOLON
        {
            stringstream ss;
            ss << convertAppcall($1)<<" = " << $3 <<";"<<endl;
            $$ = alloc_string((char*)ss.str().data());
        }
        | BREAK SEMICOLON
        {
            $$ = alloc_string((char*)"break;\n");
        }
        | RETURN SEMICOLON
        {
            $$ = alloc_string((char*)"return;\n");
        }
        | CONTINUE SEMICOLON
        | random_head statement
        | random_head statement ELSE statement
        | if_head statement
        | if_head statement ELSE statement
        | ifTime_head statement
        | ifTime_head statement ELSE statement
        | SEMICOLON
       ;

target: word
       | word PIPE word
       | word PIPE word PIPE word
       | DEFAULT PIPE word PIPE word
       | word COMMA word
       | word COMMA word COMMA word
       | DEFAULT COMMA word COMMA word
       ;

jumptarget: word
               | word COMMA word
               | word COMMA word AT word
               | word AT word
               | word COMMA word AT DEFAULT
               | word AT DEFAULT
               ;

macro_call: word LPAREN eval_arglist RPAREN
        | word LPAREN RPAREN
        ;

application_call_head: word  LPAREN { $$ = grow_string($1,(char*)"("); };

application_call: application_call_head eval_arglist RPAREN
        {
            stringstream ss;
            ss << $1 << $2 <<")";
            $$ = alloc_string((char*)ss.str().data());
            destroy_string($1);
        }
        | application_call_head RPAREN
        {
            $$ = grow_string($1,(char*)")");
        }
        ;

eval_arglist:  implicit_expr_stat
        | eval_arglist COMMA implicit_expr_stat        
        {
            stringstream ss;
            ss << "," << $3;            
            $$ = grow_string($1,(char*)ss.str().data());
            destroy_string($1);
        }
        | /* nothing */
        | eval_arglist COMMA  /* nothing */
        {
            $$ = grow_string($1,(char*)",");
        }
        ;

case_statements: case_statement
       | case_statements case_statement
       ;


case_statement: CASE word COLON statements
       | DEFAULT COLON statements
       | PATTERN word COLON statements
       | CASE word COLON
       | DEFAULT COLON
       | PATTERN word COLON
       ;

macro_statements: macro_statement
       | macro_statements macro_statement
       ;

macro_statement: statement
       | CATCH word BRA statements KET
       ;

switches: SWITCHES BRA switchlist KET
       | SWITCHES BRA KET
       ;

eswitches: ESWITCHES BRA switchlist KET
       | ESWITCHES BRA  KET
       ;

switchlist: word SEMICOLON
       | switchlist word SEMICOLON
       ;

includeslist: includedname SEMICOLON
       | includedname PIPE word3_list COLON word3_list COLON word3_list PIPE word3_list PIPE word3_list PIPE word3_list SEMICOLON
       | includedname PIPE word PIPE word3_list PIPE word3_list PIPE word3_list SEMICOLON
       | includeslist includedname SEMICOLON
       | includeslist includedname PIPE word3_list COLON word3_list COLON word3_list PIPE word3_list PIPE word3_list PIPE word3_list SEMICOLON
       | includeslist includedname PIPE word PIPE word3_list PIPE word3_list PIPE word3_list SEMICOLON
       ;

includedname: word
        | DEFAULT
        ;

includes: INCLUDES BRA includeslist KET
       | INCLUDES BRA KET
       {
            printf("\t includes block!\n");
       }
       ;

explicit_expr_stat : EXPRINIT implicit_expr_stat RSBRA ;
implicit_expr_stat : base_expr ;
base_expr: variable
    | word
    | operand_expr
    | LPAREN operand_expr RPAREN
    | explicit_expr_stat
    ;
operand_expr : unary_expr
    | binary_expr
    | conditional_op
    ;
binary_expr: base_expr binary_op base_expr;
unary_expr: unary_op base_expr;
conditional_op : base_expr CONDQUEST base_expr COLON base_expr ;
binary_op: logical_binary_op
    | arith_binary_op
    ;
logical_binary_op : PIPE { $$ = alloc_string((char*)"|"); }
                  | AND { $$ = alloc_string((char*)"&"); }
                  | EQ { $$ = alloc_string((char*)"="); }
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
variable: VARNAME { $$ = alloc_string($1); free($1); };
word: WORD { $$ = alloc_string($1); free($1); };

%%

#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <FlexLexer.h>

char *progname;

extern int yydebug;

int main(int argc, char* argv[] )
{
    //yydebug=1;
    progname = argv[0];
    std::cout << progname <<" - ael2lua - Started" <<std::endl;
    strcpy(format,"%g\n");
    std::istream* in_file = &std::cin;
    std::ostream* out_file = &std::cout;    
    bool interInput = true;
    bool visualOutput = true;
    if (argc>1)
    {
        in_file = new std::ifstream(argv[1]);
    if (in_file->fail())
    {
        std::cerr << "Unable to open input file : " << argv[1] << std::endl;
        in_file = &std::cin;        
    } else 
    {
        interInput = false;
    }
    }
    if (argc>2)
    {
        out_file = new std::ofstream(argv[2]);
    if (out_file->fail())
    {
        std::cerr << "Unable to open output file : " << argv[2] << std::endl;
        out_file = &std::cout;
    } else 
    {
        visualOutput = false;
    }
    }
    std::cout <<"Input Stream : ";
    if (interInput)
    {
        std::cout <<"stdin (interactive mode)" <<std::endl;
    } else
    {
        std::cout<<argv[1]<<std::endl;
    }
    std::cout <<"Output Stream : ";
    if (visualOutput)
    {
        std::cout <<"stdout (visual output)" <<std::endl;
    } else
    {
        std::cout<<argv[2]<<std::endl;
    }
    std::cout<<"This aren't right ? Use program parameter : ./ael input_file output_file !"<<std::endl;
    if (interInput)
    {
        std::cout<<"Now you can write the code ..."<<std::endl;
    } else 
    {
        std::cout<<"Processing the file ..."<<std::endl<<"-----------------------------"<<std::endl;
    }
    lexer.switch_streams(in_file,out_file);
    yyparse();
    return 0;
}

void yyerror( string s )
{
    //fprintf( stderr, "ERROR: %s\n", s);
    std::cerr << "ERROR : " << s <<std::endl;
    yyparse();
}

