%{

#include <string>
#include <vector>
#include <map>
#include "y.tab.hpp"

using std::string;
using std::vector;
using std::map;

#define MAX_LINE_LENG 256
#define LIST strcat(g_buf, yytext)
#define token(_t_) { LIST; printf("<%s>\n", #_t_); }
#define token2(_t_) { LIST; printf("<'%s'>\n", _t_); }
#define tokenChar(_t_) { LIST; printf("<'%c'>\n", _t_); }
#define tokenInteger(_t_,_i_) { LIST; printf("<%s: %d>\n", #_t_, _i_); }
#define tokenString(_t_,_s_) { LIST; printf("<%s: %s>\n", #_t_, _s_); }

int g_linenum = 1;
char g_buf[MAX_LINE_LENG];

%}

DELIMITERS     [,:\.;(\)\[\]\{\}]
ARITHMETIC     [\*\-\+\/\%]

ASSIGNMENT     (:=)
RELATIONAL_UNARY ([<>=])

IDENTIFIER     [A-Za-z][0-9A-Za-z]*

INTEGER        [0-9]+
REAL           [-+]?[0-9]+(\.[0-9]+([Ee][-+]?[0-9]+)?)?

STRING         \".*\"
WHITE_SPAC     [\s\t]+

SINGLE_COMMENT \/\/[^\n]*
BEGIN_COMMENT  \(\*
END_COMMENT    \*\)

%x COMMENT

%%

"array"          {token(ARRAY);return ARRAY;}
"of"             {token(OF);return OF;}
"boolean"        {token(BOOLEAN); return BOOLEAN;}
"begin"          {token(BEGIN_token); return BEGIN_token;}
"break"          {token(BREAK); return BREAK;}
"char"           {token(CHAR); return CHAR;}
"case"           {token(CASE); return CASE;}
"const"          {token(CONST); return CONST;}
"continue"       {token(CONTINUE); return CONTINUE;}
"do"             {token(DO); return DO;}
"else"           {token(ELSE); return ELSE;}
"end"            {token(END); return END;}
"exit"           {token(EXIT); return EXIT;}
"for"            {token(FOR); return FOR;}
"fn"             {token(FN); return FN;}
"if"             {token(IF); return IF;}
"integer"        {token(INTEGER); return INTEGER;}
"loop"           {token(LOOP); return LOOP;}
"module"         {token(MODULE); return MODULE;}
"print"          {token(PRINT); return PRINT;}
"println"        {token(PRINTLN); return PRINTLN;}
"procedure"      {token(PROCEDURE); return PROCEDURE;}
"repeat"         {token(REPEAT); return REPEAT;}
"return"         {token(RETURN); return RETURN;}
"real"           {token(REAL); return REAL;}
"string"         {token(STRING); return STRING;}
"record"         {token(RECORD); return RECORD;}
"then"           {token(THEN); return THEN;}
"type"           {token(TYPE); return TYPE;}
"use"            {token(USE); return USE;}
"until"          {token(UNTIL); return UNTIL;}
"var"            {token(VAR); return VAR;}
"while"          {token(WHILE); return WHILE;}
"read"           {token(READ); return READ;}

"&&"             {token('&&'); return AND;}
"||"             {token('||'); return OR;}

"=="              {token('=='); return EQ;}
"<>"             {token('<>'); return NEQ;}
">="             {token('>='); return GE;}
"<="             {token('<='); return LE;}

"~"              {token('~'); return yytext[0];}

"false" {
	tokenString("boolean","FALSE");
	// yyval -> declare in parser.y
	yylval.bval = false;
	return BOOL_CONST;
}

"true" {
	tokenString("boolean","TRUE");
	yylval.bval = true;
	return BOOL_CONST;
}

{IDENTIFIER}            {
                          tokenString(id, yytext);
                          yylval.sval = new string(yytext);
	                        return ID;
                        }

{ASSIGNMENT} {token(ASSIGNMENT_token); return ASSIGNMENT_token;}

{DELIMITERS} |
{ARITHMETIC} |
{RELATIONAL_UNARY}      { 
                            token2(yytext);
                            return yytext[0];
                        }

{INTEGER}               {
                          tokenInteger(INTEGER, atoi(yytext));
                          yylval.val = atoi(yytext);
	                        return INT_CONST;
                        }

{REAL}                  {
                          tokenString(REAL, yytext);
                          yylval.dval = atof(yytext);
                          return REAL_CONST;
                        }

{STRING}                {
                          char s[MAX_LINE_LENG] = {0};
                          int idx = 0;
                          for (int i = 1; i < yyleng - 1; ++i) {
                            if (i < yyleng - 2 && yytext[i] == '"' && yytext[i+1] == '"') {
                                s[idx++] = '"';
                                i += 1;
                            }else{
                                s[idx++] = yytext[i];
                            }
                          }
                          tokenString(STRING, s);
                          yylval.sval = new string(s);
	                        return STR_CONST;
                        }

{SINGLE_COMMENT}        { LIST; }

{BEGIN_COMMENT}         {
                          LIST;
                          BEGIN COMMENT;
                        }

<COMMENT>[^\n]          {
                          LIST;
                        }

<COMMENT>\n             {
                          LIST;
                          printf("%d: %s", g_linenum, g_buf);
                          g_linenum++;
                          g_buf[0] = '\0';
                        }

<COMMENT>{END_COMMENT}  {
                          LIST;
                          BEGIN INITIAL;
                        }

\r?\n                   {
                          LIST;
                          printf("%d: %s", g_linenum, g_buf);
                          g_linenum++;
                          g_buf[0] = '\0';
                        }

[ \t]*                  { LIST; }

.                       {
                          LIST;
                          printf("%d:%s\n", g_linenum, g_buf);
                          printf("bad character:'%s'\n",yytext);
                          exit(-1);
                        }

{WHITE_SPAC}            { LIST; }

%%