//
//  CHParserValueIndexRangeNode.m
//  Chalk
//
//  Created by Pierre Chatelier on 16/04/2016.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHParserValueIndexRangeNode.h"

#import "CHChalkContext.h"
#import "CHChalkError.h"
#import "CHChalkErrorContext.h"
#import "CHChalkToken.h"
#import "CHChalkValueNumberGmp.h"
#import "CHChalkValueIndexRange.h"
#import "CHParserValueNumberNode.h"
#import "CHPresentationConfiguration.h"
#import "CHStreamWrapper.h"
#import "CHUtils.h"
#import "NSObjectExtended.h"

@implementation CHParserValueIndexRangeNode

@synthesize joker;
@synthesize exclusive;

+(instancetype) parserNodeWithToken:(CHChalkToken*)token joker:(BOOL)joker
{
  return [[[[self class] alloc] initWithToken:token joker:joker] autorelease];
}
//end parserNodeWithToken:joker:

-(instancetype) initWithToken:(CHChalkToken*)aToken joker:(BOOL)aJoker
{
  if(!((self = [super initWithToken:aToken])))
    return nil;
  self->joker = aJoker;
  self->exclusive = ([aToken.value rangeOfString:@"..<"].location != NSNotFound);
  return self;
}
//end initWithToken:joker:

-(instancetype) initWithToken:(CHChalkToken*)aToken
{
  return [self initWithToken:aToken joker:NO];
}
//end initWithToken:

-(void) performEvaluationWithContext:(CHChalkContext*)context lazy:(BOOL)lazy
{
  [super performEvaluationWithContext:context lazy:lazy];
  if (!lazy || !self.evaluatedValue)
  {
    if (self->joker)
    {
      CHChalkValue* value =
        [[CHChalkValueIndexRange alloc] initWithToken:self->token range:NSRangeZero joker:YES exclusive:NO context:context];
      if (!value && !context.errorContext.hasError)
        [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:self->token.range]
               context:context];
      self.evaluatedValue = value;
      [value release];
      self->evaluationComputeFlags |= value.evaluationComputeFlags;
    }//end if (self->joker)
    else//if (!self->joker)
    {
      CHParserValueNumberNode* left = (self->children.count <= 0) ? nil :
        [[self->children objectAtIndex:0] dynamicCastToClass:[CHParserValueNumberNode class]];
      CHParserValueNumberNode* right = (self->children.count <= 1) ? nil :
        [[self->children objectAtIndex:1] dynamicCastToClass:[CHParserValueNumberNode class]];
      CHChalkValueNumberGmp* leftValue = [left.evaluatedValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueNumberGmp* rightValue = [right.evaluatedValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
      const chalk_gmp_value_t* leftValueGmp = leftValue.valueConstReference;
      const chalk_gmp_value_t* rightValueGmp = rightValue.valueConstReference;
      mpz_srcptr leftMpz = !leftValueGmp || (leftValueGmp->type != CHALK_VALUE_TYPE_INTEGER) ? 0 :
        leftValueGmp->integer;
      mpz_srcptr rightMpz = !rightValueGmp || (rightValueGmp->type != CHALK_VALUE_TYPE_INTEGER) ? 0 :
        rightValueGmp->integer;
      BOOL leftIsPositiveInteger = leftMpz && mpz_fits_nsui_p(leftMpz);
      BOOL rightIsPositiveInteger = rightMpz && mpz_fits_nsui_p(rightMpz);
      BOOL leftIsLessThanRight = leftIsPositiveInteger && rightIsPositiveInteger &&
        (mpz_cmp(leftMpz, rightMpz)<=0);
      if (!leftIsLessThanRight)
      {
        [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnimplemented range:self->token.range]
               context:context];
      }//end if (!leftIsLessThanRight)
      else//if (leftIsLessThanRight)
      {
        NSRange range = NSMakeRange(
          mpz_get_nsui(leftMpz),
          mpz_get_nsui(rightMpz)-mpz_get_nsui(leftMpz)+(self->exclusive ? 0U : 1U));
        CHChalkValue* value =
          [[CHChalkValueIndexRange alloc] initWithToken:self->token range:range joker:NO exclusive:exclusive context:context];
        if (!value && !context.errorContext.hasError)
          [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:self->token.range]
                 context:context];
        self.evaluatedValue = value;
        [value release];
        self->evaluationComputeFlags |= value.evaluationComputeFlags;
      }//end if (leftIsLessThanRight)
    }//end if (!self->joker)
    [context.errorContext.error setContextGenerator:self replace:NO];
  }//end if (!lazy || !self.evaluatedValue)
}
//end performEvaluationWithContext:

-(void) writeBodyToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_DOT)
  {
    NSString* selfNodeIdentifier = [NSString stringWithFormat:@"_%p", self];
    [stream writeString:[NSString stringWithFormat:@"%@ [label=\"%@\"];n", selfNodeIdentifier,
      self->joker ? @"*" : self->exclusive ? @"..<" : @"..."]];
    for(CHParserNode* child in children)
      [child writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
  }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_DOT)
  else//if (presentationConfiguration.description != CHALK_VALUE_DESCRIPTION_DOT)
  {
    if (!context.outputRawToken)
      [self->evaluatedValue writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
    else//if (context.outputRawToken)
    {
      NSUInteger childCount = self->children.count;
      CHParserNode* child1 = (childCount<1) ? nil : [[self->children objectAtIndex:0] dynamicCastToClass:[CHParserNode class]];
      CHParserNode* child2 = (childCount<2) ? nil : [[self->children objectAtIndex:1] dynamicCastToClass:[CHParserNode class]];
      if ((childCount != 2) || !child1 || !child2)
        [super writeBodyToStream:stream context:context presentationConfiguration:presentationConfiguration];
      else//if ((childCount == 2) && child1 && child2)
      {
        [child1 writeBodyToStream:stream context:context presentationConfiguration:presentationConfiguration];
        if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_STRING)
          [stream writeString:(self->joker ? @"*" : self->exclusive ? @" ..< " : @" ... ")];
        else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_ATTRIBUTEDSTRING)
          [stream writeString:(self->joker ? @"*" : self->exclusive ? @" .. <" : @" ... ")];
        else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_HTML)
          [stream writeString:(self->joker ? @"*" : self->exclusive ? @"&nbsp;..&lt;&nbsp;" : @"&nbsp;...&nbsp;")];
        else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_MATHML)
          [stream writeString:(self->joker ? @"*" : self->exclusive ? @"&nbsp;..&lt;&nbsp;" : @"&nbsp;...&nbsp;")];
        else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
          [stream writeString:(self->joker ? @"*" : self->exclusive ? @"\\textrm{~..<~}" : @"\\textrm{~...~}")];
        [child2 writeBodyToStream:stream context:context presentationConfiguration:presentationConfiguration];
      }//end if ((childCount == 2) && child1 && child2)
    }//end if (context.outputRawToken)
  }//end if (presentationConfiguration.description != CHALK_VALUE_DESCRIPTION_DOT)
}
//end writeBodyToStream:context:description:

@end
