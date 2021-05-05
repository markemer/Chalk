//
//  CHComputationEntryEntity.m
//  Chalk
//
//  Created by Pierre Chatelier on 01/05/2015.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHComputationEntryEntity.h"

#import "CHChalkUtils.h"
#import "CHChalkValueNumberGmp.h"
#import "CHChalkValueNumberRaw.h"
#import "CHComputationConfigurationEntity.h"
#import "CHComputedValueEntity.h"
#import "CHPresentationConfigurationEntity.h"
#import "CHUtils.h"
#import "NSObjectExtended.h"

@implementation CHComputationEntryEntity

@dynamic uniqueIdentifier;
@dynamic inputRawString;
@dynamic inputRawHTMLString;
@dynamic inputInterpretedHTMLString;
@dynamic inputInterpretedTeXString;
@dynamic outputRawString;
@dynamic outputHTMLString;
@dynamic outputTeXString;
@dynamic outputHtmlCumulativeFlags;
@dynamic output2RawString;
@dynamic output2HTMLString;
@dynamic output2TeXString;
@dynamic output2HtmlCumulativeFlags;
@dynamic dateCreation;
@dynamic dateModification;
@dynamic customAnnotation;
@dynamic customAnnotationVisible;

@dynamic computationConfiguration;
@dynamic presentationConfiguration;
@dynamic computedValues;
@dynamic computedValue1;
@dynamic computedValue2;

@dynamic chalkValue1;
@dynamic chalkValue2;

@dynamic softFloatSignificandBits;

+(NSString*) entityName {return @"ComputationEntry";}

-(NSInteger) uniqueIdentifier
{
  NSInteger result = 0;
  [self willAccessValueForKey:@"uniqueIdentifier"];
  result = [[self primitiveValueForKey:@"uniqueIdentifier"] integerValue];
  [self didAccessValueForKey:@"uniqueIdentifier"];
  return result;
}
//end uniqueIdentifier

-(void) setUniqueIdentifier:(NSInteger)value
{
  [self willChangeValueForKey:@"uniqueIdentifier"];
  [self setPrimitiveValue:@(value) forKey:@"uniqueIdentifier"];
  [self didChangeValueForKey:@"uniqueIdentifier"];
}
//end uniqueIdentifier

-(CHComputationConfigurationEntity*) computationConfiguration
{
  id result = nil;
  @synchronized(self)
  {
    if (!self->isCreatingComputationConfiguration)
    {
      [self willAccessValueForKey:@"computationConfiguration"];
      result = [self primitiveValueForKey:@"computationConfiguration"];
      [self didAccessValueForKey:@"computationConfiguration"];
      if (!result && self.managedObjectContext)
      {
        self->isCreatingComputationConfiguration = YES;
        result =
          [[NSEntityDescription insertNewObjectForEntityForName:[CHComputationConfigurationEntity entityName]
             inManagedObjectContext:self.managedObjectContext]
           dynamicCastToClass:[CHComputationConfigurationEntity class]];
        if (result)
        {
          [self willChangeValueForKey:@"computationConfiguration"];
          [self setPrimitiveValue:result forKey:@"computationConfiguration"];
          [self didChangeValueForKey:@"computationConfiguration"];
        }//end if (result)
        self->isCreatingComputationConfiguration = NO;
      }//end if (!result && self.managedObjectContext)
    }//end if (!self->isCreatingComputationConfiguration)
  }//end @synchronized(self)
  return [result dynamicCastToClass:[CHComputationConfigurationEntity class]];
}
//end computationConfiguration

-(CHPresentationConfigurationEntity*) presentationConfiguration
{
  id result = nil;
  @synchronized(self)
  {
    if (!self->isCreatingPresentationConfiguration)
    {
      [self willAccessValueForKey:@"presentationConfiguration"];
      result = [self primitiveValueForKey:@"presentationConfiguration"];
      [self didAccessValueForKey:@"presentationConfiguration"];
      if (!result && self.managedObjectContext)
      {
        self->isCreatingPresentationConfiguration = YES;
        result =
          [[NSEntityDescription insertNewObjectForEntityForName:[CHPresentationConfigurationEntity entityName]
             inManagedObjectContext:self.managedObjectContext]
           dynamicCastToClass:[CHPresentationConfigurationEntity class]];
        if (result)
        {
          [self willChangeValueForKey:@"presentationConfiguration"];
          [self setPrimitiveValue:result forKey:@"presentationConfiguration"];
          [self didChangeValueForKey:@"presentationConfiguration"];
        }//end if (result)
        self->isCreatingPresentationConfiguration = NO;
      }//end if (!result && self.managedObjectContext)
    }//end if (!self->isCreatingPresentationConfiguration)
  }//end @synchronized(self)
  return [result dynamicCastToClass:[CHPresentationConfigurationEntity class]];
}
//end presentationConfiguration

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

-(NSUInteger) softFloatSignificandBits
{
  NSUInteger result = self.computationConfiguration.softFloatSignificandBits;
  CHChalkValue* chalkValue = self.chalkValue1;
  CHChalkValueNumberGmp* valueGmp = [chalkValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
  CHChalkValueNumberRaw* valueRaw = [chalkValue dynamicCastToClass:[CHChalkValueNumberRaw class]];
  const chalk_gmp_value_t* gmpValue = valueGmp.valueConstReference;
  const chalk_raw_value_t* rawValue = valueRaw.valueConstReference;
  NSUInteger floatSignificandBitsCounts =
    gmpValue ?
      (gmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT) ? mpfr_get_prec(gmpValue->realExact)+1 :
      (gmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX) ? mpfir_get_prec(gmpValue->realApprox)+1 :
      result :
    rawValue ?
      getSignificandBitsCountForBitInterpretation(&rawValue->bitInterpretation, YES) :
    result;
  result = MIN(result, floatSignificandBitsCounts);
  return result;
}
//end softFloatSignificandBits

@end
