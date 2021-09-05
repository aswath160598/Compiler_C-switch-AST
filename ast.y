%{
	#include <stdio.h>
	#include <stdlib.h>
	#include <string.h>
	#include <ctype.h>
	#include <stdarg.h>
	#include "header.h"
	void yyerror(char*);
	int yylex();
	int ex (nodeType *p, int flag);
	nodeType *opr(int oper, int nops, ...);
	nodeType *id(char *identifier);
	nodeType *con(char *value);
	int if_assign = 1;
	int only_comp = 0;
%}

%union
{
	int ival;
	nodeType *nPtr;
	char string[128];
}

%token HASH INCLUDE DEFINE STDIO STDLIB MATH STRING TIME
%token	IDENTIFIER INTEGER_LITERAL FLOAT_LITERAL STRING_LITERAL HEADER_LITERAL
%token	INC_OP DEC_OP LE_OP GE_OP EQ_OP NE_OP
%token	ADD_ASSIGN SUB_ASSIGN
%token	CHAR INT FLOAT VOID MAIN
%token	FOR SWITCH DEFAULT BREAK CASE
%type <string> IDENTIFIER INTEGER_LITERAL FLOAT_LITERAL STRING_LITERAL 
%type <nPtr> primary_expression postfix_expression multiplicative_expression
%type <nPtr> unary_expression additive_expression relational_expression
%type <nPtr> equality_expression conditional_expression assignment_expression case_statement_list default_line
%type <nPtr> statement compound_statement expression_statement selection_statement case_statement block_item
%type <nPtr> expression init_declarator init_declarator_list constant_expression break_statement
%type <nPtr> iteration_statement block_item_list translation_unit
%type <nPtr> external_declaration declaration


%start translation_unit

%%
headers
	: HASH INCLUDE HEADER_LITERAL 
	| HASH INCLUDE '<' libraries '>'
	;

libraries
	: STDIO
	| STDLIB
	| MATH
	| STRING
	| TIME
	;

primary_expression
	: IDENTIFIER		{$$ = id($1);}
	| INTEGER_LITERAL	{$$ = con($1);}
	| FLOAT_LITERAL		{$$ = con($1);}
	| STRING_LITERAL	{$$ = con($1);}
	| '(' expression ')'	{$$ = $2;}
	;

postfix_expression
	: primary_expression	{$$ = $1;}
	| postfix_expression '(' ')'
	| postfix_expression '.' IDENTIFIER 
	{
	char *tmp = strcat($1->id.name,".");
	tmp = strcat(tmp, $3);
	printf(" %s\n", tmp); 			
	$$ = id(tmp);
	}
	| postfix_expression INC_OP			
	{
	$$ = opr('=', 2, $1, opr('+', 2, $1, con("1") ) );
	}
	| postfix_expression DEC_OP			
	{
	$$ = opr('=', 2, $1, opr('-', 2, $1, con("1") ) );										
	}
	| INC_OP primary_expression			
	{
	$$ = opr('=', 2, $2, opr('+', 2, $2, con("1") ) );										
	}
	| DEC_OP primary_expression			
	{
	$$ = opr('=', 2, $2, opr('-', 2, $2, con("1") ) );										
	}
	;

unary_expression
	: postfix_expression 			{$$ = $1;}
	| '+' unary_expression			{$$ = opr('+', 1, $2);}
	| '-' unary_expression			{$$ = opr('+', 1, $2);}	
	;

multiplicative_expression
	: unary_expression						{$$ = $1;}
	| multiplicative_expression '*' unary_expression		{$$ = opr('*', 2, $1, $3);}
	| multiplicative_expression '/' unary_expression		{$$ = opr('/', 2, $1, $3);}		
	| multiplicative_expression '%' unary_expression		{$$ = opr('%', 2, $1, $3);}
	;

additive_expression
	: multiplicative_expression					{$$ = $1;}
	| additive_expression '+' multiplicative_expression		{$$ = opr('+', 2, $1, $3);}
	| additive_expression '-' multiplicative_expression		{$$ = opr('-', 2, $1, $3);}
	;

relational_expression
	: additive_expression
	| relational_expression '<' additive_expression			{$$ = opr('<', 2, $1, $3);}
	| relational_expression '>' additive_expression			{$$ = opr('>', 2, $1, $3);}
	| relational_expression LE_OP additive_expression		{$$ = opr(LE_OP, 2, $1, $3);}
	| relational_expression GE_OP additive_expression		{$$ = opr(GE_OP, 2, $1, $3);}
	;

equality_expression
	: relational_expression						{$$ = $1;}
	| equality_expression EQ_OP relational_expression 		{$$ = opr(EQ_OP, 2, $1, $3);}
	| equality_expression NE_OP relational_expression		{$$ = opr(NE_OP, 2, $1, $3);}
	;

conditional_expression
	: equality_expression						{$$ = $1;}
	| equality_expression '?' expression ':' conditional_expression	{$$ = opr('?', 2, $1, opr(':', 2, $3, $5) );}
	;

assignment_expression
	: conditional_expression					{$$ = $1;}
	| unary_expression '=' assignment_expression 			{$$ = opr('=', 2, $1, $3);}
	| unary_expression ADD_ASSIGN assignment_expression 		{$$ = opr('=', 2, $1, opr('+', 2, $1, $3) );}
	| unary_expression SUB_ASSIGN assignment_expression 		{$$ = opr('=', 2, $1, opr('-', 2, $1, $3) );}
	;

expression
	: assignment_expression						{$$ = $1;}
	| expression ',' assignment_expression
	;

constant_expression
	: conditional_expression					{}
	;

declaration
	: type_specifier init_declarator_list ';'			{$$ = opr(';', 1, $2);}
	;

init_declarator_list
	: init_declarator									{$$ = $1;}
	| init_declarator_list ',' init_declarator			{$$ = opr(',', 2, $1, $3);}
	;

init_declarator
	: IDENTIFIER '=' assignment_expression 				{$$ = opr('=', 2, id($1), $3);}
	| IDENTIFIER										{$$ = id($1);}
	;

type_specifier
	: VOID
	| CHAR
	| INT
	| FLOAT
	;
statement
	: compound_statement	{$$ = $1;}
	| expression_statement	{$$ = $1;}
	| iteration_statement	{$$ = $1;}
	| selection_statement	{$$ = $1;}
	;

compound_statement
	: '{' block_item_list '}'	{$$ = $2;}
	;

block_item_list
	: block_item	{$$ = $1;}
	| block_item_list block_item {$$ = opr(';', 2, $1, $2);}
	;

block_item
	: declaration	{$$ = $1;}
	| statement		{$$ = $1;}
	;

expression_statement
	: expression ';' {$$ = $1;}
	;

iteration_statement
	: FOR '(' expression_statement expression_statement expression ')' statement {$$ = opr(FOR, 4, $3, $4, $5, $7);}
	| FOR '(' declaration expression_statement expression ')' statement {$$ = opr(FOR, 4, $3, $4, $5, $7);}
	;
selection_statement	
	: SWITCH '(' expression ')' '{' case_statement_list '}' {$$ = opr(SWITCH, 2, $3, $6);}
	;
case_statement_list
	: case_statement {$$ = $1;}
	| case_statement break_statement case_statement_list {$$ = opr(';', 3, $1, $2, $3);}
	| case_statement case_statement_list {$$ = opr(';', 2, $1, $2);}
	| default_line {$$ = $1;}
	| break_statement {$$ = opr(';',1,$1);}
	;
case_statement
	: CASE constant_expression ':' block_item_list {$$ = opr(CASE, 2, $2, $4);}
	| CASE constant_expression ':' break_statement {$$ = opr(CASE, 2, $2, $4);}
	;
break_statement
	: BREAK ';' {$$ = id("break");}
	;
default_line
	: DEFAULT ':' block_item_list {$$ = opr(DEFAULT, 1, $3);}
	;
translation_unit
	: external_declaration
	| translation_unit external_declaration 	;

external_declaration
	: INT MAIN '(' ')' compound_statement	{ex($5, 0);}
	| declaration	{if(if_assign){	ex($1, 2);}}	
	| headers 	
	;

%%

int main(){

	extern FILE *yyout;
	yyout = fopen("output", "w");
	fprintf(yyout, "%d ", 1);
	if(!yyparse())
	{
		printf("Parsing Successful\n");
	}
	else
		printf("Parsing Unsuccessful\n");
	fclose(yyout);

	return 0;
}

void yyerror(char *s){
	printf("%s\n", s);
	return;
}
nodeType *con(char *value)
{
	nodeType *p;
	if ((p = malloc(sizeof(nodeType))) == NULL)
		yyerror("out of memory");
	p->type = typeCon;
	strcpy(p->con.value, value);
	return p;
}
nodeType *id(char *identifier) {
	nodeType *p;
	if ((p = malloc(sizeof(nodeType))) == NULL)
		yyerror("out of memory");
	p->type = typeId;
	strcpy(p->id.name,identifier);
	return p;
}

nodeType *opr(int oper, int nops, ...)
{
	va_list ap;
	nodeType *p;
	int i;
	if ((p = malloc(sizeof(nodeType) +(nops-1) * sizeof(nodeType *))) == NULL)
		yyerror("out of memory");
	p->type = typeOpr;
	p->opr.oper = oper;
	p->opr.nops = nops;
	va_start(ap, nops);
	for (i = 0; i < nops; i++)
		p->opr.op[i] = va_arg(ap, nodeType*);
	va_end(ap);
	return p;
}
