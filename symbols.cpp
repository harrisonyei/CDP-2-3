#include "symbols.hpp"


// struct constructor
idValue::idValue(){
	val = 0;
	bval = false;
	dval = 0.0;
	sval = "";
}
idInfo::idInfo(){
	type = Int_type;
	flag = Var_flag;
}

/*
 *	SymbolTable
 */
SymbolTable::SymbolTable(){
	length = 0;
}

bool SymbolTable::isExist(string s){
	if(symbol_i.find(s) != symbol_i.end()){
		return true;
	}else{
		return false;
	}
}

idInfo* SymbolTable::lookup(string s){
	if(isExist(s))
		return new idInfo(symbol_i[s]);
	else
		return NULL;
}

idInfo* SymbolTable::getIdInfoPtr(string s){
	if(isExist(s))
		return &symbol_i[s];
	else
		return NULL;
}



int SymbolTable::insert(string var_name, int type, idValue value, int flag){
	if(symbol_i.find(var_name) != symbol_i.end()){
		return -1;		// find it in SymbolTable
	}
	symbol_i[var_name].name = var_name;
	symbol_i[var_name].type = type;
	symbol_i[var_name].value = value;
	symbol_i[var_name].flag = flag;
	length += 1;
	return length - 1;
}

int SymbolTable::remove(string var_name){
	std::map<std::string,idInfo>::iterator it = symbol_i.find(var_name);
	if(it != symbol_i.end()){
		symbol_i.erase(it);
		length -= 1;
		return 0;
	}
	return -1;
}

/* dump */
int SymbolTable::dump(){
	int count = 0;
	for(auto& kv : symbol_i){
		cout << count << ". " << getIdInfoStr(kv.second) << endl;
		count += 1;
	}
	return count;
}

/*
 *	SymbolTableList
 */
SymbolTableList::SymbolTableList(){
	top = -1;
	waitTypeIDs.clear();
	pushTable();
}

// push SymbolTable into SymbolTableList
void SymbolTableList::pushTable(){
	list.push_back(SymbolTable());
	top++;
}

// pop last SymbolTable in SymbolTableList, success->return true
bool SymbolTableList::popTable(){
	if(list.size() <=0)
		return false;

	list.pop_back();
	top--;
	return true;
}

// get s idInfo from SymbolTableList
// search s from top to 0
idInfo* SymbolTableList::lookup(string s){
	for(int i=top;i>=0;i--){
		if(list[i].isExist(s)){
			return list[i].lookup(s);
		}
	}
	return NULL;		// not found
}


/* INSERT */
int SymbolTableList::insertNoInit(string var_name, int type){
	return list[top].insert(var_name,type,idValue(), Var_flag);
}

int SymbolTableList::pushFuncEnd(string func_name){
	string func_end_name = "$end$"+func_name;
	return list[top].insert(func_end_name,Str_type,idValue(), ConstVal_flag);
}

int SymbolTableList::checkFuncEnd(string func_name){
	string func_end_name = "$end$"+func_name;
	return list[top].remove(func_end_name);
}

int SymbolTableList::pushWaitType(string var_name){

	waitTypeIDs.push_back(var_name);

	return 0;
}

int SymbolTableList::assignWaitType(int type){
	for(int i = 0;i < waitTypeIDs.size();i++){
		if(insertNoInit(waitTypeIDs[i],type) == -1){
			return -1;
		}
	}
	waitTypeIDs.clear();
	return 0;
}

int SymbolTableList::assignWaitTypeArray(int type,int size){
	for(int i = 0; i < waitTypeIDs.size(); i++){
		if(insertArray(waitTypeIDs[i],type,size) == -1){
			return -1;
		}
	}
	waitTypeIDs.clear();
	return 0;
}


int SymbolTableList::insertArray(string var_name, int type, int size){
	idValue tmp;
	tmp.aval = vector<idInfo>(size);
	for(int i = 0;i<size;i++){
		tmp.aval[i].type=type;
		tmp.aval[i].flag=Var_flag;
	}
	return list[top].insert(var_name,Array_type,tmp, Var_flag);
}

int SymbolTableList::assignWaitTypeFunc(int type){
	int flag = -1;
	if(funcname != ""){
		idInfo *f = list[top-1].getIdInfoPtr(funcname);
		if(f != NULL){
			f->type = type;
			flag = 0;
		}
	}
	return flag;
}

int SymbolTableList::pushWaitTypeFunc(string var_name){
	funcname = var_name;
	return list[top].insert(var_name,Void_type,idValue(), Func_flag);
}

int SymbolTableList::insert(string var_name, idInfo idinfo){
	return list[top].insert(var_name,idinfo.type,idinfo.value,idinfo.flag);
}

// set function parameters
bool SymbolTableList::setFuncParam(string name,int type){
	idInfo *f = list[top-1].getIdInfoPtr(funcname);
	if(f == NULL) 
		return false;
	idInfo tmp;
	tmp.name = name;
	tmp.type = type;
	tmp.flag = Var_flag;
	f->value.aval.push_back(tmp);
	return true;
}

/* dump */
int SymbolTableList::dump(){
	cout << "-------------- dump start --------------" << endl;
	for(int i=top;i>=0;i--){
		cout << "stack frame : " << i << endl;
		list[i].dump();
	}
	cout << "--------------  dump end  --------------" << endl;
	return list.size();
}


/* Build const value */
idInfo* intConst(int val){
	idInfo* tmp = new idInfo();
	tmp->type=Int_type;
	tmp->value.val=val;
	tmp->flag=ConstVal_flag;
	return tmp;
}
idInfo* boolConst(bool val){
	idInfo* tmp = new idInfo();
	tmp->type=Bool_type;
	tmp->value.bval=val;
	tmp->flag=ConstVal_flag;
	return tmp;
}
idInfo* realConst(double val){
	idInfo* tmp = new idInfo();
	tmp->type=Real_type;
	tmp->value.dval=val;
	tmp->flag=ConstVal_flag;
	return tmp;
}
idInfo* strConst(string* val){
	idInfo* tmp = new idInfo();
	tmp->type=Str_type;
	tmp->value.sval=*val;
	tmp->flag=ConstVal_flag;
	return tmp;
}


bool isConst(idInfo idinfo){
	if(idinfo.flag != ConstVal_flag && idinfo.flag != ConstVar_flag)
		return false;
	else 
		return true;
}

// transfar type enum to type name
string getTypeStr(int type){
		switch(type){
			case Int_type:
				return "int";
			case Bool_type:
				return "bool";
			case Real_type:
				return "real";
			case Str_type:
				return "string";
			case Array_type:
				return "array";
			case Void_type:
				return "void";
			default:
				return "ERROR!!!\n";
		}
}

// use type to get idValue value
string getValue(idValue value, int type){
		switch(type){
			case Int_type:
				return to_string(value.val);
			case Bool_type:
				return (value.bval?"true":"false");
			case Real_type:
				return to_string(value.dval);
			case Str_type:
				return "\"" + value.sval + "\"";
			case Array_type:
				return to_string(value.aval.size());
			default:
				return "ERROR!!!\n";
		}
}

// get function parameter string
string getParamStr(vector<idInfo> param){
	string s = "";
	for(int i = 0;i<param.size();i++){
		if(i!=0) s+=", ";
		s+= param[i].name + " " + getTypeStr(param[i].type);
	}
	return s;
}
// get function format string(declartion format)
string getFuncStr(idInfo tmp){
	if(tmp.flag != Func_flag) return "ERROR";
	return "func "+ getTypeStr(tmp.type) + " " + tmp.name + "(" + getParamStr(tmp.value.aval) + ")";
}

// return idInfo format string(declartion format)
string getIdInfoStr(idInfo tmp){
	string s = "";
	switch (tmp.flag) {
		case ConstVar_flag:
			s += "const";break;
		case Var_flag:
			s += "var";break;
		case Func_flag:
			s += getFuncStr(tmp);return s;
		default:
			return "ERROR!!!";
	}
	s+= " " + tmp.name + " ";
	if(tmp.type==Array_type){
		s +=  "[" + getValue(tmp.value,tmp.type)  + "]" + getTypeStr(tmp.value.aval[0].type);
	}else
		s += getTypeStr(tmp.type) + " = " + getValue(tmp.value,tmp.type);
	return s;
}

int compareType(idInfo* a,idInfo* b){
	if(a->type == b->type)
		return a->type;
	return -1;
}


