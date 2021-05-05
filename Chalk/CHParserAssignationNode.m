//
//  CHParserAssignationNode.m
//  Chalk
//
//  Created by Pierre Chatelier on 13/02/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHParserAssignationNode.h"

#import "CHChalkContext.h"
#import "CHChalkError.h"
#import "CHChalkErrorContext.h"
#import "CHChalkIdentifier.h"
#import "CHChalkIdentifierFunction.h"
#import "CHChalkIdentifierManager.h"
#import "CHChalkIdentifierVariable.h"
#import "CHChalkToken.h"
#import "CHChalkValue.h"
#import "CHChalkValueSubscript.h"
#import "CHChalkValueSubscriptable.h"
#import "CHChalkValueURLOutput.h"
#import "CHParserEnumerationNode.h"
#import "CHParserFunctionNode.h"
#import "CHParserOperatorNode.h"
#import "CHParserSubscriptNode.h"
#import "CHParserValueNode.h"
#import "CHParserIdentifierNode.h"
#import "CHPresentationConfiguration.h"
#import "CHStreamWrapper.h"
#import "NSObjectExtended.h"
#import "NSStringExtended.h"

@implementation CHParserAssignationNode

-(void) performEvaluationWithContext:(CHChalkContext*)context lazy:(BOOL)lazy
{
  if (!lazy || !self.evaluatedValue)
  {
    NSUInteger childCount = self->children.count;
    CHParserNode* child1 = [((childCount<1) ? nil : [self->children objectAtIndex:0]) dynamicCastToClass:[CHParserNode class]];
    CHParserNode* child2 = [((childCount<2) ? nil : [self->children objectAtIndex:1]) dynamicCastToClass:[CHParserNode class]];
    CHParserFunctionNode* dstFunction = [child1 dynamicCastToClass:[CHParserFunctionNode class]];
    CHParserIdentifierNode* dstIdentifier = [child1 dynamicCastToClass:[CHParserIdentifierNode class]];
    CHParserOperatorNode* dstOperator = [child1 dynamicCastToClass:[CHParserOperatorNode class]];
    CHParserOperatorNode* dstOperatorSubscript = ([dstOperator op] != CHALK_OPERATOR_SUBSCRIPT) ? nil : dstOperator;
    if (dstFunction)
    {
      CHChalkIdentifierManager* identifierManager = context.identifierManager;
      NSString* identifierToken = dstFunction.token.value;
      BOOL isReservedIdentifier = [identifierManager isDefaultIdentifierToken:identifierToken];
      if (isReservedIdentifier)
        [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorIdentifierReserved range:child1.token.range] context:context];
      else//if (!isReservedIdentifier)
      {
        CHChalkIdentifierFunction* chalkIdentifierFunction = [[identifierManager identifierForToken:identifierToken createClass:[CHChalkIdentifierFunction class]] dynamicCastToClass:[CHChalkIdentifierFunction class]];
        if (chalkIdentifierFunction)
        {
          CHParserNode* uniqueLeftFunctionChild = (dstFunction.children.count == 1) ?
            [[dstFunction.children objectAtIndex:0] dynamicCastToClass:[CHParserNode class]] :
            nil;
          CHParserEnumerationNode* functionArgumentsEnumeration = [uniqueLeftFunctionChild dynamicCastToClass:[CHParserEnumerationNode class]];
          NSMutableArray* argumentNames = [NSMutableArray arrayWithCapacity:functionArgumentsEnumeration.children.count];
          BOOL isValidFunctionDeclaration = YES;
          for(CHParserNode* argNode in functionArgumentsEnumeration.children)
          {
            CHParserIdentifierNode* argAsIdentifierNode = [argNode dynamicCastToClass:[CHParserIdentifierNode class]];
            NSString* argName = argAsIdentifierNode.token.value;
            BOOL isValidIdentifier = ![NSString isNilOrEmpty:argName];
            if (!isValidIdentifier)
              [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorParseError range:argNode.token.range] context:context];
            isValidFunctionDeclaration &= isValidIdentifier;
            if (isValidIdentifier)
              [argumentNames addObject:argName];
          }//end for each argNode
          NSMutableString* string = [NSMutableString string];
          CHStreamWrapper* streamWrapper = [[CHStreamWrapper alloc] init];
          streamWrapper.stringStream = string;
          BOOL oldOutputRawToken = context.outputRawToken;
          context.outputRawToken = YES;
          [child2 writeBodyToStream:streamWrapper context:context presentationConfiguration:context.presentationConfiguration];
          context.outputRawToken = oldOutputRawToken;
          [streamWrapper release];
          chalkIdentifierFunction.argsPossibleCount = NSMakeRange(argumentNames.count, 1);
          chalkIdentifierFunction.argumentNames = argumentNames;
          chalkIdentifierFunction.definition = string;
        }//end if (chalkIdentifierFunction)
      }//end if (!isReservedIdentifier)
    }//end if (dstFunction)
    else if (dstIdentifier)
    {
      CHChalkIdentifierManager* identifierManager = context.identifierManager;
      NSString* identifierToken = dstIdentifier.token.value;
      BOOL isReservedIdentifier = [identifierManager isDefaultIdentifierToken:identifierToken];
      if (isReservedIdentifier)
        [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorIdentifierReserved range:child1.token.range] context:context];
      else//if (!isReservedIdentifier)
      {
        CHChalkIdentifier* chalkIdentifier = [identifierManager identifierForToken:identifierToken createClass:[CHChalkIdentifierVariable class]];
        if (chalkIdentifier)
        {
          [child2 performEvaluationWithContext:context lazy:lazy];
          CHChalkValue* value = [[child2.evaluatedValue copy] autorelease];
          [identifierManager setValue:value forIdentifier:chalkIdentifier];
          self.evaluatedValue = [[value copy] autorelease];
          self.evaluationComputeFlags = child2.evaluationComputeFlags;
        }//end if (chalkIdentifier)
      }//end if (!isReservedIdentifier)
    }//end if (dstIdentifier)
    else if (dstOperatorSubscript)
    {
      NSArray* dstOperatorSubscriptChildren = dstOperatorSubscript.children;
      NSUInteger subscriptOperatorChildCount = self->children.count;
      CHParserNode* subscriptOperatorChild1 =
        [((subscriptOperatorChildCount<1) ? nil : [dstOperatorSubscriptChildren objectAtIndex:0])  dynamicCastToClass:[CHParserNode class]];
      CHParserNode* subscriptOperatorChild2 =
        [((subscriptOperatorChildCount<2) ? nil : [dstOperatorSubscriptChildren objectAtIndex:1])  dynamicCastToClass:[CHParserNode class]];
      CHParserNode<CHParserNodeSubscriptable>* subscriptableNode =
        [subscriptOperatorChild1 dynamicCastToProtocol:@protocol(CHParserNodeSubscriptable)];
      CHParserIdentifierNode* identifierNode =
        [subscriptOperatorChild1 dynamicCastToClass:[CHParserIdentifierNode class]];
      CHParserSubscriptNode* subscriptNode =
        [subscriptOperatorChild2 dynamicCastToClass:[CHParserSubscriptNode class]];
      [subscriptNode performEvaluationWithContext:context lazy:lazy];
      CHChalkValueSubscript* subscript = [subscriptNode.evaluatedValue dynamicCastToClass:[CHChalkValueSubscript class]];
      if ((!subscriptableNode && !identifierNode) || !subscript)
        [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:self->token.range]
               context:context];
      else//if ((subscriptableNode || identifierNode) && subscript)
      {
        CHChalkValue<CHChalkValueSubscriptable>* subscriptableValue = nil;
        if (subscriptableNode)
        {
          [subscriptableNode performEvaluationWithContext:context lazy:lazy];
          CHChalkValue* nodeValue = subscriptableNode.evaluatedValue;
          if (![nodeValue conformsToProtocol:@protocol(CHChalkValueSubscriptable)])
            [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:self->token.range]
                   context:context];
          else//if ([nodeValue conformsToProtocol:@protocol(CHChalkValueSubscriptable)])
            subscriptableValue = (CHChalkValue<CHChalkValueSubscriptable>*)nodeValue;
        }//end if (subscriptableNode)
        else if (identifierNode)
        {
          CHChalkIdentifierManager* identifierManager = context.identifierManager;
          CHChalkIdentifier* chalkIdentifier = [identifierManager identifierForToken:identifierNode.token.value createClass:Nil];
          if (!chalkIdentifier)
            [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorIdentifierUndefined range:self->token.range]
                   context:context];
          else//if (chalkIdentifier)
          {
            CHChalkValue* identifierValue = [identifierManager valueForIdentifier:chalkIdentifier];
            if (![identifierValue conformsToProtocol:@protocol(CHChalkValueSubscriptable)])
              [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:self->token.range]
                     context:context];
            else//if ([identifierValue conformsToProtocol:@protocol(CHChalkValueSubscriptable)])
              subscriptableValue = (CHChalkValue<CHChalkValueSubscriptable>*)identifierValue;
          }//end if (chalkIdentifier)
        }//end if (identifierNode)
        if (subscriptableValue)
        {
          [child2 performEvaluationWithContext:context lazy:lazy];
          CHChalkValue* value = child2.evaluatedValue;
          if (!context.errorContext.hasError)
          {
            [subscriptableValue setValue:value atSubscript:subscript context:context];
            self.evaluatedValue = subscriptableValue;
            self->evaluationComputeFlags = value.evaluationComputeFlags;
          }//end if (!context.errorContext.hasError)
        }//end if (subscriptableValue)
      }//end if (identifierNode && subscript)
    }//end if (dstOperatorSubscript)
    else if (dstFunction)
    {
      CHChalkIdentifier* identifier = [dstFunction identifierWithContext:context];
      if (identifier == [context.identifierManager identifierForName:@"outfile" createClass:Nil])
      {
        [dstFunction performEvaluationWithContext:context lazy:lazy];
        CHChalkValueURLOutput* chalkValueURLOutput =
          [dstFunction.evaluatedValue dynamicCastToClass:[CHChalkValueURLOutput class]];
        if (chalkValueURLOutput)
        {
          [child2 performEvaluationWithContext:context lazy:lazy];
          if (!context.errorContext.hasError)
          {
            CHStreamWrapper* stream = [[CHStreamWrapper alloc] init];
            NSMutableString* string = [[NSMutableString alloc] init];
            stream.stringStream = string;
            [child2.evaluatedValue writeBodyToStream:stream context:context presentationConfiguration:nil];
            NSData* data = [string dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
            [chalkValueURLOutput write:data append:NO context:context];
            [string release];
            [stream release];
            self.evaluatedValue = child1.evaluatedValue;
            self->evaluationComputeFlags = self.evaluatedValue.evaluationComputeFlags;
          }//end if (!context.errorContext.hasError)
        }//end if (chalkValueURLOutput)
      }//end if (identifier == [context.identifierManager identifierForName:@"outfile" createClass:Nil])
    }//end if (dstFunction)
    [context.errorContext.error setContextGenerator:self replace:NO];
  }//end if (!lazy || !self.evaluatedValue)
}
//end performEvaluationWithContext:lazy:

-(void) writeBodyToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_MATHML)
  {
    NSUInteger childCount = self->children.count;
    CHParserNode* child1 = (childCount<1) ? nil : [self->children objectAtIndex:0];
    CHParserNode* child2 = (childCount<2) ? nil : [self->children objectAtIndex:1];
    [stream writeString:@"<mi>"];
    [child1 writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
    [stream writeString:@"</mi>"];
    [stream writeString:@"<mo>:=</mo>"];
    [stream writeString:@"<mi>"];
    [child2 writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
    [stream writeString:@"</mi>"];
  }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_MATHML)
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
  {
    NSUInteger childCount = self->children.count;
    CHParserNode* child1 = (childCount<1) ? nil : [self->children objectAtIndex:0];
    CHParserNode* child2 = (childCount<2) ? nil : [self->children objectAtIndex:1];
    [child1 writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
    [stream writeString:@"\\leftarrow{}"];
    [child2 writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
  }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_DOT)
  {
    NSString* selfNodeIdentifier = [NSString stringWithFormat:@"_%p", self];
    [stream writeString:[NSString stringWithFormat:@"%@ [label=\"%@\"];n", selfNodeIdentifier, @":="]];
  }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_DOT)
  else//if (presentationConfiguration.description != CHALK_VALUE_DESCRIPTION_DOT)
  {
    NSUInteger childCount = self->children.count;
    CHParserNode* child1 = (childCount<1) ? nil : [self->children objectAtIndex:0];
    CHParserNode* child2 = (childCount<2) ? nil : [self->children objectAtIndex:1];
    [child1 writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
    [stream writeString:@":="];
    [child2 writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
  }//end if (presentationConfiguration.description != CHALK_VALUE_DESCRIPTION_DOT)
}
//end writeBodyToStream:context:options:

@end
