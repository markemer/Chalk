//
//  CHParserMatrixNode.m
//  Chalk
//
//  Created by Pierre Chatelier on 13/11/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHParserMatrixNode.h"

#import "CHChalkContext.h"
#import "CHChalkError.h"
#import "CHChalkErrorContext.h"
#import "CHChalkToken.h"
#import "CHChalkValueMatrix.h"
#import "CHParserMatrixRowNode.h"
#import "CHPresentationConfiguration.h"
#import "CHStreamWrapper.h"
#import "NSObjectExtended.h"

@implementation CHParserMatrixNode

-(BOOL) isTerminal
{
  BOOL result = YES;//the matrix has inner parenthesis
  return result;
}
//end isTerminal

-(void) performEvaluationWithContext:(CHChalkContext*)context lazy:(BOOL)lazy
{
  if (!lazy || !self.evaluatedValue)
  {
    id lastRow = [self->children lastObject];
    NSUInteger rowsCount = [self->children count];
    NSUInteger colsCount = [[lastRow children] count];
    [self->children enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
       CHParserMatrixRowNode* row = [obj dynamicCastToClass:[CHParserMatrixRowNode class]];
       NSUInteger elementsCount = [row children].count;
       if (elementsCount != colsCount)
       {
         [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorMatrixMalformed range:row.token.range]
                                context:context];
         *stop = YES;
       }//end if (elementsCount != colsCount)
    }];
    if (!context.errorContext.hasError)
      [super performEvaluationWithContext:context lazy:lazy];
    if (!context.errorContext.hasError)
    {
      
    }//end if (!context.errorContext.hasError)
    NSMutableArray* elements = [NSMutableArray array];
    [self->children enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      CHParserMatrixRowNode* row = [obj dynamicCastToClass:[CHParserMatrixRowNode class]];
      [row.children enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CHChalkValue* value = ((CHParserNode*)[obj dynamicCastToClass:[CHParserNode class]]).evaluatedValue;
        if (value)
          [elements addObject:value];
      }];
    }];
    CHChalkValueMatrix* value =
      [[[CHChalkValueMatrix alloc]
        initWithToken:self->token rowsCount:rowsCount colsCount:colsCount values:elements context:context]
          autorelease];
    self.evaluatedValue = value;
    self->evaluationComputeFlags |= value.evaluationComputeFlags;
    [context.errorContext.error setContextGenerator:self replace:NO];
  }//end if (!lazy || !self.evaluatedValue)
}
//end performEvaluationWithContext:

-(void) writeToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
  {
    [stream writeString:@"\\begin{pmatrix}"];
    [self->children enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      CHParserMatrixRowNode* row = [obj dynamicCastToClass:[CHParserMatrixRowNode class]];
      [row writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
    }];
    [stream writeString:@"\\end{pmatrix}"];
  }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_MATHML)
  {
    [stream writeString:@"<mrow><mo>(</mo><mtable>"];
    [self->children enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      CHParserMatrixRowNode* row = [obj dynamicCastToClass:[CHParserMatrixRowNode class]];
      [row writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
    }];
    [stream writeString:@"</mtable><mo>]</mo></mrow>"];
  }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_MATHML)
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_HTML)
  {
    [stream writeString:@"<table>"];
    [self->children enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      CHParserMatrixRowNode* row = [obj dynamicCastToClass:[CHParserMatrixRowNode class]];
      [row writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
    }];
    [stream writeString:@"</table>"];
  }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_HTML)
  else
  {
    [stream writeString:@"("];
    [self->children enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      CHParserMatrixRowNode* row = [obj dynamicCastToClass:[CHParserMatrixRowNode class]];
      [row writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
    }];
    [stream writeString:@")"];
  }//end if (...)
}
//end writeToStream:context:options:

@end
