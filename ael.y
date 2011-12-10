%{
#define YYSTYPE char*

#include <stdlib.h>
#include <stdio.h>
#include <stddef.h>
#include <stdarg.h>
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
#include <stack>
#include <list>

#include <FlexLexer.h>

#include "utilities.h"
#include "common.h"
#include "ss_state.h"
#include "handlers.h"

using namespace std;

string analyze_expression(const string& s);

char* to_expr_analysis(char* s)
{
    char* to_ret;
    if(isNumeric(s, 10))
    {
        to_ret = s;
    }
    else
    {
        string ss = analyze_expression(s);
        to_ret = alloc_string((char*)ss.data());
    }
    return to_ret;
}

yyFlexLexer lexer;
char format[20];
string box;
string last_block;
string last_block2;
bool is_block = false;
int label_idx = 0;
std::stack<SwitchStatementState> switchStack;

string current_ext;
string current_context;

string last_context;

int yylex(void)
{
    return lexer.yylex();
}

extern "C"
{
    int yyparse(void);
    void yyerror(const char*, ...);
    void yywarn(const char*, ...);
    FILE* yyin;
    FILE* yyout;
    ostream* out_file;

    #ifndef yywrap
    int yywrap() { return 1; }    
    #endif
}
%}

%error-verbose
%locations

%right EQ
%token RPAREN
%token LPAREN
%right KET
%left BRA
%right ASSIGN
%token SEMICOLON
%left COMMA
%right ARROW
%left PIPE
%left COLON
%left AT
%left AND
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
%token VARNAME
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

%token END 0 "end of file"

%%

file: objects { $$ = $1; string s = string($$); recycle_garbage(); *out_file << s.data(); }
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
    {
        yywarn("This context is marked to be abstract. Your LUA context will lose this property!");
        last_context = $3;
        $$ = handleContext($3,$5);
    }
    |   ABSTRACT CONTEXT word BRA KET
    {
        yywarn("This context is marked to be abstract. Your LUA context will lose this property!");
        last_context = $3;
        $$ = handleContext($3,(char*)"");
    }
    |   ABSTRACT CONTEXT DEFAULT BRA elements KET
    {
        yywarn("This context is marked to be abstract. Your LUA context will lose this property!");
        last_context = "default";
        $$ = handleContext((char*)"default",$5);
    }
    |   ABSTRACT CONTEXT DEFAULT BRA KET
    {
        yywarn("This context is marked to be abstract. Your LUA context will lose this property!");
        last_context = "default";
        $$ = handleContext((char*)"default",(char*)"");
    }
    | error KET
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
        {
            $$ = $3;
        }
        |   GLOBALS BRA KET
        {
        }
        ;

global_statements: global_statement
                   {
                        $$ = $1;
                   }
                   |    global_statements global_statement
                   {
                        stringstream ss;
                        ss << $1 << " " << $2;
                        $$ = alloc_string((char*) ss.str().data());
                        destroy_string($1);
                        destroy_string($2);
                   }
                   ;

global_statement: word EQ implicit_expr_stat SEMICOLON
                {
                    stringstream ss;
                    ss << $1 << "=" << $3 << endl;
                    $$ = alloc_string((char*)ss.str().data());
                    destroy_string($1);
                    destroy_string($3);
                }
                | error SEMICOLON
                ;


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
element:   extension
        {
            $$ = $1;
        }
        |  includes
        {
            $$ = $1;
        }
        |  switches
        {
            $$ = $1;
        }
        |  eswitches
        {
            $$ = $1;
        }
        |  ignorepat
        {
            $$ = $1;
        }
        |  word EQ implicit_expr_stat SEMICOLON
        {
            stringstream ss;
            ss << "channel." << $1 << "=" << $3 << endl;
            $$ = alloc_string((char*)ss.str().data());
            destroy_string($1);
            destroy_string($3);
        }
        |  LOCAL word EQ implicit_expr_stat SEMICOLON
        {
            stringstream ss;
            ss << "local " << $1 << "=" << $3 << endl;
            $$ = alloc_string((char*)ss.str().data());
            destroy_string($1);
            destroy_string($3);
        }
        |  SEMICOLON 
        { 
            $$ = alloc_string((char*)";"); 
        }
        | error SEMICOLON
        ;

ignorepat: IGNOREPAT ARROW word SEMICOLON
         {
            stringstream ss;
            ss << "[\"ignorepat\"] = " << $3;
            $$ = alloc_string((char*)ss.str().data());
            destroy_string($3);
         }
         ;


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
            store_hint(alloc_string((char*)ss.str().data()));
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
            store_hint(alloc_string((char*)ss.str().data()));
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

if_head: IF LPAREN implicit_expr_stat RPAREN
       {
            stringstream ss;
            ss << "if " << $3 << "then" << endl;
            $$ = alloc_string((char*) ss.str().data());
            destroy_string($3);
       }
       ;

random_head: RANDOM LPAREN implicit_expr_stat RPAREN
           {
                stringstream ss;
                ss << "r = math.random()" << endl;
                ss << "if (r*100) <= " << $3 << " then " << endl;
                $$ = alloc_string((char*)ss.str().data());
                destroy_string($3);
           }
           ;

ifTime_head:    IFTIME LPAREN word3_list COLON word3_list COLON word3_list PIPE word3_list PIPE word3_list PIPE word3_list RPAREN
           {
                TimeStruct ts;
                handleTimes($3, $5, $7, $9, $11, $13, &ts);
                string s = time2iftime(&ts);
                $$ = alloc_string((char*)s.data());
                destroy_string($3);
                destroy_string($5);
                destroy_string($7);
                destroy_string($9);
                destroy_string($11);
                destroy_string($13);
                ts.destroyAll();
           }
           |    IFTIME LPAREN word PIPE word3_list PIPE word3_list PIPE word3_list RPAREN
           {
                TimeStruct ts;
                handleTimes($3, $5, $7, $9, &ts);
                string s = time2iftime(&ts);
                $$ = alloc_string((char*)s.data());
                destroy_string($3);
                destroy_string($5);
                destroy_string($7);
                destroy_string($9);
                ts.destroyAll();
           }
           ;

word3_list: 
       word 
       { 
            $$ = $1; 
       }
       | word word 
       {
            stringstream ss;
            ss << $1 << " " << $2;
            $$ = alloc_string((char*)ss.str().c_str());
            destroy_string($1);
            destroy_string($2);
       }
       | word word word
       {
            stringstream ss;
            ss << $1 << " " << $2 << " " << $3;
            $$ = alloc_string((char*)ss.str().c_str());
            destroy_string($1);
            destroy_string($2);
            destroy_string($3);
       }
       ;

words:
     word3_list word
     {
        stringstream ss;
        ss << $1 << " " << $2;
        $$ = alloc_string((char*) ss.str().data());
        destroy_string($1);
        destroy_string($2);
     }
     | word binary_op word
     {
        stringstream ss;
        ss << $1 << $2 << $3;
        $$ = alloc_string((char*) ss.str().data());
        destroy_string($1);
        destroy_string($2);
        destroy_string($3);
     }
     | words word
     {
        stringstream ss;
        ss << $1 << " " << $2;
        $$ = alloc_string((char*) ss.str().data());
        destroy_string($1);
        destroy_string($2);
     }
     | words binary_op word
     {
        stringstream ss;
        ss << $1 << $2 << $3;
        $$ = alloc_string((char*) ss.str().data());
        destroy_string($1);
        destroy_string($2);
        destroy_string($3);
     }
     ;

switch_head: SWITCH LPAREN implicit_expr_stat RPAREN  BRA
        {
            stringstream ss;
            ss<<"do"<<endl<<"local switch_var = "<<$3<<endl;
            $$ = alloc_string((char*)ss.str().data());            
            switchStack.push(SwitchStatementState());
        }
        ;


statement:  BRA statements KET
        {
            stringstream ss;
            ss << "function()"<<endl<<$2<<"end;" << endl;
            if(!is_block)
                last_block = string($2);
            else
                last_block2 = string($2);
            is_block = true;
            $$ = alloc_string((char*)ss.str().data());
        }
        | word EQ implicit_expr_stat SEMICOLON
        {
            stringstream ss;
            ss <<"channel."<< $1 <<" = "<<$3<<endl;
            $$ = alloc_string((char*)ss.str().data());
            destroy_string($1);
            destroy_string($3);
        }
        | LOCAL word EQ implicit_expr_stat SEMICOLON
        {
            stringstream ss;
            ss << "local " << $2 << " = "<<$4<<endl;
            $$ = alloc_string((char*)ss.str().data());
            destroy_string($2);
            destroy_string($4);
        }
        | GOTO target SEMICOLON
        {
            if (($2[0]=='-')&&($2[1]=='-'))
            {
                $$ = grow_string($2,(char*)"\n");
            } 
            else
            {
                stringstream ss;
                ss << "return app.goto"<<$2<<endl;
                $$ = alloc_string((char*)ss.str().data());
                destroy_string($2);
            }
        }
        | JUMP jumptarget SEMICOLON
        {
                stringstream ss;
                ss << "return app.goto("<<$2<<")"<<endl;
                $$ = alloc_string((char*)ss.str().data());
                destroy_string($2);
        }
        | word COLON
        {
            stringstream ss;
            ss << "::"<<$1<<"::"<<endl;
            $$ = alloc_string((char*)ss.str().data());
            destroy_string($1);
        }            
        | FOR LPAREN implicit_expr_stat SEMICOLON implicit_expr_stat SEMICOLON implicit_expr_stat RPAREN statement
        {
            stringstream ss;
            string lb;
            if(is_block)
            {
                lb = string(last_block);
                is_block = false;
            }
            else
            {
                lb = string($9);
            }
            ss << "for " << $3 << ", " << $5 << ", " << $7 << " do " << endl << "::label" << label_idx << "::" << endl << lb << endl << "end;" << endl;
            label_idx++;
            $$ = alloc_string((char*)ss.str().data());
            destroy_string($3);
            destroy_string($5);
            destroy_string($7);
            destroy_string($9);
        }
        | WHILE LPAREN implicit_expr_stat RPAREN statement
        {
            stringstream ss;
            string lb;
            if(is_block)
            {
                lb = string(last_block);
                is_block = false;
            }
            else
            {
                lb = string($5);
            }
            ss << "while " << $3 << "do" << endl << lb << endl << "::label" << label_idx << "::" << endl << "end;" << endl;
            label_idx++;
            $$ = alloc_string((char*)ss.str().data());
            destroy_string($3);
            destroy_string($5);
        }
        | switch_head KET
        {
            $$ = grow_string($1,(char*)"end;\n");
        }
        | switch_head case_statements KET
        {
            stringstream ss;           
            ss << $1 << $2 <<"end;"<<endl<<"end;"<<endl;
            $$ = alloc_string((char*)ss.str().data());                                           
            //destroy_string($1);
            switchStack.pop();
        }
        | AND macro_call SEMICOLON
        {
            $$ = grow_string($2,(char*)"\n");            
        }
        | application_call SEMICOLON
        {
            $$ = grow_string($1,(char*)"\n");
        }
        | application_call EQ implicit_expr_stat SEMICOLON
        {
            stringstream ss;
            string ac = string($1).substr(4,strlen($1)-4);
            ss << "channel." << ac << ":set(" << $3 << ")" << endl;
            $$ = alloc_string((char*)ss.str().data());
            destroy_string($1);
            destroy_string($3);
        }
        | BREAK SEMICOLON
        {
            if (switchStack.empty()) //useless in break statement
            {
                $$ = alloc_string((char*)"break;\n");
            } else            
            {
                $$ = alloc_string((char*)"");
                //cerr<< "Break Found . Switch-case statement are converted to if-elseif chains so break becames useless;";
            }
        }
        | RETURN SEMICOLON
        {
            $$ = alloc_string((char*)"return\n");
        }
        | CONTINUE SEMICOLON
        {
            stringstream ss;
            ss << "goto label" << label_idx << "\n";
            $$ = alloc_string((char*) ss.str().data());
        }
        | random_head statement
        {
            string lb;
            if(is_block)
            {
                lb = string(last_block);
                is_block = false;
            }
            else
            {
                lb = string($2);
            }
            $$ = handleIf($1,(char*)lb.data());
            destroy_string($1);
            destroy_string($2);
        }
        | random_head statement ELSE statement
        {
            string lb;
            string lb2;
            if(is_block)
            {
                lb = string(last_block);
                lb2 = string(last_block2);
                is_block = false;
            }
            else
            {
                lb = string($2);
                lb2 = string($4);
            }
            $$ = handleIfElse($1, (char*)lb.data(), (char*)lb2.data());
            destroy_string($1);
            destroy_string($2);
            destroy_string($4);
        }
        | if_head statement
        {
            string lb;
            if(is_block)
            {
                lb = string(last_block);
                is_block = false;
            }
            else
            {
                lb = string($2);
            }
            $$ = handleIf($1,(char*)lb.data());
            destroy_string($1);
            destroy_string($2);
        }
        | if_head statement ELSE statement
        {
            string lb;
            string lb2;
            if(is_block)
            {
                lb = string(last_block);
                lb2 = string(last_block2);
                is_block = false;
            }
            else
            {
                lb = string($2);
                lb2 = string($4);
            }
            $$ = handleIfElse($1, (char*)lb.data(), (char*)lb2.data());
            destroy_string($1);
            destroy_string($2);
            destroy_string($4);
        }
        | ifTime_head statement
        {
            string lb;
            if(is_block)
            {
                lb = string(last_block);
                is_block = false;
            }
            else
            {
                lb = string($2);
            }

            $$ = handleIf($1,(char*)lb.data());
            destroy_string($1);
            destroy_string($2);
        }
        | ifTime_head statement ELSE statement
        {
            string lb;
            string lb2;
            if(is_block)
            {
                lb = string(last_block);
                lb2 = string(last_block2);
                is_block = false;
            }
            else
            {
                lb = string($2);
                lb2 = string($4);
            }
            $$ = handleIfElse($1, (char*)lb.data(), (char*)lb2.data());
            destroy_string($1);
            destroy_string($2);
            destroy_string($4);
        }
        | SEMICOLON
        | error SEMICOLON
        | error KET
       ;

target: word
        {
            //GOTO LOCAL LABEL => Supported
            $$ = $1;
        }
        | word PIPE word
        {
            //GOTO LABEL IN DIFFERENT EXTENSION : Not Supported
            string s($3);
            stringstream ss;
            if(isNumeric(s.data(),10))
            {
                ss << "(" << $1 << "," << $3 << ")";
            }
            else
            {
                yywarn("goto a label on a different extension is not supported");
                ss << "-- (ael2lua warning) goto a label on a different extension is not supported (original AEL2 target : ";
                ss << $1 << "|" << $3<<")";
            }
            $$ = alloc_string((char*)ss.str().data());
            destroy_string($1);
            destroy_string($3);
        }   
        | word PIPE word PIPE word
        {
            stringstream ss;
//            ss << "-- (ael2lua warning) goto a label on a different extension and/or context is not supported (original AEL2 target : ";
//            ss << $1 << "|" << $3<<"|"<<$5<<")";
            ss << "(" << $1 << "," << $3 << "," << $5 << ")";
            $$ = alloc_string((char*)ss.str().data());
            destroy_string($1);
            destroy_string($3);
            destroy_string($5);
        }
        | DEFAULT PIPE word PIPE word
        {
              //GOTO LABEL IN DIFFERENT CONTEXT AND EXTENSION : Not Supported
            stringstream ss;
//            ss << "-- (ael2lua warning) goto a label on a different extension and/or context is not supported (original AEL2 target : ";
//            ss << "default" << "|" << $3<<"|"<<$5<<")";
            ss << "(default," << $3 << "," << $5 << ")";
            $$ = alloc_string((char*)ss.str().data());
            destroy_string($3);
            destroy_string($5);

        }
        | word COMMA word
        {
            //GOTO LABEL IN DIFFERENT EXTENSION : Not Supported
            string s($3);
            stringstream ss;
            if(isNumeric(s.data(),10))
            {
                ss << "(" << $1 << "," << $3 << ")";
            }
            else
            {
                yywarn("goto a label on a different extension is not supported");
                ss << "-- (ael2lua warning) goto a label on a different extension is not supported (original AEL2 target : ";
                ss << $1 << "|" << $3<<")";
            }
            $$ = alloc_string((char*)ss.str().data());
            destroy_string($1);
            destroy_string($3);

        }
        | word COMMA word COMMA word    
        {
            //GOTO LABEL IN DIFFERENT CONTEXT AND EXTENSION : Not Supported
            stringstream ss;
         //   ss << "-- (ael2lua warning) goto a label on a different extension and/or context is not supported (original AEL2 target : ";
         //   ss << $1 << "," << $3<<","<<$5<<")";
            ss << "(" << $1 << "," << $3 << "," << $5 << ")";
            $$ = alloc_string((char*)ss.str().data());
            destroy_string($1);
            destroy_string($3);
            destroy_string($5);
        }
        | DEFAULT COMMA word COMMA word
        {
            //GOTO LABEL IN DIFFERENT CONTEXT AND EXTENSION : Not Supported
            stringstream ss;
        //    ss << "-- (ael2lua warning) goto a label on a different extension and/or context is not supported (original AEL2 target : ";
        //    ss << "default" << "," << $3<<","<<$5<<")";
            ss << "(default," << $3 << "," << $5 << ")";
            $$ = alloc_string((char*)ss.str().data());
            destroy_string($3);
            destroy_string($5);

        }
        ;

jumptarget: word
        {
            //JUMP TO EXTENSION (SAME EXTENSION)
            stringstream ss;
            ss <<"\""<<$1<<"\",1";
            $$ = alloc_string((char*)ss.str().data());
            destroy_string($1);
        }
        | word COMMA word
        {
            //JUMP TO LABEL (DIFFERENT EXTENSION)
            stringstream ss;
            ss << "\""<<$1<<"\","<<$3;
            $$ = alloc_string((char*)ss.str().data());
            destroy_string($1);
            destroy_string($3);
        }        
        | word COMMA word AT word
        {
           //JUMP TO LABEL (DIFFERENT EXTENSION AND CONTEXT);
           stringstream ss;
           ss << "\""<<$1<<"\",\""<<$3<<"\","<<$5;
           $$ = alloc_string((char*)ss.str().data());
           destroy_string($1);
           destroy_string($3);
           destroy_string($5);
        }        
        | word AT word
        {
            //JUMP TO EXTENSION : supported
            stringstream ss;
            ss << "\""<<$3<<"\",\""<<$1<<"\",1";
            $$ = alloc_string((char*)ss.str().data());
            destroy_string($1);
            destroy_string($2);
        }
/*        | word COMMA word AT DEFAULT
        {
           //JUMP TO LABEL (DIFFERENT EXTENSION AND CONTEXT);
           stringstream ss;
           ss << "\"default\",\""<<$3<<"\","<<$5;
           $$ = alloc_string((char*)ss.str().data());
           destroy_string($1);
           destroy_string($3);
        }*/
/*        | word AT DEFAULT
        {
            //JUMP TO EXTENSION : supported
            stringstream ss;
            ss << "\"default\",\""<<$1<<"\",1";
            $$ = alloc_string((char*)ss.str().data());
            destroy_string($1);
        }*/
        ;

macro_call: word LPAREN eval_arglist RPAREN
          {
                stringstream ss;
                ss << $1 << "(" << $3 << ")";
                $$ = alloc_string((char*)ss.str().data());
                destroy_string($1);
                destroy_string($3);
          }
          | word LPAREN RPAREN
          {
                $$ = grow_string($1,(char*)"()");
          }
          ;

application_call_head: word  LPAREN 
        { 
            stringstream ss;
            if(!isupper($1[1]))
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
            destroy_string($2);
        }
        | application_call_head RPAREN
        {
            $$ = grow_string($1,(char*)")");
        }
        | error RPAREN
        ;

eval_arglist: implicit_expr_stat
            {
                $$ = $1;
            }
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
        {
            $$ = alloc_string($1);
            destroy_string($1);
        }
        | case_statements case_statement
        {
            $$ = grow_string($1,$2);
            destroy_string($2);
        }
        ;


case_statement: CASE word COLON statements
        {
            CaseStat cs;
            cs.value=alloc_string($2);
            cs.typeCase=true;
            cs.typePattern=false;
            switchStack.top().sstack.push(cs);            
            $$ = alloc_string(switchStack.top().getCompleteText($4));
            //destroy_string($2);
        }
        | DEFAULT COLON statements
        {
            switchStack.top().dandlingDefault=true;            
            $$ = alloc_string(switchStack.top().getCompleteText($3));
        }
        | PATTERN word COLON statements        
        {   
            CaseStat cs;
            cs.value=alloc_string($2);
            cs.typeCase=false;
            cs.typePattern=true;
            switchStack.top().sstack.push(cs);
            $$ = alloc_string(switchStack.top().getCompleteText($4));
            //destroy_string($2);
        }
        | CASE word COLON
        {
            $$ = (char*)"";
            CaseStat cs;
            cs.value=alloc_string($2);
            cs.typeCase=true;
            cs.typePattern=false;
            switchStack.top().sstack.push(cs);
        }
        | DEFAULT COLON
        {
            $$ = (char*)"";
            switchStack.top().dandlingDefault=true;            
        }
        | PATTERN word COLON
        {
            $$ = (char*)"";
            CaseStat cs;
            cs.value=alloc_string($2);
            cs.typeCase=false;
            cs.typePattern=true;
            switchStack.top().sstack.push(cs);
        }
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
            ss<<"};"<<endl;
            $$ = alloc_string((char*)ss.str().data());
            destroy_string($2);
        }
        ;

switches: SWITCHES BRA switchlist KET
        {
            last_context = "switches";
            $$ = handleContext((char*)"switches",$3);
            destroy_string($3);
        }
       | SWITCHES BRA KET
       {
            last_context = "switches";
            $$ = handleContext((char*)"switches",(char*)"");
       }
       | error KET
       ;

eswitches: ESWITCHES BRA switchlist KET
       {
            last_context = "eswitches";
            $$ = handleContext((char*)"eswitches",$3);
            destroy_string($3);
       }
       | ESWITCHES BRA KET
       {
            last_context = "eswitches";
            $$ = handleContext((char*)"eswitches",(char*)"");
       }
       ;

switchlist: word SEMICOLON
          {
                $$ = $1;
          }
          | switchlist word SEMICOLON
          {
                stringstream ss;
                ss << $1 << endl << $2;
                $$ = alloc_string((char*)ss.str().data());
                destroy_string($1);
          }
          | error SEMICOLON
          ;

includeslist: 
       includedname SEMICOLON
       {
            stringstream ss;
            ss << handleIncludedName($1);
            $$ = alloc_string((char*)ss.str().data());
            destroy_string($1);
       }
       | includedname PIPE word3_list COLON word3_list COLON word3_list PIPE word3_list PIPE word3_list PIPE word3_list SEMICOLON
       {
            // REDO !
            stringstream ss;
            ss << $1 << "|" << $3 << ":" << $5 << ":" << $7 << "|" << $9 << "|" << $11 << "|" << $13;
            $$ = alloc_string(handleIncludedName((char*)ss.str().data()));
            destroy_string($1);
            destroy_string($3);
            destroy_string($5);
            destroy_string($7);
            destroy_string($9);
            destroy_string($11);
            destroy_string($13);
       }
       | includedname PIPE word PIPE word3_list PIPE word3_list PIPE word3_list SEMICOLON
       {
            // REDO !
            stringstream ss;
            ss << $1 << "|" << $3 << "|" << $5 << "|" << $7 << "|" << $9;
            $$ = alloc_string(handleIncludedName((char*)ss.str().data()));
            destroy_string($1);
            destroy_string($3);
            destroy_string($5);
            destroy_string($7);
            destroy_string($9);
       }
       | includeslist includedname SEMICOLON
       {
            stringstream ss;
            ss << "," << handleIncludedName($2);
            $$ = grow_string($1, (char*) ss.str().data());
            destroy_string($1);
            destroy_string($2);
       }
       | includeslist includedname PIPE word3_list COLON word3_list COLON word3_list PIPE word3_list PIPE word3_list PIPE word3_list SEMICOLON
       {
            // REDO !
            stringstream ss;
            stringstream iss;
            iss << $2 << "|" << $4 << ":" << $6 << ":" << $8 << "|" << $10 << "|" << $12 << "|" << $13;
            char* name = handleIncludedName((char*) iss.str().data());
            ss << "," << name;
            $$ = grow_string($1, (char*) ss.str().data());
            destroy_string($2);
            destroy_string($4);
            destroy_string($6);
            destroy_string($8);
            destroy_string($10);
            destroy_string($12);
            destroy_string($13);
       }
       | includeslist includedname PIPE word PIPE word3_list PIPE word3_list PIPE word3_list SEMICOLON
       {
            // REDO !
            stringstream ss;
            stringstream iss;
            iss << $2 << "|" << $4 << "|" << $6 << "|" << $8 << "|" << $10;
            char* name = handleIncludedName((char*) iss.str().data());
            ss << "," << name;
            $$ = grow_string($1, (char*) ss.str().data());
            destroy_string($2);
            destroy_string($4);
            destroy_string($6);
            destroy_string($8);
            destroy_string($10);
       }
       | error SEMICOLON
       ;

includedname: 
       word
       {
           $$ = $1;
       }
/*       | DEFAULT
       {
           $$ = alloc_string((char*) "default");
       }*/
       ;

includes: 
       INCLUDES BRA includeslist KET
       {
            stringstream ss;
            ss << "include = { " << $3 << " };";
            $$ = alloc_string((char*)ss.str().data());
            destroy_string($3);
       }
       | INCLUDES BRA KET
       {
            $$ = alloc_string((char*) "include = {};");
       }
       ;

explicit_expr_stat : EXPRINIT implicit_expr_stat RSBRA 
                   {
                        $$ = $2;
                   }
                   ;
implicit_expr_stat : base_expr
                   { 
                        $$ = $1; 
                   };

base_expr: 
    explicit_expr_stat
    {
        $$ = $1;
    }
    | word
    {
        $$ = alloc_string(to_expr_analysis($1));
        destroy_string($1);
    }
    | words
    {
        $$ = alloc_string(to_expr_analysis($1));
        destroy_string($1);
    }
    | operand_expr
    { 
        $$ = $1; 
    }
    | LPAREN operand_expr RPAREN
    { 
        stringstream ss;
        ss << "(" << $1 << ")" << endl;
        $$ = alloc_string((char*) ss.str().data());
        destroy_string($1);
    }
    | application_call
    {
        $$ = $1;
    }
    ;
operand_expr : unary_expr { $$ = $1; }
    | binary_expr { $$ = $1; }
    | conditional_op { $$ = $1; }
    | assign_expr { $$ = $1; }
    ;
assign_expr: word EQ base_expr
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
word: WORD 
    { 
        $$ = alloc_string($1); free($1); 
    }
    | VARNAME
    {
        $$ = extract_variable($1); free($1);
    }
    | DEFAULT
    {
        $$ = alloc_string((char*)"default");
    }
    ;

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
    out_file = &std::cout;    
    bool interInput = true;
    bool visualOutput = true;
    bool delete_infile = false;
    bool delete_outfile = false;
    if (argc>1)
    {
        in_file = new std::ifstream(argv[1]);
        delete_infile = true;
        if (in_file->fail())
        {
            std::cerr << "Unable to open input file : " << argv[1] << std::endl;
            in_file = &std::cin;     
        }
        else 
        {
            interInput = false;
        }
    }
    if (argc>2)
    {
        out_file = new std::ofstream(argv[2]);
        delete_outfile = true;
        if (out_file->fail())
        {
            std::cerr << "Unable to open output file : " << argv[2] << std::endl;
            out_file = &std::cout;
        } 
        else 
        {
            visualOutput = false;
        }
    }
    std::cout <<"Input Stream : ";
    if (interInput)
    {
        std::cout <<"stdin (interactive mode)" <<std::endl;
    } 
    else
    {
        std::cout<<argv[1]<<std::endl;
    }
    std::cout <<"Output Stream : ";
    if (visualOutput)
    {
        std::cout <<"stdout (visual output)" <<std::endl;
    } 
    else
    {
        std::cout<<argv[2]<<std::endl;
    }
    std::cout<<"This aren't right ? Use program parameter : ./ael input_file output_file !"<<std::endl;
    if (interInput)
    {
        std::cout<<"Now you can write the code ..."<<std::endl;
    } 
    else 
    {
        std::cout<<"Processing the file ..."<<std::endl<<"-----------------------------"<<std::endl;
    }
    lexer.switch_streams(in_file,out_file);
    yyparse();
    if(delete_infile) delete in_file;
    if(delete_outfile) delete out_file;
    return 0;
}

void
yyerror(const char *s, ...)
{
    va_list ap;
    va_start(ap, s);

    if(yylloc.first_line)
        fprintf(stderr, "%d.%d-%d.%d: error: ", yylloc.first_line, yylloc.first_column, yylloc.last_line, yylloc.last_column);
    vfprintf(stderr, s, ap);
    fprintf(stderr, "\n");
}

void
yywarn(const char *s, ...)
{
    va_list ap;
    va_start(ap, s);

    if(yylloc.first_line)
        fprintf(stderr, "%d.%d-%d.%d: warning: ", yylloc.first_line, yylloc.first_column,yylloc.last_line, yylloc.last_column);
    vfprintf(stderr, s, ap);
    fprintf(stderr, "\n");
}
