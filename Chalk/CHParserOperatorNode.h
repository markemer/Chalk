//
//  CHParserOperatorNode.h
//  Chalk
//
//  Created by Pierre Chatelier on 13/02/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHParserNode.h"

#import "CHChalkUtils.h"

@interface CHParserOperatorNode : CHParserNode <NSCopying> {
  chalk_operator_t op;
}

+(instancetype) parserNodeWithToken:(CHChalkToken*)token operator:(NSUInteger)op;
-(instancetype) initWithToken:(CHChalkToken*)token operator:(NSUInteger)op;

@property(nonatomic,readonly) chalk_operator_t op;

+(id) combine:(NSArray*)operands operator:(chalk_operator_t)op operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineAdd:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineAdd2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineSub:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineSub2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineMul:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineMul2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineDiv:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineDiv2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combinePow:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combinePow2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineSqrt:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineSqrt2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineCbrt:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineCbrt2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineMulSqrt:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineMulSqrt2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineMulCbrt:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineMulCbrt2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineDegree:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineDegree2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineFactorial:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineFactorial2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineUncertainty:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineAbs:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineSubscript:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;

+(CHChalkValue*) combineNot:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineNot2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineLeq:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineLeq2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineGeq:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineGeq2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineLow:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineLow2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineGre:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineGre2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineEqu:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineEqu2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineNeq:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineNeq2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineAnd:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineAnd2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineOr:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineOr2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineXor:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineXor2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineShl:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineShl2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineShr:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineShr2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;

+(BOOL) addIntegers:(mpz_ptr)rop op1:(mpz_srcptr)op1 op2:(mpz_srcptr)op2 operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(BOOL) subIntegers:(mpz_ptr)rop op1:(mpz_srcptr)op1 op2:(mpz_srcptr)op2 operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(BOOL) mulIntegers:(mpz_ptr)rop op1:(mpz_srcptr)op1 op2:(mpz_srcptr)op2 operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(BOOL) divIntegers:(mpz_ptr)rop op1:(mpz_srcptr)op1 op2:(mpz_srcptr)op2 operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(BOOL) factorialIntegers:(mpz_ptr)rop op1:(mpz_srcptr)op1 operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;

@end
