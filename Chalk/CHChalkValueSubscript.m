//
//  CHChalkValueSubscript.m
//  Chalk
//
//  Created by Pierre Chatelier on 14/11/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHChalkValueSubscript.h"

#import "CHChalkContext.h"
#import "CHChalkError.h"
#import "CHChalkErrorContext.h"
#import "CHChalkToken.h"
#import "CHChalkValueIndexRange.h"
#import "CHPresentationConfiguration.h"
#import "CHStreamWrapper.h"
#import "NSObjectExtended.h"

@implementation CHChalkValueSubscript

@dynamic count;
@synthesize indices;

+(BOOL) supportsSecureCoding {return YES;}

-(instancetype) initWithToken:(CHChalkToken*)aToken indices:(NSArray*)aIndices context:(CHChalkContext*)context
{
  if (!((self = [super initWithToken:aToken context:context])))
    return nil;
  __block NSMutableArray* buildingIndices = [[NSMutableArray alloc] init];
  [aIndices enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    NSNumber* indexNumber = [[obj dynamicCastToClass:[NSNumber class]] copy];
    CHChalkValueIndexRange* indexRange = [[obj dynamicCastToClass:[CHChalkValueIndexRange class]] copy];
    if (indexNumber)
      [buildingIndices addObject:indexNumber];
    else if (indexRange)
      [buildingIndices addObject:indexRange];
    else
    {
      [buildingIndices release];
      buildingIndices = nil;
      [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:aToken.range] context:context];
    }//end if (indexNumber)
    [indexNumber release];
    [indexRange release];
  }];
  self->indices = [buildingIndices copy];
  [buildingIndices release];
  if (!self->indices)
  {
    [self release];
    return nil;
  }//end if (!self->indices)
  return self;
}
//end initWithToken:indices:

-(instancetype) initWithCoder:(NSCoder*)aDecoder
{
  if (!((self = [super initWithCoder:aDecoder])))
    return nil;
  self->indices = [[aDecoder decodeObjectOfClass:[NSArray class] forKey:@"indices"] retain];
  return self;
}
//end initWithCoder:

-(void) encodeWithCoder:(NSCoder*)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:self->indices forKey:@"indices"];
}
//end encodeWithCoder:

-(void) dealloc
{
  [self->indices release];
  [super dealloc];
}
//end dealloc

-(id) copyWithZone:(NSZone*)zone
{
  CHChalkValueSubscript* result = [super copyWithZone:zone];
  if (result)
    result->indices = [self->indices copyWithZone:zone];
  return result;
}
//end copyWithZone:

-(BOOL) moveTo:(CHChalkValue*)dst
{
  BOOL result = [super moveTo:dst];
  CHChalkValueSubscript* dstSubscript = !result ? nil : [dst dynamicCastToClass:[CHChalkValueSubscript class]];
  if (result && dstSubscript)
  {
    dstSubscript->indices = self->indices;
    self->indices = nil;
  }//end if (result && dstSubscript)
  return result;
}
//end moveTo:

-(NSUInteger) count
{
  NSUInteger result = self->indices.count;
  return result;
}
//end count

-(id) indexAtIndex:(NSUInteger)index
{
  id result = (index >= self->indices.count) ? nil : [self->indices objectAtIndex:index];
  return result;
}
//end indexAtIndex:

-(void) writeHeaderToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_MATHML)
    [stream writeString:@"<mfenced open=\"[\" close=\"]\" separators=\",\">"];
  else
    [stream writeString:@"["];
}
//end writeHeaderToStream:context:options:

-(void) writeFooterToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_MATHML)
    [stream writeString:@"</mfenced>"];
  else
    [stream writeString:@"]"];
}
//end writeFooterToStream:context:options:

-(void) writeBodyToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  [self->indices enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    NSNumber* indexNumber = [obj dynamicCastToClass:[NSNumber class]];
    CHChalkValue* indexValue = [obj dynamicCastToClass:[CHChalkValue class]];
    if (idx && (presentationConfiguration.description != CHALK_VALUE_DESCRIPTION_MATHML))
      [stream writeString:@","];
    if (indexNumber)
      [stream writeString:[indexNumber stringValue]];
    else if (indexValue)
      [indexValue writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
  }];
}
//end writeBodyToStream:description:options:

@end
