//
//  CHParserValueNumberIntegerNode.m
//  Chalk
//
//  Created by Pierre Chatelier on 13/02/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHParserValueNumberIntegerNode.h"

#import "CHChalkContext.h"
#import "CHChalkError.h"
#import "CHChalkErrorContext.h"
#import "CHChalkValueParser.h"
#import "CHChalkToken.h"
#import "CHChalkUtils.h"
#import "CHChalkValue.h"
#import "CHUtils.h"
#import "NSStringExtended.h"

@implementation CHParserValueNumberIntegerNode

-(void) performEvaluationWithContext:(CHChalkContext*)context lazy:(BOOL)lazy
{
  [super performEvaluationWithContext:context lazy:lazy];
  if (!lazy || !self.evaluatedValue)
  {
    CHChalkValueParser* chalkValueParser = [[CHChalkValueParser alloc] initWithToken:self->token context:context];
    CHChalkValue* value = [chalkValueParser chalkValueWithContext:context];
    [chalkValueParser release];
    if (!value && !context.errorContext.hasError)
      [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:self->token.range]
                             context:context];
    self.evaluatedValue = value;
    self->evaluationComputeFlags |= value.evaluationComputeFlags;
    [context.errorContext.error setContextGenerator:self replace:NO];
  }//end if (!lazy || !self.evaluatedValue)
}
//end performEvaluationWithContext:

@end
