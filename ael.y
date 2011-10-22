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
#include <vector>
#include <map>
#include <algorithm>
#include <iterator>

#include <FlexLexer.h>

using namespace std;

yyFlexLexer lexer;
char format[20];
string box;
bool luaExtAllocated=false;
bool luaHintsAllocated=false;

std::set<char*> garbage;
string last_context;
std::vector<std::string> hints;

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

char* handleMacroDef(char* name,char* arglist, char* stats)
{
    stringstream ss;
    ss<<"function "<<name<<"("<<arglist<<")"<<endl;
    ss<<stats;
    ss<<"end"<<endl<<endl;
    return (char*)ss.str().data();
}

char* handleContext(char* name,char* content)
{
    stringstream ss; 
    if (!luaExtAllocated)
    {
        luaExtAllocated = true;
        ss << "extensions = {}"<<endl;
    }
    if(!luaHintsAllocated && hints.size())
    {
        luaHintsAllocated = true;
        ss << "hints = {}" << endl;
    }
    ss << "extensions." << name << " = "<<endl<<"{"<<endl;
    if (strlen(content)>0)
    {
        ss<<content<<endl;
    }
    ss<<"}" << endl<<endl;
    if(hints.size())
    {
        ss << "hints." << name << " = "<<endl<<"{"<<endl;
        for(int i = 0; i < hints.size(); i++)
        {
            ss << hints[i] << endl;
        }
        ss << "}" << endl << endl;
    }
    hints.clear();
    return alloc_string((char*)ss.str().data());
}

vector<string> string_split(const string& s)
{
    vector<string> to_ret;
    istringstream iss(s);
    copy(istream_iterator<string>(iss),
        istream_iterator<string>(),
        back_inserter<vector<string> >(to_ret));
    return to_ret;
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
        destroy_string($2);
    } 
    | object 
    {
        $$ = alloc_string($1);
    }
    ;

object:
        context { $$ = $1; }
    |   macro { $$ = $1; } 
    |   globals { $$ = $1; }
    |   SEMICOLON { $$ = alloc_string((char*)";"); }
    ;

context:  
    CONTEXT word BRA elements KET
    {
        last_context = $2;
        $$ = handleContext($2,$4);
    }
    | CONTEXT word BRA KET 
    { 
        last_context = $2;
        $$ = handleContext($2,(char*)"");
    }
    |   CONTEXT DEFAULT BRA elements KET
    {
        last_context = "default";
        $$ = handleContext((char*)"default",$4);    
    }
    |   CONTEXT DEFAULT BRA KET
    {
        last_context = "default";
        $$ = handleContext((char*)"default",(char*)"");
    }
    |   ABSTRACT CONTEXT word BRA elements KET
    |   ABSTRACT CONTEXT word BRA KET
    |   ABSTRACT CONTEXT DEFAULT BRA elements KET
    |   ABSTRACT CONTEXT DEFAULT BRA KET
    ;

macro:  MACRO word LPAREN arglist RPAREN BRA macro_statements KET
    {
        $$ = handleMacroDef($2,$4,$7);
        destroy_string($2);
        destroy_string($4);
        destroy_string($7);
    }
    |   MACRO word LPAREN arglist RPAREN BRA  KET
    {
        $$ = handleMacroDef($2,$4,(char*)"");
        destroy_string($2);
        destroy_string($4);
    }
    |   MACRO word LPAREN RPAREN BRA macro_statements KET
    {   
        $$ = handleMacroDef($2,(char*)"",$6);
        destroy_string($2);
        destroy_string($6);
    }
    |   MACRO word LPAREN RPAREN BRA KET
    {
        $$ = handleMacroDef($2,(char*)"",(char*)"");
        destroy_string($2);
    }
    ;


globals:    GLOBALS BRA global_statements KET
        |   GLOBALS BRA KET
        ;

global_statements:      global_statement
                   |    global_statements global_statement
                   ;

global_statement: word EQ implicit_expr_stat SEMICOLON;


arglist:    word { $$ = $1; }
         |  arglist COMMA word 
         { 
            stringstream ss;
            ss << ", " << $3;
            $$=grow_string($1,(char*)ss.str().c_str());
            destroy_string($3);
         }
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
            destroy_string($1);
            destroy_string($3);
        }
        |    REGEXTEN word ARROW statement
        {
            stringstream ss;
            ss <<"[\""<<$2<<"\"] = "<<$4;            
            $$ = alloc_string((char*)ss.str().data());
            destroy_string($2);
            destroy_string($4);
        }
        |    HINT LPAREN word3_list RPAREN word ARROW statement
        {
            stringstream ss;
            vector<string> r = string_split($3);
            for(int i = 0; i < r.size(); i++)
            {
                ss << "[\""<<$5<<"\"] = " << "\"" << r[i] << "\"" << endl;
            }
            ss << "[\"" << $5 << "\"] = " << $7;
            $$ = (char*) "";
            hints.push_back(alloc_string((char*)ss.str().data()));
            destroy_string($3);
            destroy_string($5);
            destroy_string($7);
        }
        |    REGEXTEN HINT LPAREN word3_list RPAREN word ARROW statement
        {
            stringstream ss;
            vector<string> r = string_split($4);
            for(int i = 0; i < r.size(); i++)
            {
                ss << "[\""<<$6<<"\"] = " << "\"" << r[i] << "\"" << endl;
            }
            ss << "[\"" << $6 << "\"] = " << $8;
            $$ = (char*)"";
            hints.push_back(alloc_string((char*)ss.str().data()));
            destroy_string($4);
            destroy_string($6);
            destroy_string($8);
        }
        ;

statements: statement
        {
            $$ = alloc_string($1);
        }
        |   statements statement
        {
            $$ = grow_string($1,$2);
            destroy_string($2);
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
        {
            stringstream ss;
            ss << "while " << $3 << "do" << endl << $5 << endl << "end";
            $$ = alloc_string((char*)ss.str().data());
            destroy_string($3);
            destroy_string($5);
        }
        | switch_head KET
        | switch_head case_statements KET
        | AND macro_call SEMICOLON
        | application_call SEMICOLON
        {
            $$ = $1;
        }
        | application_call EQ implicit_expr_stat SEMICOLON
        {
            stringstream ss;
            string ac = string($1).substr(4,strlen($1)-4);
            ss << "channel." << ac << ":set(" << $3 << ")";
            $$ = alloc_string((char*)ss.str().data());
            destroy_string($1);
            destroy_string($3);
        }
        | BREAK SEMICOLON
        {
            $$ = alloc_string((char*)"break\n");
        }
        | RETURN SEMICOLON
        {
            $$ = alloc_string((char*)"return\n");
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

application_call_head: word  LPAREN 
                    { 
                        stringstream ss;
                        $1[0] = tolower($1[0]);
                        ss << "app." << $1 << "(";
                        $$ = alloc_string((char*)ss.str().data());
                        destroy_string($1);
                    };

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
        {
            $$ = alloc_string((char*)"nil");
        }
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

macro_statements:   macro_statement
        {
            $$ = alloc_string($1);
            destroy_string($1);
        }
        | macro_statements macro_statement
        {
            $$ = grow_string($1,$2);
            destroy_string($1);
        }
        ;

macro_statement: statement      
        {
            $$ = $1;
        }
        | CATCH word BRA statements KET
        {
            stringstream ss;
            ss << "catch "<<$2<<" {"<<endl;
            ss<<$4;
            ss<<"}"<<endl;
            $$ = alloc_string((char*)ss.str().data());
            destroy_string($2);
        }
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
    {
        stringstream ss;
        ss << "\""<<$1<<"\"";
        $$ = alloc_string((char*)ss.str().data());
    }
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

