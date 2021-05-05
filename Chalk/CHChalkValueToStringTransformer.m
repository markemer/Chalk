//
//  CHChalkValueToStringTransformer.m
//  Chalk
//
//  Created by Pierre Chatelier on 19/12/2015.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHChalkValueToStringTransformer.h"

#import "CHChalkContext.h"
#import "CHChalkErrorContext.h"
#import "CHChalkToken.h"
#import "CHChalkValueNumberGmp.h"
#import "CHChalkValueParser.h"
#import "CHComputationConfiguration.h"
#import "CHPresentationConfiguration.h"
#import "CHStreamWrapper.h"
#import "NSObjectExtended.h"

@implementation CHChalkValueToStringTransformer

+(void) initialize
{
}
//end initialize

+(NSString*) name
{
  NSString* result = [self className];
  return result;
}
//end name

+(Class) transformedValueClass
{
  return [NSString class];
}
//end transformedValueClass

+(BOOL) allowsReverseTransformation
{
  return YES;
}
//end allowsReverseTransformation

+(id) transformerWithContext:(CHChalkContext*)context
{
  id result = [[[[self class] alloc] initWithContext:context] autorelease];
  return result;
}
//end transformerWithContext:

-(id) initWithContext:(CHChalkContext*)aContext
{
  if ((!(self = [super init])))
    return nil;
  self->chalkContext = [aContext copy];
  self->chalkContext.computationConfiguration.computeMode = CHALK_COMPUTE_MODE_APPROX_INTERVALS;
  self->valueParser = [[CHChalkValueParser alloc] initWithToken:nil context:self->chalkContext];
  [self->chalkContext.errorContext reset:nil];
  return self;
}
//end initWithFalseValue:trueValue:

-(void) dealloc
{
  [self->chalkContext release];
  [super dealloc];
}
//end dealloc

-(id) transformedValue:(id)value
{
  id result = nil;
  CHChalkValueNumberGmp* number = [value dynamicCastToClass:[CHChalkValueNumberGmp class]];
  const chalk_gmp_value_t* gmpValue = number.valueConstReference;
  if (gmpValue)
  {
    chalk_gmp_value_t gmpValueMpfr = {0};
    chalkGmpValueSet(&gmpValueMpfr, gmpValue, self->chalkContext.gmpPool);
    mpfr_prec_t prec = self->chalkContext.computationConfiguration.softFloatSignificandBits;
    chalkGmpValueMakeRealExact(&gmpValueMpfr, prec, self->chalkContext.gmpPool);
    CHStreamWrapper* stream = [[CHStreamWrapper alloc] init];
    stream.stringStream = [NSMutableString string];
    CHPresentationConfiguration* presentationConfiguration = [[CHPresentationConfiguration alloc] init];
    presentationConfiguration.description = CHALK_VALUE_DESCRIPTION_STRING;
    presentationConfiguration.printOptions = CHALK_VALUE_PRINT_OPTION_FORCE_EXACT;
    [CHChalkValueNumberGmp writeMpfrToStream:stream context:self->chalkContext value:gmpValueMpfr.realExact token:[CHChalkToken chalkTokenEmpty] presentationConfiguration:presentationConfiguration];
    [presentationConfiguration release];
    result = [[stream.stringStream copy] autorelease];
    [stream release];
    chalkGmpValueClear(&gmpValueMpfr, YES, self->chalkContext.gmpPool);
  }//end if (gmpValue)
  return result;
}
//end transformedValue:

-(id) reverseTransformedValue:(id)value
{
  id result = nil;
  NSString* string = [value dynamicCastToClass:[NSString class]];
  CHChalkToken* token = !string ? nil :
    [CHChalkToken chalkTokenWithValue:string range:NSMakeRange(0, string.length)];
  self->valueParser.token = token;
  [self->chalkContext.errorContext reset:nil];
  [self->valueParser analyzeWithContext:self->chalkContext];
  CHChalkValue* chalkValue = [self->valueParser chalkValueWithContext:self->chalkContext];
  CHChalkValueNumberGmp* chalkValueNumberGmp = [chalkValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
  result = chalkValueNumberGmp;
  return result;
}
//end reverseTransformedValue:

@end
