%{
	#include "header.h"
	#include <stdio.h>
	#include "y.tab.h"
	#include<string.h>

	extern void yyerror(char *);
	static void comment(void);

%}

%option yylineno

D   		[0-9]
L   		[a-zA-Z_]
A   		[a-zA-Z_0-9]


%%
"/*"		{ comment(); }
"//"[^\n]*	;



int		{strcpy(yylval.string,yytext); return(INT); }
float		{strcpy(yylval.string,yytext); return(FLOAT); }
char		{strcpy(yylval.string,yytext); return(CHAR); }
void		{strcpy(yylval.string,yytext); return(VOID); }
main		{strcpy(yylval.string,yytext); return(MAIN); }


"#"			{ return HASH; }
include		{return INCLUDE; }
define		{return DEFINE; }


"math.h"	{return MATH; }
"stdio.h"	{return STDIO; }
"stdlib.h"	{return STDLIB; }
"string.h"	{return STRING; }
"time.h"	{return TIME; }


for		{return (FOR); }
switch	{return (SWITCH);}
case	{return (CASE);}
break	{return (BREAK);}
default {return (DEFAULT);}


{L}{A}*				{strcpy(yylval.string,yytext); return IDENTIFIER;}
{D}+				{strcpy(yylval.string,yytext); return INTEGER_LITERAL;}
{D}+\.{D}+			{strcpy(yylval.string,yytext); return FLOAT_LITERAL;}
\"{A}+(".h"|".c")\"	{return HEADER_LITERAL;}
L?\"(\\.|[^\\"])*\"	{return(STRING_LITERAL);}

"+="		{return(ADD_ASSIGN);}
"-="		{return(SUB_ASSIGN);}

"++"		{return(INC_OP);}
"--"		{return(DEC_OP);}
"<="		{strcpy(yylval.string,yytext); return(LE_OP);}
">="		{strcpy(yylval.string,yytext); return(GE_OP);}
"=="		{strcpy(yylval.string,yytext); return(EQ_OP);}
"!="		{strcpy(yylval.string,yytext); return(NE_OP);}
[ ]+		;	
";"|"^"|"|"|"?"|"{"|"}"|","|":"|"="|"("|")"|"["|"]"|"."|"&"|"!" {return yytext[0];}
"-"		{strcpy(yylval.string,yytext);return('-');}
"+"		{strcpy(yylval.string,yytext);return('+');}
"*"		{strcpy(yylval.string,yytext);return('*');}
"/"		{strcpy(yylval.string,yytext);return('/');}
"%"		{strcpy(yylval.string,yytext);return('%');}
"<"		{strcpy(yylval.string,yytext);return('<');}
">"		{strcpy(yylval.string,yytext);return('>');}
\n 		;
[\n]+		;
\t 		;	
.		{printf("No Match, Invalid Expression %s\n", yytext); }
%%
int yywrap(void)
{
	return 1;
}


static void comment(void)
{
    int c;

    while ((c = input()) != 0){
        if (c == '*')
        {
            while ((c = input()) == '*')
                ;

            if (c == '/')
                return;

            if (c == 0)
                break;
        }
    }
    printf("unterminated comment");
}

