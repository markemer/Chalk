/* definitions */
%option reentrant noyywrap
%option extra-type="void*"
%option prefix="yy_rpn"
/*%option header-file="chalk-lexer-rpn.flex.h"*/

%{
  #include "chalk-parser-rpn.h"
  #include "CHParserContext.h"
  #include "CHUtils.h"
  #define YY_NO_INPUT
  #define YY_INIT yy_rpnset_column(0, scanner);
  #define YY_USER_ACTION {NSRange currentRange = NSMakeRange(yy_rpnget_column(yyscanner), yy_rpnget_leng(yyscanner)); yy_rpnset_column((int)(currentRange.location+currentRange.length), yyscanner);
  #define YY_BREAK } break;
  extern void tokenizerEmit_rpn(int tokenId, const unsigned char* input, size_t length, NSRange range, CHParserContext* context);
  //#define YY_INPUT(buf,result,max_size) result = [((CHParserContext*)yy_rpnget_extra(yyscanner)).parserFeeder feedBuffer:buf length:max_size]
  #define ECHO {CHParserContext* context = yy_rpnget_extra(yyscanner); context.lastTokenRange = NSMakeRange(yy_rpnget_column(yyscanner), yy_rpnget_leng(yyscanner)); context.stop = YES; yyterminate();}
%}

UNBREAKABLE_SPACE (\xC2\xA0)
WHITESPACE  ([\f\n\r\t ]|{UNBREAKABLE_SPACE})+
KEYWORD_AND (?i:AND)
KEYWORD_NOT (?i:NOT)
KEYWORD_OR  (?i:OR)
KEYWORD_XOR (?i:XOR)

SYMBOL_EXPONENT #?[eEpP]
SYMBOL_PI (\xCF\x80)|(\xF0\x9D\x9B\x91)|(\xF0\x9D\x9C\x8B)|(\xF0\x9D\x9D\x85)|(\xF0\x9D\x9D\xBF)|(\xF0\x9D\x9E\xB9)
SYMBOL_INFINITY (\xE2\x88\x9E)
SYMBOL_SQRT (\xE2\x88\x9A)
SYMBOL_CBRT (\xE2\x88\x9B)
SYMBOL_ELLIPSIS_INCLUSIVE (\.\.\.)
SYMBOL_ELLIPSIS_EXCLUSIVE (\.\.\<)
SYMBOL_ELLIPSIS {SYMBOL_ELLIPSIS_INCLUSIVE}|(\xE2\x80\xA6)
SYMBOL_PER_CENT (\%)
SYMBOL_PER_THOUSAND (\xE2\x80\xB0)
SYMBOL_PER_TEN_THOUSAND (\xE2\x80\xB1)
SYMBOL_PER_MILLION (\xE3\x8F\x99)|(ppm)
SYMBOL_PER_FRACTION ({SYMBOL_PER_CENT}|{SYMBOL_PER_THOUSAND}|{SYMBOL_PER_TEN_THOUSAND}|{SYMBOL_PER_MILLION})

IF (?i:if)
THEN (?i:then)
ELSE (?i:else)
QUESTION \?
ALTERNATE \:

/*IDENTIFIER {SYMBOL_PI}|{SYMBOL_INFINITY}|{SYMBOL_SQRT}|{SYMBOL_CBRT}|(?i:[_a-z]+[_a-z0-9]*)*/
IDENTIFIER {SYMBOL_PI}|{SYMBOL_INFINITY}|(?i:[_a-z]+[_a-z0-9]*)

DIGIT_GENERIC     (?i:[0-9a-z])

BASE_IDENTIFIER   (?i:[0-9a-z#&_$]*[a-z#&_$]+)+

INTEGER_RADICAL_GENERIC     {DIGIT_GENERIC}+|({DIGIT_GENERIC}+{UNBREAKABLE_SPACE}+{DIGIT_GENERIC}*)+

INTEGER_POSITIVE {BASE_IDENTIFIER}?{INTEGER_RADICAL_GENERIC}{BASE_IDENTIFIER}?

INDEX_RANGE_OPERATOR_INCLUSIVE \.\.\.
INDEX_RANGE_OPERATOR_EXCLUSIVE \.\.\<
INDEX_RANGE_OPERATOR {INDEX_RANGE_OPERATOR_INCLUSIVE}|{INDEX_RANGE_OPERATOR_EXCLUSIVE}
INDEX_RANGE_JOKER    \*

DECIMAL_SEPARATOR \.

REAL_EXPONENT {SYMBOL_EXPONENT}[\-]?{INTEGER_POSITIVE}
REAL_POSITIVE ({INTEGER_POSITIVE}{SYMBOL_ELLIPSIS})|({INTEGER_POSITIVE}{SYMBOL_ELLIPSIS}?{REAL_EXPONENT})|({BASE_IDENTIFIER}?{INTEGER_RADICAL_GENERIC}{DECIMAL_SEPARATOR}{INTEGER_RADICAL_GENERIC}?{SYMBOL_ELLIPSIS}?{BASE_IDENTIFIER}?{REAL_EXPONENT}?)|({BASE_IDENTIFIER}?{DECIMAL_SEPARATOR}{INTEGER_RADICAL_GENERIC}{SYMBOL_ELLIPSIS}?{BASE_IDENTIFIER}?{REAL_EXPONENT}?)

NUMBER_POSITIVE {INTEGER_POSITIVE}{SYMBOL_ELLIPSIS}?|{REAL_POSITIVE}
INTEGER_PER_FRACTION {INTEGER_POSITIVE}{SYMBOL_ELLIPSIS}?{SYMBOL_PER_FRACTION}
REAL_PER_FRACTION {REAL_POSITIVE}{SYMBOL_PER_FRACTION}

STRING_QUOTED_SIMPLE \'(?:\\.|[^\'\\])*\'
STRING_QUOTED_DOUBLE \"(?:\\.|[^\"\\])*\"
STRING_QUOTED {STRING_QUOTED_SIMPLE}|{STRING_QUOTED_DOUBLE}

PARENTHESIS_LEFT \(
PARENTHESIS_RIGHT \)

OPERATOR_PLUS   \+
OPERATOR_MINUS  (\-)
OPERATOR_MINUS_UNARY (?i:NEG)|(\x22\x12)
OPERATOR_TIMES   (\*)|(\xC3\x97)
OPERATOR_DIVIDE  (\/)|(\xC3\xB7)
OPERATOR_POW     (\^)|(\*\*)
OPERATOR_SQRT    {SYMBOL_SQRT}
OPERATOR_CBRT    {SYMBOL_CBRT}
OPERATOR_PLUS2   {OPERATOR_PLUS}\?
OPERATOR_MINUS2  {OPERATOR_MINUS}\?
OPERATOR_TIMES2  {OPERATOR_TIMES}\?
OPERATOR_DIVIDE2 {OPERATOR_DIVIDE}\?
OPERATOR_POW2    (\^\?)|(\*\*\?)
OPERATOR_SQRT2   {SYMBOL_SQRT}\?
OPERATOR_CBRT2   {SYMBOL_CBRT}\?
OPERATOR_UNCERTAINTY (\+\/\-)|(\xC2\xB1)

OPERATOR_FACTORIAL \!
OPERATOR_FACTORIAL2 {OPERATOR_FACTORIAL}\?
OPERATOR_DEGREE (\°)|(\x00\xBA)|(\x22\x18)
OPERATOR_DEGREE2 {OPERATOR_DEGREE}\?

OPERATOR_ABS \|

OPERATOR_LEQ (\<\=)|(\x22\x64)
OPERATOR_GEQ (\>\=)|(\x22\x65)
OPERATOR_LOW \<
OPERATOR_GRE \>
OPERATOR_EQU \=\=
OPERATOR_NEQ (\!\=)|(\x22\x60)
OPERATOR_AND {KEYWORD_AND}|(\&\&)|(\x22\x27)
OPERATOR_OR  {KEYWORD_OR}|(\|\|)|(\x22\x28)
OPERATOR_XOR {KEYWORD_XOR}|(\^\^)|(\x22\xBB)
OPERATOR_SHL (\<\<)|(\x22\x6A)
OPERATOR_SHR (\>\>)|(\x22\x6B)
OPERATOR_NOT {KEYWORD_NOT}|\~
OPERATOR_LEQ2 {OPERATOR_LEQ}\?
OPERATOR_GEQ2 {OPERATOR_GEQ}\?
OPERATOR_LOW2 {OPERATOR_LOW}\?
OPERATOR_GRE2 {OPERATOR_GRE}\?
OPERATOR_EQU2 {OPERATOR_EQU}\?
OPERATOR_NEQ2 {OPERATOR_NEQ}\?
OPERATOR_AND2 {OPERATOR_AND}\?
OPERATOR_SHL2 {OPERATOR_SHL}\?
OPERATOR_SHR2 {OPERATOR_SHR}\?
OPERATOR_OR2  {OPERATOR_OR}\?
OPERATOR_XOR2 {OPERATOR_XOR}\?
OPERATOR_NOT2 {OPERATOR_NOT}\?

OPERATOR_ASSIGN (\:\=)|(\<\-)|(\x21\x90)
OPERATOR_ASSIGN_DYNAMIC (\:\:\=)|(\<\<\-)|(\x21\x9E)

INTERVAL_LEFT_DELIMITER  \[
INTERVAL_ITEM_SEPARATOR  \;
INTERVAL_RIGHT_DELIMITER \]

LIST_LEFT_DELIMITER  \{
LIST_RIGHT_DELIMITER \}

ENUMERATION_SEPARATOR \,

%%

{WHITESPACE} {
}
{INDEX_RANGE_OPERATOR} {
  printf("CHALK_LEMON_RPN_INDEX_RANGE_OPERATOR(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_INDEX_RANGE_OPERATOR, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{INDEX_RANGE_JOKER} {
  printf("CHALK_LEMON_RPN_INDEX_RANGE_JOKER(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_INDEX_RANGE_JOKER, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{STRING_QUOTED} {
  printf("CHALK_LEMON_RPN_STRING_QUOTED(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_STRING_QUOTED, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{PARENTHESIS_LEFT} {
  printf("CHALK_LEMON_RPN_PARENTHESIS_LEFT(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_PARENTHESIS_LEFT, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{PARENTHESIS_RIGHT} {
  printf("CHALK_LEMON_RPN_PARENTHESIS_RIGHT(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_PARENTHESIS_RIGHT, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_PLUS} {
  printf("CHALK_LEMON_RPN_OPERATOR_PLUS(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_PLUS, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_PLUS2} {
  printf("CHALK_LEMON_RPN_OPERATOR_PLUS2(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_PLUS2, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_MINUS} {
  printf("CHALK_LEMON_RPN_OPERATOR_MINUS(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_MINUS, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_MINUS2} {
  printf("CHALK_LEMON_RPN_OPERATOR_MINUS2(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_MINUS2, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_MINUS_UNARY} {
  printf("CHALK_LEMON_RPN_OPERATOR_MINUS_UNARY(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_MINUS_UNARY, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_TIMES} {
  printf("CHALK_LEMON_RPN_OPERATOR_TIMES(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_TIMES, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_TIMES2} {
  printf("CHALK_LEMON_RPN_OPERATOR_TIMES2(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_TIMES2, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_DIVIDE} {
  printf("CHALK_LEMON_RPN_OPERATOR_DIVIDE(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_DIVIDE, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_DIVIDE2} {
  printf("CHALK_LEMON_RPN_OPERATOR_DIVIDE2(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_DIVIDE2, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_POW} {
  printf("CHALK_LEMON_RPN_OPERATOR_POW(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_POW, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_POW2} {
  printf("CHALK_LEMON_RPN_OPERATOR_POW2(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_POW2, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_SQRT} {
  printf("CHALK_LEMON_RPN_OPERATOR_SQRT(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_SQRT, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_SQRT2} {
  printf("CHALK_LEMON_RPN_OPERATOR_SQRT2(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_SQRT2, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_CBRT} {
  printf("CHALK_LEMON_RPN_OPERATOR_CBRT(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_CBRT, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_CBRT2} {
  printf("CHALK_LEMON_RPN_OPERATOR_CBRT2(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_CBRT2, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_FACTORIAL} {
  printf("CHALK_LEMON_RPN_OPERATOR_FACTORIAL(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_FACTORIAL, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_FACTORIAL2} {
  printf("CHALK_LEMON_RPN_OPERATOR_FACTORIAL2(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_FACTORIAL2, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_DEGREE} {
  printf("CHALK_LEMON_RPN_OPERATOR_DEGREE(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_DEGREE, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_DEGREE2} {
  printf("CHALK_LEMON_RPN_OPERATOR_DEGREE2(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_DEGREE2, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_UNCERTAINTY} {
  printf("CHALK_LEMON_RPN_OPERATOR_UNCERTAINTY(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_UNCERTAINTY, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_ABS} {
  printf("CHALK_LEMON_RPN_OPERATOR_ABS(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_ABS, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_NOT} {
  printf("CHALK_LEMON_RPN_OPERATOR_NOT(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_NOT, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_NOT2} {
  printf("CHALK_LEMON_RPN_OPERATOR_NOT2(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_NOT2, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_LEQ} {
  printf("CHALK_LEMON_RPN_OPERATOR_LEQ(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_LEQ, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_LEQ2} {
  printf("CHALK_LEMON_RPN_OPERATOR_LEQ2(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_LEQ2, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_GEQ} {
  printf("CHALK_LEMON_RPN_OPERATOR_GEQ(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_GEQ, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_GEQ2} {
  printf("CHALK_LEMON_RPN_OPERATOR_GEQ2(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_GEQ2, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_LOW} {
  printf("CHALK_LEMON_RPN_OPERATOR_LOW(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_LOW, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_LOW2} {
  printf("CHALK_LEMON_RPN_OPERATOR_LOW2(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_LOW2, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_GRE} {
  printf("CHALK_LEMON_RPN_OPERATOR_GRE(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_GRE, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_GRE2} {
  printf("CHALK_LEMON_RPN_OPERATOR_GRE2(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_GRE2, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_EQU} {
  printf("CHALK_LEMON_RPN_OPERATOR_EQU(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_EQU, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_EQU2} {
  printf("CHALK_LEMON_RPN_OPERATOR_EQU2(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_EQU2, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_NEQ} {
  printf("CHALK_LEMON_RPN_OPERATOR_NEQ(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_NEQ, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_NEQ2} {
  printf("CHALK_LEMON_RPN_OPERATOR_NEQ2(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_NEQ2, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_AND} {
  printf("CHALK_LEMON_RPN_OPERATOR_AND(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_AND, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_AND2} {
  printf("CHALK_LEMON_RPN_OPERATOR_AND2(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_AND2, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_OR} {
  printf("CHALK_LEMON_RPN_OPERATOR_OR(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_OR, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_OR2} {
  printf("CHALK_LEMON_RPN_OPERATOR_OR2(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_OR2, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_XOR} {
  printf("CHALK_LEMON_RPN_OPERATOR_XOR(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_XOR, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_XOR2} {
  printf("CHALK_LEMON_RPN_OPERATOR_XOR2(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_XOR2, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_SHL} {
  printf("CHALK_LEMON_RPN_OPERATOR_SHL(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_SHL, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_SHR} {
  printf("CHALK_LEMON_RPN_OPERATOR_SHR(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_SHR, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_ASSIGN} {
  printf("CHALK_LEMON_RPN_OPERATOR_ASSIGN(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_ASSIGN, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_ASSIGN_DYNAMIC} {
  printf("CHALK_LEMON_RPN_OPERATOR_ASSIGN_DYNAMIC(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_OPERATOR_ASSIGN_DYNAMIC, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{INTERVAL_LEFT_DELIMITER} {
  printf("CHALK_LEMON_RPN_INTERVAL_LEFT_DELIMITER(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_INTERVAL_LEFT_DELIMITER, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{INTERVAL_ITEM_SEPARATOR} {
  printf("CHALK_LEMON_RPN_INTERVAL_ITEM_SEPARATOR(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_INTERVAL_ITEM_SEPARATOR, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{INTERVAL_RIGHT_DELIMITER} {
  printf("CHALK_LEMON_RPN_INTERVAL_RIGHT_DELIMITER(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_INTERVAL_RIGHT_DELIMITER, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{LIST_LEFT_DELIMITER} {
  printf("CHALK_LEMON_RPN_LIST_LEFT_DELIMITER(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_LIST_LEFT_DELIMITER, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{LIST_RIGHT_DELIMITER} {
  printf("CHALK_LEMON_RPN_LIST_RIGHT_DELIMITER(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_LIST_RIGHT_DELIMITER, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{ENUMERATION_SEPARATOR} {
  printf("CHALK_LEMON_RPN_ENUMERATION_SEPARATOR(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_ENUMERATION_SEPARATOR, (const unsigned char*)yytext, yyleng, 
                currentRange, yyget_extra(yyscanner));}
{IF} {
  printf("CHALK_LEMON_RPN_IF(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_IF, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{THEN} {
  printf("CHALK_LEMON_RPN_THEN(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_THEN, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{ELSE} {
  printf("CHALK_LEMON_RPN_ELSE(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_ELSE, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{QUESTION} {
  printf("CHALK_LEMON_RPN_QUESTION(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_QUESTION, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{ALTERNATE} {
  printf("CHALK_LEMON_RPN_ALTERNATE(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_ALTERNATE, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{IDENTIFIER} {
  printf("CHALK_LEMON_RPN_IDENTIFIER(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_IDENTIFIER, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{INTEGER_PER_FRACTION} {
  DebugLogStatic(1, @"INTEGER_PER_FRACTION(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_INTEGER_PER_FRACTION, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{REAL_PER_FRACTION} {
  DebugLogStatic(1, @"REAL_PER_FRACTION(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_REAL_PER_FRACTION, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{INTEGER_POSITIVE} {
  printf("CHALK_LEMON_RPN_INTEGER_POSITIVE(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_INTEGER_POSITIVE, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{REAL_POSITIVE} {
  printf("REAL_POSITIVE(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit_rpn(CHALK_LEMON_RPN_REAL_POSITIVE, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}               
%%

void chalk_scan_rpn_buffer(const char* bytes, NSUInteger length, CHParserContext* context)
{
  yyscan_t scanner;
  yy_rpnlex_init_extra(context, &scanner);
  yy_rpn_scan_bytes(bytes, length, scanner);
  yy_rpnset_column(0, scanner);
  yy_rpnlex(scanner);
  yy_rpnlex_destroy(scanner);
}
//end chalk_scan_rpn_buffer()

void chalk_scan_rpn_file(FILE* file, CHParserContext* context)
{
  yyscan_t scanner;
  yy_rpnlex_init_extra(context, &scanner);
  yy_rpnrestart(file, scanner);
  yy_rpnset_column(0, scanner);
  yy_rpnlex(scanner);
  yy_rpnlex_destroy(scanner);
}
//end chalk_scan_rpn_file()

void chalk_scan_rpn_fileDescriptor(int fd, CHParserContext* context)
{
  FILE* file = fdopen(fd, "rb");
  chalk_scan_rpn_file(file, context);
  fclose(file);
}
//end chalk_scan_rpn_fileDescriptor()

void chalk_scan_rpn_nsstring(NSString* input, CHParserContext* context)
{
  const char* bytes = [input UTF8String];
  NSUInteger length = [input lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
  chalk_scan_rpn_buffer(bytes, length, context);
}
//end chalk_scan_rpn_nsstring()

void chalk_scan_rpn(CHParserContext* context)
{
  yyscan_t scanner;
  yy_rpnlex_init_extra(context, &scanner);
  yy_rpn_scan_buffer(0, 0, scanner);//no initial data, it will be queried by YY_INPUT
  yy_rpnlex(scanner);//won't return until 0 is returned by YY_INPUT
  yy_rpnlex_destroy(scanner);
}
//end chalk_scan_rpn()
