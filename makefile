TARGET = parser
LEX = flex
YACC = yacc
YACCFLAG = -y -d
CXX = g++
CXXFLAG = -std=c++11 -Wno-deprecated-register

.PHONY: all clean

all: $(TARGET)

$(TARGET): lex.yy.cpp y.tab.cpp symbols.cpp symbols.hpp 
	$(CXX) $(CXXFLAG) y.tab.cpp symbols.cpp -o $@ -ll -ly

lex.yy.cpp: proj1.l
	$(LEX) -o $@ $^

y.tab.cpp: proj2.y
	$(YACC) $(YACCFLAG) $^ -o $@

clean:
	$(RM) $(TARGET) lex.yy.cpp y.tab.*
