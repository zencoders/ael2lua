%{
#include <stdio.h>
#include <stdlib.h>
#include "ael.tab.h"
extern int yylval;
%}

%%
"="         { return EQ; }
")"         { return RPAREN; }
"("         { return LPAREN; }
"}"         { return KET; }
"{"         { return BRA; }
":"         { return COLON; }
";"         { return SEMICOLON; }
","         { return COMMA; }
"=>"        { return ARROW; }
"|"         { return PIPE; }
"@"         { return AT; }
"&"         { return AND; }
"if"        { return IF; }
"else"      { return ELSE; }
"while"     { return WHILE; }
"case"      { return CASE; }
"default"   { return DEFAULT; }
"pattern"   { return PATTERN; }
"context"   { return CONTEXT; }
"abstract"  { return ABSTRACT; }
"macro"     { return MACRO; }
"globals"   { return GLOBALS; }
"local"     { return LOCAL; }
"ignorepat" { return IGNOREPAT; }
"regexten"  { return REGEXTEN; }
"hint"      { return HINT; }
"random"    { return RANDOM; }
"ifTime"    { return IFTIME; }
"switch"    { return SWITCH; }
"switches"  { return SWITCHES; }
"eswitches" { return ESWITCHES; }
"includes"  { return INCLUDES; }
"goto"      { return GOTO; }
"jump"      { return JUMP; }
"for"       { return FOR; }
"break"     { return BREAK; }
"return"    { return RETURN; }
"continue"  { return CONTINUE; }
"catch"     { return CATCH; }
[-a-zA-Z0-9"_/.\<\>\*\+!$#\[\]][-a-zA-Z0-9"_/.!\*\+\<\>\{\}$#\[\]]*      { return WORD; }
[^=\)\(\}\{:;,(=>)\|@&]*      { return COLLECTED_WORD; }

%%

/*
int main()
{
    yylex();
    return 0;
}
*/

#ifndef yywrap
int yywrap() { return 1; }
#endif
