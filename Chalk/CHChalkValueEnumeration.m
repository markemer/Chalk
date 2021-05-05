//
//  CHChalkValueEnumeration.m
//  Chalk
//
//  Created by Pierre Chatelier on 09/11/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHChalkValueEnumeration.h"

#import "CHChalkContext.h"
#import "CHChalkError.h"
#import "CHChalkErrorContext.h"
#import "CHChalkValueIndexRange.h"
#import "CHChalkValueMovable.h"
#import "CHChalkValueNumberGmp.h"
#import "CHChalkValueSubscript.h"
#import "CHChalkToken.h"
#import "CHPresentationConfiguration.h"
#import "CHStreamWrapper.h"
#import "CHUtils.h"
#import "NSArrayExtended.h"
#import "NSObjectExtended.h"

@implementation CHChalkValueEnumeration

@dynamic count;
@synthesize values;

-(instancetype) initWithToken:(CHChalkToken*)aToken context:(CHChalkContext*)context
{
  return [self initWithToken:aToken count:0 value:nil context:context];
}
//end initWithToken:context:

-(instancetype) initWithToken:(CHChalkToken*)aToken count:(NSUInteger)count value:(CHChalkValue*)value context:(CHChalkContext*)context
{
  if (!((self = [super initWithToken:aToken context:context])))
    return nil;
  @autoreleasepool{
    CHChalkValue* fillValue = value ? value : [CHChalkValue null];
    self->values = [[NSMutableArray alloc] initWithCapacity:count];
    for(NSUInteger i = 0 ; self->values && i<count ; ++i)
    {
      CHChalkValue* fillValueClone = [fillValue copy];
      if (fillValueClone)
        [self->values addObject:fillValueClone];
      else//if (!fillValueClone)
      {
        [self->values release];
        self->values = nil;
      }//end if (!fillValueClone)
      [fillValueClone release];
    }//end for each element
  }//end @autoreleasepool
  [self->values enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    self->evaluationComputeFlags |= ((CHChalkValue*)[obj dynamicCastToClass:[CHChalkValue class]]).evaluationComputeFlags;
  }];
  if (!self->values)
  {
    [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:aToken.range] context:context];
    [self release];
    return nil;
  }//end if (!self->values)
  return self;
}
//end initWithToken:count:value:context:

-(instancetype) initWithToken:(CHChalkToken*)aToken values:(NSArray*)aValues context:(CHChalkContext*)context
{
  if (!((self = [super initWithToken:aToken context:context])))
    return nil;
  self->values = [CHChalkValue copyValues:aValues withZone:nil];
  [self->values enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    self->evaluationComputeFlags |= ((CHChalkValue*)[obj dynamicCastToClass:[CHChalkValue class]]).evaluationComputeFlags;
  }];
  if (!self->values)
  {
    [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:aToken.range] context:context];
    [self release];
    return nil;
  }//end if (!self->values)
  return self;
}
//end initWithToken:values:context:

-(instancetype) initWithCoder:(NSCoder*)aDecoder
{
  if (!((self = [super initWithCoder:aDecoder])))
    return nil;
  self->values = [[aDecoder decodeObjectOfClass:[NSMutableArray class] forKey:@"values"] retain];
  return self;
}
//end initWithCoder:

-(void) encodeWithCoder:(NSCoder*)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:self->values forKey:@"values"];
}
//end encodeWithCoder:

-(void) dealloc
{
  [self->values release];
  [super dealloc];
}
//end dealloc

-(id) copyWithZone:(NSZone*)zone
{
  CHChalkValueEnumeration* result = [super copyWithZone:zone];
  if (result)
  {
    result->values = [CHChalkValue copyValues:self->values withZone:zone];
    if (!result->values && self->values)
    {
      [result release];
      result = nil;
    }//end if (!result->values)
  }//end if (result)
  return result;
}
//end copyWithZone:

-(BOOL) moveTo:(CHChalkValue*)dst
{
  BOOL result = [super moveTo:dst];
  CHChalkValueEnumeration* dstList = !result ? nil : [dst dynamicCastToClass:[CHChalkValueEnumeration class]];
  if (result && dstList)
  {
    dstList->values = self->values;
    self->values = nil;
  }//end if (result && dstList)
  return result;
}
//end moveTo:

-(NSUInteger) count
{
  NSUInteger result = self->values.count;
  return result;
}
//end count

-(BOOL) isZero
{
  BOOL result = NO;
  __block BOOL isNotZero = NO;
  [self->values enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    CHChalkValue* element = [obj dynamicCastToClass:[CHChalkValue class]];
    BOOL elementIsZero = element.isZero;
    if (!elementIsZero)
    {
      isNotZero = YES;
      *stop = YES;
    }//end if (!elementIsZero)
  }];
  result = !isNotZero;
  return result;
}
//end isZero

-(BOOL) isOne:(BOOL*)isOneIgnoringSign;
{
  BOOL result = NO;
  __block BOOL isNotOne = NO;
  __block BOOL hadToIgnoreSign = NO;
  [self->values enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    CHChalkValue* element = [obj dynamicCastToClass:[CHChalkValue class]];
    BOOL elementIsOneIgnoringSign = NO;
    BOOL elementIsOk =
      ([element isOne:isOneIgnoringSign ? &elementIsOneIgnoringSign : 0] && (!isOneIgnoringSign || elementIsOneIgnoringSign));
    if (!elementIsOk)
    {
      isNotOne = YES;
      *stop = YES;
    }//end if (!elementIsOk)
    else if (isOneIgnoringSign && elementIsOneIgnoringSign)
      hadToIgnoreSign = YES;
  }];
  result = !isNotOne;
  if (isOneIgnoringSign)
    *isOneIgnoringSign = hadToIgnoreSign;
  return result;
}
//end isOne:

-(BOOL) negate
{
  BOOL result = NO;
  __block BOOL error = NO;
  [self->values enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    CHChalkValue* element = [obj dynamicCastToClass:[CHChalkValue class]];
    BOOL negated = [element negate];
    if (!negated)
    {
      error = YES;
      *stop = YES;
    }}];
  result = !error;
  return result;
}
//end negate

-(void) adaptToComputeMode:(chalk_compute_mode_t)computeMode context:(CHChalkContext*)context
{
  [self->values enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    CHChalkValue* value = [obj dynamicCastToClass:[CHChalkValue class]];
    [value adaptToComputeMode:computeMode context:context];
  }];
}
//end adaptToComputeMode:context:

-(CHChalkValue*) valueAtSubscript:(CHChalkValueSubscript*)subscript context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (subscript)
  {
    if (subscript.count == 1)
    {
      id indexObject = [subscript indexAtIndex:0];
      NSNumber* indexNumber = [indexObject dynamicCastToClass:[NSNumber class]];
      CHChalkValueIndexRange* indexRange = [indexObject dynamicCastToClass:[CHChalkValueIndexRange class]];
      NSRange range =
        indexNumber ? NSMakeRange(indexNumber.unsignedIntegerValue, 1) :
        indexRange ? indexRange.joker ? NSMakeRange(0, self.count) : indexRange.range :
        NSRangeZero;
      if (indexNumber || indexRange)
      {
        if (range.location+range.length > self->values.count)
          [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorDimensionsMismatch range:subscript.token.range] context:context];
        else//if (range.location+range.length <= self->values.count)
        {
          if (indexNumber)
            result = [[[self->values objectAtIndex:range.location] copy] autorelease];
          else//if (indexRange)
          {
            NSArray* subValues = [self->values subarrayWithRange:range];
            result = !subValues ? nil :
              [[[[self class] alloc] initWithToken:subscript.token values:subValues context:context] autorelease];
          }//end if (indexRange)
          if (!result)
            [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorDimensionsMismatch range:subscript.token.range] context:context];
        }//end if (range.location+range.length <= self->values.count)
      }//end if (indexNumber || indexRange)
      else//if (!indexNumber && !indexRange)
        [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:subscript.token.range] context:context];
    }//end if (subscript.count == 1)
    else//if (subscript.count != 1)
      [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorDimensionsMismatch range:subscript.token.range] context:context];
  }//end if (subscript)
  else
    [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnimplemented range:subscript.token.range] context:context];
  return result;
}
//end valueAtSubscript:context:

-(BOOL) setValue:(CHChalkValue*)value atSubscript:(CHChalkValueSubscript*)subscript context:(CHChalkContext*)context
{
  BOOL result = NO;
  if (subscript)
  {
    if (subscript.count == 1)
    {
      id indexObject = [subscript indexAtIndex:0];
      NSNumber* indexNumber = [indexObject dynamicCastToClass:[NSNumber class]];
      CHChalkValueIndexRange* indexRange = [indexObject dynamicCastToClass:[CHChalkValueIndexRange class]];
      NSRange range =
        indexNumber ? NSMakeRange(indexNumber.unsignedIntegerValue, 1) :
        indexRange ? indexRange.joker ? NSMakeRange(0, self.count) :indexRange.range :
        NSRangeZero;
      if (indexNumber || indexRange)
      {
        if (range.location+range.length > self->values.count)
          [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorDimensionsMismatch range:subscript.token.range] context:context];
        else//if (range.location+range.length <= self->values.count)
        {
          BOOL error = NO;
          NSUInteger idx = 0;
          for(idx = range.location ; idx<range.location+range.length ; ++idx)
          {
            CHChalkValue* valueClone = [value copyWithZone:nil];
            if (!valueClone)
              [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:subscript.token.range] context:context];
            error |= !valueClone || ![self setValue:valueClone atIndex:idx];
            [valueClone release];
          }//end for each idx
          result = !error;
        }//end if (range.location+range.length <= self->values.count)
      }//end if (indexNumber || indexRange)
      else//(!indexNumber && !indexRange)
        [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:subscript.token.range] context:context];
    }//end if (subscript.count == 1)
    else//if (subscript.count != 1)
      [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorDimensionsMismatch range:subscript.token.range] context:context];
  }//end if (subscript)
  else
    [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnimplemented range:subscript.token.range] context:context];
  return result;
}
//end setValue:atSubscript:context:

-(CHChalkValue*) valueAtIndex:(NSUInteger)index;
{
  CHChalkValue* result = nil;
  if (index < self->values.count)
  {
    id element = [self->values objectAtIndex:index];
    result = [element dynamicCastToClass:[CHChalkValue class]];
  }//end if (index < self->values.count)
  return result;
}
//end valueAtIndex:

-(BOOL) setValue:(CHChalkValue*)value atIndex:(NSUInteger)index
{
  BOOL result = NO;
  if (value && (index < self->values.count))
  {
    [self->values replaceObjectAtIndex:index withObject:value];
    result = YES;
  }//end if (index < self->values.count)
  return result;
}
//end setValue:atIndex:

-(BOOL) addValue:(CHChalkValue*)value
{
  BOOL result = NO;
  if (value)
  {
    [self->values addObject:value];
    result = YES;
  }//end if (value)
  return result;
}
//end addValue

-(void) writeHeaderToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_MATHML)
    [stream writeString:@"<mfenced open=\"\" close=\"\" separators=\",\">"];
}
//end writeHeaderToStream:context:presentationConfiguration:

-(void) writeFooterToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_MATHML)
    [stream writeString:@"</mfenced>"];
}
//end writeFooterToStream:context:presentationConfiguration:

-(void) writeBodyToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  [self->values enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    CHChalkValue* elementValue = [obj dynamicCastToClass:[CHChalkValue class]];
    if (idx && (presentationConfiguration.description != CHALK_VALUE_DESCRIPTION_MATHML))
      [stream writeString:@","];
    [elementValue writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
  }];
}
//end writeBodyToStream:context:presentationConfiguration:

@end
