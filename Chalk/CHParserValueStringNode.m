//
//  CHParserValueStringNode.m
//  Chalk
//
//  Created by Pierre Chatelier on 13/02/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHParserValueStringNode.h"

#import "CHChalkContext.h"
#import "CHChalkError.h"
#import "CHChalkErrorContext.h"
#import "CHChalkToken.h"
#import "CHChalkValueString.h"
#import "CHPresentationConfiguration.h"
#import "CHStreamWrapper.h"
#import "NSObjectExtended.h"
#import "NSStringExtended.h"
#import "NSString+HTML.h"

@implementation CHParserValueStringNode

@dynamic innerString;

-(NSString*) innerString
{
  NSString* result =
    [self->token.value isMatchedByRegex:@"^\".*\"$"] ?
      [self->token.value stringByReplacingOccurrencesOfRegex:@"^\"(.*)\"$" withString:@"$1"] :
    [self->token.value isMatchedByRegex:@"^'.*'$"] ?
      [self->token.value stringByReplacingOccurrencesOfRegex:@"^'(.*)'$" withString:@"$1"] :
    self->token.value;
  return result;
}
//end innerString:

-(void) performEvaluationWithContext:(CHChalkContext*)context lazy:(BOOL)lazy
{
  [super performEvaluationWithContext:context lazy:lazy];
  if (!lazy || !self.evaluatedValue)
  {
    NSString* unescapedString = self.innerString;
    CHChalkValue* value = !unescapedString ? nil :
      [[CHChalkValueString alloc] initWithToken:self->token string:unescapedString context:context];
    if (!value && !context.errorContext.hasError)
      [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:self->token.range]
             context:context];
    self.evaluatedValue = value;
    [value release];
    self->evaluationComputeFlags |= value.evaluationComputeFlags;
    [context.errorContext.error setContextGenerator:self replace:NO];
  }//end if (!lazy || !self.evaluatedValue)
}
//end performEvaluationWithContext:

-(void) writeBodyToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_DOT)
  {
    NSString* selfNodeIdentifier = [NSString stringWithFormat:@"_%p", self];
    [stream writeString:[NSString stringWithFormat:@"%@ [label=\"%@\"];n", selfNodeIdentifier, self->token.value]];
  }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_DOT)
  else//if (presentationConfiguration.description != CHALK_VALUE_DESCRIPTION_DOT)
  {
    if (!context.outputRawToken)
      [self->evaluatedValue writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
    else//if (context.outputRawToken)
    {
      NSString* string = self.innerString;
      if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
      {
        string = [NSString stringWithFormat:@"\\textrm{%@}",
          [string stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"]];
      }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
      else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_MATHML)
        string = [string encodeHTMLCharacterEntities];
      else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_HTML)
        string = [string encodeHTMLCharacterEntities];
      [stream writeString:string];
    }//end if (context.outputRawToken)
  }//end if (presentationConfiguration.description != CHALK_VALUE_DESCRIPTION_DOT)
}
//end writeBodyToStream:context:description:

@end
