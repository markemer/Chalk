//
//  CHChalkIdentifierFunction.h
//  Chalk
//
//  Created by Pierre Chatelier on 08/11/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CHChalkIdentifier.h"

@interface CHChalkIdentifierFunction : CHChalkIdentifier <NSCopying, NSSecureCoding> {
  NSRange argsPossibleCount;
  NSArray* argumentNames;
  NSString* definition;
}

@property(nonatomic) NSRange argsPossibleCount;
@property(nonatomic,copy) NSArray* argumentNames;
@property(nonatomic,copy) NSString* definition;

+(instancetype) intervalIdentifier;
+(instancetype) absIdentifier;
+(instancetype) angleIdentifier;
+(instancetype) anglesIdentifier;
+(instancetype) invIdentifier;
+(instancetype) powIdentifier;
+(instancetype) sqrtIdentifier;
+(instancetype) cbrtIdentifier;
+(instancetype) rootIdentifier;
+(instancetype) expIdentifier;
+(instancetype) lnIdentifier;
+(instancetype) log10Identifier;
+(instancetype) sinIdentifier;
+(instancetype) cosIdentifier;
+(instancetype) tanIdentifier;
+(instancetype) asinIdentifier;
+(instancetype) acosIdentifier;
+(instancetype) atanIdentifier;
+(instancetype) atan2Identifier;
+(instancetype) sinhIdentifier;
+(instancetype) coshIdentifier;
+(instancetype) tanhIdentifier;
+(instancetype) asinhIdentifier;
+(instancetype) acoshIdentifier;
+(instancetype) atanhIdentifier;
+(instancetype) gammaIdentifier;
+(instancetype) zetaIdentifier;
+(instancetype) conjIdentifier;
+(instancetype) matrixIdentifier;
+(instancetype) identityIdentifier;
+(instancetype) transposeIdentifier;
+(instancetype) traceIdentifier;
+(instancetype) detIdentifier;
+(instancetype) isPrimeIdentifier;
+(instancetype) nextPrimeIdentifier;
+(instancetype) nthPrimeIdentifier;
+(instancetype) primesIdentifier;
+(instancetype) gcdIdentifier;
+(instancetype) lcmIdentifier;
+(instancetype) modIdentifier;
+(instancetype) binomialIdentifier;
+(instancetype) primorialIdentifier;
+(instancetype) fibonacciIdentifier;
+(instancetype) jacobiIdentifier;
+(instancetype) inputIdentifier;
+(instancetype) outputIdentifier;
+(instancetype) output2Identifier;
+(instancetype) fromBaseIdentifier;
+(instancetype) inFileIdentifier;
+(instancetype) outFileIdentifier;
+(instancetype) toU8Identifier;
+(instancetype) toS8Identifier;
+(instancetype) toU16Identifier;
+(instancetype) toS16Identifier;
+(instancetype) toU32Identifier;
+(instancetype) toS32Identifier;
+(instancetype) toU64Identifier;
+(instancetype) toS64Identifier;
+(instancetype) toU128Identifier;
+(instancetype) toS128Identifier;
+(instancetype) toU256Identifier;
+(instancetype) toS256Identifier;
+(instancetype) toUCustomIdentifier;
+(instancetype) toSCustomIdentifier;
+(instancetype) toChalkIntegerIdentifier;
+(instancetype) toF16Identifier;
+(instancetype) toF32Identifier;
+(instancetype) toF64Identifier;
+(instancetype) toF128Identifier;
+(instancetype) toF256Identifier;
+(instancetype) toChalkFloatIdentifier;
+(instancetype) fromU8Identifier;
+(instancetype) fromS8Identifier;
+(instancetype) fromU16Identifier;
+(instancetype) fromS16Identifier;
+(instancetype) fromU32Identifier;
+(instancetype) fromS32Identifier;
+(instancetype) fromU64Identifier;
+(instancetype) fromS64Identifier;
+(instancetype) fromU128Identifier;
+(instancetype) fromS128Identifier;
+(instancetype) fromU256Identifier;
+(instancetype) fromS256Identifier;
+(instancetype) fromUCustomIdentifier;
+(instancetype) fromSCustomIdentifier;
+(instancetype) fromChalkIntegerIdentifier;
+(instancetype) fromF16Identifier;
+(instancetype) fromF32Identifier;
+(instancetype) fromF64Identifier;
+(instancetype) fromF128Identifier;
+(instancetype) fromF256Identifier;
+(instancetype) fromChalkFloatIdentifier;
+(instancetype) shiftIdentifier;
+(instancetype) rollIdentifier;
+(instancetype) bitsSwapIdentifier;
+(instancetype) bitsReverseIdentifier;
+(instancetype) bitsConcatLEIdentifier;
+(instancetype) bitsConcatBEIdentifier;
+(instancetype) golombRiceDecodeIdentifier;
+(instancetype) golombRiceEncodeIdentifier;
+(instancetype) hConcatIdentifier;
+(instancetype) vConcatIdentifier;
+(instancetype) sumIdentifier;
+(instancetype) productIdentifier;
+(instancetype) integralIdentifier;

-(instancetype) initWithName:(NSString*)name caseSensitive:(BOOL)caseSensitive tokens:(NSArray*)tokens symbol:(NSString*)symbol symbolAsText:(NSString*)symbolAsText symbolAsTeX:(NSString*)symbolAsTeX argsPossibleCount:(NSRange)argsPossibleCount;

@end
