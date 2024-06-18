//
//  CHCHalkOperatorManager.h
//  Chalk
//
//  Created by Pierre Chatelier on 08/11/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CHChalkUtils.h"

@class CHChalkOperator;

@interface CHChalkOperatorManager : NSObject {
  NSMutableDictionary* operators;
}

+(NSArray*) defaultOperators;
+(instancetype) operatorManagerWithDefaults:(BOOL)withDefaults;
-(instancetype) init;

-(BOOL) addOperator:(CHChalkOperator*)chalkOperator;
-(BOOL) removeOperator:(CHChalkOperator*)chalkOperator;
-(void) removeAllExceptDefaults:(BOOL)exceptDefault;
-(CHChalkOperator*) operatorForIdentifier:(chalk_operator_t)identifier;


@end
