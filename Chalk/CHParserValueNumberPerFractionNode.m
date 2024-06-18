//
//  CHParserValueNumberPerFractionNode.m
//  Chalk
//
//  Created by Pierre Chatelier on 13/02/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHParserValueNumberPerFractionNode.h"

#import "CHChalkContext.h"
#import "CHChalkError.h"
#import "CHChalkErrorContext.h"
#import "CHChalkToken.h"
#import "CHChalkValue.h"
#import "CHChalkValueNumberFraction.h"
#import "CHChalkValueNumberGmp.h"
#import "CHChalkValueParser.h"
#import "CHUtils.h"

#import "NSObjectExtended.h"

@implementation CHParserValueNumberPerFractionNode

-(void) performEvaluationWithContext:(CHChalkContext*)context lazy:(BOOL)lazy
{
  [super performEvaluationWithContext:context lazy:lazy];
  if (!lazy || !self.evaluatedValue)
  {
    NSString* tokenString = self.token.value;
    NSString* perCentString = @"%";
    NSString* perThousandString = @"\u2030";
    NSString* perTenThousandString = @"\u2031";
    NSString* perMillionString = @"ppm";
    NSRange perCentRange = [tokenString rangeOfString:perCentString options:NSAnchoredSearch|NSBackwardsSearch|NSCaseInsensitiveSearch];
    NSRange perThousandRange = [tokenString rangeOfString:perThousandString options:NSAnchoredSearch|NSBackwardsSearch|NSCaseInsensitiveSearch];
    NSRange perTenThousandRange = [tokenString rangeOfString:perTenThousandString options:NSAnchoredSearch|NSBackwardsSearch|NSCaseInsensitiveSearch];
    NSRange perMillionRange = [tokenString rangeOfString:perMillionString options:NSAnchoredSearch|NSBackwardsSearch|NSCaseInsensitiveSearch];
    NSRange suffixRange =
      (perCentRange.location != NSNotFound) ? perCentRange :
      (perThousandRange.location != NSNotFound) ? perThousandRange :
      (perTenThousandRange.location != NSNotFound) ? perTenThousandRange :
      (perMillionRange.location != NSNotFound) ? perMillionRange :
      NSRangeNotFound;
    NSString* numberString = [tokenString substringToIndex:(tokenString.length-suffixRange.length)];
    CHChalkToken* numberToken = [CHChalkToken chalkTokenWithValue:numberString range:NSMakeRange(self.token.range.location, numberString.length)];
    NSUInteger fraction =
      (perCentRange.location != NSNotFound) ? 100U :
      (perThousandRange.location != NSNotFound) ? 1000U :
      (perTenThousandRange.location != NSNotFound) ? 10000U :
      (perMillionRange.location != NSNotFound) ? 1000000U :
      0U;
    CHChalkValueParser* chalkValueParser = [[CHChalkValueParser alloc] initWithToken:numberToken context:context];
    CHChalkValueNumberGmp* valueNumberGmp = [[chalkValueParser chalkValueWithContext:context] dynamicCastToClass:[CHChalkValueNumberGmp class]];
    [chalkValueParser release];
    if (!fraction)
      [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:self.token.range] context:context];
    CHChalkValueNumberFraction* valueNumberFraction = !fraction ? nil :
      [[CHChalkValueNumberFraction alloc] initWithToken:self.token numberValue:valueNumberGmp fraction:fraction context:context];
    if (!valueNumberFraction)
      [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:self.token.range] context:context];
    self.evaluatedValue = valueNumberFraction;
    self->evaluationComputeFlags |= valueNumberFraction.evaluationComputeFlags;
    [valueNumberFraction release];
    [context.errorContext.error setContextGenerator:self replace:NO];
  }//end if (!lazy || !self.evaluatedValue)
}
//end performEvaluationWithContext:

@end
