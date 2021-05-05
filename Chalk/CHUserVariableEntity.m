//
//  CHUserVariable.m
//  Chalk
//
//  Created by Pierre Chatelier on 01/05/2015.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHUserVariableEntity.h"

#import "CHComputedValueEntity.h"
#import "NSObjectExtended.h"
#import "NSStringExtended.h"

@implementation CHUserVariableEntity

@dynamic identifierName;
@dynamic inputRawString;
@dynamic isDynamic;

@dynamic computedValues;
@dynamic computedValue1;
@dynamic computedValue2;

@dynamic chalkValue1;
@dynamic chalkValue2;

+(NSString*) entityName {return @"UserVariable";}

-(void) setInputRawString:(NSString*)value
{
  if (![NSString string:value equals:self.inputRawString])
  {
    [self willChangeValueForKey:@"inputRawString"];
    [self setPrimitiveValue:value forKey:@"inputRawString"];
    [self didChangeValueForKey:@"inputRawString"];
  }//end if (![NSString string:value equals:self.inputRawString])
}
//end setInputRawString:

-(CHComputedValueEntity*) computedValue1
{
  CHComputedValueEntity* result = nil;
  [self willAccessValueForKey:@"computedValues"];
  NSMutableOrderedSet* computedValues = self.computedValues;
  [self didAccessValueForKey:@"computedValues"];
  result = (computedValues.count >= 1) ? [computedValues objectAtIndex:0] : nil;
  return result;
}
//end computedValue1

-(CHComputedValueEntity*) computedValue2
{
  CHComputedValueEntity* result = nil;
  NSMutableOrderedSet* computedValues = self.computedValues;
  result = (computedValues.count >= 2) ? [computedValues objectAtIndex:1] : nil;
  return result;
}
//end computedValue2

-(CHChalkValue*) chalkValue1
{
  CHChalkValue* result = self.computedValue1.chalkValue;
  return result;
}
//end chalkValue

-(void) setChalkValue1:(CHChalkValue*)value
{
  if (!self.computedValue1)
  {
    CHComputedValueEntity* computedValue =
      [[NSEntityDescription insertNewObjectForEntityForName:[CHComputedValueEntity entityName]
         inManagedObjectContext:self.managedObjectContext]
       dynamicCastToClass:[CHComputedValueEntity class]];
    NSMutableOrderedSet* computedValues = self.computedValues;
    [self willChangeValueForKey:@"computedValues"];
    if (!computedValues)
      [self setPrimitiveValue:[NSMutableOrderedSet orderedSetWithObjects:computedValue, nil] forKey:@"computedValues"];
    else if (computedValues.count == 0)
      [computedValues addObject:computedValue];
    else if (computedValues.count >= 1)
      [computedValues replaceObjectAtIndex:0 withObject:computedValue];
    [self didChangeValueForKey:@"computedValues"];
    [computedValue setValue:self forKey:@"owner"];
  }//end if (!computedValue1)
  self.computedValue1.chalkValue = value;
}
//end setChalkValue1:

-(CHChalkValue*) chalkValue2
{
  CHChalkValue* result = self.computedValue2.chalkValue;
  return result;
}
//end chalkValue2

-(void) setChalkValue2:(CHChalkValue*)value
{
  if (!self.computedValue2)
  {
    CHComputedValueEntity* computedValue =
      [[NSEntityDescription insertNewObjectForEntityForName:[CHComputedValueEntity entityName]
         inManagedObjectContext:self.managedObjectContext]
       dynamicCastToClass:[CHComputedValueEntity class]];
    NSMutableOrderedSet* computedValues = self.computedValues;
    [self willChangeValueForKey:@"computedValues"];
    if (!computedValues)
      [self setPrimitiveValue:[NSMutableOrderedSet orderedSetWithObjects:computedValue, nil] forKey:@"computedValues"];
    else if (computedValues.count == 0)
      [computedValues addObject:computedValue];
    else if (computedValues.count == 1)
      [computedValues addObject:computedValue];
    else if (computedValues.count >= 2)
      [computedValues replaceObjectAtIndex:1 withObject:computedValue];
    [self didChangeValueForKey:@"computedValues"];
    [computedValue setValue:self forKey:@"owner"];
  }//end if (!computedValue2)
  self.computedValue2.chalkValue = value;
}
//end setChalkValue2:

@end
