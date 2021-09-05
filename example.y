%{
	#include <stdio.h>
	#include <stdlib.h>
	#include <string.h>
	#include <ctype.h>
	#define LIMIT 1024
	#define MAX_SYMBOLS 100			// defines max no of record in each symbol table
	#define MAX_SCOPE 10			// defines max no of scopes allowed 
	#define NEWSCOPE 1				// denoted new scope
	#define OLDSCOPE 0				// denotes old scope
	#define TYPE_LENGTH 6			// length of type int float void ....
	#define MAX_NO_OF_STRUCT 10		// max_no of structure which can be defined in a scope
	#define STRUCT_FLAG 2			// Flag to know struct which is declared
	
	
	/* the start index for the member of nested struct in the parent struct  initialized at nested_struct rule */ 
	int nested_struct_start_index;
	
	// keyword_Array
	char keywords[7][8] = {"char","int","float","void","main","for","switch","case","default","break"};
	int c = 0;
	int scope = NEWSCOPE;
	void yyerror(const char*);
	int yylex();
	
	int ternary_flag = 0;
	int not_defined = 0;
	
	int error = 0;
	struct symbol {
		char name[LIMIT];
		char type[LIMIT];
		char value[LIMIT];
	};
	
	
	struct stack_for_symbol_tables{
		int index_to_insert;
		struct symbol symbol_table[MAX_SYMBOLS];
	}symbol_table_stack[MAX_SCOPE];
	
	
	int top_stack_for_symbol_tables = -1;
	
	// called to perform all artihmatic operations
	void fun(char *result ,char *arg1,char *arg2,char *arg3);
	
	/* called to push the varaibles in the current scope */
	int push_my(char *type,char *name,char *value,int flag);

	/* to pop the scope */
	int pop_my();
	
	/* to check if the varaible of current scope is declared or not
	   return value 1 if not else -1; 
	*/
	int search_my(char *name,int flag);
	
	void display();
	
	int update_variable_value(char *name,char *value);
	
	void check(char *arg1,char *arg3);
	
	void coercion(char *type,char *value);
	
	void init_symbol_table();
	
	void write_to_file();
%}
%union
{
	int ival;
	char string[128];
}
%token  HASH INCLUDE DEFINE STDIO STDLIB MATH STRING TIME
%token	IDENTIFIER INTEGER_LITERAL FLOAT_LITERAL STRING_LITERAL HEADER_LITERAL
%token	INC_OP DEC_OP LE_OP GE_OP EQ_OP NE_OP
%token	ADD_ASSIGN SUB_ASSIGN
%token	CHAR INT FLOAT VOID MAIN
%token	FOR 
%type <string> multiplicative_expression unary_expression init_declarator_list init_declarator declaration type_specifier assignment_expression IDENTIFIER additive_expression relational_expression equality_expression conditional_expression expression primary_expression postfix_expression LE_OP GE_OP EQ_OP NE_OP '+' '-' '<' '>' '%' '*' '/'
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
	: IDENTIFIER
	| INTEGER_LITERAL
	| FLOAT_LITERAL
	| STRING_LITERAL	
	| '(' expression ')'	
	{
		int flag = 1;
		int i=0;
		while($2[i] != '\0')
		{
			if(!isdigit($2[i]))
			{
				flag = 0;
				break;
			}
			i++;
		}
		if(!flag)
		{
			strcpy($$,"(");
			strcpy($$+1,$2);
			strcat($$,")");
			$$[strlen($$)] = '\0';
		}
		else
		{
			strcpy($$,$2);
		}
	}
	;
postfix_expression
	: primary_expression
	| postfix_expression '(' ')'
	| postfix_expression '.' IDENTIFIER
	{
		char temp[LIMIT];
		strcpy(temp,$1);
		strcat(temp,".");
		strcat(temp,$3);
		strcpy($$,temp); 
		int value = update_variable_value($$,"");
		if(value == -1)
		{
			FILE *fptr = fopen("error.txt","a");
			fprintf(fptr,"Varaible %s is not defined\n",$$);
			error = 1;
			fclose(fptr);
			not_defined = -1;
		}
	}
	| postfix_expression INC_OP
	| postfix_expression DEC_OP
	| INC_OP primary_expression
	| DEC_OP primary_expression
	;
unary_expression
	: postfix_expression
	| unary_operator unary_expression
	;
unary_operator
	: '+'
	| '-'
	;
multiplicative_expression
	: unary_expression
	| multiplicative_expression '*' unary_expression	
	{
		check($1,$3);	// to check if varaibles used are defined or not
		fun($$,$1,$2,$3);
	}
	| multiplicative_expression '/' unary_expression	
	{
		check($1,$3);	// to check if varaibles used are defined or not
		fun($$,$1,$2,$3);
	}
	| multiplicative_expression '%' unary_expression  	
	{
		check($1,$3);	// to check if varaibles used are defined or not
		fun($$,$1,$2,$3);
	}
	;
additive_expression
	: multiplicative_expression
	| additive_expression '+' multiplicative_expression 
	{
		check($1,$3);	// to check if varaibles used are defined or not
		fun($$,$1,$2,$3);
 	}
	| additive_expression '-' multiplicative_expression	
	{
		check($1,$3);	// to check if varaibles used are defined or not
		fun($$,$1,$2,$3);
	}
	;
relational_expression
	: additive_expression 
	| relational_expression '<' additive_expression 	
	{
		check($1,$3);	// to check if varaibles used are defined or not
		fun($$,$1,$2,$3);
	}
	| relational_expression '>' additive_expression		
	{
		check($1,$3);	// to check if varaibles used are defined or not
		fun($$,$1,$2,$3);
	}
	| relational_expression LE_OP additive_expression	
	{
		check($1,$3);	// to check if varaibles used are defined or not
		fun($$,$1,$2,$3);
	}
	| relational_expression GE_OP additive_expression	
	{
		check($1,$3);	// to check if varaibles used are defined or not
		fun($$,$1,$2,$3);
	}
	;
equality_expression
	: relational_expression
	| equality_expression EQ_OP relational_expression	
	{
		check($1,$3);	// to check if varaibles used are defined or not
		fun($$,$1,$2,$3);
	}
	| equality_expression NE_OP relational_expression	
	{
		check($1,$3);	// to check if varaibles used are defined or not
		fun($$,$1,$2,$3);
	}
	;
conditional_expression
	: equality_expression
	| equality_expression '?'{ if( strlen($1) == 1 && !strcmp($1,"1") ) ternary_flag = 1; }expression ':' conditional_expression
	;
assignment_expression
	: conditional_expression
	| unary_expression assignment_operator assignment_expression	
	{
		if(not_defined == 0 || ternary_flag == 1)
		{
			int value = update_variable_value($1,$3);
			if( value == -1 )
			{
				not_defined = 1;
				FILE *fptr = fopen("error.txt","a");
				fprintf(fptr,"Varaible %s is not defined\n",$$);
				error = 1;
				fclose(fptr);
			}
		}
		not_defined = 0;
		ternary_flag = 0;
	}
	;
assignment_operator
	: '='
	| ADD_ASSIGN
	| SUB_ASSIGN
	;
expression
	: assignment_expression
	| expression ',' assignment_expression
	;
constant_expression
	: conditional_expression
	;
declaration
	: type_specifier ';'		
	| type_specifier init_declarator_list ';'
	{
		char *type = $1;		
		/* if the $2 has '_' character then varaible has value associated it*/
		if(index($2,'?') != NULL)
		{
			
			/* to get the index of '_' in $2 */
			char *_ = index($2, '?');
			
			/* to get the no of character in the name string */
			int _index = (int)(_ - $2);
			
			/* to get the no of character in the value string */
			int value_length = strlen($2) - _index;
			
			char name[_index];
			strncpy(name,$2,_index);
			name[_index] = '\0';
			
			char value[value_length];
			strncpy(value,$2+_index+1,value_length);
			value[value_length] = '\0';
			
			coercion(type,value);
			if(not_defined == 0)
				push_my(type,name,value,scope);
			not_defined = 0;
		}
		else
		{
			char name[strlen($2)+1];
			strcpy(name,$2);
			push_my(type,name,"",scope);
		}
	}
	;
init_declarator_list
	: init_declarator
	| init_declarator_list ',' init_declarator
	;
init_declarator
	: IDENTIFIER '=' assignment_expression 	
	{										
		strncpy($$+strlen($$), "?", 2);
		$$[strlen($$)] = '\0';
		strncpy($$+strlen($$), $3, sizeof($3));
	}
	| IDENTIFIER{strncpy($$,$1,strlen($1) - 1);$$[strlen($$)] = '\0';}	
	;
type_specifier
	: VOID
	| CHAR
	| INT
	| FLOAT
	;
statement
	: compound_statement
	| expression_statement
	| iteration_statement
	;
compound_statement
	: '{' '}'
	| '{' new_scope block_item_list '}' new_scope_end
	;
new_scope
	:		{scope = NEWSCOPE;}	
	;
new_scope_end
	:		{
				scope = OLDSCOPE;
				write_to_file();
				pop_my();
			}
	;
block_item_list
	: block_item
	| block_item_list block_item
	;
block_item
	: declaration
	| statement
	;
expression_statement
	: ';'
	| expression ';'
	;
iteration_statement
	: FOR '(' expression_statement expression_statement expression ')' statement
	;
translation_unit
	: external_declaration						
	| translation_unit external_declaration
	;
external_declaration
	: INT MAIN '(' ')' compound_statement	{write_to_file();}	
	| declaration
	| headers
	;
%%
void yyerror(const char *str)
{
	fflush(stdout);
	fprintf(stderr, "*** %s\n", str);
}
int main(){
	init_symbol_table();
	if(!yyparse())
	{
		printf("Successful\n");
	}
	else
		printf("Unsuccessful\n");
	return 0;
}
void init_symbol_table()
{
	FILE *fptr = fopen("symbol_table.txt","w");
	fclose(fptr);
	FILE *fptr1 = fopen("error.txt","w");
	fclose(fptr1);
	top_stack_for_symbol_tables = 0;
	int *index_to_insert = &symbol_table_stack[top_stack_for_symbol_tables].index_to_insert;
	int i;
	for(i=0;i<NO_OF_KEYWORD;i++)
	{
		strcpy(symbol_table_stack[top_stack_for_symbol_tables].symbol_table[*index_to_insert].name,keywords[i]);
		strcpy(symbol_table_stack[top_stack_for_symbol_tables].symbol_table[*index_to_insert].type,"KEYWORD");
		strcpy(symbol_table_stack[top_stack_for_symbol_tables].symbol_table[*index_to_insert].value,"");
		symbol_table_stack[top_stack_for_symbol_tables].index_to_insert++;
	}
	write_to_file();
}
void write_to_file()
{
	FILE *fptr = fopen("symbol_table.txt","a");
	int i = 0;
	if(top_stack_for_symbol_tables != -1)
	{
		int length = symbol_table_stack[top_stack_for_symbol_tables].index_to_insert;
		for(i=0;i<length;i++)
		{
			fprintf(fptr,"TYPE : %5s\t\tNAME : %5s\t\tVALUE : %5s\n",symbol_table_stack[top_stack_for_symbol_tables].symbol_table[i].type,symbol_table_stack[top_stack_for_symbol_tables].symbol_table[i].name,symbol_table_stack[top_stack_for_symbol_tables].symbol_table[i].value);
		}
	}
	fprintf(fptr,"\n");
	fclose(fptr);
}
void coercion(char *type,char *value)
{	
	char buf[6];
	int i=0;
	int is_digit = 1;
	int is_decimal = 0;
	//printf("Type : %s Value : %s\n",type,value);
	while(value[i] != '\0')
	{
		if( isdigit(value[i]) || value[i] == '.')
		{
			if(value[i] == '.')
				is_decimal = 1; 
		}
		else
		{
			is_digit = 0;
			break;
		}
		i++;
	}
	if(!strcmp(type,"int") && is_digit)
	{
		int temp = atoi(value);
		gcvt(temp,6,buf);
		buf[strlen(buf)] = '\0';
		strcpy(value,buf);
		if(is_decimal)
		{
			FILE *fptr = fopen("error.txt","a");
			error = 1;
			fprintf(fptr,"Warning : data loss may occur.Converting float to int\n");
			fclose(fptr);
		}
	}
	else if(!strcmp(type,"float") && is_digit)
	{
		float temp = atof(value);
		gcvt(temp,6,buf);
		buf[strlen(buf)] = '\0';
		strcpy(value,buf);
	}
}
int search_my(char *name,int flag)
{
	if(!flag)
	{
		int length = symbol_table_stack[top_stack_for_symbol_tables].index_to_insert;
		int i = 0;
		while(i<length)
		{
			if(!strcmp(name,symbol_table_stack[top_stack_for_symbol_tables].symbol_table[i].name))
				return -1;
			i++;
		}
	}
	return 1;
}
int push_my(char *type,char *name,char *value,int flag)
{
	if(top_stack_for_symbol_tables == MAX_SCOPE)
		printf("Cannot have more than %d Scope in a program",MAX_SCOPE);
	else
	{
		if( top_stack_for_symbol_tables != -1 && strlen(type) != 0 && search_my(name,flag) == -1 )
		{
			FILE *fptr = fopen("error.txt","a");
			error = 1;
			fprintf(fptr,"Cannot have multiple decleration for same variable %s\n",name);
			fclose(fptr);
			return -1;	
		}
		else
		{
			if(flag == NEWSCOPE)
			{
				top_stack_for_symbol_tables++;
				scope = OLDSCOPE;
			}
			int index_to_insert = symbol_table_stack[top_stack_for_symbol_tables].index_to_insert;
			if(symbol_table_stack[top_stack_for_symbol_tables].index_to_insert <= MAX_SYMBOLS)
			{
				strcpy(symbol_table_stack[top_stack_for_symbol_tables].symbol_table[index_to_insert].name,name);
				strcpy(symbol_table_stack[top_stack_for_symbol_tables].symbol_table[index_to_insert].type,type);
				/*
				char buf[6];
				if(!strcmp(type,"float"))
				{
					float temp = atof(value);
					char buf[6];
					gcvt(temp,6,buf);
					buf[strlen(buf)] = '\0';
				}
				else if(!strcmp(type,"int"))
				{
					int temp = atoi(value);
					gcvt(temp,6,buf);
					buf[strlen(buf)] = '\0';
				}
				*/
				strcpy(symbol_table_stack[top_stack_for_symbol_tables].symbol_table[index_to_insert].value,value);
				symbol_table_stack[top_stack_for_symbol_tables].index_to_insert += 1;
			}
			else
			{
				printf("Cannot have more than %d Symbols in each scope",MAX_SYMBOLS);
				return -1;
			}
			return 0;
		}
	}
}
int pop_my()
{
	if(top_stack_for_symbol_tables == -1)
	{
		printf("No Scope Present");
		return -1;
	}
	else
	{
		// setting index_to_insert of top_stack_for_symbol_tables to 0 
		symbol_table_stack[top_stack_for_symbol_tables].index_to_insert = 0;
		
		// setting struct_index_to_insert of top_stack_for_symbol_tables to 0 and also all the index_to_insert_member of struct_defined
		int struct_index_to_insert =  symbol_table_stack[top_stack_for_symbol_tables].struct_index_to_insert;
		int i;
		for(i = 0;i<struct_index_to_insert;i++)
			symbol_table_stack[top_stack_for_symbol_tables].struct_defined[i].index_to_insert_member = 0;
		symbol_table_stack[top_stack_for_symbol_tables].struct_index_to_insert = 0;
		
		// need to clear stack top before decrementing
		top_stack_for_symbol_tables--; 
		return 0;
	}
}
void display()
{
	int i = 0;
	if(top_stack_for_symbol_tables != -1)
	{
		int length = symbol_table_stack[top_stack_for_symbol_tables].index_to_insert;
		for(i=0;i<length;i++)
		{
			printf("TYPE : %s\tNAME : %s\tVALUE : %s\n",symbol_table_stack[top_stack_for_symbol_tables].symbol_table[i].type,symbol_table_stack[top_stack_for_symbol_tables].symbol_table[i].name,symbol_table_stack[top_stack_for_symbol_tables].symbol_table[i].value);
		}
	}
}
void fun(char *result ,char *arg1,char *arg2,char *arg3)
{
	int arg1_length = strlen(arg1);
	int arg3_length = strlen(arg3);
	int i=arg1_length-1;
	int j = 0;
	if((isdigit(arg1[i]) | arg1[i] == '.') || (isdigit(arg3[j])  | arg3[j] == '.'))
	{
		float temp; 
		if(!strcmp(arg2,"*"))
		{
			while((i >= 0) && (isdigit(arg1[i]) | arg1[i] == '.'))
			{
				i--;
			}
			
			while((j < arg3_length) && (isdigit(arg3[j])  | arg3[j] == '.'))
			{
				j++;
			}
			
			if(i+1 <= arg1_length-1 && j-1 >= 0)
			{
				char temp_arg3[j];
				strncpy(temp_arg3,arg3,j);
				
				if(!strcmp(arg2,"*"))
					temp = atof(arg1+(i+1)) * atof(temp_arg3);
				else if(!strcmp(arg2,"/"))
					temp = atof(arg1+(i+1)) / atof(temp_arg3);
				else if(!strcmp(arg2,"%"))
					temp = atoi(arg1+(i+1)) % atoi(temp_arg3);
				else if(!strcmp(arg2,"+"))
					temp = atof(arg1+(i+1)) + atof(temp_arg3);
				else if(!strcmp(arg2,"-"))
					temp = atof(arg1+(i+1)) - atof(temp_arg3);
				else if(!strcmp(arg2,"<"))
					temp = atof(arg1+(i+1)) < atof(temp_arg3);
				else if(!strcmp(arg2,">"))
					temp = atof(arg1+(i+1)) > atof(temp_arg3);
				else if(!strcmp(arg2,">="))
					temp = atof(arg1+(i+1)) >= atof(temp_arg3);
				else if(!strcmp(arg2,"<="))
					temp = atof(arg1+(i+1)) <= atof(temp_arg3);
				else if(!strcmp(arg2,"!="))
					temp = atof(arg1+(i+1)) != atof(temp_arg3);
				else if(!strcmp(arg2,"=="))
					temp = atof(arg1+(i+1)) == atof(temp_arg3);
				
				char buf[128];
				gcvt(temp,6,buf);
				strcat(buf,arg3+j);
				strncpy(arg1+i+1,buf,sizeof(buf));
				strcpy(result,arg1);
				return;
			}
			else
			{
				strncpy(result,arg1,sizeof(arg1));
				strcat(result,arg2);
				strcat(result,arg3);
				result[strlen(result)] = '\0';
				return;
			}
		}
	}
	else
	{
		char *p[128];
		strncpy(result,arg1,sizeof(arg1));
		result[strlen(result)] = '\0';
		strcat(result,arg2);
		result[strlen(result)] = '\0';
		strcat(result,arg3);
		result[strlen(result)] = '\0';
	}	
}
int update_variable_value(char *name,char *value)
{
	int i,j;
	int index_to_insert;
	char *temp_name;
	for(i=top_stack_for_symbol_tables;i>=0;i--)
	{
		index_to_insert = symbol_table_stack[i].index_to_insert;
		for(j=0;j<index_to_insert;j++)
		{
			temp_name = symbol_table_stack[i].symbol_table[j].name;
			if(!strcmp(temp_name,name))
			{
				if(strlen(value) == 0)
					return 1;
				value[strlen(value)] = '\0';
				strcpy(symbol_table_stack[i].symbol_table[j].value,value);
				return 1;
			}
		}
	}
	return -1;	
}
void check(char *arg1,char *arg3)
{
	char temp_name[128];
	int i=0;
	int flag_operator = 0;	// means argument passed doesn't have operator
	int value;
	if( !isdigit(arg1[0]) && arg1[0] != '(' )
	{
		while( arg1[i] != '\0' )
		{
			if( !isalnum(arg1[i]) )

			{
				flag_operator = 1;				
				break;
			}
			i++;
		}
		if( !flag_operator )
		{
			value = update_variable_value(arg1,"");
			if(value == -1)
			{
				not_defined = 1;
				FILE *fptr = fopen("error.txt","a");
				fprintf(fptr,"Varaible %s is not defined\n",arg1);
				error = 1;
				fclose(fptr);
			}
		}
	}
	i=0;
	flag_operator = 0;
	if( !isdigit(arg3[0]) && arg3[0] != '(' )
	{
		while( arg3[i] != '\0' )
		{
			if( !isalnum(arg3[i]) )
			{
				flag_operator = 1;				
				break;
			}
			i++;
		}
		if( !flag_operator )
		{
			value = update_variable_value(arg3,"");
			if(value == -1)
			{
				not_defined = 1;
				FILE *fptr = fopen("error.txt","a");
				fprintf(fptr,"Varaible %s is not defined\n",arg3);
				error = 1;
				fclose(fptr);
			}
		}
	}
	
}

