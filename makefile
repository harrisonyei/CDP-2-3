TARGET = compiler
LEX = flex
YACC = yacc
YACCFLAG = -y -d
CXX = g++
CXXFLAG = -std=c++11 -Wno-deprecated-register

.PHONY: all clean run

all: $(TARGET)

$(TARGET): lex.yy.cpp y.tab.cpp symbols.cpp symbols.hpp GenJavaASM.cpp GenJavaASM.h
	$(CXX) $(CXXFLAG) y.tab.cpp symbols.cpp GenJavaASM.cpp -o $@ -ll -ly

lex.yy.cpp: proj1.l
	$(LEX) -o $@ $^

y.tab.cpp: proj3.y
	$(YACC) $(YACCFLAG) $^ -o $@

clean:
	$(RM) $(TARGET) lex.yy.cpp y.tab.*


run: $(TARGET)
	@test $(file)
	./$(TARGET) $(file).txt
	./javaa $(file).jasm
	@echo "--------- run -----------"
	@java $(file)
	@echo "--------- end -----------"
	@#rm $(file).jasm $(file).class
