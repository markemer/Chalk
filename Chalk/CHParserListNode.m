//
//  CHParserListNode.m
//  Chalk
//
//  Created by Pierre Chatelier on 13/02/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHParserListNode.h"

#import "CHChalkContext.h"
#import "CHChalkError.h"
#import "CHChalkErrorContext.h"
#import "CHChalkToken.h"
#import "CHChalkUtils.h"
#import "CHChalkValueList.h"
#import "CHParserEnumerationNode.h"
#import "CHPresentationConfiguration.h"
#import "CHStreamWrapper.h"
#import "NSObjectExtended.h"

@implementation CHParserListNode

-(void) performEvaluationWithContext:(CHChalkContext*)context lazy:(BOOL)lazy
{
  [super performEvaluationWithContext:context lazy:lazy];
  if (!lazy || !self.evaluatedValue)
  {
    CHParserEnumerationNode* enumeration = [[self->children lastObject] dynamicCastToClass:[CHParserEnumerationNode class]];
    NSArray* enumerationChildren = enumeration.children;
    __block NSMutableArray* childrenValues = [[NSMutableArray alloc] initWithCapacity:enumerationChildren.count];
    [enumerationChildren enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      CHChalkValue* childValue = ((CHParserNode*)[obj dynamicCastToClass:[CHParserNode class]]).evaluatedValue;
      if (childValue)
      {
        [childrenValues addObject:childValue];
        self->evaluationComputeFlags |= childValue.evaluationComputeFlags;
      }//end if (childValue)
      else//if (!childValue)
      {
        [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:self->token.range] context:context];
        [childrenValues release];
        childrenValues = nil;
        *stop = YES;
      }
    }];
    CHChalkValueList* value = !childrenValues ? nil :
      [[CHChalkValueList alloc] initWithToken:self->token values:childrenValues context:context];
    if (!value)
      [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:self->token.range] context:context];
    value.evaluationComputeFlags = self->evaluationComputeFlags;
    self.evaluatedValue = value;
    [value release];
    [childrenValues release];
    [context.errorContext.error setContextGenerator:self replace:NO];
  }//end if (!lazy || !self.evaluatedValue)
}
//end performEvaluationWithContext:

-(void) writeHeaderToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_MATHML)
    [stream writeString:@"<mfenced open=\"{\" close=\"}\" separators=\",\">"];
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
    [stream writeString:@"\\{"];
  else
    [stream writeString:@"{"];
}
//end writeHeaderToStream:context:options:

-(void) writeFooterToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_MATHML)
    [stream writeString:@"</mfenced>"];
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
    [stream writeString:@"\\}"];
  else
    [stream writeString:@"}"];
}
//end writeFooterToStream:context:options:

-(void) writeBodyToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_DOT)
  {
    NSString* selfNodeIdentifier = [NSString stringWithFormat:@"_%p", self];
    [stream writeString:[NSString stringWithFormat:@"%@ [label=\"%@\"];n", selfNodeIdentifier, @"list"]];
  }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_DOT)
  else//if (presentationConfiguration.description != CHALK_VALUE_DESCRIPTION_DOT)
  {
    [self->children enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      CHParserNode* parserNode = [obj dynamicCastToClass:[CHParserNode class]];
      if (idx && (presentationConfiguration.description != CHALK_VALUE_DESCRIPTION_MATHML))
        [stream writeString:@","];
      [parserNode writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
    }];
  }//end if (presentationConfiguration.description != CHALK_VALUE_DESCRIPTION_DOT)
}
//end writeBodyToStream:context:options:

@end
