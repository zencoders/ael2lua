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
#include <stack>
#include <list>

#include <FlexLexer.h>

#include "utilities.h"

using namespace std;

char* alloc_string(char*);

typedef struct {
    char* value;
    bool typePattern;
    bool typeCase;
} CaseStat;

class SwitchStatementState
{
    public:
    bool initialized;    
    bool dandlingDefault;
    std::stack<CaseStat> sstack;
    SwitchStatementState()
    {
        dandlingDefault=0x0;
        initialized=false;
    }
    char* getCompleteText(char* statements)
    {
        stringstream ss;
        int num = this->sstack.size();
        if (num>0)
        {
            if (this->initialized) {
               ss << "else";
            } else {
               this->initialized=true;
            }
            ss<<"if ";
            bool c_s_first=true;
            stringstream condStream;
            while(!this->sstack.empty())
            {
                if(!c_s_first)
                {
                    condStream << " or ";
                } else 
                {
                    c_s_first=false;
                }
                if (this->sstack.top().typeCase)
                {
                    condStream<<"( switch_var == "<<this->sstack.top().value<<")";
                } else if (this->sstack.top().typePattern)                
                {
                    condStream<<"( string.match(switch_var,\""<<this->sstack.top().value<<"\") ~= nil )";
                }
                this->sstack.pop();
            }
            if (num>1)
            {
                ss <<"("<< condStream.str()<<")";
            } else {
                ss << condStream.str();
            }
            ss<<" then"<<endl<<statements;
        }
        if (dandlingDefault)
        {
            ss<<"else "<<endl<<statements;
        }
        return alloc_string((char*)ss.str().data());
    }
};

yyFlexLexer lexer;
char format[20];
string box;
bool luaExtAllocated=false;
bool luaHintsAllocated=false;
std::stack<SwitchStatementState> switchStack;

string current_ext;
string current_context;

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

typedef struct 
{
    char* beginHour;
    char* endHour;
    char* beginMinutes;
    char* endMinutes;
    char* beginDay;
    char* endDay;
    char* beginDOM;
    char* endDOM;
    char* beginMonth;
    char* endMonth;

    void destroyAll()
    {
        destroy_string(beginHour);
        destroy_string(endHour);
        destroy_string(beginMinutes);
        destroy_string(endMinutes);
        destroy_string(beginDay);
        destroy_string(endDay);
        destroy_string(beginDOM);
        destroy_string(endDOM);
        destroy_string(beginMonth);
        destroy_string(endMonth);
    }
} TimeStruct;



string time2iftime(TimeStruct* ts)
{
    stringstream ss;
    ss << "temp = os.date()" << endl;
    ss << "if (";
    bool first = true;
    if(ts->beginMonth != "")
    {
        ss << "temp.month >= " << ts->beginMonth << ((ts->endMonth != "") ? (" and temp.month < " + string(ts->endMonth)) : "");
        first = false;
    }
    if(ts->beginDOM != "")
    {
        if(!first)
            ss << " and ";
        ss << "temp.day >= " << ts->beginDOM << ((ts->endDOM != "") ? (" and temp.day < " + string(ts->endDOM)) : "");
        first = false;
    }
    if(ts->beginDay != "")
    {
        if(!first)
            ss << " and ";
        ss << "temp.wday >= " << ts->beginDay << ((ts->beginDay != "") ? (" and temp.wday < " + string(ts->endDay)) : "");
        first = false;
    }
    if(!first)
        ss << " and ";
    ss << "(temp.hour + 0.01 * temp.min) >= " << ts->beginHour << "." << ts->beginMinutes;
    ss << " and (temp.hour + 0.01 * temp.min) < " << ts->endHour << "." << ts->endMinutes;
    ss << ") then" << endl;
    return ss.str();
}

void handleTimes(char* t1, char* t2, char* t3, char* day, char* md, char* m, TimeStruct* ts)
{
    string bh(t1);
    string em(t3);
    vector<string> second_word = split(t2, '-');
    ts->beginHour = alloc_string((char*)trim(bh).data());
    ts->beginMinutes = alloc_string((char*)trim(second_word[0]).data());
    ts->endHour = alloc_string((char*)trim(second_word[1]).data());
    ts->endMinutes = alloc_string((char*)trim(em).data());
    string dw(day);
    string dayword(trim(dw));
    string beginDayString = "";
    string endDayString = "";
    if(dayword != "*")
    {
        vector<string> days = split(dayword, '-');
        beginDayString = sday2iday(trim(days[0]));
        if(days.size() > 1)
        {
            endDayString = sday2iday(trim(days[1]));
        }
    }
    ts->beginDay = alloc_string((char*)beginDayString.data());
    ts->endDay = alloc_string((char*)endDayString.data());
    string dom(md);
    string dayOfMonth(trim(dom));
    string beginDOMString = "";
    string endDOMString = "";
    if(dayOfMonth != "*")
    {
        vector<string> monthDays = split(dayOfMonth, '-');
        beginDOMString = trim(monthDays[0]);
        if(monthDays.size() > 1)
        {
            endDOMString = trim(monthDays[1]);
        }
    }
    ts->beginDOM = alloc_string((char*)beginDOMString.data());
    ts->endDOM = alloc_string((char*)endDOMString.data());
    string mon(m);
    string month(trim(mon));
    string beginMonthString = "";
    string endMonthString = "";
    if(month != "*")
    {
        vector<string> months = split(month, '-');
        beginMonthString = smonth2imonth(trim(months[0]));
        if(months.size() > 1)
        {
            endMonthString = smonth2imonth(trim(months[1]));
        }
    }
    ts->beginMonth = alloc_string((char*)beginMonthString.data());
    ts->endMonth = alloc_string((char*)endMonthString.data());
}

void handleTimes(char* time, char* day, char* md, char* m, TimeStruct* ts)
{
    char* t1;
    char* t2;
    char* t3;
    if(string(time) == "*")
    {
        t1 = (char*)"00";
        t2 = (char*)"00-23";
        t3 = (char*)"59";
    }
    else
    {
        vector<string> time_parts = split(time, ':');
        t1 = (char*) time_parts[0].data();
        t2 = (char*) time_parts[1].data();
        t3 = (char*) time_parts[2].data();
    }
    handleTimes(t1,t2,t3,day,md,m,ts);
}

char* grow_string(char* head, char* tail)
{
    char* s = (char*) calloc((strlen(head) + strlen(tail) + 2), sizeof(char));
    sprintf(s,"%s%s", head, tail);
    destroy_string(head); //IT IS SUPPOSED head ALLOCATED USING MALLOC
    garbage.insert(s);
    return s;
}

char* handleIf(char* head, char* statement)
{
    stringstream ss;
    ss << head << statement << endl << "end";
    return alloc_string((char*)ss.str().data());
}

char* handleIfElse(char* head, char* statement, char* statement2)
{
    stringstream ss;
    ss << head << statement << endl << "else" << endl << statement2 << endl << "end";
    return alloc_string((char*)ss.str().data());
}

char* handleIncludedName(char* name)
{
    stringstream ss;
    ss << "\"" << name << "\"";
    return alloc_string((char*)ss.str().data());
}

char* handleMacroDef(char* name,char* arglist, char* stats)
{
    stringstream ss;
    ss<<"function "<<name<<"("<<arglist<<")"<<endl;
    ss<<stats;
    ss<<"end"<<endl<<endl;
    return alloc_string((char*)ss.str().data());
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
element:   extension
        {
            $$ = $1;
        }
        |  includes
        {
            $$ = $1;
        }
        |  switches
        |  eswitches
        |  ignorepat
        {
            $$ = $1;
        }
        |  word EQ implicit_expr_stat SEMICOLON
        |  LOCAL word EQ implicit_expr_stat SEMICOLON
        |  SEMICOLON 
        { 
            $$ = alloc_string((char*)";"); 
        }
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
            ss << "function()"<<endl<<$2<<"end;";
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
            ss << "local "<<$2<<" = "<<$4<<endl;
            $$ = alloc_string((char*)ss.str().data());
            destroy_string($2);
            destroy_string($4);
        }
        | GOTO target SEMICOLON
        {
            if (($2[0]=='-')&&($2[1]=='-'))
            {
                $$ = grow_string($2,(char*)"\n");
            } else
            {
                stringstream ss;
                ss << "goto "<<$2<<endl;
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
            ss << "for " << $3 << ", " << $5 << ", " << $7 << " do " << endl << $9 << endl << "end";
            $$ = alloc_string((char*)ss.str().data());
            destroy_string($3);
            destroy_string($5);
            destroy_string($7);
            destroy_string($9);
        }
        | WHILE LPAREN implicit_expr_stat RPAREN statement
        {
            stringstream ss;
            ss << "while " << $3 << "do" << endl << $5 << endl << "end";
            $$ = alloc_string((char*)ss.str().data());
            destroy_string($3);
            destroy_string($5);
        }
        | switch_head KET
        {
            $$ = grow_string($1,(char*)"end\n");
        }
        | switch_head case_statements KET
        {
            stringstream ss;           
            ss << $1 << $2 <<"end"<<endl<<"end"<<endl;
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
            ss << "channel." << ac << ":set(" << $3 << ")";
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
        | random_head statement
        {
            $$ = handleIf($1,$2);
            destroy_string($1);
            destroy_string($2);
        }
        | random_head statement ELSE statement
        {
            $$ = handleIfElse($1, $2, $4);
            destroy_string($1);
            destroy_string($2);
            destroy_string($4);
        }
        | if_head statement
        {
            $$ = handleIf($1,$2);
            destroy_string($1);
            destroy_string($2);
        }
        | if_head statement ELSE statement
        {
            $$ = handleIfElse($1, $2, $4);
            destroy_string($1);
            destroy_string($2);
            destroy_string($4);
        }
        | ifTime_head statement
        {
            $$ = handleIf($1,$2);
            destroy_string($1);
            destroy_string($2);
        }
        | ifTime_head statement ELSE statement
        {
            $$ = handleIfElse($1, $2, $4);
            destroy_string($1);
            destroy_string($2);
            destroy_string($4);
        }
        | SEMICOLON
       ;

target: word
        {
            //GOTO LOCAL LABEL => Supported
            $$ = $1;
        }
        | word PIPE word
        {
            //GOTO LABEL IN DIFFERENT EXTENSION : Not Supported
            stringstream ss;
            ss << "-- (ael2lua warning) goto a label on a different extension is not supported (original AEL2 target : ";
            ss << $1 << "|" << $3<<")";
            $$ = alloc_string((char*)ss.str().data());
            destroy_string($1);
            destroy_string($3);
        }   
        | word PIPE word PIPE word
        {
            //GOTO LABEL IN DIFFERENT CONTEXT AND EXTENSION : Not Supported
            stringstream ss;
            ss << "-- (ael2lua warning) goto a label on a different extension and/or context is not supported (original AEL2 target : ";
            ss << $1 << "|" << $3<<"|"<<$5<<")";
            $$ = alloc_string((char*)ss.str().data());
            destroy_string($1);
            destroy_string($3);
            destroy_string($5);
        }
        | DEFAULT PIPE word PIPE word
        {
              //GOTO LABEL IN DIFFERENT CONTEXT AND EXTENSION : Not Supported
            stringstream ss;
            ss << "-- (ael2lua warning) goto a label on a different extension and/or context is not supported (original AEL2 target : ";
            ss << "default" << "|" << $3<<"|"<<$5<<")";
            $$ = alloc_string((char*)ss.str().data());
            destroy_string($3);
            destroy_string($5);

        }
        | word COMMA word
        {
            //GOTO LABEL IN DIFFERENT EXTENSION : Not Supported
            stringstream ss;
            ss << "-- (ael2lua warning) goto a label on a different extension is not supported (original AEL2 target : ";
            ss << $1 << "," << $3<<")";
            $$ = alloc_string((char*)ss.str().data());
            destroy_string($1);
            destroy_string($3);

        }
        | word COMMA word COMMA word    
        {
            //GOTO LABEL IN DIFFERENT CONTEXT AND EXTENSION : Not Supported
            stringstream ss;
            ss << "-- (ael2lua warning) goto a label on a different extension and/or context is not supported (original AEL2 target : ";
            ss << $1 << "," << $3<<","<<$5<<")";
            $$ = alloc_string((char*)ss.str().data());
            destroy_string($1);
            destroy_string($3);
            destroy_string($5);
        }
        | DEFAULT COMMA word COMMA word
        {
            //GOTO LABEL IN DIFFERENT CONTEXT AND EXTENSION : Not Supported
            stringstream ss;
            ss << "-- (ael2lua warning) goto a label on a different extension and/or context is not supported (original AEL2 target : ";
            ss << "default" << "," << $3<<","<<$5<<")";
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
        | word COMMA word AT DEFAULT
        {
           //JUMP TO LABEL (DIFFERENT EXTENSION AND CONTEXT);
           stringstream ss;
           ss << "\"default\",\""<<$3<<"\","<<$5;
           $$ = alloc_string((char*)ss.str().data());
           destroy_string($1);
           destroy_string($3);
        }
        | word AT DEFAULT
        {
            //JUMP TO EXTENSION : supported
            stringstream ss;
            ss << "\"default\",\""<<$1<<"\",1";
            $$ = alloc_string((char*)ss.str().data());
            destroy_string($1);
        }
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
       ;

includedname: 
       word
       {
           $$ = $1;
       }
       | DEFAULT
       {
           $$ = alloc_string((char*) "default");
       }
       ;

includes: 
       INCLUDES BRA includeslist KET
       {
            stringstream ss;
            ss << "include = { " << $3 << " }";
            $$ = alloc_string((char*)ss.str().data());
            destroy_string($3);
       }
       | INCLUDES BRA KET
       {
            $$ = alloc_string((char*) "include = {}");
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
conditional_op : base_expr CONDQUEST base_expr COLON base_expr ;
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

