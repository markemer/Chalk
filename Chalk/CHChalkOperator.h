//
//  CHChalkOperator.h
//  Chalk
//
//  Created by Pierre Chatelier on 08/11/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CHChalkUtils.h"

@interface CHChalkOperator : NSObject <NSCopying> {
  chalk_operator_t operatorIdentifier;
  chalk_operator_position_t operatorPosition;
  NSString* symbol;
  NSString* symbolAsText;
  NSString* symbolAsTeX;
}

@property(nonatomic,readonly) chalk_operator_t operatorIdentifier;
@property(nonatomic,readonly) chalk_operator_position_t operatorPosition;
@property(nonatomic,copy) NSString* symbol;
@property(nonatomic,copy) NSString* symbolAsText;
@property(nonatomic,copy) NSString* symbolAsTeX;

+(instancetype) plusOperator;
+(instancetype) plus2Operator;
+(instancetype) minusOperator;
+(instancetype) minus2Operator;
+(instancetype) timesOperator;
+(instancetype) times2Operator;
+(instancetype) divideOperator;
+(instancetype) divide2Operator;
+(instancetype) powOperator;
+(instancetype) pow2Operator;
+(instancetype) sqrtOperator;
+(instancetype) sqrt2Operator;
+(instancetype) cbrtOperator;
+(instancetype) cbrt2Operator;
+(instancetype) mulSqrtOperator;
+(instancetype) mulSqrt2Operator;
+(instancetype) mulCbrtOperator;
+(instancetype) mulCbrt2Operator;
+(instancetype) degreeOperator;
+(instancetype) degree2Operator;
+(instancetype) factorialOperator;
+(instancetype) factorial2Operator;
+(instancetype) uncertaintyOperator;
+(instancetype) absOperator;
+(instancetype) notOperator;
+(instancetype) not2Operator;
+(instancetype) leqOperator;
+(instancetype) leq2Operator;
+(instancetype) geqOperator;
+(instancetype) geq2Operator;
+(instancetype) greOperator;
+(instancetype) gre2Operator;
+(instancetype) lowOperator;
+(instancetype) low2Operator;
+(instancetype) equOperator;
+(instancetype) equ2Operator;
+(instancetype) neqOperator;
+(instancetype) neq2Operator;
+(instancetype) andOperator;
+(instancetype) and2Operator;
+(instancetype) orOperator;
+(instancetype) or2Operator;
+(instancetype) xorOperator;
+(instancetype) xor2Operator;
+(instancetype) subscriptOperator;

-(instancetype) initWithIdentifier:(chalk_operator_t)operatorIdentifier operatorPosition:(chalk_operator_position_t)operatorPosition
                            symbol:(NSString*)symbol symbolAsText:(NSString*)symbolAsText symbolAsTeX:(NSString*)symbolAsTeX;

@end
