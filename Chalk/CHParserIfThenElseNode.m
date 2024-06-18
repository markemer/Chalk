//
//  CHParserIfThenElseNode.m
//  Chalk
//
//  Created by Pierre Chatelier on 18/12/2017.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHParserIfThenElseNode.h"

#import "CHChalkContext.h"
#import "CHChalkToken.h"
#import "CHChalkValue.h"
#import "CHChalkValueBoolean.h"
#import "CHChalkError.h"
#import "CHChalkErrorContext.h"
#import "CHChalkValueNumberRaw.h"
#import "CHPresentationConfiguration.h"
#import "CHStreamWrapper.h"
#import "NSObjectExtended.h"

@implementation CHParserIfThenElseNode

+(CHParserIfThenElseNode*) parserNodeWithIf:(CHParserNode*)ifNode Then:(CHParserNode*)thenNode Else:(CHParserNode*)elseNode
{
  return [[[[self class] alloc] initWithIf:ifNode Then:thenNode Else:elseNode] autorelease];
}
//end parserNodeWithIf:Then:Else:

-(instancetype) initWithIf:(CHParserNode*)aIfNode Then:(CHParserNode*)aThenNode Else:(CHParserNode*)aElseNode
{
  if (!((self = [super initWithToken:[CHChalkToken chalkTokenEmpty]])))
    return nil;
  self->ifNode = [aIfNode retain];
  self->thenNode = [aThenNode retain];
  self->elseNode = [aElseNode retain];
  [self addChild:self->ifNode];
  [self addChild:self->thenNode];
  [self addChild:self->elseNode];
  return self;
}
//end initWithIfThen:Else:

-(void) dealloc
{
  [self->ifNode release];
  [self->thenNode release];
  [self->elseNode release];
  [super dealloc];
}
//end dealloc

-(void) performEvaluationWithContext:(CHChalkContext*)context lazy:(BOOL)lazy
{
  [self->ifNode performEvaluationWithContext:context lazy:lazy];
  CHChalkValue* predicateValue = self->ifNode.evaluatedValue;
  CHChalkValueBoolean* predicateValueBoolean = [predicateValue dynamicCastToClass:[CHChalkValueBoolean class]];
  self->evaluationComputeFlags |= self->ifNode.evaluationComputeFlags;
  if (!predicateValueBoolean)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError] replace:NO];
  else//if (predicateValueBoolean)
  {
    BOOL isTrue = (predicateValueBoolean.chalkBoolValue == CHALK_BOOL_YES);
    if (isTrue)
    {
      [self->thenNode performEvaluationWithContext:context lazy:lazy];
      self.evaluatedValue = self->thenNode.evaluatedValue;
      self->evaluationComputeFlags |= self->thenNode.evaluationComputeFlags;
    }//end if (isTrue)
    else//if (!isTrue)
    {
      [self->elseNode performEvaluationWithContext:context lazy:lazy];
      self.evaluatedValue = self->elseNode.evaluatedValue;
      self->evaluationComputeFlags |= self->elseNode.evaluationComputeFlags;
    }//end if (!isTrue)
  }//end if (!isSum && !isProduct)
}
//end performEvaluationWithContext:

-(void) writeBodyToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  if (!presentationConfiguration || (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_STRING))
  {
    [stream writeString:@"("];
    [stream writeString:@"IF"];
    [stream writeString:@"("];
    [self->ifNode writeBodyToStream:stream context:context presentationConfiguration:presentationConfiguration];
    [stream writeString:@")"];
    [stream writeString:@" "];
    [stream writeString:@"THEN"];
    [stream writeString:@"("];
    [self->thenNode writeBodyToStream:stream context:context presentationConfiguration:presentationConfiguration];
    [stream writeString:@")"];
    [stream writeString:@" "];
    [stream writeString:@"ELSE"];
    [stream writeString:@"("];
    [self->elseNode writeBodyToStream:stream context:context presentationConfiguration:presentationConfiguration];
    [stream writeString:@")"];
    [stream writeString:@")"];
  }//end if (!presentationConfiguration || (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_STRING))
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_ATTRIBUTEDSTRING)
  {
    [stream writeString:@"("];
    [stream writeString:@"IF"];
    [stream writeString:@"("];
    [self->ifNode writeBodyToStream:stream context:context presentationConfiguration:presentationConfiguration];
    [stream writeString:@")"];
    [stream writeString:@" "];
    [stream writeString:@"THEN"];
    [stream writeString:@"("];
    [self->thenNode writeBodyToStream:stream context:context presentationConfiguration:presentationConfiguration];
    [stream writeString:@")"];
    [stream writeString:@" "];
    [stream writeString:@"ELSE"];
    [stream writeString:@"("];
    [self->elseNode writeBodyToStream:stream context:context presentationConfiguration:presentationConfiguration];
    [stream writeString:@")"];
    [stream writeString:@")"];
  }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_ATTRIBUTEDSTRING)
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_DOT)
  {
    NSString* selfNodeIdentifier = [NSString stringWithFormat:@"_%p IF THEN ELSE", self];
    [stream writeString:[NSString stringWithFormat:@"%@;n", selfNodeIdentifier]];
  }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_DOT)
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_MATHML)
  {
    [stream writeString:@"("];
    [stream writeString:@"IF"];
    [stream writeString:@"("];
    [self->ifNode writeBodyToStream:stream context:context presentationConfiguration:presentationConfiguration];
    [stream writeString:@")"];
    [stream writeString:@" "];
    [stream writeString:@"THEN"];
    [stream writeString:@"("];
    [self->thenNode writeBodyToStream:stream context:context presentationConfiguration:presentationConfiguration];
    [stream writeString:@")"];
    [stream writeString:@" "];
    [stream writeString:@"ELSE"];
    [stream writeString:@"("];
    [self->elseNode writeBodyToStream:stream context:context presentationConfiguration:presentationConfiguration];
    [stream writeString:@")"];
    [stream writeString:@")"];
  }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_MATHML)
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
  {
    [stream writeString:@"\\left("];
    [stream writeString:@"IF"];
    [stream writeString:@"\\left("];
    [self->ifNode writeBodyToStream:stream context:context presentationConfiguration:presentationConfiguration];
    [stream writeString:@"\\right)"];
    [stream writeString:@" "];
    [stream writeString:@"THEN"];
    [stream writeString:@"\\left("];
    [self->thenNode writeBodyToStream:stream context:context presentationConfiguration:presentationConfiguration];
    [stream writeString:@"\\right)"];
    [stream writeString:@" "];
    [stream writeString:@"ELSE"];
    [stream writeString:@"\\left("];
    [self->elseNode writeBodyToStream:stream context:context presentationConfiguration:presentationConfiguration];
    [stream writeString:@"\\right)"];
    [stream writeString:@"\\right)"];
  }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_HTML)
  {
    NSMutableString* s = [[NSMutableString alloc] init];
    CHStreamWrapper* stream2 = [[CHStreamWrapper alloc] init];
    stream2.stringStream = s;
    [stream2 writeString:@"("];
    [stream2 writeString:@"IF"];
    [stream2 writeString:@"("];
    [self->ifNode writeBodyToStream:stream2 context:context presentationConfiguration:presentationConfiguration];
    [stream2 writeString:@")"];
    [stream2 writeString:@" "];
    [stream2 writeString:@"THEN"];
    [stream2 writeString:@"("];
    [self->thenNode writeBodyToStream:stream2 context:context presentationConfiguration:presentationConfiguration];
    [stream2 writeString:@")"];
    [stream2 writeString:@" "];
    [stream2 writeString:@"ELSE"];
    [stream2 writeString:@"("];
    [self->elseNode writeBodyToStream:stream2 context:context presentationConfiguration:presentationConfiguration];
    [stream2 writeString:@")"];
    [stream2 writeString:@")"];
    [stream2 release];
    NSString* symbol = [[s copy] autorelease];
    [s release];
    if (self->evaluationErrors.count)
    {
      NSString* errorsString = [[[self->evaluationErrors valueForKey:@"friendlyDescription"] componentsJoinedByString:@","] stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
      NSString* string =
        [NSString stringWithFormat:@"<span class=\"errorFlag\" onmouseover=\"tooltip.show('%@');\" onmouseout=\"tooltip.hide();\">%@</span>",
          errorsString, symbol];
      [stream writeString:string];
    }//end if (self->evaluationErrors.count)
    else if (self->evaluationComputeFlags)
    {
      CHChalkValueNumberRaw* evaluatedValueRaw = [self->evaluatedValue dynamicCastToClass:[CHChalkValueNumberRaw class]];
      const chalk_raw_value_t* rawValue = evaluatedValueRaw.valueConstReference;
      const chalk_bit_interpretation_t* bitInterpretation = !rawValue ? 0 : &rawValue->bitInterpretation;
      NSString* flagsImageString = [chalkGmpComputeFlagsGetHTML(self->evaluationComputeFlags, bitInterpretation, NO) stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
      NSString* string =
        [NSString stringWithFormat:@"<span class=\"hasTooltip\" onmouseover=\"tooltip.show('%@');\" onmouseout=\"tooltip.hide();\">%@</span>", flagsImageString, symbol];
      [stream writeString:string];
    }
    else
      [stream writeString:symbol];
  }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_HTML)
}
//end writeBodyToStream:context:options:

@end
