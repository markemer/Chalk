//
//  CHChalkOperatorManager.m
//  Chalk
//
//  Created by Pierre Chatelier on 06/11/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHChalkOperatorManager.h"

#import "CHChalkOperator.h"

@implementation CHChalkOperatorManager

+(NSArray*) defaultOperators
{
  static NSArray* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [@[[CHChalkOperator plusOperator], [CHChalkOperator plus2Operator],
                      [CHChalkOperator minusOperator], [CHChalkOperator minus2Operator],
                      [CHChalkOperator timesOperator], [CHChalkOperator times2Operator],
                      [CHChalkOperator divideOperator], [CHChalkOperator divide2Operator],
                      [CHChalkOperator powOperator], [CHChalkOperator pow2Operator],
                      [CHChalkOperator sqrtOperator], [CHChalkOperator sqrt2Operator],
                      [CHChalkOperator cbrtOperator], [CHChalkOperator cbrt2Operator],
                      [CHChalkOperator mulSqrtOperator], [CHChalkOperator mulSqrt2Operator],
                      [CHChalkOperator mulCbrtOperator], [CHChalkOperator mulCbrt2Operator],
                      [CHChalkOperator degreeOperator], [CHChalkOperator degree2Operator],
                      [CHChalkOperator factorialOperator], [CHChalkOperator factorial2Operator],
                      [CHChalkOperator uncertaintyOperator],
                      [CHChalkOperator absOperator],
                      [CHChalkOperator notOperator], [CHChalkOperator not2Operator],
                      [CHChalkOperator geqOperator], [CHChalkOperator geq2Operator],
                      [CHChalkOperator leqOperator], [CHChalkOperator leq2Operator],
                      [CHChalkOperator greOperator], [CHChalkOperator gre2Operator],
                      [CHChalkOperator lowOperator], [CHChalkOperator low2Operator],
                      [CHChalkOperator equOperator], [CHChalkOperator equ2Operator],
                      [CHChalkOperator neqOperator], [CHChalkOperator neq2Operator],
                      [CHChalkOperator andOperator], [CHChalkOperator and2Operator],
                      [CHChalkOperator orOperator], [CHChalkOperator or2Operator],
                      [CHChalkOperator xorOperator], [CHChalkOperator xor2Operator],
                      [CHChalkOperator subscriptOperator],
                     ] retain];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end defaultOperators

+(instancetype) operatorManagerWithDefaults:(BOOL)withDefaults
{
  CHChalkOperatorManager* result = [[[CHChalkOperatorManager alloc] init] autorelease];
  if (withDefaults)
  {
    for(CHChalkOperator* defaultOperator in [self defaultOperators])
      [result addOperator:defaultOperator];
  }//end if (withDefaults)
  return result;
}
//end operatorManagerWithDefaults:

-(instancetype) init
{
  if (!((self = [super init])))
    return nil;
  self->operators = [[NSMutableDictionary alloc] init];
  return self;
}
//end init

-(void) dealloc
{
  [self->operators release];
  [super dealloc];
}
//end dealloc

-(BOOL) addOperator:(CHChalkOperator*)chalkOperator
{
  BOOL result = NO;
  NSNumber* key = !chalkOperator ? nil : @(chalkOperator.operatorIdentifier);
  if (key)
  {
    @synchronized(self)
    {
      [self->operators setObject:chalkOperator forKey:key];
      result = YES;
    }//end @synchronized(self)
  }//end if (key)
  return result;
}
//end addOperator:

-(BOOL) removeOperator:(CHChalkOperator*)chalkOperator
{
  BOOL result = NO;
  NSNumber* key = !chalkOperator ? nil : @(chalkOperator.operatorIdentifier);
  if (key)
  {
    @synchronized(self)
    {
      BOOL hasObject = ([self->operators objectForKey:key] != nil);
      [self->operators removeObjectForKey:key];
      result = hasObject;
    }//end @synchronized(self)
  }//end if (key)
  return result;
}
//end removeOperator:

-(void) removeAllExceptDefaults:(BOOL)exceptDefault
{
  @synchronized(self)
  {
    if (!exceptDefault)
      [self->operators removeAllObjects];
    else//if (exceptDefault)
    {
      NSSet* operatorsToRemove = nil;
      NSSet* defaultOperators = [NSSet setWithArray:[[self class] defaultOperators]];
      operatorsToRemove = [self->operators keysOfEntriesWithOptions:NSEnumerationConcurrent passingTest:^BOOL(id key, id obj, BOOL *stop) {
        return ![defaultOperators containsObject:obj];
      }];
      for(CHChalkOperator* operatorToRemove in operatorsToRemove)
        [self removeOperator:operatorToRemove];
    }//end if (exceptDefault)
  }//end @synchronized(self)
}
//end removeAllExceptDefaults

-(CHChalkOperator*) operatorForIdentifier:(chalk_operator_t)identifier
{
  CHChalkOperator* result = nil;
  NSNumber* key = @(identifier);
  if (key)
  {
    @synchronized(self)
    {
      result = [self->operators objectForKey:key];
    }//end @synchronized(self)
  }//end if (key)
  return result;
}
//end operatorForIdentifier:

@end
