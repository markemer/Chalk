/*
** 2000-05-29
**
** The author disclaims copyright to this source code.  In place of
** a legal notice, here is a blessing:
**
**    May you do good and not evil.
**    May you find forgiveness for yourself and forgive others.
**    May you share freely, never taking more than you give.
**
*************************************************************************
** Driver template for the LEMON parser generator.
**
** The "lemon" program processes an LALR(1) input grammar file, then uses
** this template to construct a parser.  The "lemon" program inserts text
** at each "%%" line.  Also, any "P-a-r-s-e" identifer prefix (without the
** interstitial "-" characters) contained in this template is changed into
** the value of the %name directive from the grammar.  Otherwise, the content
** of this template is copied straight through into the generate parser
** source file.
**
** The following is the concatenation of all %include directives from the
** input grammar file:
*/
#include <stdio.h>
#include <assert.h>
/************ Begin %include sections from the grammar ************************/
#line 2 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
#include <assert.h>
#line 3 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
#include "chalk-parser.h"
#line 4 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
#include "CHChalkToken.h"
#line 5 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
#include "CHParserContext.h"
#line 6 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
#include "CHParserNode.h"
#line 7 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
#include "CHParserAssignationNode.h"
#line 8 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
#include "CHParserAssignationDynamicNode.h"
#line 9 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
#include "CHParserEnumerationNode.h"
#line 10 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
#include "CHParserFunctionNode.h"
#line 11 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
#include "CHParserIdentifierNode.h"
#line 12 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
#include "CHParserIfThenElseNode.h"
#line 13 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
#include "CHParserListNode.h"
#line 14 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
#include "CHParserMatrixNode.h"
#line 15 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
#include "CHParserMatrixRowNode.h"
#line 16 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
#include "CHParserOperatorNode.h"
#line 17 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
#include "CHParserSubscriptNode.h"
#line 18 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
#include "CHParserValueIndexRangeNode.h"
#line 19 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
#include "CHParserValueNode.h"
#line 20 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
#include "CHParserValueNumberNode.h"
#line 21 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
#include "CHParserValueNumberIntegerNode.h"
#line 22 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
#include "CHParserValueNumberRealNode.h"
#line 23 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
#include "CHParserValueNumberIntervalNode.h"
#line 24 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
#include "CHParserValueNumberPerFractionNode.h"
#line 25 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
#include "CHParserValueStringNode.h"
#line 26 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
#include "CHUtils.h"
#line 79 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
/**************** End of %include directives **********************************/
/* These constants specify the various numeric values for terminal symbols
** in a format understandable to "makeheaders".  This section is blank unless
** "lemon" is run with the "-m" command-line option.
***************** Begin makeheaders token definitions *************************/
/**************** End makeheaders token definitions ***************************/

/* The next sections is a series of control #defines.
** various aspects of the generated parser.
**    YYCODETYPE         is the data type used to store the integer codes
**                       that represent terminal and non-terminal symbols.
**                       "unsigned char" is used if there are fewer than
**                       256 symbols.  Larger types otherwise.
**    YYNOCODE           is a number of type YYCODETYPE that is not used for
**                       any terminal or nonterminal symbol.
**    YYFALLBACK         If defined, this indicates that one or more tokens
**                       (also known as: "terminal symbols") have fall-back
**                       values which should be used if the original symbol
**                       would not parse.  This permits keywords to sometimes
**                       be used as identifiers, for example.
**    YYACTIONTYPE       is the data type used for "action codes" - numbers
**                       that indicate what to do in response to the next
**                       token.
**    ParseTOKENTYPE     is the data type used for minor type for terminal
**                       symbols.  Background: A "minor type" is a semantic
**                       value associated with a terminal or non-terminal
**                       symbols.  For example, for an "ID" terminal symbol,
**                       the minor type might be the name of the identifier.
**                       Each non-terminal can have a different minor type.
**                       Terminal symbols all have the same minor type, though.
**                       This macros defines the minor type for terminal 
**                       symbols.
**    YYMINORTYPE        is the data type used for all minor types.
**                       This is typically a union of many types, one of
**                       which is ParseTOKENTYPE.  The entry in the union
**                       for terminal symbols is called "yy0".
**    YYSTACKDEPTH       is the maximum depth of the parser's stack.  If
**                       zero the stack is dynamically sized using realloc()
**    ParseARG_SDECL     A static variable declaration for the %extra_argument
**    ParseARG_PDECL     A parameter declaration for the %extra_argument
**    ParseARG_PARAM     Code to pass %extra_argument as a subroutine parameter
**    ParseARG_STORE     Code to store %extra_argument into yypParser
**    ParseARG_FETCH     Code to extract %extra_argument from yypParser
**    ParseCTX_*         As ParseARG_ except for %extra_context
**    YYERRORSYMBOL      is the code number of the error symbol.  If not
**                       defined, then do no error processing.
**    YYNSTATE           the combined number of states.
**    YYNRULE            the number of rules in the grammar
**    YYNTOKEN           Number of terminal symbols
**    YY_MAX_SHIFT       Maximum value for shift actions
**    YY_MIN_SHIFTREDUCE Minimum value for shift-reduce actions
**    YY_MAX_SHIFTREDUCE Maximum value for shift-reduce actions
**    YY_ERROR_ACTION    The yy_action[] code for syntax error
**    YY_ACCEPT_ACTION   The yy_action[] code for accept
**    YY_NO_ACTION       The yy_action[] code for no-op
**    YY_MIN_REDUCE      Minimum value for reduce actions
**    YY_MAX_REDUCE      Maximum value for reduce actions
*/
#ifndef INTERFACE
# define INTERFACE 1
#endif
/************* Begin control #defines *****************************************/
#define YYCODETYPE unsigned char
#define YYNOCODE 102
#define YYACTIONTYPE unsigned short int
#define ParseTOKENTYPE CHChalkToken*
typedef union {
  int yyinit;
  ParseTOKENTYPE yy0;
  CHParserMatrixRowNode* yy6;
  CHParserValueNumberRealNode* yy19;
  CHParserAssignationNode* yy29;
  CHParserIdentifierNode* yy60;
  CHParserEnumerationNode* yy61;
  CHParserValueNumberNode* yy67;
  CHParserNode* yy101;
  CHParserValueNode* yy110;
  CHParserValueNumberIntegerNode* yy141;
  CHParserValueStringNode* yy169;
  CHParserListNode* yy173;
  CHParserValueIndexRangeNode* yy191;
  CHParserMatrixNode* yy194;
  CHParserValueNumberIntervalNode* yy196;
} YYMINORTYPE;
#ifndef YYSTACKDEPTH
#define YYSTACKDEPTH 100
#endif
#define ParseARG_SDECL CHParserContext* context;
#define ParseARG_PDECL ,CHParserContext* context
#define ParseARG_PARAM ,context
#define ParseARG_FETCH CHParserContext* context=yypParser->context;
#define ParseARG_STORE yypParser->context=context;
#define ParseCTX_SDECL
#define ParseCTX_PDECL
#define ParseCTX_PARAM
#define ParseCTX_FETCH
#define ParseCTX_STORE
#define YYNSTATE             135
#define YYNRULE              95
#define YYNRULE_WITH_ACTION  95
#define YYNTOKEN             74
#define YY_MAX_SHIFT         134
#define YY_MIN_SHIFTREDUCE   175
#define YY_MAX_SHIFTREDUCE   269
#define YY_ERROR_ACTION      270
#define YY_ACCEPT_ACTION     271
#define YY_NO_ACTION         272
#define YY_MIN_REDUCE        273
#define YY_MAX_REDUCE        367
/************* End control #defines *******************************************/
#define YY_NLOOKAHEAD ((int)(sizeof(yy_lookahead)/sizeof(yy_lookahead[0])))

/* Define the yytestcase() macro to be a no-op if is not already defined
** otherwise.
**
** Applications can choose to define yytestcase() in the %include section
** to a macro that can assist in verifying code coverage.  For production
** code the yytestcase() macro should be turned off.  But it is useful
** for testing.
*/
#ifndef yytestcase
# define yytestcase(X)
#endif


/* Next are the tables used to determine what action to take based on the
** current state and lookahead token.  These tables are used to implement
** functions that take a state number and lookahead value and return an
** action integer.  
**
** Suppose the action integer is N.  Then the action is determined as
** follows
**
**   0 <= N <= YY_MAX_SHIFT             Shift N.  That is, push the lookahead
**                                      token onto the stack and goto state N.
**
**   N between YY_MIN_SHIFTREDUCE       Shift to an arbitrary state then
**     and YY_MAX_SHIFTREDUCE           reduce by rule N-YY_MIN_SHIFTREDUCE.
**
**   N == YY_ERROR_ACTION               A syntax error has occurred.
**
**   N == YY_ACCEPT_ACTION              The parser accepts its input.
**
**   N == YY_NO_ACTION                  No such action.  Denotes unused
**                                      slots in the yy_action[] table.
**
**   N between YY_MIN_REDUCE            Reduce by rule N-YY_MIN_REDUCE
**     and YY_MAX_REDUCE
**
** The action table is constructed as a single large table named yy_action[].
** Given state S and lookahead X, the action is computed as either:
**
**    (A)   N = yy_action[ yy_shift_ofst[S] + X ]
**    (B)   N = yy_default[S]
**
** The (A) formula is preferred.  The B formula is used instead if
** yy_lookahead[yy_shift_ofst[S]+X] is not equal to X.
**
** The formulas above are for computing the action when the lookahead is
** a terminal symbol.  If the lookahead is a non-terminal (as occurs after
** a reduce action) then the yy_reduce_ofst[] array is used in place of
** the yy_shift_ofst[] array.
**
** The following are the tables generated in this section:
**
**  yy_action[]        A single table containing all actions.
**  yy_lookahead[]     A table containing the lookahead for each entry in
**                     yy_action.  Used to detect hash collisions.
**  yy_shift_ofst[]    For each state, the offset into yy_action for
**                     shifting terminals.
**  yy_reduce_ofst[]   For each state, the offset into yy_action for
**                     shifting non-terminals after a reduce.
**  yy_default[]       Default action for each state.
**
*********** Begin parsing tables **********************************************/
#define YY_ACTTAB_COUNT (2651)
static const YYACTIONTYPE yy_action[] = {
 /*     0 */   273,   11,   10,   31,   30,   29,   28,   25,   24,   23,
 /*    10 */    22,   27,   26,   43,   42,   41,   40,   39,   38,   37,
 /*    20 */    36,   35,   34,   33,   32,  352,   54,   53,   52,   51,
 /*    30 */    47,   46,   50,   48,   49,   45,   44,  363,  276,  274,
 /*    40 */    58,   57,   56,   55,  272,  272,  272,  272,  224,  225,
 /*    50 */     2,  222,  223,    2,  222,  223,  272,  272,   62,  272,
 /*    60 */   272,   62,  177,  272,  272,  127,    5,    5,  272,    5,
 /*    70 */    31,   30,   29,   28,   25,   24,   23,   22,   27,   26,
 /*    80 */    43,   42,   41,   40,   39,   38,   37,   36,   35,   34,
 /*    90 */    33,   32,    4,   54,   53,   52,   51,   47,   46,   50,
 /*   100 */    48,   49,   45,   44,    6,  222,  223,   58,   57,   56,
 /*   110 */    55,  272,   62,    7,  266,  224,  225,    2,  222,  223,
 /*   120 */     5,  272,  259,  272,  272,   62,   12,  272,  272,  272,
 /*   130 */   272,  272,  272,    5,  272,  272,  272,   31,   30,   29,
 /*   140 */    28,   25,   24,   23,   22,   27,   26,   43,   42,   41,
 /*   150 */    40,   39,   38,   37,   36,   35,   34,   33,   32,  226,
 /*   160 */    54,   53,   52,   51,   47,   46,   50,   48,   49,   45,
 /*   170 */    44,    9,    6,    6,   58,   57,   56,   55,  272,  272,
 /*   180 */   272,  272,  224,  225,    2,  222,  223,  194,  272,  263,
 /*   190 */   272,  272,   62,  267,  272,  272,  272,  272,  272,  272,
 /*   200 */     5,  272,  272,  272,   31,   30,   29,   28,   25,   24,
 /*   210 */    23,   22,   27,   26,   43,   42,   41,   40,   39,   38,
 /*   220 */    37,   36,   35,   34,   33,   32,  272,   54,   53,   52,
 /*   230 */    51,   47,   46,   50,   48,   49,   45,   44,  272,  272,
 /*   240 */   272,   58,   57,   56,   55,  272,  272,  272,  272,  224,
 /*   250 */   225,    2,  222,  223,  272,  272,  272,  272,  272,   62,
 /*   260 */   272,  272,  272,  272,  272,  272,  272,    5,  272,  272,
 /*   270 */   272,  272,  198,  272,  272,  272,   31,   30,   29,   28,
 /*   280 */    25,   24,   23,   22,   27,   26,   43,   42,   41,   40,
 /*   290 */    39,   38,   37,   36,   35,   34,   33,   32,  272,   54,
 /*   300 */    53,   52,   51,   47,   46,   50,   48,   49,   45,   44,
 /*   310 */   272,  272,  272,   58,   57,   56,   55,  272,  272,  272,
 /*   320 */   272,  224,  225,    2,  222,  223,  272,  272,  272,  272,
 /*   330 */    59,   62,  272,  272,  272,  272,  272,  272,  272,    5,
 /*   340 */   272,  272,  272,   31,   30,   29,   28,   25,   24,   23,
 /*   350 */    22,   27,   26,   43,   42,   41,   40,   39,   38,   37,
 /*   360 */    36,   35,   34,   33,   32,  272,   54,   53,   52,   51,
 /*   370 */    47,   46,   50,   48,   49,   45,   44,  272,  272,  272,
 /*   380 */    58,   57,   56,   55,  272,  272,  272,  272,  224,  225,
 /*   390 */     2,  222,  223,  272,  272,  272,   60,  272,   62,  272,
 /*   400 */   272,  272,  272,  272,  272,  272,    5,  272,  272,  272,
 /*   410 */    31,   30,   29,   28,   25,   24,   23,   22,   27,   26,
 /*   420 */    43,   42,   41,   40,   39,   38,   37,   36,   35,   34,
 /*   430 */    33,   32,  272,   54,   53,   52,   51,   47,   46,   50,
 /*   440 */    48,   49,   45,   44,  272,  272,  272,   58,   57,   56,
 /*   450 */    55,  272,  272,  272,  272,  224,  225,    2,  222,  223,
 /*   460 */   272,  272,  272,  272,  272,   62,  272,  272,  272,  272,
 /*   470 */   272,  272,  272,    5,  272,  188,  272,   31,   30,   29,
 /*   480 */    28,   25,   24,   23,   22,   27,   26,   43,   42,   41,
 /*   490 */    40,   39,   38,   37,   36,   35,   34,   33,   32,  272,
 /*   500 */    54,   53,   52,   51,   47,   46,   50,   48,   49,   45,
 /*   510 */    44,  272,  272,  272,   58,   57,   56,   55,  272,  272,
 /*   520 */   272,  272,  224,  225,    2,  222,  223,  272,  272,  272,
 /*   530 */   272,  272,   62,  272,  272,  272,  272,  272,  272,  272,
 /*   540 */     5,   63,  272,  272,   31,   30,   29,   28,   25,   24,
 /*   550 */    23,   22,   27,   26,   43,   42,   41,   40,   39,   38,
 /*   560 */    37,   36,   35,   34,   33,   32,  272,   54,   53,   52,
 /*   570 */    51,   47,   46,   50,   48,   49,   45,   44,  272,  272,
 /*   580 */   272,   58,   57,   56,   55,  272,  272,  272,  272,  224,
 /*   590 */   225,    2,  222,  223,  272,  272,  272,  272,  272,   62,
 /*   600 */   272,  272,  272,  272,  272,  272,  272,    5,  272,  272,
 /*   610 */   272,  272,  272,  272,  272,   25,   24,   23,   22,   27,
 /*   620 */    26,   43,   42,   41,   40,   39,   38,   37,   36,   35,
 /*   630 */    34,   33,   32,  272,   54,   53,   52,   51,   47,   46,
 /*   640 */    50,   48,   49,   45,   44,  272,  272,  272,   58,   57,
 /*   650 */    56,   55,  272,  272,  272,  272,  224,  225,    2,  222,
 /*   660 */   223,  272,  272,  272,  272,  272,   62,  272,  272,  272,
 /*   670 */   272,  272,  272,  272,    5,  272,   23,   22,   27,   26,
 /*   680 */    43,   42,   41,   40,   39,   38,   37,   36,   35,   34,
 /*   690 */    33,   32,  272,   54,   53,   52,   51,   47,   46,   50,
 /*   700 */    48,   49,   45,   44,  272,  272,  272,   58,   57,   56,
 /*   710 */    55,  272,  272,  272,  272,  224,  225,    2,  222,  223,
 /*   720 */   272,  272,  272,  272,  272,   62,  272,  272,  272,  272,
 /*   730 */   272,  272,  272,    5,  272,  272,  272,   27,   26,   43,
 /*   740 */    42,   41,   40,   39,   38,   37,   36,   35,   34,   33,
 /*   750 */    32,  272,   54,   53,   52,   51,   47,   46,   50,   48,
 /*   760 */    49,   45,   44,  272,  272,  272,   58,   57,   56,   55,
 /*   770 */   272,  272,  272,  272,  224,  225,    2,  222,  223,  272,
 /*   780 */   272,  272,  272,  272,   62,  272,  272,  272,  272,  272,
 /*   790 */   272,  272,    5,  272,  272,  272,  272,  272,   43,   42,
 /*   800 */    41,   40,   39,   38,   37,   36,   35,   34,   33,   32,
 /*   810 */   272,   54,   53,   52,   51,   47,   46,   50,   48,   49,
 /*   820 */    45,   44,  272,  272,  272,   58,   57,   56,   55,  272,
 /*   830 */   272,  272,  272,  224,  225,    2,  222,  223,  272,  272,
 /*   840 */   272,  272,  272,   62,  272,  272,  272,  272,  272,  272,
 /*   850 */   272,    5,  272,  272,  272,  272,  272,  270,  270,  270,
 /*   860 */   270,  270,  270,  270,  270,  270,  270,  270,  270,  272,
 /*   870 */    54,   53,   52,   51,   47,   46,   50,   48,   49,   45,
 /*   880 */    44,  272,  272,  272,   58,   57,   56,   55,  272,  272,
 /*   890 */   272,  272,  224,  225,    2,  222,  223,  272,  272,  272,
 /*   900 */    15,  272,   62,   20,  272,  272,  272,  272,  272,  272,
 /*   910 */     5,  272,   14,   13,   21,   19,   18,   17,   16,  272,
 /*   920 */   272,  272,  272,  272,  272,  272,  272,  272,  272,  272,
 /*   930 */    61,  272,  272,  272,  272,  177,  272,  180,  183,  184,
 /*   940 */   187,   64,  272,   15,  189,    8,   20,    3,  272,  272,
 /*   950 */   272,  272,  179,  272,  272,   14,   13,   21,   19,   18,
 /*   960 */    17,   16,  272,  272,  272,  272,  272,  272,  272,  272,
 /*   970 */   272,  272,  272,   61,  272,  272,  272,  272,  177,  272,
 /*   980 */   180,  272,  272,  187,   64,  272,  272,  189,    8,  272,
 /*   990 */     3,   47,   46,   50,   48,   49,   45,   44,  272,  272,
 /*  1000 */   272,   58,   57,   56,   55,  272,  272,  272,  272,  224,
 /*  1010 */   225,    2,  222,  223,  272,  272,  272,   15,  272,   62,
 /*  1020 */    20,  272,  272,  272,  272,  272,  272,    5,  272,   14,
 /*  1030 */    13,   21,   19,   18,   17,   16,  272,  272,  272,  272,
 /*  1040 */   272,  272,  272,  272,  272,  272,  272,   61,  272,  272,
 /*  1050 */   272,  272,  177,   15,  180,  272,   20,  187,   64,  272,
 /*  1060 */   272,  189,    8,  272,    3,   14,   13,   21,   19,   18,
 /*  1070 */    17,   16,  272,  272,  272,  272,  272,  272,  272,  272,
 /*  1080 */   272,  272,  272,   61,  272,  272,  272,  272,  177,  272,
 /*  1090 */   180,  272,  272,  187,   64,  272,  279,  189,    1,  280,
 /*  1100 */     3,  288,  272,  289,  291,  133,  293,  272,  351,  124,
 /*  1110 */   130,  272,  272,   68,  272,  272,  272,  272,  349,  350,
 /*  1120 */   272,  359,  362,  279,  272,  272,  280,  272,  288,  272,
 /*  1130 */   289,  291,  133,  293,  272,  351,  272,  272,  272,  272,
 /*  1140 */   123,  283,  284,  307,  272,  349,  350,  134,  272,  354,
 /*  1150 */   280,  272,  288,  272,  289,  291,  133,  293,  131,  351,
 /*  1160 */   272,  272,  272,  272,   77,  272,  272,  272,  272,  349,
 /*  1170 */   350,  355,  134,  272,  354,  280,  272,  288,  272,  289,
 /*  1180 */   291,  133,  293,  129,  351,  272,  272,  272,  272,   77,
 /*  1190 */   272,  272,  272,  272,  349,  350,  355,  134,  272,  354,
 /*  1200 */   280,  272,  288,  272,  289,  291,  133,  293,  128,  351,
 /*  1210 */   272,  272,  272,  272,   77,  272,  272,  272,  272,  349,
 /*  1220 */   350,  355,  279,  272,  272,  280,  272,  288,  272,  289,
 /*  1230 */   291,  133,  293,  272,  351,  272,  272,  132,  271,   65,
 /*  1240 */   272,  272,  272,  272,  349,  350,  134,  272,  354,  280,
 /*  1250 */   272,  288,  272,  289,  291,  133,  293,  272,  351,  272,
 /*  1260 */   272,  272,  272,   77,  272,  272,  272,  272,  349,  350,
 /*  1270 */   356,  279,  272,  272,  280,  272,  288,  272,  289,  291,
 /*  1280 */   133,  293,  272,  351,  272,  130,  272,  272,   76,  272,
 /*  1290 */   272,  272,  272,  349,  350,  279,  359,  272,  280,  272,
 /*  1300 */   288,  272,  289,  291,  133,  293,  272,  351,  124,  272,
 /*  1310 */   272,  272,   69,  272,  272,  272,  272,  349,  350,   45,
 /*  1320 */    44,  362,  272,  272,   58,   57,   56,   55,  272,  272,
 /*  1330 */   272,  272,  224,  225,    2,  222,  223,  272,  272,  272,
 /*  1340 */   272,  272,   62,  272,  279,  272,  272,  280,  272,  288,
 /*  1350 */     5,  289,  291,  133,  293,  272,  351,  272,  272,  272,
 /*  1360 */   272,   76,  272,  272,  272,  272,  349,  350,  272,  360,
 /*  1370 */   279,  272,  272,  280,  272,  288,  272,  289,  291,  133,
 /*  1380 */   293,  272,  351,  272,  272,  272,  272,   74,  272,  272,
 /*  1390 */   272,  272,  349,  350,  279,  272,  272,  280,  272,  288,
 /*  1400 */   272,  289,  291,  133,  293,  272,  351,  272,  272,  272,
 /*  1410 */   272,   75,  272,  272,  272,  272,  349,  350,  279,  272,
 /*  1420 */   272,  280,  272,  288,  272,  289,  291,  133,  293,  272,
 /*  1430 */   351,  272,  272,  272,  272,  125,  272,  272,  272,  272,
 /*  1440 */   349,  350,  279,  272,  272,  280,  272,  288,  272,  289,
 /*  1450 */   291,  133,  293,  272,  351,  272,  272,  272,  272,  105,
 /*  1460 */   272,  272,  272,  279,  349,  350,  280,  272,  288,  272,
 /*  1470 */   289,  291,  133,  293,  272,  351,  272,  272,  272,  272,
 /*  1480 */   106,  272,  272,  272,  272,  349,  350,  279,  272,  272,
 /*  1490 */   280,  272,  288,  272,  289,  291,  133,  293,  272,  351,
 /*  1500 */   272,  272,  272,  272,   67,  272,  272,  272,  272,  349,
 /*  1510 */   350,  279,  272,  272,  280,  272,  288,  272,  289,  291,
 /*  1520 */   133,  293,  272,  351,  272,  272,  272,  272,  114,  272,
 /*  1530 */   272,  272,  272,  349,  350,  279,  272,  272,  280,  272,
 /*  1540 */   288,  272,  289,  291,  133,  293,  272,  351,  272,  272,
 /*  1550 */   272,  272,  115,  272,  272,  272,  279,  349,  350,  280,
 /*  1560 */   272,  288,  272,  289,  291,  133,  293,  272,  351,  272,
 /*  1570 */   272,  272,  272,  116,  272,  272,  272,  272,  349,  350,
 /*  1580 */   279,  272,  272,  280,  272,  288,  272,  289,  291,  133,
 /*  1590 */   293,  272,  351,  272,  272,  272,  272,  117,  272,  272,
 /*  1600 */   272,  272,  349,  350,  279,  272,  272,  280,  272,  288,
 /*  1610 */   272,  289,  291,  133,  293,  272,  351,  272,  272,  272,
 /*  1620 */   272,  100,  272,  272,  272,  272,  349,  350,  279,  272,
 /*  1630 */   272,  280,  272,  288,  272,  289,  291,  133,  293,  272,
 /*  1640 */   351,  272,  272,  272,  272,  118,  272,  272,  272,  279,
 /*  1650 */   349,  350,  280,  272,  288,  272,  289,  291,  133,  293,
 /*  1660 */   272,  351,  272,  272,  272,  272,   84,  272,  272,  272,
 /*  1670 */   272,  349,  350,  279,  272,  272,  280,  272,  288,  272,
 /*  1680 */   289,  291,  133,  293,  272,  351,  272,  272,  272,  272,
 /*  1690 */    85,  272,  272,  272,  272,  349,  350,  279,  272,  272,
 /*  1700 */   280,  272,  288,  272,  289,  291,  133,  293,  272,  351,
 /*  1710 */   272,  272,  272,  272,   82,  272,  272,  272,  272,  349,
 /*  1720 */   350,  279,  272,  272,  280,  272,  288,  272,  289,  291,
 /*  1730 */   133,  293,  272,  351,  272,  272,  272,  272,   83,  272,
 /*  1740 */   272,  272,  279,  349,  350,  280,  272,  288,  272,  289,
 /*  1750 */   291,  133,  293,  272,  351,  272,  272,  272,  272,   86,
 /*  1760 */   272,  272,  272,  272,  349,  350,  279,  272,  272,  280,
 /*  1770 */   272,  288,  272,  289,  291,  133,  293,  272,  351,  272,
 /*  1780 */   272,  272,  272,   87,  272,  272,  272,  272,  349,  350,
 /*  1790 */   279,  272,  272,  280,  272,  288,  272,  289,  291,  133,
 /*  1800 */   293,  272,  351,  272,  272,  272,  272,   78,  272,  272,
 /*  1810 */   272,  272,  349,  350,  279,  272,  272,  280,  272,  288,
 /*  1820 */   272,  289,  291,  133,  293,  272,  351,  272,  272,  272,
 /*  1830 */   272,   79,  272,  272,  272,  279,  349,  350,  280,  272,
 /*  1840 */   288,  272,  289,  291,  133,  293,  272,  351,  272,  272,
 /*  1850 */   272,  272,   80,  272,  272,  272,  272,  349,  350,  279,
 /*  1860 */   272,  272,  280,  272,  288,  272,  289,  291,  133,  293,
 /*  1870 */   272,  351,  272,  272,  272,  272,   81,  272,  272,  272,
 /*  1880 */   272,  349,  350,  279,  272,  272,  280,  272,  288,  272,
 /*  1890 */   289,  291,  133,  293,  272,  351,  272,  272,  272,  272,
 /*  1900 */    88,  272,  272,  272,  272,  349,  350,  279,  272,  272,
 /*  1910 */   280,  272,  288,  272,  289,  291,  133,  293,  272,  351,
 /*  1920 */   272,  272,  272,  272,   89,  272,  272,  272,  279,  349,
 /*  1930 */   350,  280,  272,  288,  272,  289,  291,  133,  293,  272,
 /*  1940 */   351,  272,  272,  272,  272,   90,  272,  272,  272,  272,
 /*  1950 */   349,  350,  279,  272,  272,  280,  272,  288,  272,  289,
 /*  1960 */   291,  133,  293,  272,  351,  272,  272,  272,  272,   91,
 /*  1970 */   272,  272,  272,  272,  349,  350,  279,  272,  272,  280,
 /*  1980 */   272,  288,  272,  289,  291,  133,  293,  272,  351,  272,
 /*  1990 */   272,  272,  272,   92,  272,  272,  272,  272,  349,  350,
 /*  2000 */   279,  272,  272,  280,  272,  288,  272,  289,  291,  133,
 /*  2010 */   293,  272,  351,  272,  272,  272,  272,   93,  272,  272,
 /*  2020 */   272,  279,  349,  350,  280,  272,  288,  272,  289,  291,
 /*  2030 */   133,  293,  272,  351,  272,  272,  272,  272,   94,  272,
 /*  2040 */   272,  272,  272,  349,  350,  279,  272,  272,  280,  272,
 /*  2050 */   288,  272,  289,  291,  133,  293,  272,  351,  272,  272,
 /*  2060 */   272,  272,   95,  272,  272,  272,  272,  349,  350,  279,
 /*  2070 */   272,  272,  280,  272,  288,  272,  289,  291,  133,  293,
 /*  2080 */   272,  351,  272,  272,  272,  272,   96,  272,  272,  272,
 /*  2090 */   272,  349,  350,  279,  272,  272,  280,  272,  288,  272,
 /*  2100 */   289,  291,  133,  293,  272,  351,  272,  272,  272,  272,
 /*  2110 */    97,  272,  272,  272,  279,  349,  350,  280,  272,  288,
 /*  2120 */   272,  289,  291,  133,  293,  272,  351,  272,  272,  272,
 /*  2130 */   272,   98,  272,  272,  272,  272,  349,  350,  279,  272,
 /*  2140 */   272,  280,  272,  288,  272,  289,  291,  133,  293,  272,
 /*  2150 */   351,  272,  272,  272,  272,   99,  272,  272,  272,  272,
 /*  2160 */   349,  350,  279,  272,  272,  280,  272,  288,  272,  289,
 /*  2170 */   291,  133,  293,  272,  351,  272,  272,  272,  272,  107,
 /*  2180 */   272,  272,  272,  272,  349,  350,  279,  272,  272,  280,
 /*  2190 */   272,  288,  272,  289,  291,  133,  293,  272,  351,  272,
 /*  2200 */   272,  272,  272,  108,  272,  272,  272,  279,  349,  350,
 /*  2210 */   280,  272,  288,  272,  289,  291,  133,  293,  272,  351,
 /*  2220 */   272,  272,  272,  272,  109,  272,  272,  272,  272,  349,
 /*  2230 */   350,  279,  272,  272,  280,  272,  288,  272,  289,  291,
 /*  2240 */   133,  293,  272,  351,  272,  272,  272,  272,  110,  272,
 /*  2250 */   272,  272,  272,  349,  350,  279,  272,  272,  280,  272,
 /*  2260 */   288,  272,  289,  291,  133,  293,  272,  351,  272,  272,
 /*  2270 */   272,  272,  111,  272,  272,  272,  272,  349,  350,  279,
 /*  2280 */   272,  272,  280,  272,  288,  272,  289,  291,  133,  293,
 /*  2290 */   272,  351,  272,  272,  272,  272,  112,  272,  272,  272,
 /*  2300 */   279,  349,  350,  280,  272,  288,  272,  289,  291,  133,
 /*  2310 */   293,  272,  351,  272,  272,  272,  272,  113,  272,  272,
 /*  2320 */   272,  272,  349,  350,  279,  272,  272,  280,  272,  288,
 /*  2330 */   272,  289,  291,  133,  293,  272,  351,  272,  272,  272,
 /*  2340 */   272,  101,  272,  272,  272,  272,  349,  350,  279,  272,
 /*  2350 */   272,  280,  272,  288,  272,  289,  291,  133,  293,  272,
 /*  2360 */   351,  272,  272,  272,  272,  102,  272,  272,  272,  272,
 /*  2370 */   349,  350,  279,  272,  272,  280,  272,  288,  272,  289,
 /*  2380 */   291,  133,  293,  272,  351,  272,  272,  272,  272,  103,
 /*  2390 */   272,  272,  272,  279,  349,  350,  280,  272,  288,  272,
 /*  2400 */   289,  291,  133,  293,  272,  351,  272,  272,  272,  272,
 /*  2410 */   104,  272,  272,  272,  272,  349,  350,  279,  272,  272,
 /*  2420 */   280,  272,  288,  272,  289,  291,  133,  293,  272,  351,
 /*  2430 */   272,  272,  272,  272,  119,  272,  272,  272,  272,  349,
 /*  2440 */   350,  279,  272,  272,  280,  272,  288,  272,  289,  291,
 /*  2450 */   133,  293,  272,  351,  272,  272,  272,  272,  120,  272,
 /*  2460 */   272,  272,  272,  349,  350,  279,  272,  272,  280,  272,
 /*  2470 */   288,  272,  289,  291,  133,  293,  272,  351,  272,  272,
 /*  2480 */   272,  272,  121,  272,  272,  272,  279,  349,  350,  280,
 /*  2490 */   272,  288,  272,  289,  291,  133,  293,  272,  351,  272,
 /*  2500 */   272,  272,  272,  122,  272,  272,  272,  272,  349,  350,
 /*  2510 */   279,  272,  272,  280,  272,  288,  272,  289,  291,  133,
 /*  2520 */   293,  272,  351,  272,  272,  272,  272,  126,  272,  272,
 /*  2530 */   272,  272,  349,  350,  279,  272,  272,  280,  272,  288,
 /*  2540 */   272,  289,  291,  133,  293,  272,  351,  272,  272,  272,
 /*  2550 */   272,   70,  272,  272,  272,  272,  349,  350,  279,  272,
 /*  2560 */   272,  280,  272,  288,  272,  289,  291,  133,  293,  272,
 /*  2570 */   351,  272,  272,  272,  272,   71,  272,  272,  272,  279,
 /*  2580 */   349,  350,  280,  272,  288,  272,  289,  291,  133,  293,
 /*  2590 */   272,  351,  272,  272,  272,  272,   66,  272,  272,  272,
 /*  2600 */   272,  349,  350,  279,  272,  272,  280,  272,  288,  272,
 /*  2610 */   289,  291,  133,  293,  272,  351,  272,  272,  272,  272,
 /*  2620 */    72,  272,  272,  272,  272,  349,  350,  279,  272,  272,
 /*  2630 */   280,  272,  288,  272,  289,  291,  133,  293,  272,  351,
 /*  2640 */   272,  272,  272,  272,   73,  272,  272,  272,  272,  349,
 /*  2650 */   350,
};
static const YYCODETYPE yy_lookahead[] = {
 /*     0 */     0,    1,    2,    3,    4,    5,    6,    7,    8,    9,
 /*    10 */    10,   11,   12,   13,   14,   15,   16,   17,   18,   19,
 /*    20 */    20,   21,   22,   23,   24,   96,   26,   27,   28,   29,
 /*    30 */    30,   31,   32,   33,   34,   35,   36,  101,   75,    0,
 /*    40 */    40,   41,   42,   43,  102,  102,  102,  102,   48,   49,
 /*    50 */    50,   51,   52,   50,   51,   52,  102,  102,   58,  102,
 /*    60 */   102,   58,   60,  102,  102,   61,   66,   66,  102,   66,
 /*    70 */     3,    4,    5,    6,    7,    8,    9,   10,   11,   12,
 /*    80 */    13,   14,   15,   16,   17,   18,   19,   20,   21,   22,
 /*    90 */    23,   24,   70,   26,   27,   28,   29,   30,   31,   32,
 /*   100 */    33,   34,   35,   36,   53,   51,   52,   40,   41,   42,
 /*   110 */    43,  102,   58,   70,   71,   48,   49,   50,   51,   52,
 /*   120 */    66,  102,   71,  102,  102,   58,   59,  102,  102,  102,
 /*   130 */   102,  102,  102,   66,  102,  102,  102,    3,    4,    5,
 /*   140 */     6,    7,    8,    9,   10,   11,   12,   13,   14,   15,
 /*   150 */    16,   17,   18,   19,   20,   21,   22,   23,   24,   25,
 /*   160 */    26,   27,   28,   29,   30,   31,   32,   33,   34,   35,
 /*   170 */    36,   53,   53,   53,   40,   41,   42,   43,  102,  102,
 /*   180 */   102,  102,   48,   49,   50,   51,   52,   68,  102,   71,
 /*   190 */   102,  102,   58,   73,  102,  102,  102,  102,  102,  102,
 /*   200 */    66,  102,  102,  102,    3,    4,    5,    6,    7,    8,
 /*   210 */     9,   10,   11,   12,   13,   14,   15,   16,   17,   18,
 /*   220 */    19,   20,   21,   22,   23,   24,  102,   26,   27,   28,
 /*   230 */    29,   30,   31,   32,   33,   34,   35,   36,  102,  102,
 /*   240 */   102,   40,   41,   42,   43,  102,  102,  102,  102,   48,
 /*   250 */    49,   50,   51,   52,  102,  102,  102,  102,  102,   58,
 /*   260 */   102,  102,  102,  102,  102,  102,  102,   66,  102,  102,
 /*   270 */   102,  102,   71,  102,  102,  102,    3,    4,    5,    6,
 /*   280 */     7,    8,    9,   10,   11,   12,   13,   14,   15,   16,
 /*   290 */    17,   18,   19,   20,   21,   22,   23,   24,  102,   26,
 /*   300 */    27,   28,   29,   30,   31,   32,   33,   34,   35,   36,
 /*   310 */   102,  102,  102,   40,   41,   42,   43,  102,  102,  102,
 /*   320 */   102,   48,   49,   50,   51,   52,  102,  102,  102,  102,
 /*   330 */    57,   58,  102,  102,  102,  102,  102,  102,  102,   66,
 /*   340 */   102,  102,  102,    3,    4,    5,    6,    7,    8,    9,
 /*   350 */    10,   11,   12,   13,   14,   15,   16,   17,   18,   19,
 /*   360 */    20,   21,   22,   23,   24,  102,   26,   27,   28,   29,
 /*   370 */    30,   31,   32,   33,   34,   35,   36,  102,  102,  102,
 /*   380 */    40,   41,   42,   43,  102,  102,  102,  102,   48,   49,
 /*   390 */    50,   51,   52,  102,  102,  102,   56,  102,   58,  102,
 /*   400 */   102,  102,  102,  102,  102,  102,   66,  102,  102,  102,
 /*   410 */     3,    4,    5,    6,    7,    8,    9,   10,   11,   12,
 /*   420 */    13,   14,   15,   16,   17,   18,   19,   20,   21,   22,
 /*   430 */    23,   24,  102,   26,   27,   28,   29,   30,   31,   32,
 /*   440 */    33,   34,   35,   36,  102,  102,  102,   40,   41,   42,
 /*   450 */    43,  102,  102,  102,  102,   48,   49,   50,   51,   52,
 /*   460 */   102,  102,  102,  102,  102,   58,  102,  102,  102,  102,
 /*   470 */   102,  102,  102,   66,  102,   68,  102,    3,    4,    5,
 /*   480 */     6,    7,    8,    9,   10,   11,   12,   13,   14,   15,
 /*   490 */    16,   17,   18,   19,   20,   21,   22,   23,   24,  102,
 /*   500 */    26,   27,   28,   29,   30,   31,   32,   33,   34,   35,
 /*   510 */    36,  102,  102,  102,   40,   41,   42,   43,  102,  102,
 /*   520 */   102,  102,   48,   49,   50,   51,   52,  102,  102,  102,
 /*   530 */   102,  102,   58,  102,  102,  102,  102,  102,  102,  102,
 /*   540 */    66,   67,  102,  102,    3,    4,    5,    6,    7,    8,
 /*   550 */     9,   10,   11,   12,   13,   14,   15,   16,   17,   18,
 /*   560 */    19,   20,   21,   22,   23,   24,  102,   26,   27,   28,
 /*   570 */    29,   30,   31,   32,   33,   34,   35,   36,  102,  102,
 /*   580 */   102,   40,   41,   42,   43,  102,  102,  102,  102,   48,
 /*   590 */    49,   50,   51,   52,  102,  102,  102,  102,  102,   58,
 /*   600 */   102,  102,  102,  102,  102,  102,  102,   66,  102,  102,
 /*   610 */   102,  102,  102,  102,  102,    7,    8,    9,   10,   11,
 /*   620 */    12,   13,   14,   15,   16,   17,   18,   19,   20,   21,
 /*   630 */    22,   23,   24,  102,   26,   27,   28,   29,   30,   31,
 /*   640 */    32,   33,   34,   35,   36,  102,  102,  102,   40,   41,
 /*   650 */    42,   43,  102,  102,  102,  102,   48,   49,   50,   51,
 /*   660 */    52,  102,  102,  102,  102,  102,   58,  102,  102,  102,
 /*   670 */   102,  102,  102,  102,   66,  102,    9,   10,   11,   12,
 /*   680 */    13,   14,   15,   16,   17,   18,   19,   20,   21,   22,
 /*   690 */    23,   24,  102,   26,   27,   28,   29,   30,   31,   32,
 /*   700 */    33,   34,   35,   36,  102,  102,  102,   40,   41,   42,
 /*   710 */    43,  102,  102,  102,  102,   48,   49,   50,   51,   52,
 /*   720 */   102,  102,  102,  102,  102,   58,  102,  102,  102,  102,
 /*   730 */   102,  102,  102,   66,  102,  102,  102,   11,   12,   13,
 /*   740 */    14,   15,   16,   17,   18,   19,   20,   21,   22,   23,
 /*   750 */    24,  102,   26,   27,   28,   29,   30,   31,   32,   33,
 /*   760 */    34,   35,   36,  102,  102,  102,   40,   41,   42,   43,
 /*   770 */   102,  102,  102,  102,   48,   49,   50,   51,   52,  102,
 /*   780 */   102,  102,  102,  102,   58,  102,  102,  102,  102,  102,
 /*   790 */   102,  102,   66,  102,  102,  102,  102,  102,   13,   14,
 /*   800 */    15,   16,   17,   18,   19,   20,   21,   22,   23,   24,
 /*   810 */   102,   26,   27,   28,   29,   30,   31,   32,   33,   34,
 /*   820 */    35,   36,  102,  102,  102,   40,   41,   42,   43,  102,
 /*   830 */   102,  102,  102,   48,   49,   50,   51,   52,  102,  102,
 /*   840 */   102,  102,  102,   58,  102,  102,  102,  102,  102,  102,
 /*   850 */   102,   66,  102,  102,  102,  102,  102,   13,   14,   15,
 /*   860 */    16,   17,   18,   19,   20,   21,   22,   23,   24,  102,
 /*   870 */    26,   27,   28,   29,   30,   31,   32,   33,   34,   35,
 /*   880 */    36,  102,  102,  102,   40,   41,   42,   43,  102,  102,
 /*   890 */   102,  102,   48,   49,   50,   51,   52,  102,  102,  102,
 /*   900 */    25,  102,   58,   28,  102,  102,  102,  102,  102,  102,
 /*   910 */    66,  102,   37,   38,   39,   40,   41,   42,   43,  102,
 /*   920 */   102,  102,  102,  102,  102,  102,  102,  102,  102,  102,
 /*   930 */    55,  102,  102,  102,  102,   60,  102,   62,   63,   64,
 /*   940 */    65,   66,  102,   25,   69,   70,   28,   72,  102,  102,
 /*   950 */   102,  102,   34,  102,  102,   37,   38,   39,   40,   41,
 /*   960 */    42,   43,  102,  102,  102,  102,  102,  102,  102,  102,
 /*   970 */   102,  102,  102,   55,  102,  102,  102,  102,   60,  102,
 /*   980 */    62,  102,  102,   65,   66,  102,  102,   69,   70,  102,
 /*   990 */    72,   30,   31,   32,   33,   34,   35,   36,  102,  102,
 /*  1000 */   102,   40,   41,   42,   43,  102,  102,  102,  102,   48,
 /*  1010 */    49,   50,   51,   52,  102,  102,  102,   25,  102,   58,
 /*  1020 */    28,  102,  102,  102,  102,  102,  102,   66,  102,   37,
 /*  1030 */    38,   39,   40,   41,   42,   43,  102,  102,  102,  102,
 /*  1040 */   102,  102,  102,  102,  102,  102,  102,   55,  102,  102,
 /*  1050 */   102,  102,   60,   25,   62,  102,   28,   65,   66,  102,
 /*  1060 */   102,   69,   70,  102,   72,   37,   38,   39,   40,   41,
 /*  1070 */    42,   43,  102,  102,  102,  102,  102,  102,  102,  102,
 /*  1080 */   102,  102,  102,   55,  102,  102,  102,  102,   60,  102,
 /*  1090 */    62,  102,  102,   65,   66,  102,   75,   69,   70,   78,
 /*  1100 */    72,   80,  102,   82,   83,   84,   85,  102,   87,   88,
 /*  1110 */    89,  102,  102,   92,  102,  102,  102,  102,   97,   98,
 /*  1120 */   102,  100,  101,   75,  102,  102,   78,  102,   80,  102,
 /*  1130 */    82,   83,   84,   85,  102,   87,  102,  102,  102,  102,
 /*  1140 */    92,   93,   94,   95,  102,   97,   98,   75,  102,   77,
 /*  1150 */    78,  102,   80,  102,   82,   83,   84,   85,   86,   87,
 /*  1160 */   102,  102,  102,  102,   92,  102,  102,  102,  102,   97,
 /*  1170 */    98,   99,   75,  102,   77,   78,  102,   80,  102,   82,
 /*  1180 */    83,   84,   85,   86,   87,  102,  102,  102,  102,   92,
 /*  1190 */   102,  102,  102,  102,   97,   98,   99,   75,  102,   77,
 /*  1200 */    78,  102,   80,  102,   82,   83,   84,   85,   86,   87,
 /*  1210 */   102,  102,  102,  102,   92,  102,  102,  102,  102,   97,
 /*  1220 */    98,   99,   75,  102,  102,   78,  102,   80,  102,   82,
 /*  1230 */    83,   84,   85,  102,   87,  102,  102,   90,   91,   92,
 /*  1240 */   102,  102,  102,  102,   97,   98,   75,  102,   77,   78,
 /*  1250 */   102,   80,  102,   82,   83,   84,   85,  102,   87,  102,
 /*  1260 */   102,  102,  102,   92,  102,  102,  102,  102,   97,   98,
 /*  1270 */    99,   75,  102,  102,   78,  102,   80,  102,   82,   83,
 /*  1280 */    84,   85,  102,   87,  102,   89,  102,  102,   92,  102,
 /*  1290 */   102,  102,  102,   97,   98,   75,  100,  102,   78,  102,
 /*  1300 */    80,  102,   82,   83,   84,   85,  102,   87,   88,  102,
 /*  1310 */   102,  102,   92,  102,  102,  102,  102,   97,   98,   35,
 /*  1320 */    36,  101,  102,  102,   40,   41,   42,   43,  102,  102,
 /*  1330 */   102,  102,   48,   49,   50,   51,   52,  102,  102,  102,
 /*  1340 */   102,  102,   58,  102,   75,  102,  102,   78,  102,   80,
 /*  1350 */    66,   82,   83,   84,   85,  102,   87,  102,  102,  102,
 /*  1360 */   102,   92,  102,  102,  102,  102,   97,   98,  102,  100,
 /*  1370 */    75,  102,  102,   78,  102,   80,  102,   82,   83,   84,
 /*  1380 */    85,  102,   87,  102,  102,  102,  102,   92,  102,  102,
 /*  1390 */   102,  102,   97,   98,   75,  102,  102,   78,  102,   80,
 /*  1400 */   102,   82,   83,   84,   85,  102,   87,  102,  102,  102,
 /*  1410 */   102,   92,  102,  102,  102,  102,   97,   98,   75,  102,
 /*  1420 */   102,   78,  102,   80,  102,   82,   83,   84,   85,  102,
 /*  1430 */    87,  102,  102,  102,  102,   92,  102,  102,  102,  102,
 /*  1440 */    97,   98,   75,  102,  102,   78,  102,   80,  102,   82,
 /*  1450 */    83,   84,   85,  102,   87,  102,  102,  102,  102,   92,
 /*  1460 */   102,  102,  102,   75,   97,   98,   78,  102,   80,  102,
 /*  1470 */    82,   83,   84,   85,  102,   87,  102,  102,  102,  102,
 /*  1480 */    92,  102,  102,  102,  102,   97,   98,   75,  102,  102,
 /*  1490 */    78,  102,   80,  102,   82,   83,   84,   85,  102,   87,
 /*  1500 */   102,  102,  102,  102,   92,  102,  102,  102,  102,   97,
 /*  1510 */    98,   75,  102,  102,   78,  102,   80,  102,   82,   83,
 /*  1520 */    84,   85,  102,   87,  102,  102,  102,  102,   92,  102,
 /*  1530 */   102,  102,  102,   97,   98,   75,  102,  102,   78,  102,
 /*  1540 */    80,  102,   82,   83,   84,   85,  102,   87,  102,  102,
 /*  1550 */   102,  102,   92,  102,  102,  102,   75,   97,   98,   78,
 /*  1560 */   102,   80,  102,   82,   83,   84,   85,  102,   87,  102,
 /*  1570 */   102,  102,  102,   92,  102,  102,  102,  102,   97,   98,
 /*  1580 */    75,  102,  102,   78,  102,   80,  102,   82,   83,   84,
 /*  1590 */    85,  102,   87,  102,  102,  102,  102,   92,  102,  102,
 /*  1600 */   102,  102,   97,   98,   75,  102,  102,   78,  102,   80,
 /*  1610 */   102,   82,   83,   84,   85,  102,   87,  102,  102,  102,
 /*  1620 */   102,   92,  102,  102,  102,  102,   97,   98,   75,  102,
 /*  1630 */   102,   78,  102,   80,  102,   82,   83,   84,   85,  102,
 /*  1640 */    87,  102,  102,  102,  102,   92,  102,  102,  102,   75,
 /*  1650 */    97,   98,   78,  102,   80,  102,   82,   83,   84,   85,
 /*  1660 */   102,   87,  102,  102,  102,  102,   92,  102,  102,  102,
 /*  1670 */   102,   97,   98,   75,  102,  102,   78,  102,   80,  102,
 /*  1680 */    82,   83,   84,   85,  102,   87,  102,  102,  102,  102,
 /*  1690 */    92,  102,  102,  102,  102,   97,   98,   75,  102,  102,
 /*  1700 */    78,  102,   80,  102,   82,   83,   84,   85,  102,   87,
 /*  1710 */   102,  102,  102,  102,   92,  102,  102,  102,  102,   97,
 /*  1720 */    98,   75,  102,  102,   78,  102,   80,  102,   82,   83,
 /*  1730 */    84,   85,  102,   87,  102,  102,  102,  102,   92,  102,
 /*  1740 */   102,  102,   75,   97,   98,   78,  102,   80,  102,   82,
 /*  1750 */    83,   84,   85,  102,   87,  102,  102,  102,  102,   92,
 /*  1760 */   102,  102,  102,  102,   97,   98,   75,  102,  102,   78,
 /*  1770 */   102,   80,  102,   82,   83,   84,   85,  102,   87,  102,
 /*  1780 */   102,  102,  102,   92,  102,  102,  102,  102,   97,   98,
 /*  1790 */    75,  102,  102,   78,  102,   80,  102,   82,   83,   84,
 /*  1800 */    85,  102,   87,  102,  102,  102,  102,   92,  102,  102,
 /*  1810 */   102,  102,   97,   98,   75,  102,  102,   78,  102,   80,
 /*  1820 */   102,   82,   83,   84,   85,  102,   87,  102,  102,  102,
 /*  1830 */   102,   92,  102,  102,  102,   75,   97,   98,   78,  102,
 /*  1840 */    80,  102,   82,   83,   84,   85,  102,   87,  102,  102,
 /*  1850 */   102,  102,   92,  102,  102,  102,  102,   97,   98,   75,
 /*  1860 */   102,  102,   78,  102,   80,  102,   82,   83,   84,   85,
 /*  1870 */   102,   87,  102,  102,  102,  102,   92,  102,  102,  102,
 /*  1880 */   102,   97,   98,   75,  102,  102,   78,  102,   80,  102,
 /*  1890 */    82,   83,   84,   85,  102,   87,  102,  102,  102,  102,
 /*  1900 */    92,  102,  102,  102,  102,   97,   98,   75,  102,  102,
 /*  1910 */    78,  102,   80,  102,   82,   83,   84,   85,  102,   87,
 /*  1920 */   102,  102,  102,  102,   92,  102,  102,  102,   75,   97,
 /*  1930 */    98,   78,  102,   80,  102,   82,   83,   84,   85,  102,
 /*  1940 */    87,  102,  102,  102,  102,   92,  102,  102,  102,  102,
 /*  1950 */    97,   98,   75,  102,  102,   78,  102,   80,  102,   82,
 /*  1960 */    83,   84,   85,  102,   87,  102,  102,  102,  102,   92,
 /*  1970 */   102,  102,  102,  102,   97,   98,   75,  102,  102,   78,
 /*  1980 */   102,   80,  102,   82,   83,   84,   85,  102,   87,  102,
 /*  1990 */   102,  102,  102,   92,  102,  102,  102,  102,   97,   98,
 /*  2000 */    75,  102,  102,   78,  102,   80,  102,   82,   83,   84,
 /*  2010 */    85,  102,   87,  102,  102,  102,  102,   92,  102,  102,
 /*  2020 */   102,   75,   97,   98,   78,  102,   80,  102,   82,   83,
 /*  2030 */    84,   85,  102,   87,  102,  102,  102,  102,   92,  102,
 /*  2040 */   102,  102,  102,   97,   98,   75,  102,  102,   78,  102,
 /*  2050 */    80,  102,   82,   83,   84,   85,  102,   87,  102,  102,
 /*  2060 */   102,  102,   92,  102,  102,  102,  102,   97,   98,   75,
 /*  2070 */   102,  102,   78,  102,   80,  102,   82,   83,   84,   85,
 /*  2080 */   102,   87,  102,  102,  102,  102,   92,  102,  102,  102,
 /*  2090 */   102,   97,   98,   75,  102,  102,   78,  102,   80,  102,
 /*  2100 */    82,   83,   84,   85,  102,   87,  102,  102,  102,  102,
 /*  2110 */    92,  102,  102,  102,   75,   97,   98,   78,  102,   80,
 /*  2120 */   102,   82,   83,   84,   85,  102,   87,  102,  102,  102,
 /*  2130 */   102,   92,  102,  102,  102,  102,   97,   98,   75,  102,
 /*  2140 */   102,   78,  102,   80,  102,   82,   83,   84,   85,  102,
 /*  2150 */    87,  102,  102,  102,  102,   92,  102,  102,  102,  102,
 /*  2160 */    97,   98,   75,  102,  102,   78,  102,   80,  102,   82,
 /*  2170 */    83,   84,   85,  102,   87,  102,  102,  102,  102,   92,
 /*  2180 */   102,  102,  102,  102,   97,   98,   75,  102,  102,   78,
 /*  2190 */   102,   80,  102,   82,   83,   84,   85,  102,   87,  102,
 /*  2200 */   102,  102,  102,   92,  102,  102,  102,   75,   97,   98,
 /*  2210 */    78,  102,   80,  102,   82,   83,   84,   85,  102,   87,
 /*  2220 */   102,  102,  102,  102,   92,  102,  102,  102,  102,   97,
 /*  2230 */    98,   75,  102,  102,   78,  102,   80,  102,   82,   83,
 /*  2240 */    84,   85,  102,   87,  102,  102,  102,  102,   92,  102,
 /*  2250 */   102,  102,  102,   97,   98,   75,  102,  102,   78,  102,
 /*  2260 */    80,  102,   82,   83,   84,   85,  102,   87,  102,  102,
 /*  2270 */   102,  102,   92,  102,  102,  102,  102,   97,   98,   75,
 /*  2280 */   102,  102,   78,  102,   80,  102,   82,   83,   84,   85,
 /*  2290 */   102,   87,  102,  102,  102,  102,   92,  102,  102,  102,
 /*  2300 */    75,   97,   98,   78,  102,   80,  102,   82,   83,   84,
 /*  2310 */    85,  102,   87,  102,  102,  102,  102,   92,  102,  102,
 /*  2320 */   102,  102,   97,   98,   75,  102,  102,   78,  102,   80,
 /*  2330 */   102,   82,   83,   84,   85,  102,   87,  102,  102,  102,
 /*  2340 */   102,   92,  102,  102,  102,  102,   97,   98,   75,  102,
 /*  2350 */   102,   78,  102,   80,  102,   82,   83,   84,   85,  102,
 /*  2360 */    87,  102,  102,  102,  102,   92,  102,  102,  102,  102,
 /*  2370 */    97,   98,   75,  102,  102,   78,  102,   80,  102,   82,
 /*  2380 */    83,   84,   85,  102,   87,  102,  102,  102,  102,   92,
 /*  2390 */   102,  102,  102,   75,   97,   98,   78,  102,   80,  102,
 /*  2400 */    82,   83,   84,   85,  102,   87,  102,  102,  102,  102,
 /*  2410 */    92,  102,  102,  102,  102,   97,   98,   75,  102,  102,
 /*  2420 */    78,  102,   80,  102,   82,   83,   84,   85,  102,   87,
 /*  2430 */   102,  102,  102,  102,   92,  102,  102,  102,  102,   97,
 /*  2440 */    98,   75,  102,  102,   78,  102,   80,  102,   82,   83,
 /*  2450 */    84,   85,  102,   87,  102,  102,  102,  102,   92,  102,
 /*  2460 */   102,  102,  102,   97,   98,   75,  102,  102,   78,  102,
 /*  2470 */    80,  102,   82,   83,   84,   85,  102,   87,  102,  102,
 /*  2480 */   102,  102,   92,  102,  102,  102,   75,   97,   98,   78,
 /*  2490 */   102,   80,  102,   82,   83,   84,   85,  102,   87,  102,
 /*  2500 */   102,  102,  102,   92,  102,  102,  102,  102,   97,   98,
 /*  2510 */    75,  102,  102,   78,  102,   80,  102,   82,   83,   84,
 /*  2520 */    85,  102,   87,  102,  102,  102,  102,   92,  102,  102,
 /*  2530 */   102,  102,   97,   98,   75,  102,  102,   78,  102,   80,
 /*  2540 */   102,   82,   83,   84,   85,  102,   87,  102,  102,  102,
 /*  2550 */   102,   92,  102,  102,  102,  102,   97,   98,   75,  102,
 /*  2560 */   102,   78,  102,   80,  102,   82,   83,   84,   85,  102,
 /*  2570 */    87,  102,  102,  102,  102,   92,  102,  102,  102,   75,
 /*  2580 */    97,   98,   78,  102,   80,  102,   82,   83,   84,   85,
 /*  2590 */   102,   87,  102,  102,  102,  102,   92,  102,  102,  102,
 /*  2600 */   102,   97,   98,   75,  102,  102,   78,  102,   80,  102,
 /*  2610 */    82,   83,   84,   85,  102,   87,  102,  102,  102,  102,
 /*  2620 */    92,  102,  102,  102,  102,   97,   98,   75,  102,  102,
 /*  2630 */    78,  102,   80,  102,   82,   83,   84,   85,  102,   87,
 /*  2640 */   102,  102,  102,  102,   92,  102,  102,  102,  102,   97,
 /*  2650 */    98,   74,   74,   74,   74,   74,   74,   74,   74,   74,
 /*  2660 */    74,   74,   74,   74,   74,   74,   74,   74,   74,   74,
 /*  2670 */    74,   74,   74,   74,   74,   74,   74,   74,   74,   74,
 /*  2680 */    74,   74,   74,   74,   74,   74,   74,   74,   74,   74,
 /*  2690 */    74,   74,   74,   74,   74,   74,   74,   74,   74,   74,
 /*  2700 */    74,   74,   74,   74,   74,   74,   74,   74,   74,   74,
 /*  2710 */    74,   74,   74,   74,   74,   74,   74,   74,   74,   74,
 /*  2720 */    74,   74,   74,   74,   74,
};
#define YY_SHIFT_COUNT    (134)
#define YY_SHIFT_MIN      (0)
#define YY_SHIFT_MAX      (1284)
static const unsigned short int yy_shift_ofst[] = {
 /*     0 */   992, 1028,  875,  918,  918,  918,  918,  992, 1028,  992,
 /*    10 */   992,  992,  992,  992,  992,  992,  992,  992,  992,  992,
 /*    20 */   992,  992,  992,  992,  992,  992,  992,  992,  992,  992,
 /*    30 */   992,  992,  992,  992,  992,  992,  992,  992,  992,  992,
 /*    40 */   992,  992,  992,  992,  992,  992,  992,  992,  992,  992,
 /*    50 */   992,  992,  992,  992,  992,  992,  992,  992,  992,  992,
 /*    60 */   992,  992,  992,  992,  992,    0,   67,  134,  201,  201,
 /*    70 */   273,  340,  407,  474,  541,  541,  541,  541,  608,  608,
 /*    80 */   608,  608,  667,  667,  726,  726,  785,  785,  844,  844,
 /*    90 */   844,  844,  844,  844,  844,  844,  844,  844,  844,  844,
 /*   100 */   961,  961,  961,  961,  961, 1284, 1284, 1284, 1284, 1284,
 /*   110 */  1284, 1284, 1284, 1284,    3,    3,    3,    3,    3,    3,
 /*   120 */     3,    3,    3,   54,   43,    1,    1,    2,  119,   51,
 /*   130 */   118,  120,   39,   22,    4,
};
#define YY_REDUCE_COUNT (127)
#define YY_REDUCE_MIN   (-71)
#define YY_REDUCE_MAX   (2552)
static const short yy_reduce_ofst[] = {
 /*     0 */  1147, 1021, 1048, 1072, 1097, 1122, 1171, 1196, 1220, 1269,
 /*    10 */  1295, 1319, 1343, 1367, 1388, 1412, 1436, 1460, 1481, 1505,
 /*    20 */  1529, 1553, 1574, 1598, 1622, 1646, 1667, 1691, 1715, 1739,
 /*    30 */  1760, 1784, 1808, 1832, 1853, 1877, 1901, 1925, 1946, 1970,
 /*    40 */  1994, 2018, 2039, 2063, 2087, 2111, 2132, 2156, 2180, 2204,
 /*    50 */  2225, 2249, 2273, 2297, 2318, 2342, 2366, 2390, 2411, 2435,
 /*    60 */  2459, 2483, 2504, 2528, 2552,  -71,  -71,  -71,  -71,  -71,
 /*    70 */   -71,  -71,  -71,  -71,  -71,  -71,  -71,  -71,  -71,  -71,
 /*    80 */   -71,  -71,  -71,  -71,  -71,  -71,  -71,  -71,  -71,  -71,
 /*    90 */   -71,  -71,  -71,  -71,  -71,  -71,  -71,  -71,  -71,  -71,
 /*   100 */   -71,  -71,  -71,  -71,  -71,  -71,  -71,  -71,  -71,  -71,
 /*   110 */   -71,  -71,  -71,  -71,  -71,  -71,  -71,  -71,  -71,  -71,
 /*   120 */   -71,  -71,  -71,  -71,  -64,  -71,  -71,  -37,
};
static const YYACTIONTYPE yy_default[] = {
 /*     0 */   270,  270,  270,  270,  270,  270,  270,  270,  270,  270,
 /*    10 */   270,  270,  270,  270,  270,  270,  270,  270,  270,  270,
 /*    20 */   270,  270,  270,  270,  270,  270,  270,  270,  270,  270,
 /*    30 */   270,  270,  270,  270,  270,  270,  270,  270,  270,  270,
 /*    40 */   270,  270,  270,  270,  270,  270,  270,  270,  270,  270,
 /*    50 */   270,  270,  270,  270,  270,  270,  270,  270,  270,  270,
 /*    60 */   270,  270,  270,  270,  270,  270,  270,  270,  358,  270,
 /*    70 */   270,  270,  270,  270,  367,  366,  358,  353,  342,  341,
 /*    80 */   340,  339,  346,  345,  348,  347,  344,  343,  338,  337,
 /*    90 */   336,  335,  334,  333,  332,  331,  330,  329,  328,  327,
 /*   100 */   298,  312,  311,  310,  309,  326,  325,  319,  318,  317,
 /*   110 */   316,  315,  314,  313,  302,  301,  300,  299,  297,  306,
 /*   120 */   305,  304,  303,  308,  270,  295,  294,  270,  270,  270,
 /*   130 */   270,  270,  270,  290,  279,
};
/********** End of lemon-generated parsing tables *****************************/

/* The next table maps tokens (terminal symbols) into fallback tokens.  
** If a construct like the following:
** 
**      %fallback ID X Y Z.
**
** appears in the grammar, then ID becomes a fallback token for X, Y,
** and Z.  Whenever one of the tokens X, Y, or Z is input to the parser
** but it does not parse, the type of the token is changed to ID and
** the parse is retried before an error is thrown.
**
** This feature can be used, for example, to cause some keywords in a language
** to revert to identifiers if they keyword does not apply in the context where
** it appears.
*/
#ifdef YYFALLBACK
static const YYCODETYPE yyFallback[] = {
};
#endif /* YYFALLBACK */

/* The following structure represents a single element of the
** parser's stack.  Information stored includes:
**
**   +  The state number for the parser at this level of the stack.
**
**   +  The value of the token stored at this level of the stack.
**      (In other words, the "major" token.)
**
**   +  The semantic value stored at this level of the stack.  This is
**      the information used by the action routines in the grammar.
**      It is sometimes called the "minor" token.
**
** After the "shift" half of a SHIFTREDUCE action, the stateno field
** actually contains the reduce action for the second half of the
** SHIFTREDUCE.
*/
struct yyStackEntry {
  YYACTIONTYPE stateno;  /* The state-number, or reduce action in SHIFTREDUCE */
  YYCODETYPE major;      /* The major token value.  This is the code
                         ** number for the token at this stack level */
  YYMINORTYPE minor;     /* The user-supplied minor token value.  This
                         ** is the value of the token  */
};
typedef struct yyStackEntry yyStackEntry;

/* The state of the parser is completely contained in an instance of
** the following structure */
struct yyParser {
  yyStackEntry *yytos;          /* Pointer to top element of the stack */
#ifdef YYTRACKMAXSTACKDEPTH
  int yyhwm;                    /* High-water mark of the stack */
#endif
#ifndef YYNOERRORRECOVERY
  int yyerrcnt;                 /* Shifts left before out of the error */
#endif
  ParseARG_SDECL                /* A place to hold %extra_argument */
  ParseCTX_SDECL                /* A place to hold %extra_context */
#if YYSTACKDEPTH<=0
  int yystksz;                  /* Current side of the stack */
  yyStackEntry *yystack;        /* The parser's stack */
  yyStackEntry yystk0;          /* First stack entry */
#else
  yyStackEntry yystack[YYSTACKDEPTH];  /* The parser's stack */
  yyStackEntry *yystackEnd;            /* Last entry in the stack */
#endif
};
typedef struct yyParser yyParser;

#ifndef NDEBUG
#include <stdio.h>
static FILE *yyTraceFILE = 0;
static char *yyTracePrompt = 0;
#endif /* NDEBUG */

#ifndef NDEBUG
/* 
** Turn parser tracing on by giving a stream to which to write the trace
** and a prompt to preface each trace message.  Tracing is turned off
** by making either argument NULL 
**
** Inputs:
** <ul>
** <li> A FILE* to which trace output should be written.
**      If NULL, then tracing is turned off.
** <li> A prefix string written at the beginning of every
**      line of trace output.  If NULL, then tracing is
**      turned off.
** </ul>
**
** Outputs:
** None.
*/
void ParseTrace(FILE *TraceFILE, char *zTracePrompt){
  yyTraceFILE = TraceFILE;
  yyTracePrompt = zTracePrompt;
  if( yyTraceFILE==0 ) yyTracePrompt = 0;
  else if( yyTracePrompt==0 ) yyTraceFILE = 0;
}
#endif /* NDEBUG */

#if defined(YYCOVERAGE) || !defined(NDEBUG)
/* For tracing shifts, the names of all terminals and nonterminals
** are required.  The following table supplies these names */
static const char *const yyTokenName[] = { 
  /*    0 */ "$",
  /*    1 */ "OPERATOR_ASSIGN",
  /*    2 */ "OPERATOR_ASSIGN_DYNAMIC",
  /*    3 */ "OPERATOR_SHL",
  /*    4 */ "OPERATOR_SHL2",
  /*    5 */ "OPERATOR_SHR",
  /*    6 */ "OPERATOR_SHR2",
  /*    7 */ "OPERATOR_OR",
  /*    8 */ "OPERATOR_OR2",
  /*    9 */ "OPERATOR_XOR",
  /*   10 */ "OPERATOR_XOR2",
  /*   11 */ "OPERATOR_AND",
  /*   12 */ "OPERATOR_AND2",
  /*   13 */ "OPERATOR_LEQ",
  /*   14 */ "OPERATOR_LEQ2",
  /*   15 */ "OPERATOR_GEQ",
  /*   16 */ "OPERATOR_GEQ2",
  /*   17 */ "OPERATOR_LOW",
  /*   18 */ "OPERATOR_LOW2",
  /*   19 */ "OPERATOR_GRE",
  /*   20 */ "OPERATOR_GRE2",
  /*   21 */ "OPERATOR_EQU",
  /*   22 */ "OPERATOR_EQU2",
  /*   23 */ "OPERATOR_NEQ",
  /*   24 */ "OPERATOR_NEQ2",
  /*   25 */ "OPERATOR_ABS",
  /*   26 */ "OPERATOR_PLUS",
  /*   27 */ "OPERATOR_PLUS2",
  /*   28 */ "OPERATOR_MINUS",
  /*   29 */ "OPERATOR_MINUS2",
  /*   30 */ "OPERATOR_DIVIDE",
  /*   31 */ "OPERATOR_DIVIDE2",
  /*   32 */ "OPERATOR_TIMES",
  /*   33 */ "OPERATOR_TIMES2",
  /*   34 */ "INDEX_RANGE_JOKER",
  /*   35 */ "OPERATOR_POW",
  /*   36 */ "OPERATOR_POW2",
  /*   37 */ "OPERATOR_NOT",
  /*   38 */ "OPERATOR_NOT2",
  /*   39 */ "OPERATOR_MINUS_UNARY",
  /*   40 */ "OPERATOR_SQRT",
  /*   41 */ "OPERATOR_SQRT2",
  /*   42 */ "OPERATOR_CBRT",
  /*   43 */ "OPERATOR_CBRT2",
  /*   44 */ "OPERATOR_MUL_SQRT",
  /*   45 */ "OPERATOR_MUL_SQRT2",
  /*   46 */ "OPERATOR_MUL_CBRT",
  /*   47 */ "OPERATOR_MUL_CBRT2",
  /*   48 */ "OPERATOR_FACTORIAL",
  /*   49 */ "OPERATOR_FACTORIAL2",
  /*   50 */ "OPERATOR_UNCERTAINTY",
  /*   51 */ "OPERATOR_DEGREE",
  /*   52 */ "OPERATOR_DEGREE2",
  /*   53 */ "ENUMERATION_SEPARATOR",
  /*   54 */ "OPERATOR_SUBSCRIPT",
  /*   55 */ "IF",
  /*   56 */ "THEN",
  /*   57 */ "ELSE",
  /*   58 */ "QUESTION",
  /*   59 */ "ALTERNATE",
  /*   60 */ "INTEGER_POSITIVE",
  /*   61 */ "INDEX_RANGE_OPERATOR",
  /*   62 */ "REAL_POSITIVE",
  /*   63 */ "INTEGER_PER_FRACTION",
  /*   64 */ "REAL_PER_FRACTION",
  /*   65 */ "STRING_QUOTED",
  /*   66 */ "INTERVAL_LEFT_DELIMITER",
  /*   67 */ "INTERVAL_ITEM_SEPARATOR",
  /*   68 */ "INTERVAL_RIGHT_DELIMITER",
  /*   69 */ "IDENTIFIER",
  /*   70 */ "PARENTHESIS_LEFT",
  /*   71 */ "PARENTHESIS_RIGHT",
  /*   72 */ "LIST_LEFT_DELIMITER",
  /*   73 */ "LIST_RIGHT_DELIMITER",
  /*   74 */ "context",
  /*   75 */ "integer",
  /*   76 */ "integer10_radical",
  /*   77 */ "index_range",
  /*   78 */ "real",
  /*   79 */ "real10_radical",
  /*   80 */ "number",
  /*   81 */ "number10_radical",
  /*   82 */ "string_quoted",
  /*   83 */ "interval",
  /*   84 */ "identifier",
  /*   85 */ "value",
  /*   86 */ "enumeration",
  /*   87 */ "list",
  /*   88 */ "matrix_rows",
  /*   89 */ "matrix_row_enumeration",
  /*   90 */ "assignation",
  /*   91 */ "command",
  /*   92 */ "expr",
  /*   93 */ "integer_per_fraction",
  /*   94 */ "real_per_fraction",
  /*   95 */ "number_per_fraction",
  /*   96 */ "subscript",
  /*   97 */ "function_call",
  /*   98 */ "matrix",
  /*   99 */ "enumeration_element",
  /*  100 */ "matrix_row_element",
  /*  101 */ "matrix_row",
};
#endif /* defined(YYCOVERAGE) || !defined(NDEBUG) */

#ifndef NDEBUG
/* For tracing reduce actions, the names of all rules are required.
*/
static const char *const yyRuleName[] = {
 /*   0 */ "command ::= expr",
 /*   1 */ "command ::= assignation",
 /*   2 */ "integer ::= INTEGER_POSITIVE",
 /*   3 */ "index_range ::= integer INDEX_RANGE_OPERATOR integer",
 /*   4 */ "index_range ::= INDEX_RANGE_JOKER",
 /*   5 */ "real ::= REAL_POSITIVE",
 /*   6 */ "number ::= integer",
 /*   7 */ "number ::= real",
 /*   8 */ "integer_per_fraction ::= INTEGER_PER_FRACTION",
 /*   9 */ "real_per_fraction ::= REAL_PER_FRACTION",
 /*  10 */ "number_per_fraction ::= integer_per_fraction",
 /*  11 */ "number_per_fraction ::= real_per_fraction",
 /*  12 */ "string_quoted ::= STRING_QUOTED",
 /*  13 */ "interval ::= INTERVAL_LEFT_DELIMITER expr INTERVAL_ITEM_SEPARATOR expr INTERVAL_RIGHT_DELIMITER",
 /*  14 */ "identifier ::= IDENTIFIER",
 /*  15 */ "value ::= number",
 /*  16 */ "value ::= string_quoted",
 /*  17 */ "value ::= identifier",
 /*  18 */ "value ::= interval",
 /*  19 */ "subscript ::= INTERVAL_LEFT_DELIMITER enumeration INTERVAL_RIGHT_DELIMITER",
 /*  20 */ "expr ::= value",
 /*  21 */ "expr ::= IF expr THEN expr ELSE expr",
 /*  22 */ "expr ::= expr QUESTION expr ALTERNATE expr",
 /*  23 */ "expr ::= PARENTHESIS_LEFT expr PARENTHESIS_RIGHT",
 /*  24 */ "expr ::= OPERATOR_MINUS_UNARY expr",
 /*  25 */ "expr ::= OPERATOR_MINUS expr",
 /*  26 */ "expr ::= OPERATOR_SQRT expr",
 /*  27 */ "expr ::= OPERATOR_SQRT2 expr",
 /*  28 */ "expr ::= OPERATOR_CBRT expr",
 /*  29 */ "expr ::= OPERATOR_CBRT2 expr",
 /*  30 */ "expr ::= expr OPERATOR_SQRT expr",
 /*  31 */ "expr ::= expr OPERATOR_SQRT2 expr",
 /*  32 */ "expr ::= expr OPERATOR_CBRT expr",
 /*  33 */ "expr ::= expr OPERATOR_CBRT2 expr",
 /*  34 */ "expr ::= expr OPERATOR_UNCERTAINTY number_per_fraction",
 /*  35 */ "expr ::= expr OPERATOR_UNCERTAINTY expr",
 /*  36 */ "expr ::= expr OPERATOR_PLUS expr",
 /*  37 */ "expr ::= expr OPERATOR_PLUS2 expr",
 /*  38 */ "expr ::= expr OPERATOR_MINUS expr",
 /*  39 */ "expr ::= expr OPERATOR_MINUS2 expr",
 /*  40 */ "expr ::= expr OPERATOR_TIMES expr",
 /*  41 */ "expr ::= expr INDEX_RANGE_JOKER expr",
 /*  42 */ "expr ::= expr OPERATOR_TIMES2 expr",
 /*  43 */ "expr ::= expr OPERATOR_DIVIDE expr",
 /*  44 */ "expr ::= expr OPERATOR_DIVIDE2 expr",
 /*  45 */ "expr ::= expr OPERATOR_POW expr",
 /*  46 */ "expr ::= expr OPERATOR_POW2 expr",
 /*  47 */ "expr ::= expr OPERATOR_DEGREE",
 /*  48 */ "expr ::= expr OPERATOR_DEGREE2",
 /*  49 */ "expr ::= expr OPERATOR_FACTORIAL",
 /*  50 */ "expr ::= expr OPERATOR_FACTORIAL2",
 /*  51 */ "expr ::= OPERATOR_ABS expr OPERATOR_ABS",
 /*  52 */ "expr ::= OPERATOR_NOT expr",
 /*  53 */ "expr ::= OPERATOR_NOT2 expr",
 /*  54 */ "expr ::= expr OPERATOR_LEQ expr",
 /*  55 */ "expr ::= expr OPERATOR_LEQ2 expr",
 /*  56 */ "expr ::= expr OPERATOR_GEQ expr",
 /*  57 */ "expr ::= expr OPERATOR_GEQ2 expr",
 /*  58 */ "expr ::= expr OPERATOR_LOW expr",
 /*  59 */ "expr ::= expr OPERATOR_LOW2 expr",
 /*  60 */ "expr ::= expr OPERATOR_GRE expr",
 /*  61 */ "expr ::= expr OPERATOR_GRE2 expr",
 /*  62 */ "expr ::= expr OPERATOR_EQU expr",
 /*  63 */ "expr ::= expr OPERATOR_EQU2 expr",
 /*  64 */ "expr ::= expr OPERATOR_NEQ expr",
 /*  65 */ "expr ::= expr OPERATOR_NEQ2 expr",
 /*  66 */ "expr ::= expr OPERATOR_SHL expr",
 /*  67 */ "expr ::= expr OPERATOR_SHL2 expr",
 /*  68 */ "expr ::= expr OPERATOR_SHR expr",
 /*  69 */ "expr ::= expr OPERATOR_SHR2 expr",
 /*  70 */ "expr ::= expr OPERATOR_AND expr",
 /*  71 */ "expr ::= expr OPERATOR_AND2 expr",
 /*  72 */ "expr ::= expr OPERATOR_OR expr",
 /*  73 */ "expr ::= expr OPERATOR_OR2 expr",
 /*  74 */ "expr ::= expr OPERATOR_XOR expr",
 /*  75 */ "expr ::= expr OPERATOR_XOR2 expr",
 /*  76 */ "expr ::= function_call",
 /*  77 */ "expr ::= matrix",
 /*  78 */ "expr ::= list",
 /*  79 */ "expr ::= expr subscript",
 /*  80 */ "enumeration_element ::= expr",
 /*  81 */ "enumeration_element ::= index_range",
 /*  82 */ "enumeration ::= enumeration_element",
 /*  83 */ "enumeration ::= enumeration ENUMERATION_SEPARATOR enumeration_element",
 /*  84 */ "function_call ::= identifier PARENTHESIS_LEFT enumeration PARENTHESIS_RIGHT",
 /*  85 */ "matrix_row_element ::= expr",
 /*  86 */ "matrix_row_enumeration ::= matrix_row_element",
 /*  87 */ "matrix_row_enumeration ::= matrix_row_enumeration ENUMERATION_SEPARATOR matrix_row_element",
 /*  88 */ "matrix_row ::= PARENTHESIS_LEFT matrix_row_enumeration PARENTHESIS_RIGHT",
 /*  89 */ "matrix_rows ::= matrix_row",
 /*  90 */ "matrix_rows ::= matrix_rows matrix_row",
 /*  91 */ "matrix ::= PARENTHESIS_LEFT matrix_rows PARENTHESIS_RIGHT",
 /*  92 */ "list ::= LIST_LEFT_DELIMITER enumeration LIST_RIGHT_DELIMITER",
 /*  93 */ "assignation ::= expr OPERATOR_ASSIGN expr",
 /*  94 */ "assignation ::= expr OPERATOR_ASSIGN_DYNAMIC expr",
};
#endif /* NDEBUG */


#if YYSTACKDEPTH<=0
/*
** Try to increase the size of the parser stack.  Return the number
** of errors.  Return 0 on success.
*/
static int yyGrowStack(yyParser *p){
  int newSize;
  int idx;
  yyStackEntry *pNew;

  newSize = p->yystksz*2 + 100;
  idx = p->yytos ? (int)(p->yytos - p->yystack) : 0;
  if( p->yystack==&p->yystk0 ){
    pNew = malloc(newSize*sizeof(pNew[0]));
    if( pNew ) pNew[0] = p->yystk0;
  }else{
    pNew = realloc(p->yystack, newSize*sizeof(pNew[0]));
  }
  if( pNew ){
    p->yystack = pNew;
    p->yytos = &p->yystack[idx];
#ifndef NDEBUG
    if( yyTraceFILE ){
      fprintf(yyTraceFILE,"%sStack grows from %d to %d entries.\n",
              yyTracePrompt, p->yystksz, newSize);
    }
#endif
    p->yystksz = newSize;
  }
  return pNew==0; 
}
#endif

/* Datatype of the argument to the memory allocated passed as the
** second argument to ParseAlloc() below.  This can be changed by
** putting an appropriate #define in the %include section of the input
** grammar.
*/
#ifndef YYMALLOCARGTYPE
# define YYMALLOCARGTYPE size_t
#endif

/* Initialize a new parser that has already been allocated.
*/
void ParseInit(void *yypRawParser ParseCTX_PDECL){
  yyParser *yypParser = (yyParser*)yypRawParser;
  ParseCTX_STORE
#ifdef YYTRACKMAXSTACKDEPTH
  yypParser->yyhwm = 0;
#endif
#if YYSTACKDEPTH<=0
  yypParser->yytos = NULL;
  yypParser->yystack = NULL;
  yypParser->yystksz = 0;
  if( yyGrowStack(yypParser) ){
    yypParser->yystack = &yypParser->yystk0;
    yypParser->yystksz = 1;
  }
#endif
#ifndef YYNOERRORRECOVERY
  yypParser->yyerrcnt = -1;
#endif
  yypParser->yytos = yypParser->yystack;
  yypParser->yystack[0].stateno = 0;
  yypParser->yystack[0].major = 0;
#if YYSTACKDEPTH>0
  yypParser->yystackEnd = &yypParser->yystack[YYSTACKDEPTH-1];
#endif
}

#ifndef Parse_ENGINEALWAYSONSTACK
/* 
** This function allocates a new parser.
** The only argument is a pointer to a function which works like
** malloc.
**
** Inputs:
** A pointer to the function used to allocate memory.
**
** Outputs:
** A pointer to a parser.  This pointer is used in subsequent calls
** to Parse and ParseFree.
*/
void *ParseAlloc(void *(*mallocProc)(YYMALLOCARGTYPE) ParseCTX_PDECL){
  yyParser *yypParser;
  yypParser = (yyParser*)(*mallocProc)( (YYMALLOCARGTYPE)sizeof(yyParser) );
  if( yypParser ){
    ParseCTX_STORE
    ParseInit(yypParser ParseCTX_PARAM);
  }
  return (void*)yypParser;
}
#endif /* Parse_ENGINEALWAYSONSTACK */


/* The following function deletes the "minor type" or semantic value
** associated with a symbol.  The symbol can be either a terminal
** or nonterminal. "yymajor" is the symbol code, and "yypminor" is
** a pointer to the value to be deleted.  The code used to do the 
** deletions is derived from the %destructor and/or %token_destructor
** directives of the input grammar.
*/
static void yy_destructor(
  yyParser *yypParser,    /* The parser */
  YYCODETYPE yymajor,     /* Type code for object to destroy */
  YYMINORTYPE *yypminor   /* The object to be destroyed */
){
  ParseARG_FETCH
  ParseCTX_FETCH
  switch( yymajor ){
    /* Here is inserted the actions which take place when a
    ** terminal or non-terminal is destroyed.  This can happen
    ** when the symbol is popped from the stack during a
    ** reduce or during error processing or when a parser is 
    ** being destroyed before it is finished parsing.
    **
    ** Note: during a reduce, the only symbols destroyed are those
    ** which appear on the RHS of the rule, but which are *not* used
    ** inside the C code.
    */
/********* Begin destructor definitions ***************************************/
    case 74: /* context */
{
#line 41 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"

  context = 0;//prevent compile warning

#line 1292 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
}
      break;
/********* End destructor definitions *****************************************/
    default:  break;   /* If no destructor action specified: do nothing */
  }
}

/*
** Pop the parser's stack once.
**
** If there is a destructor routine associated with the token which
** is popped from the stack, then call it.
*/
static void yy_pop_parser_stack(yyParser *pParser){
  yyStackEntry *yytos;
  assert( pParser->yytos!=0 );
  assert( pParser->yytos > pParser->yystack );
  yytos = pParser->yytos--;
#ifndef NDEBUG
  if( yyTraceFILE ){
    fprintf(yyTraceFILE,"%sPopping %s\n",
      yyTracePrompt,
      yyTokenName[yytos->major]);
  }
#endif
  yy_destructor(pParser, yytos->major, &yytos->minor);
}

/*
** Clear all secondary memory allocations from the parser
*/
void ParseFinalize(void *p){
  yyParser *pParser = (yyParser*)p;
  while( pParser->yytos>pParser->yystack ) yy_pop_parser_stack(pParser);
#if YYSTACKDEPTH<=0
  if( pParser->yystack!=&pParser->yystk0 ) free(pParser->yystack);
#endif
}

#ifndef Parse_ENGINEALWAYSONSTACK
/* 
** Deallocate and destroy a parser.  Destructors are called for
** all stack elements before shutting the parser down.
**
** If the YYPARSEFREENEVERNULL macro exists (for example because it
** is defined in a %include section of the input grammar) then it is
** assumed that the input pointer is never NULL.
*/
void ParseFree(
  void *p,                    /* The parser to be deleted */
  void (*freeProc)(void*)     /* Function used to reclaim memory */
){
#ifndef YYPARSEFREENEVERNULL
  if( p==0 ) return;
#endif
  ParseFinalize(p);
  (*freeProc)(p);
}
#endif /* Parse_ENGINEALWAYSONSTACK */

/*
** Return the peak depth of the stack for a parser.
*/
#ifdef YYTRACKMAXSTACKDEPTH
int ParseStackPeak(void *p){
  yyParser *pParser = (yyParser*)p;
  return pParser->yyhwm;
}
#endif

/* This array of booleans keeps track of the parser statement
** coverage.  The element yycoverage[X][Y] is set when the parser
** is in state X and has a lookahead token Y.  In a well-tested
** systems, every element of this matrix should end up being set.
*/
#if defined(YYCOVERAGE)
static unsigned char yycoverage[YYNSTATE][YYNTOKEN];
#endif

/*
** Write into out a description of every state/lookahead combination that
**
**   (1)  has not been used by the parser, and
**   (2)  is not a syntax error.
**
** Return the number of missed state/lookahead combinations.
*/
#if defined(YYCOVERAGE)
int ParseCoverage(FILE *out){
  int stateno, iLookAhead, i;
  int nMissed = 0;
  for(stateno=0; stateno<YYNSTATE; stateno++){
    i = yy_shift_ofst[stateno];
    for(iLookAhead=0; iLookAhead<YYNTOKEN; iLookAhead++){
      if( yy_lookahead[i+iLookAhead]!=iLookAhead ) continue;
      if( yycoverage[stateno][iLookAhead]==0 ) nMissed++;
      if( out ){
        fprintf(out,"State %d lookahead %s %s\n", stateno,
                yyTokenName[iLookAhead],
                yycoverage[stateno][iLookAhead] ? "ok" : "missed");
      }
    }
  }
  return nMissed;
}
#endif

/*
** Find the appropriate action for a parser given the terminal
** look-ahead token iLookAhead.
*/
static YYACTIONTYPE yy_find_shift_action(
  YYCODETYPE iLookAhead,    /* The look-ahead token */
  YYACTIONTYPE stateno      /* Current state number */
){
  int i;

  if( stateno>YY_MAX_SHIFT ) return stateno;
  assert( stateno <= YY_SHIFT_COUNT );
#if defined(YYCOVERAGE)
  yycoverage[stateno][iLookAhead] = 1;
#endif
  do{
    i = yy_shift_ofst[stateno];
    assert( i>=0 );
    assert( i<=YY_ACTTAB_COUNT );
    assert( i+YYNTOKEN<=(int)YY_NLOOKAHEAD );
    assert( iLookAhead!=YYNOCODE );
    assert( iLookAhead < YYNTOKEN );
    i += iLookAhead;
    assert( i<(int)YY_NLOOKAHEAD );
    if( yy_lookahead[i]!=iLookAhead ){
#ifdef YYFALLBACK
      YYCODETYPE iFallback;            /* Fallback token */
      assert( iLookAhead<sizeof(yyFallback)/sizeof(yyFallback[0]) );
      iFallback = yyFallback[iLookAhead];
      if( iFallback!=0 ){
#ifndef NDEBUG
        if( yyTraceFILE ){
          fprintf(yyTraceFILE, "%sFALLBACK %s => %s\n",
             yyTracePrompt, yyTokenName[iLookAhead], yyTokenName[iFallback]);
        }
#endif
        assert( yyFallback[iFallback]==0 ); /* Fallback loop must terminate */
        iLookAhead = iFallback;
        continue;
      }
#endif
#ifdef YYWILDCARD
      {
        int j = i - iLookAhead + YYWILDCARD;
        assert( j<(int)(sizeof(yy_lookahead)/sizeof(yy_lookahead[0])) );
        if( yy_lookahead[j]==YYWILDCARD && iLookAhead>0 ){
#ifndef NDEBUG
          if( yyTraceFILE ){
            fprintf(yyTraceFILE, "%sWILDCARD %s => %s\n",
               yyTracePrompt, yyTokenName[iLookAhead],
               yyTokenName[YYWILDCARD]);
          }
#endif /* NDEBUG */
          return yy_action[j];
        }
      }
#endif /* YYWILDCARD */
      return yy_default[stateno];
    }else{
      assert( i>=0 && i<sizeof(yy_action)/sizeof(yy_action[0]) );
      return yy_action[i];
    }
  }while(1);
}

/*
** Find the appropriate action for a parser given the non-terminal
** look-ahead token iLookAhead.
*/
static YYACTIONTYPE yy_find_reduce_action(
  YYACTIONTYPE stateno,     /* Current state number */
  YYCODETYPE iLookAhead     /* The look-ahead token */
){
  int i;
#ifdef YYERRORSYMBOL
  if( stateno>YY_REDUCE_COUNT ){
    return yy_default[stateno];
  }
#else
  assert( stateno<=YY_REDUCE_COUNT );
#endif
  i = yy_reduce_ofst[stateno];
  assert( iLookAhead!=YYNOCODE );
  i += iLookAhead;
#ifdef YYERRORSYMBOL
  if( i<0 || i>=YY_ACTTAB_COUNT || yy_lookahead[i]!=iLookAhead ){
    return yy_default[stateno];
  }
#else
  assert( i>=0 && i<YY_ACTTAB_COUNT );
  assert( yy_lookahead[i]==iLookAhead );
#endif
  return yy_action[i];
}

/*
** The following routine is called if the stack overflows.
*/
static void yyStackOverflow(yyParser *yypParser){
   ParseARG_FETCH
   ParseCTX_FETCH
#ifndef NDEBUG
   if( yyTraceFILE ){
     fprintf(yyTraceFILE,"%sStack Overflow!\n",yyTracePrompt);
   }
#endif
   while( yypParser->yytos>yypParser->yystack ) yy_pop_parser_stack(yypParser);
   /* Here code is inserted which will execute if the parser
   ** stack every overflows */
/******** Begin %stack_overflow code ******************************************/
/******** End %stack_overflow code ********************************************/
   ParseARG_STORE /* Suppress warning about unused %extra_argument var */
   ParseCTX_STORE
}

/*
** Print tracing information for a SHIFT action
*/
#ifndef NDEBUG
static void yyTraceShift(yyParser *yypParser, int yyNewState, const char *zTag){
  if( yyTraceFILE ){
    if( yyNewState<YYNSTATE ){
      fprintf(yyTraceFILE,"%s%s '%s', go to state %d\n",
         yyTracePrompt, zTag, yyTokenName[yypParser->yytos->major],
         yyNewState);
    }else{
      fprintf(yyTraceFILE,"%s%s '%s', pending reduce %d\n",
         yyTracePrompt, zTag, yyTokenName[yypParser->yytos->major],
         yyNewState - YY_MIN_REDUCE);
    }
  }
}
#else
# define yyTraceShift(X,Y,Z)
#endif

/*
** Perform a shift action.
*/
static void yy_shift(
  yyParser *yypParser,          /* The parser to be shifted */
  YYACTIONTYPE yyNewState,      /* The new state to shift in */
  YYCODETYPE yyMajor,           /* The major token to shift in */
  ParseTOKENTYPE yyMinor        /* The minor token to shift in */
){
  yyStackEntry *yytos;
  yypParser->yytos++;
#ifdef YYTRACKMAXSTACKDEPTH
  if( (int)(yypParser->yytos - yypParser->yystack)>yypParser->yyhwm ){
    yypParser->yyhwm++;
    assert( yypParser->yyhwm == (int)(yypParser->yytos - yypParser->yystack) );
  }
#endif
#if YYSTACKDEPTH>0 
  if( yypParser->yytos>yypParser->yystackEnd ){
    yypParser->yytos--;
    yyStackOverflow(yypParser);
    return;
  }
#else
  if( yypParser->yytos>=&yypParser->yystack[yypParser->yystksz] ){
    if( yyGrowStack(yypParser) ){
      yypParser->yytos--;
      yyStackOverflow(yypParser);
      return;
    }
  }
#endif
  if( yyNewState > YY_MAX_SHIFT ){
    yyNewState += YY_MIN_REDUCE - YY_MIN_SHIFTREDUCE;
  }
  yytos = yypParser->yytos;
  yytos->stateno = yyNewState;
  yytos->major = yyMajor;
  yytos->minor.yy0 = yyMinor;
  yyTraceShift(yypParser, yyNewState, "Shift");
}

/* For rule J, yyRuleInfoLhs[J] contains the symbol on the left-hand side
** of that rule */
static const YYCODETYPE yyRuleInfoLhs[] = {
    91,  /* (0) command ::= expr */
    91,  /* (1) command ::= assignation */
    75,  /* (2) integer ::= INTEGER_POSITIVE */
    77,  /* (3) index_range ::= integer INDEX_RANGE_OPERATOR integer */
    77,  /* (4) index_range ::= INDEX_RANGE_JOKER */
    78,  /* (5) real ::= REAL_POSITIVE */
    80,  /* (6) number ::= integer */
    80,  /* (7) number ::= real */
    93,  /* (8) integer_per_fraction ::= INTEGER_PER_FRACTION */
    94,  /* (9) real_per_fraction ::= REAL_PER_FRACTION */
    95,  /* (10) number_per_fraction ::= integer_per_fraction */
    95,  /* (11) number_per_fraction ::= real_per_fraction */
    82,  /* (12) string_quoted ::= STRING_QUOTED */
    83,  /* (13) interval ::= INTERVAL_LEFT_DELIMITER expr INTERVAL_ITEM_SEPARATOR expr INTERVAL_RIGHT_DELIMITER */
    84,  /* (14) identifier ::= IDENTIFIER */
    85,  /* (15) value ::= number */
    85,  /* (16) value ::= string_quoted */
    85,  /* (17) value ::= identifier */
    85,  /* (18) value ::= interval */
    96,  /* (19) subscript ::= INTERVAL_LEFT_DELIMITER enumeration INTERVAL_RIGHT_DELIMITER */
    92,  /* (20) expr ::= value */
    92,  /* (21) expr ::= IF expr THEN expr ELSE expr */
    92,  /* (22) expr ::= expr QUESTION expr ALTERNATE expr */
    92,  /* (23) expr ::= PARENTHESIS_LEFT expr PARENTHESIS_RIGHT */
    92,  /* (24) expr ::= OPERATOR_MINUS_UNARY expr */
    92,  /* (25) expr ::= OPERATOR_MINUS expr */
    92,  /* (26) expr ::= OPERATOR_SQRT expr */
    92,  /* (27) expr ::= OPERATOR_SQRT2 expr */
    92,  /* (28) expr ::= OPERATOR_CBRT expr */
    92,  /* (29) expr ::= OPERATOR_CBRT2 expr */
    92,  /* (30) expr ::= expr OPERATOR_SQRT expr */
    92,  /* (31) expr ::= expr OPERATOR_SQRT2 expr */
    92,  /* (32) expr ::= expr OPERATOR_CBRT expr */
    92,  /* (33) expr ::= expr OPERATOR_CBRT2 expr */
    92,  /* (34) expr ::= expr OPERATOR_UNCERTAINTY number_per_fraction */
    92,  /* (35) expr ::= expr OPERATOR_UNCERTAINTY expr */
    92,  /* (36) expr ::= expr OPERATOR_PLUS expr */
    92,  /* (37) expr ::= expr OPERATOR_PLUS2 expr */
    92,  /* (38) expr ::= expr OPERATOR_MINUS expr */
    92,  /* (39) expr ::= expr OPERATOR_MINUS2 expr */
    92,  /* (40) expr ::= expr OPERATOR_TIMES expr */
    92,  /* (41) expr ::= expr INDEX_RANGE_JOKER expr */
    92,  /* (42) expr ::= expr OPERATOR_TIMES2 expr */
    92,  /* (43) expr ::= expr OPERATOR_DIVIDE expr */
    92,  /* (44) expr ::= expr OPERATOR_DIVIDE2 expr */
    92,  /* (45) expr ::= expr OPERATOR_POW expr */
    92,  /* (46) expr ::= expr OPERATOR_POW2 expr */
    92,  /* (47) expr ::= expr OPERATOR_DEGREE */
    92,  /* (48) expr ::= expr OPERATOR_DEGREE2 */
    92,  /* (49) expr ::= expr OPERATOR_FACTORIAL */
    92,  /* (50) expr ::= expr OPERATOR_FACTORIAL2 */
    92,  /* (51) expr ::= OPERATOR_ABS expr OPERATOR_ABS */
    92,  /* (52) expr ::= OPERATOR_NOT expr */
    92,  /* (53) expr ::= OPERATOR_NOT2 expr */
    92,  /* (54) expr ::= expr OPERATOR_LEQ expr */
    92,  /* (55) expr ::= expr OPERATOR_LEQ2 expr */
    92,  /* (56) expr ::= expr OPERATOR_GEQ expr */
    92,  /* (57) expr ::= expr OPERATOR_GEQ2 expr */
    92,  /* (58) expr ::= expr OPERATOR_LOW expr */
    92,  /* (59) expr ::= expr OPERATOR_LOW2 expr */
    92,  /* (60) expr ::= expr OPERATOR_GRE expr */
    92,  /* (61) expr ::= expr OPERATOR_GRE2 expr */
    92,  /* (62) expr ::= expr OPERATOR_EQU expr */
    92,  /* (63) expr ::= expr OPERATOR_EQU2 expr */
    92,  /* (64) expr ::= expr OPERATOR_NEQ expr */
    92,  /* (65) expr ::= expr OPERATOR_NEQ2 expr */
    92,  /* (66) expr ::= expr OPERATOR_SHL expr */
    92,  /* (67) expr ::= expr OPERATOR_SHL2 expr */
    92,  /* (68) expr ::= expr OPERATOR_SHR expr */
    92,  /* (69) expr ::= expr OPERATOR_SHR2 expr */
    92,  /* (70) expr ::= expr OPERATOR_AND expr */
    92,  /* (71) expr ::= expr OPERATOR_AND2 expr */
    92,  /* (72) expr ::= expr OPERATOR_OR expr */
    92,  /* (73) expr ::= expr OPERATOR_OR2 expr */
    92,  /* (74) expr ::= expr OPERATOR_XOR expr */
    92,  /* (75) expr ::= expr OPERATOR_XOR2 expr */
    92,  /* (76) expr ::= function_call */
    92,  /* (77) expr ::= matrix */
    92,  /* (78) expr ::= list */
    92,  /* (79) expr ::= expr subscript */
    99,  /* (80) enumeration_element ::= expr */
    99,  /* (81) enumeration_element ::= index_range */
    86,  /* (82) enumeration ::= enumeration_element */
    86,  /* (83) enumeration ::= enumeration ENUMERATION_SEPARATOR enumeration_element */
    97,  /* (84) function_call ::= identifier PARENTHESIS_LEFT enumeration PARENTHESIS_RIGHT */
   100,  /* (85) matrix_row_element ::= expr */
    89,  /* (86) matrix_row_enumeration ::= matrix_row_element */
    89,  /* (87) matrix_row_enumeration ::= matrix_row_enumeration ENUMERATION_SEPARATOR matrix_row_element */
   101,  /* (88) matrix_row ::= PARENTHESIS_LEFT matrix_row_enumeration PARENTHESIS_RIGHT */
    88,  /* (89) matrix_rows ::= matrix_row */
    88,  /* (90) matrix_rows ::= matrix_rows matrix_row */
    98,  /* (91) matrix ::= PARENTHESIS_LEFT matrix_rows PARENTHESIS_RIGHT */
    87,  /* (92) list ::= LIST_LEFT_DELIMITER enumeration LIST_RIGHT_DELIMITER */
    90,  /* (93) assignation ::= expr OPERATOR_ASSIGN expr */
    90,  /* (94) assignation ::= expr OPERATOR_ASSIGN_DYNAMIC expr */
};

/* For rule J, yyRuleInfoNRhs[J] contains the negative of the number
** of symbols on the right-hand side of that rule. */
static const signed char yyRuleInfoNRhs[] = {
   -1,  /* (0) command ::= expr */
   -1,  /* (1) command ::= assignation */
   -1,  /* (2) integer ::= INTEGER_POSITIVE */
   -3,  /* (3) index_range ::= integer INDEX_RANGE_OPERATOR integer */
   -1,  /* (4) index_range ::= INDEX_RANGE_JOKER */
   -1,  /* (5) real ::= REAL_POSITIVE */
   -1,  /* (6) number ::= integer */
   -1,  /* (7) number ::= real */
   -1,  /* (8) integer_per_fraction ::= INTEGER_PER_FRACTION */
   -1,  /* (9) real_per_fraction ::= REAL_PER_FRACTION */
   -1,  /* (10) number_per_fraction ::= integer_per_fraction */
   -1,  /* (11) number_per_fraction ::= real_per_fraction */
   -1,  /* (12) string_quoted ::= STRING_QUOTED */
   -5,  /* (13) interval ::= INTERVAL_LEFT_DELIMITER expr INTERVAL_ITEM_SEPARATOR expr INTERVAL_RIGHT_DELIMITER */
   -1,  /* (14) identifier ::= IDENTIFIER */
   -1,  /* (15) value ::= number */
   -1,  /* (16) value ::= string_quoted */
   -1,  /* (17) value ::= identifier */
   -1,  /* (18) value ::= interval */
   -3,  /* (19) subscript ::= INTERVAL_LEFT_DELIMITER enumeration INTERVAL_RIGHT_DELIMITER */
   -1,  /* (20) expr ::= value */
   -6,  /* (21) expr ::= IF expr THEN expr ELSE expr */
   -5,  /* (22) expr ::= expr QUESTION expr ALTERNATE expr */
   -3,  /* (23) expr ::= PARENTHESIS_LEFT expr PARENTHESIS_RIGHT */
   -2,  /* (24) expr ::= OPERATOR_MINUS_UNARY expr */
   -2,  /* (25) expr ::= OPERATOR_MINUS expr */
   -2,  /* (26) expr ::= OPERATOR_SQRT expr */
   -2,  /* (27) expr ::= OPERATOR_SQRT2 expr */
   -2,  /* (28) expr ::= OPERATOR_CBRT expr */
   -2,  /* (29) expr ::= OPERATOR_CBRT2 expr */
   -3,  /* (30) expr ::= expr OPERATOR_SQRT expr */
   -3,  /* (31) expr ::= expr OPERATOR_SQRT2 expr */
   -3,  /* (32) expr ::= expr OPERATOR_CBRT expr */
   -3,  /* (33) expr ::= expr OPERATOR_CBRT2 expr */
   -3,  /* (34) expr ::= expr OPERATOR_UNCERTAINTY number_per_fraction */
   -3,  /* (35) expr ::= expr OPERATOR_UNCERTAINTY expr */
   -3,  /* (36) expr ::= expr OPERATOR_PLUS expr */
   -3,  /* (37) expr ::= expr OPERATOR_PLUS2 expr */
   -3,  /* (38) expr ::= expr OPERATOR_MINUS expr */
   -3,  /* (39) expr ::= expr OPERATOR_MINUS2 expr */
   -3,  /* (40) expr ::= expr OPERATOR_TIMES expr */
   -3,  /* (41) expr ::= expr INDEX_RANGE_JOKER expr */
   -3,  /* (42) expr ::= expr OPERATOR_TIMES2 expr */
   -3,  /* (43) expr ::= expr OPERATOR_DIVIDE expr */
   -3,  /* (44) expr ::= expr OPERATOR_DIVIDE2 expr */
   -3,  /* (45) expr ::= expr OPERATOR_POW expr */
   -3,  /* (46) expr ::= expr OPERATOR_POW2 expr */
   -2,  /* (47) expr ::= expr OPERATOR_DEGREE */
   -2,  /* (48) expr ::= expr OPERATOR_DEGREE2 */
   -2,  /* (49) expr ::= expr OPERATOR_FACTORIAL */
   -2,  /* (50) expr ::= expr OPERATOR_FACTORIAL2 */
   -3,  /* (51) expr ::= OPERATOR_ABS expr OPERATOR_ABS */
   -2,  /* (52) expr ::= OPERATOR_NOT expr */
   -2,  /* (53) expr ::= OPERATOR_NOT2 expr */
   -3,  /* (54) expr ::= expr OPERATOR_LEQ expr */
   -3,  /* (55) expr ::= expr OPERATOR_LEQ2 expr */
   -3,  /* (56) expr ::= expr OPERATOR_GEQ expr */
   -3,  /* (57) expr ::= expr OPERATOR_GEQ2 expr */
   -3,  /* (58) expr ::= expr OPERATOR_LOW expr */
   -3,  /* (59) expr ::= expr OPERATOR_LOW2 expr */
   -3,  /* (60) expr ::= expr OPERATOR_GRE expr */
   -3,  /* (61) expr ::= expr OPERATOR_GRE2 expr */
   -3,  /* (62) expr ::= expr OPERATOR_EQU expr */
   -3,  /* (63) expr ::= expr OPERATOR_EQU2 expr */
   -3,  /* (64) expr ::= expr OPERATOR_NEQ expr */
   -3,  /* (65) expr ::= expr OPERATOR_NEQ2 expr */
   -3,  /* (66) expr ::= expr OPERATOR_SHL expr */
   -3,  /* (67) expr ::= expr OPERATOR_SHL2 expr */
   -3,  /* (68) expr ::= expr OPERATOR_SHR expr */
   -3,  /* (69) expr ::= expr OPERATOR_SHR2 expr */
   -3,  /* (70) expr ::= expr OPERATOR_AND expr */
   -3,  /* (71) expr ::= expr OPERATOR_AND2 expr */
   -3,  /* (72) expr ::= expr OPERATOR_OR expr */
   -3,  /* (73) expr ::= expr OPERATOR_OR2 expr */
   -3,  /* (74) expr ::= expr OPERATOR_XOR expr */
   -3,  /* (75) expr ::= expr OPERATOR_XOR2 expr */
   -1,  /* (76) expr ::= function_call */
   -1,  /* (77) expr ::= matrix */
   -1,  /* (78) expr ::= list */
   -2,  /* (79) expr ::= expr subscript */
   -1,  /* (80) enumeration_element ::= expr */
   -1,  /* (81) enumeration_element ::= index_range */
   -1,  /* (82) enumeration ::= enumeration_element */
   -3,  /* (83) enumeration ::= enumeration ENUMERATION_SEPARATOR enumeration_element */
   -4,  /* (84) function_call ::= identifier PARENTHESIS_LEFT enumeration PARENTHESIS_RIGHT */
   -1,  /* (85) matrix_row_element ::= expr */
   -1,  /* (86) matrix_row_enumeration ::= matrix_row_element */
   -3,  /* (87) matrix_row_enumeration ::= matrix_row_enumeration ENUMERATION_SEPARATOR matrix_row_element */
   -3,  /* (88) matrix_row ::= PARENTHESIS_LEFT matrix_row_enumeration PARENTHESIS_RIGHT */
   -1,  /* (89) matrix_rows ::= matrix_row */
   -2,  /* (90) matrix_rows ::= matrix_rows matrix_row */
   -3,  /* (91) matrix ::= PARENTHESIS_LEFT matrix_rows PARENTHESIS_RIGHT */
   -3,  /* (92) list ::= LIST_LEFT_DELIMITER enumeration LIST_RIGHT_DELIMITER */
   -3,  /* (93) assignation ::= expr OPERATOR_ASSIGN expr */
   -3,  /* (94) assignation ::= expr OPERATOR_ASSIGN_DYNAMIC expr */
};

static void yy_accept(yyParser*);  /* Forward Declaration */

/*
** Perform a reduce action and the shift that must immediately
** follow the reduce.
**
** The yyLookahead and yyLookaheadToken parameters provide reduce actions
** access to the lookahead token (if any).  The yyLookahead will be YYNOCODE
** if the lookahead token has already been consumed.  As this procedure is
** only called from one place, optimizing compilers will in-line it, which
** means that the extra parameters have no performance impact.
*/
static YYACTIONTYPE yy_reduce(
  yyParser *yypParser,         /* The parser */
  unsigned int yyruleno,       /* Number of the rule by which to reduce */
  int yyLookahead,             /* Lookahead token, or YYNOCODE if none */
  ParseTOKENTYPE yyLookaheadToken  /* Value of the lookahead token */
  ParseCTX_PDECL                   /* %extra_context */
){
  int yygoto;                     /* The next state */
  YYACTIONTYPE yyact;             /* The next action */
  yyStackEntry *yymsp;            /* The top of the parser's stack */
  int yysize;                     /* Amount to pop the stack */
  ParseARG_FETCH
  (void)yyLookahead;
  (void)yyLookaheadToken;
  yymsp = yypParser->yytos;
#ifndef NDEBUG
  if( yyTraceFILE && yyruleno<(int)(sizeof(yyRuleName)/sizeof(yyRuleName[0])) ){
    yysize = yyRuleInfoNRhs[yyruleno];
    if( yysize ){
      fprintf(yyTraceFILE, "%sReduce %d [%s]%s, pop back to state %d.\n",
        yyTracePrompt,
        yyruleno, yyRuleName[yyruleno],
        yyruleno<YYNRULE_WITH_ACTION ? "" : " without external action",
        yymsp[yysize].stateno);
    }else{
      fprintf(yyTraceFILE, "%sReduce %d [%s]%s.\n",
        yyTracePrompt, yyruleno, yyRuleName[yyruleno],
        yyruleno<YYNRULE_WITH_ACTION ? "" : " without external action");
    }
  }
#endif /* NDEBUG */

  /* Check that the stack is large enough to grow by a single entry
  ** if the RHS of the rule is empty.  This ensures that there is room
  ** enough on the stack to push the LHS value */
  if( yyRuleInfoNRhs[yyruleno]==0 ){
#ifdef YYTRACKMAXSTACKDEPTH
    if( (int)(yypParser->yytos - yypParser->yystack)>yypParser->yyhwm ){
      yypParser->yyhwm++;
      assert( yypParser->yyhwm == (int)(yypParser->yytos - yypParser->yystack));
    }
#endif
#if YYSTACKDEPTH>0 
    if( yypParser->yytos>=yypParser->yystackEnd ){
      yyStackOverflow(yypParser);
      /* The call to yyStackOverflow() above pops the stack until it is
      ** empty, causing the main parser loop to exit.  So the return value
      ** is never used and does not matter. */
      return 0;
    }
#else
    if( yypParser->yytos>=&yypParser->yystack[yypParser->yystksz-1] ){
      if( yyGrowStack(yypParser) ){
        yyStackOverflow(yypParser);
        /* The call to yyStackOverflow() above pops the stack until it is
        ** empty, causing the main parser loop to exit.  So the return value
        ** is never used and does not matter. */
        return 0;
      }
      yymsp = yypParser->yytos;
    }
#endif
  }

  switch( yyruleno ){
  /* Beginning here are the reduction cases.  A typical example
  ** follows:
  **   case 0:
  **  #line <lineno> <grammarfile>
  **     { ... }           // User supplied code
  **  #line <lineno> <thisfile>
  **     break;
  */
/********** Begin reduce actions **********************************************/
        YYMINORTYPE yylhsminor;
      case 0: /* command ::= expr */
#line 80 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101=yymsp[0].minor.yy101;
  DebugLogStatic(1, @"command(%@) = expr(%@)\n", yylhsminor.yy101, yymsp[0].minor.yy101);
  [context.parserListener parserContext:context didEncounterRootNode:yylhsminor.yy101];
}
#line 1872 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[0].minor.yy101 = yylhsminor.yy101;
        break;
      case 1: /* command ::= assignation */
#line 85 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101=yymsp[0].minor.yy29;
  DebugLogStatic(1, @"command(%@) = assignation(%@)\n", yylhsminor.yy101, yymsp[0].minor.yy29);
  [context.parserListener parserContext:context didEncounterRootNode:yylhsminor.yy101];
}
#line 1882 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[0].minor.yy101 = yylhsminor.yy101;
        break;
      case 2: /* integer ::= INTEGER_POSITIVE */
#line 91 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy141=[CHParserValueNumberIntegerNode parserNodeWithToken:yymsp[0].minor.yy0];
  DebugLogStatic(1, @"%@ ::= INTEGER_POSITIVE(%@)", yylhsminor.yy141, yymsp[0].minor.yy0);
}
#line 1891 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[0].minor.yy141 = yylhsminor.yy141;
        break;
      case 3: /* index_range ::= integer INDEX_RANGE_OPERATOR integer */
#line 95 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy191=[CHParserValueIndexRangeNode parserNodeWithToken:[CHChalkToken chalkTokenUnion:@[yymsp[-2].minor.yy141.token,yymsp[-1].minor.yy0,yymsp[0].minor.yy141.token]]];
  [yylhsminor.yy191 addChild:yymsp[-2].minor.yy141];
  [yylhsminor.yy191 addChild:yymsp[0].minor.yy141];
  DebugLogStatic(1, @"index_range(%@) ::= {index_range(%@, %@, %@)}", yylhsminor.yy191, yymsp[-2].minor.yy141, yymsp[-1].minor.yy0, yymsp[0].minor.yy141);
}
#line 1902 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy191 = yylhsminor.yy191;
        break;
      case 4: /* index_range ::= INDEX_RANGE_JOKER */
#line 101 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy191=[CHParserValueIndexRangeNode parserNodeWithToken:yymsp[0].minor.yy0 joker:YES];
  DebugLogStatic(1, @"index_range(%@) ::= {index_range(%@)}", yylhsminor.yy191, yymsp[0].minor.yy0);
}
#line 1911 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[0].minor.yy191 = yylhsminor.yy191;
        break;
      case 5: /* real ::= REAL_POSITIVE */
#line 105 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy19=[CHParserValueNumberRealNode parserNodeWithToken:yymsp[0].minor.yy0];
  DebugLogStatic(1, @"%@ ::= REAL_POSITIVE(%@)", yylhsminor.yy19, yymsp[0].minor.yy0);
}
#line 1920 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[0].minor.yy19 = yylhsminor.yy19;
        break;
      case 6: /* number ::= integer */
#line 109 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{yylhsminor.yy67=yymsp[0].minor.yy141;}
#line 1926 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[0].minor.yy67 = yylhsminor.yy67;
        break;
      case 7: /* number ::= real */
#line 110 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{yylhsminor.yy67=yymsp[0].minor.yy19;}
#line 1932 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[0].minor.yy67 = yylhsminor.yy67;
        break;
      case 8: /* integer_per_fraction ::= INTEGER_PER_FRACTION */
#line 112 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101=[CHParserValueNumberPerFractionNode parserNodeWithToken:yymsp[0].minor.yy0];
  DebugLogStatic(1, @"%@ ::= INTEGER_PER_FRACTION(%@)", yylhsminor.yy101, yymsp[0].minor.yy0);
}
#line 1941 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[0].minor.yy101 = yylhsminor.yy101;
        break;
      case 9: /* real_per_fraction ::= REAL_PER_FRACTION */
#line 116 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101=[CHParserValueNumberPerFractionNode parserNodeWithToken:yymsp[0].minor.yy0];
  DebugLogStatic(1, @"%@ ::= REAL_PER_FRACTION(%@)", yylhsminor.yy101, yymsp[0].minor.yy0);
}
#line 1950 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[0].minor.yy101 = yylhsminor.yy101;
        break;
      case 10: /* number_per_fraction ::= integer_per_fraction */
      case 11: /* number_per_fraction ::= real_per_fraction */ yytestcase(yyruleno==11);
#line 120 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{yylhsminor.yy101=yymsp[0].minor.yy101;}
#line 1957 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[0].minor.yy101 = yylhsminor.yy101;
        break;
      case 12: /* string_quoted ::= STRING_QUOTED */
#line 123 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy169=[CHParserValueStringNode parserNodeWithToken:yymsp[0].minor.yy0];
  DebugLogStatic(1, @"%@ ::= \"%@\"", yylhsminor.yy169, yymsp[0].minor.yy0);
}
#line 1966 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[0].minor.yy169 = yylhsminor.yy169;
        break;
      case 13: /* interval ::= INTERVAL_LEFT_DELIMITER expr INTERVAL_ITEM_SEPARATOR expr INTERVAL_RIGHT_DELIMITER */
#line 128 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy196=[CHParserValueNumberIntervalNode parserNodeWithToken:[CHChalkToken chalkTokenUnion:@[yymsp[-4].minor.yy0,yymsp[-3].minor.yy101.token,yymsp[-2].minor.yy0,yymsp[-1].minor.yy101.token,yymsp[0].minor.yy0]]];
  [yylhsminor.yy196 addChild:yymsp[-3].minor.yy101];
  [yylhsminor.yy196 addChild:yymsp[-1].minor.yy101];
  DebugLogStatic(1, @"interval(%@) ::= {interval([%@;%@])}", yylhsminor.yy196, yymsp[-3].minor.yy101, yymsp[-1].minor.yy101);
}
#line 1977 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-4].minor.yy196 = yylhsminor.yy196;
        break;
      case 14: /* identifier ::= IDENTIFIER */
#line 135 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy60=[CHParserIdentifierNode parserNodeWithToken:yymsp[0].minor.yy0];
  DebugLogStatic(1, @"%@ ::= IDENTIFIER(%@)", yylhsminor.yy60, yymsp[0].minor.yy0);
}
#line 1986 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[0].minor.yy60 = yylhsminor.yy60;
        break;
      case 15: /* value ::= number */
#line 139 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{yylhsminor.yy110=yymsp[0].minor.yy67;}
#line 1992 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[0].minor.yy110 = yylhsminor.yy110;
        break;
      case 16: /* value ::= string_quoted */
#line 140 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{yylhsminor.yy110=yymsp[0].minor.yy169;}
#line 1998 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[0].minor.yy110 = yylhsminor.yy110;
        break;
      case 17: /* value ::= identifier */
#line 141 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{yylhsminor.yy110=yymsp[0].minor.yy60;}
#line 2004 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[0].minor.yy110 = yylhsminor.yy110;
        break;
      case 18: /* value ::= interval */
#line 142 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{yylhsminor.yy110=yymsp[0].minor.yy196;}
#line 2010 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[0].minor.yy110 = yylhsminor.yy110;
        break;
      case 19: /* subscript ::= INTERVAL_LEFT_DELIMITER enumeration INTERVAL_RIGHT_DELIMITER */
#line 144 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserSubscriptNode parserNodeWithToken:[CHChalkToken chalkTokenUnion:@[yymsp[-2].minor.yy0,yymsp[-1].minor.yy61.token,yymsp[0].minor.yy0]]];
  [yylhsminor.yy101 addChild:yymsp[-1].minor.yy61];
  DebugLogStatic(1, @"subscript(%@) ::= [enumeration(%@)]", yylhsminor.yy101, yymsp[-1].minor.yy61);
}
#line 2020 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy101 = yylhsminor.yy101;
        break;
      case 20: /* expr ::= value */
#line 150 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = yymsp[0].minor.yy110;
  DebugLogStatic(1, @"expr(%@) ::= value(%@)", yylhsminor.yy101, yymsp[0].minor.yy110);
}
#line 2029 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[0].minor.yy101 = yylhsminor.yy101;
        break;
      case 21: /* expr ::= IF expr THEN expr ELSE expr */
#line 154 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yymsp[-5].minor.yy101 = [CHParserIfThenElseNode parserNodeWithIf:yymsp[-4].minor.yy101 Then:yymsp[-2].minor.yy101 Else:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= if (%@) then (%@) else (%@)", yymsp[-5].minor.yy101, yymsp[-4].minor.yy101, yymsp[-2].minor.yy101, yymsp[0].minor.yy101);
}
#line 2038 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
        break;
      case 22: /* expr ::= expr QUESTION expr ALTERNATE expr */
#line 158 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserIfThenElseNode parserNodeWithIf:yymsp[-4].minor.yy101 Then:yymsp[-2].minor.yy101 Else:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= (%@) ? (%@) : (%@)", yylhsminor.yy101, yymsp[-4].minor.yy101, yymsp[-2].minor.yy101, yymsp[0].minor.yy101);
}
#line 2046 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-4].minor.yy101 = yylhsminor.yy101;
        break;
      case 23: /* expr ::= PARENTHESIS_LEFT expr PARENTHESIS_RIGHT */
#line 162 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yymsp[-2].minor.yy101 = yymsp[-1].minor.yy101;
  DebugLogStatic(1, @"expr(%@) ::= ( value(%@) )", yymsp[-2].minor.yy101, yymsp[-1].minor.yy101);
}
#line 2055 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
        break;
      case 24: /* expr ::= OPERATOR_MINUS_UNARY expr */
      case 25: /* expr ::= OPERATOR_MINUS expr */ yytestcase(yyruleno==25);
#line 166 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_MINUS];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= negate expr(%@)", yylhsminor.yy101, yymsp[0].minor.yy101);
}
#line 2065 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-1].minor.yy101 = yylhsminor.yy101;
        break;
      case 26: /* expr ::= OPERATOR_SQRT expr */
#line 176 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_SQRT];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= sqrt(expr(%@))", yylhsminor.yy101, yymsp[0].minor.yy101);
}
#line 2075 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-1].minor.yy101 = yylhsminor.yy101;
        break;
      case 27: /* expr ::= OPERATOR_SQRT2 expr */
#line 181 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_SQRT2];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= .sqrt(expr(%@))", yylhsminor.yy101, yymsp[0].minor.yy101);
}
#line 2085 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-1].minor.yy101 = yylhsminor.yy101;
        break;
      case 28: /* expr ::= OPERATOR_CBRT expr */
#line 186 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_CBRT];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= cbrt(expr(%@))", yylhsminor.yy101, yymsp[0].minor.yy101);
}
#line 2095 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-1].minor.yy101 = yylhsminor.yy101;
        break;
      case 29: /* expr ::= OPERATOR_CBRT2 expr */
#line 191 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_CBRT2];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= .cbrt(expr(%@))", yylhsminor.yy101, yymsp[0].minor.yy101);
}
#line 2105 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-1].minor.yy101 = yylhsminor.yy101;
        break;
      case 30: /* expr ::= expr OPERATOR_SQRT expr */
#line 196 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_MUL_SQRT];
  [yylhsminor.yy101 addChild:yymsp[-2].minor.yy101];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= expr(%@)*sqrt(expr(%@))", yylhsminor.yy101, yymsp[-2].minor.yy101, yymsp[0].minor.yy101);
}
#line 2116 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy101 = yylhsminor.yy101;
        break;
      case 31: /* expr ::= expr OPERATOR_SQRT2 expr */
#line 202 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_MUL_SQRT2];
  [yylhsminor.yy101 addChild:yymsp[-2].minor.yy101];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= expr(%@)*.sqrt(expr(%@))", yylhsminor.yy101, yymsp[-2].minor.yy101, yymsp[0].minor.yy101);
}
#line 2127 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy101 = yylhsminor.yy101;
        break;
      case 32: /* expr ::= expr OPERATOR_CBRT expr */
#line 208 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_MUL_CBRT];
  [yylhsminor.yy101 addChild:yymsp[-2].minor.yy101];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= expr(%@)*cbrt(expr(%@))", yylhsminor.yy101, yymsp[-2].minor.yy101, yymsp[0].minor.yy101);
}
#line 2138 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy101 = yylhsminor.yy101;
        break;
      case 33: /* expr ::= expr OPERATOR_CBRT2 expr */
#line 214 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_MUL_CBRT2];
  [yylhsminor.yy101 addChild:yymsp[-2].minor.yy101];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= expr(%@)*.cbrt(expr(%@))", yylhsminor.yy101, yymsp[-2].minor.yy101, yymsp[0].minor.yy101);
}
#line 2149 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy101 = yylhsminor.yy101;
        break;
      case 34: /* expr ::= expr OPERATOR_UNCERTAINTY number_per_fraction */
      case 35: /* expr ::= expr OPERATOR_UNCERTAINTY expr */ yytestcase(yyruleno==35);
#line 220 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_UNCERTAINTY];
  [yylhsminor.yy101 addChild:yymsp[-2].minor.yy101];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= expr(%@) +/- expr(%@)", yylhsminor.yy101, yymsp[-2].minor.yy101, yymsp[0].minor.yy101);
}
#line 2161 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy101 = yylhsminor.yy101;
        break;
      case 36: /* expr ::= expr OPERATOR_PLUS expr */
#line 232 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_PLUS];
  [yylhsminor.yy101 addChild:yymsp[-2].minor.yy101];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= expr(%@)+expr(%@)", yylhsminor.yy101, yymsp[-2].minor.yy101, yymsp[0].minor.yy101);
}
#line 2172 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy101 = yylhsminor.yy101;
        break;
      case 37: /* expr ::= expr OPERATOR_PLUS2 expr */
#line 238 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_PLUS2];
  [yylhsminor.yy101 addChild:yymsp[-2].minor.yy101];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= expr(%@).+expr(%@)", yylhsminor.yy101, yymsp[-2].minor.yy101, yymsp[0].minor.yy101);
}
#line 2183 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy101 = yylhsminor.yy101;
        break;
      case 38: /* expr ::= expr OPERATOR_MINUS expr */
#line 244 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_MINUS];
  [yylhsminor.yy101 addChild:yymsp[-2].minor.yy101];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= expr(%@)-expr(%@)", yylhsminor.yy101, yymsp[-2].minor.yy101, yymsp[0].minor.yy101);
}
#line 2194 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy101 = yylhsminor.yy101;
        break;
      case 39: /* expr ::= expr OPERATOR_MINUS2 expr */
#line 250 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_MINUS2];
  [yylhsminor.yy101 addChild:yymsp[-2].minor.yy101];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= expr(%@).-expr(%@)", yylhsminor.yy101, yymsp[-2].minor.yy101, yymsp[0].minor.yy101);
}
#line 2205 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy101 = yylhsminor.yy101;
        break;
      case 40: /* expr ::= expr OPERATOR_TIMES expr */
      case 41: /* expr ::= expr INDEX_RANGE_JOKER expr */ yytestcase(yyruleno==41);
#line 256 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_TIMES];
  [yylhsminor.yy101 addChild:yymsp[-2].minor.yy101];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= expr(%@)*expr(%@)", yylhsminor.yy101, yymsp[-2].minor.yy101, yymsp[0].minor.yy101);
}
#line 2217 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy101 = yylhsminor.yy101;
        break;
      case 42: /* expr ::= expr OPERATOR_TIMES2 expr */
#line 268 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_TIMES2];
  [yylhsminor.yy101 addChild:yymsp[-2].minor.yy101];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= expr(%@).*expr(%@)", yylhsminor.yy101, yymsp[-2].minor.yy101, yymsp[0].minor.yy101);
}
#line 2228 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy101 = yylhsminor.yy101;
        break;
      case 43: /* expr ::= expr OPERATOR_DIVIDE expr */
#line 274 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_DIVIDE];
  [yylhsminor.yy101 addChild:yymsp[-2].minor.yy101];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= expr(%@)/expr(%@)", yylhsminor.yy101, yymsp[-2].minor.yy101, yymsp[0].minor.yy101);
}
#line 2239 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy101 = yylhsminor.yy101;
        break;
      case 44: /* expr ::= expr OPERATOR_DIVIDE2 expr */
#line 280 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_DIVIDE2];
  [yylhsminor.yy101 addChild:yymsp[-2].minor.yy101];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= expr(%@)./expr(%@)", yylhsminor.yy101, yymsp[-2].minor.yy101, yymsp[0].minor.yy101);
}
#line 2250 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy101 = yylhsminor.yy101;
        break;
      case 45: /* expr ::= expr OPERATOR_POW expr */
#line 286 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_POW];
  [yylhsminor.yy101 addChild:yymsp[-2].minor.yy101];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= expr(%@)^expr(%@)", yylhsminor.yy101, yymsp[-2].minor.yy101, yymsp[0].minor.yy101);
}
#line 2261 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy101 = yylhsminor.yy101;
        break;
      case 46: /* expr ::= expr OPERATOR_POW2 expr */
#line 292 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_POW2];
  [yylhsminor.yy101 addChild:yymsp[-2].minor.yy101];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= expr(%@).^expr(%@)", yylhsminor.yy101, yymsp[-2].minor.yy101, yymsp[0].minor.yy101);
}
#line 2272 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy101 = yylhsminor.yy101;
        break;
      case 47: /* expr ::= expr OPERATOR_DEGREE */
#line 298 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_OPERATOR_DEGREE];
  [yylhsminor.yy101 addChild:yymsp[-1].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= expr(%@)°", yylhsminor.yy101, yymsp[-1].minor.yy101);
}
#line 2282 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-1].minor.yy101 = yylhsminor.yy101;
        break;
      case 48: /* expr ::= expr OPERATOR_DEGREE2 */
#line 303 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_OPERATOR_DEGREE2];
  [yylhsminor.yy101 addChild:yymsp[-1].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= expr(%@).°", yylhsminor.yy101, yymsp[-1].minor.yy101);
}
#line 2292 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-1].minor.yy101 = yylhsminor.yy101;
        break;
      case 49: /* expr ::= expr OPERATOR_FACTORIAL */
#line 308 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_OPERATOR_FACTORIAL];
  [yylhsminor.yy101 addChild:yymsp[-1].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= expr(%@)!", yylhsminor.yy101, yymsp[-1].minor.yy101);
}
#line 2302 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-1].minor.yy101 = yylhsminor.yy101;
        break;
      case 50: /* expr ::= expr OPERATOR_FACTORIAL2 */
#line 313 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_OPERATOR_FACTORIAL2];
  [yylhsminor.yy101 addChild:yymsp[-1].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= expr(%@).!", yylhsminor.yy101, yymsp[-1].minor.yy101);
}
#line 2312 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-1].minor.yy101 = yylhsminor.yy101;
        break;
      case 51: /* expr ::= OPERATOR_ABS expr OPERATOR_ABS */
#line 318 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:[CHChalkToken chalkTokenUnion:@[yymsp[-2].minor.yy0,yymsp[0].minor.yy0]] operator:CHALK_LEMON_OPERATOR_ABS];
  [yylhsminor.yy101 addChild:yymsp[-1].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= |expr(%@)|", yylhsminor.yy101, yymsp[-1].minor.yy101);
}
#line 2322 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy101 = yylhsminor.yy101;
        break;
      case 52: /* expr ::= OPERATOR_NOT expr */
#line 323 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_NOT];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= !expr(%@)", yylhsminor.yy101, yymsp[0].minor.yy101);
}
#line 2332 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-1].minor.yy101 = yylhsminor.yy101;
        break;
      case 53: /* expr ::= OPERATOR_NOT2 expr */
#line 328 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_NOT2];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= .!expr(%@)", yylhsminor.yy101, yymsp[0].minor.yy101);
}
#line 2342 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-1].minor.yy101 = yylhsminor.yy101;
        break;
      case 54: /* expr ::= expr OPERATOR_LEQ expr */
#line 333 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_LEQ];
  [yylhsminor.yy101 addChild:yymsp[-2].minor.yy101];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= expr(%@) <= expr(%@)", yylhsminor.yy101, yymsp[-2].minor.yy101, yymsp[0].minor.yy101);
}
#line 2353 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy101 = yylhsminor.yy101;
        break;
      case 55: /* expr ::= expr OPERATOR_LEQ2 expr */
#line 339 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_LEQ2];
  [yylhsminor.yy101 addChild:yymsp[-2].minor.yy101];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= expr(%@) .<= expr(%@)", yylhsminor.yy101, yymsp[-2].minor.yy101, yymsp[0].minor.yy101);
}
#line 2364 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy101 = yylhsminor.yy101;
        break;
      case 56: /* expr ::= expr OPERATOR_GEQ expr */
#line 345 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_GEQ];
  [yylhsminor.yy101 addChild:yymsp[-2].minor.yy101];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= expr(%@) >= expr(%@)", yylhsminor.yy101, yymsp[-2].minor.yy101, yymsp[0].minor.yy101);
}
#line 2375 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy101 = yylhsminor.yy101;
        break;
      case 57: /* expr ::= expr OPERATOR_GEQ2 expr */
#line 351 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_GEQ2];
  [yylhsminor.yy101 addChild:yymsp[-2].minor.yy101];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= expr(%@) .>= expr(%@)", yylhsminor.yy101, yymsp[-2].minor.yy101, yymsp[0].minor.yy101);
}
#line 2386 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy101 = yylhsminor.yy101;
        break;
      case 58: /* expr ::= expr OPERATOR_LOW expr */
#line 357 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_LOW];
  [yylhsminor.yy101 addChild:yymsp[-2].minor.yy101];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= expr(%@) < expr(%@)", yylhsminor.yy101, yymsp[-2].minor.yy101, yymsp[0].minor.yy101);
}
#line 2397 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy101 = yylhsminor.yy101;
        break;
      case 59: /* expr ::= expr OPERATOR_LOW2 expr */
#line 363 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_LOW2];
  [yylhsminor.yy101 addChild:yymsp[-2].minor.yy101];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= expr(%@) .< expr(%@)", yylhsminor.yy101, yymsp[-2].minor.yy101, yymsp[0].minor.yy101);
}
#line 2408 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy101 = yylhsminor.yy101;
        break;
      case 60: /* expr ::= expr OPERATOR_GRE expr */
#line 369 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_GRE];
  [yylhsminor.yy101 addChild:yymsp[-2].minor.yy101];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= expr(%@) > expr(%@)", yylhsminor.yy101, yymsp[-2].minor.yy101, yymsp[0].minor.yy101);
}
#line 2419 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy101 = yylhsminor.yy101;
        break;
      case 61: /* expr ::= expr OPERATOR_GRE2 expr */
#line 375 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_GRE2];
  [yylhsminor.yy101 addChild:yymsp[-2].minor.yy101];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= expr(%@) .> expr(%@)", yylhsminor.yy101, yymsp[-2].minor.yy101, yymsp[0].minor.yy101);
}
#line 2430 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy101 = yylhsminor.yy101;
        break;
      case 62: /* expr ::= expr OPERATOR_EQU expr */
#line 381 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_EQU];
  [yylhsminor.yy101 addChild:yymsp[-2].minor.yy101];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= expr(%@) == expr(%@)", yylhsminor.yy101, yymsp[-2].minor.yy101, yymsp[0].minor.yy101);
}
#line 2441 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy101 = yylhsminor.yy101;
        break;
      case 63: /* expr ::= expr OPERATOR_EQU2 expr */
#line 387 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_EQU2];
  [yylhsminor.yy101 addChild:yymsp[-2].minor.yy101];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= expr(%@) .== expr(%@)", yylhsminor.yy101, yymsp[-2].minor.yy101, yymsp[0].minor.yy101);
}
#line 2452 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy101 = yylhsminor.yy101;
        break;
      case 64: /* expr ::= expr OPERATOR_NEQ expr */
#line 393 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_NEQ];
  [yylhsminor.yy101 addChild:yymsp[-2].minor.yy101];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= expr(%@) != expr(%@)", yylhsminor.yy101, yymsp[-2].minor.yy101, yymsp[0].minor.yy101);
}
#line 2463 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy101 = yylhsminor.yy101;
        break;
      case 65: /* expr ::= expr OPERATOR_NEQ2 expr */
#line 399 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_NEQ2];
  [yylhsminor.yy101 addChild:yymsp[-2].minor.yy101];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= expr(%@) .!= expr(%@)", yylhsminor.yy101, yymsp[-2].minor.yy101, yymsp[0].minor.yy101);
}
#line 2474 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy101 = yylhsminor.yy101;
        break;
      case 66: /* expr ::= expr OPERATOR_SHL expr */
#line 405 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_SHL];
  [yylhsminor.yy101 addChild:yymsp[-2].minor.yy101];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= expr(%@) SHL expr(%@)", yylhsminor.yy101, yymsp[-2].minor.yy101, yymsp[0].minor.yy101);
}
#line 2485 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy101 = yylhsminor.yy101;
        break;
      case 67: /* expr ::= expr OPERATOR_SHL2 expr */
#line 411 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_SHL2];
  [yylhsminor.yy101 addChild:yymsp[-2].minor.yy101];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= expr(%@) SHL2 expr(%@)", yylhsminor.yy101, yymsp[-2].minor.yy101, yymsp[0].minor.yy101);
}
#line 2496 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy101 = yylhsminor.yy101;
        break;
      case 68: /* expr ::= expr OPERATOR_SHR expr */
#line 417 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_SHR];
  [yylhsminor.yy101 addChild:yymsp[-2].minor.yy101];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= expr(%@) SHR expr(%@)", yylhsminor.yy101, yymsp[-2].minor.yy101, yymsp[0].minor.yy101);
}
#line 2507 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy101 = yylhsminor.yy101;
        break;
      case 69: /* expr ::= expr OPERATOR_SHR2 expr */
#line 423 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_SHR2];
  [yylhsminor.yy101 addChild:yymsp[-2].minor.yy101];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= expr(%@) SHR2 expr(%@)", yylhsminor.yy101, yymsp[-2].minor.yy101, yymsp[0].minor.yy101);
}
#line 2518 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy101 = yylhsminor.yy101;
        break;
      case 70: /* expr ::= expr OPERATOR_AND expr */
#line 429 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_AND];
  [yylhsminor.yy101 addChild:yymsp[-2].minor.yy101];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= expr(%@) AND expr(%@)", yylhsminor.yy101, yymsp[-2].minor.yy101, yymsp[0].minor.yy101);
}
#line 2529 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy101 = yylhsminor.yy101;
        break;
      case 71: /* expr ::= expr OPERATOR_AND2 expr */
#line 435 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_AND2];
  [yylhsminor.yy101 addChild:yymsp[-2].minor.yy101];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= expr(%@) .AND expr(%@)", yylhsminor.yy101, yymsp[-2].minor.yy101, yymsp[0].minor.yy101);
}
#line 2540 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy101 = yylhsminor.yy101;
        break;
      case 72: /* expr ::= expr OPERATOR_OR expr */
#line 441 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_OR];
  [yylhsminor.yy101 addChild:yymsp[-2].minor.yy101];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= expr(%@) OR expr(%@)", yylhsminor.yy101, yymsp[-2].minor.yy101, yymsp[0].minor.yy101);
}
#line 2551 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy101 = yylhsminor.yy101;
        break;
      case 73: /* expr ::= expr OPERATOR_OR2 expr */
#line 447 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_OR2];
  [yylhsminor.yy101 addChild:yymsp[-2].minor.yy101];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= expr(%@) .OR expr(%@)", yylhsminor.yy101, yymsp[-2].minor.yy101, yymsp[0].minor.yy101);
}
#line 2562 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy101 = yylhsminor.yy101;
        break;
      case 74: /* expr ::= expr OPERATOR_XOR expr */
#line 453 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_XOR];
  [yylhsminor.yy101 addChild:yymsp[-2].minor.yy101];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= expr(%@) XOR expr(%@)", yylhsminor.yy101, yymsp[-2].minor.yy101, yymsp[0].minor.yy101);
}
#line 2573 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy101 = yylhsminor.yy101;
        break;
      case 75: /* expr ::= expr OPERATOR_XOR2 expr */
#line 459 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_XOR2];
  [yylhsminor.yy101 addChild:yymsp[-2].minor.yy101];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= expr(%@) .XOR expr(%@)", yylhsminor.yy101, yymsp[-2].minor.yy101, yymsp[0].minor.yy101);
}
#line 2584 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy101 = yylhsminor.yy101;
        break;
      case 76: /* expr ::= function_call */
#line 465 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101=yymsp[0].minor.yy101;
  DebugLogStatic(1, @"expr(%@) = function_call(%@)", yylhsminor.yy101, yymsp[0].minor.yy101);
}
#line 2593 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[0].minor.yy101 = yylhsminor.yy101;
        break;
      case 77: /* expr ::= matrix */
#line 469 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101=yymsp[0].minor.yy101;
  DebugLogStatic(1, @"expr(%@) = matrix(%@)", yylhsminor.yy101, yymsp[0].minor.yy101);
}
#line 2602 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[0].minor.yy101 = yylhsminor.yy101;
        break;
      case 78: /* expr ::= list */
#line 473 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101=yymsp[0].minor.yy173;
  DebugLogStatic(1, @"expr(%@) = list(%@)", yylhsminor.yy101, yymsp[0].minor.yy173);
}
#line 2611 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[0].minor.yy101 = yylhsminor.yy101;
        break;
      case 79: /* expr ::= expr subscript */
#line 477 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy101.token operator:CHALK_LEMON_OPERATOR_SUBSCRIPT];
  [yylhsminor.yy101 addChild:yymsp[-1].minor.yy101];
  [yylhsminor.yy101 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"expr(%@) ::= expr(%@)[%@]", yylhsminor.yy101, yymsp[-1].minor.yy101, yymsp[0].minor.yy101);
}
#line 2622 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-1].minor.yy101 = yylhsminor.yy101;
        break;
      case 80: /* enumeration_element ::= expr */
#line 488 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = yymsp[0].minor.yy101;
  DebugLogStatic(1, @"enumeration_element(%@) ::= %@", yylhsminor.yy101, yymsp[0].minor.yy101);
}
#line 2631 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[0].minor.yy101 = yylhsminor.yy101;
        break;
      case 81: /* enumeration_element ::= index_range */
#line 492 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = yymsp[0].minor.yy191;
  DebugLogStatic(1, @"enumeration_element(%@) ::= %@", yylhsminor.yy101, yymsp[0].minor.yy191);
}
#line 2640 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[0].minor.yy101 = yylhsminor.yy101;
        break;
      case 82: /* enumeration ::= enumeration_element */
#line 496 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy61 = [CHParserEnumerationNode parserNodeWithToken:yymsp[0].minor.yy101.token];
  [yylhsminor.yy61 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"enumeration(%@) ::= enumeration_element(%@)", yylhsminor.yy61, yymsp[0].minor.yy101);
}
#line 2650 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[0].minor.yy61 = yylhsminor.yy61;
        break;
      case 83: /* enumeration ::= enumeration ENUMERATION_SEPARATOR enumeration_element */
#line 501 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy61=yymsp[-2].minor.yy61;
  yylhsminor.yy61.token = [CHChalkToken chalkTokenUnion:@[yymsp[-2].minor.yy61.token,yymsp[-1].minor.yy0,yymsp[0].minor.yy101.token]];
  [yylhsminor.yy61 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"enumeration(%@) ::= enumeration(%@),enumeration_element(%@)", yylhsminor.yy61, yymsp[-2].minor.yy61, yymsp[0].minor.yy101);
}
#line 2661 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy61 = yylhsminor.yy61;
        break;
      case 84: /* function_call ::= identifier PARENTHESIS_LEFT enumeration PARENTHESIS_RIGHT */
#line 508 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101=[CHParserFunctionNode parserNodeWithToken:yymsp[-3].minor.yy60.token];
  [yylhsminor.yy101 addChild:yymsp[-1].minor.yy61];
  DebugLogStatic(1, @"function_call(%@) ::= identifier(%@)(enumeration(%@))", yylhsminor.yy101, yymsp[-3].minor.yy60, yymsp[-1].minor.yy61);
}
#line 2671 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-3].minor.yy101 = yylhsminor.yy101;
        break;
      case 85: /* matrix_row_element ::= expr */
#line 518 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = yymsp[0].minor.yy101;
  DebugLogStatic(1, @"matrix_row_element(%@) ::= %@", yylhsminor.yy101, yymsp[0].minor.yy101);
}
#line 2680 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[0].minor.yy101 = yylhsminor.yy101;
        break;
      case 86: /* matrix_row_enumeration ::= matrix_row_element */
#line 522 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy6 = [CHParserMatrixRowNode parserNodeWithToken:yymsp[0].minor.yy101.token];
  [yylhsminor.yy6 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"matrix_row_enumeration(%@) ::= matrix_row_element(%@)", yylhsminor.yy6, yymsp[0].minor.yy101);
}
#line 2690 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[0].minor.yy6 = yylhsminor.yy6;
        break;
      case 87: /* matrix_row_enumeration ::= matrix_row_enumeration ENUMERATION_SEPARATOR matrix_row_element */
#line 527 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy6=yymsp[-2].minor.yy6;
  yylhsminor.yy6.token = [CHChalkToken chalkTokenUnion:@[yymsp[-2].minor.yy6.token,yymsp[-1].minor.yy0,yymsp[0].minor.yy101.token]];
  [yylhsminor.yy6 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"matrix_row_enumeration(%@) ::= matrix_row_enumeration(%@),matrix_row_element(%@)", yylhsminor.yy6, yymsp[-2].minor.yy6, yymsp[0].minor.yy101);
}
#line 2701 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy6 = yylhsminor.yy6;
        break;
      case 88: /* matrix_row ::= PARENTHESIS_LEFT matrix_row_enumeration PARENTHESIS_RIGHT */
#line 533 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = yymsp[-1].minor.yy6;
  yylhsminor.yy101.token = [CHChalkToken chalkTokenUnion:@[yymsp[-2].minor.yy0,yymsp[-1].minor.yy6.token,yymsp[0].minor.yy0]];
  DebugLogStatic(1, @"matrix_row(%@) ::= (matrix_row_enumeration(%@))", yylhsminor.yy101, yymsp[-1].minor.yy6);
}
#line 2711 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy101 = yylhsminor.yy101;
        break;
      case 89: /* matrix_rows ::= matrix_row */
#line 538 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy194 = [CHParserMatrixNode parserNodeWithToken:yymsp[0].minor.yy101.token];
  [yylhsminor.yy194 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"matrix_rows(%@) ::= (matrix_row_enumeration(%@))", yylhsminor.yy194, yymsp[0].minor.yy101);
}
#line 2721 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[0].minor.yy194 = yylhsminor.yy194;
        break;
      case 90: /* matrix_rows ::= matrix_rows matrix_row */
#line 543 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy194 = yymsp[-1].minor.yy194;
  yylhsminor.yy194.token = [CHChalkToken chalkTokenUnion:@[yymsp[-1].minor.yy194.token,yymsp[0].minor.yy101.token]];
  [yylhsminor.yy194 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"matrix_rows(%@) ::= matrix_rows(%@) %@", yylhsminor.yy194, yymsp[-1].minor.yy194, yymsp[0].minor.yy101);
}
#line 2732 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-1].minor.yy194 = yylhsminor.yy194;
        break;
      case 91: /* matrix ::= PARENTHESIS_LEFT matrix_rows PARENTHESIS_RIGHT */
#line 549 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy101 = yymsp[-1].minor.yy194;
  yylhsminor.yy101.token = [CHChalkToken chalkTokenUnion:@[yymsp[-2].minor.yy0,yymsp[-1].minor.yy194.token,yymsp[0].minor.yy0]];
  DebugLogStatic(1, @"matrix(%@) ::= (matrix_row(%@))", yylhsminor.yy101, yymsp[-1].minor.yy194);
}
#line 2742 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy101 = yylhsminor.yy101;
        break;
      case 92: /* list ::= LIST_LEFT_DELIMITER enumeration LIST_RIGHT_DELIMITER */
#line 555 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy173=[CHParserListNode parserNodeWithToken:[CHChalkToken chalkTokenUnion:@[yymsp[-2].minor.yy0,yymsp[-1].minor.yy61.token,yymsp[0].minor.yy0]]];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy61];
  DebugLogStatic(1, @"list(%@) ::= {enumeration(%@)}", yylhsminor.yy173, yymsp[-1].minor.yy61);
}
#line 2752 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy173 = yylhsminor.yy173;
        break;
      case 93: /* assignation ::= expr OPERATOR_ASSIGN expr */
#line 561 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy29=[CHParserAssignationNode parserNodeWithToken:yymsp[-1].minor.yy0];
  [yylhsminor.yy29 addChild:yymsp[-2].minor.yy101];
  [yylhsminor.yy29 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"assignation(%@) ::= identifier(%@) <- %@", yylhsminor.yy29, yymsp[-2].minor.yy101, yymsp[0].minor.yy101);
}
#line 2763 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy29 = yylhsminor.yy29;
        break;
      case 94: /* assignation ::= expr OPERATOR_ASSIGN_DYNAMIC expr */
#line 568 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"
{
  yylhsminor.yy29=[CHParserAssignationDynamicNode parserNodeWithToken:yymsp[-1].minor.yy0];
  [yylhsminor.yy29 addChild:yymsp[-2].minor.yy101];
  [yylhsminor.yy29 addChild:yymsp[0].minor.yy101];
  DebugLogStatic(1, @"assignation_dynamic(%@) ::= identifier(%@) <-= %@", yylhsminor.yy29, yymsp[-2].minor.yy101, yymsp[0].minor.yy101);
}
#line 2774 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
  yymsp[-2].minor.yy29 = yylhsminor.yy29;
        break;
      default:
        break;
/********** End reduce actions ************************************************/
  };
  assert( yyruleno<sizeof(yyRuleInfoLhs)/sizeof(yyRuleInfoLhs[0]) );
  yygoto = yyRuleInfoLhs[yyruleno];
  yysize = yyRuleInfoNRhs[yyruleno];
  yyact = yy_find_reduce_action(yymsp[yysize].stateno,(YYCODETYPE)yygoto);

  /* There are no SHIFTREDUCE actions on nonterminals because the table
  ** generator has simplified them to pure REDUCE actions. */
  assert( !(yyact>YY_MAX_SHIFT && yyact<=YY_MAX_SHIFTREDUCE) );

  /* It is not possible for a REDUCE to be followed by an error */
  assert( yyact!=YY_ERROR_ACTION );

  yymsp += yysize+1;
  yypParser->yytos = yymsp;
  yymsp->stateno = (YYACTIONTYPE)yyact;
  yymsp->major = (YYCODETYPE)yygoto;
  yyTraceShift(yypParser, yyact, "... then shift");
  return yyact;
}

/*
** The following code executes when the parse fails
*/
#ifndef YYNOERRORRECOVERY
static void yy_parse_failed(
  yyParser *yypParser           /* The parser */
){
  ParseARG_FETCH
  ParseCTX_FETCH
#ifndef NDEBUG
  if( yyTraceFILE ){
    fprintf(yyTraceFILE,"%sFail!\n",yyTracePrompt);
  }
#endif
  while( yypParser->yytos>yypParser->yystack ) yy_pop_parser_stack(yypParser);
  /* Here code is inserted which will be executed whenever the
  ** parser fails */
/************ Begin %parse_failure code ***************************************/
#line 32 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"

  DebugLogStatic(0, @"lemon parse failure");
  context.stop = YES;
#line 2823 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
/************ End %parse_failure code *****************************************/
  ParseARG_STORE /* Suppress warning about unused %extra_argument variable */
  ParseCTX_STORE
}
#endif /* YYNOERRORRECOVERY */

/*
** The following code executes when a syntax error first occurs.
*/
static void yy_syntax_error(
  yyParser *yypParser,           /* The parser */
  int yymajor,                   /* The major type of the error token */
  ParseTOKENTYPE yyminor         /* The minor type of the error token */
){
  ParseARG_FETCH
  ParseCTX_FETCH
#define TOKEN yyminor
/************ Begin %syntax_error code ****************************************/
#line 36 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.lemon"

  DebugLogStatic(0, @"lemon syntax error");
  context.stop = YES;
#line 2846 "/Users/chacha/Programmation/Cocoa/Projets/Applications/Chalk/Chalk/chalk-parser.c"
/************ End %syntax_error code ******************************************/
  ParseARG_STORE /* Suppress warning about unused %extra_argument variable */
  ParseCTX_STORE
}

/*
** The following is executed when the parser accepts
*/
static void yy_accept(
  yyParser *yypParser           /* The parser */
){
  ParseARG_FETCH
  ParseCTX_FETCH
#ifndef NDEBUG
  if( yyTraceFILE ){
    fprintf(yyTraceFILE,"%sAccept!\n",yyTracePrompt);
  }
#endif
#ifndef YYNOERRORRECOVERY
  yypParser->yyerrcnt = -1;
#endif
  assert( yypParser->yytos==yypParser->yystack );
  /* Here code is inserted which will be executed whenever the
  ** parser accepts */
/*********** Begin %parse_accept code *****************************************/
/*********** End %parse_accept code *******************************************/
  ParseARG_STORE /* Suppress warning about unused %extra_argument variable */
  ParseCTX_STORE
}

/* The main parser program.
** The first argument is a pointer to a structure obtained from
** "ParseAlloc" which describes the current state of the parser.
** The second argument is the major token number.  The third is
** the minor token.  The fourth optional argument is whatever the
** user wants (and specified in the grammar) and is available for
** use by the action routines.
**
** Inputs:
** <ul>
** <li> A pointer to the parser (an opaque structure.)
** <li> The major token number.
** <li> The minor token number.
** <li> An option argument of a grammar-specified type.
** </ul>
**
** Outputs:
** None.
*/
void Parse(
  void *yyp,                   /* The parser */
  int yymajor,                 /* The major token code number */
  ParseTOKENTYPE yyminor       /* The value for the token */
  ParseARG_PDECL               /* Optional %extra_argument parameter */
){
  YYMINORTYPE yyminorunion;
  YYACTIONTYPE yyact;   /* The parser action. */
#if !defined(YYERRORSYMBOL) && !defined(YYNOERRORRECOVERY)
  int yyendofinput;     /* True if we are at the end of input */
#endif
#ifdef YYERRORSYMBOL
  int yyerrorhit = 0;   /* True if yymajor has invoked an error */
#endif
  yyParser *yypParser = (yyParser*)yyp;  /* The parser */
  ParseCTX_FETCH
  ParseARG_STORE

  assert( yypParser->yytos!=0 );
#if !defined(YYERRORSYMBOL) && !defined(YYNOERRORRECOVERY)
  yyendofinput = (yymajor==0);
#endif

  yyact = yypParser->yytos->stateno;
#ifndef NDEBUG
  if( yyTraceFILE ){
    if( yyact < YY_MIN_REDUCE ){
      fprintf(yyTraceFILE,"%sInput '%s' in state %d\n",
              yyTracePrompt,yyTokenName[yymajor],yyact);
    }else{
      fprintf(yyTraceFILE,"%sInput '%s' with pending reduce %d\n",
              yyTracePrompt,yyTokenName[yymajor],yyact-YY_MIN_REDUCE);
    }
  }
#endif

  do{
    assert( yyact==yypParser->yytos->stateno );
    yyact = yy_find_shift_action((YYCODETYPE)yymajor,yyact);
    if( yyact >= YY_MIN_REDUCE ){
      yyact = yy_reduce(yypParser,yyact-YY_MIN_REDUCE,yymajor,
                        yyminor ParseCTX_PARAM);
    }else if( yyact <= YY_MAX_SHIFTREDUCE ){
      yy_shift(yypParser,yyact,(YYCODETYPE)yymajor,yyminor);
#ifndef YYNOERRORRECOVERY
      yypParser->yyerrcnt--;
#endif
      break;
    }else if( yyact==YY_ACCEPT_ACTION ){
      yypParser->yytos--;
      yy_accept(yypParser);
      return;
    }else{
      assert( yyact == YY_ERROR_ACTION );
      yyminorunion.yy0 = yyminor;
#ifdef YYERRORSYMBOL
      int yymx;
#endif
#ifndef NDEBUG
      if( yyTraceFILE ){
        fprintf(yyTraceFILE,"%sSyntax Error!\n",yyTracePrompt);
      }
#endif
#ifdef YYERRORSYMBOL
      /* A syntax error has occurred.
      ** The response to an error depends upon whether or not the
      ** grammar defines an error token "ERROR".  
      **
      ** This is what we do if the grammar does define ERROR:
      **
      **  * Call the %syntax_error function.
      **
      **  * Begin popping the stack until we enter a state where
      **    it is legal to shift the error symbol, then shift
      **    the error symbol.
      **
      **  * Set the error count to three.
      **
      **  * Begin accepting and shifting new tokens.  No new error
      **    processing will occur until three tokens have been
      **    shifted successfully.
      **
      */
      if( yypParser->yyerrcnt<0 ){
        yy_syntax_error(yypParser,yymajor,yyminor);
      }
      yymx = yypParser->yytos->major;
      if( yymx==YYERRORSYMBOL || yyerrorhit ){
#ifndef NDEBUG
        if( yyTraceFILE ){
          fprintf(yyTraceFILE,"%sDiscard input token %s\n",
             yyTracePrompt,yyTokenName[yymajor]);
        }
#endif
        yy_destructor(yypParser, (YYCODETYPE)yymajor, &yyminorunion);
        yymajor = YYNOCODE;
      }else{
        while( yypParser->yytos >= yypParser->yystack
            && (yyact = yy_find_reduce_action(
                        yypParser->yytos->stateno,
                        YYERRORSYMBOL)) > YY_MAX_SHIFTREDUCE
        ){
          yy_pop_parser_stack(yypParser);
        }
        if( yypParser->yytos < yypParser->yystack || yymajor==0 ){
          yy_destructor(yypParser,(YYCODETYPE)yymajor,&yyminorunion);
          yy_parse_failed(yypParser);
#ifndef YYNOERRORRECOVERY
          yypParser->yyerrcnt = -1;
#endif
          yymajor = YYNOCODE;
        }else if( yymx!=YYERRORSYMBOL ){
          yy_shift(yypParser,yyact,YYERRORSYMBOL,yyminor);
        }
      }
      yypParser->yyerrcnt = 3;
      yyerrorhit = 1;
      if( yymajor==YYNOCODE ) break;
      yyact = yypParser->yytos->stateno;
#elif defined(YYNOERRORRECOVERY)
      /* If the YYNOERRORRECOVERY macro is defined, then do not attempt to
      ** do any kind of error recovery.  Instead, simply invoke the syntax
      ** error routine and continue going as if nothing had happened.
      **
      ** Applications can set this macro (for example inside %include) if
      ** they intend to abandon the parse upon the first syntax error seen.
      */
      yy_syntax_error(yypParser,yymajor, yyminor);
      yy_destructor(yypParser,(YYCODETYPE)yymajor,&yyminorunion);
      break;
#else  /* YYERRORSYMBOL is not defined */
      /* This is what we do if the grammar does not define ERROR:
      **
      **  * Report an error message, and throw away the input token.
      **
      **  * If the input token is $, then fail the parse.
      **
      ** As before, subsequent error messages are suppressed until
      ** three input tokens have been successfully shifted.
      */
      if( yypParser->yyerrcnt<=0 ){
        yy_syntax_error(yypParser,yymajor, yyminor);
      }
      yypParser->yyerrcnt = 3;
      yy_destructor(yypParser,(YYCODETYPE)yymajor,&yyminorunion);
      if( yyendofinput ){
        yy_parse_failed(yypParser);
#ifndef YYNOERRORRECOVERY
        yypParser->yyerrcnt = -1;
#endif
      }
      break;
#endif
    }
  }while( yypParser->yytos>yypParser->yystack );
#ifndef NDEBUG
  if( yyTraceFILE ){
    yyStackEntry *i;
    char cDiv = '[';
    fprintf(yyTraceFILE,"%sReturn. Stack=",yyTracePrompt);
    for(i=&yypParser->yystack[1]; i<=yypParser->yytos; i++){
      fprintf(yyTraceFILE,"%c%s", cDiv, yyTokenName[i->major]);
      cDiv = ' ';
    }
    fprintf(yyTraceFILE,"]\n");
  }
#endif
  return;
}

/*
** Return the fallback token corresponding to canonical token iToken, or
** 0 if iToken has no fallback.
*/
int ParseFallback(int iToken){
#ifdef YYFALLBACK
  assert( iToken<(int)(sizeof(yyFallback)/sizeof(yyFallback[0])) );
  return yyFallback[iToken];
#else
  (void)iToken;
  return 0;
#endif
}
