#include <iostream>
#include <fstream>
#include <stack>
#include "symbols.hpp"

using namespace std;

enum JavaOp{
    OP_REL_EQ,
    OP_REL_NEQ,
    OP_REL_LT,
    OP_REL_LE,
    OP_REL_GT,
    OP_REL_GE,

    OP_COM_PLUS,
    OP_COM_SUB,
    OP_COM_MUL,
    OP_COM_DIV,
    OP_COM_REM,
    OP_COM_NEG,

    OP_LOG_AND,
    OP_LOG_OR,
    OP_LOG_NOT,
};

extern ofstream OUT_STREAM;

int GetNewLabel();

int PushLabel();

int PopLabel();

int GetTopLabel();

string ConvertToJavaType(uint8_t type);
// done
void GenClassRegionStart(string className);

void GenMainRegionStart(); // done
// done
void GenProcRegionStart(string name, int type,vector<idInfo>& args);

void GenRegionEnd();

// done
void GenReturnVoid();

// done
void GenReturnInt();

// 目前只管int, boolean
void GenDefGlobalVar(string name, int type); // done

void GenGetGlobalVar(string name, int type, string scopeName);

void GenSetGlobalVar(string name, int type, string scopeName);

void GenInvokeProc(string name, int type, string scopeName, vector<idInfo>& args);

void GenLoadFromStack(int index);

void GenSaveToStack(int index); // done

void GenGetConstant(int val); // done

void GenGetConstant(bool val); // done

void GenGetConstant(string val); // done

void GenPrintStart(); // done

void GenPrintStrEnd(bool ln); // done

void GenPrintIntEnd(bool ln); // done

void GenPrintBoolEnd(bool ln); // done

void GenRelationalOp(JavaOp op); // done

void GenComputationalOp(JavaOp op); // done

void GenIfStart(); // done

void GenIfElse(); // done

void GenIfEnd(); // done
void GenWhileStart(); // done

void GenWhileCondition(); // done

void GenWhileEnd(); // done