#include <iostream>
#include <map>
#include <vector>
#include <stdio.h>
using namespace std;

enum type{
	Int_type,
	Bool_type,
	Real_type,
	Str_type,
	Array_type,
	Void_type
};
enum idflag{
	ConstVal_flag,				// const value (123)
	ConstVar_flag,				// const variable (const a=123)
	Var_flag,					// variable
	Func_flag,					// function
	Proc_flag					// function
};

struct idInfo;
struct idValue{
	int val;					// integer
	bool bval; 					// boolean
	double dval;				// real
	string sval;				// string
	vector<idInfo> aval;		// array and function parameters
	idValue();
};

/* store constant or variable or function information */
struct idInfo{
	int index;
	string name;	// id name
	int type;		// enum type
	idValue value;	// value depend on type
	int flag;		// enum idflag
	idInfo();
};

/* symbol table */
class SymbolTable{
private:
	map<string,idInfo> symbol_i;		// use variable name get ifInfo
	int length;
	int index;
public:
	SymbolTable(string _scopeName,int _index);
	bool isExist(string);				// check variable in the SymbolTable
	idInfo* lookup(string);				// return Copied idInfo if variable in the SymbolTable (else return NULL)
	idInfo* getIdInfoPtr(string);		// return idInfo pointer if variable in the SymbolTable (else return NULL)
	int insert(string var_name, int type, idValue value, int flag);		// insert var into the SymbolTable
	int dump();							// dump the SymbolTable
	string scopeName;
};

/* 	symbol table list
 *  use a stack to implement variable scope
 */
class SymbolTableList{
private:
	int top;						// top of stack
	string funcname;
	vector<SymbolTable> list;		// SymbolTable list
	vector<string> waitTypeIDs;
public:
	SymbolTableList();
	void pushTable(string scopeName);    // push a SymbolTable into list
	bool popTable();				// pop a SymbolTable from list
	idInfo* lookup(string);			// lookup all SymbolTable from list (from top to 0)
	string getScopeName(string);    // lookup all SymbolTable from list (from top to 0)
	bool isGlobal(string);
	bool isGlobal();
	
	/* insert a variable into the SymbolTable(current scope) */
	int insertNoInit(string var_name, int type);
	int insertArray(string var_name, int type, int size);
	int insert(string var_name, idInfo idinfo);		// use name and idInfo
	int pushWaitType(string var_name); // push identifiers without init type to a stack, and will add to it later
	int assignWaitType(int type); // add type to all identifiers in stack
	int assignWaitTypeArray(int type,int size); // add type to all identifier arrays
	int pushWaitTypeFunc(string var_name);		// initilize function without type
	int assignWaitTypeFunc(int type);  // late assign type to function
	bool setFuncParam(string);	// set function parameters
	int dump();						// dump all SymbolTable (from top to 0)
};

// Build const value
idInfo* intConst(int);
idInfo* boolConst(bool);
idInfo* realConst(double);
idInfo* strConst(string*);

// check the idInfo is a const
bool isConst(idInfo);

// transfar type enum to type name
string getTypeStr(int type);
// use type to get idValue value
string getValue(idValue value, int type);
// get function format string(declartion format)
string getFuncStr(idInfo);
// return idInfo format string(declartion format)
string getIdInfoStr(idInfo);

int compareType(idInfo*,idInfo*); // compare two identifiers type, return type if they are the same, else return -1
