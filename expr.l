%option noyywrap
%option prefix="exp"
%{
#include <stdio.h>
#include <stdlib.h>
#include "expr.tab.h"

char *expp;

extern int expwrap(void);
%}

NUM [0-9]+ 
NOVAR_WORD (\$[-a-zA-Z0-9"_/.!\*\+\<\>#$}\[\]]|\{[-a-zA-Z0-9"_/.!\*\+\<\>#\$\{}\[\]]|[-a-zA-Z0-9"_/.!\*\+\<\>#}\[\]])*
VAR $\{[-a-zA-Z][-a-zA-Z0-9]*\}

%%

=           { /*printf("EQ\n");*/ return EQ; }
\)          { /*printf("RPAREN\n");*/ return RPAREN; }
\(          { /*printf("LPAREN\n");*/ return LPAREN; }
\}          { /*printf("KET\n");*/ return KET; }
\{          { /*printf("BRA\n");*/ return BRA; }
"]"	        { /*printf("RSBRA\n");*/return RSBRA; }
:           { /*printf("COLON\n");*/ return COLON; }
;           { /*printf("SEMICOLON\n");*/ return SEMICOLON; }
,           { /*printf("COMMA\n");*/ return COMMA; }
"=>"        { /*printf("ARROW\n");*/ return ARROW; }
\|          { /*printf("PIPE\n");*/return PIPE; }
@           { /*printf("AT\n");*/return AT; }
&           { /*printf("AND\n");*/return AND; }
"${"	    { /*printf("VARBEGIN\n");*/return VARBEGIN;}
"$["	    { /*printf("EXPRINIT\n");*/return EXPRINIT;}
"!="	    { /*printf("NOTEQ\n");*/return NOTEQ; }
"=="        { /*printf("EQUAL\n");*/return EQUAL;}
">"	        { /*printf("GT\n");*/return GT; }
"<"	        { /*printf("LT\n");*/return LT; }
">="	    { /*printf("GTEQ\n");*/return GTEQ; }
"<="	    { /*printf("LTEQ\n");*/return LTEQ; }
"+"	        { /*printf("PLUS\n");*/return PLUS; }
"-"	        { /*printf("MINUS\n");*/return MINUS; }
"*"	        { /*printf("MULT\n");*/return MULT; }
"/"	        { /*printf("DIV\n");*/return DIV; }
"%"	        { /*printf("MOD\n");*/return MOD; }
"!"         { /*printf("LOGNOT\n");*/return LOGNOT; }
"=~"	    { /*printf("LIKEOP\n");*/return LIKEOP; }
"?"	        { /*printf("CONDQUEST\n");*/return CONDQUEST; }

{NUM}   {
	    /*printf("VARNAME (%s)\n",yytext);*/
	    expp = (char*)calloc(strlen(yytext)+1,sizeof(char));
	    strcpy(expp,yytext);
	    explval = (YYSTYPE)expp;
	    return NUM;
	    }

{VAR}   {
	    /*printf("VARNAME (%s)\n",yytext);*/
	    expp = (char*)calloc(strlen(yytext)+1,sizeof(char));
	    strcpy(expp,yytext);
	    explval = (YYSTYPE)expp;
	    return VAR;
	    }

{NOVAR_WORD}   {
	    /*printf("VARNAME (%s)\n",yytext);*/
	    expp = (char*)calloc(strlen(yytext)+1,sizeof(char));
	    strcpy(expp,yytext);
	    explval = (YYSTYPE)expp;
	    return NOVAR_WORD;
	    }

%%
