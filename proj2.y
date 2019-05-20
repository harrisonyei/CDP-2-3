%{
#include <iostream>
#include <string>
#include <stdio.h>
#include <cmath>
#include "symbols.hpp"
#include "lex.yy.cpp"
#define Trace(t) if (Opt_P) cout<<"TRACE => "<<t<<endl;
using namespace std;
void yyerror(string s);

int Opt_P = 1;		// print trace message
int Opt_DS = 1;		// dump symboltable when function or compound parse finished
SymbolTableList stl;
vector<vector<idInfo>> fpstack;
int mainFunc = 0;
%}

/* type */
%union {
	int val;
	double dval;
	bool bval;
	string* sval;
	idInfo* idinfo;
	int type;
}

/* tokens */

/* Operator : length > one char */
%token AND OR EQ NEQ GE LE

// keywords 
%token ASSIGNMENT_token BEGIN_token END EXIT FN MODULE PRINT PRINTLN PROCEDURE REPEAT RETURN RECORD TYPE USE
%token IF ELSE DO WHILE UNTIL FOR LOOP CONTINUE BREAK CASE THEN READ
%token ARRAY OF BOOLEAN CHAR VAR CONST INTEGER REAL STRING VOID

%token <sval> ID 
%token <val> INT_CONST 
%token <bval> BOOL_CONST 
%token <dval> REAL_CONST 
%token <sval> STR_CONST

/* type declare for non-terminal symbols */
%type <idinfo> const_value expression bool_expression func_invocation
%type <type> var_type opt_func_type

/* precedence */
%left OR
%left AND
%left '~'
%left '<' '>' LE GE EQ NEQ
%left '+' '-'
%left '*' '/'
%nonassoc UMINUS UPLUS
%nonassoc PIORITY_0
%nonassoc PIORITY_1

%start program
%%
/* declare constant */
const_dec:ID '=' expression
		{
			Trace("declare constant, multi-line")
			if(!isConst(*$3)) 
				yyerror("ERROR : assign value not constant");

			$3->flag = ConstVar_flag;

			if(stl.insert(*$1,*$3) == -1) 
				yyerror("ERROR : variable redefinition");
		}
		| // empty
		;
/* declare variable */
var_dec: IDs ':' var_type
		{
			Trace("declare variable")
			if(stl.assignWaitType($3) == -1) 
				yyerror("ERROR : variable redefinition");
		}
		| // empty
	   ;

/* declare array */
arr_dec: IDs ':' ARRAY '[' expression ',' expression ']' OF var_type
		{
			int size = 0;
			int num0 = 0;
			int num1 = 0;

			Trace("declare array")
			if($5->type != Int_type && $5->type != Real_type || $7->type != Int_type && $7->type != Real_type){
				yyerror("operator error");
			}

			if($5->flag == ConstVal_flag){
				if($5->type == Int_type){
					num0 = $5->value.val;
				}else if($5->type == Real_type){
					num0 = $5->value.dval;
				}
			}

			if($7->flag == ConstVal_flag){
				if($7->type == Int_type){
					num1 = $7->value.val;
				}else if($7->type == Real_type){
					num1 = $7->value.dval;
				}
			}

			size = num1 - num0;

			if(size <= 0){
				yyerror("array size error");
			}else{
				if(stl.assignWaitTypeArray($10,size) == -1){
					yyerror("array dec error");
				}
			}
		};
/* optional variable and constant declarations */
opt_var_dec: VAR var_dec ';' opt_var_dec_var opt_var_dec
		   | CONST const_dec ';' opt_var_dec_const opt_var_dec
		   | arr_dec ';' opt_var_dec
		   | // empty
		   ;
opt_var_dec_const: const_dec ';' opt_var_dec_const
				| // empty
				;
opt_var_dec_var: var_dec ';' opt_var_dec_var
				| // empty
				; 
opt_func_dec: func_dec opt_func_dec 
			 | // empty
			 ;
/* program */
program: MODULE ID
		{
			Trace("declare module")
			stl.pushTable();
			if(stl.pushFuncEnd(*$2) == -1){
				yyerror("add module name error");
			}
		}
		opt_var_dec opt_func_dec BEGIN_token opt_statement module_end
		{

		};
module_end: END ID '.'
		{
			if(stl.checkFuncEnd(*$2) == -1){
				yyerror("valid module end error");
			}
			if(Opt_DS)
				stl.dump();
			if(!stl.popTable())
				yyerror("pop symbol table error");
		};
/* function ( procedure ) */ 
func_dec: PROCEDURE ID
		{
			Trace("declare function")
			if(stl.pushWaitTypeFunc(*$2) == -1){
				yyerror("push wait type function name error");
			}
			stl.pushTable();
			if(stl.pushFuncEnd(*$2) == -1){
				yyerror("add module name error");
			}
		}
		'(' opt_params ')' func_dec_type BEGIN_token statement ';' opt_statement func_end
		{
			
		};
func_end: END ID ';'
		{
			if(stl.checkFuncEnd(*$2) == -1){
				yyerror("valid module end error");
			}
			if(!stl.popTable())
				yyerror("pop symbol table error");
		};
func_dec_type: opt_func_type
		{
			if(Opt_DS)
				stl.dump();
			if(stl.assignWaitTypeFunc($1) == -1) 
				yyerror("ERROR : function name conflict");
		};
/* formal parameter */
opt_params: params
			|
			;
/* param <,param,...>*/
params: params ',' param
	  | param
	  ;
param: ID ':' var_type
		{
			if(stl.insertNoInit(*$1,$3) == -1) 
				yyerror("ERROR : variable redefinition");
			if(!stl.setFuncParam(*$1,$3)) 
				yyerror("ERROR : set function parameter error");
		}
	 ;
opt_func_type: ':' INTEGER  { $$ = Int_type;  }
		 | ':' BOOLEAN	{ $$ = Bool_type; }
		 | ':' REAL		{ $$ = Real_type; }
		 | ':' STRING	{ $$ = Str_type;  }
		 |              { $$ = Void_type; }
		 ;
/* statement */
opt_statement: statement ';' opt_statement
			 | // empty
			 ;
// [not finished]
statement: ID ASSIGNMENT_token expression
		{
			Trace("statement: variable assign")
			idInfo *tmp = stl.lookup(*$1);
			if(tmp == NULL) yyerror("undeclared identifier " + *$1);
			if(tmp->flag != Var_flag) yyerror("ERROR : " + *$1 + " not var");
			if(tmp->type != $3->type) yyerror("ERROR : type not match");
		}
		 | ID '[' expression ']' ASSIGNMENT_token expression
		{
			Trace("statement: array variable assign")
			idInfo *tmp = stl.lookup(*$1);
			if(tmp == NULL) yyerror("undeclared identifier " + *$1);
			if(tmp->flag != Var_flag) yyerror("ERROR : " + *$1 + " not var");
			if(tmp->type != Array_type) yyerror("ERROR : " + *$1 + " not array");
			if($3->type != Int_type) yyerror("ERROR : index not integer");
			if($3->value.val >= tmp->value.aval.size()) yyerror("ERROR : array index out of range");
			if(tmp->value.aval[0].type != $6->type) yyerror("ERROR : type not match");
		}
		| PRINT expression 
		{ 
			Trace("statement: print expression")
		}
		| PRINTLN expression 
		{ 
			Trace("statement: print expression with new line") 
		}
		| READ ID
		{
			Trace("statement: read user input to " + *$2)
			idInfo *tmp = stl.lookup(*$2);
			if(tmp == NULL) yyerror("undeclared identifier " + *$2);
			if(tmp->flag != Var_flag) yyerror("ERROR : " + *$2 + " not var, cannot be set value");
		}
		| RETURN %prec PIORITY_0
		{ 
			Trace("statement: return")
		}
		| RETURN expression %prec PIORITY_1
		{ 
			Trace("statement: return expression")
		}
		| conditional
		| loop
		| proc_invocation
		;
/* conditional */
conditional: IF '(' bool_expression ')' THEN opt_statement 
{
	Trace("if")
}
opt_else END
{
	Trace("end if")
};
opt_else: ELSE opt_statement
{
	Trace("else")
}
| // empty
;
/* loop */
loop: WHILE '(' bool_expression ')' DO opt_statement END
{
	Trace("while")
};
/* expression */
bool_expression: expression
{
	if($1->type != Bool_type) 
		yyerror("ERROR : condition not boolean");
	$$ = $1;
};
expression: const_value
			{
				Trace("const_value")
			}
			| ID %prec PIORITY_0
			{
				Trace("ID")
				idInfo *tmp = stl.lookup(*$1);

				if(tmp == NULL) 
					yyerror("undeclared identifier " + *$1);

				if(tmp->flag == Func_flag){
					Trace("call function")
					tmp->flag = ConstVal_flag;
				}
					
				if(tmp->flag == ConstVar_flag) 
					tmp->flag = ConstVal_flag;

				$$ = tmp;
			}
			| ID '[' expression ']' %prec PIORITY_1
			{
				Trace("arr[]")
				idInfo *tmp = stl.lookup(*$1);
				if(tmp == NULL) 
					yyerror("undeclared identifier " + *$1);
				if(tmp->flag != Var_flag) 
					yyerror("ERROR : " + *$1 + " not var");
				if(tmp->type != Array_type) 
					yyerror("ERROR : " + *$1 + " not array");
				if($3->type != Int_type)
					yyerror("ERROR : index not integer");
				if($3->value.val >= tmp->value.aval.size()) 
					yyerror("ERROR : array index out of range");
				$$ = new idInfo(tmp->value.aval[$3->value.val]);
			}
			|'+' expression %prec UPLUS
			{
				Trace("+expression")
				if($2->type != Int_type && $2->type != Real_type) 
					yyerror("operator error");
				if($2->flag == ConstVal_flag){
					if($2->type == Int_type){
						$$ = intConst($2->value.val);
					}else if($2->type == Real_type){
						$$ = realConst($2->value.val);
					}
				}else{
					idInfo *tmp = new idInfo();
					tmp->flag = Var_flag; 
					tmp->type = $2->type;
					$$ = tmp;
				}
			}
			|'-' expression %prec UMINUS
			{
				Trace("-expression")
				if($2->type != Int_type && $2->type != Real_type) 
					yyerror("operator error");
				if($2->flag == ConstVal_flag){
					if($2->type == Int_type){
						$$ = intConst(-$2->value.val);
					}else if($2->type == Real_type){
						$$ = realConst(-$2->value.val);
					}
				}else{
					idInfo *tmp = new idInfo();
					tmp->flag = Var_flag; 
					tmp->type = $2->type;
					$$ = tmp;
				}
			}
			| expression '*' expression
			{
				int type = compareType($1,$3);
				Trace("expression * expression")
				if(type == -1) 
					yyerror("ERROR : type not match");
				if(type != Int_type && type != Real_type) 
					yyerror("operator error");
				if($1->flag == ConstVal_flag && $3->flag == ConstVal_flag){
					if(type == Int_type){
						$$ = intConst($1->value.val * $3->value.val);
					}else if(type == Real_type){
						$$ = realConst($1->value.dval * $3->value.dval);
					}
				}else{
					idInfo *tmp = new idInfo();
					tmp->flag = Var_flag; 
					tmp->type= type;
					$$ = tmp;
				}
			}
			| expression '/' expression
			{
				int type = compareType($1,$3);
				Trace("expression / expression")
				if(type == -1) 
					yyerror("ERROR : type not match");
				if(type != Int_type && type != Real_type) 
					yyerror("operator error");
				if($1->flag == ConstVal_flag && $3->flag == ConstVal_flag){
					if(type == Int_type){
						$$ = intConst($1->value.val / $3->value.val);
					}else if(type == Real_type){
						$$ = realConst($1->value.dval / $3->value.dval);
					}
				}else{
					idInfo *tmp = new idInfo();
					tmp->flag = Var_flag; 
					tmp->type= type;
					$$ = tmp;
				}
			}
			| expression '+' expression
			{
				int type = compareType($1,$3);
				Trace("expression + expression")
				if(type == -1) 
					yyerror("ERROR : type not match");
				if(type != Int_type && type != Real_type) 
					yyerror("operator error");
				if($1->flag == ConstVal_flag && $3->flag == ConstVal_flag){
					if(type == Int_type){
						$$ = intConst($1->value.val + $3->value.val);
					}else if(type == Real_type){
						$$ = realConst($1->value.dval + $3->value.dval);
					}else if(type == Str_type){
						$$ = strConst(new string($1->value.sval + $3->value.sval));
					}
				}else{
					idInfo *tmp = new idInfo();
					tmp->flag = Var_flag; 
					tmp->type= type;
					$$ = tmp;
				}
			}
			| expression '-' expression
			{
				int type = compareType($1,$3);
				Trace("expression - expression")
				if(type == -1) 
					yyerror("ERROR : type not match");
				if(type != Int_type && type != Real_type) 
					yyerror("operator error");
				if($1->flag == ConstVal_flag && $3->flag == ConstVal_flag){
					if(type == Int_type){
						$$ = intConst($1->value.val - $3->value.val);
					}else if(type == Real_type){
						$$ = realConst($1->value.dval - $3->value.dval);
					}
				}else{
					idInfo *tmp = new idInfo();
					tmp->flag = Var_flag; 
					tmp->type= type;
					$$ = tmp;
				}
			}
			| expression '<' expression
			{
				int type = compareType($1,$3);
				Trace("expression < expression")
				if(type == -1) 
					yyerror("ERROR : type not match");
				if(type != Int_type && type != Real_type) 
					yyerror("operator error");
				if($1->flag == ConstVal_flag && $3->flag == ConstVal_flag){
					if(type == Int_type){
						$$ = boolConst($1->value.val < $3->value.val);
					}else if(type == Real_type){
						$$ = boolConst($1->value.dval < $3->value.dval);
					}
				}else{
					idInfo *tmp = new idInfo();
					tmp->flag = Var_flag; 
					tmp->type = Bool_type;
					$$ = tmp;
				}
			}
			| expression LE expression
			{
				int type = compareType($1,$3);
				Trace("expression <= expression")
				if(type == -1) 
					yyerror("ERROR : type not match");
				if(type != Int_type && type != Real_type) 
					yyerror("operator error");
				if($1->flag == ConstVal_flag && $3->flag == ConstVal_flag){
					if(type == Int_type){
						$$ = boolConst($1->value.val <= $3->value.val);
					}else if(type == Real_type){
						$$ = boolConst($1->value.dval <= $3->value.dval);
					}
				}else{
					idInfo *tmp = new idInfo();
					tmp->flag = Var_flag; 
					tmp->type = Bool_type;
					$$ = tmp;
				}
			}
			| expression EQ expression
			{
				int type = compareType($1,$3);
				Trace("expression == expression")
				if(type == -1) 
					yyerror("ERROR : type not match");
				if(type != Int_type && type != Real_type && type != Bool_type) 
					yyerror("operator error");
				if($1->flag == ConstVal_flag && $3->flag == ConstVal_flag){
					if(type == Int_type){
						$$ = boolConst($1->value.val == $3->value.val);
					}else if(type == Real_type){
						$$ = boolConst($1->value.dval == $3->value.dval);
					}else if(type == Bool_type){
						$$ = boolConst($1->value.bval == $3->value.bval);
					}
				}else{
					idInfo *tmp = new idInfo();
					tmp->flag = Var_flag; 
					tmp->type = Bool_type;
					$$ = tmp;
				}
			}
			| expression GE expression
			{
				int type = compareType($1,$3);
				Trace("expression >= expression")
				if(type == -1) 
					yyerror("ERROR : type not match");
				if(type != Int_type && type != Real_type) 
					yyerror("operator error");
				if($1->flag == ConstVal_flag && $3->flag == ConstVal_flag){
					if(type == Int_type){
						$$ = boolConst($1->value.val >= $3->value.val);
					}else if(type == Real_type){
						$$ = boolConst($1->value.dval >= $3->value.dval);
					}
				}else{
					idInfo *tmp = new idInfo();
					tmp->flag = Var_flag; 
					tmp->type = Bool_type;
					$$ = tmp;
				}
			}
			| expression '>' expression
			{
				int type = compareType($1,$3);
				Trace("expression > expression")
				if(type == -1) 
					yyerror("ERROR : type not match");
				if(type != Int_type && type != Real_type) 
					yyerror("operator error");
				if($1->flag == ConstVal_flag && $3->flag == ConstVal_flag){
					if(type == Int_type){
						$$ = boolConst($1->value.val > $3->value.val);
					}else if(type == Real_type){
						$$ = boolConst($1->value.dval > $3->value.dval);
					}
				}else{
					idInfo *tmp = new idInfo();
					tmp->flag = Var_flag; 
					tmp->type = Bool_type;
					$$ = tmp;
				}
			}
			| expression NEQ expression
			{
				int type = compareType($1,$3);
				Trace("expression <> expression")
				if(type == -1) 
					yyerror("ERROR : type not match");
				if(type != Int_type && type != Real_type && type != Bool_type) 
					yyerror("operator error");
				if($1->flag == ConstVal_flag && $3->flag == ConstVal_flag){
					if(type == Int_type){
						$$ = boolConst($1->value.val != $3->value.val);
					}else if(type == Real_type){
						$$ = boolConst($1->value.dval != $3->value.dval);
					}else if(type == Bool_type){
						$$ = boolConst($1->value.bval != $3->value.bval);
					}
				}else{
					idInfo *tmp = new idInfo();
					tmp->flag = Var_flag; 
					tmp->type = Bool_type;
					$$ = tmp;
				}
			}
			| '~' expression
			{
				Trace("!expression")
				if($2->type != Bool_type) 
					yyerror("operator error");
				if($2->flag == ConstVal_flag){
					$$ = boolConst(!$2->value.bval);
				}else{
					idInfo *tmp = new idInfo();
					tmp->flag = Var_flag; 
					tmp->type= Bool_type;
					$$ = tmp;
				}
			}
			| expression AND expression
			{
				int type = compareType($1,$3);
				Trace("expression && expression")
				if(type == -1) 
					yyerror("ERROR : type not match");
				if(type != Bool_type) 
					yyerror("operator error");
				if($1->flag == ConstVal_flag && $3->flag == ConstVal_flag){
					if(type == Bool_type){
						$$ = boolConst($1->value.bval && $3->value.bval);
					}
				}else{
					idInfo *tmp = new idInfo();
					tmp->flag = Var_flag; 
					tmp->type = Bool_type;
					$$ = tmp;
				}
			}
			| expression OR expression
			{
				int type = compareType($1,$3);
				Trace("expression || expression")
				if(type == -1) 
					yyerror("ERROR : type not match");
				if(type != Bool_type) 
					yyerror("operator error");
				if($1->flag == ConstVal_flag && $3->flag == ConstVal_flag){
					if(type == Bool_type){
						$$ = boolConst($1->value.bval || $3->value.bval);
					}
				}else{
					idInfo *tmp = new idInfo();
					tmp->flag = Var_flag; 
					tmp->type = Bool_type;
					$$ = tmp;
				}
			}
			| '(' expression ')' 
			{
				Trace("(expression)")
				$$ = $2;
			}
			| func_invocation
			;

/* const value */
const_value: INT_CONST { $$=intConst($1); }
		   | BOOL_CONST { $$=boolConst($1); }
		   | REAL_CONST { $$=realConst($1); }
		   | STR_CONST { $$=strConst($1); }
		   ;

/* procedure invocation */
proc_invocation: func_invocation
{
	Trace("call procedure")
};
/* function invocation */
func_invocation: 
ID
{
	fpstack.push_back(vector<idInfo>());
}
'(' opt_comma_separated_expressions ')'
{
	Trace("call function")
	idInfo *tmp = stl.lookup(*$1);
	if(tmp == NULL) 
		yyerror("undeclared identifier " + *$1);
	if(tmp->flag != Func_flag) 
		yyerror("ERROR : " + *$1 + " not function");
	vector<idInfo> tmpArr = tmp->value.aval;
	if(tmpArr.size() != fpstack[fpstack.size()-1].size()) 
		yyerror("ERROR : function parameter size not match");
	for(int i= 0;i<tmpArr.size();i++){
		if(tmpArr[i].type != fpstack[fpstack.size()-1].at(i).type) 
			yyerror("ERROR : function parameter type not match");
	}
	$$ = tmp;
	fpstack.pop_back();
};
/* opt_comma_separated_expressions */
opt_comma_separated_expressions: 
expression ',' opt_comma_separated_expressions %prec PIORITY_1
{
	fpstack[fpstack.size()-1].push_back(*$1);
}
| expression %prec PIORITY_0
{
	fpstack[fpstack.size()-1].push_back(*$1);
} 
| // empty
;
/* identifier <,...,identifier> */
IDs: ID IDs
	{
		Trace("identifier")
		if(stl.pushWaitType(*$1) == -1){
			yyerror("push wait type identifier error");
		}
	}
	| ',' ID IDs
	{
		Trace("multi-identifier")
		if(stl.pushWaitType(*$2) == -1){
			yyerror("push wait type identifier error");
		}
	}
	| // empty
	;

var_type: INTEGER	{ $$ = Int_type;  }
		| BOOLEAN	{ $$ = Bool_type; }
		| REAL		{ $$ = Real_type; }
		| STRING	{ $$ = Str_type;  }
		;

%%
void yyerror(string s) {
	cerr << "line " << g_linenum << ": " << s << endl;
	exit(1);
}

int main(void) {
	yyparse();
	return 0; 
}
