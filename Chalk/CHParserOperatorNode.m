//
//  CHParserOperatorNode.m
//  Chalk
//
//  Created by Pierre Chatelier on 13/02/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHParserOperatorNode.h"

#import "CHChalkContext.h"
#import "CHChalkError.h"
#import "CHChalkErrorContext.h"
#import "CHChalkOperator.h"
#import "CHChalkOperatorManager.h"
#import "CHChalkToken.h"
#import "CHChalkValueBoolean.h"
#import "CHChalkValueFormalSimple.h"
#import "CHChalkValueQuaternion.h"
#import "CHChalkValueList.h"
#import "CHChalkValueMatrix.h"
#import "CHChalkValueNumberFraction.h"
#import "CHChalkValueNumberGmp.h"
#import "CHChalkValueNumberRaw.h"
#import "CHChalkValueSubscript.h"
#import "CHComputationConfiguration.h"
#import "CHParserFunctionNode.h"
#import "CHPresentationConfiguration.h"
#import "CHStreamWrapper.h"
#import "CHUtils.h"
#import "NSAttributedStringExtended.h"
#import "NSMutableArrayExtended.h"
#import "NSObjectExtended.h"
#import "NSStringExtended.h"

#import "chalk-parser.h"

@interface CHParserOperatorNode()
+(CHChalkValueList*) combineSEL:(SEL)selector arguments:(NSArray*)arguments list:(CHChalkValueList*)list index:(NSUInteger)index operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combine2_1:(SEL)selector operands:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combine2_2:(SEL)selector operands:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context;
@end

@implementation CHParserOperatorNode

@synthesize op;

+(instancetype) parserNodeWithToken:(CHChalkToken*)token operator:(NSUInteger)op
{
  return [[[[self class] alloc] initWithToken:token operator:op] autorelease];
}
//end parserNodeWithToken:operator:

-(instancetype) initWithToken:(CHChalkToken*)aToken operator:(NSUInteger)aOp
{
  if (!((self = [super initWithToken:aToken])))
    return nil;
  self->op = aOp;
  return self;
}
//end initWithToken:operator:

-(void) dealloc
{
  [super dealloc];
}
//end dealloc

-(id) copyWithZone:(NSZone*)zone
{
  CHParserOperatorNode* result = [super copyWithZone:zone];
  if (result)
  {
    result->op = self->op;
  }//end if (result)
  return result;
}
//end copyWithZone:

-(BOOL) isPredicate
{
  BOOL result =
   (self->op == CHALK_OPERATOR_EQU) ||
   (self->op == CHALK_OPERATOR_LEQ) ||
   (self->op == CHALK_OPERATOR_GEQ) ||
   (self->op == CHALK_OPERATOR_LOW) ||
   (self->op == CHALK_OPERATOR_GRE) ||
   (self->op == CHALK_OPERATOR_AND) || (self->op == CHALK_OPERATOR_AND2) ||
   (self->op == CHALK_OPERATOR_OR)  || (self->op == CHALK_OPERATOR_OR2) ||
   (self->op == CHALK_OPERATOR_XOR) || (self->op == CHALK_OPERATOR_XOR2);
  return result;
}
//end isPredicate

-(void) performEvaluationWithContext:(CHChalkContext*)context lazy:(BOOL)lazy
{
  __block BOOL optimizedEvaluation = NO;
  if ((self->op == CHALK_OPERATOR_AND) || (self->op == CHALK_OPERATOR_AND2))
  {
    if (!lazy || !self.evaluatedValue)
    {
      [self->children enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CHParserNode* childNode = [obj dynamicCastToClass:[CHParserNode class]];
        [childNode performEvaluationWithContext:context lazy:lazy];
        CHChalkValue* value = [childNode evaluatedValue];
        CHChalkValueBoolean* valueBoolean = [value dynamicCastToClass:[CHChalkValueBoolean class]];
        if (valueBoolean && (valueBoolean.chalkBoolValue == CHALK_BOOL_NO))
        {
          self.evaluatedValue = [[value copy] autorelease];
          optimizedEvaluation = YES;
          *stop = YES;
        }//end if (valueBoolean && (valueBoolean.chalkBoolValue == CHALK_BOOL_YES))
        self->evaluationComputeFlags |= !self.evaluatedValue ? 0 : self.evaluatedValue.evaluationComputeFlags;
        if (context.errorContext.hasError && stop)
          *stop = YES;
      }];
    }//end if (!lazy || !self.evaluatedValue)
  }//end if ((self->op == CHALK_OPERATOR_AND) || (self->op == CHALK_OPERATOR_AND2))
  else if ((self->op == CHALK_OPERATOR_OR) || (self->op == CHALK_OPERATOR_OR2))
  {
    if (!lazy || !self.evaluatedValue)
    {
      [self->children enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CHParserNode* childNode = [obj dynamicCastToClass:[CHParserNode class]];
        [childNode performEvaluationWithContext:context lazy:lazy];
        CHChalkValue* value = [childNode evaluatedValue];
        CHChalkValueBoolean* valueBoolean = [value dynamicCastToClass:[CHChalkValueBoolean class]];
        if (valueBoolean && (valueBoolean.chalkBoolValue == CHALK_BOOL_YES))
        {
          self.evaluatedValue = [[value copy] autorelease];
          optimizedEvaluation = YES;
          *stop = YES;
        }//end if (valueBoolean && (valueBoolean.chalkBoolValue == CHALK_BOOL_YES))
        self->evaluationComputeFlags |= !self.evaluatedValue ? 0 : self.evaluatedValue.evaluationComputeFlags;
        if (context.errorContext.hasError && stop)
          *stop = YES;
      }];
    }//end if (!lazy || !self.evaluatedValue)
  }//end if ((self->op == CHALK_OPERATOR_OR) || (self->op == CHALK_OPERATOR_OR2))
  else
    [super performEvaluationWithContext:context lazy:lazy];
  
  if (!optimizedEvaluation && (!lazy || !self.evaluatedValue))
  {
    NSMutableArray* childrenValues = [NSMutableArray arrayWithCapacity:self->children.count];
    for(CHParserNode* child in self->children)
      [childrenValues safeAddObject:child.evaluatedValue];
    CHChalkValue* value = nil;
    if (!context.errorContext.hasError)
    {
      value = [[self class] combine:childrenValues operator:self->op operatorToken:self->token context:context];
      [self addError:context.errorContext.error];
    }//end if (!context.errorContext.hasError)
    self->evaluationComputeFlags |= !value ? 0 : value.evaluationComputeFlags;
    if (!value && !context.errorContext.hasError)
      [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:self->token.range] context:context];
    self.evaluatedValue = value;
  }//end if (!lazy || !self.evaluatedValue)
  [context.errorContext.error setContextGenerator:self replace:NO];
}
//end performEvaluationWithContext:

-(void) writeBodyToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  NSUInteger childCount = self->children.count;
  CHParserNode* child1 = (childCount<1) ? nil : [[self->children objectAtIndex:0] dynamicCastToClass:[CHParserNode class]];
  CHParserNode* child2 = (childCount<2) ? nil : [[self->children objectAtIndex:1] dynamicCastToClass:[CHParserNode class]];
  BOOL hasParenthesis1 = child1 && !child1.isTerminal;
  BOOL hasParenthesis2 = child2 && !child2.isTerminal;
  CHChalkOperatorManager* operatorManager = context.operatorManager;
  CHChalkOperator* operatorIdentifier = [operatorManager operatorForIdentifier:self->op];
  if (operatorIdentifier)
  {
    NSString* symbol = operatorIdentifier.symbol;
    if ([symbol isMatchedByRegex:@"^[a-zA-Z].*"])
      symbol = [NSString stringWithFormat:@" %@", symbol];
    if ([symbol isMatchedByRegex:@".*[a-zA-Z]$"])
      symbol = [NSString stringWithFormat:@"%@ ", symbol];
    if (!presentationConfiguration || (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_STRING))
    {
      NSString* parenthesis1Left = hasParenthesis1 ? @"(" : nil;
      NSString* parenthesis1Right = hasParenthesis1 ? @")" : nil;
      NSString* parenthesis2Left = hasParenthesis2 ? @"(" : nil;
      NSString* parenthesis2Right = hasParenthesis2 ? @")" : nil;
      NSUInteger placeHoldersCount = [symbol componentsMatchedByRegex:@"%@"].count;
      if (placeHoldersCount == childCount)
      {
        NSArray* components = [symbol componentsSeparatedByString:@"%@"];
        for(NSUInteger i = 0 ; i<childCount ; ++i)
        {
          [stream writeString:[components objectAtIndex:i]];
          CHParserNode* parserNode = [[self->children objectAtIndex:i] dynamicCastToClass:[CHParserNode class]];
          BOOL isTerminal = parserNode.isTerminal;
          if (!isTerminal)
            [stream writeString:@"("];
          [parserNode writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
          if (!isTerminal)
            [stream writeString:@")"];
        }//end for each child
        [stream writeString:[components lastObject]];
      }//end if (placeHoldersCount == argsCount)
      else if (placeHoldersCount > 0){
      }
      else if (!child1){
      }
      else if (!child2)
      {
        if ((operatorIdentifier.operatorPosition & CHALK_OPERATOR_POSITION_PREFIX) != 0)
          [stream writeString:symbol];
        [stream writeString:parenthesis1Left];
        [child1 writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
        [stream writeString:parenthesis1Right];
        if ((operatorIdentifier.operatorPosition & CHALK_OPERATOR_POSITION_POSTFIX) != 0)
          [stream writeString:symbol];
      }//end if (!child2)
      else if (child1 && child2)
      {
        if (((operatorIdentifier.operatorPosition & CHALK_OPERATOR_POSITION_PREFIX) != 0) &&
            ((operatorIdentifier.operatorPosition & CHALK_OPERATOR_POSITION_INFIX) == 0))
          [stream writeString:symbol];
        [stream writeString:parenthesis1Left];
        [child1 writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
        [stream writeString:parenthesis1Right];
        if ((operatorIdentifier.operatorPosition & CHALK_OPERATOR_POSITION_INFIX) != 0)
          [stream writeString:symbol];
        [stream writeString:parenthesis2Left];
        [child2 writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
        [stream writeString:parenthesis2Right];
        if (((operatorIdentifier.operatorPosition & CHALK_OPERATOR_POSITION_POSTFIX) != 0) &&
            ((operatorIdentifier.operatorPosition & CHALK_OPERATOR_POSITION_INFIX) == 0))
          [stream writeString:symbol];
      }//end if (child1 && child2)
    }//end if (!presentationConfiguration || (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_STRING))
    else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_ATTRIBUTEDSTRING)
    {
      NSAttributedString* parenthesis1LeftAttributed  = [[[NSAttributedString alloc] initWithString:@"("] autorelease];
      NSAttributedString* parenthesis1RightAttributed = [[[NSAttributedString alloc] initWithString:@")"] autorelease];
      NSAttributedString* parenthesis2LeftAttributed  = [[[NSAttributedString alloc] initWithString:@"("] autorelease];
      NSAttributedString* parenthesis2RightAttributed = [[[NSAttributedString alloc] initWithString:@")"] autorelease];
      NSAttributedString* attributedSymbol = [[[NSAttributedString alloc] initWithString:symbol] autorelease];
      NSUInteger placeHoldersCount = [symbol componentsMatchedByRegex:@"%@"].count;
      if (placeHoldersCount == childCount)
      {
        NSArray* components = [symbol componentsSeparatedByString:@"%@"];
        for(NSUInteger i = 0 ; i<childCount ; ++i)
        {
          [stream writeString:[components objectAtIndex:i]];
          CHParserNode* parserNode = [[self->children objectAtIndex:i] dynamicCastToClass:[CHParserNode class]];
          BOOL isTerminal = parserNode.isTerminal;
          if (!isTerminal)
            [stream writeString:@"("];
          [parserNode writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
          if (!isTerminal)
            [stream writeString:@")"];
        }//end for each child
        [stream writeString:[components lastObject]];
      }//end if (placeHoldersCount == argsCount)
      else if (placeHoldersCount > 0){
      }
      else if (!child1){
      }
      else if (!child2)
      {
        if ((operatorIdentifier.operatorPosition & CHALK_OPERATOR_POSITION_PREFIX) != 0)
          [stream writeAttributedString:attributedSymbol];
        [stream writeAttributedString:parenthesis1LeftAttributed];
        [child1 writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
        [stream writeAttributedString:parenthesis1RightAttributed];
        if ((operatorIdentifier.operatorPosition & CHALK_OPERATOR_POSITION_POSTFIX) != 0)
          [stream writeAttributedString:attributedSymbol];
      }//end if (!child2)
      else if (child1 && child2)
      {
        if (((operatorIdentifier.operatorPosition & CHALK_OPERATOR_POSITION_PREFIX) != 0) &&
            ((operatorIdentifier.operatorPosition & CHALK_OPERATOR_POSITION_INFIX) == 0))
          [stream writeAttributedString:attributedSymbol];
        [stream writeAttributedString:parenthesis1LeftAttributed];
        [child1 writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
        [stream writeAttributedString:parenthesis1RightAttributed];
        if ((operatorIdentifier.operatorPosition & CHALK_OPERATOR_POSITION_INFIX) != 0)
          [stream writeString:operatorIdentifier.symbolAsText];
        [stream writeAttributedString:parenthesis2LeftAttributed];
        [child2 writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
        [stream writeAttributedString:parenthesis2RightAttributed];
        if (((operatorIdentifier.operatorPosition & CHALK_OPERATOR_POSITION_POSTFIX) != 0) &&
            ((operatorIdentifier.operatorPosition & CHALK_OPERATOR_POSITION_INFIX) == 0))
          [stream writeAttributedString:attributedSymbol];
      }//end if (child1 && child2)
    }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_ATTRIBUTEDSTRING)
    else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_DOT)
    {
      NSString* selfNodeIdentifier = [NSString stringWithFormat:@"_%p", self];
      [stream writeString:[NSString stringWithFormat:@"%@ [label=\"%@\"];n", selfNodeIdentifier, symbol]];
      for(CHParserNode* child in children)
        [child writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
    }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_DOT)
    else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_MATHML)
    {
      NSString* parenthesis1Left = hasParenthesis1 ? @"<mfenced>" : nil;
      NSString* parenthesis1Right = hasParenthesis1 ? @"</mfenced>" : nil;
      NSString* parenthesis2Left = hasParenthesis2 ? @"<mfenced>" : nil;
      NSString* parenthesis2Right = hasParenthesis2 ? @"</mfenced>" : nil;
      NSString* mathSymbol = [NSString stringWithFormat:@"<mo>%@</mo>", symbol];
      NSUInteger placeHoldersCount = [mathSymbol componentsMatchedByRegex:@"%@"].count;
      if (placeHoldersCount == childCount)
      {
        NSArray* components = [symbol componentsSeparatedByString:@"%@"];
        for(NSUInteger i = 0 ; i<childCount ; ++i)
        {
          [stream writeString:[components objectAtIndex:i]];
          CHParserNode* parserNode = [[self->children objectAtIndex:i] dynamicCastToClass:[CHParserNode class]];
          BOOL isTerminal = parserNode.isTerminal;
          if (!isTerminal)
            [stream writeString:@"("];
          [parserNode writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
          if (!isTerminal)
            [stream writeString:@")"];
        }//end for each child
        [stream writeString:[components lastObject]];
      }//end if (placeHoldersCount == argsCount)
      else if (placeHoldersCount > 0){
      }
      else if (!child1){
      }
      else if (!child2)
      {
        if ((operatorIdentifier.operatorPosition & CHALK_OPERATOR_POSITION_PREFIX) != 0)
          [stream writeString:mathSymbol];
        [stream writeString:parenthesis1Left];
        [child1 writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
        [stream writeString:parenthesis1Right];
        if ((operatorIdentifier.operatorPosition & CHALK_OPERATOR_POSITION_POSTFIX) != 0)
          [stream writeString:mathSymbol];
      }//end if (!child2)
      else if (child1 && child2)
      {
        if (((operatorIdentifier.operatorPosition & CHALK_OPERATOR_POSITION_PREFIX) != 0) &&
            ((operatorIdentifier.operatorPosition & CHALK_OPERATOR_POSITION_INFIX) == 0))
          [stream writeString:mathSymbol];
        [stream writeString:parenthesis1Left];
        [child1 writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
        [stream writeString:parenthesis1Right];
        if ((operatorIdentifier.operatorPosition & CHALK_OPERATOR_POSITION_INFIX) != 0)
          [stream writeString:mathSymbol];
        [stream writeString:parenthesis2Left];
        [child2 writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
        [stream writeString:parenthesis2Right];
        if (((operatorIdentifier.operatorPosition & CHALK_OPERATOR_POSITION_POSTFIX) != 0) &&
            ((operatorIdentifier.operatorPosition & CHALK_OPERATOR_POSITION_INFIX) == 0))
          [stream writeString:mathSymbol];
      }//end if (child1 && child2)
    }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_MATHML)
    else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
    {
      NSString* parenthesis1Left = hasParenthesis1 ? @"{(" : nil;
      NSString* parenthesis1Right = hasParenthesis1 ? @")}" : nil;
      NSString* parenthesis2Left = hasParenthesis2 ? @"{(" : nil;
      NSString* parenthesis2Right = hasParenthesis2 ? @")}" : nil;
      NSString* texSymbol = operatorIdentifier.symbolAsTeX;
      NSUInteger placeHoldersCount = [texSymbol componentsMatchedByRegex:@"%@"].count;
      if (placeHoldersCount == children.count)
      {
        NSArray* components = [texSymbol componentsSeparatedByString:@"%@"];
        for(NSUInteger i = 0, count = children.count ; i<count ; ++i)
        {
          [stream writeString:[components objectAtIndex:i]];
          CHParserNode* parserNode = [[children objectAtIndex:i] dynamicCastToClass:[CHParserNode class]];
          BOOL shouldUseParenthesis = parserNode && !parserNode.isTerminal &&
            (self->op != CHALK_OPERATOR_DIVIDE);
          if (shouldUseParenthesis)
            [stream writeString:@"("];
          [parserNode writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
          if (shouldUseParenthesis)
            [stream writeString:@")"];
        }//end for each child
        [stream writeString:[components lastObject]];
      }//end if (placeHoldersCount == children.count)
      else if (placeHoldersCount > 0){
      }
      else if (!child1){
      }
      else if (!child2)
      {
        if ((operatorIdentifier.operatorPosition & CHALK_OPERATOR_POSITION_PREFIX) != 0)
          [stream writeString:texSymbol];
        BOOL shouldUseParenthesis = (self->op != CHALK_OPERATOR_ABS);
        if (shouldUseParenthesis)
          [stream writeString:parenthesis1Left];
        [child1 writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
        if (shouldUseParenthesis)
          [stream writeString:parenthesis1Right];
        if ((operatorIdentifier.operatorPosition & CHALK_OPERATOR_POSITION_POSTFIX) != 0)
          [stream writeString:texSymbol];
      }//end if (!child2)
      else if (child1 && child2)
      {
        if (((operatorIdentifier.operatorPosition & CHALK_OPERATOR_POSITION_PREFIX) != 0) &&
            ((operatorIdentifier.operatorPosition & CHALK_OPERATOR_POSITION_INFIX) == 0))
          [stream writeString:texSymbol];
        [stream writeString:parenthesis1Left];
        [child1 writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
        [stream writeString:parenthesis1Right];
        if ((operatorIdentifier.operatorPosition & CHALK_OPERATOR_POSITION_INFIX) != 0)
          [stream writeString:texSymbol];
        [stream writeString:parenthesis2Left];
        [child2 writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
        [stream writeString:parenthesis2Right];
        if (((operatorIdentifier.operatorPosition & CHALK_OPERATOR_POSITION_POSTFIX) != 0) &&
            ((operatorIdentifier.operatorPosition & CHALK_OPERATOR_POSITION_INFIX) == 0))
          [stream writeString:texSymbol];
      }//end if (child1 && child2)
    }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
    else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_HTML)
    {
      NSString* operatorHeader = nil;
      NSString* operatorFooter = nil;
      if (self->evaluationErrors.count)
      {
        NSString* errorsString = [[[self->evaluationErrors valueForKey:@"friendlyDescription"] componentsJoinedByString:@","] stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
        operatorHeader = [NSString stringWithFormat:@"<span class=\"errorFlag\" onmouseover=\"tooltip.show('%@');\" onmouseout=\"tooltip.hide();\">", errorsString];
        operatorFooter = @"</span>";
      }//end if (self->evaluationErrors.count)
      else if ((presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_HTML) && (self->evaluationComputeFlags != CHALK_COMPUTE_FLAG_NONE))
      {
      CHChalkValueNumberRaw* evaluatedValueRaw = [self->evaluatedValue dynamicCastToClass:[CHChalkValueNumberRaw class]];
      const chalk_raw_value_t* rawValue = evaluatedValueRaw.valueConstReference;
      const chalk_bit_interpretation_t* bitInterpretation = !rawValue ? 0 : &rawValue->bitInterpretation;
        NSString* flagsImageString = [chalkGmpComputeFlagsGetHTML(self->evaluationComputeFlags, bitInterpretation, NO) stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
        operatorHeader = [NSString stringWithFormat:@"<span class=\"hasTooltip\" onmouseover=\"tooltip.show('%@');\" onmouseout=\"tooltip.hide();\">", flagsImageString];
        operatorFooter = @"</span>";
      }//end if ((presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_HTML) && (self->evaluationComputeFlags != CHALK_COMPUTE_FLAG_NONE))

      NSString* parenthesis1Left = hasParenthesis1 ? @"(" : nil;
      NSString* parenthesis1Right = hasParenthesis1 ? @")" : nil;
      NSString* parenthesis2Left = hasParenthesis2 ? @"(" : nil;
      NSString* parenthesis2Right = hasParenthesis2 ? @")" : nil;
      NSString* fullSymbol = [NSString stringWithFormat:@"%@%@%@",
        !operatorHeader ? @"" : operatorHeader,
        symbol,
        !operatorFooter ? @"" : operatorFooter];
      NSUInteger placeHoldersCount = [fullSymbol componentsMatchedByRegex:@"%@"].count;
      if (placeHoldersCount == childCount)
      {
        NSArray* components = [fullSymbol componentsSeparatedByString:@"%@"];
        for(NSUInteger i = 0 ; i<childCount ; ++i)
        {
          [stream writeString:[components objectAtIndex:i]];
          CHParserNode* parserNode = [[self->children objectAtIndex:i] dynamicCastToClass:[CHParserNode class]];
          BOOL isTerminal = parserNode.isTerminal;
          if (!isTerminal)
            [stream writeString:@"("];
          [parserNode writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
          if (!isTerminal)
            [stream writeString:@")"];
        }//end for each child
        [stream writeString:[components lastObject]];
      }//end if (placeHoldersCount == argsCount)
      else if (placeHoldersCount > 0){
      }
      else if (!child1){
      }
      else if (!child2)
      {
        if ((operatorIdentifier.operatorPosition & CHALK_OPERATOR_POSITION_PREFIX) != 0)
          [stream writeString:fullSymbol];
        [stream writeString:parenthesis1Left];
        [child1 writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
        [stream writeString:parenthesis1Right];
        if ((operatorIdentifier.operatorPosition & CHALK_OPERATOR_POSITION_POSTFIX) != 0)
          [stream writeString:fullSymbol];
      }//end if (!child2)
      else if (child1 && child2)
      {
        if (((operatorIdentifier.operatorPosition & CHALK_OPERATOR_POSITION_PREFIX) != 0) &&
            ((operatorIdentifier.operatorPosition & CHALK_OPERATOR_POSITION_INFIX) == 0))
          [stream writeString:fullSymbol];
        [stream writeString:parenthesis1Left];
        [child1 writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
        [stream writeString:parenthesis1Right];
        if ((operatorIdentifier.operatorPosition & CHALK_OPERATOR_POSITION_INFIX) != 0)
          [stream writeString:fullSymbol];
        [stream writeString:parenthesis2Left];
        [child2 writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
        [stream writeString:parenthesis2Right];
        if (((operatorIdentifier.operatorPosition & CHALK_OPERATOR_POSITION_POSTFIX) != 0) &&
            ((operatorIdentifier.operatorPosition & CHALK_OPERATOR_POSITION_INFIX) == 0))
          [stream writeString:fullSymbol];
      }//end if (child1 && child2)
    }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_HTML)
  }//end if (operatorIdentifier)
}
//end writeBodyToStream:context:options:

+(id) combine:(NSArray*)operands operator:(chalk_operator_t)op operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  static NSDictionary* operators = nil;
  if (!operators)
  {
    @synchronized(self)
    {
      if (!operators)
        operators = [@{
          @(CHALK_OPERATOR_PLUS):[NSValue valueWithPointer:@selector(combineAdd:operatorToken:context:)],
          @(CHALK_OPERATOR_PLUS2):[NSValue valueWithPointer:@selector(combineAdd2:operatorToken:context:)],
          @(CHALK_OPERATOR_MINUS):[NSValue valueWithPointer:@selector(combineSub:operatorToken:context:)],
          @(CHALK_OPERATOR_MINUS2):[NSValue valueWithPointer:@selector(combineSub2:operatorToken:context:)],
          @(CHALK_OPERATOR_TIMES):[NSValue valueWithPointer:@selector(combineMul:operatorToken:context:)],
          @(CHALK_OPERATOR_TIMES2):[NSValue valueWithPointer:@selector(combineMul2:operatorToken:context:)],
          @(CHALK_OPERATOR_DIVIDE):[NSValue valueWithPointer:@selector(combineDiv:operatorToken:context:)],
          @(CHALK_OPERATOR_DIVIDE2):[NSValue valueWithPointer:@selector(combineDiv2:operatorToken:context:)],
          @(CHALK_OPERATOR_POW):[NSValue valueWithPointer:@selector(combinePow:operatorToken:context:)],
          @(CHALK_OPERATOR_POW2):[NSValue valueWithPointer:@selector(combinePow2:operatorToken:context:)],
          @(CHALK_OPERATOR_SQRT):[NSValue valueWithPointer:@selector(combineSqrt:operatorToken:context:)],
          @(CHALK_OPERATOR_SQRT2):[NSValue valueWithPointer:@selector(combineSqrt2:operatorToken:context:)],
          @(CHALK_OPERATOR_CBRT):[NSValue valueWithPointer:@selector(combineCbrt:operatorToken:context:)],
          @(CHALK_OPERATOR_CBRT2):[NSValue valueWithPointer:@selector(combineCbrt2:operatorToken:context:)],
          @(CHALK_OPERATOR_MUL_SQRT):[NSValue valueWithPointer:@selector(combineMulSqrt:operatorToken:context:)],
          @(CHALK_OPERATOR_MUL_SQRT2):[NSValue valueWithPointer:@selector(combineMulSqrt2:operatorToken:context:)],
          @(CHALK_OPERATOR_MUL_CBRT):[NSValue valueWithPointer:@selector(combineMulCbrt:operatorToken:context:)],
          @(CHALK_OPERATOR_MUL_CBRT2):[NSValue valueWithPointer:@selector(combineMulCbrt2:operatorToken:context:)],
          @(CHALK_OPERATOR_DEGREE):[NSValue valueWithPointer:@selector(combineDegree:operatorToken:context:)],
          @(CHALK_OPERATOR_DEGREE2):[NSValue valueWithPointer:@selector(combineDegree2:operatorToken:context:)],
          @(CHALK_OPERATOR_FACTORIAL):[NSValue valueWithPointer:@selector(combineFactorial:operatorToken:context:)],
          @(CHALK_OPERATOR_FACTORIAL2):[NSValue valueWithPointer:@selector(combineFactorial2:operatorToken:context:)],
          @(CHALK_OPERATOR_UNCERTAINTY):[NSValue valueWithPointer:@selector(combineUncertainty:operatorToken:context:)],
          @(CHALK_OPERATOR_ABS):[NSValue valueWithPointer:@selector(combineAbs:operatorToken:context:)],
          @(CHALK_OPERATOR_NOT):[NSValue valueWithPointer:@selector(combineNot:operatorToken:context:)],
          @(CHALK_OPERATOR_NOT2):[NSValue valueWithPointer:@selector(combineNot2:operatorToken:context:)],
          @(CHALK_OPERATOR_LEQ):[NSValue valueWithPointer:@selector(combineLeq:operatorToken:context:)],
          @(CHALK_OPERATOR_LEQ2):[NSValue valueWithPointer:@selector(combineLeq2:operatorToken:context:)],
          @(CHALK_OPERATOR_GEQ):[NSValue valueWithPointer:@selector(combineGeq:operatorToken:context:)],
          @(CHALK_OPERATOR_GEQ2):[NSValue valueWithPointer:@selector(combineGeq2:operatorToken:context:)],
          @(CHALK_OPERATOR_LOW):[NSValue valueWithPointer:@selector(combineLow:operatorToken:context:)],
          @(CHALK_OPERATOR_LOW2):[NSValue valueWithPointer:@selector(combineLow2:operatorToken:context:)],
          @(CHALK_OPERATOR_GRE):[NSValue valueWithPointer:@selector(combineGre:operatorToken:context:)],
          @(CHALK_OPERATOR_GRE2):[NSValue valueWithPointer:@selector(combineGre2:operatorToken:context:)],
          @(CHALK_OPERATOR_EQU):[NSValue valueWithPointer:@selector(combineEqu:operatorToken:context:)],
          @(CHALK_OPERATOR_EQU2):[NSValue valueWithPointer:@selector(combineEqu2:operatorToken:context:)],
          @(CHALK_OPERATOR_NEQ):[NSValue valueWithPointer:@selector(combineNeq:operatorToken:context:)],
          @(CHALK_OPERATOR_NEQ2):[NSValue valueWithPointer:@selector(combineNeq2:operatorToken:context:)],
          @(CHALK_OPERATOR_AND):[NSValue valueWithPointer:@selector(combineAnd:operatorToken:context:)],
          @(CHALK_OPERATOR_AND2):[NSValue valueWithPointer:@selector(combineAnd2:operatorToken:context:)],
          @(CHALK_OPERATOR_OR):[NSValue valueWithPointer:@selector(combineOr:operatorToken:context:)],
          @(CHALK_OPERATOR_OR2):[NSValue valueWithPointer:@selector(combineOr2:operatorToken:context:)],
          @(CHALK_OPERATOR_XOR):[NSValue valueWithPointer:@selector(combineXor:operatorToken:context:)],
          @(CHALK_OPERATOR_XOR2):[NSValue valueWithPointer:@selector(combineXor2:operatorToken:context:)],
          @(CHALK_OPERATOR_SHL):[NSValue valueWithPointer:@selector(combineShl:operatorToken:context:)],
          @(CHALK_OPERATOR_SHL2):[NSValue valueWithPointer:@selector(combineShl2:operatorToken:context:)],
          @(CHALK_OPERATOR_SHR):[NSValue valueWithPointer:@selector(combineShr:operatorToken:context:)],
          @(CHALK_OPERATOR_SHR2):[NSValue valueWithPointer:@selector(combineShr2:operatorToken:context:)],
          @(CHALK_OPERATOR_SUBSCRIPT):[NSValue valueWithPointer:@selector(combineSubscript:operatorToken:context:)]
         } retain];
    }//end @synchronized(self)
  }//end if (!operators)
  SEL selector = (SEL)[[[operators objectForKey:@(op)] dynamicCastToClass:[NSValue class]] pointerValue];
  if (!selector)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorUnknown range:token.range] replace:NO];
  else
    result = [self performSelector:selector withArguments:@[operands, token, context]];
  return result;
}
//end combine:operator:context:

+(CHChalkValueList*) combineSEL:(SEL)selector arguments:(NSArray*)arguments list:(CHChalkValueList*)list index:(NSUInteger)index operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValueList* result = nil;
  if (arguments && list)
  {
    CHChalkValueList* newList = [[CHChalkValueList alloc] initWithToken:token count:list.count value:nil context:context];
    if (!newList)
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                             replace:NO];
    else//if (newList)
    {
      IMP imp = [self methodForSelector:selector];
      typedef CHChalkValue* (*imp_sel_t)(id, SEL, NSArray*, CHChalkToken*, CHChalkContext*);
      imp_sel_t imp_sel = (imp_sel_t)imp;
      [list.values enumerateObjectsWithOptions:
        (context.concurrentEvaluations ? NSEnumerationConcurrent : 0)
        usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CHChalkValue* elementValue = [obj dynamicCastToClass:[CHChalkValue class]];
        NSMutableArray* newArguments = [NSMutableArray arrayWithArray:arguments];
        CHChalkValue* newElementValue = nil;
        if (!newArguments){
        }
        else if (elementValue)
        {
          [newArguments replaceObjectAtIndex:index withObject:elementValue];
          newElementValue = (CHChalkValue*)imp_sel(self, selector, newArguments, token, context);
        }//end if (elementValue)
        if (newElementValue)
          [newList setValue:newElementValue atIndex:idx];
        else//if (newElementValue)
        {
          *stop = YES;
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
        }//end if (!newElementValue)
      }];
    }//end if (newList)
    result = [newList autorelease];
    [newList.values enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      result.evaluationComputeFlags |= ((CHChalkValue*)[obj dynamicCastToClass:[CHChalkValue class]]).evaluationComputeFlags;
    }];
  }//end if (arguments && list)
  return result;
}
//end combineSEL:arguments:list:index:operatorToken:context:

+(CHChalkValue*) combine2_1:(SEL)selector operands:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    id operand = [operands objectAtIndex:0];
    CHChalkValueScalar* operandScalar = [operand dynamicCastToClass:[CHChalkValueScalar class]];
    CHChalkValueMatrix* operandMatrix = [operand dynamicCastToClass:[CHChalkValueMatrix class]];
    CHChalkValueList* operandList = [operand dynamicCastToClass:[CHChalkValueList class]];
    if (operandScalar)
    {
      IMP imp = [self methodForSelector:selector];
      typedef CHChalkValue* (*imp_sel_t)(id, SEL, NSArray*, CHChalkToken*, CHChalkContext*);
      imp_sel_t imp_sel = (imp_sel_t)imp;
      result = (CHChalkValue*)imp_sel(self, selector, @[operandScalar], token, context);
    }//end if (operandScalar)
    else if (operandMatrix)
    {
      __block CHChalkValueMatrix* currentValueMatrix = [[CHChalkValueMatrix alloc] initWithToken:token rowsCount:operandMatrix.rowsCount colsCount:operandMatrix.colsCount value:nil context:context];
      if (!currentValueMatrix)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      else//if (currentValueMatrix)
      {
        IMP imp = [self methodForSelector:selector];
        typedef CHChalkValue* (*imp_sel_t)(id, SEL, NSArray*, CHChalkToken*, CHChalkContext*);
        imp_sel_t imp_sel = (imp_sel_t)imp;
        NSUInteger colsCount = currentValueMatrix.colsCount;
        [currentValueMatrix.values enumerateObjectsWithOptions:
          (context.concurrentEvaluations ? NSEnumerationConcurrent : 0)
          usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
          NSUInteger row = !colsCount ? 0 :idx/colsCount;
          NSUInteger col = !colsCount ? 0 :idx%colsCount;
          CHChalkValue* oldValue = [operandMatrix valueAtRow:row col:col];
          CHChalkValue* newValue = (CHChalkValue*)imp_sel(self, selector, @[oldValue], token, context);
          if (newValue)
            [currentValueMatrix setValue:newValue atRow:row col:col];
          else//if (!newValue)
          {
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                   replace:NO];
            *stop = YES;
          }//end if (!newValue)
        }];
        if (context.errorContext.hasError)
        {
          [currentValueMatrix release];
          currentValueMatrix = nil;
        }//end if (context.errorContext.hasError)
      }//end if (currentValueMatrix)
      result = [currentValueMatrix autorelease];
    }//end if (operandMatrix)
    else if (operandList)
    {
      __block CHChalkValueList* currentValueList = [[CHChalkValueList alloc] initWithToken:token count:operandList.count value:nil context:context];
      if (!currentValueList)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      else//if (currentValueList)
      {
        IMP imp = [self methodForSelector:selector];
        typedef CHChalkValue* (*imp_sel_t)(id, SEL, NSArray*, CHChalkToken*, CHChalkContext*);
        imp_sel_t imp_sel = (imp_sel_t)imp;
        [currentValueList.values enumerateObjectsWithOptions:
          (context.concurrentEvaluations ? NSEnumerationConcurrent : 0)
          usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
          CHChalkValue* oldValue = [operandList valueAtIndex:idx];
          CHChalkValue* newValue = (CHChalkValue*)imp_sel(self, selector, @[oldValue], token, context);
          if (newValue)
            [currentValueList setValue:newValue atIndex:idx];
          else//if (!newValue)
          {
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                   replace:NO];
            *stop = YES;
          }//end if (!newValue)
        }];
        if (context.errorContext.hasError)
        {
          [currentValueList release];
          currentValueList = nil;
        }//end if (context.errorContext.hasError)
      }//end if (currentValueList)
      result = [currentValueList autorelease];
    }//end if (operandList)
  }//end if (operands.count == 1)
  return result;
}
//end combine2_1:operatorToken:context:

+(CHChalkValue*) combine2_2:(SEL)selector operands:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count < 2)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count >= 2)
  {
    __block CHChalkValue* currentValue = nil;
    __block chalk_compute_flags_t computeFlags = 0;
    [operands enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      CHChalkValue* operand = [obj dynamicCastToClass:[CHChalkValue class]];
      if (!operand)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                               replace:NO];
      else if (!idx)
      {
        [currentValue release];
        currentValue = [operand copy];
        //[currentValue.token unionWithToken:token];//experimental
      }//end if (!idx)
      else//if (idx>0)
      {
        //[currentValue.token unionWithToken:operand.token];//experimental
        IMP imp = [self methodForSelector:selector];
        typedef CHChalkValue* (*imp_sel_t)(id, SEL, NSArray*, CHChalkToken*, CHChalkContext*);
        imp_sel_t imp_sel = (imp_sel_t)imp;
        CHChalkValueScalar* operandScalar = [operand dynamicCastToClass:[CHChalkValueScalar class]];
        CHChalkValueMatrix* operandMatrix = [operand dynamicCastToClass:[CHChalkValueMatrix class]];
        CHChalkValueList* operandList = [operand dynamicCastToClass:[CHChalkValueList class]];
        CHChalkValueScalar* currentValueScalar = [currentValue dynamicCastToClass:[CHChalkValueScalar class]];
        CHChalkValueMatrix* currentValueMatrix = [currentValue dynamicCastToClass:[CHChalkValueMatrix class]];
        CHChalkValueList* currentValueList = [currentValue dynamicCastToClass:[CHChalkValueList class]];
        if (currentValueMatrix && operandScalar)
        {
          NSUInteger colsCount = currentValueMatrix.colsCount;
          [currentValueMatrix.values enumerateObjectsWithOptions:
            (context.concurrentEvaluations ? NSEnumerationConcurrent : 0)
            usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSUInteger row = !colsCount ? 0 : idx/colsCount;
            NSUInteger col = !colsCount ? 0 : idx%colsCount;
            CHChalkValue* oldValue = [obj dynamicCastToClass:[CHChalkValue class]];
            CHChalkValue* newValue = !oldValue ? nil :
              (CHChalkValue*)imp_sel(self, selector, @[oldValue,operandScalar], token, context);
            if (newValue)
              [currentValueMatrix setValue:newValue atRow:row col:col];
            else
              *stop = YES;
          }];
        }//end if (currentValueMatrix && operandScalar)
        else if (currentValueScalar && operandMatrix)
        {
          IMP imp = [self methodForSelector:selector];
          typedef CHChalkValue* (*imp_sel_t)(id, SEL, NSArray*, CHChalkToken*, CHChalkContext*);
          imp_sel_t imp_sel = (imp_sel_t)imp;
          CHChalkValueMatrix* newMatrix = [[CHChalkValueMatrix alloc] initWithToken:token rowsCount:operandMatrix.rowsCount colsCount:operandMatrix.colsCount value:currentValueScalar context:context];
          if (!newMatrix)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range] replace:NO];
          NSUInteger colsCount = newMatrix.colsCount;
          [newMatrix.values enumerateObjectsWithOptions:
            (context.concurrentEvaluations ? NSEnumerationConcurrent : 0)
             usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSUInteger row = !colsCount ? 0 : idx/colsCount;
            NSUInteger col = !colsCount ? 0 : idx%colsCount;
            CHChalkValue* operandElementValue = [operandMatrix valueAtRow:row col:col];
            CHChalkValue* newValue = !currentValueScalar || !operandElementValue ? nil :
              (CHChalkValue*)imp_sel(self, selector, @[currentValueScalar,operandElementValue], token, context);
            if (newValue)
              [newMatrix setValue:newValue atRow:row col:col];
            else//if (!newValue)
            {
              [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range] replace:NO];
              *stop = YES;
            }//end if (!newValue)
          }];
          if (context.errorContext.hasError)
          {
            [newMatrix release];
            newMatrix = nil;
          }//end if (context.errorContext.hasError)
          [currentValue release];
          currentValue = newMatrix;
        }//end if (currentValueScalar && operandMatrix)
        else if (currentValueMatrix && operandMatrix)
        {
          if ((currentValueMatrix.rowsCount != operandMatrix.rowsCount) || (currentValueMatrix.colsCount != operandMatrix.colsCount))
          {
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorDimensionsMismatch range:token.range] replace:NO];
            [currentValue release];
            currentValue = nil;
          }//end if ((currentValueMatrix.rowsCount != operandMatrix.rowsCount) || (currentValueMatrix.colsCount != operandMatrix.colsCount))
          else//if ((currentValueMatrix.rowsCount == operandMatrix.rowsCount) && (currentValueMatrix.colsCount == operandMatrix.colsCount))
          {
            IMP imp = [self methodForSelector:selector];
            typedef CHChalkValue* (*imp_sel_t)(id, SEL, NSArray*, CHChalkToken*, CHChalkContext*);
            imp_sel_t imp_sel = (imp_sel_t)imp;
            NSUInteger colsCount = currentValueMatrix.colsCount;
            [currentValueMatrix.values enumerateObjectsWithOptions:
              (context.concurrentEvaluations ? NSEnumerationConcurrent : 0)
              usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
              NSUInteger row = !colsCount ? 0 : idx/colsCount;
              NSUInteger col = !colsCount ? 0 : idx%colsCount;
              CHChalkValue* oldValue = [currentValueMatrix valueAtRow:row col:col];
              CHChalkValue* operandElementValue = [operandMatrix valueAtRow:row col:col];
              CHChalkValue* newValue = !oldValue || !operandElementValue ? nil :
                (CHChalkValue*)imp_sel(self, selector, @[oldValue,operandElementValue], token, context);
              if (newValue)
                [currentValueMatrix setValue:newValue atRow:row col:col];
              else//if (!newValue)
              {
                [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range] replace:NO];
                *stop = YES;
              }//end if (!newValue)
            }];
            if (context.errorContext.hasError)
            {
              [currentValue release];
              currentValue = nil;
            }//end if (context.errorContext.hasError)
          }//end if ((currentValueMatrix.rowsCount == operandMatrix.rowsCount) && (currentValueMatrix.colsCount == operandMatrix.colsCount))
        }//end if (currentValueMatrix && operandMatrix)
        else if (currentValueList && operandScalar)
        {
          [currentValueList.values enumerateObjectsWithOptions:
            (context.concurrentEvaluations ? NSEnumerationConcurrent : 0)
            usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            CHChalkValue* oldValue = [obj dynamicCastToClass:[CHChalkValue class]];
            CHChalkValue* newValue = !oldValue ? nil :
              (CHChalkValue*)imp_sel(self, selector, @[oldValue,operandScalar], token, context);
            if (newValue)
              [currentValueList setValue:newValue atIndex:idx];
            else
              *stop = YES;
          }];
        }//end if (currentValueList && operandScalar)
        else if (currentValueScalar && operandList)
        {
          IMP imp = [self methodForSelector:selector];
          typedef CHChalkValue* (*imp_sel_t)(id, SEL, NSArray*, CHChalkToken*, CHChalkContext*);
          imp_sel_t imp_sel = (imp_sel_t)imp;
          CHChalkValueList* newList = [[CHChalkValueList alloc] initWithToken:token count:operandList.count value:currentValueScalar context:context];
          if (!newList)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range] replace:NO];
          [newList.values enumerateObjectsWithOptions:
            (context.concurrentEvaluations ? NSEnumerationConcurrent : 0)
            usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            CHChalkValue* operandElementValue = [operandList valueAtIndex:idx];
            CHChalkValue* newValue = !currentValueScalar || !operandElementValue ? nil :
              (CHChalkValue*)imp_sel(self, selector, @[currentValueScalar,operandElementValue], token, context);
            if (newValue)
              [newList setValue:newValue atIndex:idx];
            else//if (!newValue)
            {
              [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range] replace:NO];
              *stop = YES;
            }//end if (!newValue)
          }];
          if (context.errorContext.hasError)
          {
            [newList release];
            newList = nil;
          }//end if (context.errorContext.hasError)
          [currentValue release];
          currentValue = newList;
        }//end if (currentValueScalar && operandList)
        else if (currentValueList && operandList)
        {
          if (currentValueList.count != operandList.count)
          {
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorDimensionsMismatch range:token.range] replace:NO];
            [currentValue release];
            currentValue = nil;
          }//end if (currentValueList.count != operandList.count)
          else//if ((currentValueList.count == operandList.count)
          {
            IMP imp = [self methodForSelector:selector];
            typedef CHChalkValue* (*imp_sel_t)(id, SEL, NSArray*, CHChalkToken*, CHChalkContext*);
            imp_sel_t imp_sel = (imp_sel_t)imp;
            [currentValueList.values enumerateObjectsWithOptions:
              (context.concurrentEvaluations ? NSEnumerationConcurrent : 0)
              usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
              CHChalkValue* oldValue = [currentValueList valueAtIndex:idx];
              CHChalkValue* operandElementValue = [operandList valueAtIndex:idx];
              CHChalkValue* newValue = !oldValue || !operandElementValue ? nil :
                (CHChalkValue*)imp_sel(self, selector, @[oldValue,operandElementValue], token, context);
              if (newValue)
                [currentValueList setValue:newValue atIndex:idx];
              else//if (!newValue)
              {
                [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range] replace:NO];
                *stop = YES;
              }//end if (!newValue)
            }];
            if (context.errorContext.hasError)
            {
              [currentValue release];
              currentValue = nil;
            }//end if (context.errorContext.hasError)
          }//end if ((currentValueList.rowsCount == operandList.rowsCount) && (currentValueList.colsCount == operandList.colsCount))
        }//end if (currentValueList && operandList)
        else//if (...)
        {
          IMP imp = [self methodForSelector:selector];
          typedef CHChalkValue* (*imp_sel_t)(id, SEL, NSArray*, CHChalkToken*, CHChalkContext*);
          imp_sel_t imp_sel = (imp_sel_t)imp;
          CHChalkValue* newValue =
            (CHChalkValue*)imp_sel(self, selector, @[currentValue, operand], token, context);
          [newValue retain];
          [currentValue release];
          currentValue = newValue;
        }//end if (...)
      }//end if (idx>0)
      if (context.errorContext.hasError)
        *stop = YES;
      @synchronized(self) {
        computeFlags |=
          operand.evaluationComputeFlags |
          chalkGmpFlagsMake();
      }//end @synchronized(self)
    }];//end for each operand
    
    currentValue.evaluationComputeFlags |= computeFlags | chalkGmpFlagsMake();
    result = [CHChalkValue finalizeValue:&currentValue context:context];
    [result autorelease];
  }//end if (operands.count >= 2)
  return result;
}
//end combine2_2:operands:operatorToken:context:

+(CHChalkValue*) combineAdd:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count < 2)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count >= 2)
  {
    if (operands.count == 2)
    {
      CHChalkValue* operand1Value = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueList* operand1List = [operand1Value dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValue* operand2Value = [[operands objectAtIndex:1] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueList* operand2List = [operand2Value dynamicCastToClass:[CHChalkValueList class]];
      if (!operand1Value || !operand2Value)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                               replace:NO];
      else if (operand2List)
        result = [[self combineSEL:_cmd  arguments:operands list:operand2List index:1 operatorToken:token context:context] retain];
      else if (operand1List)
        result = [[self combineSEL:_cmd  arguments:operands list:operand1List index:0 operatorToken:token context:context] retain];
    }//end if (operands.count == 2)
    if (!result && !context.errorContext.hasError)
    {
      __block CHChalkValue* currentValue = nil;
      __block chalk_gmp_value_t nextValueGmp = {0};
      __block chalk_compute_flags_t computeFlags = 0;
      [operands enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CHChalkValue* operand = [obj dynamicCastToClass:[CHChalkValue class]];
        if (!operand)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                 replace:NO];
        else if (!idx)
        {
          [currentValue release];
          currentValue = [operand copy];
          //[currentValue.token unionWithToken:token];//experimental
        }//end if (!idx)
        else//if (idx>0)
        {
          //[currentValue.token unionWithToken:operand.token];//experimental
          CHChalkValueNumberGmp* operandGmp = [operand dynamicCastToClass:[CHChalkValueNumberGmp class]];
          CHChalkValueFormal* operandFormal = [operand dynamicCastToClass:[CHChalkValueFormal class]];
          operandGmp = !operandFormal ? operandGmp : operandFormal.value;
          CHChalkValueQuaternion* operandQuaternion = [operand dynamicCastToClass:[CHChalkValueQuaternion class]];
          CHChalkValueMatrix* operandMatrix = [operand dynamicCastToClass:[CHChalkValueMatrix class]];
          CHChalkValueNumberGmp* currentValueGmp = [currentValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
          CHChalkValueQuaternion* currentValueQuaternion = [currentValue dynamicCastToClass:[CHChalkValueQuaternion class]];
          CHChalkValueMatrix* currentValueMatrix = [currentValue dynamicCastToClass:[CHChalkValueMatrix class]];
          if (currentValueGmp && operandQuaternion)
          {
            [currentValue autorelease];
            currentValue = [[CHChalkValueQuaternion alloc] initWithToken:token
              partReal:currentValueGmp partRealWrapped:YES
              partI:[CHChalkValueNumberGmp zeroWithToken:token context:context] partIWrapped:YES
              partJ:[CHChalkValueNumberGmp zeroWithToken:token context:context] partJWrapped:YES
              partK:[CHChalkValueNumberGmp zeroWithToken:token context:context] partKWrapped:YES
              context:context];
            currentValueGmp = [currentValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
            currentValueQuaternion = [currentValue dynamicCastToClass:[CHChalkValueQuaternion class]];
          }//end if (currentValueGmp && operandQuaternion)
          
          if (operandGmp && operandGmp.isZero){
          }
          else if (currentValueMatrix && operandMatrix)
          {
            if ((operandMatrix.rowsCount != currentValueMatrix.rowsCount) || (operandMatrix.colsCount != currentValueMatrix.colsCount))
              [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorDimensionsMismatch range:token.range]
                                     replace:NO];
            else//if (dimensions ok)
            {
              NSUInteger colsCount = currentValueMatrix.colsCount;
              [currentValueMatrix.values enumerateObjectsWithOptions:
                (context.concurrentEvaluations ? NSEnumerationConcurrent : 0)
                usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSUInteger row = !colsCount ? 0 : idx/colsCount;
                NSUInteger col = !colsCount ? 0 : idx%colsCount;
                CHChalkValue* op1 = [obj dynamicCastToClass:[CHChalkValue class]];
                CHChalkValue* op2 = [operandMatrix valueAtRow:row col:col];
                CHChalkValue* sum = !op1 || !op2 ? nil :
                  [self combineAdd:@[op1, op2] operatorToken:token context:context];
                if (sum)
                  [currentValueMatrix setValue:sum atRow:row col:col];
                else//if (!sum)
                {
                  *stop = YES;
                  [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                         replace:NO];
                }//end if (!sum)
              }];
            }//end if (dimensions ok)
          }//end if (currentValueMatrix && operandMatrix)
          else if (currentValueQuaternion && operandGmp)
          {
            CHChalkValue* newPartReal = [self combineAdd:@[currentValueQuaternion.partReal,operandGmp] operatorToken:token context:context];
            CHChalkValueNumber* newPartRealValueNumber = [newPartReal dynamicCastToClass:[CHChalkValueNumber class]];
            if (newPartRealValueNumber)
              [currentValueQuaternion setPartReal:newPartRealValueNumber wrapped:YES];
            else
              [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                     replace:NO];
          }//end if (currentValueQuaternion && operandGmp)
          else if (currentValueQuaternion && operandQuaternion)
          {
            CHChalkValue* newPartReal = [self combineAdd:@[currentValueQuaternion.partReal,operandQuaternion.partReal] operatorToken:token context:context];
            CHChalkValueNumber* newPartRealValueNumber = [newPartReal dynamicCastToClass:[CHChalkValueNumber class]];
            CHChalkValue* newPartI = [self combineAdd:@[currentValueQuaternion.partI,operandQuaternion.partI] operatorToken:token context:context];
            CHChalkValueNumber* newPartIValueNumber = [newPartI dynamicCastToClass:[CHChalkValueNumber class]];
            CHChalkValue* newPartJ = [self combineAdd:@[currentValueQuaternion.partJ,operandQuaternion.partJ] operatorToken:token context:context];
            CHChalkValueNumber* newPartJValueNumber = [newPartJ dynamicCastToClass:[CHChalkValueNumber class]];
            CHChalkValue* newPartK = [self combineAdd:@[currentValueQuaternion.partK,operandQuaternion.partK] operatorToken:token context:context];
            CHChalkValueNumber* newPartKValueNumber = [newPartK dynamicCastToClass:[CHChalkValueNumber class]];
            if (newPartRealValueNumber && newPartIValueNumber && newPartJValueNumber && newPartKValueNumber)
            {
              [currentValueQuaternion setPartReal:newPartRealValueNumber wrapped:YES];
              [currentValueQuaternion setPartI:newPartIValueNumber wrapped:YES];
              [currentValueQuaternion setPartJ:newPartJValueNumber wrapped:YES];
              [currentValueQuaternion setPartK:newPartKValueNumber wrapped:YES];
            }//end if (newPartRealValueNumber && newPartIValueNumber && newPartJValueNumber && newPartKValueNumber)
            else//(!newPartRealValueNumber || !newPartIValueNumber || !newPartJValueNumber || !newPartKValueNumber)
              [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                     replace:NO];
          }//end if (currentValueQuaternion && operandQuaternion)
          else if (!currentValueGmp || !operandGmp)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorOperationNonImplemented range:token.range]
                                   replace:NO];
          else if (currentValueGmp && currentValueGmp.valueConstReference && currentValueGmp.valueConstReference && operandGmp && operandGmp.valueConstReference)
          {
            mpfr_clear_flags();
            mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
            chalk_gmp_value_t* currentValueGmpValue = currentValueGmp.valueReference;
            const chalk_gmp_value_t* operandGmpValue = operandGmp.valueConstReference;
            BOOL done = NO;
            if (!done && currentValueGmp.isZero)
            {
              chalkGmpValueSet(currentValueGmpValue, operandGmpValue, context.gmpPool);
              done = YES;
            }//end if (!done && currentValueGmp.isZero)
            if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_INTEGER) && (operandGmpValue->type == CHALK_VALUE_TYPE_INTEGER))
            {
              mpzDepool(nextValueGmp.integer, context.gmpPool);
              mpz_set_ui(nextValueGmp.integer, 0);
              nextValueGmp.type = CHALK_VALUE_TYPE_INTEGER;
              done = [self addIntegers:nextValueGmp.integer op1:currentValueGmpValue->integer op2:operandGmpValue->integer operatorToken:token context:context];
              if (done)
                mpz_swap(currentValueGmpValue->integer, nextValueGmp.integer);
              else if ((context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_INTERVALS) || (context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_BEST))
                chalkGmpValueMakeReal(currentValueGmpValue, prec, context.gmpPool);
              else
                [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorIntegerOverflow range:token.range]
                                   replace:NO];
              chalkGmpValueClear(&nextValueGmp, YES, context.gmpPool);
            }//end if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_INTEGER) && (operandGmpValue->type == CHALK_VALUE_TYPE_INTEGER))
            if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_INTEGER) && (operandGmpValue->type == CHALK_VALUE_TYPE_FRACTION))
            {
              mpqDepool(nextValueGmp.fraction, context.gmpPool);
              mpq_set_z(nextValueGmp.fraction, currentValueGmpValue->integer);
              nextValueGmp.type = CHALK_VALUE_TYPE_FRACTION;
              mpq_add(nextValueGmp.fraction, nextValueGmp.fraction, operandGmpValue->fraction);
              done = [CHChalkValueNumberGmp checkFraction:nextValueGmp.fraction token:token setError:YES context:context];
              if (done)
                chalkGmpValueMove(currentValueGmpValue, &nextValueGmp, context.gmpPool);
              else if ((context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_INTERVALS) ||
                      (context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_BEST))
                chalkGmpValueMakeReal(currentValueGmpValue, prec, context.gmpPool);
              else
                [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorIntegerOverflow range:token.range]
                                   replace:NO];
              chalkGmpValueClear(&nextValueGmp, YES, context.gmpPool);
            }//end if ((currentValueGmpValue->type == CHALK_VALUE_TYPE_INTEGER) && (operandGmpValue->type == CHALK_VALUE_TYPE_FRACTION))
            if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_INTEGER) && (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT))
            {
              chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
              mpfrDepool(nextValueGmp.realExact, prec, context.gmpPool);
              mpfr_set_z(nextValueGmp.realExact, currentValueGmpValue->integer, MPFR_RNDN);
              nextValueGmp.type = CHALK_VALUE_TYPE_REAL_EXACT;
              mpfr_add(nextValueGmp.realExact, nextValueGmp.realExact, operandGmpValue->realExact, MPFR_RNDN);
              done = !mpfr_inexflag_p();
              chalkGmpFlagsRestore(oldFlags);
              if (done)
                chalkGmpValueMove(currentValueGmpValue, &nextValueGmp, context.gmpPool);
              else if ((context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_INTERVALS) ||
                       (context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_BEST))
                chalkGmpValueMakeRealApprox(currentValueGmpValue, prec, context.gmpPool);
              else
                [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorIntegerOverflow range:token.range]
                                   replace:NO];
              chalkGmpValueClear(&nextValueGmp, YES, context.gmpPool);
            }//end if ((currentValueGmpValue->type == CHALK_VALUE_TYPE_INTEGER) && (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT))
            if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_FRACTION) && (operandGmpValue->type == CHALK_VALUE_TYPE_INTEGER))
            {
              mpqDepool(nextValueGmp.fraction, context.gmpPool);
              mpq_set_z(nextValueGmp.fraction, operandGmpValue->integer);
              nextValueGmp.type = CHALK_VALUE_TYPE_FRACTION;
              mpq_add(nextValueGmp.fraction, currentValueGmpValue->fraction, nextValueGmp.fraction);
              done = [CHChalkValueNumberGmp checkFraction:nextValueGmp.fraction token:token setError:YES context:context];
              if (done)
              {
                chalkGmpValueSimplify(&nextValueGmp, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
                chalkGmpValueMove(currentValueGmpValue, &nextValueGmp, context.gmpPool);
              }//end if (done)
              else if ((context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_INTERVALS) ||
                       (context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_BEST))
                chalkGmpValueMakeReal(currentValueGmpValue, prec, context.gmpPool);
              else
                [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorIntegerOverflow range:token.range]
                                   replace:NO];
              chalkGmpValueClear(&nextValueGmp, YES, context.gmpPool);
            }//end if ((currentValueGmpValue->type == CHALK_VALUE_TYPE_FRACTION) && (operandGmpValue->type == CHALK_VALUE_TYPE_INTEGER))
            if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_FRACTION) && (operandGmpValue->type == CHALK_VALUE_TYPE_FRACTION))
            {
              mpqDepool(nextValueGmp.fraction, context.gmpPool);
              mpq_set(nextValueGmp.fraction, currentValueGmpValue->fraction);
              nextValueGmp.type = CHALK_VALUE_TYPE_FRACTION;
              mpq_add(nextValueGmp.fraction, currentValueGmpValue->fraction, operandGmpValue->fraction);
              done = [CHChalkValueNumberGmp checkFraction:nextValueGmp.fraction token:token setError:YES context:context];
              if (done)
              {
                chalkGmpValueSimplify(&nextValueGmp, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
                chalkGmpValueMove(currentValueGmpValue, &nextValueGmp, context.gmpPool);
              }//end if (done)
              else if ((context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_INTERVALS) ||
                       (context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_BEST))
                chalkGmpValueMakeReal(currentValueGmpValue, prec, context.gmpPool);
              else
                [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorIntegerOverflow range:token.range]
                                   replace:NO];
              chalkGmpValueClear(&nextValueGmp, YES, context.gmpPool);
            }//end if ((currentValueGmpValue->type == CHALK_VALUE_TYPE_FRACTION) && (operandGmpValue->type == CHALK_VALUE_TYPE_FRACTION))
            if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_FRACTION) && (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT))
            {
              chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
              mpfrDepool(nextValueGmp.realExact, prec, context.gmpPool);
              mpfr_set_q(nextValueGmp.realExact, currentValueGmpValue->fraction, MPFR_RNDN);
              nextValueGmp.type = CHALK_VALUE_TYPE_REAL_EXACT;
              mpfr_add(nextValueGmp.realExact, nextValueGmp.realExact, operandGmpValue->realExact, MPFR_RNDN);
              done = !mpfr_inexflag_p();
              chalkGmpFlagsRestore(oldFlags);
              if (done)
                chalkGmpValueMove(currentValueGmpValue, &nextValueGmp, context.gmpPool);
              else
                chalkGmpValueMakeRealApprox(currentValueGmpValue, prec, context.gmpPool);
              chalkGmpValueClear(&nextValueGmp, YES, context.gmpPool);
            }//end if ((currentValueGmpValue->type == CHALK_VALUE_TYPE_FRACTION) && (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT))
            if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT) && (operandGmpValue->type == CHALK_VALUE_TYPE_INTEGER))
            {
              chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
              mpfrDepool(nextValueGmp.realExact, prec, context.gmpPool);
              mpfr_set_z(nextValueGmp.realExact, operandGmpValue->integer, MPFR_RNDN);
              nextValueGmp.type = CHALK_VALUE_TYPE_REAL_EXACT;
              mpfr_add(nextValueGmp.realExact, currentValueGmpValue->realExact, nextValueGmp.realExact, MPFR_RNDN);
              done = !mpfr_inexflag_p();
              chalkGmpFlagsRestore(oldFlags);
              if (done)
                chalkGmpValueMove(currentValueGmpValue, &nextValueGmp, context.gmpPool);
              else
                chalkGmpValueMakeRealApprox(currentValueGmpValue, prec, context.gmpPool);
              chalkGmpValueClear(&nextValueGmp, YES, context.gmpPool);
            }//end if ((currentValueGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT) && (operandGmpValue->type == CHALK_VALUE_TYPE_INTEGER))
            if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT) && (operandGmpValue->type == CHALK_VALUE_TYPE_FRACTION))
            {
              chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
              mpfrDepool(nextValueGmp.realExact, prec, context.gmpPool);
              mpfr_set_q(nextValueGmp.realExact, operandGmpValue->fraction, MPFR_RNDN);
              nextValueGmp.type = CHALK_VALUE_TYPE_REAL_EXACT;
              mpfr_add(nextValueGmp.realExact, currentValueGmpValue->realExact, nextValueGmp.realExact, MPFR_RNDN);
              done = !mpfr_inexflag_p();
              chalkGmpFlagsRestore(oldFlags);
              if (done)
                chalkGmpValueMove(currentValueGmpValue, &nextValueGmp, context.gmpPool);
              else
                chalkGmpValueMakeRealApprox(currentValueGmpValue, prec, context.gmpPool);
              chalkGmpValueClear(&nextValueGmp, YES, context.gmpPool);
            }//end if ((currentValueGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT) && (operandGmpValue->type == CHALK_VALUE_TYPE_FRACTION))
            if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT) && (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT))
            {
              chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
              mpfrDepool(nextValueGmp.realExact, prec, context.gmpPool);
              mpfr_set(nextValueGmp.realExact, currentValueGmpValue->realExact, MPFR_RNDN);
              nextValueGmp.type = CHALK_VALUE_TYPE_REAL_EXACT;
              mpfr_add(nextValueGmp.realExact, currentValueGmpValue->realExact, operandGmpValue->realExact, MPFR_RNDN);
              done = !mpfr_inexflag_p();
              chalkGmpFlagsRestore(oldFlags);
              if (done)
                chalkGmpValueMove(currentValueGmpValue, &nextValueGmp, context.gmpPool);
              else
                chalkGmpValueMakeRealApprox(currentValueGmpValue, prec, context.gmpPool);
              chalkGmpValueClear(&nextValueGmp, YES, context.gmpPool);
            }//end if ((currentValueGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT) && (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT))
            if (!done && (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX))
              chalkGmpValueMakeRealApprox(currentValueGmpValue, prec, context.gmpPool);
            if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX))
            {
              if (operandGmpValue->type == CHALK_VALUE_TYPE_INTEGER)
              {
                mpfir_add_z(currentValueGmpValue->realApprox, currentValueGmpValue->realApprox, operandGmpValue->integer);
                done = YES;
              }//end if (operandGmpValue->type == CHALK_VALUE_TYPE_INTEGER)
              else if (operandGmpValue->type == CHALK_VALUE_TYPE_FRACTION)
              {
                mpfir_add_q(currentValueGmpValue->realApprox, currentValueGmpValue->realApprox, operandGmpValue->fraction);
                done = YES;
              }//end if (operandGmpValue->type == CHALK_VALUE_TYPE_FRACTION)
              else if (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT)
              {
                mpfir_add_fr(currentValueGmpValue->realApprox, currentValueGmpValue->realApprox, operandGmpValue->realExact);
                done = YES;
              }//end if (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT)
              else if (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX)
              {
                mpfir_add(currentValueGmpValue->realApprox, currentValueGmpValue->realApprox, operandGmpValue->realApprox);
                done = YES;
              }//end if (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX)
            }//end if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX))
            if (done)
              currentValueGmp.evaluationComputeFlags = computeFlags | chalkGmpFlagsMake();
            else//if (!done)
              [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorOperationNonImplemented range:token.range]
                                     replace:NO];
            if (context.errorContext.hasError)
              *stop = YES;
          }//end if (currentValueGmp && currentValueGmp.valueConstReference && currentValueGmp.valueConstReference && operandGmp && operandGmp.valueConstReference)
          else
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorOperationNonImplemented range:token.range]
                                   replace:NO];
        }//end if (idx>0)
        if (context.errorContext.hasError)
          *stop = YES;
        @synchronized(self) {
          computeFlags |=
            operand.evaluationComputeFlags |
            chalkGmpFlagsMake();
        }//end @synchronized(self)
      }];//end for each operand
      
      chalkGmpValueClear(&nextValueGmp, YES, context.gmpPool);
      currentValue.evaluationComputeFlags |= computeFlags | chalkGmpFlagsMake();
      result = [CHChalkValue finalizeValue:&currentValue context:context];
      [result autorelease];
    }//end if (!result && !context.errorContext.hasError)
  }//end if (operands.count >= 2)
  return result;
}
//end combineAdd:operatorToken:context:

+(CHChalkValue*) combineAdd2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = [self combine2_2:@selector(combineAdd:operatorToken:context:) operands:operands operatorToken:token context:context];
  return result;
}
//end combineAdd2:operatorToken:context:

+(CHChalkValue*) combineSub:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count < 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else if (operands.count == 1)
  {
    CHChalkValue* operand1Value = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
    CHChalkValueList* operand1List = [operand1Value dynamicCastToClass:[CHChalkValueList class]];
    if (!operand1Value)
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                             replace:NO];
    else if (operand1List)
      result = [[self combineSEL:_cmd  arguments:operands list:operand1List index:0 operatorToken:token context:context] retain];
    if (!result && !context.errorContext.hasError)
    {
      result = [operand1Value copy];
      //[result.token unionWithToken:token];//experimental
      BOOL ok = result && [result negate];
      if (ok)
        [result autorelease];
      else//if (!ok)
      {
        [result release];
        result = nil;
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                               replace:NO];
      }//end if (!ok)
    }//end if (!result && !context.errorContext.hasError)
  }//end if (operands.count == 1)
  else//if (operands.count >= 2)
  {
    if (operands.count == 2)
    {
      CHChalkValue* operand1Value = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueList* operand1List = [operand1Value dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValue* operand2Value = [[operands objectAtIndex:1] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueList* operand2List = [operand2Value dynamicCastToClass:[CHChalkValueList class]];
      if (!operand1Value || !operand2Value)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                               replace:NO];
      else if (operand2List)
        result = [[self combineSEL:_cmd  arguments:operands list:operand2List index:1 operatorToken:token context:context] retain];
      else if (operand1List)
        result = [[self combineSEL:_cmd  arguments:operands list:operand1List index:0 operatorToken:token context:context] retain];
    }//end if (operands.count == 2)
    if (!result && !context.errorContext.hasError)
    {
      __block CHChalkValue* currentValue = nil;
      __block chalk_gmp_value_t nextValueGmp = {0};
      __block chalk_compute_flags_t computeFlags = 0;
      [operands enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CHChalkValue* operand = [obj dynamicCastToClass:[CHChalkValue class]];
        if (!operand)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                 replace:NO];
        else if (!idx)
        {
          [currentValue release];
          currentValue = [operand copy];
          //[currentValue.token unionWithToken:token];//experimental
        }//end if (!idx)
        else//if (idx>0)
        {
          //[currentValue.token unionWithToken:operand.token];//experimental
          CHChalkValueNumberGmp* operandGmp = [operand dynamicCastToClass:[CHChalkValueNumberGmp class]];
          CHChalkValueFormal* operandFormal = [operand dynamicCastToClass:[CHChalkValueFormal class]];
          operandGmp = !operandFormal ? operandGmp : operandFormal.value;
          CHChalkValueQuaternion* operandQuaternion = [operand dynamicCastToClass:[CHChalkValueQuaternion class]];
          CHChalkValueMatrix* operandMatrix = [operand dynamicCastToClass:[CHChalkValueMatrix class]];
          CHChalkValueNumberGmp* currentValueGmp = [currentValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
          CHChalkValueQuaternion* currentValueQuaternion = [currentValue dynamicCastToClass:[CHChalkValueQuaternion class]];
          CHChalkValueMatrix* currentValueMatrix = [currentValue dynamicCastToClass:[CHChalkValueMatrix class]];
          if (currentValueGmp && operandQuaternion)
          {
            [currentValue autorelease];
            currentValue = [[CHChalkValueQuaternion alloc] initWithToken:token
              partReal:currentValueGmp partRealWrapped:YES
              partI:[CHChalkValueNumberGmp zeroWithToken:token context:context] partIWrapped:YES
              partJ:[CHChalkValueNumberGmp zeroWithToken:token context:context] partJWrapped:YES
              partK:[CHChalkValueNumberGmp zeroWithToken:token context:context] partKWrapped:YES
              context:context];
            currentValueGmp = [currentValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
            currentValueQuaternion = [currentValue dynamicCastToClass:[CHChalkValueQuaternion class]];
          }//end if (currentValueGmp && operandQuaternion)
          
          if (operandGmp && operandGmp.isZero){
          }
          else if (currentValueMatrix && operandMatrix)
          {
            if ((operandMatrix.rowsCount != currentValueMatrix.rowsCount) || (operandMatrix.colsCount != currentValueMatrix.colsCount))
              [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorDimensionsMismatch range:token.range]
                                     replace:NO];
            else//if (dimensions ok)
            {
              NSUInteger colsCount = currentValueMatrix.colsCount;
              [currentValueMatrix.values enumerateObjectsWithOptions:
                (context.concurrentEvaluations ? NSEnumerationConcurrent : 0)
                usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSUInteger row = !colsCount ? 0 : idx/colsCount;
                NSUInteger col = !colsCount ? 0 : idx%colsCount;
                CHChalkValue* op1 = [obj dynamicCastToClass:[CHChalkValue class]];
                CHChalkValue* op2 = [operandMatrix valueAtRow:row col:col];
                CHChalkValue* sum = !op1 || !op2 ? nil :
                  [self combineSub:@[op1, op2] operatorToken:token context:context];
                if (sum)
                  [currentValueMatrix setValue:sum atRow:row col:col];
                else//if (!sum)
                {
                  *stop = YES;
                  [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                         replace:NO];
                }//end if (!sum)
              }];
            }//end if (dimensions ok)
          }//end if (currentValueMatrix && operandMatrix)
          else if (currentValueQuaternion && operandGmp)
          {
            CHChalkValue* newPartReal = [self combineSub:@[currentValueQuaternion.partReal,operandGmp] operatorToken:token context:context];
            CHChalkValueNumber* newPartRealValueNumber = [newPartReal dynamicCastToClass:[CHChalkValueNumber class]];
            if (newPartRealValueNumber)
              [currentValueQuaternion setPartReal:newPartRealValueNumber wrapped:YES];
            else//if (!newPartRealValueNumber)
              [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                     replace:NO];
          }//end if (currentValueQuaternion && operandGmp)
          else if (currentValueQuaternion && operandQuaternion)
          {
            CHChalkValue* newPartReal = [self combineSub:@[currentValueQuaternion.partReal,operandQuaternion.partReal] operatorToken:token context:context];
            CHChalkValueNumber* newPartRealValueNumber = [newPartReal dynamicCastToClass:[CHChalkValueNumber class]];
            CHChalkValue* newPartI = [self combineSub:@[currentValueQuaternion.partI,operandQuaternion.partI] operatorToken:token context:context];
            CHChalkValueNumber* newPartIValueNumber = [newPartI dynamicCastToClass:[CHChalkValueNumber class]];
            CHChalkValue* newPartJ = [self combineSub:@[currentValueQuaternion.partJ,operandQuaternion.partJ] operatorToken:token context:context];
            CHChalkValueNumber* newPartJValueNumber = [newPartJ dynamicCastToClass:[CHChalkValueNumber class]];
            CHChalkValue* newPartK = [self combineSub:@[currentValueQuaternion.partK,operandQuaternion.partK] operatorToken:token context:context];
            CHChalkValueNumber* newPartKValueNumber = [newPartK dynamicCastToClass:[CHChalkValueNumber class]];
            if (newPartReal && newPartI && newPartJ && newPartK)
            {
              [currentValueQuaternion setPartReal:newPartRealValueNumber wrapped:YES];
              [currentValueQuaternion setPartI:newPartIValueNumber wrapped:YES];
              [currentValueQuaternion setPartJ:newPartJValueNumber wrapped:YES];
              [currentValueQuaternion setPartK:newPartKValueNumber wrapped:YES];
            }//end if (newPartReal && newPartI && newPartJ && newPartK)
            else//if (!newPartReal || !newPartI || !newPartJ || !newPartKà
              [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                     replace:NO];
          }//end if (currentValueQuaternion && operandQuaternion)
          else if (!currentValueGmp || !operandGmp)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorOperationNonImplemented range:token.range]
                                   replace:NO];
          else if (currentValueGmp && currentValueGmp.valueConstReference && operandGmp && operandGmp.valueConstReference)
          {
            mpfr_clear_flags();
            mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
            chalk_gmp_value_t* currentValueGmpValue = currentValueGmp.valueReference;
            const chalk_gmp_value_t* operandGmpValue = operandGmp.valueConstReference;
            BOOL done = NO;
            if (!done && currentValueGmp.isZero)
            {
              chalkGmpValueSet(currentValueGmpValue, operandGmpValue, context.gmpPool);
              chalkGmpValueNeg(currentValueGmpValue);
              done = YES;
            }//end if (!done && currentValueGmp.isZero)
            if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_INTEGER) && (operandGmpValue->type == CHALK_VALUE_TYPE_INTEGER))
            {
              mpzDepool(nextValueGmp.integer, context.gmpPool);
              mpz_set_ui(nextValueGmp.integer, 0);
              nextValueGmp.type = CHALK_VALUE_TYPE_INTEGER;
              done = [self subIntegers:nextValueGmp.integer op1:currentValueGmpValue->integer op2:operandGmpValue->integer operatorToken:token context:context];
              if (done)
                mpz_swap(currentValueGmpValue->integer, nextValueGmp.integer);
              else if ((context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_INTERVALS) ||
                       (context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_BEST))
                chalkGmpValueMakeReal(currentValueGmpValue, prec, context.gmpPool);
              else
                [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorIntegerOverflow range:token.range]
                                   replace:NO];
              chalkGmpValueClear(&nextValueGmp, YES, context.gmpPool);
            }//end if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_INTEGER) && (operandGmpValue->type == CHALK_VALUE_TYPE_INTEGER))
            if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_INTEGER) && (operandGmpValue->type == CHALK_VALUE_TYPE_FRACTION))
            {
              mpqDepool(nextValueGmp.fraction, context.gmpPool);
              mpq_set_z(nextValueGmp.fraction, currentValueGmpValue->integer);
              nextValueGmp.type = CHALK_VALUE_TYPE_FRACTION;
              mpq_sub(nextValueGmp.fraction, nextValueGmp.fraction, operandGmpValue->fraction);
              done = [CHChalkValueNumberGmp checkFraction:nextValueGmp.fraction token:token setError:YES context:context];
              if (done)
                chalkGmpValueMove(currentValueGmpValue, &nextValueGmp, context.gmpPool);
              else if ((context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_INTERVALS) ||
                       (context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_BEST))
                chalkGmpValueMakeReal(currentValueGmpValue, prec, context.gmpPool);
              else
                [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorIntegerOverflow range:token.range]
                                   replace:NO];
              chalkGmpValueClear(&nextValueGmp, YES, context.gmpPool);
            }//end if ((currentValueGmpValue->type == CHALK_VALUE_TYPE_INTEGER) && (operandGmpValue->type == CHALK_VALUE_TYPE_FRACTION))
            if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_INTEGER) && (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT))
            {
              chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
              mpfrDepool(nextValueGmp.realExact, prec, context.gmpPool);
              mpfr_set_z(nextValueGmp.realExact, currentValueGmpValue->integer, MPFR_RNDN);
              nextValueGmp.type = CHALK_VALUE_TYPE_REAL_EXACT;
              mpfr_sub(nextValueGmp.realExact, nextValueGmp.realExact, operandGmpValue->realExact, MPFR_RNDN);
              done = !mpfr_inexflag_p();
              chalkGmpFlagsRestore(oldFlags);
              if (done)
                chalkGmpValueMove(currentValueGmpValue, &nextValueGmp, context.gmpPool);
              else if ((context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_INTERVALS) ||
                       (context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_BEST))
                chalkGmpValueMakeRealApprox(currentValueGmpValue, prec, context.gmpPool);
              else
                [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorIntegerOverflow range:token.range]
                                   replace:NO];
              chalkGmpValueClear(&nextValueGmp, YES, context.gmpPool);
            }//end if ((currentValueGmpValue->type == CHALK_VALUE_TYPE_INTEGER) && (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT))
            if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_FRACTION) && (operandGmpValue->type == CHALK_VALUE_TYPE_INTEGER))
            {
              mpqDepool(nextValueGmp.fraction, context.gmpPool);
              mpq_set_z(nextValueGmp.fraction, operandGmpValue->integer);
              nextValueGmp.type = CHALK_VALUE_TYPE_FRACTION;
              mpq_sub(nextValueGmp.fraction, currentValueGmpValue->fraction, nextValueGmp.fraction);
              done = [CHChalkValueNumberGmp checkFraction:nextValueGmp.fraction token:token setError:YES context:context];
              if (done)
              {
                chalkGmpValueSimplify(&nextValueGmp, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
                chalkGmpValueMove(currentValueGmpValue, &nextValueGmp, context.gmpPool);
              }//end if (done)
              else if ((context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_INTERVALS) ||
                       (context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_BEST))
                chalkGmpValueMakeReal(currentValueGmpValue, prec, context.gmpPool);
              else
                [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorIntegerOverflow range:token.range]
                                   replace:NO];
              chalkGmpValueClear(&nextValueGmp, YES, context.gmpPool);
            }//end if ((currentValueGmpValue->type == CHALK_VALUE_TYPE_FRACTION) && (operandGmpValue->type == CHALK_VALUE_TYPE_INTEGER))
            if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_FRACTION) && (operandGmpValue->type == CHALK_VALUE_TYPE_FRACTION))
            {
              mpqDepool(nextValueGmp.fraction, context.gmpPool);
              mpq_set(nextValueGmp.fraction, currentValueGmpValue->fraction);
              nextValueGmp.type = CHALK_VALUE_TYPE_FRACTION;
              mpq_sub(nextValueGmp.fraction, currentValueGmpValue->fraction, operandGmpValue->fraction);
              done = [CHChalkValueNumberGmp checkFraction:nextValueGmp.fraction token:token setError:YES context:context];
              if (done)
              {
                chalkGmpValueSimplify(&nextValueGmp, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
                chalkGmpValueMove(currentValueGmpValue, &nextValueGmp, context.gmpPool);
              }//end if (done)
              else if ((context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_INTERVALS) ||
                       (context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_BEST))
                chalkGmpValueMakeReal(currentValueGmpValue, prec, context.gmpPool);
              else
                [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorIntegerOverflow range:token.range]
                                   replace:NO];
              chalkGmpValueClear(&nextValueGmp, YES, context.gmpPool);
            }//end if ((currentValueGmpValue->type == CHALK_VALUE_TYPE_FRACTION) && (operandGmpValue->type == CHALK_VALUE_TYPE_FRACTION))
            if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_FRACTION) && (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT))
            {
              chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
              mpfrDepool(nextValueGmp.realExact, prec, context.gmpPool);
              mpfr_set_q(nextValueGmp.realExact, currentValueGmpValue->fraction, MPFR_RNDN);
              nextValueGmp.type = CHALK_VALUE_TYPE_REAL_EXACT;
              mpfr_sub(nextValueGmp.realExact, nextValueGmp.realExact, operandGmpValue->realExact, MPFR_RNDN);
              done = !mpfr_inexflag_p();
              chalkGmpFlagsRestore(oldFlags);
              if (done)
                chalkGmpValueMove(currentValueGmpValue, &nextValueGmp, context.gmpPool);
              else
                chalkGmpValueMakeRealApprox(currentValueGmpValue, prec, context.gmpPool);
              chalkGmpValueClear(&nextValueGmp, YES, context.gmpPool);
            }//end if ((currentValueGmpValue->type == CHALK_VALUE_TYPE_FRACTION) && (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT))
            if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT) && (operandGmpValue->type == CHALK_VALUE_TYPE_INTEGER))
            {
              chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
              mpfrDepool(nextValueGmp.realExact, prec, context.gmpPool);
              mpfr_set_z(nextValueGmp.realExact, operandGmpValue->integer, MPFR_RNDN);
              nextValueGmp.type = CHALK_VALUE_TYPE_REAL_EXACT;
              mpfr_sub(nextValueGmp.realExact, currentValueGmpValue->realExact, nextValueGmp.realExact, MPFR_RNDN);
              done = !mpfr_inexflag_p();
              chalkGmpFlagsRestore(oldFlags);
              if (done)
                chalkGmpValueMove(currentValueGmpValue, &nextValueGmp, context.gmpPool);
              else
                chalkGmpValueMakeRealApprox(currentValueGmpValue, prec, context.gmpPool);
              chalkGmpValueClear(&nextValueGmp, YES, context.gmpPool);
            }//end if ((currentValueGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT) && (operandGmpValue->type == CHALK_VALUE_TYPE_INTEGER))
            if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT) && (operandGmpValue->type == CHALK_VALUE_TYPE_FRACTION))
            {
              chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
              mpfrDepool(nextValueGmp.realExact, prec, context.gmpPool);
              mpfr_set_q(nextValueGmp.realExact, operandGmpValue->fraction, MPFR_RNDN);
              nextValueGmp.type = CHALK_VALUE_TYPE_REAL_EXACT;
              mpfr_sub(nextValueGmp.realExact, currentValueGmpValue->realExact, nextValueGmp.realExact, MPFR_RNDN);
              done = !mpfr_inexflag_p();
              chalkGmpFlagsRestore(oldFlags);
              if (done)
                chalkGmpValueMove(currentValueGmpValue, &nextValueGmp, context.gmpPool);
              else
                chalkGmpValueMakeRealApprox(currentValueGmpValue, prec, context.gmpPool);
              chalkGmpValueClear(&nextValueGmp, YES, context.gmpPool);
            }//end if ((currentValueGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT) && (operandGmpValue->type == CHALK_VALUE_TYPE_FRACTION))
            if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT) && (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT))
            {
              chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
              mpfrDepool(nextValueGmp.realExact, prec, context.gmpPool);
              mpfr_set(nextValueGmp.realExact, currentValueGmpValue->realExact, MPFR_RNDN);
              nextValueGmp.type = CHALK_VALUE_TYPE_REAL_EXACT;
              mpfr_sub(nextValueGmp.realExact, currentValueGmpValue->realExact, operandGmpValue->realExact, MPFR_RNDN);
              done = !mpfr_inexflag_p();
              chalkGmpFlagsRestore(oldFlags);
              if (done)
                chalkGmpValueMove(currentValueGmpValue, &nextValueGmp, context.gmpPool);
              else
                chalkGmpValueMakeRealApprox(currentValueGmpValue, prec, context.gmpPool);
              chalkGmpValueClear(&nextValueGmp, YES, context.gmpPool);
            }//end if ((currentValueGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT) && (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT))
            if (!done && (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX))
              chalkGmpValueMakeRealApprox(currentValueGmpValue, prec, context.gmpPool);
            if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX))
            {
              if (operandGmpValue->type == CHALK_VALUE_TYPE_INTEGER)
              {
                mpfir_sub_z(currentValueGmpValue->realApprox, currentValueGmpValue->realApprox, operandGmpValue->integer);
                done = YES;
              }//end if (operandGmpValue->type == CHALK_VALUE_TYPE_INTEGER)
              else if (operandGmpValue->type == CHALK_VALUE_TYPE_FRACTION)
              {
                mpfir_sub_q(currentValueGmpValue->realApprox, currentValueGmpValue->realApprox, operandGmpValue->fraction);
                done = YES;
              }//end if (operandGmpValue->type == CHALK_VALUE_TYPE_FRACTION)
              else if (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT)
              {
                mpfir_sub_fr(currentValueGmpValue->realApprox, currentValueGmpValue->realApprox, operandGmpValue->realExact);
                done = YES;
              }//end if (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT)
              else if (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX)
              {
                mpfir_sub(currentValueGmpValue->realApprox, currentValueGmpValue->realApprox, operandGmpValue->realApprox);
                done = YES;
              }//end if (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX)
            }//end if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX))
            if (done)
              currentValueGmp.evaluationComputeFlags = computeFlags | chalkGmpFlagsMake();
            else//if (!done)
              [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorOperationNonImplemented range:token.range]
                                     replace:NO];
            if (context.errorContext.hasError)
              *stop = YES;
          }//end if (currentValueGmp && currentValueGmp.valueConstReference && operandGmp && operandGmp.valueConstReference)
          else
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorOperationNonImplemented range:token.range]
                                   replace:NO];
        }//end if (idx>0)
        if (context.errorContext.hasError)
          *stop = YES;
        @synchronized(self) {
          computeFlags |=
            operand.evaluationComputeFlags |
            chalkGmpFlagsMake();
        }//end @synchronized(self)
      }];//end for each operand
      
      chalkGmpValueClear(&nextValueGmp, YES, context.gmpPool);
      currentValue.evaluationComputeFlags |= computeFlags | chalkGmpFlagsMake();
      result = [CHChalkValue finalizeValue:&currentValue context:context];
      [result autorelease];
    }//end if (!result && !context.errorContext.hasError)
  }//end if (operands.count >= 2)
  return result;
}
//end combineSub:operatorToken:context:

+(CHChalkValue*) combineSub2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = [self combine2_2:@selector(combineSub:operatorToken:context:) operands:operands operatorToken:token context:context];
  return result;
}
//end combineSub2:operatorToken:context:

+(CHChalkValue*) combineMul:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count < 2)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count >= 2)
  {
    if (operands.count == 2)
    {
      CHChalkValue* operand1Value = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueList* operand1List = [operand1Value dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValue* operand2Value = [[operands objectAtIndex:1] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueList* operand2List = [operand2Value dynamicCastToClass:[CHChalkValueList class]];
      if (!operand1Value || !operand2Value)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                               replace:NO];
      else if (operand2List)
        result = [[self combineSEL:_cmd  arguments:operands list:operand2List index:1 operatorToken:token context:context] retain];
      else if (operand1List)
        result = [[self combineSEL:_cmd  arguments:operands list:operand1List index:0 operatorToken:token context:context] retain];
    }//end if (operands.count == 2)
    if (!result && !context.errorContext.hasError)
    {
      __block CHChalkValue* currentValue = nil;
      __block chalk_gmp_value_t nextValueGmp = {0};
      __block chalk_compute_flags_t computeFlags = 0;
      [operands enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CHChalkValue* operand = [obj dynamicCastToClass:[CHChalkValue class]];
        if (!operand)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                 replace:NO];
        else if (!idx)
        {
          [currentValue release];
          currentValue = [operand copy];
          //[currentValue.token unionWithToken:token];//experimental
        }//end if (!idx)
        else//if (idx>0)
        {
          //[currentValue.token unionWithToken:operand.token];//experimental
          CHChalkValueScalar* operandScalar = [operand dynamicCastToClass:[CHChalkValueScalar class]];
          CHChalkValueNumberGmp* operandGmp = [operandScalar dynamicCastToClass:[CHChalkValueNumberGmp class]];
          CHChalkValueFormal* operandFormal = [operand dynamicCastToClass:[CHChalkValueFormal class]];
          operandGmp = !operandFormal ? operandGmp : operandFormal.value;
          CHChalkValueQuaternion* operandQuaternion = [operandScalar dynamicCastToClass:[CHChalkValueQuaternion class]];
          CHChalkValueMatrix* operandMatrix = [operand dynamicCastToClass:[CHChalkValueMatrix class]];
          CHChalkValueScalar* currentValueScalar = [currentValue dynamicCastToClass:[CHChalkValueScalar class]];
          CHChalkValueNumberGmp* currentValueGmp = [currentValueScalar dynamicCastToClass:[CHChalkValueNumberGmp class]];
          CHChalkValueQuaternion* currentValueQuaternion = [currentValueScalar dynamicCastToClass:[CHChalkValueQuaternion class]];
          CHChalkValueMatrix* currentValueMatrix = [currentValue dynamicCastToClass:[CHChalkValueMatrix class]];
          if (currentValueGmp && operandQuaternion)
          {
            [currentValue autorelease];
            currentValue = [[CHChalkValueQuaternion alloc] initWithToken:token
              partReal:currentValueGmp partRealWrapped:YES
              partI:[CHChalkValueNumberGmp zeroWithToken:token context:context] partIWrapped:YES
              partJ:[CHChalkValueNumberGmp zeroWithToken:token context:context] partJWrapped:YES
              partK:[CHChalkValueNumberGmp zeroWithToken:token context:context] partKWrapped:YES
              context:context];
            currentValueQuaternion = [currentValue dynamicCastToClass:[CHChalkValueQuaternion class]];
            currentValueGmp = nil;
            currentValueScalar = nil;
          }//end if (currentValueGmp && operandQuaternion)
          
          if (currentValueMatrix && operandMatrix)
          {
            if (currentValueMatrix.colsCount != operandMatrix.rowsCount)
              [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorDimensionsMismatch range:token.range]
                                     replace:NO];
            else//if (dimensions ok)
            {
              NSUInteger srcColCount = currentValueMatrix.colsCount;
              NSUInteger dstRowsCount = currentValueMatrix.rowsCount;
              NSUInteger dstColsCount = operandMatrix.colsCount;
              CHChalkValueMatrix* newMatrix = [[CHChalkValueMatrix alloc] initWithToken:token rowsCount:dstRowsCount colsCount:dstColsCount value:nil context:context];
              [newMatrix.values enumerateObjectsWithOptions:
                (context.concurrentEvaluations ? NSEnumerationConcurrent : 0)
                usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSUInteger row = !dstColsCount ? 0 :idx/dstColsCount;
                NSUInteger col = !dstColsCount ? 0 :idx%dstColsCount;
                CHChalkValue* dotProduct = nil;
                for(NSUInteger i = 0 ; !*stop && (i<srcColCount) ; ++i)
                {
                  @autoreleasepool{
                    CHChalkValue* op1 = [currentValueMatrix valueAtRow:row col:i];
                    CHChalkValue* op2 = [operandMatrix valueAtRow:i col:col];
                    CHChalkValue* product = !op1 || !op2 ? nil :
                      [self combineMul:@[op1, op2] operatorToken:token context:context];
                    if (product)
                    {
                      [dotProduct autorelease];
                      dotProduct = !dotProduct ? product : [self combineAdd:@[dotProduct, product] operatorToken:token context:context];
                      [dotProduct retain];
                    }//end if (product)
                    else//if (!product)
                    {
                      *stop = YES;
                      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                             replace:NO];
                    }//end if (!sum)
                  }//end @autoreleasepool
                }//end for each dotproduct part
                if (dotProduct)
                {
                  [newMatrix setValue:dotProduct atRow:row col:col];
                  [dotProduct release];
                }//end if (dotProduct)
                else//if (!dotProduct)
                {
                  *stop = YES;
                  [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                         replace:NO];
                }//end if (!dotProduct)
              }];
              [currentValue release];
              currentValue = newMatrix;
            }//end if (dimensions ok)
          }//end if (currentValueMatrix && operandMatrix)
          else if (currentValueScalar && operandMatrix)
          {
            BOOL isOneIgnoringSign = NO;
            if ([currentValueScalar isOne:&isOneIgnoringSign])
            {
              CHChalkValueMatrix* newMatrix = [operandMatrix copy];
              //[newMatrix.token unionWithToken:token];//experimental
              if (!newMatrix)
                [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                       replace:NO];
              else//if (newMatrix)
              {
                if (isOneIgnoringSign)
                  [newMatrix negate];
                [currentValue release];
                currentValue = newMatrix;
              }//end if (newMatrix)
            }//end if ([currentValueScalar isOne:&isOneIgnoringSign])
            else//if (![currentValueScalar isOne:&isOneIgnoringSign])
            {
              CHChalkValueMatrix* newMatrix = [[CHChalkValueMatrix alloc] initWithToken:token rowsCount:operandMatrix.rowsCount colsCount:operandMatrix.colsCount value:currentValueScalar context:context];
              if (!newMatrix)
                [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                       replace:NO];
              else if (currentValueScalar.isZero){
              }
              else//if (currentValueScalar != 0)
              {
                NSUInteger colsCount = newMatrix.colsCount;
                [newMatrix.values enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                  NSUInteger row = !colsCount ? 0 :idx/colsCount;
                  NSUInteger col = !colsCount ? 0 :idx%colsCount;
                  CHChalkValue* oldValue = [obj dynamicCastToClass:[CHChalkValue class]];
                  CHChalkValue* operandElementValue = [operandMatrix valueAtRow:row col:col];
                  CHChalkValue* newValue = !oldValue || !operandElementValue ? nil :
                    [self combineMul:@[oldValue,operandElementValue] operatorToken:token context:context];
                  if (newValue)
                    [newMatrix setValue:newValue atRow:row col:col];
                  else//if (!newValue)
                  {
                    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                           replace:NO];
                    *stop = YES;
                  }//end if (!newValue)
                }];
                if (context.errorContext.hasError)
                {
                  [newMatrix release];
                  newMatrix = nil;
                }//end if (context.errorContext.hasError)
              }//end if (!currentValueScalar.isZero)
              [currentValue release];
              currentValue = newMatrix;
            }//end if (!currentValueScalar.isZero)
          }//end if (![currentValueScalar isOne:&isOneIgnoringSign])
          else if (currentValueMatrix && operandScalar)
          {
            NSUInteger colsCount = currentValueMatrix.colsCount;
            BOOL isOneIgnoringSign = NO;
            if (operandScalar.isZero)
              [currentValueMatrix fill:operandScalar context:context];
            else if ([operandScalar isOne:&isOneIgnoringSign])
            {
              if (isOneIgnoringSign)
                [currentValueMatrix negate];
            }//end if ([operandScalar isOne:&isOneIgnoringSign])
            else//if (operandScalar != 0, 1, -1)
            {
              [currentValueMatrix.values enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSUInteger row = !colsCount ? 0 :idx/colsCount;
                NSUInteger col = !colsCount ? 0 :idx%colsCount;
                CHChalkValue* oldValue = [obj dynamicCastToClass:[CHChalkValue class]];
                CHChalkValue* newValue = !oldValue ? nil :
                  [self combineMul:@[oldValue,operandScalar] operatorToken:token context:context];
                if (newValue)
                  [currentValueMatrix setValue:newValue atRow:row col:col];
                else//if (!newValue)
                {
                  [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                         replace:NO];
                  *stop = YES;
                }//end if (!newValue)
              }];
            }//end if (operandScalar != 0, 1, -1)
            if (context.errorContext.hasError)
            {
              [currentValue release];
              currentValue = nil;
              currentValueMatrix = nil;
            }//end if (context.errorContext.hasError)
          }//end if (currentValueMatrix && operandScalar)
          else if (currentValueQuaternion && operandGmp)
          {
            BOOL isOneIgnoringSign = NO;
            if (operandGmp.isZero)
            {
              [currentValue release];
              currentValue = [[CHChalkValueNumberGmp zeroWithToken:token context:context] copy];
              //[currentValue.token unionWithToken:token];//experimental
            }//end if (operandGmp.isZero)
            else if ([operandGmp isOne:&isOneIgnoringSign])
            {
              if (isOneIgnoringSign)
                [currentValue negate];
            }//end if ([operandGmp isOne:&isOneIgnoringSign])
            else//if (operandGmp != 0, 1, -1)
            {
              CHChalkValue* newPartReal = [self combineMul:@[currentValueQuaternion.partReal,operandGmp] operatorToken:token context:context];
              CHChalkValue* newPartI = [self combineMul:@[currentValueQuaternion.partI,operandGmp] operatorToken:token context:context];
              CHChalkValue* newPartJ = [self combineMul:@[currentValueQuaternion.partJ,operandGmp] operatorToken:token context:context];
              CHChalkValue* newPartK = [self combineMul:@[currentValueQuaternion.partK,operandGmp] operatorToken:token context:context];
              CHChalkValueNumber* newPartRealValueNumber = [newPartReal dynamicCastToClass:[CHChalkValueNumber class]];
              CHChalkValueNumber* newPartIValueNumber = [newPartI dynamicCastToClass:[CHChalkValueNumber class]];
              CHChalkValueNumber* newPartJValueNumber = [newPartJ dynamicCastToClass:[CHChalkValueNumber class]];
              CHChalkValueNumber* newPartKValueNumber = [newPartK dynamicCastToClass:[CHChalkValueNumber class]];
              if (newPartRealValueNumber && newPartIValueNumber && newPartJValueNumber && newPartKValueNumber)
              {
                [currentValueQuaternion setPartReal:newPartRealValueNumber wrapped:YES];
                [currentValueQuaternion setPartI:newPartIValueNumber wrapped:YES];
                [currentValueQuaternion setPartJ:newPartJValueNumber wrapped:YES];
                [currentValueQuaternion setPartK:newPartKValueNumber wrapped:YES];
              }//end if (newPartRealValueNumber && newPartIValueNumber && newPartJValueNumber && newPartKValueNumber)
              else//if (!newPartRealValueNumber || !newPartIValueNumber || !newPartJValueNumber || !newPartKValueNumber)
                [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                       replace:NO];
            }//end if (operandGmp != 0, 1, -1)
          }//end if (currentValueQuaternion && operandGmp)
          else if (currentValueQuaternion && operandQuaternion)
          {
            CHChalkValue* partReal1 = [self combineMul:@[currentValueQuaternion.partReal,operandQuaternion.partReal] operatorToken:token context:context];
            CHChalkValue* partReal2 = [self combineMul:@[currentValueQuaternion.partI,operandQuaternion.partI] operatorToken:token context:context];
            CHChalkValue* partReal3 = [self combineMul:@[currentValueQuaternion.partJ,operandQuaternion.partJ] operatorToken:token context:context];
            CHChalkValue* partReal4 = [self combineMul:@[currentValueQuaternion.partK,operandQuaternion.partK] operatorToken:token context:context];
            CHChalkValue* newPartReal = !partReal1 || !partReal2 || !partReal3 || !partReal4 ? nil :
              [self combineSub:@[partReal1,partReal2,partReal3,partReal4] operatorToken:token context:context];
            CHChalkValue* partI1 = [self combineMul:@[currentValueQuaternion.partReal,operandQuaternion.partI] operatorToken:token context:context];
            CHChalkValue* partI2 = [self combineMul:@[currentValueQuaternion.partI,operandQuaternion.partReal] operatorToken:token context:context];
            CHChalkValue* partI3 = [self combineMul:@[currentValueQuaternion.partJ,operandQuaternion.partK] operatorToken:token context:context];
            CHChalkValue* partI4 = [self combineMul:@[currentValueQuaternion.partK,operandQuaternion.partJ] operatorToken:token context:context];
            CHChalkValue* partI123 = !partI1 || !partI2 || !partI3 ? nil :
              [self combineAdd:@[partI1, partI2, partI3] operatorToken:token context:context];
            CHChalkValue* newPartI = !partI123 || !partI4 ? nil :
              [self combineSub:@[partI123, partI4] operatorToken:token context:context];
            CHChalkValue* partJ1 = [self combineMul:@[currentValueQuaternion.partReal,operandQuaternion.partJ] operatorToken:token context:context];
            CHChalkValue* partJ2 = [self combineMul:@[currentValueQuaternion.partI,operandQuaternion.partK] operatorToken:token context:context];
            CHChalkValue* partJ3 = [self combineMul:@[currentValueQuaternion.partJ,operandQuaternion.partReal] operatorToken:token context:context];
            CHChalkValue* partJ4 = [self combineMul:@[currentValueQuaternion.partK,operandQuaternion.partI] operatorToken:token context:context];
            CHChalkValue* partJ134 = !partJ1 || !partJ3 || !partJ4 ? nil :
              [self combineAdd:@[partJ1, partJ3, partJ4] operatorToken:token context:context];
            CHChalkValue* newPartJ = !partJ134 || !partJ2 ? nil :
              [self combineSub:@[partJ134, partJ2] operatorToken:token context:context];
            CHChalkValue* partK1 = [self combineMul:@[currentValueQuaternion.partReal,operandQuaternion.partK] operatorToken:token context:context];
            CHChalkValue* partK2 = [self combineMul:@[currentValueQuaternion.partI,operandQuaternion.partJ] operatorToken:token context:context];
            CHChalkValue* partK3 = [self combineMul:@[currentValueQuaternion.partJ,operandQuaternion.partI] operatorToken:token context:context];
            CHChalkValue* partK4 = [self combineMul:@[currentValueQuaternion.partK,operandQuaternion.partReal] operatorToken:token context:context];
            CHChalkValue* partK124 = !partK1 || !partK2 || !partK4 ? nil :
              [self combineAdd:@[partK1, partK2, partK4] operatorToken:token context:context];
            CHChalkValue* newPartK = !partK124 || !partK3 ? nil :
              [self combineSub:@[partK124, partK3] operatorToken:token context:context];

            CHChalkValueNumber* newPartRealValueNumber = [newPartReal dynamicCastToClass:[CHChalkValueNumber class]];
            CHChalkValueNumber* newPartIValueNumber    = [newPartI dynamicCastToClass:[CHChalkValueNumber class]];
            CHChalkValueNumber* newPartJValueNumber    = [newPartJ dynamicCastToClass:[CHChalkValueNumber class]];
            CHChalkValueNumber* newPartKValueNumber    = [newPartK dynamicCastToClass:[CHChalkValueNumber class]];
            if (newPartRealValueNumber && newPartIValueNumber && newPartJValueNumber && newPartKValueNumber)
            {
              [currentValueQuaternion setPartReal:newPartRealValueNumber wrapped:YES];
              [currentValueQuaternion setPartI:newPartIValueNumber wrapped:YES];
              [currentValueQuaternion setPartJ:newPartJValueNumber wrapped:YES];
              [currentValueQuaternion setPartK:newPartKValueNumber wrapped:YES];
            }//end if (newPartRealValueNumber && newPartIValueNumber && newPartJValueNumber && newPartKValueNumber)
            else//if (!newPartRealValueNumber || !newPartIValueNumber || !newPartJValueNumber || !newPartKValueNumber)
              [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                     replace:NO];
          }//end if (currentValueQuaternion && operandQuaternion)
          else if (!currentValueGmp || !operandGmp)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorOperationNonImplemented range:token.range]
                                   replace:NO];
          else if (currentValueGmp && currentValueGmp.valueConstReference && operandGmp && operandGmp.valueConstReference)
          {
            mpfr_clear_flags();
            mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
            chalk_gmp_value_t* currentValueGmpValue = currentValueGmp.valueReference;
            const chalk_gmp_value_t* operandGmpValue = operandGmp.valueConstReference;
            BOOL isOneIgnoringSign = NO;
            BOOL done = NO;
            if (!done && operandGmp.isZero)
            {
              chalkGmpValueSetZero(currentValueGmpValue, NO, context.gmpPool);
              done = YES;
            }//end if (!done && operandGmp.isZero)
            if (!done && ([operandGmp isOne:&isOneIgnoringSign] || isOneIgnoringSign))
            {
              if (isOneIgnoringSign)
                chalkGmpValueNeg(currentValueGmpValue);
              done = YES;
            }//end if (!done && ([operandGmp isOne:&isOneIgnoringSign] || isOneIgnoringSign))
            if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_INTEGER) && (operandGmpValue->type == CHALK_VALUE_TYPE_INTEGER))
            {
              mpzDepool(nextValueGmp.integer, context.gmpPool);
              mpz_set_ui(nextValueGmp.integer, 0);
              nextValueGmp.type = CHALK_VALUE_TYPE_INTEGER;
              done = [self mulIntegers:nextValueGmp.integer op1:currentValueGmpValue->integer op2:operandGmpValue->integer operatorToken:token context:context];
              if (done)
                mpz_swap(currentValueGmpValue->integer, nextValueGmp.integer);
              else if ((context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_INTERVALS) ||
                       (context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_BEST))
                chalkGmpValueMakeReal(currentValueGmpValue, prec, context.gmpPool);
              else
                [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorIntegerOverflow range:token.range]
                                   replace:NO];
              chalkGmpValueClear(&nextValueGmp, YES, context.gmpPool);
            }//end if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_INTEGER) && (operandGmpValue->type == CHALK_VALUE_TYPE_INTEGER))
            if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_INTEGER) && (operandGmpValue->type == CHALK_VALUE_TYPE_FRACTION))
            {
              mpqDepool(nextValueGmp.fraction, context.gmpPool);
              mpq_set_z(nextValueGmp.fraction, currentValueGmpValue->integer);
              nextValueGmp.type = CHALK_VALUE_TYPE_FRACTION;
              mpq_mul(nextValueGmp.fraction, nextValueGmp.fraction, operandGmpValue->fraction);
              done = [CHChalkValueNumberGmp checkFraction:nextValueGmp.fraction token:token setError:YES context:context];
              if (done)
                chalkGmpValueMove(currentValueGmpValue, &nextValueGmp, context.gmpPool);
              else if ((context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_INTERVALS) ||
                       (context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_BEST))
                chalkGmpValueMakeReal(currentValueGmpValue, prec, context.gmpPool);
              else
                [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorIntegerOverflow range:token.range]
                                   replace:NO];
              chalkGmpValueClear(&nextValueGmp, YES, context.gmpPool);
            }//end if ((currentValueGmpValue->type == CHALK_VALUE_TYPE_INTEGER) && (operandGmpValue->type == CHALK_VALUE_TYPE_FRACTION))
            if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_INTEGER) && (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT))
            {
              chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
              mpfrDepool(nextValueGmp.realExact, prec, context.gmpPool);
              mpfr_set_z(nextValueGmp.realExact, currentValueGmpValue->integer, MPFR_RNDN);
              nextValueGmp.type = CHALK_VALUE_TYPE_REAL_EXACT;
              mpfr_mul(nextValueGmp.realExact, nextValueGmp.realExact, operandGmpValue->realExact, MPFR_RNDN);
              done = !mpfr_inexflag_p();
              chalkGmpFlagsRestore(oldFlags);
              if (done)
                chalkGmpValueMove(currentValueGmpValue, &nextValueGmp, context.gmpPool);
              else if ((context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_INTERVALS) ||
                       (context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_BEST))
                chalkGmpValueMakeRealApprox(currentValueGmpValue, prec, context.gmpPool);
              else
                [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorIntegerOverflow range:token.range]
                                   replace:NO];
              chalkGmpValueClear(&nextValueGmp, YES, context.gmpPool);
            }//end if ((currentValueGmpValue->type == CHALK_VALUE_TYPE_INTEGER) && (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT))
            if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_FRACTION) && (operandGmpValue->type == CHALK_VALUE_TYPE_INTEGER))
            {
              mpqDepool(nextValueGmp.fraction, context.gmpPool);
              mpq_set_z(nextValueGmp.fraction, operandGmpValue->integer);
              nextValueGmp.type = CHALK_VALUE_TYPE_FRACTION;
              mpq_mul(nextValueGmp.fraction, currentValueGmpValue->fraction, nextValueGmp.fraction);
              done = [CHChalkValueNumberGmp checkFraction:nextValueGmp.fraction token:token setError:YES context:context];
              if (done)
              {
                chalkGmpValueSimplify(&nextValueGmp, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
                chalkGmpValueMove(currentValueGmpValue, &nextValueGmp, context.gmpPool);
              }//end if (done)
              else if ((context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_INTERVALS) ||
                      (context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_BEST))
                chalkGmpValueMakeReal(currentValueGmpValue, prec, context.gmpPool);
              else
                [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorIntegerOverflow range:token.range]
                                   replace:NO];
              chalkGmpValueClear(&nextValueGmp, YES, context.gmpPool);
            }//end if ((currentValueGmpValue->type == CHALK_VALUE_TYPE_FRACTION) && (operandGmpValue->type == CHALK_VALUE_TYPE_INTEGER))
            if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_FRACTION) && (operandGmpValue->type == CHALK_VALUE_TYPE_FRACTION))
            {
              mpqDepool(nextValueGmp.fraction, context.gmpPool);
              mpq_set(nextValueGmp.fraction, currentValueGmpValue->fraction);
              nextValueGmp.type = CHALK_VALUE_TYPE_FRACTION;
              mpq_mul(nextValueGmp.fraction, currentValueGmpValue->fraction, operandGmpValue->fraction);
              done = [CHChalkValueNumberGmp checkFraction:nextValueGmp.fraction token:token setError:YES context:context];
              if (done)
              {
                chalkGmpValueSimplify(&nextValueGmp, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
                chalkGmpValueMove(currentValueGmpValue, &nextValueGmp, context.gmpPool);
              }//end if (done)
              else if ((context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_INTERVALS) ||
                       (context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_BEST))
                chalkGmpValueMakeReal(currentValueGmpValue, prec, context.gmpPool);
              else
                [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorIntegerOverflow range:token.range]
                                   replace:NO];
              chalkGmpValueClear(&nextValueGmp, YES, context.gmpPool);
            }//end if ((currentValueGmpValue->type == CHALK_VALUE_TYPE_FRACTION) && (operandGmpValue->type == CHALK_VALUE_TYPE_FRACTION))
            if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_FRACTION) && (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT))
            {
              chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
              mpfrDepool(nextValueGmp.realExact, prec, context.gmpPool);
              mpfr_set_q(nextValueGmp.realExact, currentValueGmpValue->fraction, MPFR_RNDN);
              nextValueGmp.type = CHALK_VALUE_TYPE_REAL_EXACT;
              mpfr_mul(nextValueGmp.realExact, nextValueGmp.realExact, operandGmpValue->realExact, MPFR_RNDN);
              done = !mpfr_inexflag_p();
              chalkGmpFlagsRestore(oldFlags);
              if (done)
                chalkGmpValueMove(currentValueGmpValue, &nextValueGmp, context.gmpPool);
              else
                chalkGmpValueMakeRealApprox(currentValueGmpValue, prec, context.gmpPool);
              chalkGmpValueClear(&nextValueGmp, YES, context.gmpPool);
            }//end if ((currentValueGmpValue->type == CHALK_VALUE_TYPE_FRACTION) && (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT))
            if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT) && (operandGmpValue->type == CHALK_VALUE_TYPE_INTEGER))
            {
              chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
              mpfrDepool(nextValueGmp.realExact, prec, context.gmpPool);
              mpfr_set_z(nextValueGmp.realExact, operandGmpValue->integer, MPFR_RNDN);
              nextValueGmp.type = CHALK_VALUE_TYPE_REAL_EXACT;
              mpfr_mul(nextValueGmp.realExact, currentValueGmpValue->realExact, nextValueGmp.realExact, MPFR_RNDN);
              done = !mpfr_inexflag_p();
              chalkGmpFlagsRestore(oldFlags);
              if (done)
                chalkGmpValueMove(currentValueGmpValue, &nextValueGmp, context.gmpPool);
              else
                chalkGmpValueMakeRealApprox(currentValueGmpValue, prec, context.gmpPool);
              chalkGmpValueClear(&nextValueGmp, YES, context.gmpPool);
            }//end if ((currentValueGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT) && (operandGmpValue->type == CHALK_VALUE_TYPE_INTEGER))
            if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT) && (operandGmpValue->type == CHALK_VALUE_TYPE_FRACTION))
            {
              chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
              mpfrDepool(nextValueGmp.realExact, prec, context.gmpPool);
              mpfr_set_q(nextValueGmp.realExact, operandGmpValue->fraction, MPFR_RNDN);
              nextValueGmp.type = CHALK_VALUE_TYPE_REAL_EXACT;
              mpfr_mul(nextValueGmp.realExact, currentValueGmpValue->realExact, nextValueGmp.realExact, MPFR_RNDN);
              done = !mpfr_inexflag_p();
              chalkGmpFlagsRestore(oldFlags);
              if (done)
                chalkGmpValueMove(currentValueGmpValue, &nextValueGmp, context.gmpPool);
              else
                chalkGmpValueMakeRealApprox(currentValueGmpValue, prec, context.gmpPool);
              chalkGmpValueClear(&nextValueGmp, YES, context.gmpPool);
            }//end if ((currentValueGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT) && (operandGmpValue->type == CHALK_VALUE_TYPE_FRACTION))
            if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT) && (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT))
            {
              chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
              mpfrDepool(nextValueGmp.realExact, prec, context.gmpPool);
              mpfr_set(nextValueGmp.realExact, currentValueGmpValue->realExact, MPFR_RNDN);
              nextValueGmp.type = CHALK_VALUE_TYPE_REAL_EXACT;
              mpfr_mul(nextValueGmp.realExact, currentValueGmpValue->realExact, operandGmpValue->realExact, MPFR_RNDN);
              done = !mpfr_inexflag_p();
              chalkGmpFlagsRestore(oldFlags);
              if (done)
                chalkGmpValueMove(currentValueGmpValue, &nextValueGmp, context.gmpPool);
              else
                chalkGmpValueMakeRealApprox(currentValueGmpValue, prec, context.gmpPool);
              chalkGmpValueClear(&nextValueGmp, YES, context.gmpPool);
            }//end if ((currentValueGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT) && (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT))
            if (!done && (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX))
              chalkGmpValueMakeRealApprox(currentValueGmpValue, prec, context.gmpPool);
            if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX))
            {
              if (operandGmpValue->type == CHALK_VALUE_TYPE_INTEGER)
              {
                mpfir_mul_z(currentValueGmpValue->realApprox, currentValueGmpValue->realApprox, operandGmpValue->integer);
                done = YES;
              }//end if (operandGmpValue->type == CHALK_VALUE_TYPE_INTEGER)
              else if (operandGmpValue->type == CHALK_VALUE_TYPE_FRACTION)
              {
                mpfir_mul_q(currentValueGmpValue->realApprox, currentValueGmpValue->realApprox, operandGmpValue->fraction);
                done = YES;
              }//end if (operandGmpValue->type == CHALK_VALUE_TYPE_FRACTION)
              else if (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT)
              {
                mpfir_mul_fr(currentValueGmpValue->realApprox, currentValueGmpValue->realApprox, operandGmpValue->realExact);
                done = YES;
              }//end if (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT)
              else if (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX)
              {
                mpfir_mul(currentValueGmpValue->realApprox, currentValueGmpValue->realApprox, operandGmpValue->realApprox);
                done = YES;
              }//end if (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX)
            }//end if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX))
            if (done)
              currentValueGmp.evaluationComputeFlags = computeFlags | chalkGmpFlagsMake();
            else//if (!done)
              [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorOperationNonImplemented range:token.range]
                                     replace:NO];
            if (context.errorContext.hasError)
              *stop = YES;
          }//end if (operandGmp && operandGmp.valueReference && currentValueGmp && currentValueGmp.valueReference)
          else
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorOperationNonImplemented range:token.range]
                                   replace:NO];
        }//end if (idx>0)
        if (context.errorContext.hasError)
          *stop = YES;
        @synchronized(self) {
          computeFlags |=
            operand.evaluationComputeFlags |
            chalkGmpFlagsMake();
        }//end @synchronized(self)
      }];//end for each operand
      
      chalkGmpValueClear(&nextValueGmp, YES, context.gmpPool);
      currentValue.evaluationComputeFlags |= computeFlags | chalkGmpFlagsMake();
      result = [CHChalkValue finalizeValue:&currentValue context:context];
      [result autorelease];
    }//end if (!result && !context.errorContext.hasError)
  }//end if (operands.count >= 2)
  return result;
}
//end combineMul:operatorToken:context:

+(CHChalkValue*) combineMul2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = [self combine2_2:@selector(combineMul:operatorToken:context:) operands:operands operatorToken:token context:context];
  return result;
}
//end combineMul2:operatorToken:context:

+(CHChalkValue*) combineDiv:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 2)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 2)
  {
    CHChalkValue* operand1Value = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
    CHChalkValueList* operand1List = [operand1Value dynamicCastToClass:[CHChalkValueList class]];
    CHChalkValue* operand2Value = [[operands objectAtIndex:1] dynamicCastToClass:[CHChalkValue class]];
    CHChalkValueList* operand2List = [operand2Value dynamicCastToClass:[CHChalkValueList class]];
    if (!operand1Value || !operand2Value)
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                             replace:NO];
    else if (operand2List)
      result = [[self combineSEL:_cmd  arguments:operands list:operand2List index:1 operatorToken:token context:context] retain];
    else if (operand1List)
      result = [[self combineSEL:_cmd  arguments:operands list:operand1List index:0 operatorToken:token context:context] retain];
    if (!result && !context.errorContext.hasError)
    {
      __block CHChalkValue* currentValue = nil;
      __block chalk_gmp_value_t nextValueGmp = {0};
      __block chalk_compute_flags_t computeFlags = 0;
      [operands enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CHChalkValue* operand = [obj dynamicCastToClass:[CHChalkValue class]];
        if (!operand)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                 replace:NO];
        else if (!idx)
        {
          [currentValue release];
          currentValue = [operand copy];
          //[currentValue.token unionWithToken:token];//experimental
        }//end if (!idx)
        else//if (idx>0)
        {
          //[currentValue.token unionWithToken:operand.token];//experimental
          CHChalkValueScalar* operandScalar = [operand dynamicCastToClass:[CHChalkValueScalar class]];
          CHChalkValueNumberGmp* operandGmp = [operandScalar dynamicCastToClass:[CHChalkValueNumberGmp class]];
          CHChalkValueFormal* operandFormal = [operand dynamicCastToClass:[CHChalkValueFormal class]];
          operandGmp = !operandFormal ? operandGmp : operandFormal.value;
          CHChalkValueQuaternion* operandQuaternion = [operandScalar dynamicCastToClass:[CHChalkValueQuaternion class]];
          CHChalkValueMatrix* operandMatrix = [operand dynamicCastToClass:[CHChalkValueMatrix class]];
          CHChalkValueScalar* currentValueScalar = [currentValue dynamicCastToClass:[CHChalkValueScalar class]];
          CHChalkValueNumberGmp* currentValueGmp = [currentValueScalar dynamicCastToClass:[CHChalkValueNumberGmp class]];
          CHChalkValueQuaternion* currentValueQuaternion = [currentValueScalar dynamicCastToClass:[CHChalkValueQuaternion class]];
          CHChalkValueMatrix* currentValueMatrix = [currentValue dynamicCastToClass:[CHChalkValueMatrix class]];
          if (currentValueGmp && !currentValueQuaternion && operandQuaternion)
          {
            [currentValue autorelease];
            currentValue = [[CHChalkValueQuaternion alloc] initWithToken:token
              partReal:currentValueGmp partRealWrapped:YES
              partI:[CHChalkValueNumberGmp zeroWithToken:token context:context] partIWrapped:YES
              partJ:[CHChalkValueNumberGmp zeroWithToken:token context:context] partJWrapped:YES
              partK:[CHChalkValueNumberGmp zeroWithToken:token context:context] partKWrapped:YES
              context:context];
            currentValueGmp = [currentValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
            currentValueQuaternion = [currentValue dynamicCastToClass:[CHChalkValueQuaternion class]];
          }//end if (currentValueGmp && !currentValueQuaternion && operandQuaternion)
          if (operandMatrix)
          {
            CHChalkValueMatrix* operandMatrixInverted = [operandMatrix copy];
            if (!operandMatrixInverted)
              [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                     replace:NO];
            else//if (operandMatrixInverted)
            {
              [operandMatrixInverted invertWithContext:context];
              CHChalkValue* newCurrentValue = [[self combineMul:@[currentValue,operandMatrixInverted] operatorToken:token context:context] retain];
              [currentValue release];
              currentValue = newCurrentValue;
              [operandMatrixInverted release];
            }//end if (operandMatrixInverted)
          }//end if (operandMatrix)
          else if (currentValueMatrix && operandScalar)
          {
            BOOL isOneIgnoringSign = NO;
            if (operandScalar.isZero)
              [currentValueMatrix fill:[CHChalkValueNumberGmp nanWithContext:context] context:context];
            else if ([operandScalar isOne:&isOneIgnoringSign])
            {
              if (isOneIgnoringSign)
                [currentValueMatrix negate];
            }//end if ([operandScalar isOne:&isOneIgnoringSign])
            else//if (![operandScalar isOne:&isOneIgnoringSign])
            {
              NSUInteger colsCount = currentValueMatrix.colsCount;
              [currentValueMatrix.values enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSUInteger row = !colsCount ? 0 :idx/colsCount;
                NSUInteger col = !colsCount ? 0 :idx%colsCount;
                CHChalkValue* oldValue = [obj dynamicCastToClass:[CHChalkValue class]];
                CHChalkValue* newValue = !oldValue ? nil :
                  [self combineDiv:@[oldValue,operandScalar] operatorToken:token context:context];
                if (newValue)
                  [currentValueMatrix setValue:newValue atRow:row col:col];
                else//if (!newValue)
                {
                  [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                         replace:NO];
                  *stop = YES;
                }//end if (!newValue)
              }];
              if (context.errorContext.hasError)
              {
                [currentValueMatrix release];
                currentValueMatrix = nil;
                currentValue = nil;
              }//end if (context.errorContext.hasError)
            }//end if (![operandScalar isOne:&isOneIgnoringSign])
          }//end if (currentValueMatrix && operandScalar)
          else if (currentValueQuaternion && operandGmp)
          {
            BOOL isOneIgnoringSign = NO;
            if (operandScalar.isZero)
            {
              [currentValue release];
              currentValue = [[CHChalkValueNumberGmp nanWithContext:context] retain];
            }//end if (operandScalar.isZero)
            else if ([operandGmp isOne:&isOneIgnoringSign])
            {
              if (isOneIgnoringSign)
                [currentValueQuaternion negate];
            }//end if ([operandGmp isOne:&isOneIgnoringSign])
            else//if (![operandGmp isOne:&isOneIgnoringSign])
            {
              CHChalkValue* newPartReal = [self combineDiv:@[currentValueQuaternion.partReal,operandGmp] operatorToken:token context:context];
              CHChalkValue* newPartI = [self combineDiv:@[currentValueQuaternion.partI,operandGmp] operatorToken:token context:context];
              CHChalkValue* newPartJ = [self combineDiv:@[currentValueQuaternion.partJ,operandGmp] operatorToken:token context:context];
              CHChalkValue* newPartK = [self combineDiv:@[currentValueQuaternion.partK,operandGmp] operatorToken:token context:context];
              CHChalkValueNumber* newPartRealValueNumber = [newPartReal dynamicCastToClass:[CHChalkValueNumber class]];
              CHChalkValueNumber* newPartIValueNumber = [newPartI dynamicCastToClass:[CHChalkValueNumber class]];
              CHChalkValueNumber* newPartJValueNumber = [newPartJ dynamicCastToClass:[CHChalkValueNumber class]];
              CHChalkValueNumber* newPartKValueNumber = [newPartK dynamicCastToClass:[CHChalkValueNumber class]];
              if (newPartRealValueNumber && newPartIValueNumber && newPartJValueNumber && newPartKValueNumber)
              {
                [currentValueQuaternion setPartReal:newPartRealValueNumber wrapped:YES];
                [currentValueQuaternion setPartI:newPartIValueNumber wrapped:YES];
                [currentValueQuaternion setPartJ:newPartJValueNumber wrapped:YES];
                [currentValueQuaternion setPartK:newPartKValueNumber wrapped:YES];
              }//end if (newPartRealValueNumber && newPartIValueNumber && newPartJValueNumber && newPartKValueNumber)
              else//if (!newPartRealValueNumber || !newPartIValueNumber || !newPartJValueNumber || !newPartKValueNumber
                [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                       replace:NO];
            }//end if (![operandGmp isOne:&isOneIgnoringSign])
          }//end if (currentValueQuaternion && operandGmp)
          else if (currentValueQuaternion && operandQuaternion)
          {
            CHChalkValue* inverted = [CHParserFunctionNode combineInv:@[operandQuaternion] token:token context:context];
            [currentValue autorelease];
            currentValue = !inverted? nil :
              [[self combineMul:@[currentValueQuaternion,inverted] operatorToken:token context:context] retain];
          }//end if (currentValueQuaternion && operandQuaternion)
          else if (!operandGmp || !currentValueGmp)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorOperationNonImplemented range:token.range]
                                   replace:NO];
          else if (currentValueGmp && currentValueGmp.valueConstReference && operandGmp && operandGmp.valueConstReference)
          {
            mpfr_clear_flags();
            mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
            chalk_gmp_value_t* currentValueGmpValue = currentValueGmp.valueReference;
            const chalk_gmp_value_t* operandGmpValue = operandGmp.valueConstReference;
            if (operandGmp.isZero)
            {
              mpfr_set_divby0();
              chalkGmpValueSetNan(currentValueGmpValue, YES, context.gmpPool);
              if (!context.computationConfiguration.propagateNaN)
                [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericDivideByZero range:token.range]
                                       replace:NO];
            }//end if (operandGmp.isZero)
            else//if (!operandGmp.isZero)
            {
              BOOL done = NO;
              BOOL isOneIgnoringSign = NO;
              if (!done && ([operandGmp isOne:&isOneIgnoringSign] || isOneIgnoringSign))
              {
                if (isOneIgnoringSign)
                  chalkGmpValueNeg(currentValueGmpValue);
                done = YES;
              }//end if (!done && ([operandGmp isOne:&isOneIgnoringSign] || isOneIgnoringSign))
              if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_INTEGER) && (operandGmpValue->type == CHALK_VALUE_TYPE_INTEGER))
              {
                mpzDepool(nextValueGmp.integer, context.gmpPool);
                mpz_set_ui(nextValueGmp.integer, 0);
                nextValueGmp.type = CHALK_VALUE_TYPE_INTEGER;
                done = [self divIntegers:nextValueGmp.integer op1:currentValueGmpValue->integer op2:operandGmpValue->integer operatorToken:token context:context];
                if (done)
                  mpz_swap(currentValueGmpValue->integer, nextValueGmp.integer);
                else
                  chalkGmpValueMakeFraction(currentValueGmpValue, context.gmpPool);
                chalkGmpValueClear(&nextValueGmp, YES, context.gmpPool);
              }//end if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_INTEGER) && (operandGmpValue->type == CHALK_VALUE_TYPE_INTEGER))
              if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_INTEGER) && (operandGmpValue->type == CHALK_VALUE_TYPE_FRACTION))
              {
                mpqDepool(nextValueGmp.fraction, context.gmpPool);
                mpq_set_z(nextValueGmp.fraction, currentValueGmpValue->integer);
                nextValueGmp.type = CHALK_VALUE_TYPE_FRACTION;
                mpq_div(nextValueGmp.fraction, nextValueGmp.fraction, operandGmpValue->fraction);
                mpq_canonicalize(nextValueGmp.fraction);
                done = [CHChalkValueNumberGmp checkFraction:nextValueGmp.fraction token:token setError:YES context:context];
                if (done)
                  chalkGmpValueMove(currentValueGmpValue, &nextValueGmp, context.gmpPool);
                else if ((context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_INTERVALS) ||
                         (context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_BEST))
                  chalkGmpValueMakeReal(currentValueGmpValue, prec, context.gmpPool);
                else
                  [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorIntegerOverflow range:token.range]
                                     replace:NO];
                chalkGmpValueClear(&nextValueGmp, YES, context.gmpPool);
              }//end if ((currentValueGmpValue->type == CHALK_VALUE_TYPE_INTEGER) && (operandGmpValue->type == CHALK_VALUE_TYPE_FRACTION))
              if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_INTEGER) && (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT))
              {
                chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
                mpfrDepool(nextValueGmp.realExact, prec, context.gmpPool);
                mpfr_set_z(nextValueGmp.realExact, currentValueGmpValue->integer, MPFR_RNDN);
                nextValueGmp.type = CHALK_VALUE_TYPE_REAL_EXACT;
                mpfr_div(nextValueGmp.realExact, nextValueGmp.realExact, operandGmpValue->realExact, MPFR_RNDN);
                done = !mpfr_inexflag_p();
                chalkGmpFlagsRestore(oldFlags);
                if (done)
                  chalkGmpValueMove(currentValueGmpValue, &nextValueGmp, context.gmpPool);
                else if ((context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_INTERVALS) ||
                         (context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_BEST))
                  chalkGmpValueMakeRealApprox(currentValueGmpValue, prec, context.gmpPool);
                else
                  [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorIntegerOverflow range:token.range]
                                     replace:NO];
                chalkGmpValueClear(&nextValueGmp, YES, context.gmpPool);
              }//end if ((currentValueGmpValue->type == CHALK_VALUE_TYPE_INTEGER) && (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT))
              if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_FRACTION) && (operandGmpValue->type == CHALK_VALUE_TYPE_INTEGER))
              {
                mpqDepool(nextValueGmp.fraction, context.gmpPool);
                mpq_set_z(nextValueGmp.fraction, operandGmpValue->integer);
                nextValueGmp.type = CHALK_VALUE_TYPE_FRACTION;
                mpq_div(nextValueGmp.fraction, currentValueGmpValue->fraction, nextValueGmp.fraction);
                mpq_canonicalize(nextValueGmp.fraction);
                done = [CHChalkValueNumberGmp checkFraction:nextValueGmp.fraction token:token setError:YES context:context];
                if (done)
                {
                  chalkGmpValueSimplify(&nextValueGmp, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
                  chalkGmpValueMove(currentValueGmpValue, &nextValueGmp, context.gmpPool);
                }//end if (done)
                else if ((context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_INTERVALS) ||
                         (context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_BEST))
                  chalkGmpValueMakeReal(currentValueGmpValue, prec, context.gmpPool);
                else
                  [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorIntegerOverflow range:token.range]
                                     replace:NO];
                chalkGmpValueClear(&nextValueGmp, YES, context.gmpPool);
              }//end if ((currentValueGmpValue->type == CHALK_VALUE_TYPE_FRACTION) && (operandGmpValue->type == CHALK_VALUE_TYPE_INTEGER))
              if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_FRACTION) && (operandGmpValue->type == CHALK_VALUE_TYPE_FRACTION))
              {
                mpqDepool(nextValueGmp.fraction, context.gmpPool);
                mpq_set(nextValueGmp.fraction, currentValueGmpValue->fraction);
                nextValueGmp.type = CHALK_VALUE_TYPE_FRACTION;
                mpq_div(nextValueGmp.fraction, currentValueGmpValue->fraction, operandGmpValue->fraction);
                mpq_canonicalize(nextValueGmp.fraction);
                done = [CHChalkValueNumberGmp checkFraction:nextValueGmp.fraction token:token setError:YES context:context];
                if (done)
                {
                  chalkGmpValueSimplify(&nextValueGmp, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
                  chalkGmpValueMove(currentValueGmpValue, &nextValueGmp, context.gmpPool);
                }//end if (done)
                else if ((context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_INTERVALS) ||
                         (context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_BEST))
                  chalkGmpValueMakeReal(currentValueGmpValue, prec, context.gmpPool);
                else
                  [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorIntegerOverflow range:token.range]
                                     replace:NO];
                chalkGmpValueClear(&nextValueGmp, YES, context.gmpPool);
              }//end if ((currentValueGmpValue->type == CHALK_VALUE_TYPE_FRACTION) && (operandGmpValue->type == CHALK_VALUE_TYPE_FRACTION))
              if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_FRACTION) && (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT))
              {
                chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
                mpfrDepool(nextValueGmp.realExact, prec, context.gmpPool);
                mpfr_set_q(nextValueGmp.realExact, currentValueGmpValue->fraction, MPFR_RNDN);
                nextValueGmp.type = CHALK_VALUE_TYPE_REAL_EXACT;
                mpfr_div(nextValueGmp.realExact, nextValueGmp.realExact, operandGmpValue->realExact, MPFR_RNDN);
                done = !mpfr_inexflag_p();
                chalkGmpFlagsRestore(oldFlags);
                if (done)
                  chalkGmpValueMove(currentValueGmpValue, &nextValueGmp, context.gmpPool);
                else
                  chalkGmpValueMakeRealApprox(currentValueGmpValue, prec, context.gmpPool);
                chalkGmpValueClear(&nextValueGmp, YES, context.gmpPool);
              }//end if ((currentValueGmpValue->type == CHALK_VALUE_TYPE_FRACTION) && (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT))
              if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT) && (operandGmpValue->type == CHALK_VALUE_TYPE_INTEGER))
              {
                chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
                mpfrDepool(nextValueGmp.realExact, prec, context.gmpPool);
                mpfr_set_z(nextValueGmp.realExact, operandGmpValue->integer, MPFR_RNDN);
                nextValueGmp.type = CHALK_VALUE_TYPE_REAL_EXACT;
                mpfr_div(nextValueGmp.realExact, currentValueGmpValue->realExact, nextValueGmp.realExact, MPFR_RNDN);
                done = !mpfr_inexflag_p();
                chalkGmpFlagsRestore(oldFlags);
                if (done)
                  chalkGmpValueMove(currentValueGmpValue, &nextValueGmp, context.gmpPool);
                else
                  chalkGmpValueMakeRealApprox(currentValueGmpValue, prec, context.gmpPool);
                chalkGmpValueClear(&nextValueGmp, YES, context.gmpPool);
              }//end if ((currentValueGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT) && (operandGmpValue->type == CHALK_VALUE_TYPE_INTEGER))
              if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT) && (operandGmpValue->type == CHALK_VALUE_TYPE_FRACTION))
              {
                chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
                mpfrDepool(nextValueGmp.realExact, prec, context.gmpPool);
                mpfr_set_q(nextValueGmp.realExact, operandGmpValue->fraction, MPFR_RNDN);
                nextValueGmp.type = CHALK_VALUE_TYPE_REAL_EXACT;
                mpfr_div(nextValueGmp.realExact, currentValueGmpValue->realExact, nextValueGmp.realExact, MPFR_RNDN);
                done = !mpfr_inexflag_p();
                chalkGmpFlagsRestore(oldFlags);
                if (done)
                  chalkGmpValueMove(currentValueGmpValue, &nextValueGmp, context.gmpPool);
                else
                  chalkGmpValueMakeRealApprox(currentValueGmpValue, prec, context.gmpPool);
                chalkGmpValueClear(&nextValueGmp, YES, context.gmpPool);
              }//end if ((currentValueGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT) && (operandGmpValue->type == CHALK_VALUE_TYPE_FRACTION))
              if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT) && (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT))
              {
                chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
                mpfrDepool(nextValueGmp.realExact, prec, context.gmpPool);
                mpfr_set(nextValueGmp.realExact, currentValueGmpValue->realExact, MPFR_RNDN);
                nextValueGmp.type = CHALK_VALUE_TYPE_REAL_EXACT;
                mpfr_div(nextValueGmp.realExact, currentValueGmpValue->realExact, operandGmpValue->realExact, MPFR_RNDN);
                done = !mpfr_inexflag_p();
                chalkGmpFlagsRestore(oldFlags);
                if (done)
                  chalkGmpValueMove(currentValueGmpValue, &nextValueGmp, context.gmpPool);
                else
                  chalkGmpValueMakeRealApprox(currentValueGmpValue, prec, context.gmpPool);
                chalkGmpValueClear(&nextValueGmp, YES, context.gmpPool);
              }//end if ((currentValueGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT) && (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT))
              if (!done && (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX))
                chalkGmpValueMakeRealApprox(currentValueGmpValue, prec, context.gmpPool);
              if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX))
              {
                if (operandGmpValue->type == CHALK_VALUE_TYPE_INTEGER)
                {
                  mpfir_div_z(currentValueGmpValue->realApprox, currentValueGmpValue->realApprox, operandGmpValue->integer);
                  done = YES;
                }//end if (operandGmpValue->type == CHALK_VALUE_TYPE_INTEGER)
                else if (operandGmpValue->type == CHALK_VALUE_TYPE_FRACTION)
                {
                  mpfir_div_q(currentValueGmpValue->realApprox, currentValueGmpValue->realApprox, operandGmpValue->fraction);
                  done = YES;
                }//end if (operandGmpValue->type == CHALK_VALUE_TYPE_FRACTION)
                else if (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT)
                {
                  mpfir_div_fr(currentValueGmpValue->realApprox, currentValueGmpValue->realApprox, operandGmpValue->realExact);
                  done = YES;
                }//end if (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT)
                else if (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX)
                {
                  mpfir_div(currentValueGmpValue->realApprox, currentValueGmpValue->realApprox, operandGmpValue->realApprox);
                  done = YES;
                }//end if (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX)
              }//end if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX))
              if (done)
                currentValueGmp.evaluationComputeFlags = computeFlags | chalkGmpFlagsMake();
              else//if (!done)
              [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorOperationNonImplemented range:token.range]
                                     replace:NO];
            if (context.errorContext.hasError)
              *stop = YES;
            }//end if (!operandGmp.isZero)
          }//end if (currentValueGmp && currentValueGmp.valueConstReference && operandGmp && operandGmp.valueConstReference)
          else
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorOperationNonImplemented range:token.range]
                                   replace:NO];
        }//end if (idx>0)
        if (context.errorContext.hasError)
          *stop = YES;
        @synchronized(self) {
          computeFlags |=
            operand.evaluationComputeFlags |
            chalkGmpFlagsMake();
        }//end @synchronized(self)
      }];//end for each operand
      
      chalkGmpValueClear(&nextValueGmp, YES, context.gmpPool);
      currentValue.evaluationComputeFlags |= computeFlags | chalkGmpFlagsMake();
      result = [CHChalkValue finalizeValue:&currentValue context:context];
      [result autorelease];
    }//end if (!result && !context.errorContext.hasError)
  }//end if (operands.count == 2)
  return result;
}
//end combineDiv:operatorToken:context:

+(CHChalkValue*) combineDiv2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = [self combine2_2:@selector(combineDiv:operatorToken:context:) operands:operands operatorToken:token context:context];
  return result;
}
//end combineDiv2:operatorToken:context:

+(CHChalkValue*) combinePow:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 2)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 2)
  {
    CHChalkValue* operand1 = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
    CHChalkValue* operand2 = [[operands objectAtIndex:1] dynamicCastToClass:[CHChalkValue class]];
    if (!operand1 || !operand2)
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                             replace:NO];
    else
      result = [CHParserFunctionNode combinePow:@[operand1,operand2] token:token context:context];
  }//end if (operands.count == 2)
  return result;
}
//end combinePow:operatorToken:context:

+(CHChalkValue*) combinePow2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = [self combine2_2:@selector(combinePow:operatorToken:context:) operands:operands operatorToken:token context:context];
  return result;
}
//end combinePow2:operatorToken:context:

+(CHChalkValue*) combineSqrt:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    CHChalkValue* operand1 = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
    if (!operand1)
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                             replace:NO];
    else
      result = [CHParserFunctionNode combineSqrt:@[operand1] token:token context:context];
  }//end if (operands.count == 1)
  return result;
}
//end combineSqrt:operatorToken:context:

+(CHChalkValue*) combineSqrt2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = [self combine2_2:@selector(combineSqrt:operatorToken:context:) operands:operands operatorToken:token context:context];
  return result;
}
//end combineSqrt2:operatorToken:context:

+(CHChalkValue*) combineCbrt:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    CHChalkValue* operand1 = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
    if (!operand1)
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                             replace:NO];
    else
      result = [CHParserFunctionNode combineCbrt:@[operand1] token:token context:context];
  }//end if (operands.count == 1)
  return result;
}
//end combineCbrt:operatorToken:context:

+(CHChalkValue*) combineCbrt2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = [self combine2_2:@selector(combineCbrt:operatorToken:context:) operands:operands operatorToken:token context:context];
  return result;
}
//end combineCbrt2:operatorToken:context:

+(CHChalkValue*) combineMulSqrt:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 2)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 2)
  {
    CHChalkValue* operand1 = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
    CHChalkValue* operand2 = [[operands objectAtIndex:1] dynamicCastToClass:[CHChalkValue class]];
    if (!operand1 || !operand2)
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                             replace:NO];
    else//if (operand1 && operand2)
    {
      result = [CHParserFunctionNode combineSqrt:@[operand2] token:token context:context];
      if (result)
        result = [CHParserOperatorNode combineMul:@[operand1, result] operatorToken:token context:context];
    }//end if (operand1 && operand2)
  }//end if (operands.count == 2)
  return result;
}
//end combineMulSqrt:operatorToken:context:

+(CHChalkValue*) combineMulSqrt2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = [self combine2_2:@selector(combineMulSqrt:operatorToken:context:) operands:operands operatorToken:token context:context];
  return result;
}
//end combineMulSqrt2:operatorToken:context:

+(CHChalkValue*) combineMulCbrt:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 2)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 2)
  {
    CHChalkValue* operand1 = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
    CHChalkValue* operand2 = [[operands objectAtIndex:1] dynamicCastToClass:[CHChalkValue class]];
    if (!operand1 || !operand2)
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                             replace:NO];
    else//if (operand1 && operand2)
    {
      result = [CHParserFunctionNode combineCbrt:@[operand2] token:token context:context];
      if (result)
        result = [CHParserOperatorNode combineMul:@[operand1, result] operatorToken:token context:context];
    }//end if (operand1 && operand2)
  }//end if (operands.count == 2)
  return result;
}
//end combineMulCbrt:operatorToken:context:

+(CHChalkValue*) combineMulCbrt2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = [self combine2_2:@selector(combineMulCbrt:operatorToken:context:) operands:operands operatorToken:token context:context];
  return result;
}
//end combineMulCbrt2:operatorToken:context:

+(CHChalkValue*) combineDegree:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    CHChalkValue* operand1Value = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
    CHChalkValueList* operand1List = [operand1Value dynamicCastToClass:[CHChalkValueList class]];
    if (!operand1Value)
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                             replace:NO];
    else if (operand1List)
      result = [[self combineSEL:_cmd  arguments:operands list:operand1List index:0 operatorToken:token context:context] retain];
    if (!result && !context.errorContext.hasError)
    {
      __block CHChalkValue* currentValue = nil;
      __block chalk_compute_flags_t computeFlags = 0;
      [operands enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CHChalkValue* operand = [obj dynamicCastToClass:[CHChalkValue class]];
        if (!operand)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                 replace:NO];
        else//if (operand)
        {
          CHChalkValueNumberGmp* operandGmp = [obj dynamicCastToClass:[CHChalkValueNumberGmp class]];
          CHChalkValueFormal* operandFormal = [obj dynamicCastToClass:[CHChalkValueFormal class]];
          operandGmp = !operandFormal ? operandGmp : operandFormal.value;
          if (operandGmp)
          {
            [currentValue autorelease];
            currentValue = [operandGmp copy];
            //[currentValue.token unionWithToken:token];//experimental
            CHChalkValueNumberGmp* currentValueGmp = [currentValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
            chalk_gmp_value_t* currentValueGmpValue = currentValueGmp.valueReference;
            if (!currentValueGmpValue)
              [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                     replace:NO];
            else//if (currentValueGmpValue)
            {
              if (![currentValueGmp isZero])
              {
                mpfr_clear_flags();
                mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
                chalkGmpValueMakeRealApprox(currentValueGmpValue, prec, context.gmpPool);
                mpfr_t pi;
                mpfrDepool(pi, prec, context.gmpPool);
                mpfr_const_pi(pi, MPFR_RNDN);
                mpfir_div_si(currentValueGmpValue->realApprox, currentValueGmpValue->realApprox, 180);
                mpfir_mul_fr(currentValueGmpValue->realApprox, currentValueGmpValue->realApprox, pi);
                mpfrRepool(pi, context.gmpPool);
              }//end if (![currentValueGmp isZero])
              if (context.errorContext.hasError)
                *stop = YES;
            }//end if (currentValueGmpValue)
          }//end if (operandGmp)
          else
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorOperationNonImplemented range:token.range]
                                   replace:NO];
        }//end if (operand)
        if (context.errorContext.hasError)
          *stop = YES;
        @synchronized(self) {
          computeFlags |=
            operand.evaluationComputeFlags |
            chalkGmpFlagsMake();
        }//end @synchronized(self)
      }];//end for each operand

      currentValue.evaluationComputeFlags |= computeFlags | chalkGmpFlagsMake();
      result = [CHChalkValue finalizeValue:&currentValue context:context];
      [result autorelease];
    }//end if (!result && !context.errorContext.hasError)
  }//end if (operands.count == 1)
  return result;
}
//end combineDegree:operatorToken:context:

+(CHChalkValue*) combineDegree2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = [self combine2_1:@selector(combineDegree:operatorToken:context:) operands:operands operatorToken:token context:context];
  return result;
}
//end combineDegree2:operatorToken:context:

+(CHChalkValue*) combineFactorial:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    CHChalkValue* operand1Value = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
    CHChalkValueList* operand1List = [operand1Value dynamicCastToClass:[CHChalkValueList class]];
    if (!operand1Value)
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                             replace:NO];
    else if (operand1List)
      result = [[self combineSEL:_cmd  arguments:operands list:operand1List index:0 operatorToken:token context:context] retain];
    if (!result && !context.errorContext.hasError)
    {
      __block CHChalkValue* currentValue = nil;
      __block chalk_compute_flags_t computeFlags = 0;
      [operands enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CHChalkValue* operand = [obj dynamicCastToClass:[CHChalkValue class]];
        if (!operand)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                 replace:NO];
        else//if (operand)
        {
          CHChalkValueNumberGmp* operandGmp = [obj dynamicCastToClass:[CHChalkValueNumberGmp class]];
          CHChalkValueFormal* operandFormal = [obj dynamicCastToClass:[CHChalkValueFormal class]];
          operandGmp = !operandFormal ? operandGmp : operandFormal.value;
          CHChalkValueQuaternion* operandQuaternion = [obj dynamicCastToClass:[CHChalkValueQuaternion class]];
          if (operandQuaternion)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorOperationNonImplemented range:token.range]
                                   replace:NO];
          else if (operandGmp)
          {
            mpfr_clear_flags();
            mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
            const chalk_gmp_value_t* operandGmpValue = operandGmp.valueConstReference;
            [currentValue autorelease];
            currentValue = [operandGmp copy];
            //[currentValue.token unionWithToken:token];//experimental
            CHChalkValueNumberGmp* currentValueGmp = [currentValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
            chalk_gmp_value_t* currentValueGmpValue = currentValueGmp.valueReference;
            if (!currentValueGmpValue)
              [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                     replace:NO];
            else//if (currentValueGmpValue)
            {
              BOOL done = NO;
              if (!done)
              {
                chalkGmpValueSet(currentValueGmpValue, operandGmpValue, context.gmpPool);
                currentValueGmp.naturalBase = operand.naturalBase;
                if (currentValueGmp.valueType != CHALK_VALUE_TYPE_INTEGER)
                {
                }//end if (currentValueGmp.valueType != CHALK_VALUE_TYPE_INTEGER)
                else if (mpz_sgn(currentValueGmpValue->integer) < 0)
                {
                  chalkGmpValueSetNan(currentValueGmpValue, YES, context.gmpPool);
                  if (!context.computationConfiguration.propagateNaN)
                    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericInvalid range:token.range]
                                           replace:NO];
                }//end if (mpz_sgn(currentValueGmpValue->integer) < 0)
                else if (mpz_sgn(currentValueGmpValue->integer) == 0)
                {
                  mpz_set_ui(currentValueGmpValue->integer, 1);
                  done = YES;
                }//end if (mpz_sgn(currentValueGmpValue->integer) == 0)
                else//if (mpz_sgn(currentValueGmpValue->integer) >= 0)
                {
                  done = [self factorialIntegers:currentValueGmpValue->integer op1:currentValueGmpValue->integer operatorToken:token context:context];
                  if (!done && !context.errorContext.hasError && mpz_fits_uint_p(operandGmpValue->integer))
                  {
                    chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
                    chalkGmpValueClear(currentValueGmpValue, YES, context.gmpPool);
                    mpfrDepool(currentValueGmpValue->realExact, prec, context.gmpPool);
                    currentValueGmpValue->type = CHALK_VALUE_TYPE_REAL_EXACT;
                    mpfr_fac_ui(currentValueGmpValue->realExact, mpz_get_ui(operandGmpValue->integer), MPFR_RNDN);
                    done = !mpfr_inexflag_p();
                    chalkGmpFlagsRestore(oldFlags);
                    if (!done)
                    {
                      chalkGmpValueClear(currentValueGmpValue, YES, context.gmpPool);
                      mpfirDepool(currentValueGmpValue->realApprox, prec, context.gmpPool);
                      currentValueGmpValue->type = CHALK_VALUE_TYPE_REAL_APPROX;
                      unsigned long ui = mpz_get_ui(operandGmpValue->integer);
                      mpfir_fac_ui(currentValueGmpValue->realApprox, ui, MPFR_RNDN);
                      done = YES;
                    }//end if (!done)
                  }//end if (!done && !context.errorContext.hasError && mpz_fits_uint_p(operandGmpValue->integer))
                }//end if (mpz_sgn(currentValueGmpValue->integer) >= 0)
              }//end if (!done && (currentValueGmpValue->type == CHALK_VALUE_TYPE_INTEGER))
              if (done)
                currentValueGmp.evaluationComputeFlags = computeFlags | chalkGmpFlagsMake();
              else//if (!done)
                [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorOperationNonImplemented range:token.range]
                                       replace:NO];
              if (context.errorContext.hasError)
                *stop = YES;
            }//end if (currentValueGmpValue)
          }//end if (operandGmp)
          else
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorOperationNonImplemented range:token.range]
                                   replace:NO];
        }//end if (operand)
        if (context.errorContext.hasError)
          *stop = YES;
        @synchronized(self) {
          computeFlags |=
            operand.evaluationComputeFlags |
            chalkGmpFlagsMake();
        }//end @synchronized(self)
      }];//end for each operand

      currentValue.evaluationComputeFlags |= computeFlags | chalkGmpFlagsMake();
      result = [CHChalkValue finalizeValue:&currentValue context:context];
      [result autorelease];
    }//end if (!result && !context.errorContext.hasError)
  }//end if (operands.count == 1)
  return result;
}
//end combineFactorial:operatorToken:context:

+(CHChalkValue*) combineFactorial2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = [self combine2_1:@selector(combineFactorial:operatorToken:context:) operands:operands operatorToken:token context:context];
  return result;
}
//end combineFactorial2:operatorToken:context:

+(CHChalkValue*) combineUncertainty:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 2)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 2)
  {
    CHChalkValueNumberFraction* fractionNumber = [[operands objectAtIndex:1] dynamicCastToClass:[CHChalkValueNumberFraction class]];
    CHChalkValueNumberGmp* fractionNumberValue = fractionNumber.numberValue;
    const chalk_gmp_value_t* fractionNumberGmpValue = fractionNumberValue.valueConstReference;
    NSUInteger fractionValue = fractionNumber.fraction;
    if (!fractionNumber)
      result = [CHParserFunctionNode combineInterval:operands token:token context:context];
    else if (!fractionValue || !fractionNumberGmpValue)
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorUnknown range:token.range]
                             replace:NO];
    else//if (fraction)
    {
      CHChalkValueNumberGmp* referenceValueNumber = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValueNumberGmp class]];
      const chalk_gmp_value_t* referenceGmpValue = referenceValueNumber.valueConstReference;
      if (!referenceValueNumber)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                               replace:NO];
      else if (!referenceGmpValue)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorUnknown range:token.range]
                               replace:NO];
      else//if (referenceGmpValue)
      {
        chalk_gmp_value_t referenceValue = {0};
        chalk_gmp_value_t delta = {0};
        chalkGmpValueSet(&referenceValue, referenceGmpValue, context.gmpPool);
        chalkGmpValueSet(&delta, fractionNumberGmpValue, context.gmpPool);
        BOOL ok = YES;
        ok &= chalkGmpValueMakeRealApprox(&referenceValue, context.computationConfiguration.softFloatSignificandBits, context.gmpPool);
        ok &= chalkGmpValueMakeRealApprox(&delta, context.computationConfiguration.softFloatSignificandBits, context.gmpPool);
        if (!ok)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                 replace:NO];
        else//if (ok)
        {
          mpz_t fractionZ;
          mpzDepool(fractionZ, context.gmpPool);
          mpz_set_nsui(fractionZ, fractionValue);
          mpfir_div_z(delta.realApprox, delta.realApprox, fractionZ);
          mpzRepool(fractionZ, context.gmpPool);
          mpfir_mul(delta.realApprox, delta.realApprox, referenceValue.realApprox);
          CHChalkValueNumberGmp* deltaValue = [[[CHChalkValueNumberGmp alloc] initWithToken:token value:&delta naturalBase:referenceValueNumber.naturalBase context:context] autorelease];
          if (!deltaValue)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                   replace:NO];
          else
            result = [CHParserFunctionNode combineInterval:@[referenceValueNumber, deltaValue] token:token context:context];
        }//end if (ok)
        chalkGmpValueClear(&referenceValue, YES, context.gmpPool);
        chalkGmpValueClear(&delta, YES, context.gmpPool);
      }//end if (referenceValue)
    }//if (fraction)
  }//end if (operands.count == 2)
  return result;
}
//end combineUncertainty:operatorToken:context:

+(CHChalkValue*) combineAbs:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    CHChalkValue* operand = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
    if (!operand)
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                             replace:NO];
    else
      result = [CHParserFunctionNode combineAbs:@[operand] token:token context:context];
  }//end if (operands.count == 1)
  return result;
}
//end combineAbs:operatorToken:context:

+(CHChalkValue*) combineNot:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    @autoreleasepool {
      CHChalkValue* operandValue = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueBoolean* operandBooleanValue = [operandValue dynamicCastToClass:[CHChalkValueBoolean class]];
      CHChalkValueNumberRaw* operandNumberRaw = [operandValue dynamicCastToClass:[CHChalkValueNumberRaw class]];
      CHChalkValueList* operandList = [operandValue dynamicCastToClass:[CHChalkValueList class]];
      if (operandList)
        result = [[self combineSEL:_cmd arguments:operands list:operandList index:0 operatorToken:token context:context] retain];
      else if (operandBooleanValue)
      {
        chalk_bool_t boolResult = chalkBoolNot(operandBooleanValue.chalkBoolValue);
        result = [[CHChalkValueBoolean alloc] initWithToken:token chalkBoolValue:boolResult context:context];
        if (!result)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                 replace:NO];
      }//if (operandBooleanValue)
      else if (operandNumberRaw)
      {
        result = [operandNumberRaw copy];
        //[result.token unionWithToken:token];//experimental
        CHChalkValueNumberRaw* resultRaw = [result dynamicCastToClass:[CHChalkValueNumberRaw class]];
        if (!result || !resultRaw.valueReference)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                 replace:NO];
        else//if (resultRaw.valueReference))
        {
          NSRange range = getTotalBitsRangeForBitInterpretation(&resultRaw.valueReference->bitInterpretation);
          mpz_complement1(resultRaw.valueReference->bits, range);
        }//end if (resultRaw.valueReference))
      }//if (operandNumberRaw)
      else
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                               replace:NO];
      result.evaluationComputeFlags |=
        operandValue.evaluationComputeFlags |
        chalkGmpFlagsMake();
    }//end @autoreleasepool
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineNot:operatorToken:context:

+(CHChalkValue*) combineNot2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = [self combine2_1:@selector(combineNot:operatorToken:context:) operands:operands operatorToken:token context:context];
  return result;
}
//end combineNot2:operatorToken:context:

+(CHChalkValue*) combineLeq:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 2)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 2)
  {
    @autoreleasepool {
      CHChalkValue* operand1Value = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueNumberGmp* operand1Gmp = [operand1Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueBoolean* operand1Boolean = [operand1Value dynamicCastToClass:[CHChalkValueBoolean class]];
      const chalk_gmp_value_t* operand1GmpValue = operand1Gmp.valueConstReference;
      CHChalkValueList* operand1List = [operand1Value dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValue* operand2Value = [[operands objectAtIndex:1] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueNumberGmp* operand2Gmp = [operand2Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueBoolean* operand2Boolean = [operand2Value dynamicCastToClass:[CHChalkValueBoolean class]];
      const chalk_gmp_value_t* operand2GmpValue = operand2Gmp.valueConstReference;
      CHChalkValueList* operand2List = [operand2Value dynamicCastToClass:[CHChalkValueList class]];
      if (operand1List)
        result = [[self combineSEL:_cmd arguments:operands list:operand1List index:0 operatorToken:token context:context] retain];
      else if (operand2List)
        result = [[self combineSEL:_cmd arguments:operands list:operand2List index:1 operatorToken:token context:context] retain];
      else if (operand1Boolean && operand2Boolean)
      {
        chalk_bool_t boolResult =
          ((NSUInteger)operand1Boolean.chalkBoolValue <= (NSUInteger)operand2Boolean.chalkBoolValue) ? CHALK_BOOL_YES :
          CHALK_BOOL_NO;
        result = [[CHChalkValueBoolean alloc] initWithToken:token chalkBoolValue:boolResult context:context];
        if (!result)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                 replace:NO];
      }//end if (operand1Boolean && operand2Boolean)
      else if (operand1GmpValue && operand2GmpValue)
      {
        chalk_bool_t boolResult = CHALK_BOOL_MAYBE;
        if (chalkGmpValueIsNan(operand1GmpValue) || chalkGmpValueIsNan(operand2GmpValue))
          boolResult = CHALK_BOOL_MAYBE;
        else if (operand1GmpValue->type == CHALK_VALUE_TYPE_INTEGER)
        {
          if (operand2GmpValue->type == CHALK_VALUE_TYPE_INTEGER)
            boolResult = (mpz_cmp(operand1GmpValue->integer, operand2GmpValue->integer) <= 0) ? CHALK_BOOL_YES :
              CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_FRACTION)
            boolResult = (mpq_cmp_z(operand2GmpValue->fraction, operand1GmpValue->integer) >= 0) ? CHALK_BOOL_YES :
              CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT)
            boolResult = (mpfr_cmp_z(operand2GmpValue->realExact, operand1GmpValue->integer) >= 0) ? CHALK_BOOL_YES :
              CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX)
            boolResult =
              (mpfr_cmp_z(&operand2GmpValue->realApprox->interval.left, operand1GmpValue->integer) >= 0) ? CHALK_BOOL_YES :
              (mpfr_cmp_z(&operand2GmpValue->realApprox->interval.right, operand1GmpValue->integer) >= 0) ? CHALK_BOOL_MAYBE :
              CHALK_BOOL_NO;
        }//end if (operand1GmpValue->type == CHALK_VALUE_TYPE_INTEGER)
        else if (operand1GmpValue->type == CHALK_VALUE_TYPE_FRACTION)
        {
          if (operand2GmpValue->type == CHALK_VALUE_TYPE_INTEGER)
            boolResult = (mpq_cmp_z(operand1GmpValue->fraction, operand2GmpValue->integer) <= 0) ? CHALK_BOOL_YES : CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_FRACTION)
            boolResult = (mpq_cmp(operand1GmpValue->fraction, operand2GmpValue->fraction) <= 0) ? CHALK_BOOL_YES : CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT)
            boolResult = (mpfr_cmp_q(operand2GmpValue->realExact, operand1GmpValue->fraction) >= 0) ? CHALK_BOOL_YES : CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX)
            boolResult =
              (mpfr_cmp_q(&operand2GmpValue->realApprox->interval.left, operand1GmpValue->fraction) >= 0) ? CHALK_BOOL_YES :
              (mpfr_cmp_q(&operand2GmpValue->realApprox->interval.right, operand1GmpValue->fraction) >= 0) ? CHALK_BOOL_MAYBE :
              CHALK_BOOL_NO;
        }//end if (operand1GmpValue->type == CHALK_VALUE_TYPE_FRACTION)
        else if (operand1GmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT)
        {
          if (operand2GmpValue->type == CHALK_VALUE_TYPE_INTEGER)
            boolResult = (mpfr_cmp_z(operand1GmpValue->realExact, operand2GmpValue->integer) <= 0) ? CHALK_BOOL_YES : CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_FRACTION)
            boolResult = (mpfr_cmp_q(operand1GmpValue->realExact, operand2GmpValue->fraction) <= 0) ? CHALK_BOOL_YES : CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT)
            boolResult = (mpfr_cmp(operand1GmpValue->realExact, operand2GmpValue->realExact) <= 0) ? CHALK_BOOL_YES : CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX)
            boolResult =
              (mpfr_cmp(&operand2GmpValue->realApprox->interval.left, operand1GmpValue->realExact) >= 0) ? CHALK_BOOL_YES :
              (mpfr_cmp(&operand2GmpValue->realApprox->interval.right, operand1GmpValue->realExact) >= 0) ? CHALK_BOOL_MAYBE :
              CHALK_BOOL_NO;
        }//end if (operand1GmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT)
        else if (operand1GmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX)
        {
          if (operand2GmpValue->type == CHALK_VALUE_TYPE_INTEGER)
            boolResult =
              (mpfr_cmp_z(&operand1GmpValue->realApprox->interval.right, operand2GmpValue->integer) <= 0) ? CHALK_BOOL_YES :
              (mpfr_cmp_z(&operand1GmpValue->realApprox->interval.left, operand2GmpValue->integer) <= 0) ? CHALK_BOOL_MAYBE :
              CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_FRACTION)
            boolResult =
              (mpfr_cmp_q(&operand1GmpValue->realApprox->interval.right, operand2GmpValue->fraction) <= 0) ? CHALK_BOOL_YES :
              (mpfr_cmp_q(&operand1GmpValue->realApprox->interval.left, operand2GmpValue->fraction) <= 0) ? CHALK_BOOL_MAYBE :
              CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT)
            boolResult =
              (mpfr_cmp(&operand1GmpValue->realApprox->interval.right, operand2GmpValue->realExact) <= 0) ? CHALK_BOOL_YES :
              (mpfr_cmp(&operand1GmpValue->realApprox->interval.left, operand2GmpValue->realExact) <= 0) ? CHALK_BOOL_MAYBE :
              CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX)
            boolResult =
              (mpfr_cmp(&operand1GmpValue->realApprox->interval.right, &operand2GmpValue->realApprox->interval.left) <= 0) ? CHALK_BOOL_YES :
              (mpfr_cmp(&operand1GmpValue->realApprox->interval.left, &operand2GmpValue->realApprox->interval.right) > 0) ? CHALK_BOOL_NO :
              CHALK_BOOL_MAYBE;
        }//end if (operand1GmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX)
        result = [[CHChalkValueBoolean alloc] initWithToken:token chalkBoolValue:boolResult context:context];
        if (!result)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                 replace:NO];
      }//if (operand1GmpValue && operand2GmpValue)
      else
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                               replace:NO];
      result.evaluationComputeFlags |=
        operand1Value.evaluationComputeFlags |
        operand2Value.evaluationComputeFlags |
        chalkGmpFlagsMake();
    }//end @autoreleasepool
  }//end if (operands.count == 2)
  return [result autorelease];
}
//end combineLeq:operatorToken:context:

+(CHChalkValue*) combineLeq2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = [self combine2_2:@selector(combineLeq:operatorToken:context:) operands:operands operatorToken:token context:context];
  return result;
}
//end combineLeq2:operatorToken:context:

+(CHChalkValue*) combineGeq:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 2)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 2)
  {
    @autoreleasepool {
      CHChalkValue* operand1Value = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueNumberGmp* operand1Gmp = [operand1Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueBoolean* operand1Boolean = [operand1Value dynamicCastToClass:[CHChalkValueBoolean class]];
      const chalk_gmp_value_t* operand1GmpValue = operand1Gmp.valueConstReference;
      CHChalkValueList* operand1List = [operand1Value dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValue* operand2Value = [[operands objectAtIndex:1] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueNumberGmp* operand2Gmp = [operand2Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueBoolean* operand2Boolean = [operand2Value dynamicCastToClass:[CHChalkValueBoolean class]];
      const chalk_gmp_value_t* operand2GmpValue = operand2Gmp.valueConstReference;
      CHChalkValueList* operand2List = [operand2Value dynamicCastToClass:[CHChalkValueList class]];
      if (operand1List)
        result = [[self combineSEL:_cmd arguments:operands list:operand1List index:0 operatorToken:token context:context] retain];
      else if (operand2List)
        result = [[self combineSEL:_cmd arguments:operands list:operand2List index:1 operatorToken:token context:context] retain];
      else if (operand1Boolean && operand2Boolean)
      {
        chalk_bool_t boolResult =
          ((NSUInteger)operand1Boolean.chalkBoolValue >= (NSUInteger)operand2Boolean.chalkBoolValue) ? CHALK_BOOL_YES :
          CHALK_BOOL_NO;
        result = [[CHChalkValueBoolean alloc] initWithToken:token chalkBoolValue:boolResult context:context];
        if (!result)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                 replace:NO];
      }//end if (operand1Boolean && operand2Boolean)
      else if (operand1GmpValue && operand2GmpValue)
      {
        chalk_bool_t boolResult = CHALK_BOOL_MAYBE;
        if (chalkGmpValueIsNan(operand1GmpValue) || chalkGmpValueIsNan(operand2GmpValue))
          boolResult = CHALK_BOOL_MAYBE;
        else if (operand1GmpValue->type == CHALK_VALUE_TYPE_INTEGER)
        {
          if (operand2GmpValue->type == CHALK_VALUE_TYPE_INTEGER)
            boolResult = (mpz_cmp(operand1GmpValue->integer, operand2GmpValue->integer) >= 0) ? CHALK_BOOL_YES :
              CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_FRACTION)
            boolResult = (mpq_cmp_z(operand2GmpValue->fraction, operand1GmpValue->integer) <= 0) ? CHALK_BOOL_YES :
              CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT)
            boolResult = (mpfr_cmp_z(operand2GmpValue->realExact, operand1GmpValue->integer) <= 0) ? CHALK_BOOL_YES :
              CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX)
            boolResult =
              (mpfr_cmp_z(&operand2GmpValue->realApprox->interval.right, operand1GmpValue->integer) <= 0) ? CHALK_BOOL_YES :
              (mpfr_cmp_z(&operand2GmpValue->realApprox->interval.left, operand1GmpValue->integer) <= 0) ? CHALK_BOOL_MAYBE :
              CHALK_BOOL_NO;
        }//end if (operand1GmpValue->type == CHALK_VALUE_TYPE_INTEGER)
        else if (operand1GmpValue->type == CHALK_VALUE_TYPE_FRACTION)
        {
          if (operand2GmpValue->type == CHALK_VALUE_TYPE_INTEGER)
            boolResult = (mpq_cmp_z(operand1GmpValue->fraction, operand2GmpValue->integer) >= 0) ? CHALK_BOOL_YES : CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_FRACTION)
            boolResult = (mpq_cmp(operand1GmpValue->fraction, operand2GmpValue->fraction) >= 0) ? CHALK_BOOL_YES : CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT)
            boolResult = (mpfr_cmp_q(operand2GmpValue->realExact, operand1GmpValue->fraction) <= 0) ? CHALK_BOOL_YES : CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX)
            boolResult =
              (mpfr_cmp_q(&operand2GmpValue->realApprox->interval.right, operand1GmpValue->fraction) <= 0) ? CHALK_BOOL_YES :
              (mpfr_cmp_q(&operand2GmpValue->realApprox->interval.left, operand1GmpValue->fraction) <= 0) ? CHALK_BOOL_MAYBE :
              CHALK_BOOL_NO;
        }//end if (operand1GmpValue->type == CHALK_VALUE_TYPE_FRACTION)
        else if (operand1GmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT)
        {
          if (operand2GmpValue->type == CHALK_VALUE_TYPE_INTEGER)
            boolResult = (mpfr_cmp_z(operand1GmpValue->realExact, operand2GmpValue->integer) >= 0) ? CHALK_BOOL_YES : CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_FRACTION)
            boolResult = (mpfr_cmp_q(operand1GmpValue->realExact, operand2GmpValue->fraction) >= 0) ? CHALK_BOOL_YES : CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT)
            boolResult = (mpfr_cmp(operand1GmpValue->realExact, operand2GmpValue->realExact) >= 0) ? CHALK_BOOL_YES : CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX)
            boolResult =
              (mpfr_cmp(&operand2GmpValue->realApprox->interval.right, operand1GmpValue->realExact) <= 0) ? CHALK_BOOL_YES :
              (mpfr_cmp(&operand2GmpValue->realApprox->interval.left, operand1GmpValue->realExact) <= 0) ? CHALK_BOOL_MAYBE :
              CHALK_BOOL_NO;
        }//end if (operand1GmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT)
        else if (operand1GmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX)
        {
          if (operand2GmpValue->type == CHALK_VALUE_TYPE_INTEGER)
            boolResult =
              (mpfr_cmp_z(&operand1GmpValue->realApprox->interval.left, operand2GmpValue->integer) >= 0) ? CHALK_BOOL_YES :
              (mpfr_cmp_z(&operand1GmpValue->realApprox->interval.right, operand2GmpValue->integer) >= 0) ? CHALK_BOOL_MAYBE :
              CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_FRACTION)
            boolResult =
              (mpfr_cmp_q(&operand1GmpValue->realApprox->interval.left, operand2GmpValue->fraction) >= 0) ? CHALK_BOOL_YES :
              (mpfr_cmp_q(&operand1GmpValue->realApprox->interval.right, operand2GmpValue->fraction) >= 0) ? CHALK_BOOL_MAYBE :
              CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT)
            boolResult =
              (mpfr_cmp(&operand1GmpValue->realApprox->interval.left, operand2GmpValue->realExact) >= 0) ? CHALK_BOOL_YES :
              (mpfr_cmp(&operand1GmpValue->realApprox->interval.right, operand2GmpValue->realExact) >= 0) ? CHALK_BOOL_MAYBE :
              CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX)
            boolResult =
              (mpfr_cmp(&operand1GmpValue->realApprox->interval.left, &operand2GmpValue->realApprox->interval.right) >= 0) ? CHALK_BOOL_YES :
              (mpfr_cmp(&operand1GmpValue->realApprox->interval.right, &operand2GmpValue->realApprox->interval.left) < 0) ? CHALK_BOOL_NO :
              CHALK_BOOL_MAYBE;
        }//end if (operand1GmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX)
        result = [[CHChalkValueBoolean alloc] initWithToken:token chalkBoolValue:boolResult context:context];
        if (!result)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                 replace:NO];
      }//if (operand1GmpValue && operand2GmpValue)
      else
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                               replace:NO];
      result.evaluationComputeFlags |=
        operand1Value.evaluationComputeFlags |
        operand2Value.evaluationComputeFlags |
        chalkGmpFlagsMake();
    }//end @autoreleasepool
  }//end if (operands.count == 2)
  return [result autorelease];
}
//end combineGeq:operatorToken:context:

+(CHChalkValue*) combineGeq2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = [self combine2_2:@selector(combineGeq:operatorToken:context:) operands:operands operatorToken:token context:context];
  return result;
}
//end combineGeq2:operatorToken:context:

+(CHChalkValue*) combineLow:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 2)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 2)
  {
    @autoreleasepool {
      CHChalkValue* operand1Value = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueNumberGmp* operand1Gmp = [operand1Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueBoolean* operand1Boolean = [operand1Value dynamicCastToClass:[CHChalkValueBoolean class]];
      const chalk_gmp_value_t* operand1GmpValue = operand1Gmp.valueConstReference;
      CHChalkValueList* operand1List = [operand1Value dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValue* operand2Value = [[operands objectAtIndex:1] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueNumberGmp* operand2Gmp = [operand2Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueBoolean* operand2Boolean = [operand2Value dynamicCastToClass:[CHChalkValueBoolean class]];
      const chalk_gmp_value_t* operand2GmpValue = operand2Gmp.valueConstReference;
      CHChalkValueList* operand2List = [operand2Value dynamicCastToClass:[CHChalkValueList class]];
      if (operand1List)
        result = [[self combineSEL:_cmd arguments:operands list:operand1List index:0 operatorToken:token context:context] retain];
      else if (operand2List)
        result = [[self combineSEL:_cmd arguments:operands list:operand2List index:1 operatorToken:token context:context] retain];
      else if (operand1Boolean && operand2Boolean)
      {
        chalk_bool_t boolResult =
          ((NSUInteger)operand1Boolean.chalkBoolValue < (NSUInteger)operand2Boolean.chalkBoolValue) ? CHALK_BOOL_YES :
          CHALK_BOOL_NO;
        result = [[CHChalkValueBoolean alloc] initWithToken:token chalkBoolValue:boolResult context:context];
        if (!result)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                 replace:NO];
      }//end if (operand1Boolean && operand2Boolean)
      else if (operand1GmpValue && operand2GmpValue)
      {
        chalk_bool_t boolResult = CHALK_BOOL_MAYBE;
        if (chalkGmpValueIsNan(operand1GmpValue) || chalkGmpValueIsNan(operand2GmpValue))
          boolResult = CHALK_BOOL_MAYBE;
        else if (operand1GmpValue->type == CHALK_VALUE_TYPE_INTEGER)
        {
          if (operand2GmpValue->type == CHALK_VALUE_TYPE_INTEGER)
            boolResult = (mpz_cmp(operand1GmpValue->integer, operand2GmpValue->integer) < 0) ? CHALK_BOOL_YES :
              CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_FRACTION)
            boolResult = (mpq_cmp_z(operand2GmpValue->fraction, operand1GmpValue->integer) > 0) ? CHALK_BOOL_YES :
              CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT)
            boolResult = (mpfr_cmp_z(operand2GmpValue->realExact, operand1GmpValue->integer) > 0) ? CHALK_BOOL_YES :
              CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX)
            boolResult =
              (mpfr_cmp_z(&operand2GmpValue->realApprox->interval.left, operand1GmpValue->integer) > 0) ? CHALK_BOOL_YES :
              (mpfr_cmp_z(&operand2GmpValue->realApprox->interval.right, operand1GmpValue->integer) > 0) ? CHALK_BOOL_MAYBE :
              CHALK_BOOL_NO;
        }//end if (operand1GmpValue->type == CHALK_VALUE_TYPE_INTEGER)
        else if (operand1GmpValue->type == CHALK_VALUE_TYPE_FRACTION)
        {
          if (operand2GmpValue->type == CHALK_VALUE_TYPE_INTEGER)
            boolResult = (mpq_cmp_z(operand1GmpValue->fraction, operand2GmpValue->integer) < 0) ? CHALK_BOOL_YES : CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_FRACTION)
            boolResult = (mpq_cmp(operand1GmpValue->fraction, operand2GmpValue->fraction) < 0) ? CHALK_BOOL_YES : CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT)
            boolResult = (mpfr_cmp_q(operand2GmpValue->realExact, operand1GmpValue->fraction) > 0) ? CHALK_BOOL_YES : CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX)
            boolResult =
              (mpfr_cmp_q(&operand2GmpValue->realApprox->interval.left, operand1GmpValue->fraction) > 0) ? CHALK_BOOL_YES :
              (mpfr_cmp_q(&operand2GmpValue->realApprox->interval.right, operand1GmpValue->fraction) > 0) ? CHALK_BOOL_MAYBE :
              CHALK_BOOL_NO;
        }//end if (operand1GmpValue->type == CHALK_VALUE_TYPE_FRACTION)
        else if (operand1GmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT)
        {
          if (operand2GmpValue->type == CHALK_VALUE_TYPE_INTEGER)
            boolResult = (mpfr_cmp_z(operand1GmpValue->realExact, operand2GmpValue->integer) < 0) ? CHALK_BOOL_YES : CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_FRACTION)
            boolResult = (mpfr_cmp_q(operand1GmpValue->realExact, operand2GmpValue->fraction) < 0) ? CHALK_BOOL_YES : CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT)
            boolResult = (mpfr_cmp(operand1GmpValue->realExact, operand2GmpValue->realExact) < 0) ? CHALK_BOOL_YES : CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX)
            boolResult =
              (mpfr_cmp(&operand2GmpValue->realApprox->interval.left, operand1GmpValue->realExact) > 0) ? CHALK_BOOL_YES :
              (mpfr_cmp(&operand2GmpValue->realApprox->interval.right, operand1GmpValue->realExact) > 0) ? CHALK_BOOL_MAYBE :
              CHALK_BOOL_NO;
        }//end if (operand1GmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT)
        else if (operand1GmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX)
        {
          if (operand2GmpValue->type == CHALK_VALUE_TYPE_INTEGER)
            boolResult =
              (mpfr_cmp_z(&operand1GmpValue->realApprox->interval.right, operand2GmpValue->integer) < 0) ? CHALK_BOOL_YES :
              (mpfr_cmp_z(&operand1GmpValue->realApprox->interval.left, operand2GmpValue->integer) < 0) ? CHALK_BOOL_MAYBE :
              CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_FRACTION)
            boolResult =
              (mpfr_cmp_q(&operand1GmpValue->realApprox->interval.right, operand2GmpValue->fraction) < 0) ? CHALK_BOOL_YES :
              (mpfr_cmp_q(&operand1GmpValue->realApprox->interval.left, operand2GmpValue->fraction) < 0) ? CHALK_BOOL_MAYBE :
              CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT)
            boolResult =
              (mpfr_cmp(&operand1GmpValue->realApprox->interval.right, operand2GmpValue->realExact) < 0) ? CHALK_BOOL_YES :
              (mpfr_cmp(&operand1GmpValue->realApprox->interval.left, operand2GmpValue->realExact) < 0) ? CHALK_BOOL_MAYBE :
              CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX)
            boolResult =
              (mpfr_cmp(&operand1GmpValue->realApprox->interval.right, &operand2GmpValue->realApprox->interval.left) < 0) ? CHALK_BOOL_YES :
              (mpfr_cmp(&operand1GmpValue->realApprox->interval.left, &operand2GmpValue->realApprox->interval.right) >= 0) ? CHALK_BOOL_NO :
              CHALK_BOOL_MAYBE;
        }//end if (operand1GmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX)
        result = [[CHChalkValueBoolean alloc] initWithToken:token chalkBoolValue:boolResult context:context];
        if (!result)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                 replace:NO];
      }//if (operand1GmpValue && operand2GmpValue)
      else
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                               replace:NO];
      result.evaluationComputeFlags |=
        operand1Value.evaluationComputeFlags |
        operand2Value.evaluationComputeFlags |
        chalkGmpFlagsMake();
    }//end @autoreleasepool
  }//end if (operands.count == 2)
  return [result autorelease];
}
//end combineLow:operatorToken:context:

+(CHChalkValue*) combineLow2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = [self combine2_2:@selector(combineLow:operatorToken:context:) operands:operands operatorToken:token context:context];
  return result;
}
//end combineLow2:operatorToken:context:

+(CHChalkValue*) combineGre:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 2)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 2)
  {
    @autoreleasepool {
      CHChalkValue* operand1Value = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueNumberGmp* operand1Gmp = [operand1Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueBoolean* operand1Boolean = [operand1Value dynamicCastToClass:[CHChalkValueBoolean class]];
      const chalk_gmp_value_t* operand1GmpValue = operand1Gmp.valueConstReference;
      CHChalkValueList* operand1List = [operand1Value dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValue* operand2Value = [[operands objectAtIndex:1] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueNumberGmp* operand2Gmp = [operand2Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueBoolean* operand2Boolean = [operand2Value dynamicCastToClass:[CHChalkValueBoolean class]];
      const chalk_gmp_value_t* operand2GmpValue = operand2Gmp.valueConstReference;
      CHChalkValueList* operand2List = [operand2Value dynamicCastToClass:[CHChalkValueList class]];
      if (operand1List)
        result = [[self combineSEL:_cmd arguments:operands list:operand1List index:0 operatorToken:token context:context] retain];
      else if (operand2List)
        result = [[self combineSEL:_cmd arguments:operands list:operand2List index:1 operatorToken:token context:context] retain];
      else if (operand1Boolean && operand2Boolean)
      {
        chalk_bool_t boolResult =
          ((NSUInteger)operand1Boolean.chalkBoolValue > (NSUInteger)operand2Boolean.chalkBoolValue) ? CHALK_BOOL_YES :
          CHALK_BOOL_NO;
        result = [[CHChalkValueBoolean alloc] initWithToken:token chalkBoolValue:boolResult context:context];
        if (!result)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                 replace:NO];
      }//end if (operand1Boolean && operand2Boolean)
      else if (operand1GmpValue && operand2GmpValue)
      {
        chalk_bool_t boolResult = CHALK_BOOL_MAYBE;
        if (chalkGmpValueIsNan(operand1GmpValue) || chalkGmpValueIsNan(operand2GmpValue))
          boolResult = CHALK_BOOL_MAYBE;
        else if (operand1GmpValue->type == CHALK_VALUE_TYPE_INTEGER)
        {
          if (operand2GmpValue->type == CHALK_VALUE_TYPE_INTEGER)
            boolResult = (mpz_cmp(operand1GmpValue->integer, operand2GmpValue->integer) > 0) ? CHALK_BOOL_YES :
              CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_FRACTION)
            boolResult = (mpq_cmp_z(operand2GmpValue->fraction, operand1GmpValue->integer) < 0) ? CHALK_BOOL_YES :
              CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT)
            boolResult = (mpfr_cmp_z(operand2GmpValue->realExact, operand1GmpValue->integer) < 0) ? CHALK_BOOL_YES :
              CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX)
            boolResult =
              (mpfr_cmp_z(&operand2GmpValue->realApprox->interval.right, operand1GmpValue->integer) < 0) ? CHALK_BOOL_YES :
              (mpfr_cmp_z(&operand2GmpValue->realApprox->interval.left, operand1GmpValue->integer) < 0) ? CHALK_BOOL_MAYBE :
              CHALK_BOOL_NO;
        }//end if (operand1GmpValue->type == CHALK_VALUE_TYPE_INTEGER)
        else if (operand1GmpValue->type == CHALK_VALUE_TYPE_FRACTION)
        {
          if (operand2GmpValue->type == CHALK_VALUE_TYPE_INTEGER)
            boolResult = (mpq_cmp_z(operand1GmpValue->fraction, operand2GmpValue->integer) > 0) ? CHALK_BOOL_YES : CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_FRACTION)
            boolResult = (mpq_cmp(operand1GmpValue->fraction, operand2GmpValue->fraction) > 0) ? CHALK_BOOL_YES : CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT)
            boolResult = (mpfr_cmp_q(operand2GmpValue->realExact, operand1GmpValue->fraction) < 0) ? CHALK_BOOL_YES : CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX)
            boolResult =
              (mpfr_cmp_q(&operand2GmpValue->realApprox->interval.right, operand1GmpValue->fraction) < 0) ? CHALK_BOOL_YES :
              (mpfr_cmp_q(&operand2GmpValue->realApprox->interval.left, operand1GmpValue->fraction) < 0) ? CHALK_BOOL_MAYBE :
              CHALK_BOOL_NO;
        }//end if (operand1GmpValue->type == CHALK_VALUE_TYPE_FRACTION)
        else if (operand1GmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT)
        {
          if (operand2GmpValue->type == CHALK_VALUE_TYPE_INTEGER)
            boolResult = (mpfr_cmp_z(operand1GmpValue->realExact, operand2GmpValue->integer) > 0) ? CHALK_BOOL_YES : CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_FRACTION)
            boolResult = (mpfr_cmp_q(operand1GmpValue->realExact, operand2GmpValue->fraction) > 0) ? CHALK_BOOL_YES : CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT)
            boolResult = (mpfr_cmp(operand1GmpValue->realExact, operand2GmpValue->realExact) > 0) ? CHALK_BOOL_YES : CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX)
            boolResult =
              (mpfr_cmp(&operand2GmpValue->realApprox->interval.right, operand1GmpValue->realExact) < 0) ? CHALK_BOOL_YES :
              (mpfr_cmp(&operand2GmpValue->realApprox->interval.left, operand1GmpValue->realExact) < 0) ? CHALK_BOOL_MAYBE :
              CHALK_BOOL_NO;
        }//end if (operand1GmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT)
        else if (operand1GmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX)
        {
          if (operand2GmpValue->type == CHALK_VALUE_TYPE_INTEGER)
            boolResult =
              (mpfr_cmp_z(&operand1GmpValue->realApprox->interval.left, operand2GmpValue->integer) > 0) ? CHALK_BOOL_YES :
              (mpfr_cmp_z(&operand1GmpValue->realApprox->interval.right, operand2GmpValue->integer) > 0) ? CHALK_BOOL_MAYBE :
              CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_FRACTION)
            boolResult =
              (mpfr_cmp_q(&operand1GmpValue->realApprox->interval.left, operand2GmpValue->fraction) > 0) ? CHALK_BOOL_YES :
              (mpfr_cmp_q(&operand1GmpValue->realApprox->interval.right, operand2GmpValue->fraction) > 0) ? CHALK_BOOL_MAYBE :
              CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT)
            boolResult =
              (mpfr_cmp(&operand1GmpValue->realApprox->interval.left, operand2GmpValue->realExact) > 0) ? CHALK_BOOL_YES :
              (mpfr_cmp(&operand1GmpValue->realApprox->interval.right, operand2GmpValue->realExact) > 0) ? CHALK_BOOL_MAYBE :
              CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX)
            boolResult =
              (mpfr_cmp(&operand1GmpValue->realApprox->interval.left, &operand2GmpValue->realApprox->interval.right) > 0) ? CHALK_BOOL_YES :
              (mpfr_cmp(&operand1GmpValue->realApprox->interval.right, &operand2GmpValue->realApprox->interval.left) <= 0) ? CHALK_BOOL_NO :
              CHALK_BOOL_MAYBE;
        }//end if (operand1GmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX)
        result = [[CHChalkValueBoolean alloc] initWithToken:token chalkBoolValue:boolResult context:context];
        if (!result)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                 replace:NO];
      }//if (operand1GmpValue && operand2GmpValue)
      else
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                               replace:NO];
      result.evaluationComputeFlags |=
        operand1Value.evaluationComputeFlags |
        operand2Value.evaluationComputeFlags |
        chalkGmpFlagsMake();
    }//end @autoreleasepool
  }//end if (operands.count == 2)
  return [result autorelease];
}
//end combineGre:operatorToken:context:

+(CHChalkValue*) combineGre2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = [self combine2_2:@selector(combineGre:operatorToken:context:) operands:operands operatorToken:token context:context];
  return result;
}
//end combineGre2:operatorToken:context:

+(CHChalkValue*) combineEqu:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 2)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 2)
  {
    @autoreleasepool {
      CHChalkValue* operand1Value = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueNumberGmp* operand1Gmp = [operand1Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueBoolean* operand1Boolean = [operand1Value dynamicCastToClass:[CHChalkValueBoolean class]];
      const chalk_gmp_value_t* operand1GmpValue = operand1Gmp.valueConstReference;
      CHChalkValueList* operand1List = [operand1Value dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValue* operand2Value = [[operands objectAtIndex:1] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueNumberGmp* operand2Gmp = [operand2Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueBoolean* operand2Boolean = [operand2Value dynamicCastToClass:[CHChalkValueBoolean class]];
      const chalk_gmp_value_t* operand2GmpValue = operand2Gmp.valueConstReference;
      CHChalkValueList* operand2List = [operand2Value dynamicCastToClass:[CHChalkValueList class]];
      if (operand1List)
        result = [[self combineSEL:_cmd arguments:operands list:operand1List index:0 operatorToken:token context:context] retain];
      else if (operand2List)
        result = [[self combineSEL:_cmd arguments:operands list:operand2List index:1 operatorToken:token context:context] retain];
      else if (operand1Boolean && operand2Boolean)
      {
        chalk_bool_t boolResult =
          (operand1Boolean.chalkBoolValue == operand2Boolean.chalkBoolValue) ? CHALK_BOOL_YES :
          CHALK_BOOL_NO;
        result = [[CHChalkValueBoolean alloc] initWithToken:token chalkBoolValue:boolResult context:context];
        if (!result)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                 replace:NO];
      }//end if (operand1Boolean && operand2Boolean)
      else if (operand1GmpValue && operand2GmpValue)
      {
        chalk_bool_t boolResult = CHALK_BOOL_MAYBE;
        if (chalkGmpValueIsNan(operand1GmpValue) || chalkGmpValueIsNan(operand2GmpValue))
          boolResult = CHALK_BOOL_MAYBE;
        else if (operand1GmpValue->type == CHALK_VALUE_TYPE_INTEGER)
        {
          if (operand2GmpValue->type == CHALK_VALUE_TYPE_INTEGER)
            boolResult = (mpz_cmp(operand1GmpValue->integer, operand2GmpValue->integer) == 0) ? CHALK_BOOL_YES :
              CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_FRACTION)
            boolResult = (mpq_cmp_z(operand2GmpValue->fraction, operand1GmpValue->integer) == 0) ? CHALK_BOOL_YES :
              CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT)
            boolResult = (mpfr_cmp_z(operand2GmpValue->realExact, operand1GmpValue->integer) == 0) ? CHALK_BOOL_YES :
              CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX)
            boolResult =
              mpfir_is_inside_z(operand1GmpValue->integer, operand2GmpValue->realApprox) ? CHALK_BOOL_MAYBE :
              CHALK_BOOL_NO;
        }//end if (operand1GmpValue->type == CHALK_VALUE_TYPE_INTEGER)
        else if (operand1GmpValue->type == CHALK_VALUE_TYPE_FRACTION)
        {
          if (operand2GmpValue->type == CHALK_VALUE_TYPE_INTEGER)
            boolResult = (mpq_cmp_z(operand1GmpValue->fraction, operand2GmpValue->integer) == 0) ? CHALK_BOOL_YES : CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_FRACTION)
            boolResult = (mpq_cmp(operand1GmpValue->fraction, operand2GmpValue->fraction) == 0) ? CHALK_BOOL_YES : CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT)
            boolResult = (mpfr_cmp_q(operand2GmpValue->realExact, operand1GmpValue->fraction) == 0) ? CHALK_BOOL_YES : CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX)
            boolResult =
              mpfir_is_inside_q(operand1GmpValue->fraction, operand2GmpValue->realApprox) ? CHALK_BOOL_MAYBE :
              CHALK_BOOL_NO;
        }//end if (operand1GmpValue->type == CHALK_VALUE_TYPE_FRACTION)
        else if (operand1GmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT)
        {
          if (operand2GmpValue->type == CHALK_VALUE_TYPE_INTEGER)
            boolResult = (mpfr_cmp_z(operand1GmpValue->realExact, operand2GmpValue->integer) == 0) ? CHALK_BOOL_YES : CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_FRACTION)
            boolResult = (mpfr_cmp_q(operand1GmpValue->realExact, operand2GmpValue->fraction) == 0) ? CHALK_BOOL_YES : CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT)
            boolResult = (mpfr_cmp(operand1GmpValue->realExact, operand2GmpValue->realExact) == 0) ? CHALK_BOOL_YES : CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX)
            boolResult =
              mpfir_is_inside_fr(operand1GmpValue->realExact, operand2GmpValue->realApprox) ? CHALK_BOOL_MAYBE :
              CHALK_BOOL_NO;
        }//end if (operand1GmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT)
        else if (operand1GmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX)
        {
          if (operand2GmpValue->type == CHALK_VALUE_TYPE_INTEGER)
            boolResult = mpfir_is_inside_z(operand2GmpValue->integer, operand1GmpValue->realApprox) ? CHALK_BOOL_MAYBE :
              CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_FRACTION)
            boolResult = mpfir_is_inside_q(operand2GmpValue->fraction, operand1GmpValue->realApprox) ? CHALK_BOOL_MAYBE :
              CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT)
            boolResult = mpfir_is_inside_fr(operand2GmpValue->realExact, operand1GmpValue->realApprox) ? CHALK_BOOL_MAYBE :
              CHALK_BOOL_NO;
          else if (operand2GmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX)
            boolResult = !mpfir_cmp(operand1GmpValue->realApprox, operand2GmpValue->realApprox) ? CHALK_BOOL_MAYBE :
              CHALK_BOOL_NO;
        }//end if (operand1GmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX)
        result = [[CHChalkValueBoolean alloc] initWithToken:token chalkBoolValue:boolResult context:context];
        if (!result)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                 replace:NO];
      }//if (operand1GmpValue && operand2GmpValue)
      else
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                               replace:NO];
      result.evaluationComputeFlags |=
        operand1Value.evaluationComputeFlags |
        operand2Value.evaluationComputeFlags |
        chalkGmpFlagsMake();
    }//end @autoreleasepool
  }//end if (operands.count == 2)
  return [result autorelease];
}
//end combineEqu:operatorToken:context:

+(CHChalkValue*) combineEqu2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = [self combine2_2:@selector(combineEqu:operatorToken:context:) operands:operands operatorToken:token context:context];
  return result;
}
//end combineEqu2:operatorToken:context:

+(CHChalkValue*) combineNeq:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 2)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 2)
  {
    CHChalkValue* equResult = [[self class] combineEqu:operands operatorToken:token context:context];
    CHChalkValueBoolean* equResultBoolean = [equResult dynamicCastToClass:[CHChalkValueBoolean class]];
    [equResultBoolean logicalNot];
    result = [equResultBoolean retain];
  }//end if (operands.count == 2)
  return [result autorelease];
}
//end combineNeq:operatorToken:context:

+(CHChalkValue*) combineNeq2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = [self combine2_2:@selector(combineNeq:operatorToken:context:) operands:operands operatorToken:token context:context];
  return result;
}
//end combineNeq2:operatorToken:context:

+(CHChalkValue*) combineAnd:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count < 2)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count >= 2)
  {
    if (operands.count == 2)
    {
      CHChalkValue* operand1Value = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueList* operand1List = [operand1Value dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValue* operand2Value = [[operands objectAtIndex:1] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueList* operand2List = [operand2Value dynamicCastToClass:[CHChalkValueList class]];
      if (!operand1Value || !operand2Value)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                               replace:NO];
      else if (operand2List)
        result = [[self combineSEL:_cmd  arguments:operands list:operand2List index:1 operatorToken:token context:context] retain];
      else if (operand1List)
        result = [[self combineSEL:_cmd  arguments:operands list:operand1List index:0 operatorToken:token context:context] retain];
    }//end if (operands.count == 2)
    if (!result && !context.errorContext.hasError)
    {
      __block chalk_bool_t currentValue = CHALK_BOOL_NO;
      __block chalk_compute_flags_t computeFlags = 0;
      __block BOOL operandsAreAllBooleans = YES;
      [operands enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CHChalkValueBoolean* operandBoolean = [obj dynamicCastToClass:[CHChalkValueBoolean class]];
        operandsAreAllBooleans &= (operandBoolean != nil);
        if (!operandsAreAllBooleans)
          *stop = YES;
      }];//end for each operand
      
      if (operandsAreAllBooleans)
      {
        [operands enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
          CHChalkValue* operand = [obj dynamicCastToClass:[CHChalkValue class]];
          CHChalkValueBoolean* operandBoolean = [obj dynamicCastToClass:[CHChalkValueBoolean class]];
          if (!operand)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                   replace:NO];
          if (!operandBoolean)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                                   replace:NO];
          else if (!idx)
            currentValue = operandBoolean.chalkBoolValue;
          else//if (idx>0)
            currentValue = chalkBoolAnd(currentValue, operandBoolean.chalkBoolValue);
          if (context.errorContext.hasError)
            *stop = YES;
          @synchronized(self) {
            computeFlags |=
              operand.evaluationComputeFlags |
              chalkGmpFlagsMake();
          }//end @synchronized(self)
        }];//end for each operand
        result = [[CHChalkValueBoolean alloc] initWithToken:token chalkBoolValue:currentValue context:context];
        [result autorelease];
      }//end if (operandsAreAllBooleans)
      else if (!operandsAreAllBooleans)
      {
        __block CHChalkValue* currentValue = nil;
        [operands enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
          CHChalkValue* operand = [obj dynamicCastToClass:[CHChalkValue class]];
          CHChalkValueNumberGmp* operandGmp = [obj dynamicCastToClass:[CHChalkValueNumberGmp class]];
          CHChalkValueFormal* operandFormal = [obj dynamicCastToClass:[CHChalkValueFormal class]];
          operandGmp = !operandFormal ? operandGmp : operandFormal.value;
          CHChalkValueNumberRaw* operandRaw = [obj dynamicCastToClass:[CHChalkValueNumberRaw class]];
          const chalk_gmp_value_t* gmpValue = operandGmp.valueConstReference;
          const chalk_raw_value_t* rawValue = operandRaw.valueConstReference;
          mpz_srcptr gmpValueZ = !gmpValue || (gmpValue->type != CHALK_VALUE_TYPE_INTEGER) ? 0 : gmpValue->integer;
          mpz_srcptr rawValueZ = !rawValue ? 0 : rawValue->bits;
          if (!gmpValueZ && !rawValueZ)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorOperationNonImplemented range:token.range]
                                   replace:NO];
          else if (!idx)
          {
            currentValue = [operand copy];
            //[currentValue.token unionWithToken:token];//experimental
          }//end if (!idx)
          else//if (idx>0)
          {
            //[currentValue.token unionWithToken:operand.token];//experimental
            CHChalkValueNumberGmp* dstGmp = [currentValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
            CHChalkValueNumberRaw* dstRaw = [currentValue dynamicCastToClass:[CHChalkValueNumberRaw class]];
            chalk_gmp_value_t* dstGmpValue = dstGmp.valueReference;
            chalk_raw_value_t* dstRawValue = dstRaw.valueReference;
            mpz_ptr dstGmpValueZ = !dstGmpValue || (dstGmpValue->type != CHALK_VALUE_TYPE_INTEGER) ? 0 : dstGmpValue->integer;
            mpz_ptr dstRawValueZ = !dstRawValue ? 0 : dstRawValue->bits;
            if (dstGmpValueZ && gmpValueZ)
              mpz_and(dstGmpValueZ, dstGmpValueZ, gmpValueZ);
            else if (dstGmpValueZ && rawValueZ)
              mpz_and(dstGmpValueZ, dstGmpValueZ, rawValueZ);
            else if (dstRawValueZ && gmpValueZ &&
                     (getTotalBitsCountForBitInterpretation(&dstRawValue->bitInterpretation) == mpz_sizeinbase(gmpValueZ, 2)))
              mpz_and(dstRawValueZ, dstRawValueZ, gmpValueZ);
            else if (dstRawValueZ && rawValueZ &&
                     (getTotalBitsCountForBitInterpretation(&dstRawValue->bitInterpretation) == getTotalBitsCountForBitInterpretation(&rawValue->bitInterpretation)))
              mpz_and(dstRawValueZ, dstRawValueZ, rawValueZ);
            else
              [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorDimensionsMismatch range:token.range]
                                     replace:NO];
          }//end if (idx>0)
          if (context.errorContext.hasError)
            *stop = YES;
          @synchronized(self) {
            computeFlags |=
              operand.evaluationComputeFlags |
              chalkGmpFlagsMake();
          }//end @synchronized(self)
        }];//end for each operand
        result = [currentValue autorelease];
      }//end if (!operandsAreAllBooleans)
    }//end if (!result && !context.errorContext.hasError)
  }//end if (operands.count >= 2)
  return result;
}
//end combineAnd:operatorToken:context:

+(CHChalkValue*) combineAnd2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = [self combine2_2:@selector(combineAnd:operatorToken:context:) operands:operands operatorToken:token context:context];
  return result;
}
//end combineAnd2:operatorToken:context:

+(CHChalkValue*) combineOr:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count < 2)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count >= 2)
  {
    if (operands.count == 2)
    {
      CHChalkValue* operand1Value = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueList* operand1List = [operand1Value dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValue* operand2Value = [[operands objectAtIndex:1] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueList* operand2List = [operand2Value dynamicCastToClass:[CHChalkValueList class]];
      if (!operand1Value || !operand2Value)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                               replace:NO];
      else if (operand2List)
        result = [[self combineSEL:_cmd  arguments:operands list:operand2List index:1 operatorToken:token context:context] retain];
      else if (operand1List)
        result = [[self combineSEL:_cmd  arguments:operands list:operand1List index:0 operatorToken:token context:context] retain];
    }//end if (operands.count == 2)
    if (!result && !context.errorContext.hasError)
    {
      __block chalk_bool_t currentValue = CHALK_BOOL_NO;
      __block chalk_compute_flags_t computeFlags = 0;
      __block BOOL operandsAreAllBooleans = YES;
      [operands enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CHChalkValueBoolean* operandBoolean = [obj dynamicCastToClass:[CHChalkValueBoolean class]];
        operandsAreAllBooleans &= (operandBoolean != nil);
        if (!operandsAreAllBooleans)
          *stop = YES;
      }];//end for each operand
      
      if (operandsAreAllBooleans)
      {
        [operands enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
          CHChalkValue* operand = [obj dynamicCastToClass:[CHChalkValue class]];
          CHChalkValueBoolean* operandBoolean = [obj dynamicCastToClass:[CHChalkValueBoolean class]];
          if (!operand)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                   replace:NO];
          if (!operandBoolean)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                                   replace:NO];
          else if (!idx)
            currentValue = operandBoolean.chalkBoolValue;
          else//if (idx>0)
            currentValue = chalkBoolOr(currentValue, operandBoolean.chalkBoolValue);
          if (context.errorContext.hasError)
            *stop = YES;
          @synchronized(self) {
            computeFlags |=
              operand.evaluationComputeFlags |
              chalkGmpFlagsMake();
          }//end @synchronized(self)
        }];//end for each operand
        result = [[CHChalkValueBoolean alloc] initWithToken:token chalkBoolValue:currentValue context:context];
        [result autorelease];
      }//end if (operandsAreAllBooleans)
      else if (!operandsAreAllBooleans)
      {
        __block CHChalkValue* currentValue = nil;
        [operands enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
          CHChalkValue* operand = [obj dynamicCastToClass:[CHChalkValue class]];
          CHChalkValueNumberGmp* operandGmp = [obj dynamicCastToClass:[CHChalkValueNumberGmp class]];
          CHChalkValueFormal* operandFormal = [obj dynamicCastToClass:[CHChalkValueFormal class]];
          operandGmp = !operandFormal ? operandGmp : operandFormal.value;
          CHChalkValueNumberRaw* operandRaw = [obj dynamicCastToClass:[CHChalkValueNumberRaw class]];
          const chalk_gmp_value_t* gmpValue = operandGmp.valueConstReference;
          const chalk_raw_value_t* rawValue = operandRaw.valueConstReference;
          mpz_srcptr gmpValueZ = !gmpValue || (gmpValue->type != CHALK_VALUE_TYPE_INTEGER) ? 0 : gmpValue->integer;
          mpz_srcptr rawValueZ = !rawValue ? 0 : rawValue->bits;
          if (!gmpValueZ && !rawValueZ)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                   replace:NO];
          else if (!idx)
          {
            currentValue = [operand copy];
            //[currentValue.token unionWithToken:token];//experimental
          }//end if (!idx)
          else//if (idx>0)
          {
            //[currentValue.token unionWithToken:operand.token];//experimental
            CHChalkValueNumberGmp* dstGmp = [currentValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
            CHChalkValueNumberRaw* dstRaw = [currentValue dynamicCastToClass:[CHChalkValueNumberRaw class]];
            chalk_gmp_value_t* dstGmpValue = dstGmp.valueReference;
            chalk_raw_value_t* dstRawValue = dstRaw.valueReference;
            mpz_ptr dstGmpValueZ = !dstGmpValue || (dstGmpValue->type != CHALK_VALUE_TYPE_INTEGER) ? 0 : dstGmpValue->integer;
            mpz_ptr dstRawValueZ = !dstRawValue ? 0 : dstRawValue->bits;
            if (dstGmpValueZ && gmpValueZ)
              mpz_ior(dstGmpValueZ, dstGmpValueZ, gmpValueZ);
            else if (dstGmpValueZ && rawValueZ)
              mpz_ior(dstGmpValueZ, dstGmpValueZ, rawValueZ);
            else if (dstRawValueZ && gmpValueZ &&
                     (getTotalBitsCountForBitInterpretation(&dstRawValue->bitInterpretation) == mpz_sizeinbase(gmpValueZ, 2)))
              mpz_ior(dstRawValueZ, dstRawValueZ, gmpValueZ);
            else if (dstRawValueZ && rawValueZ &&
                     (getTotalBitsCountForBitInterpretation(&dstRawValue->bitInterpretation) == getTotalBitsCountForBitInterpretation(&rawValue->bitInterpretation)))
              mpz_ior(dstRawValueZ, dstRawValueZ, rawValueZ);
            else
              [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorDimensionsMismatch range:token.range]
                                     replace:NO];
          }//end if (idx>0)
          if (context.errorContext.hasError)
            *stop = YES;
          @synchronized(self) {
            computeFlags |=
              operand.evaluationComputeFlags |
              chalkGmpFlagsMake();
          }//end @synchronized(self)
        }];//end for each operand
        result = [currentValue autorelease];
      }//end if (!operandsAreAllBooleans)
    }//end if (!result && !context.errorContext.hasError)
  }//end if (operands.count >= 2)
  return result;
}
//end combineOr:operatorToken:context:

+(CHChalkValue*) combineOr2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = [self combine2_2:@selector(combineOr:operatorToken:context:) operands:operands operatorToken:token context:context];
  return result;
}
//end combineOr2:operatorToken:context:

+(CHChalkValue*) combineXor:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count < 2)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count >= 2)
  {
    if (operands.count == 2)
    {
      CHChalkValue* operand1Value = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueList* operand1List = [operand1Value dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValue* operand2Value = [[operands objectAtIndex:1] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueList* operand2List = [operand2Value dynamicCastToClass:[CHChalkValueList class]];
      if (!operand1Value || !operand2Value)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                               replace:NO];
      else if (operand2List)
        result = [[self combineSEL:_cmd  arguments:operands list:operand2List index:1 operatorToken:token context:context] retain];
      else if (operand1List)
        result = [[self combineSEL:_cmd  arguments:operands list:operand1List index:0 operatorToken:token context:context] retain];
    }//end if (operands.count == 2)
    if (!result && !context.errorContext.hasError)
    {
      __block chalk_bool_t currentValue = CHALK_BOOL_NO;
      __block chalk_compute_flags_t computeFlags = 0;
      __block BOOL operandsAreAllBooleans = YES;
      [operands enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CHChalkValueBoolean* operandBoolean = [obj dynamicCastToClass:[CHChalkValueBoolean class]];
        operandsAreAllBooleans &= (operandBoolean != nil);
        if (!operandsAreAllBooleans)
          *stop = YES;
      }];//end for each operand
      
      if (operandsAreAllBooleans)
      {
        [operands enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
          CHChalkValue* operand = [obj dynamicCastToClass:[CHChalkValue class]];
          CHChalkValueBoolean* operandBoolean = [obj dynamicCastToClass:[CHChalkValueBoolean class]];
          if (!operand)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                   replace:NO];
          if (!operandBoolean)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                                   replace:NO];
          else if (!idx)
            currentValue = operandBoolean.chalkBoolValue;
          else//if (idx>0)
            currentValue = chalkBoolXor(currentValue, operandBoolean.chalkBoolValue);
          if (context.errorContext.hasError)
            *stop = YES;
          @synchronized(self) {
            computeFlags |=
              operand.evaluationComputeFlags |
              chalkGmpFlagsMake();
          }//end @synchronized(self)
        }];//end for each operand
        result = [[CHChalkValueBoolean alloc] initWithToken:token chalkBoolValue:currentValue context:context];
        [result autorelease];
      }//end if (operandsAreAllBooleans)
      else if (!operandsAreAllBooleans)
      {
        __block CHChalkValue* currentValue = nil;
        [operands enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
          CHChalkValue* operand = [obj dynamicCastToClass:[CHChalkValue class]];
          CHChalkValueNumberGmp* operandGmp = [obj dynamicCastToClass:[CHChalkValueNumberGmp class]];
          CHChalkValueFormal* operandFormal = [obj dynamicCastToClass:[CHChalkValueFormal class]];
          operandGmp = !operandFormal ? operandGmp : operandFormal.value;
          CHChalkValueNumberRaw* operandRaw = [obj dynamicCastToClass:[CHChalkValueNumberRaw class]];
          const chalk_gmp_value_t* gmpValue = operandGmp.valueConstReference;
          const chalk_raw_value_t* rawValue = operandRaw.valueConstReference;
          mpz_srcptr gmpValueZ = !gmpValue || (gmpValue->type != CHALK_VALUE_TYPE_INTEGER) ? 0 : gmpValue->integer;
          mpz_srcptr rawValueZ = !rawValue ? 0 : rawValue->bits;
          if (!gmpValueZ && !rawValueZ)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                   replace:NO];
          else if (!idx)
          {
            currentValue = [operand copy];
            //[currentValue.token unionWithToken:token];//experimental
          }//end if (!idx)
          else//if (idx>0)
          {
            //[currentValue.token unionWithToken:operand.token];//experimental
            CHChalkValueNumberGmp* dstGmp = [currentValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
            CHChalkValueNumberRaw* dstRaw = [currentValue dynamicCastToClass:[CHChalkValueNumberRaw class]];
            chalk_gmp_value_t* dstGmpValue = dstGmp.valueReference;
            chalk_raw_value_t* dstRawValue = dstRaw.valueReference;
            mpz_ptr dstGmpValueZ = !dstGmpValue || (dstGmpValue->type != CHALK_VALUE_TYPE_INTEGER) ? 0 : dstGmpValue->integer;
            mpz_ptr dstRawValueZ = !dstRawValue ? 0 : dstRawValue->bits;
            if (dstGmpValueZ && gmpValueZ)
              mpz_xor(dstGmpValueZ, dstGmpValueZ, gmpValueZ);
            else if (dstGmpValueZ && rawValueZ)
              mpz_xor(dstGmpValueZ, dstGmpValueZ, rawValueZ);
            else if (dstRawValueZ && gmpValueZ &&
                     (getTotalBitsCountForBitInterpretation(&dstRawValue->bitInterpretation) == mpz_sizeinbase(gmpValueZ, 2)))
              mpz_xor(dstRawValueZ, dstRawValueZ, gmpValueZ);
            else if (dstRawValueZ && rawValueZ &&
                     (getTotalBitsCountForBitInterpretation(&dstRawValue->bitInterpretation) == getTotalBitsCountForBitInterpretation(&rawValue->bitInterpretation)))
              mpz_xor(dstRawValueZ, dstRawValueZ, rawValueZ);
            else
              [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorDimensionsMismatch range:token.range]
                                     replace:NO];
          }//end if (idx>0)
          if (context.errorContext.hasError)
            *stop = YES;
          @synchronized(self) {
            computeFlags |=
              operand.evaluationComputeFlags |
              chalkGmpFlagsMake();
          }//end @synchronized(self)
        }];//end for each operand
        result = [currentValue autorelease];
      }//end if (!operandsAreAllBooleans)
    }//end if (!result && !context.errorContext.hasError)
  }//end if (operands.count >= 2)
  return result;
}
//end combineXor:operatorToken:context:

+(CHChalkValue*) combineXor2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = [self combine2_2:@selector(combineXor:operatorToken:context:) operands:operands operatorToken:token context:context];
  return result;
}
//end combineXor2:operatorToken:context:

+(CHChalkValue*) combineShl:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 2)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 2)
  {
    CHChalkValue* operand1Value = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
    CHChalkValueList* operand1List = [operand1Value dynamicCastToClass:[CHChalkValueList class]];

    CHChalkValue* operand2Value = [[operands objectAtIndex:1] dynamicCastToClass:[CHChalkValue class]];
    CHChalkValueList* operand2List = [operand2Value dynamicCastToClass:[CHChalkValueList class]];
    CHChalkValueNumberGmp* operand1Gmp = [operand1Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
    CHChalkValueNumberGmp* operand2Gmp = [operand2Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
    CHChalkValueNumberRaw* operand1Raw = [operand1Value dynamicCastToClass:[CHChalkValueNumberRaw class]];
    CHChalkValueNumberRaw* operand2Raw = [operand2Value dynamicCastToClass:[CHChalkValueNumberRaw class]];
    if (operand2Raw)
      operand2Gmp = [operand2Raw convertToGmpValueWithContext:context];
    const chalk_gmp_value_t* operand1GmpValue = operand1Gmp.valueConstReference;
    const chalk_gmp_value_t* operand2GmpValue = operand2Gmp.valueConstReference;
    if (!operand1Value || !operand2Value)
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                             replace:NO];
    else if (operand2List)
      result = [[self combineSEL:_cmd  arguments:operands list:operand2List index:1 operatorToken:token context:context] retain];
    else if (operand1List)
      result = [[self combineSEL:_cmd  arguments:operands list:operand1List index:0 operatorToken:token context:context] retain];
    else if (((operand1GmpValue && (operand1GmpValue->type == CHALK_VALUE_TYPE_INTEGER)) || operand1Raw) && operand2GmpValue)
    {
      if (operand2GmpValue->type != CHALK_VALUE_TYPE_INTEGER)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                               replace:NO];
      else//if (operand2GmpValue->type == CHALK_VALUE_TYPE_INTEGER)
      {
        if (!mpz_fits_nsui_p(operand2GmpValue->integer))
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorIntegerOverflow range:token.range]
                                 replace:NO];
        else//if (mpz_fits_nsui_p(operand2GmpValue->integer))
        {
          NSUInteger shiftValue = mpz_get_nsui(operand2GmpValue->integer);
          result = [[operand1Value copy] autorelease];
          CHChalkValueNumberGmp* resultGmp = [result dynamicCastToClass:[CHChalkValueNumberGmp class]];
          CHChalkValueNumberRaw* resultRaw = [result dynamicCastToClass:[CHChalkValueNumberRaw class]];
          chalk_gmp_value_t* resultGmpValue = resultGmp.valueReference;
          chalk_raw_value_t* resultRawValue = resultRaw.valueReference;
          if (!result)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                   replace:NO];
          else if (resultGmpValue && (resultGmpValue->type == CHALK_VALUE_TYPE_INTEGER))
            mpz_mul_2exp(resultGmpValue->integer, resultGmpValue->integer, shiftValue);
          else if (resultRawValue)
            mpz_shift_left(resultRawValue->bits, shiftValue, getTotalBitsRangeForBitInterpretation(&resultRawValue->bitInterpretation));
          else
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                                   replace:NO];
        }//end if (mpz_fits_nsui_p(operand2GmpValue->integer))
      }//end if (((operand1GmpValue && (operand1GmpValue->type == CHALK_VALUE_TYPE_INTEGER)) || operand1Raw) && operand2GmpValue)
    }//end if ((operand1Gmp || operand1Raw) && operand2GmpValue)
    else//if ((!operand1Gmp && !operand1Raw) || !operand2GmpValue)
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                             replace:NO];
  }//end if (operands.count == 2)
  return result;
}
//end combineShl:operatorToken:context:

+(CHChalkValue*) combineShl2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = [self combine2_2:@selector(combineShl2:operatorToken:context:) operands:operands operatorToken:token context:context];
  return result;
}
//end combineShl2:operatorToken:context:

+(CHChalkValue*) combineShr:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 2)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 2)
  {
    CHChalkValue* operand1Value = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
    CHChalkValueList* operand1List = [operand1Value dynamicCastToClass:[CHChalkValueList class]];

    CHChalkValue* operand2Value = [[operands objectAtIndex:1] dynamicCastToClass:[CHChalkValue class]];
    CHChalkValueList* operand2List = [operand2Value dynamicCastToClass:[CHChalkValueList class]];
    CHChalkValueNumberGmp* operand1Gmp = [operand1Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
    CHChalkValueNumberGmp* operand2Gmp = [operand2Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
    CHChalkValueNumberRaw* operand1Raw = [operand1Value dynamicCastToClass:[CHChalkValueNumberRaw class]];
    CHChalkValueNumberRaw* operand2Raw = [operand2Value dynamicCastToClass:[CHChalkValueNumberRaw class]];
    if (operand2Raw)
      operand2Gmp = [operand2Raw convertToGmpValueWithContext:context];
    const chalk_gmp_value_t* operand1GmpValue = operand1Gmp.valueConstReference;
    const chalk_gmp_value_t* operand2GmpValue = operand2Gmp.valueConstReference;
    if (!operand1Value || !operand2Value)
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                             replace:NO];
    else if (operand2List)
      result = [[self combineSEL:_cmd  arguments:operands list:operand2List index:1 operatorToken:token context:context] retain];
    else if (operand1List)
      result = [[self combineSEL:_cmd  arguments:operands list:operand1List index:0 operatorToken:token context:context] retain];
    else if (((operand1GmpValue && (operand1GmpValue->type == CHALK_VALUE_TYPE_INTEGER)) || operand1Raw) && operand2GmpValue)
    {
      if (operand2GmpValue->type != CHALK_VALUE_TYPE_INTEGER)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                               replace:NO];
      else//if (operand2GmpValue->type == CHALK_VALUE_TYPE_INTEGER)
      {
        if (!mpz_fits_nsui_p(operand2GmpValue->integer))
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorIntegerOverflow range:token.range]
                                 replace:NO];
        else//if (mpz_fits_nsui_p(operand2GmpValue->integer))
        {
          NSUInteger shiftValue = mpz_get_nsui(operand2GmpValue->integer);
          result = [[operand1Value copy] autorelease];
          CHChalkValueNumberGmp* resultGmp = [result dynamicCastToClass:[CHChalkValueNumberGmp class]];
          CHChalkValueNumberRaw* resultRaw = [result dynamicCastToClass:[CHChalkValueNumberRaw class]];
          chalk_gmp_value_t* resultGmpValue = resultGmp.valueReference;
          chalk_raw_value_t* resultRawValue = resultRaw.valueReference;
          if (!result)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                   replace:NO];
          else if (resultGmpValue && (resultGmpValue->type == CHALK_VALUE_TYPE_INTEGER))
            mpz_div_2exp(resultGmpValue->integer, resultGmpValue->integer, shiftValue);
          else if (resultRawValue)
            mpz_shift_right(resultRawValue->bits, shiftValue, getTotalBitsRangeForBitInterpretation(&resultRawValue->bitInterpretation));
          else
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                                   replace:NO];
        }//end if (mpz_fits_nsui_p(operand2GmpValue->integer))
      }//end if (((operand1GmpValue && (operand1GmpValue->type == CHALK_VALUE_TYPE_INTEGER)) || operand1Raw) && operand2GmpValue)
    }//end if ((operand1Gmp || operand1Raw) && operand2GmpValue)
    else//if ((!operand1Gmp && !operand1Raw) || !operand2GmpValue)
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                             replace:NO];
  }//end if (operands.count == 2)
  return result;
}
//end combineShr:operatorToken:context:

+(CHChalkValue*) combineShr2:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = [self combine2_2:@selector(combineShr2:operatorToken:context:) operands:operands operatorToken:token context:context];
  return result;
}
//end combineShr2:operatorToken:context:

+(CHChalkValue*) combineSubscript:(NSArray*)operands operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 2)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 2)
  {
    id srcOp = [operands objectAtIndex:0];
    id subscriptOp = [operands objectAtIndex:1];
    id<CHChalkValueSubscriptable> srcSubscriptable = [srcOp dynamicCastToProtocol:@protocol(CHChalkValueSubscriptable)];
    CHChalkValueSubscript* subscript = [subscriptOp dynamicCastToClass:[CHChalkValueSubscript class]];
    if (!srcSubscriptable || !subscript)
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                             replace:NO];
    else//if (srcSubscriptable && subscript)
    {
      result = [[[srcSubscriptable valueAtSubscript:subscript context:context] copy] autorelease];
      if (!result)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                               replace:NO];
    }//end if (srcSubscriptable && subscript)
  }//end if (operands.count == 2)
  return result;
}
//end combineSubscript:operatorToken:context:

+(BOOL) addIntegers:(mpz_ptr)rop op1:(mpz_srcptr)op1 op2:(mpz_srcptr)op2 operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  BOOL result = NO;
  int sign1 = mpz_sgn(op1);
  int sign2 = mpz_sgn(op2);
  if (!sign1 || !sign2)
  {
    mpz_add(rop, op1, op2);
    result = YES;
  }//end if (!sign1 || !sign2)
  else//if (sign1 && sign2)
  {
    NSUInteger nbBitsMax = context.computationConfiguration.softIntegerMaxBits;
    NSUInteger nbBits1 = mpz_sizeinbase(op1, 2);
    NSUInteger nbBits2 = mpz_sizeinbase(op2, 2);

    BOOL overflowCertain =
      (nbBits1 > nbBitsMax) ||
      (nbBits2 > nbBitsMax) ||
      ((sign1 == sign2) && (nbBits1 == nbBitsMax) && (nbBits2 == nbBitsMax));
    if (!overflowCertain)
    {
      mpz_add(rop, op1, op2);
      result = [CHChalkValueNumberGmp checkInteger:rop token:token setError:YES context:context];
    }//end if (overflowCertain)
  }//end if (sign1 && sign2)
  return result;
}
//end addIntegers:op1:op2:operatorToken:context:

+(BOOL) subIntegers:(mpz_ptr)rop op1:(mpz_srcptr)op1 op2:(mpz_srcptr)op2 operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  BOOL result = NO;
  int sign1 = mpz_sgn(op1);
  int sign2 = mpz_sgn(op2);
  if (!sign1 || !sign2)
  {
    mpz_sub(rop, op1, op2);
    result = YES;
  }//end if (!sign1 || !sign2)
  else//if (sign1 && sign2)
  {
    NSUInteger nbBitsMax = context.computationConfiguration.softIntegerMaxBits;
    NSUInteger nbBits1 = mpz_sizeinbase(op1, 2);
    NSUInteger nbBits2 = mpz_sizeinbase(op2, 2);
    BOOL overflowCertain =
      (nbBits1 > nbBitsMax) ||
      (nbBits2 > nbBitsMax) ||
      ((sign1 == -sign2) && (nbBits1 == nbBitsMax) && (nbBits2 == nbBitsMax));
    if (!overflowCertain)
    {
      mpz_sub(rop, op1, op2);
      result = [CHChalkValueNumberGmp checkInteger:rop token:token setError:YES context:context];
    }//end if (overflowCertain)
  }//end if (sign1 && sign2)
  return result;
}
//end subIntegers:op1:op2:operatorToken:context:

+(BOOL) mulIntegers:(mpz_ptr)rop op1:(mpz_srcptr)op1 op2:(mpz_srcptr)op2 operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  BOOL result = NO;
  int sign1 = mpz_sgn(op1);
  int sign2 = mpz_sgn(op2);
  if (!sign1 || !sign2)
  {
    mpz_mul(rop, op1, op2);
    result = YES;
  }//end if (!sign1 || !sign2)
  else//if (sign1 && sign2)
  {
    NSUInteger nbBitsMax = context.computationConfiguration.softIntegerMaxBits;
    NSUInteger nbBits1 = mpz_sizeinbase(op1, 2);
    NSUInteger nbBits2 = mpz_sizeinbase(op2, 2);
    BOOL overflowCertain =
      (nbBits1 > nbBitsMax) ||
      (nbBits2 > nbBitsMax) ||
      (sign1 && sign2 && (nbBits1+nbBits2 > nbBitsMax));
    if (!overflowCertain)
    {
      mpz_mul(rop, op1, op2);
      result = [CHChalkValueNumberGmp checkInteger:rop token:token setError:YES context:context];
    }//end if (overflowCertain)
  }//end if (sign1 && sign2)
  return result;
}
//end mulIntegers:op1:op2:operatorToken:context:

+(BOOL) divIntegers:(mpz_ptr)rop op1:(mpz_srcptr)op1 op2:(mpz_srcptr)op2 operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  BOOL result = NO;
  if (mpz_divisible_p(op1, op2))
  {
    mpz_divexact(rop, op1, op2);
    result = YES;
  }//end if (mpz_divisible_p(op1, op2))
  return result;
}
//end divIntegers:op1:op2:operatorToken:context:

+(BOOL) factorialIntegers:(mpz_ptr)rop op1:(mpz_srcptr)op1 operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  BOOL result = NO;
  int sign1 = mpz_sgn(op1);
  if (!sign1)
  {
    mpz_set_ui(rop, 0);
    result = YES;
  }//end if (!sign1)
  else if (sign1<0)
  {
    if (!context.computationConfiguration.propagateNaN)
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericInvalid range:token.range]
                             replace:NO];
    result = NO;
  }//end if (!sign1)
  else//if (sign1>0)
  {
    NSUInteger nbBitsMax = context.computationConfiguration.softIntegerMaxBits;
    NSUInteger nbBits1 = mpz_sizeinbase(op1, 2);
    BOOL overflowCertain = !mpz_fits_uint_p(op1) || (nbBits1 >= nbBitsMax/2);
    if (!overflowCertain)
    {
      mpz_fac_ui(rop, mpz_get_ui(op1));
      result = [CHChalkValueNumberGmp checkInteger:rop token:token setError:YES context:context];
    }//end if (overflowCertain)
  }//end if (sign1>0)
  return result;
}
//end factorialIntegers:op1:op2:operatorToken:context:

@end
