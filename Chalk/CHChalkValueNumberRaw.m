//
//  CHChalkValueNumberRaw.m
//  Chalk
//
//  Created by Pierre Chatelier on 14/02/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHChalkValueNumberRaw.h"

#import "CHChalkContext.h"
#import "CHChalkError.h"
#import "CHChalkErrorContext.h"
#import "CHChalkToken.h"
#import "CHChalkUtils.h"
#import "CHChalkValueNumberGmp.h"
#import "CHComputationConfiguration.h"
#import "CHGmpPool.h"
#import "CHPreferencesController.h"
#import "CHPresentationConfiguration.h"
#import "CHStreamWrapper.h"
#import "CHUtils.h"
#import "NSDataExtended.h"
#import "NSObjectExtended.h"
#import "NSMutableStringExtended.h"
#import "NSString+HTML.h"

@implementation CHChalkValueNumberRaw

@dynamic valueConstReference;
@dynamic valueReference;

+(BOOL) supportsSecureCoding {return YES;}

+(instancetype) zeroWithToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  id result = nil;
  CHChalkValueNumberRaw* zeroValue = [[[CHChalkValueNumberRaw alloc] initWithToken:token value:0 naturalBase:(!context ? 10 : context.computationConfiguration.baseDefault) context:context] autorelease];
  result = zeroValue;
  return result;
}
//end zeroWithToken:context:

-(instancetype) initWithToken:(CHChalkToken*)aToken context:(CHChalkContext*)context
{
  if (!((self = [super initWithToken:aToken context:context])))
    return nil;
  memset(&self->rawValue, 0, sizeof(self->rawValue));
  mpz_init(self->rawValue.bits);
  return self;
}
//end initWithToken:context:

-(instancetype) initWithToken:(CHChalkToken*)aToken value:(chalk_raw_value_t*)aValue naturalBase:(int)aNaturalBase context:(CHChalkContext*)context
{
  BOOL isBaseValid = chalkGmpBaseIsValid(aNaturalBase);
  if (!isBaseValid)
  {
    [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainGmp reason:CHChalkErrorGmpBaseInvalid range:aToken.range] context:context];
    [self release];
    return nil;
  }//end if (!isBaseValid)
  if (!((self = [super initWithToken:aToken context:context])))
    return nil;
  if (aValue)
    chalkRawValueMove(&self->rawValue, aValue, context.gmpPool);
  self->naturalBase = aNaturalBase;
  return self;
}
//end initWithToken:value:naturalBase:errorContext:

-(instancetype) initWithCoder:(NSCoder*)aDecoder
{
  if (!((self = [super initWithCoder:aDecoder])))
    return nil;
  self->rawValue = plistToRawValue([aDecoder decodeObjectForKey:@"rawValue"]);
  return self;
}
//end initWithCoder:

-(void)dealloc
{
  if (!self->isValueWapperOnly)
    chalkRawValueClear(&self->rawValue, YES, [CHGmpPool peek]);
  [super dealloc];
}
//end dealloc

-(void) encodeWithCoder:(NSCoder*)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:plistFromRawValue(self->rawValue) forKey:@"rawValue"];
}
//end encodeWithCoder:

-(id) copyWithZone:(NSZone*)zone
{
  CHChalkValueNumberRaw* result = [super copyWithZone:zone];
  if (result)
    chalkRawValueSet(&result->rawValue, &self->rawValue, [CHGmpPool peek]);
  return result;
}
//end copyWithZone:

-(void) setValueReference:(chalk_raw_value_t*)newRawValue clearPrevious:(BOOL)clearPrevious isValueWapperOnly:(BOOL)aIsValueWapperOnly
{
  if (!newRawValue)
    chalkRawValueClear(&self->rawValue, clearPrevious, [CHGmpPool peek]);
  else//if (newValue)
  {
    if (clearPrevious && !self->isValueWapperOnly)
      chalkRawValueClear(&self->rawValue, YES, [CHGmpPool peek]);
    self->rawValue = *newRawValue;
  }//end if (newValue)
  self->isValueWapperOnly = aIsValueWapperOnly;
}
//end setValueReference:clearPrevious:

-(BOOL) moveTo:(CHChalkValue*)dst
{
  BOOL result = [super moveTo:dst];
  CHChalkValueNumberRaw* dstRaw = !result ? nil : [dst dynamicCastToClass:[CHChalkValueNumberRaw class]];
  if (dstRaw)
  {
    chalkRawValueClear(&dstRaw->rawValue, YES, [CHGmpPool peek]);
    dstRaw->rawValue = self->rawValue;
    chalkRawValueClear(&self->rawValue, NO, [CHGmpPool peek]);
    result = YES;
  }//end if (dstRaw)
  return result;
}
//end moveTo:

-(BOOL) isZero
{
  BOOL result =
    !(self->rawValue.flags & CHALK_RAW_VALUE_FLAG_INFINITY) &&
    !(self->rawValue.flags & CHALK_RAW_VALUE_FLAG_NAN) &&
    !mpz_cmp_si(self->rawValue.bits, 0);
  return result;
}
//end isZero

-(BOOL) isOne:(BOOL*)isOneIgnoringSign;
{
  BOOL result =
    !(self->rawValue.flags & CHALK_RAW_VALUE_FLAG_INFINITY) &&
    !(self->rawValue.flags & CHALK_RAW_VALUE_FLAG_NAN) &&
    (!mpz_cmp_si(self->rawValue.bits, -1) || !mpz_cmp_si(self->rawValue.bits, 1));
  return result;
}
//end isOne:

-(BOOL) negate
{
  BOOL result = YES;
  if (((self->rawValue.flags & CHALK_RAW_VALUE_FLAG_POSITIVE) == 0) &&
      ((self->rawValue.flags & CHALK_RAW_VALUE_FLAG_NEGATIVE) != 0))
  {
    self->rawValue.flags |= CHALK_RAW_VALUE_FLAG_POSITIVE;
    self->rawValue.flags &= ~CHALK_RAW_VALUE_FLAG_NEGATIVE;
  }//end if (((self->value.flags & CHALK_RAW_VALUE_FLAG_POSITIVE) == 0) && ((self->value.flags & CHALK_RAW_VALUE_FLAG_NEGATIVE) != 0))
  else if (((self->rawValue.flags & CHALK_RAW_VALUE_FLAG_POSITIVE) != 0) &&
           ((self->rawValue.flags & CHALK_RAW_VALUE_FLAG_NEGATIVE) == 0))
  {
    self->rawValue.flags &= CHALK_RAW_VALUE_FLAG_POSITIVE;
    self->rawValue.flags |= ~CHALK_RAW_VALUE_FLAG_NEGATIVE;
  }//end if (((self->value.flags & CHALK_RAW_VALUE_FLAG_POSITIVE) != 0) && ((self->value.flags & CHALK_RAW_VALUE_FLAG_NEGATIVE) == 0))
  else if (((self->rawValue.flags & CHALK_RAW_VALUE_FLAG_POSITIVE) == 0) &&
           ((self->rawValue.flags & CHALK_RAW_VALUE_FLAG_NEGATIVE) == 0))
  {
    self->rawValue.flags |= CHALK_RAW_VALUE_FLAG_POSITIVE;
    self->rawValue.flags |= CHALK_RAW_VALUE_FLAG_NEGATIVE;
  }//end if (((self->value.flags & CHALK_RAW_VALUE_FLAG_POSITIVE) == 0) && ((self->value.flags & CHALK_RAW_VALUE_FLAG_NEGATIVE) == 0))
  else if (((self->rawValue.flags & CHALK_RAW_VALUE_FLAG_POSITIVE) != 0) &&
           ((self->rawValue.flags & CHALK_RAW_VALUE_FLAG_NEGATIVE) != 0))
  {
    self->rawValue.flags &= ~CHALK_RAW_VALUE_FLAG_POSITIVE;
    self->rawValue.flags &= ~CHALK_RAW_VALUE_FLAG_NEGATIVE;
  }//end if (((self->value.flags & CHALK_RAW_VALUE_FLAG_POSITIVE) != 0) && ((self->value.flags & CHALK_RAW_VALUE_FLAG_NEGATIVE) != 0))
  return result;
}
//end negate

-(NSInteger) sign
{
  NSInteger result =
    ((self->rawValue.flags & CHALK_RAW_VALUE_FLAG_NEGATIVE) == (self->rawValue.flags & CHALK_RAW_VALUE_FLAG_POSITIVE)) ? 0 :
    ((self->rawValue.flags & CHALK_RAW_VALUE_FLAG_NEGATIVE) != 0) ? -1 :
    ((self->rawValue.flags & CHALK_RAW_VALUE_FLAG_POSITIVE) != 0) ? 1 :
    0;
  return result;
}
//end sign

-(const chalk_raw_value_t*) valueConstReference
{
  return &self->rawValue;
}
//end valueConstReference

-(chalk_raw_value_t*) valueReference
{
  return &self->rawValue;
}
//end valueReference

-(CHChalkValueNumberGmp*) convertToGmpValueWithContext:(CHChalkContext*)context
{
  CHChalkValueNumberGmp* result = nil;
  chalk_gmp_value_t gmpValue = {0};
  if (self->rawValue.bitInterpretation.numberEncoding.encodingType == CHALK_NUMBER_ENCODING_UNDEFINED){
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorConversionNoRepresentation range:self.token.range] replace:NO];
  }//end if (self->naturalBitInterpretation.numberEncoding.encodingType == CHALK_NUMBER_ENCODING_UNDEFINED)
  else if (getEncodingIsInteger(self->rawValue.bitInterpretation.numberEncoding))
  {
    chalkGmpValueMakeInteger(&gmpValue, context.gmpPool);
  }//end if (getEncodingIsInteger(self->rawValue.bitInterpretation.numberEncoding))
  else
  {
    chalkGmpValueMakeReal(&gmpValue, getSignificandBitsCountForEncoding(self->rawValue.bitInterpretation.numberEncoding, YES), context.gmpPool);
  }
  if (gmpValue.type == CHALK_VALUE_TYPE_UNDEFINED)
  {
    CHChalkError* error = [CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:self.token.range];
    [context.errorContext setError:error replace:NO];
  }//end if (gmpValue.type == CHALK_VALUE_TYPE_UNDEFINED)
  else//if (gmpValue.type != CHALK_VALUE_TYPE_UNDEFINED)
  {
    chalkGmpValueSetZero(&gmpValue, YES, context.gmpPool);
    interpretFromRawToValue(&gmpValue, &self->rawValue, context.computationConfiguration.computeMode, &self->rawValue.bitInterpretation, context);
    result = [[[CHChalkValueNumberGmp alloc] initWithToken:self.token value:&gmpValue naturalBase:context.computationConfiguration.baseDefault context:context] autorelease];
    if (!result)
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:self.token.range] replace:NO];
  }//end if (gmpValue.type != CHALK_VALUE_TYPE_UNDEFINED)
  chalkGmpValueClear(&gmpValue, YES, context.gmpPool);
  return result;
}
//end convertToGmpValueWithContext

-(void) writeBodyToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  @autoreleasepool{
    CHChalkValueNumberGmp* gmpValue = [self convertToGmpValueWithContext:context];
    if (!gmpValue)
      [stream writeString:[context.errorContext.error.friendlyDescription encodeHTMLCharacterEntities]];
    else//if (!gmpValue)
      [gmpValue writeBodyToStream:stream context:context presentationConfiguration:presentationConfiguration];
  }//end @autoreleasepool
}
//end writeBodyToStream:description:options:

@end
