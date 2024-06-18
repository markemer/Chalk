/* definitions */
%option reentrant noyywrap
%option extra-type="void*"
%option prefix="yy_"
/*%option header-file="chalk-lexer.flex.h"*/

%{
  #include "chalk-parser.h"
  #include "CHParserContext.h"
  #include "CHUtils.h"
  #define YY_NO_INPUT
  #define YY_INIT yyset_column(0, scanner);
  #define YY_USER_ACTION {NSRange currentRange = NSMakeRange(yyget_column(yyscanner), yyget_leng(yyscanner)); yyset_column((int)(currentRange.location+currentRange.length), yyscanner);
  #define YY_BREAK } break;
  extern void tokenizerEmit(int tokenId, const unsigned char* input, size_t length, NSRange range, CHParserContext* context);
  //#define YY_INPUT(buf,result,max_size) result = [((CHParserContext*)yyget_extra(yyscanner)).parserFeeder feedBuffer:buf length:max_size]
  #define ECHO {CHParserContext* context = yyget_extra(yyscanner); context.lastTokenRange = NSMakeRange(yyget_column(yyscanner), yyget_leng(yyscanner)); context.stop = YES; yyterminate();}
%}

UNBREAKABLE_SPACE (\xC2\xA0)
WHITESPACE  ([ \f\r\t]|{UNBREAKABLE_SPACE})+
BLANK       ([\n]|{WHITESPACE})+
KEYWORD_AND (?i:AND)
KEYWORD_NOT (?i:NOT)
KEYWORD_OR  (?i:OR)
KEYWORD_XOR (?i:XOR)

SYMBOL_EXPONENT #?[eEpP]
SYMBOL_PI (\x01\xD7\x0B)|(\xCF\x80)|(\xF0\x9D\x9B\x91)|(\xF0\x9D\x9C\x8B)|(\xF0\x9D\x9D\x85)|(\xF0\x9D\x9D\xBF)|(\xF0\x9D\x9E\xB9)
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

INTEGER_RADICAL_GENERIC     {DIGIT_GENERIC}+|({DIGIT_GENERIC}+{WHITESPACE}+{DIGIT_GENERIC}+)+

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
OPERATOR_MINUS_UNARY (\x22\x12)
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
  DebugLogStatic(1, @"CHALK_LEMON_INDEX_RANGE_OPERATOR(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_INDEX_RANGE_OPERATOR, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{INDEX_RANGE_JOKER} {
  DebugLogStatic(1, @"CHALK_LEMON_INDEX_RANGE_JOKER(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_INDEX_RANGE_JOKER, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{STRING_QUOTED} {
  DebugLogStatic(1, @"CHALK_LEMON_STRING_QUOTED(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_STRING_QUOTED, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{PARENTHESIS_LEFT} {
  DebugLogStatic(1, @"CHALK_LEMON_PARENTHESIS_LEFT(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_PARENTHESIS_LEFT, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{PARENTHESIS_RIGHT} {
  DebugLogStatic(1, @"CHALK_LEMON_PARENTHESIS_RIGHT(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_PARENTHESIS_RIGHT, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_PLUS} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_PLUS(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_PLUS, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_PLUS2} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_PLUS2(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_PLUS2, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_MINUS} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_MINUS(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_MINUS, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_MINUS2} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_MINUS2(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_MINUS2, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_MINUS_UNARY} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_MINUS_UNARY(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_MINUS_UNARY, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_TIMES} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_TIMES(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_TIMES, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_TIMES2} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_TIMES2(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_TIMES2, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_DIVIDE} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_DIVIDE(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_DIVIDE, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_DIVIDE2} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_DIVIDE2(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_DIVIDE2, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_POW} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_POW(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_POW, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_POW2} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_POW2(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_POW2, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_SQRT} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_SQRT(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_SQRT, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_SQRT2} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_SQRT2(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_SQRT2, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_CBRT} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_CBRT(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_CBRT, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_CBRT2} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_CBRT2(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_CBRT2, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_FACTORIAL} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_FACTORIAL(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_FACTORIAL, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_FACTORIAL2} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_FACTORIAL2(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_FACTORIAL2, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_DEGREE} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_DEGREE(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_DEGREE, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_DEGREE2} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_DEGREE2(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_DEGREE2, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_UNCERTAINTY} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_UNCERTAINTY(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_UNCERTAINTY, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_ABS} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_ABS(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_ABS, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_NOT} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_NOT(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_NOT, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_NOT2} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_NOT2(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_NOT2, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_LEQ} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_LEQ(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_LEQ, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_LEQ2} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_LEQ2(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_LEQ2, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_GEQ} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_GEQ(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_GEQ, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_GEQ2} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_GEQ2(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_GEQ2, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_LOW} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_LOW(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_LOW, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_LOW2} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_LOW2(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_LOW2, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_GRE} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_GRE(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_GRE, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_GRE2} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_GRE2(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_GRE2, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_EQU} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_EQU(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_EQU, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_EQU2} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_EQU2(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_EQU2, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_NEQ} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_NEQ(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_NEQ, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_NEQ2} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_NEQ2(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_NEQ2, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_AND} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_AND(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_AND, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_AND2} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_AND2(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_AND2, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_OR} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_OR(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_OR, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_OR2} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_OR2(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_OR2, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_XOR} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_XOR(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_XOR, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_XOR2} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_XOR2(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_XOR2, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_SHL} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_SHL(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_SHL, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_SHR} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_SHR(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_SHR, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_ASSIGN} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_ASSIGN(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_ASSIGN, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{OPERATOR_ASSIGN_DYNAMIC} {
  DebugLogStatic(1, @"CHALK_LEMON_OPERATOR_ASSIGN_DYNAMIC(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_OPERATOR_ASSIGN_DYNAMIC, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{INTERVAL_LEFT_DELIMITER} {
  DebugLogStatic(1, @"CHALK_LEMON_INTERVAL_LEFT_DELIMITER(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_INTERVAL_LEFT_DELIMITER, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{INTERVAL_ITEM_SEPARATOR} {
  DebugLogStatic(1, @"CHALK_LEMON_INTERVAL_ITEM_SEPARATOR(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_INTERVAL_ITEM_SEPARATOR, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{INTERVAL_RIGHT_DELIMITER} {
  DebugLogStatic(1, @"CHALK_LEMON_INTERVAL_RIGHT_DELIMITER(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_INTERVAL_RIGHT_DELIMITER, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{LIST_LEFT_DELIMITER} {
  DebugLogStatic(1, @"CHALK_LEMON_LIST_LEFT_DELIMITER(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_LIST_LEFT_DELIMITER, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{LIST_RIGHT_DELIMITER} {
  DebugLogStatic(1, @"CHALK_LEMON_LIST_RIGHT_DELIMITER(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_LIST_RIGHT_DELIMITER, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{ENUMERATION_SEPARATOR} {
  DebugLogStatic(1, @"CHALK_LEMON_ENUMERATION_SEPARATOR(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_ENUMERATION_SEPARATOR, (const unsigned char*)yytext, yyleng, 
                currentRange, yyget_extra(yyscanner));}
{IF} {
  DebugLogStatic(1, @"CHALK_LEMON_IF(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_IF, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{THEN} {
  DebugLogStatic(1, @"CHALK_LEMON_THEN(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_THEN, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{ELSE} {
  DebugLogStatic(1, @"CHALK_LEMON_ELSE(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_ELSE, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{QUESTION} {
  DebugLogStatic(1, @"CHALK_LEMON_QUESTION(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_QUESTION, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{ALTERNATE} {
  DebugLogStatic(1, @"CHALK_LEMON_ALTERNATE(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_ALTERNATE, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{IDENTIFIER} {
  DebugLogStatic(1, @"CHALK_LEMON_IDENTIFIER(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_IDENTIFIER, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{INTEGER_PER_FRACTION} {
  DebugLogStatic(1, @"INTEGER_PER_FRACTION(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_INTEGER_PER_FRACTION, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{REAL_PER_FRACTION} {
  DebugLogStatic(1, @"REAL_PER_FRACTION(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_INTEGER_PER_FRACTION, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{INTEGER_POSITIVE} {
  DebugLogStatic(1, @"CHALK_LEMON_INTEGER_POSITIVE(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_INTEGER_POSITIVE, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
{REAL_POSITIVE} {
  DebugLogStatic(1, @"REAL_POSITIVE(%s)\n", (const unsigned char*)yytext);
  tokenizerEmit(CHALK_LEMON_REAL_POSITIVE, (const unsigned char*)yytext, yyleng,
                currentRange, yyget_extra(yyscanner));}
%%

void chalk_scan_buffer(const char* bytes, NSUInteger length, CHParserContext* context)
{
  yyscan_t scanner;
  yylex_init_extra(context, &scanner);
  yy_scan_bytes(bytes, length, scanner);
  yyset_column(0, scanner);
  yylex(scanner);
  yylex_destroy(scanner);
}
//end chalk_scan_buffer()

void chalk_scan_file(FILE* file, CHParserContext* context)
{
  yyscan_t scanner;
  yylex_init_extra(context, &scanner);
  yyrestart(file, scanner);
  yyset_column(0, scanner);
  yylex(scanner);
  yylex_destroy(scanner);
}
//end chalk_scan_file()

void chalk_scan_fileDescriptor(int fd, CHParserContext* context)
{
  FILE* file = fdopen(fd, "rb");
  chalk_scan_file(file, context);
  fclose(file);
}
//end chalk_scan_fileDescriptor()

void chalk_scan_nsstring(NSString* input, CHParserContext* context)
{
  const char* bytes = [input UTF8String];
  NSUInteger length = [input lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
  chalk_scan_buffer(bytes, length, context);
}
//end chalk_scan_nsstring()

void chalk_scan(CHParserContext* context)
{
  yyscan_t scanner;
  yylex_init_extra(context, &scanner);
  yy_scan_buffer(0, 0, scanner);//no initial data, it will be queried by YY_INPUT
  yylex(scanner);//won't return until 0 is returned by YY_INPUT
  yylex_destroy(scanner);
}
//end chalk_start_scan()
