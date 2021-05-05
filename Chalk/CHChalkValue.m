//
//  CHChalkValue.m
//  Chalk
//
//  Created by Pierre Chatelier on 16/02/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHChalkValue.h"

#import "CHChalkContext.h"
#import "CHChalkError.h"
#import "CHChalkErrorContext.h"
#import "CHChalkValueMatrix.h"
#import "CHChalkValueNumberGmp.h"
#import "CHChalkValueQuaternion.h"
#import "CHChalkValueMovable.h"
#import "CHChalkToken.h"
#import "CHChalkUtils.h"
#import "CHComputationConfiguration.h"
#import "CHPresentationConfiguration.h"
#import "CHStreamWrapper.h"
#import "NSObjectExtended.h"

@implementation CHChalkValue

@synthesize token;
@synthesize naturalBase;
@synthesize evaluationComputeFlags;
@dynamic    evaluationErrors;
@dynamic    isZero;

+(BOOL) supportsSecureCoding {return YES;}

-(instancetype) init
{
  if (!((self = [super init])))
    return nil;
  return self;
}
//end init

-(instancetype) initWithToken:(CHChalkToken*)aToken context:(CHChalkContext*)context
{
  if (!((self = [self init])))
    return nil;
  self->token = [aToken copy];
  self->naturalBase = context.computationConfiguration.baseDefault;
  self->evaluationErrors = [[NSMutableArray alloc] init];
  return self;
}
//end initWithToken:

-(instancetype) initWithToken:(CHChalkToken*)aToken naturalBase:(int)aNaturalBase context:(CHChalkContext*)context
{
  if (!((self = [self initWithToken:aToken context:context])))
    return nil;
  self->naturalBase = aNaturalBase;
  return self;
}
//end initWithToken:naturalBase:

-(instancetype) initWithCoder:(NSCoder*)aDecoder
{
  if (!((self = [super init])))
    return nil;
  self->token = [[aDecoder decodeObjectOfClass:[CHChalkToken class] forKey:@"token"] retain];
  self->naturalBase = [aDecoder decodeInt32ForKey:@"naturalBase"];
  self->evaluationComputeFlags = [aDecoder decodeInt32ForKey:@"evaluationComputeFlags"];
  self->evaluationErrors = [[aDecoder decodeObjectOfClass:[NSMutableArray class] forKey:@"evaluationErrors"] retain];
  return self;
}
//end initWithCoder:

-(void) encodeWithCoder:(NSCoder*)aCoder
{
  [aCoder encodeObject:self->token forKey:@"token"];
  [aCoder encodeInt32:self->naturalBase forKey:@"naturalBase"];
  [aCoder encodeInt32:(int)self->evaluationComputeFlags forKey:@"evaluationComputeFlags"];
  [aCoder encodeObject:self->evaluationErrors forKey:@"evaluationErrors"];
}
//end encodeWithCoder:

-(void)dealloc
{
  [self->token release];
  [self->evaluationErrors release];
  [super dealloc];
}
//end dealloc

-(id) copyWithZone:(NSZone*)zone
{
  CHChalkValue* result = [[[self class] allocWithZone:zone] initWithToken:self->token context:nil];
  if (result)
  {
    result->naturalBase = self->naturalBase;
    result->evaluationComputeFlags = self->evaluationComputeFlags;
    [result->evaluationErrors setArray:[[self->evaluationErrors copyWithZone:zone] autorelease]];
  }//end if (result)
  return result;
}
//end copyWithZone:

-(void) replaceToken:(CHChalkToken*)aToken
{
  if (aToken != self->token)
  {
    [self->token release];
    self->token = [aToken copy];
  }//end if (aToken != self->token)
}
//end replaceToken:

-(CHChalkValue*) move
{
  CHChalkValue* result = [[[[self class] alloc] init] autorelease];
  [self moveTo:result];
  return result;
}
//end move

-(BOOL) moveTo:(CHChalkValue*)dst
{
  BOOL result = (dst != nil);
  if (result && dst)
  {
    dst->token = self->token;
    self->token = nil;
    dst->naturalBase = self->naturalBase;
    self->naturalBase = 0;
    dst->evaluationComputeFlags = self->evaluationComputeFlags;
    self->evaluationComputeFlags = 0;
    dst->evaluationErrors = self->evaluationErrors;
    self->evaluationErrors = nil;
  }//end if (result)
  return result;
}
//end moveTo:

+(instancetype) null
{
  CHChalkValue* result = [[[[self class] alloc] initWithToken:[CHChalkToken chalkTokenEmpty] context:nil] autorelease];
  return result;
}
//end null

+(instancetype) zeroWithToken:(CHChalkToken*)token  context:(CHChalkContext*)context {return nil;}

-(BOOL) isZero
{
  return NO;
}
//end isZero

-(BOOL) isOne:(BOOL*)isOneIgnoringSign
{
  return NO;
}
//end isOne:

-(BOOL) negate
{
  return NO;
}
//end negate

-(void) adaptToComputeMode:(chalk_compute_mode_t)computeMode context:(CHChalkContext*)context
{
}
//end adaptToComputeMode:context:

-(void) addError:(CHChalkError*)error
{
  if (error)
  {
    @synchronized(self->evaluationErrors)
    {
      [self->evaluationErrors addObject:error];
    }//end @synchronized(self->evaluationErrors)
  }//end if (error)
}
//end addError:

-(void) addError:(CHChalkError*)error context:(CHChalkContext*)context
{
  [self addError:error];
  [context.errorContext setError:error replace:NO];
}
//end addError:context:

-(void) writeToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  [self writeHeaderToStream:stream context:context presentationConfiguration:presentationConfiguration];
  [self writeBodyToStream:stream context:context presentationConfiguration:presentationConfiguration];
  [self writeFooterToStream:stream context:context presentationConfiguration:presentationConfiguration];
}
//end writeToStream:description:

-(void) writeHeaderToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
}
//end writeHeaderToStream:description:

-(void) writeBodyToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
}
//end writeBodyToStream:description:

-(void) writeFooterToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
}
//end writeFooterToStream:description:

+(void) writeToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context numberString:(NSString*)numberString presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_MATHML)
    [stream writeString:@"<mn>"];
  [stream writeString:numberString];
  if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_MATHML)
    [stream writeString:@"</mn>"];
}
//end writeToStream:context:description:numberString:

+(void) writeToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context operatorString:(NSString*)operatorString presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_MATHML)
    [stream writeString:@"<mo>"];
  [stream writeString:operatorString];
  if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_MATHML)
    [stream writeString:@"</mo>"];
}
//end writeToStream:context:description:operatorString:

+(CHChalkValue*) simplify:(CHChalkValue**)pValue context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  CHChalkValue* value = !pValue ? nil : *pValue;
  result = value;
  //do not simplify matrix to keep nature of objects
  CHChalkValueQuaternion* valueQuaternion = [value dynamicCastToClass:[CHChalkValueQuaternion class]];
  if (valueQuaternion && valueQuaternion.isReal)
  {
    result = [valueQuaternion.partReal copy];
    [value release];
    value = nil;
    valueQuaternion = nil;
  }//end if (valueQuaternion && valueQuaternion.isReal)
  CHChalkValueNumberGmp* resultGmp = [result dynamicCastToClass:[CHChalkValueNumberGmp class]];
  if (resultGmp)
    chalkGmpValueSimplify(resultGmp.valueReference, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
  if (pValue)
    *pValue = result;
  return result;
}
//end simplify:context:

+(NSMutableArray*) copyValues:(NSArray*)values withZone:(NSZone*)zone
{
  __block NSMutableArray* result = [values mutableCopyWithZone:zone];
  [result enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    id<NSMutableCopying> objMutableCopyable = [obj dynamicCastToProtocol:@protocol(NSMutableCopying)];
    id<NSCopying> objCopyable = [obj dynamicCastToProtocol:@protocol(NSCopying)];
    CHChalkValue* value = [obj dynamicCastToClass:[CHChalkValue class]];
    CHChalkValue* valueClone =
      value ? [value copyWithZone:zone] :
      objMutableCopyable ? [objMutableCopyable mutableCopyWithZone:zone] :
      objCopyable ? [objCopyable copyWithZone:zone] :
      nil;
    if (valueClone)
    {
      [result replaceObjectAtIndex:idx withObject:valueClone];
      [valueClone release];
    }//end if (valueClone)
    else//if (!valueClone)
    {
      @synchronized(self)
      {
        [result release];
        result = nil;
      }//end @synchronized(self)
      *stop = YES;
    }//end if (!valueClone)
  }];
  return result;
}
//end copyValues:withZone:zone

+(CHChalkValue*) finalizeValue:(CHChalkValue**)pValue context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  CHChalkValue* value = !pValue ? nil : *pValue;
  if (!value){
  }
  else if (context.errorContext.hasError)
    [value release];
  else//if (!context.errorContext.hasError)
  {
    @autoreleasepool {
      result = [CHChalkValue simplify:pValue context:context];
      if (result != value)
        [result retain];
    }//end @autoreleasepool
    if (result != value)
      [result release];
  }//end if (!context.errorContext.hasError)
  if (pValue)
    *pValue = result;
  return result;
}
//end finalizeValue:context:

-(NSString*) description
{
  NSString* result = nil;
  CHStreamWrapper* stream = [[CHStreamWrapper alloc] init];
  stream.stringStream = [NSMutableString string];
  [self writeToStream:stream context:nil presentationConfiguration:nil];
  result = stream.stringStream;
  [stream release];
  return result;
}
//end description

@end
