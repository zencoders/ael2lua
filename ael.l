%option noyywrap
%{
#include <stdio.h>
#include <stdlib.h>
#include "ael.tab.h"
char *p;

extern int yywrap(void);

%}

WORD [-a-zA-Z0-9"_/.\<\>\*\+!$#\[\]][-a-zA-Z0-9"_/.!\*\+\<\>\{\}$#\[\]]*

%%
=           { /*printf("EQ\n");*/ return EQ; }
\)          { /*printf("RPAREN\n");*/ return RPAREN; }
\(          { /*printf("LPAREN\n");*/ return LPAREN; }
\}          { /*printf("KET\n");*/ return KET; }
\{          { /*printf("BRA\n");*/ return BRA; }
:           { /*printf("COLON\n");*/ return COLON; }
;           { /*printf("SEMICOLON\n");*/ return SEMICOLON; }
,           { /*printf("COMMA\n");*/ return COMMA; }
"=>"        { /*printf("ARROW\n");*/ return ARROW; }
\|          { /*printf("PIPE\n");*/return PIPE; }
@           { /*printf("AT\n");*/return AT; }
&           { /*printf("AND\n");*/return AND; }
"if"        { /*printf("IF\n");*/return IF; }
"else"      { /*printf("ELSE\n");*/return ELSE; }
"while"     { /*printf("WHILE\n");*/return WHILE; }
"case"      { /*printf("CASE\n");*/return CASE; }
"default"   { /*printf("DEFAULT\n");*/return DEFAULT; }
"pattern"   { /*printf("PATTERN\n");*/return PATTERN; }
"context"   { /*printf("CONTEXT\n");*/return CONTEXT; }
"abstract"  { /*printf("ABSTRACT\n");*/return ABSTRACT; }
"macro"     { /*printf("MACRO\n");*/return MACRO; }
"globals"   { /*printf("GLOBALS\n");*/return GLOBALS; }
"local"     { /*printf("LOCAL\n");*/return LOCAL; }
"ignorepat" { /*printf("IGNOREPAT\n");*/return IGNOREPAT; }
"regexten"  { /*printf("REGEXTEN\n");*/return REGEXTEN; }
"hint"      { /*printf("HINT\n");*/return HINT; }
"random"    { /*printf("RANDOM\n");*/return RANDOM; }
"ifTime"    { /*printf("IFTIME\n");*/return IFTIME; }
"switch"    { /*printf("SWITCH\n");*/return SWITCH; }
"switches"  { /*printf("SWITCHES\n");*/return SWITCHES; }
"eswitches" { /*printf("ESWITCHES\n");*/return ESWITCHES; }
"includes"  { /*printf("INCLUDES\n");*/return INCLUDES; }
"goto"      { /*printf("GOTO\n");*/return GOTO; }
"jump"      { /*printf("JUMP\n");*/return JUMP; }
"for"       { /*printf("FOR\n");*/return FOR; }
"break"     { /*printf("BREAK\n");*/return BREAK; }
"return"    { /*printf("RETURN\n");*/return RETURN; }
"continue"  { /*printf("CONTINUE\n");*/return CONTINUE; }
"catch"     { /*printf("CATCH\n");*/return CATCH; }

{WORD}      { 
        /*printf("WORD");*/
        p=(char*) calloc(strlen(yytext)+1,sizeof(char));
        strcpy(p, yytext);
        yylval = (YYSTYPE)p;
        return WORD; 
    }

\n  { }
[ \t]+  { }
%%

