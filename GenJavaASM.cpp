#include "GenJavaASM.h"

stack<int> labelStack;
int labelSerialNum = 0;

int GetNewLabel() {
    return labelSerialNum++;
}

int PushLabel() {
    int newLabel = GetNewLabel();
    labelStack.push(newLabel);
    return newLabel;
}

int PopLabel() {
    int label = labelStack.top();
    labelStack.pop();
    return label;
}

int GetTopLabel() {
    return labelStack.top();
}

string ConvertToJavaType(uint8_t type) {
    switch (type)
    {
    case Bool_type:
        return "boolean";
    case Int_type:
        return "int";
    case Void_type:
        return "void";
    default:
        cout << "/*UNDEFINED TYPE ERROR: " << type << "*/";
        break;
    }
    return "";
}

void GenClassRegionStart(string className) {
    OUT_STREAM << "class " << className << "\n{\n";
}

void GenMainRegionStart() {
    OUT_STREAM <<  "method public static void main(java.lang.String[])\n";
    OUT_STREAM <<  "max_stack 15\n";
    OUT_STREAM << "max_locals 15\n{\n";
}

void GenProcRegionStart(string name, int type,vector<idInfo>& args) {
    OUT_STREAM <<  "method public static " << ConvertToJavaType(type) << " " << name << "(";
    for (int i = 0; i < args.size(); i++) { // arguments.
        if (i != 0) { OUT_STREAM << ", "; }
        OUT_STREAM << ConvertToJavaType(args[i].type);
    }
    OUT_STREAM << ")\n";
    OUT_STREAM <<  "max_stack 15\n";
    OUT_STREAM << "max_locals 15\n{\n";
    // for (int i = 0; i < args.size(); i++) { // arguments.
    //     GenLoadFromStack(args[i].index);
    // }
}

void GenRegionEnd() {
    OUT_STREAM << "}\n";
}

void GenReturnVoid() {
    OUT_STREAM << "return\n";
}

void GenReturnInt() {
    OUT_STREAM << "ireturn\n";
}

// 目前只管int, boolean
void GenDefGlobalVar(string name, int type) {
    // boolean as int.
    OUT_STREAM << "field static " << ConvertToJavaType(type) << " " << name << "\n";
}

void GenGetGlobalVar(string name, int type, string scopeName) {
    OUT_STREAM << "getstatic "<< ConvertToJavaType(type) << " " << scopeName << "." << name << "\n";
}

void GenSetGlobalVar(string name, int type, string scopeName) {
    OUT_STREAM << "putstatic "<< ConvertToJavaType(type) << " " << scopeName << "." << name << "\n";
}

void GenInvokeProc(string name, int type, string scopeName, vector<idInfo>& args) {
    OUT_STREAM << "invokestatic " << ConvertToJavaType(type) << " " << scopeName << "." << name << "(";
    for (int i = 0; i < args.size(); i++) { // arguments.
        if (i != 0) { OUT_STREAM << ", "; }
        OUT_STREAM << ConvertToJavaType(args[i].type);
    }
    OUT_STREAM << ")\n";
}

void GenLoadFromStack(int index) {
    OUT_STREAM << "iload " << index << "\n";
}

void GenSaveToStack(int index) {
    OUT_STREAM << "iStore " << index << "\n";
}

void GenGetConstant(int val) {
    OUT_STREAM << "ldc " << val << "\n";
}

void GenGetConstant(bool val) {
    if (val) {
        OUT_STREAM << "iconst_1\n";
    } else {
        OUT_STREAM << "iconst_0\n";

    }
}

void GenGetConstant(string val) {
    OUT_STREAM << "ldc \"" << val << "\"\n";
}

void GenPrintStart() {
    OUT_STREAM << "getstatic java.io.PrintStream java.lang.System.out\n";
}

void GenPrintStrEnd(bool ln) {
    if (ln) {
        OUT_STREAM << "invokevirtual void java.io.PrintStream.println(java.lang.String)\n";
    } else {
        OUT_STREAM << "invokevirtual void java.io.PrintStream.print(java.lang.String)\n";
    }
}

void GenPrintIntEnd(bool ln) {
    if (ln) {
        OUT_STREAM << "invokevirtual void java.io.PrintStream.println(int)\n";
    } else {
        OUT_STREAM << "invokevirtual void java.io.PrintStream.print(int)\n";
    }
}

void GenPrintBoolEnd(bool ln) {
    if (ln) {
        OUT_STREAM << "invokevirtual void java.io.PrintStream.println(boolean)\n";
    } else {
        OUT_STREAM << "invokevirtual void java.io.PrintStream.print(boolean)\n";
    }
}

void GenRelationalOp(JavaOp op) {
    // 做比較一律先相減
    OUT_STREAM << "isub\n"; 
    int L_true = GetNewLabel(), L_exit = GetNewLabel();
    switch (op)
    {
        case OP_REL_EQ:
            OUT_STREAM << "ifeq";
        break;
        case OP_REL_NEQ:
            OUT_STREAM << "ifne";
        break;
        case OP_REL_LT:
            OUT_STREAM << "iflt";
        break;
        case OP_REL_LE:
            OUT_STREAM << "ifle";
        break;
        case OP_REL_GT:
            OUT_STREAM << "ifgt";
        break;
        case OP_REL_GE:
            OUT_STREAM << "ifge";
        break;
    default:
        break;
    }
    OUT_STREAM << " L" << L_true << "\n";
    OUT_STREAM << "iconst_0\n";
    OUT_STREAM << "goto L" << L_exit << "\n";
    OUT_STREAM << " L" << L_true << ":\n";
    OUT_STREAM << "iconst_1\n";
    OUT_STREAM << " L" << L_exit << ":\n";
}

void GenComputationalOp(JavaOp op){
	switch (op) {
		case OP_COM_PLUS:
			OUT_STREAM << "iadd\n";
			break;
		case OP_COM_SUB:
			OUT_STREAM << "isub\n";
			break;
		case OP_COM_MUL:
			OUT_STREAM << "imul\n";
			break;
		case OP_COM_DIV:
			OUT_STREAM << "idiv\n";
			break;
		case OP_COM_REM:
			OUT_STREAM << "irem\n";
			break;
        case OP_COM_NEG:
			OUT_STREAM << "ineg\n";
			break;
		case OP_LOG_AND:
			OUT_STREAM << "iand\n";
			break;
		case OP_LOG_OR:
			OUT_STREAM << "ior\n";
			break;
		case OP_LOG_NOT:
			OUT_STREAM << "iconst_1\n";
			OUT_STREAM << "ixor\n";
			break;
		default:
			break;
	}
}

void GenIfStart() {
    int label = PushLabel(); // maybe for elif, else, end.
    OUT_STREAM << "ifeq L" << label << "\n";
}

void GenIfElse() {
    int label = PopLabel(); // pop label for next.
    int gotoLabel = PushLabel();
    OUT_STREAM << "goto L" << gotoLabel << "\n";
    OUT_STREAM << "L" << label << ":\n";
}

void GenIfEnd() {
    int label = PopLabel();
    OUT_STREAM << "L" << label << ":\n";
}

void GenWhileStart() {
    int L_begin = PushLabel();
    OUT_STREAM << "L" << L_begin << ":\n";
}

void GenWhileCondition() {
    int L_exit = PushLabel();
    OUT_STREAM << "ifeq L" << L_exit << "\n";
}

void GenWhileEnd() {
    int L_exit = PopLabel();
    int L_begin = PopLabel();
    OUT_STREAM << "goto L" << L_begin << "\n";
    OUT_STREAM << "L" << L_exit << ":\n";
}