//
//  CHChalkValueNumberGmp.m
//  Chalk
//
//  Created by Pierre Chatelier on 14/02/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHChalkValueNumberGmp.h"

#import "CHChalkContext.h"
#import "CHChalkError.h"
#import "CHChalkErrorContext.h"
#import "CHChalkToken.h"
#import "CHChalkUtils.h"
#import "CHComputationConfiguration.h"
#import "CHGmpPool.h"
#import "CHPreferencesController.h"
#import "CHPresentationConfiguration.h"
#import "CHStreamWrapper.h"
#import "CHUtils.h"
#import "NSObjectExtended.h"
#import "NSMutableStringExtended.h"
#import "NSDataExtended.h"

@interface CHChalkValueNumberGmp()
+(void) writeMpfrToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context value:(mpfr_srcptr)value rounding:(mpfr_rnd_t)rounding nbDigits:(NSUInteger)nbDigits token:(CHChalkToken*)token presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;
@end

@implementation CHChalkValueNumberGmp

@dynamic valueType;
@dynamic valueConstReference;
@dynamic valueReference;

+(BOOL) supportsSecureCoding {return YES;}

+(instancetype) zeroWithToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  id result = nil;
  CHChalkValueNumberGmp* zeroValue = [[[CHChalkValueNumberGmp alloc] initWithToken:token integer:0 naturalBase:(!context ? 10 : context.computationConfiguration.baseDefault) context:context] autorelease];
  result = zeroValue;
  return result;
}
//end zeroWithToken:context:

+(CHChalkValueNumberGmp*) nanWithContext:(CHChalkContext*)context
{
  id result = nil;
  chalk_gmp_value_t value = {0};
  chalkGmpValueSetNan(&value, NO, nil);
  CHChalkValueNumberGmp* valueNumberGmp =
    [[[[self class] alloc] initWithToken:[CHChalkToken chalkTokenEmpty] value:&value naturalBase:(!context ? 10 : context.computationConfiguration.baseDefault) context:context] autorelease];
  chalkGmpValueClear(&value, YES, nil);
  result = valueNumberGmp;
  return result;
}
//end nanWithContext:

+(CHChalkValueNumberGmp*) infinityWithContext:(CHChalkContext*)context
{
  id result = nil;
  chalk_gmp_value_t value = {0};
  chalkGmpValueSetInfinity(&value, 1, NO, nil);
  CHChalkValueNumberGmp* valueNumberGmp =
    [[[[self class] alloc] initWithToken:[CHChalkToken chalkTokenEmpty] value:&value naturalBase:(!context ? 10 : context.computationConfiguration.baseDefault) context:context] autorelease];
  chalkGmpValueClear(&value, YES, nil);
  result = valueNumberGmp;
  return result;
}
//end infinityWithContext:

-(instancetype) initWithToken:(CHChalkToken*)aToken context:(CHChalkContext*)context
{
  if (!((self = [super initWithToken:aToken context:context])))
    return nil;
  self->value.type = CHALK_VALUE_TYPE_UNDEFINED;
  return self;
}
//end initWithToken:context:

-(instancetype) initWithToken:(CHChalkToken*)aToken integer:(NSInteger)integer naturalBase:(int)aNaturalBase context:(CHChalkContext*)context
{
  chalk_gmp_value_t integerValue = {0};
  chalkGmpValueMakeInteger(&integerValue, context.gmpPool);
  mpz_set_nssi(integerValue.integer, integer);
  self = [self initWithToken:aToken value:&integerValue naturalBase:aNaturalBase context:context];
  chalkGmpValueClear(&integerValue, YES, context.gmpPool);
  return self;
}
//end initWithToken:integer:naturalBase:errorContext:

-(instancetype) initWithToken:(CHChalkToken*)aToken uinteger:(NSUInteger)uinteger naturalBase:(int)aNaturalBase context:(CHChalkContext*)context
{
  chalk_gmp_value_t integerValue = {0};
  chalkGmpValueMakeInteger(&integerValue, context.gmpPool);
  mpz_set_nsui(integerValue.integer, uinteger);
  self = [self initWithToken:aToken value:&integerValue naturalBase:aNaturalBase context:context];
  chalkGmpValueClear(&integerValue, YES, context.gmpPool);
  return self;
}
//end initWithToken:uinteger:naturalBase:errorContext:

-(instancetype) initWithToken:(CHChalkToken*)aToken cgfloat:(CGFloat)cgfloat naturalBase:(int)aNaturalBase context:(CHChalkContext*)context
{
  chalk_gmp_value_t floatValue = {0};
  chalkGmpValueMakeReal(&floatValue, 8*sizeof(CGFloat), context.gmpPool);
  chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
  mpfr_set_d(floatValue.realExact, cgfloat, MPFR_RNDN);
  if (mpfr_inexflag_p())
  {
    chalkGmpValueMakeRealApprox(&floatValue, 8*sizeof(CGFloat), context.gmpPool);
    mpfir_set_d(floatValue.realApprox, cgfloat);
  }//end if (mpfr_inexflag_p())
  self->evaluationComputeFlags = chalkGmpFlagsMake();
  chalkGmpFlagsRestore(oldFlags);
  self = [self initWithToken:aToken value:&floatValue naturalBase:aNaturalBase context:context];
  chalkGmpValueClear(&floatValue, YES, context.gmpPool);
  return self;
}
//end initWithToken:uinteger:naturalBase:errorContext:

-(instancetype) initWithToken:(CHChalkToken*)aToken value:(chalk_gmp_value_t*)aValue naturalBase:(int)aNaturalBase context:(CHChalkContext*)context
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
  {
    BOOL isIntegerOverflow = NO;
    if (context && (context.computationConfiguration.softIntegerMaxBits < 8*sizeof(NSUInteger)))
    {
      if (aValue->type == CHALK_VALUE_TYPE_INTEGER)
      {
        mpz_t maxValue;
        mpzDepool(maxValue, context.gmpPool);
        mpz_set_si(maxValue, 1);
        mpz_mul_2exp(maxValue, maxValue, context.computationConfiguration.softIntegerMaxBits);
        mpz_sub_ui(maxValue, maxValue, 1);
        isIntegerOverflow |= (mpz_cmp(aValue->integer, maxValue) > 0);
        mpzRepool(maxValue, context.gmpPool);
      }//end if (aValue->type == CHALK_VALUE_TYPE_INTEGER)
      else if (aValue->type == CHALK_VALUE_TYPE_FRACTION)
      {
        mpz_t maxValue;
        mpzDepool(maxValue, context.gmpPool);
        mpz_set_si(maxValue, 1);
        mpz_mul_2exp(maxValue, maxValue, context.computationConfiguration.softIntegerMaxBits);
        mpz_sub_ui(maxValue, maxValue, 1);
        isIntegerOverflow |= (mpz_cmp(mpq_numref(aValue->fraction), maxValue) > 0) ||
                             (mpz_cmp(mpq_denref(aValue->fraction), maxValue) > 0);
        mpzRepool(maxValue, context.gmpPool);
      }//end if (aValue->type == CHALK_VALUE_TYPE_INTEGER)
    }//end if (context && (context.softIntegerMaxBits < 8*sizeof(NSUInteger)))
    if (isIntegerOverflow)
    {
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorIntegerOverflow] replace:NO];
      [self release];
      return nil;
    }//end if (isIntegerOverflow)
    self->value = *aValue;
    chalkGmpValueClear(aValue, NO, context.gmpPool);
  }//end if (aValue)
  self->naturalBase = aNaturalBase;
  return self;
}
//end initWithToken:value:naturalBase:errorContext:

-(instancetype) initWithIntegerTypeToken:(CHChalkToken*)aToken base:(int)base context:(CHChalkContext*)context
{
  BOOL isBaseValid = chalkGmpBaseIsValid(base);
  if (!isBaseValid)
  {
    [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainGmp reason:CHChalkErrorGmpBaseInvalid range:aToken.range] context:context];
    [self release];
    return nil;
  }//end if (!isBaseValid)
  if (!((self = [super initWithToken:aToken naturalBase:base context:context])))
    return nil;
  self->value.type = CHALK_VALUE_TYPE_INTEGER;
  mpzDepool(self->value.integer, context.gmpPool);
  int gmpError = mpz_set_str(self->value.integer, [self->token.value UTF8String], self->naturalBase);
  if (gmpError)
  {
    [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainGmp reason:CHChalkErrorGmpValueCannotInit range:self->token.range] context:context];
    [self release];
    return nil;
  }//end if (gmpError)
  return self;
}
//end initWithIntegerTypeToken:base:context:

-(instancetype) initWithRealTypeToken:(CHChalkToken*)aToken base:(int)base precision:(mpfr_prec_t)precision context:(CHChalkContext*)context
{
  BOOL isBaseValid = chalkGmpBaseIsValid(base);
  if (!isBaseValid)
  {
    [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainGmp reason:CHChalkErrorGmpBaseInvalid range:aToken.range] context:context];
    [self release];
    return nil;
  }//end if (!isBaseValid)
  if (!((self = [super initWithToken:aToken context:context])))
    return nil;
  const char* utf8Token = [self->token.value UTF8String];
  chalkGmpValueMakeRealExact(&self->value, precision, context.gmpPool);
  mpfr_clear_flags();
  int gmpError = mpfr_set_str(self->value.realExact, utf8Token, self->naturalBase, MPFR_RNDN);
  if (!gmpError)
  {
    if (mpfr_inexflag_p())
    {
      chalkGmpValueMakeRealApprox(&self->value, precision, context.gmpPool);
      mpfr_clear_flags();
      mpfir_set_str(self->value.realApprox, utf8Token, self->naturalBase);
      self->evaluationComputeFlags = chalkGmpFlagsMake() |
        chalkGmpFlagsAdd(self->evaluationComputeFlags, CHALK_COMPUTE_FLAG_INEXACT);
    }//end if (mpfr_inexflag_p())
    if (mpfr_overflow_p())
    {
      [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainGmp reason:CHChalkErrorGmpOverflow range:self->token.range] context:context];
      [self release];
      return nil;
    }//end if (mpfr_overflow_p())
    else if (mpfr_underflow_p())
    {
      [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainGmp reason:CHChalkErrorGmpUnderflow range:self->token.range] context:context];
      [self release];
      return nil;
    }//end if (mpfr_underflow_p())
    else
      chalkGmpValueSimplify(&self->value, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
  }//end if (!gmpError)
  else//if (gmpError)
  {
    [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainGmp reason:CHChalkErrorGmpValueCannotInit range:self->token.range] context:context];
    [self release];
    return nil;
  }//end if (gmpError)
  return self;
}
//end initWithRealTypeToken:precision:errorContext:

-(instancetype) initWithCoder:(NSCoder*)aDecoder
{
  if (!((self = [super initWithCoder:aDecoder])))
    return nil;
  chalk_value_gmp_type_t type = [aDecoder decodeInt32ForKey:@"type"];
  NSData* data1 = [aDecoder decodeObjectOfClass:[NSData class] forKey:@"data1"];
  NSData* data2 = [aDecoder decodeObjectOfClass:[NSData class] forKey:@"data2"];
  NSData* data3 = [aDecoder decodeObjectOfClass:[NSData class] forKey:@"data3"];
  FILE* file1 = [data1 openAsFile];
  FILE* file2 = [data2 openAsFile];
  FILE* file3 = [data3 openAsFile];
  NSUInteger prec = [[aDecoder decodeObjectOfClass:[NSNumber class] forKey:@"prec"] unsignedIntegerValue];
  prec = MIN(MAX(prec, MPFR_PREC_MIN), MPFR_PREC_MAX);
  chalkGmpValueMake(&self->value, type, prec, [CHGmpPool peek]);
  switch(self->value.type)
  {
    case CHALK_VALUE_TYPE_UNDEFINED:
      break;
    case CHALK_VALUE_TYPE_INTEGER:
      mpz_inp_raw(self->value.integer, file1);
      break;
    case CHALK_VALUE_TYPE_FRACTION:
      mpq_inp_str(self->value.fraction, file1, 62);
      break;
    case CHALK_VALUE_TYPE_REAL_EXACT:
      mpfr_inp_str(self->value.realExact, file1, 62, MPFR_RNDN);
      break;
    case CHALK_VALUE_TYPE_REAL_APPROX:
      mpfir_inp_str(self->value.realApprox, file1, file2, file3, 62, 62, 62, MPFR_RNDN, MPFR_RNDN, MPFR_RNDN);
      break;
  }//end switch(self->value.type)
  if (file1)
    fclose(file1);
  if (file2)
    fclose(file2);
  if (file3)
    fclose(file3);
  return self;
}
//end initWithCoder:

-(void)dealloc
{
  if (!self->isValueWapperOnly)
    chalkGmpValueClear(&self->value, YES, [CHGmpPool peek]);
  [super dealloc];
}
//end dealloc

-(void) encodeWithCoder:(NSCoder*)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeInt32:(int)self->value.type forKey:@"type"];
  NSMutableData* data1 = nil;
  NSMutableData* data2 = nil;
  NSMutableData* data3 = nil;
  FILE* file1 = 0;
  FILE* file2 = 0;
  FILE* file3 = 0;
  NSUInteger prec = 0;
  switch(self->value.type)
  {
    case CHALK_VALUE_TYPE_UNDEFINED:
      break;
    case CHALK_VALUE_TYPE_INTEGER:
      data1 = [[NSMutableData alloc] init];
      file1 = [data1 openAsFile];
      mpz_out_raw(file1, self->value.integer);
      break;
    case CHALK_VALUE_TYPE_FRACTION:
      data1 = [[NSMutableData alloc] init];
      file1 = [data1 openAsFile];
      mpq_out_str(file1, 62, self->value.fraction);
      break;
    case CHALK_VALUE_TYPE_REAL_EXACT:
      prec = mpfr_get_prec(self->value.realExact);
      data1 = [[NSMutableData alloc] init];
      file1 = [data1 openAsFile];
      mpfr_out_str(file1, 62, 0, self->value.realExact, MPFR_RNDN);
      break;
    case CHALK_VALUE_TYPE_REAL_APPROX:
      prec = mpfir_get_prec(self->value.realApprox);
      data1 = [[NSMutableData alloc] init];
      file1 = [data1 openAsFile];
      data2 = [[NSMutableData alloc] init];
      file2 = [data2 openAsFile];
      data3 = [[NSMutableData alloc] init];
      file3 = [data3 openAsFile];
      mpfir_out_str(file1, file2, file3, 62, 62, 62, 0, 0, 0, self->value.realApprox, MPFR_RNDN, MPFR_RNDN, MPFR_RNDN);
      break;
  }//end switch(self->value.type)
  [aCoder encodeObject:@(prec) forKey:@"prec"];
  if (file1)
    fclose(file1);
  if (file2)
    fclose(file2);
  if (file3)
    fclose(file3);
  if (data1)
    [aCoder encodeObject:data1 forKey:@"data1"];
  if (data2)
    [aCoder encodeObject:data2 forKey:@"data2"];
  if (data3)
    [aCoder encodeObject:data3 forKey:@"data3"];
  [data1 release];
  [data2 release];
  [data3 release];
}
//end encodeWithCoder:

-(id) copyWithZone:(NSZone*)zone
{
  CHChalkValueNumberGmp* result = [super copyWithZone:zone];
  if (result)
    chalkGmpValueSet(&result->value, &self->value, [CHGmpPool peek]);
  return result;
}
//end copyWithZone:

-(void) setValueReference:(chalk_gmp_value_t*)newValue clearPrevious:(BOOL)clearPrevious isValueWapperOnly:(BOOL)aIsValueWapperOnly
{
  if (!newValue)
    chalkGmpValueClear(&self->value, clearPrevious, [CHGmpPool peek]);
  else//if (newValue)
  {
    if (clearPrevious && !self->isValueWapperOnly)
      chalkGmpValueClear(&self->value, YES, [CHGmpPool peek]);
    self->value = *newValue;
  }//end if (newValue)
  self->isValueWapperOnly = aIsValueWapperOnly;
}
//end setValueReference:clearPrevious:

-(BOOL) moveTo:(CHChalkValue*)dst
{
  BOOL result = [super moveTo:dst];
  CHChalkValueNumberGmp* dstGmp = !result ? nil : [dst dynamicCastToClass:[CHChalkValueNumberGmp class]];
  if (dstGmp)
  {
    chalkGmpValueClear(&dstGmp->value, YES, [CHGmpPool peek]);
    dstGmp->value = self->value;
    chalkGmpValueClear(&self->value, NO, [CHGmpPool peek]);
    result = YES;
  }//end if (dstGmp)
  return result;
}
//end moveTo:

-(BOOL) isZero
{
  BOOL result = chalkGmpValueIsZero(&self->value, self->evaluationComputeFlags);
  return result;
}
//end isZero

-(BOOL) isOne:(BOOL*)isOneIgnoringSign;
{
  BOOL result = chalkGmpValueIsOne(&self->value, isOneIgnoringSign, self->evaluationComputeFlags);
  return result;
}
//end isOne:

-(BOOL) negate
{
  BOOL result = chalkGmpValueNeg(&self->value);
  return result;
}
//end negate

-(void) adaptToComputeMode:(chalk_compute_mode_t)computeMode context:(CHChalkContext*)context
{
  if (computeMode == CHALK_COMPUTE_MODE_APPROX_BEST)
  {
    if (self->value.type == CHALK_VALUE_TYPE_FRACTION)
    {
      chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
      mpfr_clear_flags();
      mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
      chalkGmpValueMakeRealApprox(&self->value, prec, context.gmpPool);
      if (!mpfr_inexflag_p())
        chalkGmpValueMakeRealExact(&self->value, prec, context.gmpPool);
      self->evaluationComputeFlags |= chalkGmpFlagsMake();
      chalkGmpFlagsRestore(oldFlags);
    }//end if (self->value.type == CHALK_VALUE_TYPE_FRACTION)
  }//end if (computeMode == CHALK_COMPUTE_MODE_APPROX_BEST)
  else if (computeMode == CHALK_COMPUTE_MODE_APPROX_INTERVALS)
  {
    if (self->value.type == CHALK_VALUE_TYPE_FRACTION)
    {
      chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
      mpfr_clear_flags();
      mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
      chalkGmpValueMakeRealApprox(&self->value, prec, context.gmpPool);
      if (!mpfr_inexflag_p())
        chalkGmpValueMakeRealExact(&self->value, prec, context.gmpPool);
      self->evaluationComputeFlags |= chalkGmpFlagsMake();
      chalkGmpFlagsRestore(oldFlags);
    }//end if (self->value.type == CHALK_VALUE_TYPE_FRACTION)
  }//end if (computeMode == CHALK_COMPUTE_MODE_APPROX_INTERVALS)
}
//end adaptToComputeMode:context:

-(NSInteger) sign
{
  NSInteger result = chalkGmpValueSign(&self->value);
  return result;
}
//end sign

-(chalk_value_gmp_type_t) valueType
{
  chalk_value_gmp_type_t result = self->value.type;
  return result;
}
//end valueType

-(const chalk_gmp_value_t*) valueConstReference
{
  return &self->value;
}
//end valueConstReference

-(chalk_gmp_value_t*) valueReference
{
  return &self->value;
}
//end valueReference

-(void) writeBodyToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  if (self->evaluationErrors.count)
  {
    NSString* errorsString = [[[self->evaluationErrors valueForKey:@"friendlyDescription"] componentsJoinedByString:@","] stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
    if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_HTML)
    {
      NSString* htmlErrorsString = [NSString stringWithFormat:@"<span class=\"errorFlag\">%@</span>", errorsString];
      NSString* htmlElementString = [NSString stringWithFormat:@"<span class=\"hasTooltip\" onmouseover=\"tooltip.show('%@');\" onmouseout=\"tooltip.hide();\">", htmlErrorsString];
      [stream writeString:htmlElementString];
    }//end
    else
      [stream writeString:errorsString];
  }//end if (self->evaluationErrors.count)
  else if (self->value.type == CHALK_VALUE_TYPE_INTEGER)
  {
    if ((context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_BEST) ||
        (context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_INTERVALS))
    {
      chalk_gmp_value_t valueAdapted = {0};
      chalkGmpValueSet(&valueAdapted, &self->value, context.gmpPool);
      chalkGmpValueMakeReal(&valueAdapted, context.computationConfiguration.softFloatSignificandBits, context.gmpPool);
      if (valueAdapted.type == CHALK_VALUE_TYPE_REAL_EXACT)
        [[self class] writeMpfrToStream:stream context:context value:valueAdapted.realExact token:self->token presentationConfiguration:presentationConfiguration];
      else if (valueAdapted.type == CHALK_VALUE_TYPE_REAL_APPROX)
        [[self class] writeMpfirToStream:stream context:context value:valueAdapted.realApprox token:self->token presentationConfiguration:presentationConfiguration];
      chalkGmpValueClear(&valueAdapted, YES, context.gmpPool);
    }//end if CHALK_COMPUTE_MODE_APPROX_BEST,CHALK_COMPUTE_MODE_APPROX_INTERVALS
    else//if (CHALK_COMPUTE_MODE_EXACT)
      [[self class] writeMpzToStream:stream context:context value:self->value.integer token:self->token presentationConfiguration:presentationConfiguration];
  }//end if (self->value.type == CHALK_VALUE_TYPE_INTEGER)
  else if (self->value.type == CHALK_VALUE_TYPE_FRACTION)
  {
    if ((context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_BEST) ||
        (context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_INTERVALS))
    {
      chalk_gmp_value_t valueAdapted = {0};
      chalkGmpValueSet(&valueAdapted, &self->value, context.gmpPool);
      chalkGmpValueMakeReal(&valueAdapted, context.computationConfiguration.softFloatSignificandBits, context.gmpPool);
      if (valueAdapted.type == CHALK_VALUE_TYPE_REAL_EXACT)
        [[self class] writeMpfrToStream:stream context:context value:valueAdapted.realExact token:self->token presentationConfiguration:presentationConfiguration];
      else if (valueAdapted.type == CHALK_VALUE_TYPE_REAL_APPROX)
        [[self class] writeMpfirToStream:stream context:context value:valueAdapted.realApprox token:self->token presentationConfiguration:presentationConfiguration];
      chalkGmpValueClear(&valueAdapted, YES, context.gmpPool);
    }//end if CHALK_COMPUTE_MODE_APPROX_BEST,CHALK_COMPUTE_MODE_APPROX_INTERVALS
    else//if (CHALK_COMPUTE_MODE_EXACT)
    {
      mpq_canonicalize(self->value.fraction);
      [[self class] writeMpqToStream:stream context:context value:self->value.fraction token:self->token presentationConfiguration:presentationConfiguration];
    }
  }//end if (self->value.type == CHALK_VALUE_TYPE_FRACTION)
  else if (self->value.type == CHALK_VALUE_TYPE_REAL_EXACT)
  {
    [[self class] writeMpfrToStream:stream context:context value:self->value.realExact token:self->token presentationConfiguration:presentationConfiguration];
  }
  else if (self->value.type == CHALK_VALUE_TYPE_REAL_APPROX)
  {
    [[self class] writeMpfirToStream:stream context:context value:self->value.realApprox token:self->token presentationConfiguration:presentationConfiguration];
  }//end if (self->value.type == CHALK_VALUE_TYPE_REAL_APPROX)
}
//end writeBodyToStream:description:options:

+(BOOL) checkInteger:(mpz_srcptr)op token:(CHChalkToken*)token setError:(BOOL)setError context:(CHChalkContext*)context
{
  BOOL result = NO;
  int sgn = mpz_sgn(op);
  if (!sgn)
    result = YES;
  else//if (sgn)
    result = [self checkInteger:op maxBitsCount:context.computationConfiguration.softIntegerMaxBits token:token setError:setError context:context];
  return result;
}
//end checkInteger:token:setError:context:

+(BOOL) checkInteger:(mpz_srcptr)op maxBitsCount:(NSUInteger)maxBitsCount token:(CHChalkToken*)token setError:(BOOL)setError context:(CHChalkContext*)context
{
  BOOL result = NO;
  int sgn = mpz_sgn(op);
  if (!sgn)
    result = YES;
  else//if (sgn)
  {
    NSUInteger nbBits = mpz_sizeinbase(op, 2);
    BOOL overflow = (nbBits > maxBitsCount);
    if (overflow)
    {
      if ((context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_EXACT) && setError)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorIntegerOverflow range:token.range]
                               replace:NO];
    }//end if (overflow)
    result = !overflow;
  }//end if (sgn)
  return result;
}
//end checkInteger:maxBitsCount:token:setError:context:

+(BOOL) checkFraction:(mpq_srcptr)op token:(CHChalkToken*)token setError:(BOOL)setError context:(CHChalkContext*)context
{
  BOOL result = NO;
  int sgn = mpq_sgn(op);
  if (!sgn)
    result = YES;
  else if (sgn)
    result = [self checkInteger:mpq_numref(op) maxBitsCount:context.computationConfiguration.softIntegerMaxBits token:token setError:setError context:context] &&
             [self checkInteger:mpq_denref(op) maxBitsCount:context.computationConfiguration.softIntegerDenominatorMaxBits token:token setError:setError context:context];
  return result;
}
//end checkFraction:token:setError:context:

+(void) writeToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context value:(const chalk_gmp_value_t*)value token:(CHChalkToken*)token presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  if (!value){
  }
  else if (value->type == CHALK_VALUE_TYPE_INTEGER)
    [self writeMpzToStream:stream context:context value:value->integer token:token presentationConfiguration:presentationConfiguration];
  else if (value->type == CHALK_VALUE_TYPE_FRACTION)
    [self writeMpqToStream:stream context:context value:value->fraction token:token presentationConfiguration:presentationConfiguration];
  else if (value->type == CHALK_VALUE_TYPE_REAL_EXACT)
    [self writeMpfrToStream:stream context:context value:value->realExact token:token presentationConfiguration:presentationConfiguration];
  else if (value->type == CHALK_VALUE_TYPE_REAL_APPROX)
    [self writeMpfirToStream:stream context:context value:value->realApprox token:token presentationConfiguration:presentationConfiguration];
}
//end writeToStream:context:description:value:tolen:options:

+(void) writeMpzToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context value:(mpz_srcptr)value token:(CHChalkToken*)token presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  if (!value){
  }//end if (!value)
  else//if (value)
  {
    NSString* space =
      (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX) ? @"\\ " :
      (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_MATHML) ? @"&nbsp;" :
      (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_HTML) ? @"&nbsp;" :
      NSSTRING_UNBREAKABLE_SPACE;
    int base = presentationConfiguration.base ? presentationConfiguration.base : context.computationConfiguration.baseDefault;
    NSInteger integerGroupSize = presentationConfiguration.integerGroupSize;
    int sgn = mpz_sgn(value);
    int displayBase = presentationConfiguration.baseUseLowercase ? ABS(base) : -ABS(base);
    BOOL useExternalMemory = NO;
    char* buffer = useExternalMemory ? [context depoolMemoryForMpzGetStr:value base:displayBase] : 0;
    char* bytes  = useExternalMemory && !buffer ? 0 : mpz_get_str(buffer, displayBase, value);
    size_t bytesLength = !bytes ? 0 : strlen(bytes);
    NSString* outputBasePrefix = [context outputPrefixForBase:base];
    NSString* outputBaseSuffix = [context outputSuffixForBase:base];
    NSString* string = !bytes ? nil : [[NSString alloc] initWithBytesNoCopy:bytes length:bytesLength encoding:NSUTF8StringEncoding freeWhenDone:NO];
    @autoreleasepool {
      if (!string)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      else if ((sgn<0) && (presentationConfiguration.printOptions&CHALK_VALUE_PRINT_OPTION_IGNORE_SIGN))
      {
        [stream writeString:outputBasePrefix];
        [stream writeString:[string substringFromIndex:1] groupSize:integerGroupSize groupOffset:0 space:space];
        [stream writeString:outputBaseSuffix];
      }//end if ((sgn<0) && (presentationConfiguration.printOptions&CHALK_VALUE_PRINT_OPTION_IGNORE_SIGN))
      else if (sgn<0)
      {
        [stream writeString:[string substringToIndex:1]];
        [stream writeString:outputBasePrefix];
        [stream writeString:[string substringFromIndex:1] groupSize:integerGroupSize groupOffset:0 space:space];
        [stream writeString:outputBaseSuffix];
      }//end if (sgn<0)
      else//if (sgn>=0)
      {
        [stream writeString:outputBasePrefix];
        [stream writeString:string groupSize:integerGroupSize groupOffset:0 space:space];
        [stream writeString:outputBaseSuffix];
      }//end if (sgn>=0)
    }//end @autoreleasepool
    [string release];
    if (buffer != 0)
      [CHChalkContext repoolMemory:buffer forMpzOutBuffer:bytes context:context];
    else if (bytes && !useExternalMemory)
      mpfr_free_str(bytes);
  }//end if (value)
}
//end writeMpzToStream:context:description:value:token:options:

+(void) writeMpqToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context value:(mpq_srcptr)value token:(CHChalkToken*)token presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  NSUInteger power = 0;
  int base = presentationConfiguration.base ? presentationConfiguration.base : context.computationConfiguration.baseDefault;
  if (!value){
  }//end if (!value)
  else if (chalkGmpIsPowerOfBase(mpq_denref(value), base, &power, context.gmpPool))
  {
    int sgn = mpq_sgn(value);
    int displayBase = presentationConfiguration.baseUseLowercase ? ABS(base) : -ABS(base);
    BOOL useExternalMemory = NO;
    char* buffer = useExternalMemory ? [context depoolMemoryForMpzGetStr:mpq_numref(value) base:displayBase] : 0;
    char* bytes  = useExternalMemory && !buffer ? 0 : mpz_get_str(buffer, displayBase, mpq_numref(value));
    size_t bytesLength = !bytes ? 0 : strlen(bytes);
    NSString* outputBasePrefix = [context outputPrefixForBase:base];
    NSString* outputBaseSuffix = [context outputSuffixForBase:base];
    NSString* string = !bytes ? nil : [[NSString alloc] initWithBytesNoCopy:bytes length:bytesLength encoding:NSUTF8StringEncoding freeWhenDone:NO];
    NSUInteger nbDigits = MIN(mpz_sizeinbase(mpq_numref(value), base), bytesLength);
    NSUInteger headZerosCount = (power>nbDigits) ? (power-nbDigits) : 0;
    if ((sgn<0) && !(presentationConfiguration.printOptions&CHALK_VALUE_PRINT_OPTION_IGNORE_SIGN))
      [stream writeString:@"-"];
    if (power>=nbDigits)
    {
      [stream writeString:outputBasePrefix];
      [stream writeString:@"0."];
      [stream writeCharacter:'0' count:headZerosCount];
      NSUInteger sgnShift = ((sgn<0) ? 1 : 0);
      [stream writeString:[string substringFromIndex:sgnShift]];
      [stream writeString:outputBaseSuffix];
    }//end if (power>=nbDigits)
    else if (power<nbDigits)
    {
      NSUInteger sgnShift = ((sgn<0) ? 1 : 0);
      [stream writeString:outputBasePrefix];
      @autoreleasepool {
        [stream writeString:[string substringWithRange:NSMakeRange(sgnShift, nbDigits-power)]];
      }//end @autoreleasepool
      [stream writeString:@"."];
      @autoreleasepool {
        [stream writeString:[string substringFromIndex:sgnShift+nbDigits-power]];
      }//end @autoreleasepool
      [stream writeString:outputBaseSuffix];
    }//end if (power<nbDigits)
    [string release];
    if (buffer != 0)
      [CHChalkContext repoolMemory:buffer forMpzOutBuffer:bytes context:context];
    else if (bytes && !useExternalMemory)
      mpfr_free_str(bytes);
  }//end if (chalkGmpIsPowerOfBase(mpq_numref(value), base, &power))
  else if (context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_BEST)
  {
    mpfr_t realExact;
    mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
    mpfrDepool(realExact, prec, context.gmpPool);
    mpfr_set_q(realExact, value, MPFR_RNDN);
    [[self class] writeMpfrToStream:stream context:context value:realExact token:token presentationConfiguration:presentationConfiguration];
    mpfrRepool(realExact, context.gmpPool);
  }//end if ((context.computeMode == CHALK_COMPUTE_MODE_APPROX_BEST)
  else if (context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_INTERVALS)
  {
    mpfir_t realApprox;
    mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
    mpfirDepool(realApprox, prec, context.gmpPool);
    mpfir_set_q(realApprox, value);
    [[self class] writeMpfirToStream:stream context:context value:realApprox token:token presentationConfiguration:presentationConfiguration];
    mpfirRepool(realApprox, context.gmpPool);
  }//end if ((context.computeMode == CHALK_COMPUTE_MODE_APPROX_INTERVALS)
  else//if (!context.allowApproximateResult)
  {
    if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
    {
      [stream writeString:@"\\frac{"];
      [self writeMpzToStream:stream context:context value:mpq_numref(value) token:token presentationConfiguration:presentationConfiguration];
      [stream writeString:@"}{"];
      [self writeMpzToStream:stream context:context value:mpq_denref(value) token:token presentationConfiguration:presentationConfiguration];
      [stream writeString:@"}"];
    }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
    else//if (presentationConfiguration.description != CHALK_VALUE_DESCRIPTION_TEX)
    {
      int sgn = mpq_sgn(value);
      BOOL useExternalMemory = NO;
      char* buffer = useExternalMemory ? [context depoolMemoryForMpqGetStr:value base:base] : 0;
      char* bytes  = useExternalMemory && !buffer ? 0 : mpq_get_str(buffer, base, value);
      size_t bytesLength = !bytes ? 0 : strlen(bytes);
      NSString* outputBasePrefix = [context outputPrefixForBase:base];
      NSString* outputBaseSuffix = [context outputSuffixForBase:base];
      NSString* string = !bytes ? nil : [[NSString alloc] initWithBytesNoCopy:bytes length:bytesLength encoding:NSUTF8StringEncoding freeWhenDone:NO];
      if ((sgn<0) && (presentationConfiguration.printOptions&CHALK_VALUE_PRINT_OPTION_IGNORE_SIGN))
      {
        [stream writeString:outputBasePrefix];
        @autoreleasepool {
          [stream writeString:[string substringFromIndex:1]];
        }//end @autoreleasepool
        [stream writeString:outputBaseSuffix];
      }//end if ((sgn<0) && (presentationConfiguration.printOptions&CHALK_VALUE_PRINT_OPTION_IGNORE_SIGN))
      else if (sgn<0)
      {
        [stream writeString:@"-"];
        [stream writeString:outputBasePrefix];
        @autoreleasepool {
          [stream writeString:[string substringFromIndex:1]];
        }//end @autoreleasepool
        [stream writeString:outputBaseSuffix];
      }//end if (sgn<0)
      else//if (sgn>=0)
      {
        [stream writeString:outputBasePrefix];
        [stream writeString:string];
        [stream writeString:outputBaseSuffix];
      }//if (sgn>=0)
      [string release];
      if (buffer != 0)
        [CHChalkContext repoolMemory:buffer forMpqOutBuffer:bytes context:context];
      else if (bytes && !useExternalMemory)
        mpfr_free_str(bytes);
    }//end if (presentationConfiguration.description != CHALK_VALUE_DESCRIPTION_TEX)
  }//end if (!context.allowApproximateResult)
}
//end writeMpqToStream:context:value:token:options:

+(void) writeMpfrToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context value:(mpfr_srcptr)value token:(CHChalkToken*)token presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  [self writeMpfrToStream:stream context:context value:value rounding:MPFR_RNDN nbDigits:0 token:token presentationConfiguration:presentationConfiguration];
}
//end writeMpqToStream:context:value:token:options:

+(void) writeMpfrToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context value:(mpfr_srcptr)value rounding:(mpfr_rnd_t)rounding nbDigits:(NSUInteger)nbDigits token:(CHChalkToken*)token presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  int base = presentationConfiguration.base ? presentationConfiguration.base : context.computationConfiguration.baseDefault;
  BOOL isInexactValue = ((presentationConfiguration.printOptions&CHALK_VALUE_PRINT_OPTION_FORCE_INEXACT) != 0);
  if (!value){
  }//end if (!value)
  else if (mpfr_nan_p(value))
    [stream writeString:@"NaN"];
  else if (mpfr_inf_p(value))
  {
    if ((mpfr_sgn(value)<0) && !(presentationConfiguration.printOptions&CHALK_VALUE_PRINT_OPTION_IGNORE_SIGN))
      [stream writeString:@"-"];
    if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
      [stream writeString:@"\\infty{}"];
    else
      [stream writeString:NSSTRING_INFINITY];
  }//end if (mpfr_inf_p(value))
  else if (mpfr_zero_p(value) && !isInexactValue)
  {
    NSString* outputBasePrefix = [context outputPrefixForBase:base];
    NSString* outputBaseSuffix = [context outputSuffixForBase:base];
    [stream writeString:outputBasePrefix];
    [stream writeString:@"0"];
    [stream writeString:outputBaseSuffix];
  }//end if (mpfr_zero_p(value) && !isInexactValue)
  else//if (mpfr_number_p(value))
  {
    @autoreleasepool {
      NSString* space =
        (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX) ? @"\\ " :
        (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_MATHML) ? @"&nbsp;" :
        (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_HTML) ? @"&nbsp;" :
        NSSTRING_UNBREAKABLE_SPACE;
      NSInteger sgn = mpfr_sgn(value);
      NSUInteger minRoundingDigitsCount = chalkGmpGetMinRoundingDigitsCount();
      NSUInteger numberOfDigits = nbDigits;
      BOOL hasExactDigits = NO;
      if (numberOfDigits<minRoundingDigitsCount)
      {
        NSUInteger numberOfSignificandDigits = chalkGmpGetSignificandDigitsCount(value, base);
        NSUInteger numberOfDisplayDigits = //[context softFloatDisplayDigitsWithBase:base];
          chalkGmpGetMaximumExactDigitsCountFromBitsCount(presentationConfiguration.softFloatDisplayBits, base);
        numberOfDigits = MAX(minRoundingDigitsCount, MIN(numberOfDisplayDigits, numberOfSignificandDigits));
        NSUInteger numberOfSignificandBits = mpfr_get_prec(value);
        NSUInteger numberOfDisplayBits = [context softFloatDisplayDigitsWithBase:2];
        hasExactDigits = (numberOfDisplayBits >= numberOfSignificandBits);
        if (!hasExactDigits && mpfr_regular_p(value) && (mpfr_get_exp(value)<0))
        {
          mpfr_prec_t prec = mpfr_get_prec(value);
          mp_bitcnt_t excessBits = (mp_bits_per_limb-(prec%mp_bits_per_limb))%mp_bits_per_limb;
          mp_bitcnt_t bit = mpn_scan1(value->_mpfr_d, excessBits);
          mp_bitcnt_t leadingZeroBits = (bit-excessBits);
          DebugLog(1, @"prec = %@, bit = %@, excessBits = %@, numberOfSignificandBits=%@, numberOfDisplayBits=%@ (numberOfSignificandBits-numberOfDisplayBits) = %@ numberOfSignificandDigits = %@ numberOfDisplayDigits=%@" , @(prec), @(bit), @(excessBits), @(numberOfSignificandBits), @(numberOfDisplayBits), @(numberOfSignificandBits-numberOfDisplayBits), @(numberOfSignificandDigits), @(numberOfDisplayDigits));
          //mpn_print2(valueToDisplay->_mpfr_d, (prec+mp_bits_per_limb-1)/mp_bits_per_limb);
          mp_bitcnt_t msbBitsCount = numberOfSignificandBits-(bit-excessBits)+mpfr_get_exp(value);
          DebugLog(1, @"numberOfSignificandBits = %@", @(numberOfSignificandBits));
          DebugLog(1, @"mpfr_get_exp(valueToDisplay) = %@", @(mpfr_get_exp(value)));
          if (numberOfSignificandBits > mpfr_get_exp(value))
          {
            mp_bitcnt_t bitsThatCanBeIgnorefIfZero = numberOfSignificandBits-mpfr_get_exp(value);
            DebugLog(1, @"leadingZeroBits = %@", @(leadingZeroBits));
            DebugLog(1, @"msbBitsCount = %@", @(msbBitsCount));
            DebugLog(1, @"bitsThatCanBeIgnorefIfZero = %@", @(bitsThatCanBeIgnorefIfZero));
            NSUInteger numberOfDisplayDigitsAdapted = chalkGmpGetMaximumExactDigitsCountFromBitsCount(msbBitsCount, base);
            DebugLog(1, @"numberOfDisplayDigitsAdapted = %@", @(numberOfDisplayDigitsAdapted));
            if (leadingZeroBits >= bitsThatCanBeIgnorefIfZero)
              hasExactDigits = YES;
          }//end if (numberOfSignificandBits > mpfr_get_exp(valueToDisplay))
        }//end if (!hasExactDigits && mpfr_regular_p(valueToDisplay) && (mpfr_get_exp(valueToDisplay)<0))
      }//end if (numberOfDigits<minRoundingDigitsCount)
      BOOL useExternalMemory = NO;
      char* buffer = useExternalMemory ? [context depoolMemoryForMpfrGetStr:value nbDigits:numberOfDigits] : 0;
      mpfr_exp_t e = 0;
      chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
      int displayMBase = ABS(base);
      int displayNBase = presentationConfiguration.baseUseDecimalExponent ? 10 : displayMBase;
      CHPresentationConfiguration* localPresentationConfiguration = presentationConfiguration ? presentationConfiguration : [[[CHPresentationConfiguration alloc] init] autorelease];
      int oldBase = localPresentationConfiguration.base;
      localPresentationConfiguration.base = displayNBase;
      char* bytes = useExternalMemory && !buffer ? 0 : mpfr_get_str(buffer, &e, displayMBase, numberOfDigits, value, rounding);
      if (!bytes){
      }
      else if (presentationConfiguration.baseUseLowercase)
        strtolower(bytes, strlen(bytes));
      else
        strtoupper(bytes, strlen(bytes));
      size_t bytesLength = !bytes ? 0 : strlen(bytes);
      NSString* outputBasePrefix = [context outputPrefixForBase:base];
      NSString* outputBaseSuffix = [context outputSuffixForBase:base];
      BOOL inexactWarning = isInexactValue ||
        (/*!hasExactDigits &&*/ (!chalkGmpMpfrGetStrRaiseInexFlag() || mpfr_inexflag_p()));
      chalkGmpFlagsRestore(oldFlags);
      NSString* string = !bytes ? nil : [[NSString alloc] initWithBytesNoCopy:bytes length:bytesLength encoding:NSUTF8StringEncoding freeWhenDone:NO];
      NSUInteger stringLength = string.length;
      BOOL removeTrailingZeros = YES;
      if (removeTrailingZeros)
      {
        @autoreleasepool {
          NSArray* matches = [string captureComponentsMatchedByRegex:@"^(-?(0*[^0]+)*)(0*)$"];
          NSRange stringHeadRange = ([matches count]<2) ? NSRangeZero : NSMakeRange(0, [[matches objectAtIndex:1] length]);
          stringHeadRange.length = MIN(MAX(stringHeadRange.length, (e<0) ? 0 : e), string.length-stringHeadRange.location);
          stringLength = (matches.count < 4) ? stringLength : stringHeadRange.length;
        }//end @autoreleasepool
      }//end if (removeTrailingZeros)
      if (!string)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      else if (!string.length)
      {
        [stream writeString:outputBasePrefix];
        [stream writeString:@"0"];
        [stream writeString:outputBaseSuffix];
      }//end if (!string.length)
      else//if (stringLength >= ((sgn ? 1 : 0)+minRoundingDigitsCount))
      {
        NSUInteger firstDigitIndex = ((sgn < 0) ? 1 : 0);
        BOOL prettyPrintReducingExponent =
          ((e<=0) && ((mpfr_uexp_t)(-e) < presentationConfiguration.softMaxPrettyPrintNegativeExponent)) ||
          ((e>0)  && ((mpfr_uexp_t)(e)  < presentationConfiguration.softMaxPrettyPrintPositiveExponent) && (!inexactWarning || (e<=numberOfDigits)));
        if (prettyPrintReducingExponent)
        {
          if (e<=0)
          {
            [stream writeString:(sgn<0) ? @"-" : nil];
            [stream writeString:outputBasePrefix];
            [stream writeString:@"0"];
            if (!mpfr_zero_p(value))
              [stream writeString:@"."];
            [stream writeCharacter:'0' count:((mpfr_uexp_t)-e) groupSize:-presentationConfiguration.integerGroupSize groupOffset:0 space:space];
            NSUInteger groupOffset = !presentationConfiguration.integerGroupSize ? 0 : ((mpfr_uexp_t)-e)%ABS(presentationConfiguration.integerGroupSize);
            if (presentationConfiguration.integerGroupSize && ((mpfr_uexp_t)-e) && !groupOffset && (stringLength-firstDigitIndex))
              [stream writeString:space];
            [stream writeString:[string substringWithRange:NSMakeRange(firstDigitIndex, stringLength-firstDigitIndex)] groupSize:-presentationConfiguration.integerGroupSize groupOffset:groupOffset space:space];
          }//end if (e<=0)
          else//if (e>0)
          {
            NSUInteger remainingCharactersLength = MAX(stringLength, e+firstDigitIndex);
            NSUInteger integerPartLength = firstDigitIndex+MIN(e, stringLength-firstDigitIndex);
            if (sgn<0)
            {
              [stream writeString:[string substringToIndex:1]];
              [stream writeString:outputBasePrefix];
              [stream writeString:[string substringWithRange:NSMakeRange(1, integerPartLength-1)] groupSize:presentationConfiguration.integerGroupSize groupOffset:0 space:space];
            }//end if (sgn<0)
            else//if (sgn>=0)
            {
              [stream writeString:outputBasePrefix];
              [stream writeString:[string substringToIndex:integerPartLength] groupSize:presentationConfiguration.integerGroupSize groupOffset:0 space:space];
            }//end if (sgn>=0)
            remainingCharactersLength -= integerPartLength;
            if (remainingCharactersLength)
            {
              if (e>=stringLength)
              {
                NSUInteger groupOffset = (!presentationConfiguration.integerGroupSize ? 0 : integerPartLength%ABS(presentationConfiguration.integerGroupSize));
                [stream writeCharacter:'0' count:remainingCharactersLength groupSize:presentationConfiguration.integerGroupSize groupOffset:groupOffset space:space];
              }//end if (e>=stringLength)
              else//if (e<stringLength)
              {
                [stream writeString:@"."];
                [stream writeString:[string substringWithRange:NSMakeRange(integerPartLength, stringLength-integerPartLength)] groupSize:-presentationConfiguration.integerGroupSize groupOffset:0 space:space];
              }//end if (e<stringLength)
            }//end if (remainingCharactersLength)
          }//end if (e>0)
          [stream writeString:outputBaseSuffix];
          if (inexactWarning && !(presentationConfiguration.printOptions&CHALK_VALUE_PRINT_OPTION_FORCE_EXACT))
            [stream writeString:NSSTRING_ELLIPSIS];
        }//end if (prettyPrintReducingExponent)
        else//if (!prettyPrintReducingExponent)
        {
          BOOL useExponentSuperScript = NO;
          if (e<=0)
          {
            NSUInteger fractionPointInsertionIndex = firstDigitIndex+1;
            if (sgn<0)
            {
              [stream writeString:[string substringToIndex:1]];
              [stream writeString:outputBasePrefix];
              [stream writeString:[string substringWithRange:NSMakeRange(1, fractionPointInsertionIndex-1)] groupSize:presentationConfiguration.integerGroupSize groupOffset:0 space:space];
            }//end if (sgn<0)
            else//if (sgn>=0)
            {
              [stream writeString:outputBasePrefix];
              [stream writeString:[string substringToIndex:fractionPointInsertionIndex] groupSize:presentationConfiguration.integerGroupSize groupOffset:0 space:space];
            }//end if (sgn>=0)
            if (firstDigitIndex+1 < stringLength)
            {
              [stream writeString:@"."];
              [stream writeString:[string substringWithRange:NSMakeRange(fractionPointInsertionIndex, stringLength-fractionPointInsertionIndex)] groupSize:-presentationConfiguration.integerGroupSize groupOffset:0 space:space];
            }//end if (firstDigitIndex+1 < stringLength)
            [stream writeString:outputBaseSuffix];
            if (inexactWarning && !(presentationConfiguration.printOptions&CHALK_VALUE_PRINT_OPTION_FORCE_EXACT))
              [stream writeString:NSSTRING_ELLIPSIS];
            NSUInteger absExponent = ((mpfr_uexp_t)(-e))+1;
            if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
              [stream writeString:useExponentSuperScript ? @"e^{-" : @"e{-"];
            else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_HTML)
              [stream writeString:useExponentSuperScript ? @"e<sup>-" : @"e-"];
            else
              [stream writeString:@"e-"];
            mpz_t e_mpz;
            mpzDepool(e_mpz, context.gmpPool);
            mpz_set_nsui(e_mpz, absExponent);
            [self writeMpzToStream:stream context:context value:e_mpz token:token presentationConfiguration:presentationConfiguration];
            if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
              [stream writeString:@"}"];
            else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_HTML)
              [stream writeString:useExponentSuperScript ? @"</sup>" : @""];
            mpzRepool(e_mpz, context.gmpPool);
          }//end if (e<=0)
          else//if (e > 0)
          {
            NSUInteger fractionPointInsertionIndex = firstDigitIndex+1;
            if (sgn<0)
            {
              [stream writeString:[string substringToIndex:1]];
              [stream writeString:outputBasePrefix];
              [stream writeString:[string substringWithRange:NSMakeRange(1, fractionPointInsertionIndex-1)] groupSize:presentationConfiguration.integerGroupSize groupOffset:0 space:space];
            }//end if (sgn<0)
            else//if (sgn>=0)
            {
              [stream writeString:outputBasePrefix];
              [stream writeString:[string substringToIndex:fractionPointInsertionIndex] groupSize:presentationConfiguration.integerGroupSize groupOffset:0 space:space];
            }//end if (sgn>=0)
            if (fractionPointInsertionIndex < stringLength)
            {
              [stream writeString:@"."];
              [stream writeString:[string substringWithRange:NSMakeRange(fractionPointInsertionIndex, stringLength-fractionPointInsertionIndex)] groupSize:-presentationConfiguration.integerGroupSize groupOffset:0 space:space];
            }//end if (firstDigitIndex+1 < stringLength)
            [stream writeString:outputBaseSuffix];
            if (inexactWarning && !(presentationConfiguration.printOptions&CHALK_VALUE_PRINT_OPTION_FORCE_EXACT))
              [stream writeString:NSSTRING_ELLIPSIS];
            NSUInteger absExponent = ((mpfr_uexp_t)(e))-1;
            if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
              [stream writeString:useExponentSuperScript ? @"e^{" : @"e{"];
            else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_HTML)
              [stream writeString:useExponentSuperScript ? @"e<sup>" : @"e"];
            else
              [stream writeString:@"e"];
            NSFont* currentFont = [stream.attributedStringStream attribute:NSFontAttributeName atIndex:0 effectiveRange:0];
            if (!currentFont)
              currentFont = [NSFont systemFontOfSize:[NSFont systemFontSize]];
            NSFont* exponentFont = [NSFont fontWithDescriptor:currentFont.fontDescriptor size:[NSFont systemFontSize]/2.];
            NSUInteger index = stream.attributedStringStream.length;
            mpz_t e_mpz;
            mpzDepool(e_mpz, context.gmpPool);
            mpz_set_nsui(e_mpz, absExponent);
            [self writeMpzToStream:stream context:context value:e_mpz token:token presentationConfiguration:presentationConfiguration];
            NSUInteger index2 = stream.attributedStringStream.length;
            if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
              [stream writeString:@"}"];
            else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_HTML)
              [stream writeString:useExponentSuperScript ? @"</sup>" : @""];
            else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_ATTRIBUTEDSTRING)
            {
              if (exponentFont)
                [stream.attributedStringStream addAttributes:@{/*NSFontAttributeName:exponentFont, NSBaselineOffsetAttributeName:@(10*[NSFont systemFontSize]),*/NSSuperscriptAttributeName:@1} range:NSMakeRange(index, index2-index)];
            }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_ATTRIBUTEDSTRING)
            mpzRepool(e_mpz, context.gmpPool);
          }//end if (e > 0)
        }//end if (!prettyPrintReducingExponent)
      }//end if (string)
      [string release];
      localPresentationConfiguration.base = oldBase;
      if (buffer != 0)
        [CHChalkContext repoolMemory:buffer forMpfrOutBuffer:bytes context:context];
      else if (bytes && !useExternalMemory)
        mpfr_free_str(bytes);
    }//end @autoreleasepool
  }//end if (mpfr_number_p(value))
}
//end writeMpfrToStream:context:value:rounding:nbDigits:token:presentationConfiguration:

+(void) writeMpfiToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context value:(mpfi_srcptr)value token:(CHChalkToken*)token presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  if (value)
    DebugLog(1, @"write [%f;%f]", mpfr_get_d(&value->left, MPFR_RNDN), mpfr_get_d(&value->right, MPFR_RNDN));
  int base = presentationConfiguration.base ? presentationConfiguration.base : context.computationConfiguration.baseDefault;
  if (!value){
  }//end if (!value)
  else if (mpfi_nan_p(value))
    [stream writeString:@"NaN"];
  else if (!mpfr_cmp(&value->left, &value->right))
  {
    if (mpfr_zero_p(&value->left))
      [stream writeString:@"0"];
    else
      [self writeMpfrToStream:stream context:context value:&value->left token:token presentationConfiguration:presentationConfiguration];
  }//end if (!mpfr_cmp(&value->left, &value->right))
  else if (mpfi_inf_p(value))
  {
    [stream writeString:mpfr_inf_p(&value->left) ? @"(" : @"["];
    [self writeMpfrToStream:stream context:context value:&value->left token:token presentationConfiguration:presentationConfiguration];
    [stream writeString:@";"];
    [self writeMpfrToStream:stream context:context value:&value->right token:token presentationConfiguration:presentationConfiguration];
    [stream writeString:mpfr_inf_p(&value->right) ? @")" : @"]"];
  }//end if (mpfi_inf_p(value))
  else//if (mpfi_number_p(value))
  {
    @autoreleasepool
    {
      NSUInteger softFloatDisplayBits = presentationConfiguration.softFloatDisplayBits;
      
      int displayMBase = ABS(base);
      int displayNBase = presentationConfiguration.baseUseDecimalExponent ? 10 : displayMBase;
      CHPresentationConfiguration* localPresentationConfiguration = presentationConfiguration ? presentationConfiguration : [[[CHPresentationConfiguration alloc] init] autorelease];
      int oldBase = localPresentationConfiguration.base;
      localPresentationConfiguration.base = displayNBase;
      mpfr_t radius;
      mpfrDepool(radius, mpfi_get_prec(value), context.gmpPool);
      BOOL writePlusMinus = YES;
      BOOL isExactDiameter = !mpfi_diam_abs(radius, value);
      DebugLog(1, @"value->left %.14f", mpfr_get_d(&value->left, MPFR_RNDN));
      DebugLog(1, @"value->right %.14f", mpfr_get_d(&value->right, MPFR_RNDN));
      DebugLog(1, @"diam %f is exact? %d", mpfr_get_d(radius, MPFR_RNDN), isExactDiameter);
      if (isExactDiameter && mpfr_zero_p(radius))//left is equal to right, should already be handled above with !cmp of left and right
      {
        [self writeMpfrToStream:stream context:context value:&value->left token:token presentationConfiguration:localPresentationConfiguration];
      }//end if (isExactDiameter && mpfr_zero_p(diameter))
      else//if (!isExactDiameter || !mpfr_zero_p(diameter))
      {
        BOOL specificWriteDone = NO;
        //find the base power of the diameter, so that we can compute how much digits should be written for the mid value
        mpfr_div_2exp(radius, radius, 1, MPFR_RNDU);//make radius=diameter/2
        DebugLog(1, @"radius %.14f", mpfr_get_d(radius, MPFR_RNDN));
        if (mpfr_zero_p(radius))//the diameter is zero because of an underflow
        {
          mpfr_set_zero(radius, 0);
          mpfr_nextabove(radius);
        }//end if (mpfr_zero_p(diameter))
        mpfr_t mid;
        mpfrDepool(mid, mpfi_get_prec(value), context.gmpPool);
        mpfi_mid(mid, value);
        DebugLog(1, @"mid %.14f", mpfr_get_d(mid, MPFR_RNDN));
        mpfr_exp_t eRadius = 0;
        mpfr_exp_t eMid = 0;
        char buffer[4] = {0};
        mpfr_get_str(buffer, &eRadius, base, 2, radius, MPFR_RNDU);
        DebugLog(1, @"<%s> eRadius %ld", buffer, eRadius);
        mpfr_get_str(buffer, &eMid, base, 2, mid, MPFR_RNDN);
        DebugLog(1, @"<%s> eMid %ld", buffer, eMid);
        mpz_t eRadiusz;
        mpz_t eMidz;
        mpz_t diffz;
        mpzDepool(eRadiusz, context.gmpPool);
        mpz_set_nssi(eRadiusz, eRadius);
        mpzDepool(eMidz, context.gmpPool);
        mpz_set_nssi(eMidz, eMid);
        mpzDepool(diffz, context.gmpPool);
        mpz_sub(diffz, eMidz, eRadiusz);
        DebugLog(1, @"eMid-eRadius = %ld", mpz_get_si(diffz));
        NSUInteger nbDigitsToDisplay = chalkGmpGetMinRoundingDigitsCount();
        NSUInteger maxNbDigitsToDisplay = chalkGmpGetMaximumExactDigitsCountFromBitsCount(softFloatDisplayBits, base);
        if (mpz_sgn(diffz)>0)
        {
          mpz_add_ui(diffz, diffz, 1);
          if (mpz_cmp_ui(diffz, maxNbDigitsToDisplay)>0)
            nbDigitsToDisplay = maxNbDigitsToDisplay;
          else if (mpz_fits_nsui_p(diffz))
            nbDigitsToDisplay = MIN(maxNbDigitsToDisplay, mpz_get_nsui(diffz));
          mpz_t diffz2;
          mpzDepool(diffz2, context.gmpPool);
          mpz_set_nsui(diffz2, nbDigitsToDisplay);
          mpz_sub(diffz2, eMidz, diffz2);
          DebugLog(1, @"diffz2=eMid-nbDigitsToDisplay = %ld", mpz_get_si(diffz2));
          if (mpz_fits_sint_p(diffz2))
          {
            long diffz2l = mpz_get_si(diffz2);
            mpfr_t radius2;
            mpfrDepool(radius2, mpfi_get_prec(value), context.gmpPool);
            mpfr_set_nsui(radius2, base, MPFR_RNDU);
            mpfr_pow_si(radius2, radius2, diffz2l, MPFR_RNDU);
            mpfr_max(radius, radius, radius2, MPFR_RNDU);
            mpfrRepool(radius2, context.gmpPool);
          }//end if (mpz_fits_sint_p(diffz2))
          mpzRepool(diffz2, context.gmpPool);
          
          if (!writePlusMinus)
          {
            DebugLog(1, @"!writePlusMinus : %.14f with %ld digits", mpfr_get_d(mid, MPFR_RNDN), nbDigitsToDisplay);
            [self writeMpfrToStream:stream context:context value:mid rounding:MPFR_RNDN nbDigits:nbDigitsToDisplay token:token presentationConfiguration:presentationConfiguration];
            specificWriteDone = YES;
          }//end if (!writePlusMinus)
        }//end if (mpz_sgn(diffz)>0)
        if (!specificWriteDone && ((mpz_sgn(diffz)<0) || writePlusMinus))
        {
          BOOL useExponentSuperScript = NO;
          DebugLog(1, @"!specificWriteDone : %.14f with %ld digits", mpfr_get_d(mid, MPFR_RNDN), nbDigitsToDisplay);
          [self writeMpfrToStream:stream context:context value:mid rounding:MPFR_RNDN nbDigits:nbDigitsToDisplay token:token presentationConfiguration:presentationConfiguration];
          if (writePlusMinus)
          {
            if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
              [stream writeString:@"\\pm{}"];
            else
              [stream writeString:NSSTRING_PLUSMINUS];
            char outChar = 0;
            NSInteger outExp = 0;
            chalkGmpValueGetOneDigitUpRounding(radius, base, &outChar, &outExp);
            if (!outExp)
              [stream writeString:[NSString stringWithFormat:@"%c", outChar]];
            else//if (outExp)
            {
              [stream writeString:[NSString stringWithFormat:@"%ce", outChar]];
              if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
                [stream writeString:useExponentSuperScript ? @"^{" : @"{"];
              else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_HTML)
                [stream writeString:useExponentSuperScript ? @"<sup>" : @""];
              mpz_t e_mpz;
              mpzDepool(e_mpz, context.gmpPool);
              mpz_set_nssi(e_mpz, outExp);
              [self writeMpzToStream:stream context:context value:e_mpz token:token presentationConfiguration:presentationConfiguration];
              mpzRepool(e_mpz, context.gmpPool);
              if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
                [stream writeString:@"}"];
              else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_HTML)
                [stream writeString:useExponentSuperScript ? @"</sup>" : @""];
            }//end if (outExp)
          }//end if (writePlusMinus)
          specificWriteDone = YES;
        }//end if (!specificWriteDone && ((mpz_sgn(diffz)<0) || writePlusMinus))
        mpfrRepool(mid, context.gmpPool);
        mpzRepool(eRadiusz, context.gmpPool);
        mpzRepool(eMidz, context.gmpPool);
        mpzRepool(diffz, context.gmpPool);
        if (!specificWriteDone)
        {
          [stream writeString:@"["];
          [self writeMpfrToStream:stream context:context value:&value->left rounding:MPFR_RNDD nbDigits:0 token:token presentationConfiguration:presentationConfiguration];
          [stream writeString:@","];
          [self writeMpfrToStream:stream context:context value:&value->right rounding:MPFR_RNDU nbDigits:0 token:token presentationConfiguration:presentationConfiguration];
          [stream writeString:@"]"];
        }//end if (!specificWriteDone)
      }//end if (!isExactDiameter || !mpfr_zero_p(diameter))
      mpfrRepool(radius, context.gmpPool);
      localPresentationConfiguration.base = oldBase;
    }//end @autoreleasepool
  }//end if (mpfi_number_p(value))
}
//end writeMpfiToStream:context:value:token:options:

+(void) writeMpfirToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context value:(mpfir_srcptr)value token:(CHChalkToken*)token presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  if (!value){
  }//end if(!value)
  else if (context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_BEST)
  {
    chalk_value_print_options_t oldPrintOptions = presentationConfiguration.printOptions;
    if (!mpfr_equal_p(&value->interval.left, &value->estimation) ||
        !mpfr_equal_p(&value->interval.right, &value->estimation))
      presentationConfiguration.printOptions = oldPrintOptions | CHALK_VALUE_PRINT_OPTION_FORCE_INEXACT;
    [self writeMpfrToStream:stream context:context value:&value->estimation token:token presentationConfiguration:presentationConfiguration];
    presentationConfiguration.printOptions = oldPrintOptions;
  }//end if (context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_BEST)
  else
    [self writeMpfiToStream:stream context:context value:&value->interval token:token presentationConfiguration:presentationConfiguration];
}
//end writeMpfirToStream:context:value:token:options:

@end
