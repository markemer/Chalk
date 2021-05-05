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
#include <assert.h>
#include "chalk-parser-rpn.h"
#include "CHChalkToken.h"
#include "CHParserContext.h"
#include "CHParserNode.h"
#include "CHParserAssignationNode.h"
#include "CHParserAssignationDynamicNode.h"
#include "CHParserEnumerationNode.h"
#include "CHParserFunctionNode.h"
#include "CHParserIdentifierNode.h"
#include "CHParserIfThenElseNode.h"
#include "CHParserListNode.h"
#include "CHParserMatrixNode.h"
#include "CHParserMatrixRowNode.h"
#include "CHParserOperatorNode.h"
#include "CHParserSubscriptNode.h"
#include "CHParserValueIndexRangeNode.h"
#include "CHParserValueNode.h"
#include "CHParserValueNumberNode.h"
#include "CHParserValueNumberIntegerNode.h"
#include "CHParserValueNumberRealNode.h"
#include "CHParserValueNumberIntervalNode.h"
#include "CHParserValueNumberPerFractionNode.h"
#include "CHParserValueStringNode.h"
#include "CHUtils.h"
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
**    Parse_rpnTOKENTYPE     is the data type used for minor type for terminal
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
**                       which is Parse_rpnTOKENTYPE.  The entry in the union
**                       for terminal symbols is called "yy0".
**    YYSTACKDEPTH       is the maximum depth of the parser's stack.  If
**                       zero the stack is dynamically sized using realloc()
**    Parse_rpnARG_SDECL     A static variable declaration for the %extra_argument
**    Parse_rpnARG_PDECL     A parameter declaration for the %extra_argument
**    Parse_rpnARG_PARAM     Code to pass %extra_argument as a subroutine parameter
**    Parse_rpnARG_STORE     Code to store %extra_argument into yypParser
**    Parse_rpnARG_FETCH     Code to extract %extra_argument from yypParser
**    Parse_rpnCTX_*         As Parse_rpnARG_ except for %extra_context
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
#define YYNOCODE 99
#define YYACTIONTYPE unsigned short int
#define Parse_rpnTOKENTYPE CHChalkToken*
typedef union {
  int yyinit;
  Parse_rpnTOKENTYPE yy0;
  CHParserValueNumberRealNode* yy1;
  CHParserAssignationNode* yy29;
  CHParserIdentifierNode* yy30;
  CHParserValueIndexRangeNode* yy41;
  CHParserValueNumberIntervalNode* yy52;
  CHParserMatrixNode* yy62;
  CHParserValueNode* yy68;
  CHParserEnumerationNode* yy96;
  CHParserValueNumberNode* yy115;
  CHParserValueStringNode* yy163;
  CHParserListNode* yy167;
  CHParserNode* yy173;
  CHParserValueNumberIntegerNode* yy189;
  CHParserMatrixRowNode* yy198;
} YYMINORTYPE;
#ifndef YYSTACKDEPTH
#define YYSTACKDEPTH 100
#endif
#define Parse_rpnARG_SDECL CHParserContext* context;
#define Parse_rpnARG_PDECL ,CHParserContext* context
#define Parse_rpnARG_PARAM ,context
#define Parse_rpnARG_FETCH CHParserContext* context=yypParser->context;
#define Parse_rpnARG_STORE yypParser->context=context;
#define Parse_rpnCTX_SDECL
#define Parse_rpnCTX_PDECL
#define Parse_rpnCTX_PARAM
#define Parse_rpnCTX_FETCH
#define Parse_rpnCTX_STORE
#define YYNSTATE             54
#define YYNRULE              90
#define YYNRULE_WITH_ACTION  90
#define YYNTOKEN             74
#define YY_MAX_SHIFT         53
#define YY_MIN_SHIFTREDUCE   130
#define YY_MAX_SHIFTREDUCE   219
#define YY_ERROR_ACTION      220
#define YY_ACCEPT_ACTION     221
#define YY_NO_ACTION         222
#define YY_MIN_REDUCE        223
#define YY_MAX_REDUCE        312
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
#define YY_ACTTAB_COUNT (1237)
static const YYACTIONTYPE yy_action[] = {
 /*     0 */   308,  226,  224,  191,  192,  193,  194,  197,  198,  199,
 /*    10 */   200,  195,  196,  179,  180,  181,  182,  183,  184,  185,
 /*    20 */   186,   33,  188,  189,  190,   36,  161,  162,  163,  164,
 /*    30 */   168,  169,  165,  167,  166,  170,  171,   35,   34,  154,
 /*    40 */   222,  222,  222,  222,  174,  175,    2,  172,  173,  222,
 /*    50 */   222,   41,  222,  222,   38,  222,  132,  132,  135,  222,
 /*    60 */    46,  142,    5,    6,    6,  144,    8,  222,  155,  156,
 /*    70 */   157,  158,    3,  223,   32,   31,    7,  216,  149,   28,
 /*    80 */   222,  229,  209,  230,  238,  239,  241,   52,  243,    6,
 /*    90 */   296,   45,   49,    4,   33,   12,  222,  213,   36,  222,
 /*   100 */   294,  295,  222,  304,  307,  222,  222,  222,  222,  222,
 /*   110 */    35,   34,  154,  217,  222,  222,  222,  174,  175,    2,
 /*   120 */   172,  173,  222,  222,   41,  222,  222,   38,  222,  132,
 /*   130 */   222,  135,   33,  222,  142,    5,   36,  222,  144,    8,
 /*   140 */   222,  155,  156,  157,  158,    3,  222,  222,   35,   34,
 /*   150 */   154,  222,  222,  222,  222,  174,  175,    2,  172,  173,
 /*   160 */   222,  222,   41,  222,  222,   38,  222,  132,  222,  135,
 /*   170 */   222,   33,  142,    5,   42,   36,  144,    8,  222,  155,
 /*   180 */   156,  157,  158,    3,  222,  222,  222,   35,   34,  154,
 /*   190 */   222,  222,  222,  222,  174,  175,    2,  172,  173,  222,
 /*   200 */   222,   41,  222,  222,   38,  222,  132,  222,  135,   33,
 /*   210 */   222,  142,    5,   36,  222,  144,    8,  153,  155,  156,
 /*   220 */   157,  158,    3,  222,  222,   35,   34,  154,  222,  222,
 /*   230 */   222,  222,  174,  175,    2,  172,  173,  222,  222,   41,
 /*   240 */   222,  222,   38,   37,  132,  222,  135,   33,  222,  142,
 /*   250 */     5,   36,  222,  144,    8,  222,  155,  156,  157,  158,
 /*   260 */     3,  222,  222,   35,   34,  154,  222,  222,  222,  222,
 /*   270 */   174,  175,    2,  172,  173,  222,  222,   41,  222,   39,
 /*   280 */    38,  222,  132,  222,  135,   33,  222,  142,    5,   36,
 /*   290 */   222,  144,    8,  222,  155,  156,  157,  158,    3,  222,
 /*   300 */   222,   35,   34,  154,  222,  222,  222,  222,  174,  175,
 /*   310 */     2,  172,  173,  222,  222,   41,   40,  222,   38,  222,
 /*   320 */   132,  222,  135,   33,  222,  142,    5,   36,  222,  144,
 /*   330 */     8,  222,  155,  156,  157,  158,    3,  222,  222,   35,
 /*   340 */    34,  154,  222,  222,  222,  222,  174,  175,    2,  172,
 /*   350 */   173,  222,  222,   41,  222,  222,   38,  222,  132,  222,
 /*   360 */   135,   33,  222,  142,    5,   36,  143,  144,    8,  222,
 /*   370 */   155,  156,  157,  158,    3,  222,  222,   35,   34,  154,
 /*   380 */   222,  222,  222,  222,  174,  175,    2,  172,  173,  222,
 /*   390 */   222,   41,  222,  222,   38,  222,  132,  222,  135,  220,
 /*   400 */   222,  142,    5,   36,  222,  144,    8,  222,  155,  156,
 /*   410 */   157,  158,    3,  222,  222,   35,   34,  154,  222,  222,
 /*   420 */   222,  222,  174,  175,    2,  172,  173,  222,  222,   41,
 /*   430 */   222,  222,   38,  222,  132,  222,  135,   33,  222,  142,
 /*   440 */     5,   44,  222,  144,    8,  222,  155,  156,  157,  158,
 /*   450 */     3,  222,  222,   35,   34,  154,  222,  222,  222,  222,
 /*   460 */   174,  175,    2,  172,  173,  222,  222,   41,  222,  222,
 /*   470 */    38,  222,  132,  222,  135,  222,  222,  142,    5,  222,
 /*   480 */   222,  144,    8,  222,  155,  156,  157,  158,    3,  222,
 /*   490 */   222,   35,   34,  154,  222,  222,  222,  222,  174,  175,
 /*   500 */     2,  172,  173,  222,  222,   41,  222,  222,   38,  222,
 /*   510 */   132,  222,  135,  222,  222,  142,    5,  222,  222,  144,
 /*   520 */     8,  222,  155,  156,  157,  158,    3,  222,  222,  172,
 /*   530 */   173,  222,  222,   41,  222,  222,   38,  222,  132,  222,
 /*   540 */   135,  222,  222,  142,    5,  222,  222,  144,    8,  222,
 /*   550 */   155,  156,  157,  158,    3,  222,  222,  222,  229,  222,
 /*   560 */   230,  238,  239,  241,   52,  243,  222,  296,  222,  222,
 /*   570 */   222,  222,   27,  233,  234,  252,  222,  294,  295,  222,
 /*   580 */   222,   53,  299,  230,  238,  239,  241,   52,  243,   50,
 /*   590 */   296,  222,  222,  222,  222,   22,  222,  222,  222,  222,
 /*   600 */   294,  295,  300,  222,  222,   53,  299,  230,  238,  239,
 /*   610 */   241,   52,  243,   48,  296,  222,  222,  222,  222,   22,
 /*   620 */   222,  222,  222,  222,  294,  295,  300,   53,  299,  230,
 /*   630 */   238,  239,  241,   52,  243,   47,  296,  222,  222,  222,
 /*   640 */   222,   11,  222,  222,  222,  222,  294,  295,  300,  229,
 /*   650 */   222,  230,  238,  239,  241,   52,  243,  222,  296,   36,
 /*   660 */   222,   51,  221,   10,  222,  222,  222,  222,  294,  295,
 /*   670 */   222,   35,   34,  222,  222,  222,  222,  222,  222,  222,
 /*   680 */   222,  222,  222,  222,  222,   41,  222,  222,  222,  222,
 /*   690 */   132,  222,  135,  138,  139,  142,   43,  222,  222,  144,
 /*   700 */     8,  222,  222,  222,  222,  222,    3,   53,  299,  230,
 /*   710 */   238,  239,  241,   52,  243,  222,  296,  222,  222,  222,
 /*   720 */   222,   22,  222,  222,  222,  222,  294,  295,  301,  229,
 /*   730 */   222,  230,  238,  239,  241,   52,  243,  222,  296,  222,
 /*   740 */    49,  222,  222,   21,  222,  222,  222,  222,  294,  295,
 /*   750 */   222,  304,  222,  222,  222,  222,  222,  222,  222,  222,
 /*   760 */    36,  229,  222,  230,  238,  239,  241,   52,  243,  134,
 /*   770 */   296,   45,   35,   34,  222,   13,  222,  222,  222,  222,
 /*   780 */   294,  295,  222,  222,  307,  222,   41,  222,  222,  222,
 /*   790 */   222,  132,  222,  135,  222,  222,  142,   43,  222,  222,
 /*   800 */   144,    8,  222,  222,  222,  222,  222,    3,  229,  222,
 /*   810 */   230,  238,  239,  241,   52,  243,  222,  296,  222,  222,
 /*   820 */   222,  222,    9,  222,  222,  222,  297,  294,  295,  222,
 /*   830 */   222,  222,  222,  222,   36,  222,  229,  222,  230,  238,
 /*   840 */   239,  241,   52,  243,  222,  296,   35,   34,  222,  222,
 /*   850 */    21,  222,  222,  222,  222,  294,  295,  222,  305,  222,
 /*   860 */    41,  222,  222,  222,   36,  132,  222,  135,  222,  222,
 /*   870 */   142,   43,  222,  222,  144,    8,   35,   34,  222,  222,
 /*   880 */   222,    3,  222,  222,  222,  222,  222,  222,  222,  222,
 /*   890 */    41,  222,  222,  222,  222,  132,  222,  135,  222,  222,
 /*   900 */   142,   43,  222,  222,  144,    1,  222,  132,  222,  135,
 /*   910 */   222,    3,  142,    5,  222,  222,  144,    8,  222,  155,
 /*   920 */   156,  157,  158,    3,  222,  222,  222,  222,  222,  222,
 /*   930 */   222,  229,  222,  230,  238,  239,  241,   52,  243,  222,
 /*   940 */   296,  222,  222,  222,  222,   19,  222,  222,  222,  222,
 /*   950 */   294,  295,  229,  222,  230,  238,  239,  241,   52,  243,
 /*   960 */   222,  296,  222,  222,  222,  222,   20,  222,  222,  222,
 /*   970 */   222,  294,  295,  229,  222,  230,  238,  239,  241,   52,
 /*   980 */   243,  222,  296,  222,  222,  222,  222,   23,  222,  222,
 /*   990 */   222,  222,  294,  295,  222,  229,  222,  230,  238,  239,
 /*  1000 */   241,   52,  243,  222,  296,  222,  222,  222,  222,   25,
 /*  1010 */   222,  222,  222,  222,  294,  295,  229,  222,  230,  238,
 /*  1020 */   239,  241,   52,  243,  222,  296,  222,  222,  222,  222,
 /*  1030 */    26,  222,  222,  222,  222,  294,  295,  229,  222,  230,
 /*  1040 */   238,  239,  241,   52,  243,  222,  296,  222,  222,  222,
 /*  1050 */   222,   24,  222,  222,  222,  222,  294,  295,  229,  222,
 /*  1060 */   230,  238,  239,  241,   52,  243,  222,  296,  222,  222,
 /*  1070 */   222,  222,   29,  222,  222,  222,  222,  294,  295,  222,
 /*  1080 */   229,  222,  230,  238,  239,  241,   52,  243,  222,  296,
 /*  1090 */   222,  222,  222,  222,   14,  222,  222,  222,  222,  294,
 /*  1100 */   295,  229,  222,  230,  238,  239,  241,   52,  243,  222,
 /*  1110 */   296,  222,  222,  222,  222,   30,  222,  222,  222,  222,
 /*  1120 */   294,  295,  229,  222,  230,  238,  239,  241,   52,  243,
 /*  1130 */   222,  296,  222,  222,  222,  222,   15,  222,  222,  222,
 /*  1140 */   222,  294,  295,  229,  222,  230,  238,  239,  241,   52,
 /*  1150 */   243,  222,  296,  222,  222,  222,  222,   16,  222,  222,
 /*  1160 */   222,  222,  294,  295,  222,  229,  222,  230,  238,  239,
 /*  1170 */   241,   52,  243,  222,  296,  222,  222,  222,  222,   17,
 /*  1180 */   222,  222,  222,  222,  294,  295,  229,  222,  230,  238,
 /*  1190 */   239,  241,   52,  243,  222,  296,  222,  222,  222,  222,
 /*  1200 */    18,   35,   34,  222,  222,  294,  295,  222,  222,  222,
 /*  1210 */   222,  222,  222,  222,  222,   41,  222,  222,  222,  222,
 /*  1220 */   132,  222,  135,  222,  222,  142,   43,  222,  222,  144,
 /*  1230 */     8,  222,  222,  222,  222,  222,    3,
};
static const YYCODETYPE yy_lookahead[] = {
 /*     0 */    98,   75,    0,    3,    4,    5,    6,    7,    8,    9,
 /*    10 */    10,   11,   12,   13,   14,   15,   16,   17,   18,   19,
 /*    20 */    20,   21,   22,   23,   24,   25,   26,   27,   28,   29,
 /*    30 */    30,   31,   32,   33,   34,   35,   36,   37,   38,   39,
 /*    40 */    99,   99,   99,   99,   44,   45,   46,   47,   48,   99,
 /*    50 */    99,   51,   99,   99,   54,   99,   56,   56,   58,   99,
 /*    60 */    57,   61,   62,   49,   49,   65,   66,   99,   68,   69,
 /*    70 */    70,   71,   72,    0,    1,    2,   66,   67,   64,   49,
 /*    80 */    99,   75,   67,   77,   78,   79,   80,   81,   82,   49,
 /*    90 */    84,   85,   86,   66,   21,   89,   99,   67,   25,   99,
 /*   100 */    94,   95,   99,   97,   98,   99,   99,   99,   99,   99,
 /*   110 */    37,   38,   39,   73,   99,   99,   99,   44,   45,   46,
 /*   120 */    47,   48,   99,   99,   51,   99,   99,   54,   99,   56,
 /*   130 */    99,   58,   21,   99,   61,   62,   25,   99,   65,   66,
 /*   140 */    99,   68,   69,   70,   71,   72,   99,   99,   37,   38,
 /*   150 */    39,   99,   99,   99,   99,   44,   45,   46,   47,   48,
 /*   160 */    99,   99,   51,   99,   99,   54,   99,   56,   99,   58,
 /*   170 */    99,   21,   61,   62,   63,   25,   65,   66,   99,   68,
 /*   180 */    69,   70,   71,   72,   99,   99,   99,   37,   38,   39,
 /*   190 */    99,   99,   99,   99,   44,   45,   46,   47,   48,   99,
 /*   200 */    99,   51,   99,   99,   54,   99,   56,   99,   58,   21,
 /*   210 */    99,   61,   62,   25,   99,   65,   66,   67,   68,   69,
 /*   220 */    70,   71,   72,   99,   99,   37,   38,   39,   99,   99,
 /*   230 */    99,   99,   44,   45,   46,   47,   48,   99,   99,   51,
 /*   240 */    99,   99,   54,   55,   56,   99,   58,   21,   99,   61,
 /*   250 */    62,   25,   99,   65,   66,   99,   68,   69,   70,   71,
 /*   260 */    72,   99,   99,   37,   38,   39,   99,   99,   99,   99,
 /*   270 */    44,   45,   46,   47,   48,   99,   99,   51,   99,   53,
 /*   280 */    54,   99,   56,   99,   58,   21,   99,   61,   62,   25,
 /*   290 */    99,   65,   66,   99,   68,   69,   70,   71,   72,   99,
 /*   300 */    99,   37,   38,   39,   99,   99,   99,   99,   44,   45,
 /*   310 */    46,   47,   48,   99,   99,   51,   52,   99,   54,   99,
 /*   320 */    56,   99,   58,   21,   99,   61,   62,   25,   99,   65,
 /*   330 */    66,   99,   68,   69,   70,   71,   72,   99,   99,   37,
 /*   340 */    38,   39,   99,   99,   99,   99,   44,   45,   46,   47,
 /*   350 */    48,   99,   99,   51,   99,   99,   54,   99,   56,   99,
 /*   360 */    58,   21,   99,   61,   62,   25,   64,   65,   66,   99,
 /*   370 */    68,   69,   70,   71,   72,   99,   99,   37,   38,   39,
 /*   380 */    99,   99,   99,   99,   44,   45,   46,   47,   48,   99,
 /*   390 */    99,   51,   99,   99,   54,   99,   56,   99,   58,   21,
 /*   400 */    99,   61,   62,   25,   99,   65,   66,   99,   68,   69,
 /*   410 */    70,   71,   72,   99,   99,   37,   38,   39,   99,   99,
 /*   420 */    99,   99,   44,   45,   46,   47,   48,   99,   99,   51,
 /*   430 */    99,   99,   54,   99,   56,   99,   58,   21,   99,   61,
 /*   440 */    62,   25,   99,   65,   66,   99,   68,   69,   70,   71,
 /*   450 */    72,   99,   99,   37,   38,   39,   99,   99,   99,   99,
 /*   460 */    44,   45,   46,   47,   48,   99,   99,   51,   99,   99,
 /*   470 */    54,   99,   56,   99,   58,   99,   99,   61,   62,   99,
 /*   480 */    99,   65,   66,   99,   68,   69,   70,   71,   72,   99,
 /*   490 */    99,   37,   38,   39,   99,   99,   99,   99,   44,   45,
 /*   500 */    46,   47,   48,   99,   99,   51,   99,   99,   54,   99,
 /*   510 */    56,   99,   58,   99,   99,   61,   62,   99,   99,   65,
 /*   520 */    66,   99,   68,   69,   70,   71,   72,   99,   99,   47,
 /*   530 */    48,   99,   99,   51,   99,   99,   54,   99,   56,   99,
 /*   540 */    58,   99,   99,   61,   62,   99,   99,   65,   66,   99,
 /*   550 */    68,   69,   70,   71,   72,   99,   99,   99,   75,   99,
 /*   560 */    77,   78,   79,   80,   81,   82,   99,   84,   99,   99,
 /*   570 */    99,   99,   89,   90,   91,   92,   99,   94,   95,   99,
 /*   580 */    99,   75,   76,   77,   78,   79,   80,   81,   82,   83,
 /*   590 */    84,   99,   99,   99,   99,   89,   99,   99,   99,   99,
 /*   600 */    94,   95,   96,   99,   99,   75,   76,   77,   78,   79,
 /*   610 */    80,   81,   82,   83,   84,   99,   99,   99,   99,   89,
 /*   620 */    99,   99,   99,   99,   94,   95,   96,   75,   76,   77,
 /*   630 */    78,   79,   80,   81,   82,   83,   84,   99,   99,   99,
 /*   640 */    99,   89,   99,   99,   99,   99,   94,   95,   96,   75,
 /*   650 */    99,   77,   78,   79,   80,   81,   82,   99,   84,   25,
 /*   660 */    99,   87,   88,   89,   99,   99,   99,   99,   94,   95,
 /*   670 */    99,   37,   38,   99,   99,   99,   99,   99,   99,   99,
 /*   680 */    99,   99,   99,   99,   99,   51,   99,   99,   99,   99,
 /*   690 */    56,   99,   58,   59,   60,   61,   62,   99,   99,   65,
 /*   700 */    66,   99,   99,   99,   99,   99,   72,   75,   76,   77,
 /*   710 */    78,   79,   80,   81,   82,   99,   84,   99,   99,   99,
 /*   720 */    99,   89,   99,   99,   99,   99,   94,   95,   96,   75,
 /*   730 */    99,   77,   78,   79,   80,   81,   82,   99,   84,   99,
 /*   740 */    86,   99,   99,   89,   99,   99,   99,   99,   94,   95,
 /*   750 */    99,   97,   99,   99,   99,   99,   99,   99,   99,   99,
 /*   760 */    25,   75,   99,   77,   78,   79,   80,   81,   82,   34,
 /*   770 */    84,   85,   37,   38,   99,   89,   99,   99,   99,   99,
 /*   780 */    94,   95,   99,   99,   98,   99,   51,   99,   99,   99,
 /*   790 */    99,   56,   99,   58,   99,   99,   61,   62,   99,   99,
 /*   800 */    65,   66,   99,   99,   99,   99,   99,   72,   75,   99,
 /*   810 */    77,   78,   79,   80,   81,   82,   99,   84,   99,   99,
 /*   820 */    99,   99,   89,   99,   99,   99,   93,   94,   95,   99,
 /*   830 */    99,   99,   99,   99,   25,   99,   75,   99,   77,   78,
 /*   840 */    79,   80,   81,   82,   99,   84,   37,   38,   99,   99,
 /*   850 */    89,   99,   99,   99,   99,   94,   95,   99,   97,   99,
 /*   860 */    51,   99,   99,   99,   25,   56,   99,   58,   99,   99,
 /*   870 */    61,   62,   99,   99,   65,   66,   37,   38,   99,   99,
 /*   880 */    99,   72,   99,   99,   99,   99,   99,   99,   99,   99,
 /*   890 */    51,   99,   99,   99,   99,   56,   99,   58,   99,   99,
 /*   900 */    61,   62,   99,   99,   65,   66,   99,   56,   99,   58,
 /*   910 */    99,   72,   61,   62,   99,   99,   65,   66,   99,   68,
 /*   920 */    69,   70,   71,   72,   99,   99,   99,   99,   99,   99,
 /*   930 */    99,   75,   99,   77,   78,   79,   80,   81,   82,   99,
 /*   940 */    84,   99,   99,   99,   99,   89,   99,   99,   99,   99,
 /*   950 */    94,   95,   75,   99,   77,   78,   79,   80,   81,   82,
 /*   960 */    99,   84,   99,   99,   99,   99,   89,   99,   99,   99,
 /*   970 */    99,   94,   95,   75,   99,   77,   78,   79,   80,   81,
 /*   980 */    82,   99,   84,   99,   99,   99,   99,   89,   99,   99,
 /*   990 */    99,   99,   94,   95,   99,   75,   99,   77,   78,   79,
 /*  1000 */    80,   81,   82,   99,   84,   99,   99,   99,   99,   89,
 /*  1010 */    99,   99,   99,   99,   94,   95,   75,   99,   77,   78,
 /*  1020 */    79,   80,   81,   82,   99,   84,   99,   99,   99,   99,
 /*  1030 */    89,   99,   99,   99,   99,   94,   95,   75,   99,   77,
 /*  1040 */    78,   79,   80,   81,   82,   99,   84,   99,   99,   99,
 /*  1050 */    99,   89,   99,   99,   99,   99,   94,   95,   75,   99,
 /*  1060 */    77,   78,   79,   80,   81,   82,   99,   84,   99,   99,
 /*  1070 */    99,   99,   89,   99,   99,   99,   99,   94,   95,   99,
 /*  1080 */    75,   99,   77,   78,   79,   80,   81,   82,   99,   84,
 /*  1090 */    99,   99,   99,   99,   89,   99,   99,   99,   99,   94,
 /*  1100 */    95,   75,   99,   77,   78,   79,   80,   81,   82,   99,
 /*  1110 */    84,   99,   99,   99,   99,   89,   99,   99,   99,   99,
 /*  1120 */    94,   95,   75,   99,   77,   78,   79,   80,   81,   82,
 /*  1130 */    99,   84,   99,   99,   99,   99,   89,   99,   99,   99,
 /*  1140 */    99,   94,   95,   75,   99,   77,   78,   79,   80,   81,
 /*  1150 */    82,   99,   84,   99,   99,   99,   99,   89,   99,   99,
 /*  1160 */    99,   99,   94,   95,   99,   75,   99,   77,   78,   79,
 /*  1170 */    80,   81,   82,   99,   84,   99,   99,   99,   99,   89,
 /*  1180 */    99,   99,   99,   99,   94,   95,   75,   99,   77,   78,
 /*  1190 */    79,   80,   81,   82,   99,   84,   99,   99,   99,   99,
 /*  1200 */    89,   37,   38,   99,   99,   94,   95,   99,   99,   99,
 /*  1210 */    99,   99,   99,   99,   99,   51,   99,   99,   99,   99,
 /*  1220 */    56,   99,   58,   99,   99,   61,   62,   99,   99,   65,
 /*  1230 */    66,   99,   99,   99,   99,   99,   72,   99,   99,   99,
 /*  1240 */    99,   99,   99,   99,   99,   99,   99,   99,   99,   99,
 /*  1250 */    99,   99,   99,   99,   99,   99,   99,   99,   99,   99,
 /*  1260 */    99,   99,   99,   99,   99,   99,   99,   99,   99,   99,
 /*  1270 */    99,   99,   99,   99,   99,   99,   74,   74,   74,   74,
 /*  1280 */    74,   74,   74,   74,   74,   74,   74,   74,   74,   74,
 /*  1290 */    74,   74,   74,   74,   74,   74,   74,   74,   74,   74,
 /*  1300 */    74,   74,   74,   74,   74,   74,   74,   74,   74,   74,
 /*  1310 */    74,
};
#define YY_SHIFT_COUNT    (53)
#define YY_SHIFT_MIN      (0)
#define YY_SHIFT_MAX      (1164)
static const unsigned short int yy_shift_ofst[] = {
 /*     0 */   809,  839,  634,  735,  735,  735,  735,  809,  839,    0,
 /*    10 */    73,  111,  150,  150,  188,  226,  264,  302,  111,  340,
 /*    20 */   340,  340,  340,  378,  416,  454,  454,  482,  809,  851,
 /*    30 */   851,  809,  809,  809,  809,  809,  809,  809,  809,  809,
 /*    40 */   809,  809,  809,  809, 1164,   10,    1,   14,   15,   30,
 /*    50 */    40,    2,   27,    3,
};
#define YY_REDUCE_COUNT (46)
#define YY_REDUCE_MIN   (-98)
#define YY_REDUCE_MAX   (1111)
static const short yy_reduce_ofst[] = {
 /*     0 */   574,    6,  483,  506,  530,  552,  632,  654,  686,  733,
 /*    10 */   733,  733,  733,  733,  733,  733,  733,  733,  733,  733,
 /*    20 */   733,  733,  733,  733,  733,  733,  733,  733,  761,  733,
 /*    30 */   733,  856,  877,  898,  920,  941,  962,  983, 1005, 1026,
 /*    40 */  1047, 1068, 1090, 1111,  962,  -98,  -74,
};
static const YYACTIONTYPE yy_default[] = {
 /*     0 */   220,  220,  220,  220,  220,  220,  220,  220,  220,  220,
 /*    10 */   220,  298,  303,  220,  220,  220,  220,  220,  220,  312,
 /*    20 */   311,  303,  298,  280,  220,  271,  270,  253,  220,  245,
 /*    30 */   244,  220,  220,  220,  220,  220,  220,  220,  220,  220,
 /*    40 */   220,  220,  220,  220,  269,  220,  220,  220,  220,  220,
 /*    50 */   220,  220,  240,  229,
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
  Parse_rpnARG_SDECL                /* A place to hold %extra_argument */
  Parse_rpnCTX_SDECL                /* A place to hold %extra_context */
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
void Parse_rpnTrace(FILE *TraceFILE, char *zTracePrompt){
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
  /*   44 */ "OPERATOR_FACTORIAL",
  /*   45 */ "OPERATOR_FACTORIAL2",
  /*   46 */ "OPERATOR_UNCERTAINTY",
  /*   47 */ "OPERATOR_DEGREE",
  /*   48 */ "OPERATOR_DEGREE2",
  /*   49 */ "ENUMERATION_SEPARATOR",
  /*   50 */ "OPERATOR_SUBSCRIPT",
  /*   51 */ "IF",
  /*   52 */ "THEN",
  /*   53 */ "ELSE",
  /*   54 */ "QUESTION",
  /*   55 */ "ALTERNATE",
  /*   56 */ "INTEGER_POSITIVE",
  /*   57 */ "INDEX_RANGE_OPERATOR",
  /*   58 */ "REAL_POSITIVE",
  /*   59 */ "INTEGER_PER_FRACTION",
  /*   60 */ "REAL_PER_FRACTION",
  /*   61 */ "STRING_QUOTED",
  /*   62 */ "INTERVAL_LEFT_DELIMITER",
  /*   63 */ "INTERVAL_ITEM_SEPARATOR",
  /*   64 */ "INTERVAL_RIGHT_DELIMITER",
  /*   65 */ "IDENTIFIER",
  /*   66 */ "PARENTHESIS_LEFT",
  /*   67 */ "PARENTHESIS_RIGHT",
  /*   68 */ "OPERATOR_MINUS_SQRT",
  /*   69 */ "OPERATOR_MINUS_SQRT2",
  /*   70 */ "OPERATOR_MINUS_CBRT",
  /*   71 */ "OPERATOR_MINUS_CBRT2",
  /*   72 */ "LIST_LEFT_DELIMITER",
  /*   73 */ "LIST_RIGHT_DELIMITER",
  /*   74 */ "context",
  /*   75 */ "integer",
  /*   76 */ "index_range",
  /*   77 */ "real",
  /*   78 */ "number",
  /*   79 */ "string_quoted",
  /*   80 */ "interval",
  /*   81 */ "identifier",
  /*   82 */ "value",
  /*   83 */ "enumeration",
  /*   84 */ "list",
  /*   85 */ "matrix_rows",
  /*   86 */ "matrix_row_enumeration",
  /*   87 */ "assignation",
  /*   88 */ "command",
  /*   89 */ "expr",
  /*   90 */ "integer_per_fraction",
  /*   91 */ "real_per_fraction",
  /*   92 */ "number_per_fraction",
  /*   93 */ "subscript",
  /*   94 */ "function_call",
  /*   95 */ "matrix",
  /*   96 */ "enumeration_element",
  /*   97 */ "matrix_row_element",
  /*   98 */ "matrix_row",
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
 /*  24 */ "expr ::= expr OPERATOR_MINUS_UNARY",
 /*  25 */ "expr ::= expr OPERATOR_MINUS_SQRT",
 /*  26 */ "expr ::= expr OPERATOR_MINUS_SQRT2",
 /*  27 */ "expr ::= expr OPERATOR_MINUS_CBRT",
 /*  28 */ "expr ::= expr OPERATOR_MINUS_CBRT2",
 /*  29 */ "expr ::= expr OPERATOR_UNCERTAINTY number_per_fraction",
 /*  30 */ "expr ::= expr OPERATOR_UNCERTAINTY expr",
 /*  31 */ "expr ::= expr expr OPERATOR_PLUS",
 /*  32 */ "expr ::= expr expr OPERATOR_PLUS2",
 /*  33 */ "expr ::= expr expr OPERATOR_MINUS",
 /*  34 */ "expr ::= expr expr OPERATOR_MINUS2",
 /*  35 */ "expr ::= expr expr OPERATOR_TIMES",
 /*  36 */ "expr ::= expr expr INDEX_RANGE_JOKER",
 /*  37 */ "expr ::= expr expr OPERATOR_TIMES2",
 /*  38 */ "expr ::= expr expr OPERATOR_DIVIDE",
 /*  39 */ "expr ::= expr expr OPERATOR_DIVIDE2",
 /*  40 */ "expr ::= expr expr OPERATOR_POW",
 /*  41 */ "expr ::= expr expr OPERATOR_POW2",
 /*  42 */ "expr ::= expr OPERATOR_DEGREE",
 /*  43 */ "expr ::= expr OPERATOR_DEGREE2",
 /*  44 */ "expr ::= expr OPERATOR_FACTORIAL",
 /*  45 */ "expr ::= expr OPERATOR_FACTORIAL2",
 /*  46 */ "expr ::= OPERATOR_ABS expr OPERATOR_ABS",
 /*  47 */ "expr ::= OPERATOR_NOT expr",
 /*  48 */ "expr ::= OPERATOR_NOT2 expr",
 /*  49 */ "expr ::= expr expr OPERATOR_LEQ",
 /*  50 */ "expr ::= expr expr OPERATOR_LEQ2",
 /*  51 */ "expr ::= expr expr OPERATOR_GEQ",
 /*  52 */ "expr ::= expr expr OPERATOR_GEQ2",
 /*  53 */ "expr ::= expr expr OPERATOR_LOW",
 /*  54 */ "expr ::= expr expr OPERATOR_LOW2",
 /*  55 */ "expr ::= expr expr OPERATOR_GRE",
 /*  56 */ "expr ::= expr expr OPERATOR_GRE2",
 /*  57 */ "expr ::= expr OPERATOR_EQU expr",
 /*  58 */ "expr ::= expr expr OPERATOR_EQU2",
 /*  59 */ "expr ::= expr expr OPERATOR_NEQ",
 /*  60 */ "expr ::= expr expr OPERATOR_NEQ2",
 /*  61 */ "expr ::= expr expr OPERATOR_SHL",
 /*  62 */ "expr ::= expr expr OPERATOR_SHL2",
 /*  63 */ "expr ::= expr expr OPERATOR_SHR",
 /*  64 */ "expr ::= expr expr OPERATOR_SHR2",
 /*  65 */ "expr ::= expr expr OPERATOR_AND",
 /*  66 */ "expr ::= expr expr OPERATOR_AND2",
 /*  67 */ "expr ::= expr expr OPERATOR_OR",
 /*  68 */ "expr ::= expr expr OPERATOR_OR2",
 /*  69 */ "expr ::= expr expr OPERATOR_XOR",
 /*  70 */ "expr ::= expr expr OPERATOR_XOR2",
 /*  71 */ "expr ::= function_call",
 /*  72 */ "expr ::= matrix",
 /*  73 */ "expr ::= list",
 /*  74 */ "expr ::= expr subscript",
 /*  75 */ "enumeration_element ::= expr",
 /*  76 */ "enumeration_element ::= index_range",
 /*  77 */ "enumeration ::= enumeration_element",
 /*  78 */ "enumeration ::= enumeration ENUMERATION_SEPARATOR enumeration_element",
 /*  79 */ "function_call ::= identifier PARENTHESIS_LEFT enumeration PARENTHESIS_RIGHT",
 /*  80 */ "matrix_row_element ::= expr",
 /*  81 */ "matrix_row_enumeration ::= matrix_row_element",
 /*  82 */ "matrix_row_enumeration ::= matrix_row_enumeration ENUMERATION_SEPARATOR matrix_row_element",
 /*  83 */ "matrix_row ::= PARENTHESIS_LEFT matrix_row_enumeration PARENTHESIS_RIGHT",
 /*  84 */ "matrix_rows ::= matrix_row",
 /*  85 */ "matrix_rows ::= matrix_rows matrix_row",
 /*  86 */ "matrix ::= PARENTHESIS_LEFT matrix_rows PARENTHESIS_RIGHT",
 /*  87 */ "list ::= LIST_LEFT_DELIMITER enumeration LIST_RIGHT_DELIMITER",
 /*  88 */ "assignation ::= expr OPERATOR_ASSIGN expr",
 /*  89 */ "assignation ::= expr OPERATOR_ASSIGN_DYNAMIC expr",
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
** second argument to Parse_rpnAlloc() below.  This can be changed by
** putting an appropriate #define in the %include section of the input
** grammar.
*/
#ifndef YYMALLOCARGTYPE
# define YYMALLOCARGTYPE size_t
#endif

/* Initialize a new parser that has already been allocated.
*/
void Parse_rpnInit(void *yypRawParser Parse_rpnCTX_PDECL){
  yyParser *yypParser = (yyParser*)yypRawParser;
  Parse_rpnCTX_STORE
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

#ifndef Parse_rpn_ENGINEALWAYSONSTACK
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
** to Parse_rpn and Parse_rpnFree.
*/
void *Parse_rpnAlloc(void *(*mallocProc)(YYMALLOCARGTYPE) Parse_rpnCTX_PDECL){
  yyParser *yypParser;
  yypParser = (yyParser*)(*mallocProc)( (YYMALLOCARGTYPE)sizeof(yyParser) );
  if( yypParser ){
    Parse_rpnCTX_STORE
    Parse_rpnInit(yypParser Parse_rpnCTX_PARAM);
  }
  return (void*)yypParser;
}
#endif /* Parse_rpn_ENGINEALWAYSONSTACK */


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
  Parse_rpnARG_FETCH
  Parse_rpnCTX_FETCH
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

  context = 0;//prevent compile warning

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
void Parse_rpnFinalize(void *p){
  yyParser *pParser = (yyParser*)p;
  while( pParser->yytos>pParser->yystack ) yy_pop_parser_stack(pParser);
#if YYSTACKDEPTH<=0
  if( pParser->yystack!=&pParser->yystk0 ) free(pParser->yystack);
#endif
}

#ifndef Parse_rpn_ENGINEALWAYSONSTACK
/* 
** Deallocate and destroy a parser.  Destructors are called for
** all stack elements before shutting the parser down.
**
** If the YYPARSEFREENEVERNULL macro exists (for example because it
** is defined in a %include section of the input grammar) then it is
** assumed that the input pointer is never NULL.
*/
void Parse_rpnFree(
  void *p,                    /* The parser to be deleted */
  void (*freeProc)(void*)     /* Function used to reclaim memory */
){
#ifndef YYPARSEFREENEVERNULL
  if( p==0 ) return;
#endif
  Parse_rpnFinalize(p);
  (*freeProc)(p);
}
#endif /* Parse_rpn_ENGINEALWAYSONSTACK */

/*
** Return the peak depth of the stack for a parser.
*/
#ifdef YYTRACKMAXSTACKDEPTH
int Parse_rpnStackPeak(void *p){
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
int Parse_rpnCoverage(FILE *out){
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
   Parse_rpnARG_FETCH
   Parse_rpnCTX_FETCH
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
   Parse_rpnARG_STORE /* Suppress warning about unused %extra_argument var */
   Parse_rpnCTX_STORE
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
  Parse_rpnTOKENTYPE yyMinor        /* The minor token to shift in */
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
    88,  /* (0) command ::= expr */
    88,  /* (1) command ::= assignation */
    75,  /* (2) integer ::= INTEGER_POSITIVE */
    76,  /* (3) index_range ::= integer INDEX_RANGE_OPERATOR integer */
    76,  /* (4) index_range ::= INDEX_RANGE_JOKER */
    77,  /* (5) real ::= REAL_POSITIVE */
    78,  /* (6) number ::= integer */
    78,  /* (7) number ::= real */
    90,  /* (8) integer_per_fraction ::= INTEGER_PER_FRACTION */
    91,  /* (9) real_per_fraction ::= REAL_PER_FRACTION */
    92,  /* (10) number_per_fraction ::= integer_per_fraction */
    92,  /* (11) number_per_fraction ::= real_per_fraction */
    79,  /* (12) string_quoted ::= STRING_QUOTED */
    80,  /* (13) interval ::= INTERVAL_LEFT_DELIMITER expr INTERVAL_ITEM_SEPARATOR expr INTERVAL_RIGHT_DELIMITER */
    81,  /* (14) identifier ::= IDENTIFIER */
    82,  /* (15) value ::= number */
    82,  /* (16) value ::= string_quoted */
    82,  /* (17) value ::= identifier */
    82,  /* (18) value ::= interval */
    93,  /* (19) subscript ::= INTERVAL_LEFT_DELIMITER enumeration INTERVAL_RIGHT_DELIMITER */
    89,  /* (20) expr ::= value */
    89,  /* (21) expr ::= IF expr THEN expr ELSE expr */
    89,  /* (22) expr ::= expr QUESTION expr ALTERNATE expr */
    89,  /* (23) expr ::= PARENTHESIS_LEFT expr PARENTHESIS_RIGHT */
    89,  /* (24) expr ::= expr OPERATOR_MINUS_UNARY */
    89,  /* (25) expr ::= expr OPERATOR_MINUS_SQRT */
    89,  /* (26) expr ::= expr OPERATOR_MINUS_SQRT2 */
    89,  /* (27) expr ::= expr OPERATOR_MINUS_CBRT */
    89,  /* (28) expr ::= expr OPERATOR_MINUS_CBRT2 */
    89,  /* (29) expr ::= expr OPERATOR_UNCERTAINTY number_per_fraction */
    89,  /* (30) expr ::= expr OPERATOR_UNCERTAINTY expr */
    89,  /* (31) expr ::= expr expr OPERATOR_PLUS */
    89,  /* (32) expr ::= expr expr OPERATOR_PLUS2 */
    89,  /* (33) expr ::= expr expr OPERATOR_MINUS */
    89,  /* (34) expr ::= expr expr OPERATOR_MINUS2 */
    89,  /* (35) expr ::= expr expr OPERATOR_TIMES */
    89,  /* (36) expr ::= expr expr INDEX_RANGE_JOKER */
    89,  /* (37) expr ::= expr expr OPERATOR_TIMES2 */
    89,  /* (38) expr ::= expr expr OPERATOR_DIVIDE */
    89,  /* (39) expr ::= expr expr OPERATOR_DIVIDE2 */
    89,  /* (40) expr ::= expr expr OPERATOR_POW */
    89,  /* (41) expr ::= expr expr OPERATOR_POW2 */
    89,  /* (42) expr ::= expr OPERATOR_DEGREE */
    89,  /* (43) expr ::= expr OPERATOR_DEGREE2 */
    89,  /* (44) expr ::= expr OPERATOR_FACTORIAL */
    89,  /* (45) expr ::= expr OPERATOR_FACTORIAL2 */
    89,  /* (46) expr ::= OPERATOR_ABS expr OPERATOR_ABS */
    89,  /* (47) expr ::= OPERATOR_NOT expr */
    89,  /* (48) expr ::= OPERATOR_NOT2 expr */
    89,  /* (49) expr ::= expr expr OPERATOR_LEQ */
    89,  /* (50) expr ::= expr expr OPERATOR_LEQ2 */
    89,  /* (51) expr ::= expr expr OPERATOR_GEQ */
    89,  /* (52) expr ::= expr expr OPERATOR_GEQ2 */
    89,  /* (53) expr ::= expr expr OPERATOR_LOW */
    89,  /* (54) expr ::= expr expr OPERATOR_LOW2 */
    89,  /* (55) expr ::= expr expr OPERATOR_GRE */
    89,  /* (56) expr ::= expr expr OPERATOR_GRE2 */
    89,  /* (57) expr ::= expr OPERATOR_EQU expr */
    89,  /* (58) expr ::= expr expr OPERATOR_EQU2 */
    89,  /* (59) expr ::= expr expr OPERATOR_NEQ */
    89,  /* (60) expr ::= expr expr OPERATOR_NEQ2 */
    89,  /* (61) expr ::= expr expr OPERATOR_SHL */
    89,  /* (62) expr ::= expr expr OPERATOR_SHL2 */
    89,  /* (63) expr ::= expr expr OPERATOR_SHR */
    89,  /* (64) expr ::= expr expr OPERATOR_SHR2 */
    89,  /* (65) expr ::= expr expr OPERATOR_AND */
    89,  /* (66) expr ::= expr expr OPERATOR_AND2 */
    89,  /* (67) expr ::= expr expr OPERATOR_OR */
    89,  /* (68) expr ::= expr expr OPERATOR_OR2 */
    89,  /* (69) expr ::= expr expr OPERATOR_XOR */
    89,  /* (70) expr ::= expr expr OPERATOR_XOR2 */
    89,  /* (71) expr ::= function_call */
    89,  /* (72) expr ::= matrix */
    89,  /* (73) expr ::= list */
    89,  /* (74) expr ::= expr subscript */
    96,  /* (75) enumeration_element ::= expr */
    96,  /* (76) enumeration_element ::= index_range */
    83,  /* (77) enumeration ::= enumeration_element */
    83,  /* (78) enumeration ::= enumeration ENUMERATION_SEPARATOR enumeration_element */
    94,  /* (79) function_call ::= identifier PARENTHESIS_LEFT enumeration PARENTHESIS_RIGHT */
    97,  /* (80) matrix_row_element ::= expr */
    86,  /* (81) matrix_row_enumeration ::= matrix_row_element */
    86,  /* (82) matrix_row_enumeration ::= matrix_row_enumeration ENUMERATION_SEPARATOR matrix_row_element */
    98,  /* (83) matrix_row ::= PARENTHESIS_LEFT matrix_row_enumeration PARENTHESIS_RIGHT */
    85,  /* (84) matrix_rows ::= matrix_row */
    85,  /* (85) matrix_rows ::= matrix_rows matrix_row */
    95,  /* (86) matrix ::= PARENTHESIS_LEFT matrix_rows PARENTHESIS_RIGHT */
    84,  /* (87) list ::= LIST_LEFT_DELIMITER enumeration LIST_RIGHT_DELIMITER */
    87,  /* (88) assignation ::= expr OPERATOR_ASSIGN expr */
    87,  /* (89) assignation ::= expr OPERATOR_ASSIGN_DYNAMIC expr */
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
   -2,  /* (24) expr ::= expr OPERATOR_MINUS_UNARY */
   -2,  /* (25) expr ::= expr OPERATOR_MINUS_SQRT */
   -2,  /* (26) expr ::= expr OPERATOR_MINUS_SQRT2 */
   -2,  /* (27) expr ::= expr OPERATOR_MINUS_CBRT */
   -2,  /* (28) expr ::= expr OPERATOR_MINUS_CBRT2 */
   -3,  /* (29) expr ::= expr OPERATOR_UNCERTAINTY number_per_fraction */
   -3,  /* (30) expr ::= expr OPERATOR_UNCERTAINTY expr */
   -3,  /* (31) expr ::= expr expr OPERATOR_PLUS */
   -3,  /* (32) expr ::= expr expr OPERATOR_PLUS2 */
   -3,  /* (33) expr ::= expr expr OPERATOR_MINUS */
   -3,  /* (34) expr ::= expr expr OPERATOR_MINUS2 */
   -3,  /* (35) expr ::= expr expr OPERATOR_TIMES */
   -3,  /* (36) expr ::= expr expr INDEX_RANGE_JOKER */
   -3,  /* (37) expr ::= expr expr OPERATOR_TIMES2 */
   -3,  /* (38) expr ::= expr expr OPERATOR_DIVIDE */
   -3,  /* (39) expr ::= expr expr OPERATOR_DIVIDE2 */
   -3,  /* (40) expr ::= expr expr OPERATOR_POW */
   -3,  /* (41) expr ::= expr expr OPERATOR_POW2 */
   -2,  /* (42) expr ::= expr OPERATOR_DEGREE */
   -2,  /* (43) expr ::= expr OPERATOR_DEGREE2 */
   -2,  /* (44) expr ::= expr OPERATOR_FACTORIAL */
   -2,  /* (45) expr ::= expr OPERATOR_FACTORIAL2 */
   -3,  /* (46) expr ::= OPERATOR_ABS expr OPERATOR_ABS */
   -2,  /* (47) expr ::= OPERATOR_NOT expr */
   -2,  /* (48) expr ::= OPERATOR_NOT2 expr */
   -3,  /* (49) expr ::= expr expr OPERATOR_LEQ */
   -3,  /* (50) expr ::= expr expr OPERATOR_LEQ2 */
   -3,  /* (51) expr ::= expr expr OPERATOR_GEQ */
   -3,  /* (52) expr ::= expr expr OPERATOR_GEQ2 */
   -3,  /* (53) expr ::= expr expr OPERATOR_LOW */
   -3,  /* (54) expr ::= expr expr OPERATOR_LOW2 */
   -3,  /* (55) expr ::= expr expr OPERATOR_GRE */
   -3,  /* (56) expr ::= expr expr OPERATOR_GRE2 */
   -3,  /* (57) expr ::= expr OPERATOR_EQU expr */
   -3,  /* (58) expr ::= expr expr OPERATOR_EQU2 */
   -3,  /* (59) expr ::= expr expr OPERATOR_NEQ */
   -3,  /* (60) expr ::= expr expr OPERATOR_NEQ2 */
   -3,  /* (61) expr ::= expr expr OPERATOR_SHL */
   -3,  /* (62) expr ::= expr expr OPERATOR_SHL2 */
   -3,  /* (63) expr ::= expr expr OPERATOR_SHR */
   -3,  /* (64) expr ::= expr expr OPERATOR_SHR2 */
   -3,  /* (65) expr ::= expr expr OPERATOR_AND */
   -3,  /* (66) expr ::= expr expr OPERATOR_AND2 */
   -3,  /* (67) expr ::= expr expr OPERATOR_OR */
   -3,  /* (68) expr ::= expr expr OPERATOR_OR2 */
   -3,  /* (69) expr ::= expr expr OPERATOR_XOR */
   -3,  /* (70) expr ::= expr expr OPERATOR_XOR2 */
   -1,  /* (71) expr ::= function_call */
   -1,  /* (72) expr ::= matrix */
   -1,  /* (73) expr ::= list */
   -2,  /* (74) expr ::= expr subscript */
   -1,  /* (75) enumeration_element ::= expr */
   -1,  /* (76) enumeration_element ::= index_range */
   -1,  /* (77) enumeration ::= enumeration_element */
   -3,  /* (78) enumeration ::= enumeration ENUMERATION_SEPARATOR enumeration_element */
   -4,  /* (79) function_call ::= identifier PARENTHESIS_LEFT enumeration PARENTHESIS_RIGHT */
   -1,  /* (80) matrix_row_element ::= expr */
   -1,  /* (81) matrix_row_enumeration ::= matrix_row_element */
   -3,  /* (82) matrix_row_enumeration ::= matrix_row_enumeration ENUMERATION_SEPARATOR matrix_row_element */
   -3,  /* (83) matrix_row ::= PARENTHESIS_LEFT matrix_row_enumeration PARENTHESIS_RIGHT */
   -1,  /* (84) matrix_rows ::= matrix_row */
   -2,  /* (85) matrix_rows ::= matrix_rows matrix_row */
   -3,  /* (86) matrix ::= PARENTHESIS_LEFT matrix_rows PARENTHESIS_RIGHT */
   -3,  /* (87) list ::= LIST_LEFT_DELIMITER enumeration LIST_RIGHT_DELIMITER */
   -3,  /* (88) assignation ::= expr OPERATOR_ASSIGN expr */
   -3,  /* (89) assignation ::= expr OPERATOR_ASSIGN_DYNAMIC expr */
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
  Parse_rpnTOKENTYPE yyLookaheadToken  /* Value of the lookahead token */
  Parse_rpnCTX_PDECL                   /* %extra_context */
){
  int yygoto;                     /* The next state */
  YYACTIONTYPE yyact;             /* The next action */
  yyStackEntry *yymsp;            /* The top of the parser's stack */
  int yysize;                     /* Amount to pop the stack */
  Parse_rpnARG_FETCH
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
  **     { ... }           // User supplied code
  **     break;
  */
/********** Begin reduce actions **********************************************/
        YYMINORTYPE yylhsminor;
      case 0: /* command ::= expr */
{
  yylhsminor.yy173=yymsp[0].minor.yy173;
  NSLog(@"command(%@) = expr(%@)\n", yylhsminor.yy173, yymsp[0].minor.yy173);
  [context.parserListener parserContext:context didEncounterRootNode:yylhsminor.yy173];
}
  yymsp[0].minor.yy173 = yylhsminor.yy173;
        break;
      case 1: /* command ::= assignation */
{
  yylhsminor.yy173=yymsp[0].minor.yy29;
  NSLog(@"command(%@) = assignation(%@)\n", yylhsminor.yy173, yymsp[0].minor.yy29);
  [context.parserListener parserContext:context didEncounterRootNode:yylhsminor.yy173];
}
  yymsp[0].minor.yy173 = yylhsminor.yy173;
        break;
      case 2: /* integer ::= INTEGER_POSITIVE */
{
  yylhsminor.yy189=[CHParserValueNumberIntegerNode parserNodeWithToken:yymsp[0].minor.yy0];
  NSLog(@"%@ ::= INTEGER_POSITIVE(%@)", yylhsminor.yy189, yymsp[0].minor.yy0);
}
  yymsp[0].minor.yy189 = yylhsminor.yy189;
        break;
      case 3: /* index_range ::= integer INDEX_RANGE_OPERATOR integer */
{
  yylhsminor.yy41=[CHParserValueIndexRangeNode parserNodeWithToken:[CHChalkToken chalkTokenUnion:@[yymsp[-2].minor.yy189.token,yymsp[-1].minor.yy0,yymsp[0].minor.yy189.token]]];
  [yylhsminor.yy41 addChild:yymsp[-2].minor.yy189];
  [yylhsminor.yy41 addChild:yymsp[0].minor.yy189];
  NSLog(@"index_range(%@) ::= {index_range(%@, %@, %@)}", yylhsminor.yy41, yymsp[-2].minor.yy189, yymsp[-1].minor.yy0, yymsp[0].minor.yy189);
}
  yymsp[-2].minor.yy41 = yylhsminor.yy41;
        break;
      case 4: /* index_range ::= INDEX_RANGE_JOKER */
{
  yylhsminor.yy41=[CHParserValueIndexRangeNode parserNodeWithToken:yymsp[0].minor.yy0 joker:YES];
  NSLog(@"index_range(%@) ::= {index_range(%@)}", yylhsminor.yy41, yymsp[0].minor.yy0);
}
  yymsp[0].minor.yy41 = yylhsminor.yy41;
        break;
      case 5: /* real ::= REAL_POSITIVE */
{
  yylhsminor.yy1=[CHParserValueNumberRealNode parserNodeWithToken:yymsp[0].minor.yy0];
  NSLog(@"%@ ::= REAL_POSITIVE(%@)", yylhsminor.yy1, yymsp[0].minor.yy0);
}
  yymsp[0].minor.yy1 = yylhsminor.yy1;
        break;
      case 6: /* number ::= integer */
{yylhsminor.yy115=yymsp[0].minor.yy189;}
  yymsp[0].minor.yy115 = yylhsminor.yy115;
        break;
      case 7: /* number ::= real */
{yylhsminor.yy115=yymsp[0].minor.yy1;}
  yymsp[0].minor.yy115 = yylhsminor.yy115;
        break;
      case 8: /* integer_per_fraction ::= INTEGER_PER_FRACTION */
{
  yylhsminor.yy173=[CHParserValueNumberPerFractionNode parserNodeWithToken:yymsp[0].minor.yy0];
  DebugLogStatic(1, @"%@ ::= INTEGER_PER_FRACTION(%@)", yylhsminor.yy173, yymsp[0].minor.yy0);
}
  yymsp[0].minor.yy173 = yylhsminor.yy173;
        break;
      case 9: /* real_per_fraction ::= REAL_PER_FRACTION */
{
  yylhsminor.yy173=[CHParserValueNumberPerFractionNode parserNodeWithToken:yymsp[0].minor.yy0];
  DebugLogStatic(1, @"%@ ::= REAL_PER_FRACTION(%@)", yylhsminor.yy173, yymsp[0].minor.yy0);
}
  yymsp[0].minor.yy173 = yylhsminor.yy173;
        break;
      case 10: /* number_per_fraction ::= integer_per_fraction */
      case 11: /* number_per_fraction ::= real_per_fraction */ yytestcase(yyruleno==11);
{yylhsminor.yy173=yymsp[0].minor.yy173;}
  yymsp[0].minor.yy173 = yylhsminor.yy173;
        break;
      case 12: /* string_quoted ::= STRING_QUOTED */
{
  yylhsminor.yy163=[CHParserValueStringNode parserNodeWithToken:yymsp[0].minor.yy0];
  NSLog(@"%@ ::= \"%@\"", yylhsminor.yy163, yymsp[0].minor.yy0);
}
  yymsp[0].minor.yy163 = yylhsminor.yy163;
        break;
      case 13: /* interval ::= INTERVAL_LEFT_DELIMITER expr INTERVAL_ITEM_SEPARATOR expr INTERVAL_RIGHT_DELIMITER */
{
  yylhsminor.yy52=[CHParserValueNumberIntervalNode parserNodeWithToken:[CHChalkToken chalkTokenUnion:@[yymsp[-4].minor.yy0,yymsp[-3].minor.yy173.token,yymsp[-2].minor.yy0,yymsp[-1].minor.yy173.token,yymsp[0].minor.yy0]]];
  [yylhsminor.yy52 addChild:yymsp[-3].minor.yy173];
  [yylhsminor.yy52 addChild:yymsp[-1].minor.yy173];
  NSLog(@"interval(%@) ::= {interval([%@;%@])}", yylhsminor.yy52, yymsp[-3].minor.yy173, yymsp[-1].minor.yy173);
}
  yymsp[-4].minor.yy52 = yylhsminor.yy52;
        break;
      case 14: /* identifier ::= IDENTIFIER */
{
  yylhsminor.yy30=[CHParserIdentifierNode parserNodeWithToken:yymsp[0].minor.yy0];
  NSLog(@"%@ ::= IDENTIFIER(%@)", yylhsminor.yy30, yymsp[0].minor.yy0);
}
  yymsp[0].minor.yy30 = yylhsminor.yy30;
        break;
      case 15: /* value ::= number */
{yylhsminor.yy68=yymsp[0].minor.yy115;}
  yymsp[0].minor.yy68 = yylhsminor.yy68;
        break;
      case 16: /* value ::= string_quoted */
{yylhsminor.yy68=yymsp[0].minor.yy163;}
  yymsp[0].minor.yy68 = yylhsminor.yy68;
        break;
      case 17: /* value ::= identifier */
{yylhsminor.yy68=yymsp[0].minor.yy30;}
  yymsp[0].minor.yy68 = yylhsminor.yy68;
        break;
      case 18: /* value ::= interval */
{yylhsminor.yy68=yymsp[0].minor.yy52;}
  yymsp[0].minor.yy68 = yylhsminor.yy68;
        break;
      case 19: /* subscript ::= INTERVAL_LEFT_DELIMITER enumeration INTERVAL_RIGHT_DELIMITER */
{
  yylhsminor.yy173 = [CHParserSubscriptNode parserNodeWithToken:[CHChalkToken chalkTokenUnion:@[yymsp[-2].minor.yy0,yymsp[-1].minor.yy96.token,yymsp[0].minor.yy0]]];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy96];
  NSLog(@"subscript(%@) ::= [enumeration(%@)]", yylhsminor.yy173, yymsp[-1].minor.yy96);
}
  yymsp[-2].minor.yy173 = yylhsminor.yy173;
        break;
      case 20: /* expr ::= value */
{
  yylhsminor.yy173 = yymsp[0].minor.yy68;
  NSLog(@"expr(%@) ::= value(%@)", yylhsminor.yy173, yymsp[0].minor.yy68);
}
  yymsp[0].minor.yy173 = yylhsminor.yy173;
        break;
      case 21: /* expr ::= IF expr THEN expr ELSE expr */
{
  yymsp[-5].minor.yy173 = [CHParserIfThenElseNode parserNodeWithIf:yymsp[-4].minor.yy173 Then:yymsp[-2].minor.yy173 Else:yymsp[0].minor.yy173];
  DebugLogStatic(1, @"expr(%@) ::= if (%@) then (%@) else (%@)", yymsp[-5].minor.yy173, yymsp[-4].minor.yy173, yymsp[-2].minor.yy173, yymsp[0].minor.yy173);
}
        break;
      case 22: /* expr ::= expr QUESTION expr ALTERNATE expr */
{
  yylhsminor.yy173 = [CHParserIfThenElseNode parserNodeWithIf:yymsp[-4].minor.yy173 Then:yymsp[-2].minor.yy173 Else:yymsp[0].minor.yy173];
  DebugLogStatic(1, @"expr(%@) ::= (%@) ? (%@) : (%@)", yylhsminor.yy173, yymsp[-4].minor.yy173, yymsp[-2].minor.yy173, yymsp[0].minor.yy173);
}
  yymsp[-4].minor.yy173 = yylhsminor.yy173;
        break;
      case 23: /* expr ::= PARENTHESIS_LEFT expr PARENTHESIS_RIGHT */
{
  yymsp[-2].minor.yy173 = yymsp[-1].minor.yy173;
  NSLog(@"expr(%@) ::= ( value(%@) )", yymsp[-2].minor.yy173, yymsp[-1].minor.yy173);
}
        break;
      case 24: /* expr ::= expr OPERATOR_MINUS_UNARY */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_MINUS];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy173];
  NSLog(@"expr(%@) ::= negate expr(%@)", yylhsminor.yy173, yymsp[-1].minor.yy173);
}
  yymsp[-1].minor.yy173 = yylhsminor.yy173;
        break;
      case 25: /* expr ::= expr OPERATOR_MINUS_SQRT */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_SQRT];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy173];
  NSLog(@"expr(%@) ::= sqrt expr(%@)", yylhsminor.yy173, yymsp[-1].minor.yy173);
}
  yymsp[-1].minor.yy173 = yylhsminor.yy173;
        break;
      case 26: /* expr ::= expr OPERATOR_MINUS_SQRT2 */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_SQRT2];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy173];
  NSLog(@"expr(%@) ::= .sqrt expr(%@)", yylhsminor.yy173, yymsp[-1].minor.yy173);
}
  yymsp[-1].minor.yy173 = yylhsminor.yy173;
        break;
      case 27: /* expr ::= expr OPERATOR_MINUS_CBRT */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_CBRT];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy173];
  NSLog(@"expr(%@) ::= cbrt expr(%@)", yylhsminor.yy173, yymsp[-1].minor.yy173);
}
  yymsp[-1].minor.yy173 = yylhsminor.yy173;
        break;
      case 28: /* expr ::= expr OPERATOR_MINUS_CBRT2 */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_CBRT2];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy173];
  NSLog(@"expr(%@) ::= .cbrt expr(%@)", yylhsminor.yy173, yymsp[-1].minor.yy173);
}
  yymsp[-1].minor.yy173 = yylhsminor.yy173;
        break;
      case 29: /* expr ::= expr OPERATOR_UNCERTAINTY number_per_fraction */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_OPERATOR_UNCERTAINTY];
  [yylhsminor.yy173 addChild:yymsp[-2].minor.yy173];
  [yylhsminor.yy173 addChild:yymsp[0].minor.yy173];
  DebugLogStatic(1, @"expr(%@) ::= expr(%@) +/- expr(%@)", yylhsminor.yy173, yymsp[-2].minor.yy173, yymsp[0].minor.yy173);
}
  yymsp[-2].minor.yy173 = yylhsminor.yy173;
        break;
      case 30: /* expr ::= expr OPERATOR_UNCERTAINTY expr */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_UNCERTAINTY];
  [yylhsminor.yy173 addChild:yymsp[-2].minor.yy173];
  [yylhsminor.yy173 addChild:yymsp[0].minor.yy173];
  NSLog(@"expr(%@) ::= expr(%@) +/- expr(%@)", yylhsminor.yy173, yymsp[-2].minor.yy173, yymsp[0].minor.yy173);
}
  yymsp[-2].minor.yy173 = yylhsminor.yy173;
        break;
      case 31: /* expr ::= expr expr OPERATOR_PLUS */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_PLUS];
  [yylhsminor.yy173 addChild:yymsp[-2].minor.yy173];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy173];
  NSLog(@"expr(%@) ::= expr(%@)+expr(%@)", yylhsminor.yy173, yymsp[-2].minor.yy173, yymsp[-1].minor.yy173);
}
  yymsp[-2].minor.yy173 = yylhsminor.yy173;
        break;
      case 32: /* expr ::= expr expr OPERATOR_PLUS2 */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_PLUS2];
  [yylhsminor.yy173 addChild:yymsp[-2].minor.yy173];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy173];
  NSLog(@"expr(%@) ::= expr(%@).+expr(%@)", yylhsminor.yy173, yymsp[-2].minor.yy173, yymsp[-1].minor.yy173);
}
  yymsp[-2].minor.yy173 = yylhsminor.yy173;
        break;
      case 33: /* expr ::= expr expr OPERATOR_MINUS */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_MINUS];
  [yylhsminor.yy173 addChild:yymsp[-2].minor.yy173];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy173];
  NSLog(@"expr(%@) ::= expr(%@)-expr(%@)", yylhsminor.yy173, yymsp[-2].minor.yy173, yymsp[-1].minor.yy173);
}
  yymsp[-2].minor.yy173 = yylhsminor.yy173;
        break;
      case 34: /* expr ::= expr expr OPERATOR_MINUS2 */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_MINUS2];
  [yylhsminor.yy173 addChild:yymsp[-2].minor.yy173];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy173];
  NSLog(@"expr(%@) ::= expr(%@).-expr(%@)", yylhsminor.yy173, yymsp[-2].minor.yy173, yymsp[-1].minor.yy173);
}
  yymsp[-2].minor.yy173 = yylhsminor.yy173;
        break;
      case 35: /* expr ::= expr expr OPERATOR_TIMES */
      case 36: /* expr ::= expr expr INDEX_RANGE_JOKER */ yytestcase(yyruleno==36);
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_TIMES];
  [yylhsminor.yy173 addChild:yymsp[-2].minor.yy173];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy173];
  NSLog(@"expr(%@) ::= expr(%@)*expr(%@)", yylhsminor.yy173, yymsp[-2].minor.yy173, yymsp[-1].minor.yy173);
}
  yymsp[-2].minor.yy173 = yylhsminor.yy173;
        break;
      case 37: /* expr ::= expr expr OPERATOR_TIMES2 */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_TIMES2];
  [yylhsminor.yy173 addChild:yymsp[-2].minor.yy173];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy173];
  NSLog(@"expr(%@) ::= expr(%@).*expr(%@)", yylhsminor.yy173, yymsp[-2].minor.yy173, yymsp[-1].minor.yy173);
}
  yymsp[-2].minor.yy173 = yylhsminor.yy173;
        break;
      case 38: /* expr ::= expr expr OPERATOR_DIVIDE */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_DIVIDE];
  [yylhsminor.yy173 addChild:yymsp[-2].minor.yy173];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy173];
  NSLog(@"expr(%@) ::= expr(%@)/expr(%@)", yylhsminor.yy173, yymsp[-2].minor.yy173, yymsp[-1].minor.yy173);
}
  yymsp[-2].minor.yy173 = yylhsminor.yy173;
        break;
      case 39: /* expr ::= expr expr OPERATOR_DIVIDE2 */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_DIVIDE2];
  [yylhsminor.yy173 addChild:yymsp[-2].minor.yy173];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy173];
  NSLog(@"expr(%@) ::= expr(%@)./expr(%@)", yylhsminor.yy173, yymsp[-2].minor.yy173, yymsp[-1].minor.yy173);
}
  yymsp[-2].minor.yy173 = yylhsminor.yy173;
        break;
      case 40: /* expr ::= expr expr OPERATOR_POW */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_POW];
  [yylhsminor.yy173 addChild:yymsp[-2].minor.yy173];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy173];
  NSLog(@"expr(%@) ::= expr(%@)^expr(%@)", yylhsminor.yy173, yymsp[-2].minor.yy173, yymsp[-1].minor.yy173);
}
  yymsp[-2].minor.yy173 = yylhsminor.yy173;
        break;
      case 41: /* expr ::= expr expr OPERATOR_POW2 */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_POW2];
  [yylhsminor.yy173 addChild:yymsp[-2].minor.yy173];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy173];
  NSLog(@"expr(%@) ::= expr(%@).^expr(%@)", yylhsminor.yy173, yymsp[-2].minor.yy173, yymsp[-1].minor.yy173);
}
  yymsp[-2].minor.yy173 = yylhsminor.yy173;
        break;
      case 42: /* expr ::= expr OPERATOR_DEGREE */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_DEGREE];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy173];
  NSLog(@"expr(%@) ::= expr(%@)!", yylhsminor.yy173, yymsp[-1].minor.yy173);
}
  yymsp[-1].minor.yy173 = yylhsminor.yy173;
        break;
      case 43: /* expr ::= expr OPERATOR_DEGREE2 */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_DEGREE2];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy173];
  NSLog(@"expr(%@) ::= expr(%@).!", yylhsminor.yy173, yymsp[-1].minor.yy173);
}
  yymsp[-1].minor.yy173 = yylhsminor.yy173;
        break;
      case 44: /* expr ::= expr OPERATOR_FACTORIAL */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_FACTORIAL];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy173];
  NSLog(@"expr(%@) ::= expr(%@)!", yylhsminor.yy173, yymsp[-1].minor.yy173);
}
  yymsp[-1].minor.yy173 = yylhsminor.yy173;
        break;
      case 45: /* expr ::= expr OPERATOR_FACTORIAL2 */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_FACTORIAL2];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy173];
  NSLog(@"expr(%@) ::= expr(%@).!", yylhsminor.yy173, yymsp[-1].minor.yy173);
}
  yymsp[-1].minor.yy173 = yylhsminor.yy173;
        break;
      case 46: /* expr ::= OPERATOR_ABS expr OPERATOR_ABS */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:[CHChalkToken chalkTokenUnion:@[yymsp[-2].minor.yy0,yymsp[0].minor.yy0]] operator:CHALK_LEMON_RPN_OPERATOR_ABS];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy173];
  NSLog(@"expr(%@) ::= |expr(%@)|", yylhsminor.yy173, yymsp[-1].minor.yy173);
}
  yymsp[-2].minor.yy173 = yylhsminor.yy173;
        break;
      case 47: /* expr ::= OPERATOR_NOT expr */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_NOT];
  [yylhsminor.yy173 addChild:yymsp[0].minor.yy173];
  NSLog(@"expr(%@) ::= !expr(%@)", yylhsminor.yy173, yymsp[0].minor.yy173);
}
  yymsp[-1].minor.yy173 = yylhsminor.yy173;
        break;
      case 48: /* expr ::= OPERATOR_NOT2 expr */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_NOT2];
  [yylhsminor.yy173 addChild:yymsp[0].minor.yy173];
  NSLog(@"expr(%@) ::= .!expr(%@)", yylhsminor.yy173, yymsp[0].minor.yy173);
}
  yymsp[-1].minor.yy173 = yylhsminor.yy173;
        break;
      case 49: /* expr ::= expr expr OPERATOR_LEQ */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_LEQ];
  [yylhsminor.yy173 addChild:yymsp[-2].minor.yy173];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy173];
  NSLog(@"expr(%@) ::= expr(%@) <= expr(%@)", yylhsminor.yy173, yymsp[-2].minor.yy173, yymsp[-1].minor.yy173);
}
  yymsp[-2].minor.yy173 = yylhsminor.yy173;
        break;
      case 50: /* expr ::= expr expr OPERATOR_LEQ2 */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_LEQ2];
  [yylhsminor.yy173 addChild:yymsp[-2].minor.yy173];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy173];
  NSLog(@"expr(%@) ::= expr(%@) .<= expr(%@)", yylhsminor.yy173, yymsp[-2].minor.yy173, yymsp[-1].minor.yy173);
}
  yymsp[-2].minor.yy173 = yylhsminor.yy173;
        break;
      case 51: /* expr ::= expr expr OPERATOR_GEQ */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_GEQ];
  [yylhsminor.yy173 addChild:yymsp[-2].minor.yy173];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy173];
  NSLog(@"expr(%@) ::= expr(%@) >= expr(%@)", yylhsminor.yy173, yymsp[-2].minor.yy173, yymsp[-1].minor.yy173);
}
  yymsp[-2].minor.yy173 = yylhsminor.yy173;
        break;
      case 52: /* expr ::= expr expr OPERATOR_GEQ2 */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_GEQ2];
  [yylhsminor.yy173 addChild:yymsp[-2].minor.yy173];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy173];
  NSLog(@"expr(%@) ::= expr(%@) .>= expr(%@)", yylhsminor.yy173, yymsp[-2].minor.yy173, yymsp[-1].minor.yy173);
}
  yymsp[-2].minor.yy173 = yylhsminor.yy173;
        break;
      case 53: /* expr ::= expr expr OPERATOR_LOW */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_LOW];
  [yylhsminor.yy173 addChild:yymsp[-2].minor.yy173];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy173];
  NSLog(@"expr(%@) ::= expr(%@) < expr(%@)", yylhsminor.yy173, yymsp[-2].minor.yy173, yymsp[-1].minor.yy173);
}
  yymsp[-2].minor.yy173 = yylhsminor.yy173;
        break;
      case 54: /* expr ::= expr expr OPERATOR_LOW2 */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_LOW2];
  [yylhsminor.yy173 addChild:yymsp[-2].minor.yy173];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy173];
  NSLog(@"expr(%@) ::= expr(%@) .< expr(%@)", yylhsminor.yy173, yymsp[-2].minor.yy173, yymsp[-1].minor.yy173);
}
  yymsp[-2].minor.yy173 = yylhsminor.yy173;
        break;
      case 55: /* expr ::= expr expr OPERATOR_GRE */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_GRE];
  [yylhsminor.yy173 addChild:yymsp[-2].minor.yy173];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy173];
  NSLog(@"expr(%@) ::= expr(%@) > expr(%@)", yylhsminor.yy173, yymsp[-2].minor.yy173, yymsp[-1].minor.yy173);
}
  yymsp[-2].minor.yy173 = yylhsminor.yy173;
        break;
      case 56: /* expr ::= expr expr OPERATOR_GRE2 */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_GRE2];
  [yylhsminor.yy173 addChild:yymsp[-2].minor.yy173];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy173];
  NSLog(@"expr(%@) ::= expr(%@) .> expr(%@)", yylhsminor.yy173, yymsp[-2].minor.yy173, yymsp[-1].minor.yy173);
}
  yymsp[-2].minor.yy173 = yylhsminor.yy173;
        break;
      case 57: /* expr ::= expr OPERATOR_EQU expr */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[-1].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_EQU];
  [yylhsminor.yy173 addChild:yymsp[-2].minor.yy173];
  [yylhsminor.yy173 addChild:yymsp[0].minor.yy173];
  NSLog(@"expr(%@) ::= expr(%@) == expr(%@)", yylhsminor.yy173, yymsp[-2].minor.yy173, yymsp[0].minor.yy173);
}
  yymsp[-2].minor.yy173 = yylhsminor.yy173;
        break;
      case 58: /* expr ::= expr expr OPERATOR_EQU2 */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_EQU2];
  [yylhsminor.yy173 addChild:yymsp[-2].minor.yy173];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy173];
  NSLog(@"expr(%@) ::= expr(%@) .== expr(%@)", yylhsminor.yy173, yymsp[-2].minor.yy173, yymsp[-1].minor.yy173);
}
  yymsp[-2].minor.yy173 = yylhsminor.yy173;
        break;
      case 59: /* expr ::= expr expr OPERATOR_NEQ */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_NEQ];
  [yylhsminor.yy173 addChild:yymsp[-2].minor.yy173];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy173];
  NSLog(@"expr(%@) ::= expr(%@) != expr(%@)", yylhsminor.yy173, yymsp[-2].minor.yy173, yymsp[-1].minor.yy173);
}
  yymsp[-2].minor.yy173 = yylhsminor.yy173;
        break;
      case 60: /* expr ::= expr expr OPERATOR_NEQ2 */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_NEQ2];
  [yylhsminor.yy173 addChild:yymsp[-2].minor.yy173];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy173];
  NSLog(@"expr(%@) ::= expr(%@) .!= expr(%@)", yylhsminor.yy173, yymsp[-2].minor.yy173, yymsp[-1].minor.yy173);
}
  yymsp[-2].minor.yy173 = yylhsminor.yy173;
        break;
      case 61: /* expr ::= expr expr OPERATOR_SHL */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_SHL];
  [yylhsminor.yy173 addChild:yymsp[-2].minor.yy173];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy173];
  NSLog(@"expr(%@) ::= expr(%@) SHL expr(%@)", yylhsminor.yy173, yymsp[-2].minor.yy173, yymsp[-1].minor.yy173);
}
  yymsp[-2].minor.yy173 = yylhsminor.yy173;
        break;
      case 62: /* expr ::= expr expr OPERATOR_SHL2 */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_SHL2];
  [yylhsminor.yy173 addChild:yymsp[-2].minor.yy173];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy173];
  NSLog(@"expr(%@) ::= expr(%@) SHL2 expr(%@)", yylhsminor.yy173, yymsp[-2].minor.yy173, yymsp[-1].minor.yy173);
}
  yymsp[-2].minor.yy173 = yylhsminor.yy173;
        break;
      case 63: /* expr ::= expr expr OPERATOR_SHR */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_SHR];
  [yylhsminor.yy173 addChild:yymsp[-2].minor.yy173];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy173];
  NSLog(@"expr(%@) ::= expr(%@) SHR expr(%@)", yylhsminor.yy173, yymsp[-2].minor.yy173, yymsp[-1].minor.yy173);
}
  yymsp[-2].minor.yy173 = yylhsminor.yy173;
        break;
      case 64: /* expr ::= expr expr OPERATOR_SHR2 */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_SHR2];
  [yylhsminor.yy173 addChild:yymsp[-2].minor.yy173];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy173];
  NSLog(@"expr(%@) ::= expr(%@) SHR2 expr(%@)", yylhsminor.yy173, yymsp[-2].minor.yy173, yymsp[-1].minor.yy173);
}
  yymsp[-2].minor.yy173 = yylhsminor.yy173;
        break;
      case 65: /* expr ::= expr expr OPERATOR_AND */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_AND];
  [yylhsminor.yy173 addChild:yymsp[-2].minor.yy173];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy173];
  NSLog(@"expr(%@) ::= expr(%@) AND expr(%@)", yylhsminor.yy173, yymsp[-2].minor.yy173, yymsp[-1].minor.yy173);
}
  yymsp[-2].minor.yy173 = yylhsminor.yy173;
        break;
      case 66: /* expr ::= expr expr OPERATOR_AND2 */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_AND2];
  [yylhsminor.yy173 addChild:yymsp[-2].minor.yy173];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy173];
  NSLog(@"expr(%@) ::= expr(%@) .AND expr(%@)", yylhsminor.yy173, yymsp[-2].minor.yy173, yymsp[-1].minor.yy173);
}
  yymsp[-2].minor.yy173 = yylhsminor.yy173;
        break;
      case 67: /* expr ::= expr expr OPERATOR_OR */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_OR];
  [yylhsminor.yy173 addChild:yymsp[-2].minor.yy173];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy173];
  NSLog(@"expr(%@) ::= expr(%@) OR expr(%@)", yylhsminor.yy173, yymsp[-2].minor.yy173, yymsp[-1].minor.yy173);
}
  yymsp[-2].minor.yy173 = yylhsminor.yy173;
        break;
      case 68: /* expr ::= expr expr OPERATOR_OR2 */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_OR2];
  [yylhsminor.yy173 addChild:yymsp[-2].minor.yy173];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy173];
  NSLog(@"expr(%@) ::= expr(%@) .OR expr(%@)", yylhsminor.yy173, yymsp[-2].minor.yy173, yymsp[-1].minor.yy173);
}
  yymsp[-2].minor.yy173 = yylhsminor.yy173;
        break;
      case 69: /* expr ::= expr expr OPERATOR_XOR */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_XOR];
  [yylhsminor.yy173 addChild:yymsp[-2].minor.yy173];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy173];
  NSLog(@"expr(%@) ::= expr(%@) XOR expr(%@)", yylhsminor.yy173, yymsp[-2].minor.yy173, yymsp[-1].minor.yy173);
}
  yymsp[-2].minor.yy173 = yylhsminor.yy173;
        break;
      case 70: /* expr ::= expr expr OPERATOR_XOR2 */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy0 operator:CHALK_LEMON_RPN_OPERATOR_XOR2];
  [yylhsminor.yy173 addChild:yymsp[-2].minor.yy173];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy173];
  NSLog(@"expr(%@) ::= expr(%@) .XOR expr(%@)", yylhsminor.yy173, yymsp[-2].minor.yy173, yymsp[-1].minor.yy173);
}
  yymsp[-2].minor.yy173 = yylhsminor.yy173;
        break;
      case 71: /* expr ::= function_call */
{
  yylhsminor.yy173=yymsp[0].minor.yy173;
  NSLog(@"expr(%@) = function_call(%@)", yylhsminor.yy173, yymsp[0].minor.yy173);
}
  yymsp[0].minor.yy173 = yylhsminor.yy173;
        break;
      case 72: /* expr ::= matrix */
{
  yylhsminor.yy173=yymsp[0].minor.yy173;
  NSLog(@"expr(%@) = matrix(%@)", yylhsminor.yy173, yymsp[0].minor.yy173);
}
  yymsp[0].minor.yy173 = yylhsminor.yy173;
        break;
      case 73: /* expr ::= list */
{
  yylhsminor.yy173=yymsp[0].minor.yy167;
  NSLog(@"expr(%@) = list(%@)", yylhsminor.yy173, yymsp[0].minor.yy167);
}
  yymsp[0].minor.yy173 = yylhsminor.yy173;
        break;
      case 74: /* expr ::= expr subscript */
{
  yylhsminor.yy173 = [CHParserOperatorNode parserNodeWithToken:yymsp[0].minor.yy173.token operator:CHALK_LEMON_RPN_OPERATOR_SUBSCRIPT];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy173];
  [yylhsminor.yy173 addChild:yymsp[0].minor.yy173];
  NSLog(@"expr(%@) ::= expr(%@)[%@]", yylhsminor.yy173, yymsp[-1].minor.yy173, yymsp[0].minor.yy173);
}
  yymsp[-1].minor.yy173 = yylhsminor.yy173;
        break;
      case 75: /* enumeration_element ::= expr */
{
  yylhsminor.yy173 = yymsp[0].minor.yy173;
  NSLog(@"enumeration_element(%@) ::= %@", yylhsminor.yy173, yymsp[0].minor.yy173);
}
  yymsp[0].minor.yy173 = yylhsminor.yy173;
        break;
      case 76: /* enumeration_element ::= index_range */
{
  yylhsminor.yy173 = yymsp[0].minor.yy41;
  NSLog(@"enumeration_element(%@) ::= %@", yylhsminor.yy173, yymsp[0].minor.yy41);
}
  yymsp[0].minor.yy173 = yylhsminor.yy173;
        break;
      case 77: /* enumeration ::= enumeration_element */
{
  yylhsminor.yy96 = [CHParserEnumerationNode parserNodeWithToken:yymsp[0].minor.yy173.token];
  [yylhsminor.yy96 addChild:yymsp[0].minor.yy173];
  NSLog(@"enumeration(%@) ::= enumeration_element(%@)", yylhsminor.yy96, yymsp[0].minor.yy173);
}
  yymsp[0].minor.yy96 = yylhsminor.yy96;
        break;
      case 78: /* enumeration ::= enumeration ENUMERATION_SEPARATOR enumeration_element */
{
  yylhsminor.yy96=yymsp[-2].minor.yy96;
  yylhsminor.yy96.token = [CHChalkToken chalkTokenUnion:@[yymsp[-2].minor.yy96.token,yymsp[-1].minor.yy0,yymsp[0].minor.yy173.token]];
  [yylhsminor.yy96 addChild:yymsp[0].minor.yy173];
  NSLog(@"enumeration(%@) ::= enumeration(%@),enumeration_element(%@)", yylhsminor.yy96, yymsp[-2].minor.yy96, yymsp[0].minor.yy173);
}
  yymsp[-2].minor.yy96 = yylhsminor.yy96;
        break;
      case 79: /* function_call ::= identifier PARENTHESIS_LEFT enumeration PARENTHESIS_RIGHT */
{
  yylhsminor.yy173=[CHParserFunctionNode parserNodeWithToken:yymsp[-3].minor.yy30.token];
  [yylhsminor.yy173 addChild:yymsp[-1].minor.yy96];
  NSLog(@"function_call(%@) ::= identifier(%@)(enumeration(%@))", yylhsminor.yy173, yymsp[-3].minor.yy30, yymsp[-1].minor.yy96);
}
  yymsp[-3].minor.yy173 = yylhsminor.yy173;
        break;
      case 80: /* matrix_row_element ::= expr */
{
  yylhsminor.yy173 = yymsp[0].minor.yy173;
  NSLog(@"matrix_row_element(%@) ::= %@", yylhsminor.yy173, yymsp[0].minor.yy173);
}
  yymsp[0].minor.yy173 = yylhsminor.yy173;
        break;
      case 81: /* matrix_row_enumeration ::= matrix_row_element */
{
  yylhsminor.yy198 = [CHParserMatrixRowNode parserNodeWithToken:yymsp[0].minor.yy173.token];
  [yylhsminor.yy198 addChild:yymsp[0].minor.yy173];
  NSLog(@"matrix_row_enumeration(%@) ::= matrix_row_element(%@)", yylhsminor.yy198, yymsp[0].minor.yy173);
}
  yymsp[0].minor.yy198 = yylhsminor.yy198;
        break;
      case 82: /* matrix_row_enumeration ::= matrix_row_enumeration ENUMERATION_SEPARATOR matrix_row_element */
{
  yylhsminor.yy198=yymsp[-2].minor.yy198;
  yylhsminor.yy198.token = [CHChalkToken chalkTokenUnion:@[yymsp[-2].minor.yy198.token,yymsp[-1].minor.yy0,yymsp[0].minor.yy173.token]];
  [yylhsminor.yy198 addChild:yymsp[0].minor.yy173];
  NSLog(@"matrix_row_enumeration(%@) ::= matrix_row_enumeration(%@),matrix_row_element(%@)", yylhsminor.yy198, yymsp[-2].minor.yy198, yymsp[0].minor.yy173);
}
  yymsp[-2].minor.yy198 = yylhsminor.yy198;
        break;
      case 83: /* matrix_row ::= PARENTHESIS_LEFT matrix_row_enumeration PARENTHESIS_RIGHT */
{
  yylhsminor.yy173 = yymsp[-1].minor.yy198;
  yylhsminor.yy173.token = [CHChalkToken chalkTokenUnion:@[yymsp[-2].minor.yy0,yymsp[-1].minor.yy198.token,yymsp[0].minor.yy0]];
  NSLog(@"matrix_row(%@) ::= (matrix_row_enumeration(%@))", yylhsminor.yy173, yymsp[-1].minor.yy198);
}
  yymsp[-2].minor.yy173 = yylhsminor.yy173;
        break;
      case 84: /* matrix_rows ::= matrix_row */
{
  yylhsminor.yy62 = [CHParserMatrixNode parserNodeWithToken:yymsp[0].minor.yy173.token];
  [yylhsminor.yy62 addChild:yymsp[0].minor.yy173];
  NSLog(@"matrix_rows(%@) ::= (matrix_row_enumeration(%@))", yylhsminor.yy62, yymsp[0].minor.yy173);
}
  yymsp[0].minor.yy62 = yylhsminor.yy62;
        break;
      case 85: /* matrix_rows ::= matrix_rows matrix_row */
{
  yylhsminor.yy62 = yymsp[-1].minor.yy62;
  yylhsminor.yy62.token = [CHChalkToken chalkTokenUnion:@[yymsp[-1].minor.yy62.token,yymsp[0].minor.yy173.token]];
  [yylhsminor.yy62 addChild:yymsp[0].minor.yy173];
  NSLog(@"matrix_rows(%@) ::= matrix_rows(%@) %@", yylhsminor.yy62, yymsp[-1].minor.yy62, yymsp[0].minor.yy173);
}
  yymsp[-1].minor.yy62 = yylhsminor.yy62;
        break;
      case 86: /* matrix ::= PARENTHESIS_LEFT matrix_rows PARENTHESIS_RIGHT */
{
  yylhsminor.yy173 = yymsp[-1].minor.yy62;
  yylhsminor.yy173.token = [CHChalkToken chalkTokenUnion:@[yymsp[-2].minor.yy0,yymsp[-1].minor.yy62.token,yymsp[0].minor.yy0]];
  NSLog(@"matrix(%@) ::= (matrix_row(%@))", yylhsminor.yy173, yymsp[-1].minor.yy62);
}
  yymsp[-2].minor.yy173 = yylhsminor.yy173;
        break;
      case 87: /* list ::= LIST_LEFT_DELIMITER enumeration LIST_RIGHT_DELIMITER */
{
  yylhsminor.yy167=[CHParserListNode parserNodeWithToken:[CHChalkToken chalkTokenUnion:@[yymsp[-2].minor.yy0,yymsp[-1].minor.yy96.token,yymsp[0].minor.yy0]]];
  [yylhsminor.yy167 addChild:yymsp[-1].minor.yy96];
  NSLog(@"list(%@) ::= {enumeration(%@)}", yylhsminor.yy167, yymsp[-1].minor.yy96);
}
  yymsp[-2].minor.yy167 = yylhsminor.yy167;
        break;
      case 88: /* assignation ::= expr OPERATOR_ASSIGN expr */
{
  yylhsminor.yy29=[CHParserAssignationNode parserNodeWithToken:yymsp[-1].minor.yy0];
  [yylhsminor.yy29 addChild:yymsp[-2].minor.yy173];
  [yylhsminor.yy29 addChild:yymsp[0].minor.yy173];
  NSLog(@"assignation(%@) ::= identifier(%@) <- %@", yylhsminor.yy29, yymsp[-2].minor.yy173, yymsp[0].minor.yy173);
}
  yymsp[-2].minor.yy29 = yylhsminor.yy29;
        break;
      case 89: /* assignation ::= expr OPERATOR_ASSIGN_DYNAMIC expr */
{
  yylhsminor.yy29=[CHParserAssignationDynamicNode parserNodeWithToken:yymsp[-1].minor.yy0];
  [yylhsminor.yy29 addChild:yymsp[-2].minor.yy173];
  [yylhsminor.yy29 addChild:yymsp[0].minor.yy173];
  NSLog(@"assignation_dynamic(%@) ::= identifier(%@) <-= %@", yylhsminor.yy29, yymsp[-2].minor.yy173, yymsp[0].minor.yy173);
}
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
  Parse_rpnARG_FETCH
  Parse_rpnCTX_FETCH
#ifndef NDEBUG
  if( yyTraceFILE ){
    fprintf(yyTraceFILE,"%sFail!\n",yyTracePrompt);
  }
#endif
  while( yypParser->yytos>yypParser->yystack ) yy_pop_parser_stack(yypParser);
  /* Here code is inserted which will be executed whenever the
  ** parser fails */
/************ Begin %parse_failure code ***************************************/

  NSLog(@"lemon parse failure");
  context.stop = YES;
/************ End %parse_failure code *****************************************/
  Parse_rpnARG_STORE /* Suppress warning about unused %extra_argument variable */
  Parse_rpnCTX_STORE
}
#endif /* YYNOERRORRECOVERY */

/*
** The following code executes when a syntax error first occurs.
*/
static void yy_syntax_error(
  yyParser *yypParser,           /* The parser */
  int yymajor,                   /* The major type of the error token */
  Parse_rpnTOKENTYPE yyminor         /* The minor type of the error token */
){
  Parse_rpnARG_FETCH
  Parse_rpnCTX_FETCH
#define TOKEN yyminor
/************ Begin %syntax_error code ****************************************/

  NSLog(@"lemon syntax error");
  context.stop = YES;
/************ End %syntax_error code ******************************************/
  Parse_rpnARG_STORE /* Suppress warning about unused %extra_argument variable */
  Parse_rpnCTX_STORE
}

/*
** The following is executed when the parser accepts
*/
static void yy_accept(
  yyParser *yypParser           /* The parser */
){
  Parse_rpnARG_FETCH
  Parse_rpnCTX_FETCH
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
  Parse_rpnARG_STORE /* Suppress warning about unused %extra_argument variable */
  Parse_rpnCTX_STORE
}

/* The main parser program.
** The first argument is a pointer to a structure obtained from
** "Parse_rpnAlloc" which describes the current state of the parser.
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
void Parse_rpn(
  void *yyp,                   /* The parser */
  int yymajor,                 /* The major token code number */
  Parse_rpnTOKENTYPE yyminor       /* The value for the token */
  Parse_rpnARG_PDECL               /* Optional %extra_argument parameter */
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
  Parse_rpnCTX_FETCH
  Parse_rpnARG_STORE

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
                        yyminor Parse_rpnCTX_PARAM);
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
int Parse_rpnFallback(int iToken){
#ifdef YYFALLBACK
  assert( iToken<(int)(sizeof(yyFallback)/sizeof(yyFallback[0])) );
  return yyFallback[iToken];
#else
  (void)iToken;
  return 0;
#endif
}
