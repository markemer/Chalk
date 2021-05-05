//
//  CHParserValueNumberIntervalNode.m
//  Chalk
//
//  Created by Pierre Chatelier on 13/11/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHParserValueNumberIntervalNode.h"

#import "CHChalkContext.h"
#import "CHChalkError.h"
#import "CHChalkErrorContext.h"
#import "CHChalkToken.h"
#import "CHChalkValueParser.h"
#import "CHChalkValueNumberGmp.h"
#import "CHComputationConfiguration.h"
#import "CHStreamWrapper.h"
#import "CHUtils.h"
#import "NSObjectExtended.h"

@implementation CHParserValueNumberIntervalNode

-(BOOL) isTerminal
{
  BOOL result = YES;//the interval has inner brackets
  return result;
}
//end isTerminal

-(void) writeBodyToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  [stream writeString:@"["];
  for(NSUInteger i = 0, count = self->children.count ; i<count ; ++i)
  {
    [[self->children objectAtIndex:i] writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
    if (i+1<count)
      [stream writeString:@";"];
  }//end for each child
  [stream writeString:@"]"];
}
//end writeBodyToStream:context:options:

-(void) performEvaluationWithContext:(CHChalkContext*)context lazy:(BOOL)lazy
{
  [super performEvaluationWithContext:context lazy:lazy];
  if (!lazy || !self.evaluatedValue)
  {
    NSUInteger childCount = self->children.count;
    CHParserNode* valueNode1 = (childCount != 2) ? nil : [self->children objectAtIndex:0];
    CHParserNode* valueNode2 = (childCount != 2) ? nil : [self->children objectAtIndex:1];
    CHChalkValueNumberGmp* valueGmp1 = [valueNode1.evaluatedValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
    CHChalkValueNumberGmp* valueGmp2 = [valueNode2.evaluatedValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
    if (valueNode1 && !valueGmp1)
      [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnimplemented range:valueNode1.token.range]
                             context:context];
    if (valueNode2 && !valueGmp2)
      [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnimplemented range:valueNode2.token.range]
                             context:context];
    const chalk_gmp_value_t* valueGmp1Value = valueGmp1.valueConstReference;
    const chalk_gmp_value_t* valueGmp2Value = valueGmp2.valueConstReference;
    CHChalkValue* value = nil;
    if (valueGmp1Value && valueGmp2Value)
    {
      chalk_gmp_value_t interval = {0};
      mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
      chalkGmpValueMakeRealApprox(&interval, prec, context.gmpPool);
      if (valueGmp1Value->type == CHALK_VALUE_TYPE_INTEGER)
        mpfr_set_z(&interval.realApprox->interval.left, valueGmp1Value->integer, MPFR_RNDD);
      else if (valueGmp1Value->type == CHALK_VALUE_TYPE_FRACTION)
        mpfr_set_q(&interval.realApprox->interval.left, valueGmp1Value->fraction, MPFR_RNDD);
      else if (valueGmp1Value->type == CHALK_VALUE_TYPE_REAL_EXACT)
        mpfr_set(&interval.realApprox->interval.left, valueGmp1Value->realExact, MPFR_RNDD);
      else if (valueGmp1Value->type == CHALK_VALUE_TYPE_REAL_APPROX)
        mpfr_set(&interval.realApprox->interval.left, &valueGmp1Value->realApprox->interval.left, MPFR_RNDD);
      
      if (valueGmp2Value->type == CHALK_VALUE_TYPE_INTEGER)
        mpfr_set_z(&interval.realApprox->interval.right, valueGmp2Value->integer, MPFR_RNDU);
      else if (valueGmp2Value->type == CHALK_VALUE_TYPE_FRACTION)
        mpfr_set_q(&interval.realApprox->interval.right, valueGmp2Value->fraction, MPFR_RNDU);
      else if (valueGmp2Value->type == CHALK_VALUE_TYPE_REAL_EXACT)
        mpfr_set(&interval.realApprox->interval.right, valueGmp2Value->realExact, MPFR_RNDU);
      else if (valueGmp2Value->type == CHALK_VALUE_TYPE_REAL_APPROX)
        mpfr_set(&interval.realApprox->interval.right, &valueGmp2Value->realApprox->interval.right, MPFR_RNDU);
      
      mpfir_estimation_update(interval.realApprox);
      
      chalkGmpValueSimplify(&interval, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
      value = [[[CHChalkValueNumberGmp alloc] initWithToken:self->token value:&interval naturalBase:valueGmp1.naturalBase context:context] autorelease];
      value.evaluationComputeFlags |= chalkGmpFlagsMake();
      chalkGmpValueClear(&interval, YES, context.gmpPool);
    }//end if (valueGmp1Value && valueGmp2Value)
    if (!value)
      [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:self->token.range]
                             context:context];
    self.evaluatedValue = value;
    self->evaluationComputeFlags |= value.evaluationComputeFlags;
    [context.errorContext.error setContextGenerator:self replace:NO];
  }//end if (!lazy || !self.evaluatedValue)
}
//end performEvaluationWithContext:

@end
