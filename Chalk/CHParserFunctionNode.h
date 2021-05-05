//
//  CHParserFunctionNode.h
//  Chalk
//
//  Created by Pierre Chatelier on 13/02/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHParserNode.h"

@class CHChalkContext;
@class CHChalkToken;
@class CHChalkIdentifier;
@class CHChalkIdentifierFunction;
@class CHChalkValue;

@interface CHParserFunctionNode : CHParserNode <NSCopying>{
  CHChalkIdentifier* cachedIdentifier;
  NSArray* argumentNames;
}

@property(readonly,retain) CHChalkIdentifier* identifier;
@property(copy) NSArray* argumentNames;

-(CHChalkIdentifier*) identifierWithContext:(CHChalkContext*)context;

+(CHChalkValue*) combine:(NSArray*)operands functionIdentifier:(CHChalkIdentifierFunction*)functionIdentifier token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineInterval:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineAbs:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineAbs2:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineAngle:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineAngles:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineInv:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineSqrt:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineCbrt:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineRoot:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineExp:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineLn:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineLog10:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineSin:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineSinDeg:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineCos:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineCosDeg:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineTan:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineTanDeg:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineASin:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineACos:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineATan:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineATan2:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineSinh:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineCosh:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineTanh:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineASinh:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineACosh:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineATanh:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineConj:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineSqr:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combinePow:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineMatrix:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineIdentity:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineDet:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineIsPrime:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineNextPrime:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineNthPrime:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combinePrimes:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineGcd:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineLcm:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineBinomial:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combinePrimorial:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineFibonacci:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineJacobi:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineInput:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineOutput:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineOutput2:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineFromBase:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineInFile:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineOutFile:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineToU8:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineToS8:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineToU16:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineToS16:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineToU32:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineToS32:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineToU64:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineToS64:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineToU128:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineToS128:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineToU256:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineToS256:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineToUCustom:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineToSCustom:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineToChalkInteger:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineToF16:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineToF32:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineToF64:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineToF128:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineToF256:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineToChalkFloat:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineShift:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineRoll:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineBitsSwap:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineBitsReverse:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineGolombRiceDecode:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineGolombRiceEncode:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineHConcat:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineVConcat:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;

+(BOOL) powIntegers:(mpz_ptr)rop op1:(mpz_srcptr)op1 op2:(mpz_srcptr)op2 operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) pow:(CHChalkValue*)value integerPower:(mpz_srcptr)integerPower operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
@end
