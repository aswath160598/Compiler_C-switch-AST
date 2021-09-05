typedef enum { typeCon, typeId, typeOpr } nodeEnum;


typedef struct 
{
	char value[100];
} conNodeType;

typedef struct
{
	char name[100];
} idNodeType;

typedef struct 
{
	int oper;
	int nops;
	struct nodeTypeTag *op[1];
} oprNodeType;

typedef struct nodeTypeTag 
{
	nodeEnum type;
	union
	{
		conNodeType con;
		idNodeType id;
		oprNodeType opr;
	};
}nodeType;
