//
//  CHParserFunctionNode.m
//  Chalk
//
//  Created by Pierre Chatelier on 13/02/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHParserFunctionNode.h"

#import "CHChalkContext.h"
#import "CHChalkError.h"
#import "CHChalkErrorContext.h"
#import "CHChalkErrorURLContent.h"
#import "CHChalkIdentifier.h"
#import "CHChalkIdentifierConstant.h"
#import "CHChalkIdentifierFunction.h"
#import "CHChalkIdentifierManager.h"
#import "CHChalkIdentifierVariable.h"
#import "CHChalkToken.h"
#import "CHChalkUtils.h"
#import "CHChalkValue.h"
#import "CHChalkValueBoolean.h"
#import "CHChalkValueFormalSimple.h"
#import "CHChalkValueEnumeration.h"
#import "CHChalkValueList.h"
#import "CHChalkValueMatrix.h"
#import "CHChalkValueNumberGmp.h"
#import "CHChalkValueNumberRaw.h"
#import "CHChalkValueParser.h"
#import "CHChalkValueQuaternion.h"
#import "CHChalkValueScalar.h"
#import "CHChalkValueString.h"
#import "CHChalkValueURL.h"
#import "CHChalkValueURLInput.h"
#import "CHChalkValueURLOutput.h"
#import "CHComputationConfiguration.h"
#import "CHComputationEntryEntity.h"
#import "CHComputedValueEntity.h"
#import "CHParser.h"
#import "CHParserContext.h"
#import "CHParserIdentifierNode.h"
#import "CHParserEnumerationNode.h"
#import "CHParserOperatorNode.h"
#import "CHParserValueNode.h"
#import "CHPresentationConfiguration.h"
#import "CHPrimesManager.h"
#import "CHStreamWrapper.h"
#import "CHUtils.h"

#import "NSMutableArrayExtended.h"
#import "NSObjectExtended.h"
#import "NSStringExtended.h"
#import "NSString+HTML.h"
#import "NSURLExtended.h"

@interface CHParserFunctionNode()
+(CHChalkValueMatrix*) combineMatrixSEL:(SEL)selector operand:(CHChalkValueMatrix*)operandMatrix token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValueList*) combineSEL:(SEL)selector arguments:(NSArray*)arguments list:(CHChalkValueList*)list index:(NSUInteger)index token:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) combineToRawValue:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context;
@end

@implementation CHParserFunctionNode

@dynamic identifier;
@synthesize argumentNames;

-(void) dealloc
{
  [self->cachedIdentifier release];
  self.argumentNames = nil;
  [super dealloc];
}
//end dealloc

-(id) copyWithZone:(NSZone*)zone
{
  CHParserFunctionNode* result = (CHParserFunctionNode*)[super copyWithZone:zone];
  if (result)
    result->cachedIdentifier = [self->cachedIdentifier retain];
  return result;
}
//end copyWithZone:

-(CHChalkIdentifier*) identifier
{
  return [[self->cachedIdentifier retain] autorelease];
}
//end identifier

-(CHChalkIdentifier*) identifierWithContext:(CHChalkContext*)context
{
  CHChalkIdentifier* result = [context.identifierManager identifierForToken:self.token.value createClass:Nil];
  return result;
}
//end identifierWithContext:

-(void) performEvaluationWithContext:(CHChalkContext*)context lazy:(BOOL)lazy
{
  NSString* identifierToken = self->token.value;
  CHChalkIdentifierManager* identifierManager = context.identifierManager;
  CHChalkIdentifierFunction* functionIdentifier =
    self->cachedIdentifier ? self->cachedIdentifier :
    [[identifierManager identifierForToken:identifierToken createClass:Nil] dynamicCastToClass:[CHChalkIdentifierFunction class]];
  if (!self->cachedIdentifier)
    self->cachedIdentifier = [functionIdentifier retain];
  if (!functionIdentifier)
    [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorIdentifierFunctionUndefined range:self->token.range] context:context];
  BOOL isSum = (functionIdentifier == [CHChalkIdentifierFunction sumIdentifier]);
  BOOL isProduct = (functionIdentifier == [CHChalkIdentifierFunction productIdentifier]);
  BOOL isIntegral = (functionIdentifier == [CHChalkIdentifierFunction integralIdentifier]);
  BOOL isCustomFunction = ![[CHChalkIdentifierManager defaultIdentifiersFunctions] containsObject:functionIdentifier];
  if (!functionIdentifier){
  }
  else if (isCustomFunction)
  {
    CHParserEnumerationNode* subEnumeration = (self.children.count != 1) ? nil :
      [[self.children objectAtIndex:0] dynamicCastToClass:[CHParserEnumerationNode class]];
    NSArray* args = subEnumeration.children;
    if (!NSRangeContains(functionIdentifier.argsPossibleCount, args.count))
      [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:self->token.range] context:context];
    else//if (NSRangeContains(functionIdentifier.argsPossibleCount, args.count))
    {
      CHChalkContext* localContext = [[context copy] autorelease];
      CHChalkIdentifierManager* localIdentifierManager = [[context.identifierManager copy] autorelease];
      localContext.identifierManager = localIdentifierManager;
      for(NSUInteger i = 0 ; i<args.count ; ++i)
      {
        NSString* argName = [[functionIdentifier.argumentNames objectAtIndex:i] dynamicCastToClass:[NSString class]];
        CHParserNode* argNode = [[args objectAtIndex:i] dynamicCastToClass:[CHParserNode class]];
        [argNode performEvaluationWithContext:context lazy:lazy];
        CHChalkValue* argValue = argNode.evaluatedValue;
        CHChalkIdentifier* argIdentifier = [localIdentifierManager identifierForName:argName createClass:[CHChalkIdentifierVariable class]];
        [localIdentifierManager setValue:argValue forIdentifier:argIdentifier];
      }//end for each arg
      #pragma warning TODO
      CHParser* localParser = [[[CHParser alloc] init] autorelease];
      [localParser parseTo:localParser fromString:functionIdentifier.definition context:localContext];
      CHChalkError* localParseError = localContext.errorContext.error;
      NSArray* localRootNodes = localParser.rootNodes;
      CHParserNode* localParserNode = localParseError ? nil : [localRootNodes.firstObject dynamicCastToClass:[CHParserNode class]];
      [localParserNode performEvaluationWithContext:localContext lazy:NO];
      self.evaluatedValue = localParserNode.evaluatedValue;
      self->evaluationComputeFlags |= localParserNode.evaluationComputeFlags;
    }//end if (NSRangeContains(functionIdentifier.argsPossibleCount, args.count))
  }//end if (isCustomFunction)
  else if (isIntegral)
  {
    CHParserEnumerationNode* subEnumeration = (self.children.count != 1) ? nil :
      [[self.children objectAtIndex:0] dynamicCastToClass:[CHParserEnumerationNode class]];
    NSArray* args = subEnumeration.children;
    if (!NSRangeContains(functionIdentifier.argsPossibleCount, args.count))
      [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:self->token.range] context:context];
    else if (!context.errorContext.hasError)
    {
      NSArray* subChildren = subEnumeration.children;
      NSUInteger subChildrenCount = subChildren.count;
      CHParserNode* node0 = (subChildrenCount<=0) ? nil : [subChildren objectAtIndex:0];
      CHParserNode* node1 = (subChildrenCount<=1) ? nil : [subChildren objectAtIndex:1];
      CHParserNode* node2 = (subChildrenCount<=2) ? nil : [subChildren objectAtIndex:2];
      CHParserNode* node3 = (subChildrenCount<=3) ? nil : [subChildren objectAtIndex:3];
      CHParserNode* node4 = (subChildrenCount<=3) ? nil : [subChildren objectAtIndex:4];
      CHParserIdentifierNode* evolvingIdentifierNode = [node1 dynamicCastToClass:[CHParserIdentifierNode class]];
      CHChalkIdentifier* evolvingIdentifier = [identifierManager identifierForToken:evolvingIdentifierNode.token.value createClass:[CHChalkIdentifier class]];
      if (!node0)
        [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:node0.token.range] context:context];
      else if (!evolvingIdentifier)
        [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:node1.token.range] context:context];
      else if ([evolvingIdentifier dynamicCastToClass:[CHChalkIdentifierConstant class]] || [evolvingIdentifier dynamicCastToClass:[CHChalkIdentifierFunction class]] ||
               [evolvingIdentifier dynamicCastToClass:[CHChalkIdentifierVariable class]])
        [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorIdentifierReserved range:node1.token.range] context:context];
      else if (node0 && evolvingIdentifier && node2 && node3 && node4)
      {
        NSArray* argsToEvaluate = !node2 || !node3 || !node4 ? nil : @[node2, node3, node4];
        NSArray* expressionToEvaluate = !node0 ? nil : @[node0];
        [super performEvaluationWithChildren:argsToEvaluate context:context lazy:lazy];
        CHChalkValueNumberGmp* valueFrom = [node2.evaluatedValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
        CHChalkValueNumberGmp* valueTo = [node3.evaluatedValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
        CHChalkValueNumberGmp* valueStep = [node4.evaluatedValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
        const chalk_gmp_value_t* gmpValueFrom = valueFrom.valueConstReference;
        const chalk_gmp_value_t* gmpValueTo = valueTo.valueConstReference;
        const chalk_gmp_value_t* gmpValueStep = valueStep.valueConstReference;
        if (!gmpValueFrom)
          [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:node2.token.range] context:context];
        else if (!gmpValueTo)
          [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:node3.token.range] context:context];
        else if (!gmpValueStep)
          [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:node4.token.range] context:context];
        else if (chalkGmpValueIsNan(gmpValueFrom))
        {
          if (!context.computationConfiguration.propagateNaN)
            [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericInvalid range:node2.token.range] context:context];
          self.evaluatedValue = [CHChalkValueNumberGmp nanWithContext:context];
          mpfr_set_nanflag();
          self->evaluationComputeFlags |= chalkGmpFlagsMake();
        }//end if (chalkGmpValueIsNan(gmpValueFrom))
        else if (chalkGmpValueIsNan(gmpValueTo))
        {
          if (!context.computationConfiguration.propagateNaN)
            [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericInvalid range:node2.token.range] context:context];
          self.evaluatedValue = [CHChalkValueNumberGmp nanWithContext:context];
          mpfr_set_nanflag();
          self->evaluationComputeFlags |= chalkGmpFlagsMake();
        }//end if (chalkGmpValueIsNan(gmpValueTo))
        else if (chalkGmpValueIsNan(gmpValueStep))
        {
          if (!context.computationConfiguration.propagateNaN)
            [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericInvalid range:node2.token.range] context:context];
          self.evaluatedValue = [CHChalkValueNumberGmp nanWithContext:context];
          mpfr_set_nanflag();
          self->evaluationComputeFlags |= chalkGmpFlagsMake();
        }//end if (chalkGmpValueIsNan(gmpValueStep))
        else//if (gmpValueFrom && gmpValueTo && gmpValueStep)
        {
          if (chalkGmpValueCmp(gmpValueFrom, gmpValueTo, context.gmpPool) > 0)
            [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:NSRangeUnion(node2.token.range, node3.token.range)] context:context];
          else if (chalkGmpValueSign(gmpValueStep) <= 0)
            [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:NSRangeUnion(node2.token.range, node3.token.range)] context:context];
          else//if (chalkGmpValueCmp(gmpValueFrom, gmpValueTo, context.gmpPool) <= 0)
          {
            chalk_gmp_value_t valueFrom = {0};
            chalk_gmp_value_t valueTo = {0};
            chalk_gmp_value_t valueStep = {0};
            chalk_gmp_value_t valueRangeFull = {0};
            chalk_gmp_value_t valueRangeCurrent = {0};
            chalkGmpValueSet(&valueFrom, gmpValueFrom, context.gmpPool);
            chalkGmpValueSet(&valueTo, gmpValueTo, context.gmpPool);
            chalkGmpValueSet(&valueStep, gmpValueStep, context.gmpPool);
            chalkGmpValueMakeRealApprox(&valueFrom, context.computationConfiguration.softFloatSignificandBits, context.gmpPool);
            chalkGmpValueMakeRealApprox(&valueTo, context.computationConfiguration.softFloatSignificandBits, context.gmpPool);
            chalkGmpValueMakeRealExact(&valueStep, context.computationConfiguration.softFloatSignificandBits, context.gmpPool);
            chalkGmpValueMakeRealApprox(&valueRangeFull, context.computationConfiguration.softFloatSignificandBits, context.gmpPool);
            chalkGmpValueMakeRealApprox(&valueRangeCurrent, context.computationConfiguration.softFloatSignificandBits, context.gmpPool);
            mpfr_set(&valueRangeFull.realApprox->interval.left, &valueFrom.realApprox->interval.left, MPFR_RNDD);
            mpfr_set(&valueRangeFull.realApprox->interval.right, &valueTo.realApprox->interval.right, MPFR_RNDU);
            mpfir_estimation_update(valueRangeFull.realApprox);
            mpfr_set(&valueRangeCurrent.realApprox->interval.left, &valueFrom.realApprox->interval.left, MPFR_RNDD);
            mpfr_add(&valueRangeCurrent.realApprox->interval.right, &valueRangeCurrent.realApprox->interval.left, valueStep.realExact, MPFR_RNDN);
            mpfir_estimation_update(valueRangeCurrent.realApprox);

            CHChalkValue* accumulatedValue = nil;
            chalk_compute_flags_t accumulatedEvaluationComputeFlags = 0;
            CHChalkIdentifierManager* identifierManager = context.identifierManager;
            CHChalkValueNumberGmp* currentIdentifierValue =
              [[CHChalkValueNumberGmp alloc] initWithToken:node2.token value:&valueRangeCurrent naturalBase:10 context:context];
            chalk_gmp_value_t* currentIdentifierGmpValue = currentIdentifierValue.valueReference;
            if (!currentIdentifierGmpValue)
            {
              [currentIdentifierValue release];
              [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:self.token.range] context:context];
            }//end if (!currentIdentifierGmpValue)
            else//if (currentIdentifierGmpValue)
            {
              mpfir_intersect(currentIdentifierGmpValue->realApprox, currentIdentifierGmpValue->realApprox, valueRangeFull.realApprox);
              BOOL stop = mpfir_is_empty(currentIdentifierGmpValue->realApprox) ||
                          mpfr_equal_p(&currentIdentifierGmpValue->realApprox->interval.left, &currentIdentifierGmpValue->realApprox->interval.right);
              while(!stop)
              {
                @autoreleasepool {
                  [identifierManager setValue:currentIdentifierValue forIdentifier:evolvingIdentifier];
                  [super performEvaluationWithChildren:expressionToEvaluate context:context lazy:NO];
                  stop |= context.errorContext.hasError;
                  if (!stop)
                  {
                    CHChalkValue* newValue = node0.evaluatedValue;

                    chalk_gmp_value_t stepToWrap = {0};
                    chalkGmpValueMakeRealExact(&stepToWrap, context.computationConfiguration.softFloatSignificandBits, context.gmpPool);
                    mpfir_diam_abs(stepToWrap.realExact, currentIdentifierValue.valueConstReference->realApprox);
                    CHChalkValueNumberGmp* stepWrapped = [[[CHChalkValueNumberGmp alloc] initWithToken:[CHChalkToken chalkTokenEmpty] value:&stepToWrap naturalBase:10 context:context] autorelease];
                    chalkGmpValueClear(&stepToWrap, YES, context.gmpPool);
                    
                    newValue = !newValue || !stepWrapped ? nil :
                      [CHParserOperatorNode combineMul:@[newValue, stepWrapped] operatorToken:self.token context:context];

                    if (!newValue)
                      [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:self.token.range] context:context];
                    else if (!accumulatedValue)
                      accumulatedValue = [newValue retain];
                    else//if (accumulatedValue)
                    {
                      CHChalkValue* newAccumulatedValue =
                        [CHParserOperatorNode combineAdd:@[accumulatedValue, newValue] operatorToken:self.token context:context];
                      accumulatedEvaluationComputeFlags |= newAccumulatedValue.evaluationComputeFlags;
                      if (!newAccumulatedValue)
                        [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:self.token.range] context:context];
                      [accumulatedValue release];
                      accumulatedValue = [newAccumulatedValue retain];
                    }//end if (accumulatedValue)
                  }//end if (!stop)
                }//end @autoreleasepool
                mpfr_swap(&currentIdentifierGmpValue->realApprox->interval.left, &currentIdentifierGmpValue->realApprox->interval.right);
                mpfr_add(&currentIdentifierGmpValue->realApprox->interval.right, &currentIdentifierGmpValue->realApprox->interval.left, valueStep.realExact, MPFR_RNDN);
                mpfir_estimation_update(currentIdentifierGmpValue->realApprox);
                mpfir_intersect(currentIdentifierGmpValue->realApprox, currentIdentifierGmpValue->realApprox, valueRangeFull.realApprox);
                stop |= mpfir_is_empty(currentIdentifierGmpValue->realApprox) ||
                        mpfr_equal_p(&currentIdentifierGmpValue->realApprox->interval.left, &currentIdentifierGmpValue->realApprox->interval.right);
              }//end while(mpz_cmp(identifierValue, mpzValueTo) <= 0)
              if (!context.errorContext.hasError)
              {
                self.evaluatedValue = accumulatedValue;
                self->evaluationComputeFlags = accumulatedEvaluationComputeFlags;
              }//end if (!context.errorContext.hasError)
              [accumulatedValue autorelease];
              [currentIdentifierValue release];
            }//end if (currentIdentifierGmpValue)
            
            chalkGmpValueClear(&valueFrom, YES, context.gmpPool);
            chalkGmpValueClear(&valueTo, YES, context.gmpPool);
            chalkGmpValueClear(&valueStep, YES, context.gmpPool);
            chalkGmpValueClear(&valueRangeFull, YES, context.gmpPool);
            chalkGmpValueClear(&valueRangeCurrent, YES, context.gmpPool);
          }//end if (chalkGmpValueCmp(gmpValueFrom, gmpValueTo, context.gmpPool) <= 0)
        }//end if (gmpValueFrom && gmpValueTo && gmpValueStep)
      }//if (node0 && evolvingIdentifier && node2 && node3 && node4)
      else
        [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:self->token.range] context:context];
    }//end if (!context.errorContext.hasError)
    if (!self.evaluatedValue && !context.errorContext.hasError)
      [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:self->token.range] context:context];
  }//end if (isIntegral)
  else if (isSum || isProduct)
  {
    CHParserEnumerationNode* subEnumeration = (self.children.count != 1) ? nil :
      [[self.children objectAtIndex:0] dynamicCastToClass:[CHParserEnumerationNode class]];
    NSArray* args = subEnumeration.children;
    if (!NSRangeContains(functionIdentifier.argsPossibleCount, args.count))
      [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:self->token.range] context:context];
    else if (!context.errorContext.hasError)
    {
      NSArray* subChildren = subEnumeration.children;
      NSUInteger subChildrenCount = subChildren.count;
      CHParserNode* node0 = (subChildrenCount<=0) ? nil : [subChildren objectAtIndex:0];
      CHParserNode* node1 = (subChildrenCount<=1) ? nil : [subChildren objectAtIndex:1];
      CHParserNode* node2 = (subChildrenCount<=2) ? nil : [subChildren objectAtIndex:2];
      CHParserNode* node3 = (subChildrenCount<=3) ? nil : [subChildren objectAtIndex:3];
      CHParserIdentifierNode* evolvingIdentifierNode = [node1 dynamicCastToClass:[CHParserIdentifierNode class]];
      CHChalkIdentifier* evolvingIdentifier = [identifierManager identifierForToken:evolvingIdentifierNode.token.value createClass:[CHChalkIdentifier class]];
      if (!node0)
        [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:node0.token.range] context:context];
      else if (!evolvingIdentifier)
        [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:node1.token.range] context:context];
      else if ([evolvingIdentifier dynamicCastToClass:[CHChalkIdentifierConstant class]] || [evolvingIdentifier dynamicCastToClass:[CHChalkIdentifierFunction class]] ||
               [evolvingIdentifier dynamicCastToClass:[CHChalkIdentifierVariable class]])
        [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorIdentifierReserved range:node1.token.range] context:context];
      else if (node0 && evolvingIdentifier && node2 && node3)
      {
        NSArray* argsToEvaluate = !node2 || !node3 ? nil : @[node2, node3];
        NSArray* expressionToEvaluate = !node0 ? nil : @[node0];
        [super performEvaluationWithChildren:argsToEvaluate context:context lazy:lazy];
        CHChalkValueNumberGmp* valueFrom = [node2.evaluatedValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
        CHChalkValueNumberGmp* valueTo = [node3.evaluatedValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
        const chalk_gmp_value_t* gmpValueFrom = valueFrom.valueConstReference;
        const chalk_gmp_value_t* gmpValueTo = valueTo.valueConstReference;
        mpz_srcptr mpzValueFrom = !gmpValueFrom || (gmpValueFrom->type != CHALK_VALUE_TYPE_INTEGER) ? 0 : gmpValueFrom->integer;
        mpz_srcptr mpzValueTo = !gmpValueTo || (gmpValueTo->type != CHALK_VALUE_TYPE_INTEGER) ? 0 : gmpValueTo->integer;
        if (!mpzValueFrom)
          [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:node2.token.range] context:context];
        else if (!mpzValueTo)
          [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:node3.token.range] context:context];
        else//if (mpzValueFrom && mpzValueTo)
        {
          if (mpz_cmp(mpzValueFrom, mpzValueTo) > 0)
            [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:NSRangeUnion(node2.token.range, node3.token.range)] context:context];
          else//if (mpz_cmp(mpzValueFrom, mpzValueTo) <= 0)
          {
            CHChalkValue* accumulatedValue = nil;
            chalk_compute_flags_t accumulatedEvaluationComputeFlags = 0;
            CHChalkIdentifierManager* identifierManager = context.identifierManager;
            CHChalkValueNumberGmp* currentIdentifierValue =
              [[CHChalkValueNumberGmp alloc] initWithToken:[CHChalkToken chalkTokenEmpty] integer:0 naturalBase:10 context:context];
            chalk_gmp_value_t* currentIdentifierGmpValue = currentIdentifierValue.valueReference;
            if (!currentIdentifierGmpValue)
            {
              [currentIdentifierValue release];
              [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:self.token.range] context:context];
            }//end if (!currentIdentifierGmpValue)
            else//if (currentIdentifierGmpValue)
            {
              chalkGmpValueSet(currentIdentifierGmpValue, gmpValueFrom, context.gmpPool);
              BOOL stop = (mpz_cmp(currentIdentifierGmpValue->integer, mpzValueTo) > 0);
              while(!stop)
              {
                @autoreleasepool {
                  [identifierManager setValue:currentIdentifierValue forIdentifier:evolvingIdentifier];
                  [super performEvaluationWithChildren:expressionToEvaluate context:context lazy:NO];
                  stop |= context.errorContext.hasError;
                  if (!stop)
                  {
                    CHChalkValue* newValue = node0.evaluatedValue;
                    if (!newValue)
                      [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:self.token.range] context:context];
                    else if (!accumulatedValue)
                      accumulatedValue = [newValue retain];
                    else//if (accumulatedValue)
                    {
                      CHChalkValue* newAccumulatedValue =
                        isSum ? [CHParserOperatorNode combineAdd:@[accumulatedValue, newValue] operatorToken:self.token context:context] :
                        isProduct ? [CHParserOperatorNode combineMul:@[accumulatedValue, newValue] operatorToken:self.token context:context] :
                        nil;
                      accumulatedEvaluationComputeFlags |= newAccumulatedValue.evaluationComputeFlags;
                      if (!newAccumulatedValue)
                        [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:self.token.range] context:context];
                      [accumulatedValue release];
                      accumulatedValue = [newAccumulatedValue retain];
                    }//end if (accumulatedValue)
                  }//end if (!stop)
                }//end @autoreleasepool
                mpz_add_ui(currentIdentifierGmpValue->integer, currentIdentifierGmpValue->integer, 1);
                stop |= (mpz_cmp(currentIdentifierGmpValue->integer, mpzValueTo) > 0);
              }//end while(mpz_cmp(identifierValue, mpzValueTo) <= 0)
              if (!context.errorContext.hasError)
              {
                self.evaluatedValue = accumulatedValue;
                self->evaluationComputeFlags = accumulatedEvaluationComputeFlags;
              }//end if (!context.errorContext.hasError)
              [accumulatedValue autorelease];
              [currentIdentifierValue release];
            }//end if (currentIdentifierGmpValue)
          }//end if (mpz_cmp(mpzValueFrom, mpzValueTo) <= 0)
        }//end if (mpzValueFrom && mpzValueTo)
      }//if (node0 && evolvingIdentifier && node2 && node3)
      else
        [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:self->token.range] context:context];
    }//end if (!context.errorContext.hasError)
    if (!self.evaluatedValue && !context.errorContext.hasError)
      [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:self->token.range] context:context];
  }//end if (isSum || isProduct)
  else//if (!isSum && !isProduct)
  {
    [super performEvaluationWithContext:context lazy:lazy];
    if (!lazy || !self.evaluatedValue)
    {
      CHParserEnumerationNode* enumeration = [[self->children lastObject] dynamicCastToClass:[CHParserEnumerationNode class]];
      CHChalkValueEnumeration* args = [enumeration.evaluatedValue dynamicCastToClass:[CHChalkValueEnumeration class]];
      if (!args)
        [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:self->token.range] context:context];
      else//if (args)
      {
        if (!NSRangeContains(functionIdentifier.argsPossibleCount, args.count))
          [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:self->token.range] context:context];
        else if (!context.errorContext.hasError)
        {
          BOOL isSin = (functionIdentifier == [CHChalkIdentifierFunction sinIdentifier]);
          BOOL isCos = (functionIdentifier == [CHChalkIdentifierFunction cosIdentifier]);
          BOOL isTan = (functionIdentifier == [CHChalkIdentifierFunction tanIdentifier]);
          BOOL isDegCompatible = isSin || isCos || isTan;
          CHParserEnumerationNode* subEnumeration = !isDegCompatible || (self.children.count != 1) ? nil :
            [[self.children objectAtIndex:0] dynamicCastToClass:[CHParserEnumerationNode class]];
          CHParserNode* singleChild = (subEnumeration.children.count != 1) ? nil : [subEnumeration.children objectAtIndex:0];
          CHParserIdentifierNode* singleChildAsIdentifier = [singleChild dynamicCastToClass:[CHParserIdentifierNode class]];
          CHParserOperatorNode* singleChildAsOperator = [singleChild dynamicCastToClass:[CHParserOperatorNode class]];
          BOOL isPi = [[singleChildAsIdentifier identifierWithContext:context] isEqualTo:[CHChalkIdentifier piIdentifier]];
          BOOL isSubDegree = (singleChildAsOperator.op == CHALK_OPERATOR_DEGREE) && (singleChildAsOperator.children.count == 1);
          BOOL isSubMinusUnary =
            ((singleChildAsOperator.op == CHALK_OPERATOR_MINUS) || (singleChildAsOperator.op == CHALK_OPERATOR_MINUS)) &&
            (singleChildAsOperator.children.count == 1);
          CHParserNode* subDegree = nil;
          if (isSubDegree)
            subDegree = [[singleChildAsOperator.children objectAtIndex:0] dynamicCastToClass:[CHParserNode class]];
          else if (isSubMinusUnary)
          {
            CHParserOperatorNode* subSubOperator =
              [[singleChildAsOperator.children objectAtIndex:0] dynamicCastToClass:[CHParserOperatorNode class]];
            BOOL isSubSubDegree = (subSubOperator.op == CHALK_OPERATOR_DEGREE) &&
              (subSubOperator.children.count == 1);
            if (isSubSubDegree)
              subDegree = [[subSubOperator.children objectAtIndex:0] dynamicCastToClass:[CHParserNode class]];
          }//end if (isSubMinusUnary)
          BOOL done = NO;
          if (isPi)
          {
            CHChalkValue* value =
              isSin ? [CHChalkValueNumberGmp zeroWithToken:self->token context:context] :
              isCos ? [[[CHChalkValueNumberGmp alloc] initWithToken:self->token integer:-1 naturalBase:context.presentationConfiguration.base context:context] autorelease] :
              isTan ? [CHChalkValueNumberGmp zeroWithToken:self->token context:context] :
              nil;
            self.evaluatedValue = value;
            self->evaluationComputeFlags = value.evaluationComputeFlags;
            [self addError:context.errorContext.error];
            done = (value != nil);
          }//end if (isPi)
          else if (subDegree)
          {
            @autoreleasepool {
              CHChalkValue* value =
                isSin ? [[self class] combineSinDeg:@[subDegree.evaluatedValue] token:self->token context:context] :
                isCos ? [[self class] combineCosDeg:@[subDegree.evaluatedValue] token:self->token context:context] :
                isTan ? [[self class] combineTanDeg:@[subDegree.evaluatedValue] token:self->token context:context] :
                nil;
              BOOL error = NO;
              if ((isSubMinusUnary) && (isSin || isTan))
                error |= ![value negate];
              if (!error)
              {
                self.evaluatedValue = value;
                self->evaluationComputeFlags = value.evaluationComputeFlags;
                [self addError:context.errorContext.error];
                done = (value != nil);
              }//end if (!error)
            }//end @autoreleasepool
          }//end if (subDegree)
          if (!done)
          {
            @autoreleasepool {
              CHChalkValue* value = [[self class] combine:args.values functionIdentifier:functionIdentifier token:self->token context:context];
              self.evaluatedValue = value;
              self->evaluationComputeFlags = value.evaluationComputeFlags;
              [self addError:context.errorContext.error];
            }//end @autoreleasepool
          }//end if (!done)
        }//end if (!context.errorContext.hasError)
      }//end if (argsWrapper)
      [context.errorContext.error setContextGenerator:self replace:NO];
    }//end if (!lazy || !self.evaluatedValue)
  }//end if (!isSum && !isProduct)
}
//end performEvaluationWithContext:

-(void) writeBodyToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  NSString* tokenString = self->token.value;
  NSString* identifierToken = self->token.value;
  CHChalkIdentifierManager* identifierManager = context.identifierManager;
  CHChalkIdentifierFunction* functionIdentifier =
    self->cachedIdentifier ? self->cachedIdentifier :
    [[identifierManager identifierForToken:identifierToken createClass:Nil] dynamicCastToClass:[CHChalkIdentifierFunction class]];
  CHParserEnumerationNode* argsWrapper = [[self->children lastObject] dynamicCastToClass:[CHParserEnumerationNode class]];
  NSArray* args = [argsWrapper children];
  //NSUInteger argsCount = args.count;
  if (!presentationConfiguration || (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_STRING))
  {
    NSString* symbol = !functionIdentifier ? tokenString : functionIdentifier.symbol;
    [stream writeString:symbol];
    [stream writeString:@"("];
    [args enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if (idx)
        [stream writeString:@","];
      [obj writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
    }];
    [stream writeString:@")"];
  }//end if (!presentationConfiguration || (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_STRING))
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_ATTRIBUTEDSTRING)
  {
    NSString* symbol = !functionIdentifier ? tokenString : functionIdentifier.symbol;
    NSDictionary* currentAttributes = stream.currentAttributes;
    NSAttributedString* parenthesisLeft = [[NSAttributedString alloc] initWithString:@"(" attributes:currentAttributes];
    NSAttributedString* parenthesisRight = [[NSAttributedString alloc] initWithString:@")" attributes:currentAttributes];
    NSAttributedString* parenthesisSeparator = [[NSAttributedString alloc] initWithString:@"," attributes:currentAttributes];
    [stream writeString:symbol bold:NO italic:YES];
    [stream writeAttributedString:parenthesisLeft];
    [args enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if (idx)
        [stream writeAttributedString:parenthesisSeparator];
      [obj writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
    }];
    [stream writeAttributedString:parenthesisRight];
    [parenthesisLeft release];
    [parenthesisRight release];
    [parenthesisSeparator release];
  }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_ATTRIBUTEDSTRING)
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_DOT)
  {
    NSString* symbol = !functionIdentifier ? tokenString : functionIdentifier.symbol;
    NSString* selfNodeIdentifier = [NSString stringWithFormat:@"_%p", self];
    [stream writeString:[NSString stringWithFormat:@"%@ [label=\"%@\"];n", selfNodeIdentifier, symbol]];
  }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_DOT)
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_MATHML)
  {
    NSString* symbol = !functionIdentifier ? tokenString : functionIdentifier.symbol;
    [stream writeString:@"<mi>"];
    [stream writeString:symbol];
    [stream writeString:@"</mi>"];
    [stream writeString:@"<mfenced open=\"(\" close=\")\" separators=\",\">"];
    [args enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      [obj writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
    }];
    [stream writeString:@"</mfenced>"];
  }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_MATHML)
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
  {
    NSString* symbol = !functionIdentifier ? tokenString : functionIdentifier.symbolAsTeX;
    NSArray* placeHolders = [symbol componentsMatchedByRegex:@"%[0-9]*@"];
    NSUInteger placeHoldersCount = placeHolders.count;
    BOOL hasParenthesis = [symbol isMatchedByRegex:@".*\\(.*\\).*"];
    if (placeHoldersCount)
    {
      NSArray* components = [symbol componentsSeparatedByRegex:@"%[0-9]*@"];
      for(NSUInteger i = 0 ; i<placeHoldersCount ; ++i)
      {
        NSString* placeHolder = (i<placeHolders.count) ? [placeHolders objectAtIndex:i] : nil;
        NSString* modifiedIndexString = [placeHolder stringByReplacingOccurrencesOfRegex:@"^\\%(.*)\\@$" withString:@"$1"];
        NSUInteger modifiedIndex = !modifiedIndexString.length ? i : [modifiedIndexString integerValue];
        NSString* component = (i<components.count) ? [components objectAtIndex:i] : nil;
        [stream writeString:component];
        CHParserNode* parserNode = (modifiedIndex<args.count) ? [[args objectAtIndex:modifiedIndex] dynamicCastToClass:[CHParserNode class]] : nil;
        BOOL isTerminal = hasParenthesis || parserNode.isTerminal ||
          (functionIdentifier == [CHChalkIdentifierFunction sqrtIdentifier]) ||
          (functionIdentifier == [CHChalkIdentifierFunction rootIdentifier]);
        if (!isTerminal)
          [stream writeString:@"\\left("];
        [parserNode writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
        if (!isTerminal)
          [stream writeString:@"\\right)"];
      }//end for each child
      [stream writeString:[components lastObject]];
    }//end if (placeHoldersCount)
    else//if (!placeHoldersCount)
    {
      [stream writeString:symbol];
      [stream writeString:@"\\left({"];
      [args enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CHParserNode* parserNode = [obj dynamicCastToClass:[CHParserNode class]];
        if (idx)
          [stream writeString:@","];
        [parserNode writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
      }];
      [stream writeString:@"}\\right)"];
    }//end if (!placeHoldersCount)
  }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_HTML)
  {
    NSString* symbol = !functionIdentifier ? tokenString : functionIdentifier.symbol;
    NSString* iconString = nil;
    if ((functionIdentifier == [CHChalkIdentifierFunction inFileIdentifier]) ||
        (functionIdentifier == [CHChalkIdentifierFunction outFileIdentifier]))
    {
      NSMutableString* title = [NSMutableString string];
      CHStreamWrapper* stream2 = [[CHStreamWrapper alloc] init];
      stream2.stringStream = title;
      [args enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (idx)
          [stream2 writeString:@","];
        [obj writeToStream:stream2 context:context presentationConfiguration:presentationConfiguration];
      }];
      iconString = [NSString stringWithFormat:@"<img class=\"%@\" onmouseover=\"tooltip.show('%@')\" onmouseout=\"tooltip.hide()\" src=\"%@\" />",
        (functionIdentifier == [CHChalkIdentifierFunction inFileIdentifier]) ?
          @"file-read" :
        (functionIdentifier == [CHChalkIdentifierFunction outFileIdentifier]) ?
          @"file-write" :
        @"",
        [title encodeHTMLCharacterEntities],
        @"images/transparent.png"];
      [stream2 release];
    }//end if infile or outfile
    if (self->evaluationErrors.count)
    {
      NSString* errorsString = [[[self->evaluationErrors valueForKey:@"friendlyDescription"] componentsJoinedByString:@","] stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
      NSString* string =
        [NSString stringWithFormat:@"<span class=\"errorFlag\" onmouseover=\"tooltip.show('%@');\" onmouseout=\"tooltip.hide();\">%@</span>",
          errorsString, iconString ? iconString : symbol];
      [stream writeString:string];
    }//end if (self->evaluationErrors.count)
    else if (self->evaluationComputeFlags)
    {
      CHChalkValueNumberRaw* evaluatedValueRaw = [self->evaluatedValue dynamicCastToClass:[CHChalkValueNumberRaw class]];
      const chalk_raw_value_t* rawValue = evaluatedValueRaw.valueConstReference;
      const chalk_bit_interpretation_t* bitInterpretation = !rawValue ? 0 : &rawValue->bitInterpretation;
      NSString* flagsImageString = [chalkGmpComputeFlagsGetHTML(self->evaluationComputeFlags, bitInterpretation, NO) stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
      NSString* string =
        [NSString stringWithFormat:@"<span class=\"hasTooltip\" onmouseover=\"tooltip.show('%@');\" onmouseout=\"tooltip.hide();\">%@</span>", flagsImageString, iconString ? iconString : symbol];
      [stream writeString:string];
    }
    else
      [stream writeString:iconString ? iconString : symbol];
    if (!iconString)
    {
      [stream writeString:@"("];
      [args enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (idx)
          [stream writeString:@","];
        [obj writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
      }];
      [stream writeString:@")"];
    }//end if (!iconString)
  }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_HTML)
}
//end writeBodyToStream:context:options:

+(CHChalkValue*) combine:(NSArray*)operands functionIdentifier:(CHChalkIdentifierFunction*)functionIdentifier token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  static NSMapTable* functions = nil;
  if (!functions)
  {
    @synchronized(self)
    {
      if (!functions)
      {
        functions = [[NSMapTable alloc] initWithKeyOptions:NSMapTableWeakMemory|NSMapTableObjectPointerPersonality
                                              valueOptions:NSMapTableStrongMemory
                                                  capacity:10];
        [functions setObject:[NSValue valueWithPointer:@selector(combineInterval:token:context:)] forKey:[CHChalkIdentifierFunction intervalIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineAbs:token:context:)] forKey:[CHChalkIdentifierFunction absIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineAngle:token:context:)] forKey:[CHChalkIdentifierFunction angleIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineAngles:token:context:)] forKey:[CHChalkIdentifierFunction anglesIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineFloor:token:context:)] forKey:[CHChalkIdentifierFunction floorIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineCeil:token:context:)] forKey:[CHChalkIdentifierFunction ceilIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineInv:token:context:)] forKey:[CHChalkIdentifierFunction invIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combinePow:token:context:)] forKey:[CHChalkIdentifierFunction powIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineSqrt:token:context:)] forKey:[CHChalkIdentifierFunction sqrtIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineCbrt:token:context:)] forKey:[CHChalkIdentifierFunction cbrtIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineRoot:token:context:)] forKey:[CHChalkIdentifierFunction rootIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineExp:token:context:)] forKey:[CHChalkIdentifierFunction expIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineLn:token:context:)] forKey:[CHChalkIdentifierFunction lnIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineLog10:token:context:)] forKey:[CHChalkIdentifierFunction log10Identifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineSin:token:context:)] forKey:[CHChalkIdentifierFunction sinIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineCos:token:context:)] forKey:[CHChalkIdentifierFunction cosIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineTan:token:context:)] forKey:[CHChalkIdentifierFunction tanIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineASin:token:context:)] forKey:[CHChalkIdentifierFunction asinIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineACos:token:context:)] forKey:[CHChalkIdentifierFunction acosIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineATan:token:context:)] forKey:[CHChalkIdentifierFunction atanIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineATan2:token:context:)] forKey:[CHChalkIdentifierFunction atan2Identifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineSinh:token:context:)] forKey:[CHChalkIdentifierFunction sinhIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineCosh:token:context:)] forKey:[CHChalkIdentifierFunction coshIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineTanh:token:context:)] forKey:[CHChalkIdentifierFunction tanhIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineASinh:token:context:)] forKey:[CHChalkIdentifierFunction asinhIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineACosh:token:context:)] forKey:[CHChalkIdentifierFunction acoshIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineATanh:token:context:)] forKey:[CHChalkIdentifierFunction atanhIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineGamma:token:context:)] forKey:[CHChalkIdentifierFunction gammaIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineZeta:token:context:)] forKey:[CHChalkIdentifierFunction zetaIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineConj:token:context:)] forKey:[CHChalkIdentifierFunction conjIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineMatrix:token:context:)] forKey:[CHChalkIdentifierFunction matrixIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineIdentity:token:context:)] forKey:[CHChalkIdentifierFunction identityIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineTranspose:token:context:)] forKey:[CHChalkIdentifierFunction transposeIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineTrace:token:context:)] forKey:[CHChalkIdentifierFunction traceIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineDet:token:context:)] forKey:[CHChalkIdentifierFunction detIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineIsPrime:token:context:)] forKey:[CHChalkIdentifierFunction isPrimeIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineNextPrime:token:context:)] forKey:[CHChalkIdentifierFunction nextPrimeIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineNthPrime:token:context:)] forKey:[CHChalkIdentifierFunction nthPrimeIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combinePrimes:token:context:)] forKey:[CHChalkIdentifierFunction primesIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineGcd:token:context:)] forKey:[CHChalkIdentifierFunction gcdIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineLcm:token:context:)] forKey:[CHChalkIdentifierFunction lcmIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineMod:token:context:)] forKey:[CHChalkIdentifierFunction modIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineBinomial:token:context:)] forKey:[CHChalkIdentifierFunction binomialIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combinePrimorial:token:context:)] forKey:[CHChalkIdentifierFunction primorialIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineFibonacci:token:context:)] forKey:[CHChalkIdentifierFunction fibonacciIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineJacobi:token:context:)] forKey:[CHChalkIdentifierFunction jacobiIdentifier]];
        //[functions setObject:[NSValue valueWithPointer:@selector(combineInput:token:context:)] forKey:[CHChalkIdentifierFunction inputIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineOutput:token:context:)] forKey:[CHChalkIdentifierFunction outputIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineOutput2:token:context:)] forKey:[CHChalkIdentifierFunction output2Identifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineFromBase:token:context:)] forKey:[CHChalkIdentifierFunction fromBaseIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineInFile:token:context:)] forKey:[CHChalkIdentifierFunction inFileIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineOutFile:token:context:)] forKey:[CHChalkIdentifierFunction outFileIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineToU8:token:context:)] forKey:[CHChalkIdentifierFunction toU8Identifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineToS8:token:context:)] forKey:[CHChalkIdentifierFunction toS8Identifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineToU16:token:context:)] forKey:[CHChalkIdentifierFunction toU16Identifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineToS16:token:context:)] forKey:[CHChalkIdentifierFunction toS16Identifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineToU32:token:context:)] forKey:[CHChalkIdentifierFunction toU32Identifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineToS32:token:context:)] forKey:[CHChalkIdentifierFunction toS32Identifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineToU64:token:context:)] forKey:[CHChalkIdentifierFunction toU64Identifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineToS64:token:context:)] forKey:[CHChalkIdentifierFunction toS64Identifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineToU128:token:context:)] forKey:[CHChalkIdentifierFunction toU128Identifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineToS128:token:context:)] forKey:[CHChalkIdentifierFunction toS128Identifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineToU256:token:context:)] forKey:[CHChalkIdentifierFunction toU256Identifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineToS256:token:context:)] forKey:[CHChalkIdentifierFunction toS256Identifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineToUCustom:token:context:)] forKey:[CHChalkIdentifierFunction toUCustomIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineToSCustom:token:context:)] forKey:[CHChalkIdentifierFunction toSCustomIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineToChalkInteger:token:context:)] forKey:[CHChalkIdentifierFunction toChalkIntegerIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineToF16:token:context:)] forKey:[CHChalkIdentifierFunction toF16Identifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineToF32:token:context:)] forKey:[CHChalkIdentifierFunction toF32Identifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineToF64:token:context:)] forKey:[CHChalkIdentifierFunction toF64Identifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineToF128:token:context:)] forKey:[CHChalkIdentifierFunction toF128Identifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineToF256:token:context:)] forKey:[CHChalkIdentifierFunction toF256Identifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineToChalkFloat:token:context:)] forKey:[CHChalkIdentifierFunction toChalkFloatIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineFromU8:token:context:)] forKey:[CHChalkIdentifierFunction fromU8Identifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineFromS8:token:context:)] forKey:[CHChalkIdentifierFunction fromS8Identifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineFromU16:token:context:)] forKey:[CHChalkIdentifierFunction fromU16Identifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineFromS16:token:context:)] forKey:[CHChalkIdentifierFunction fromS16Identifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineFromU32:token:context:)] forKey:[CHChalkIdentifierFunction fromU32Identifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineFromS32:token:context:)] forKey:[CHChalkIdentifierFunction fromS32Identifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineFromU64:token:context:)] forKey:[CHChalkIdentifierFunction fromU64Identifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineFromS64:token:context:)] forKey:[CHChalkIdentifierFunction fromS64Identifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineFromU128:token:context:)] forKey:[CHChalkIdentifierFunction fromU128Identifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineFromS128:token:context:)] forKey:[CHChalkIdentifierFunction fromS128Identifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineFromU256:token:context:)] forKey:[CHChalkIdentifierFunction fromU256Identifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineFromS256:token:context:)] forKey:[CHChalkIdentifierFunction fromS256Identifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineFromUCustom:token:context:)] forKey:[CHChalkIdentifierFunction fromUCustomIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineFromSCustom:token:context:)] forKey:[CHChalkIdentifierFunction fromSCustomIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineFromChalkInteger:token:context:)] forKey:[CHChalkIdentifierFunction fromChalkIntegerIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineFromF16:token:context:)] forKey:[CHChalkIdentifierFunction fromF16Identifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineFromF32:token:context:)] forKey:[CHChalkIdentifierFunction fromF32Identifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineFromF64:token:context:)] forKey:[CHChalkIdentifierFunction fromF64Identifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineFromF128:token:context:)] forKey:[CHChalkIdentifierFunction fromF128Identifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineFromF256:token:context:)] forKey:[CHChalkIdentifierFunction fromF256Identifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineFromChalkFloat:token:context:)] forKey:[CHChalkIdentifierFunction fromChalkFloatIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineShift:token:context:)] forKey:[CHChalkIdentifierFunction shiftIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineRoll:token:context:)] forKey:[CHChalkIdentifierFunction rollIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineBitsSwap:token:context:)] forKey:[CHChalkIdentifierFunction bitsSwapIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineBitsReverse:token:context:)] forKey:[CHChalkIdentifierFunction bitsReverseIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineBitsConcatLE:token:context:)] forKey:[CHChalkIdentifierFunction bitsConcatLEIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineBitsConcatBE:token:context:)] forKey:[CHChalkIdentifierFunction bitsConcatBEIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineGolombRiceDecode:token:context:)] forKey:[CHChalkIdentifierFunction golombRiceDecodeIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineGolombRiceEncode:token:context:)] forKey:[CHChalkIdentifierFunction golombRiceEncodeIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineHConcat:token:context:)] forKey:[CHChalkIdentifierFunction hConcatIdentifier]];
        [functions setObject:[NSValue valueWithPointer:@selector(combineVConcat:token:context:)] forKey:[CHChalkIdentifierFunction vConcatIdentifier]];
      }//end if (!functions)
    }//end @synchronized(self)
  }//end if (!functions)
  SEL selector = !functionIdentifier ? 0 : (SEL)[[[functions objectForKey:functionIdentifier] dynamicCastToClass:[NSValue class]] pointerValue];
  result = [self performSelector:selector withArguments:@[operands, token, context]];
  return result;
}
//end combine:functionIdentifier:token:context:

+(CHChalkValueMatrix*) combineMatrixSEL:(SEL)selector operand:(CHChalkValueMatrix*)operandMatrix token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValueMatrix* result = nil;
  if (operandMatrix)
  {
    CHChalkValueMatrix* newMatrix = [[CHChalkValueMatrix alloc] initWithToken:token rowsCount:operandMatrix.rowsCount colsCount:operandMatrix.colsCount value:0 context:context];
    if (!newMatrix)
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                             replace:NO];
    else//if (newMatrix)
    {
      IMP imp = [self methodForSelector:selector];
      typedef CHChalkValue*(*imp_sel_t)(id, SEL, NSArray*, CHChalkToken*, CHChalkContext*);
      imp_sel_t imp_sel = (imp_sel_t)imp;
      NSUInteger colsCount = newMatrix.colsCount;
      [newMatrix.values enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSUInteger row = !colsCount ? 0 :idx/colsCount;
        NSUInteger col = !colsCount ? 0 :idx%colsCount;
        CHChalkValue* operandElementValue = [operandMatrix valueAtRow:row col:col];
        CHChalkValue* newElementValue = !operandElementValue ? nil :
          imp_sel(self, selector, @[operandElementValue], token, context);
        if (newElementValue)
          [newMatrix setValue:newElementValue atRow:row col:col];
        else//if (newElementValue)
        {
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                 replace:NO];
          *stop = YES;
        }//end if (newElementValue)
      }];
    }//end if (newMatrix)
    if (context.errorContext.hasError)
    {
      [newMatrix release];
      newMatrix = nil;
    }//end if (context.errorContext.hasError)
    result = newMatrix;
  }//end if (operandMatrix)
  return [result autorelease];
}
//end combineMatrixSEL:operand:token:context:

+(CHChalkValueMatrix*) combineMatrixSEL:(SEL)selector operand:(CHChalkValueMatrix*)operandMatrix otherOperands:(NSArray*)otherOperands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValueMatrix* result = nil;
  if (operandMatrix)
  {
    CHChalkValueMatrix* newMatrix = [[CHChalkValueMatrix alloc] initWithToken:token rowsCount:operandMatrix.rowsCount colsCount:operandMatrix.colsCount value:0 context:context];
    if (!newMatrix)
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                             replace:NO];
    else//if (newMatrix)
    {
      NSMutableArray* newOperands = [NSMutableArray arrayWithCapacity:1+otherOperands.count];
      [newOperands addObject:[NSNull null]];
      [newOperands addObjectsFromArray:otherOperands];
      IMP imp = [self methodForSelector:selector];
      typedef CHChalkValue*(*imp_sel_t)(id, SEL, NSArray*, CHChalkToken*, CHChalkContext*);
      imp_sel_t imp_sel = (imp_sel_t)imp;
      NSUInteger colsCount = newMatrix.colsCount;
      [newMatrix.values enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSUInteger row = !colsCount ? 0 :idx/colsCount;
        NSUInteger col = !colsCount ? 0 :idx%colsCount;
        CHChalkValue* operandElementValue = [operandMatrix valueAtRow:row col:col];
        CHChalkValue* newElementValue = nil;
        if (operandElementValue)
        {
          [newOperands replaceObjectAtIndex:0 withObject:operandElementValue];
           newElementValue = imp_sel(self, selector, newOperands, token, context);
        }//end if (operandElementValue)
        if (newElementValue)
          [newMatrix setValue:newElementValue atRow:row col:col];
        else//if (newElementValue)
        {
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                 replace:NO];
          *stop = YES;
        }//end if (newElementValue)
      }];
    }//end if (newMatrix)
    if (context.errorContext.hasError)
    {
      [newMatrix release];
      newMatrix = nil;
    }//end if (context.errorContext.hasError)
    result = newMatrix;
  }//end if (operandMatrix)
  return [result autorelease];
}
//end combineMatrixSEL:operand:otherOperands:token:context:

+(CHChalkValueList*) combineSEL:(SEL)selector arguments:(NSArray*)arguments list:(CHChalkValueList*)list index:(NSUInteger)index token:(CHChalkToken*)token context:(CHChalkContext*)context
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
      typedef CHChalkValue*(*imp_sel_t)(id, SEL, NSArray*, CHChalkToken*, CHChalkContext*);
      imp_sel_t imp_sel = (imp_sel_t)imp;
      [list.values enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CHChalkValue* elementValue = [obj dynamicCastToClass:[CHChalkValue class]];
        NSMutableArray* newArguments = [NSMutableArray arrayWithArray:arguments];
        CHChalkValue* newElementValue = nil;
        if (!newArguments){
        }
        else if (elementValue)
        {
          [newArguments replaceObjectAtIndex:index withObject:elementValue];
          newElementValue = imp_sel(self, selector, newArguments, token, context);
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
//end combineSEL:class:arguments:list:index:token:context:

+(CHChalkValue*) combineInterval:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  id parameter1 = (operands.count < 1) ? nil : [operands objectAtIndex:0];
  id parameter2 = (operands.count < 2) ? nil : [operands objectAtIndex:1];
  id parameter3 = (operands.count < 3) ? nil : [operands objectAtIndex:2];
  CHChalkValue* referenceValue = [parameter1 dynamicCastToClass:[CHChalkValue class]];
  CHChalkValueNumberGmp* referenceValueNumber = [referenceValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
  CHChalkValue* deltaValue = [parameter2 dynamicCastToClass:[CHChalkValue class]];
  CHChalkValueNumberGmp* deltaValueNumber = [deltaValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
  CHChalkValue* directionValue = [parameter3 dynamicCastToClass:[CHChalkValue class]];
  CHChalkValueNumberGmp* directionValueNumber = [directionValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
  if (!referenceValueNumber || !referenceValueNumber.valueConstReference ||
      !deltaValueNumber || !deltaValueNumber.valueConstReference ||
      (directionValue && !directionValueNumber) ||
      (directionValueNumber && !directionValueNumber.valueConstReference) ||
      (directionValueNumber && directionValueNumber.valueType != CHALK_VALUE_TYPE_INTEGER))
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                           replace:NO];
  else//if (referenceValueNumber && deltaValueNumber && (!directionValue || directionValueNumber))
  {
    long direction = 0;
    const chalk_gmp_value_t* directionValueNumberGmpValue = directionValueNumber.valueConstReference;
    if (!directionValueNumberGmpValue)
      direction = 0;
    else if (mpz_cmp_si(directionValueNumberGmpValue->integer, -1) &&
        mpz_cmp_si(directionValueNumberGmpValue->integer,  0) &&
        mpz_cmp_si(directionValueNumberGmpValue->integer,  1))
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                             replace:NO];
    else//if (direction is -1, 0 or 1)
      direction = mpz_get_si(directionValueNumberGmpValue->integer);
    const chalk_gmp_value_t* referenceValueNumberGmpValue = referenceValueNumber.valueConstReference;
    const chalk_gmp_value_t* deltaValueNumberGmpValue = deltaValueNumber.valueConstReference;
    chalk_gmp_value_t delta = {0};
    chalkGmpValueSet(&delta, deltaValueNumberGmpValue, context.gmpPool);
    if (delta.type == CHALK_VALUE_TYPE_INTEGER)
      mpz_abs(delta.integer, delta.integer);
    else if (delta.type == CHALK_VALUE_TYPE_FRACTION)
      mpq_abs(delta.fraction, delta.fraction);
    else if (delta.type == CHALK_VALUE_TYPE_REAL_EXACT)
      mpfr_abs(delta.realExact, delta.realExact, MPFR_RNDU);
    else if (delta.type == CHALK_VALUE_TYPE_REAL_APPROX)
      mpfir_abs(delta.realApprox, delta.realApprox);

    chalk_gmp_value_t interval = {0};
    mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
    chalkGmpValueMakeRealApprox(&interval, prec, context.gmpPool);
    if (direction<0)
    {
      if (referenceValueNumberGmpValue->type == CHALK_VALUE_TYPE_INTEGER)
        mpfr_set_z(&interval.realApprox->interval.right, referenceValueNumberGmpValue->integer, MPFR_RNDU);
      else if (referenceValueNumberGmpValue->type == CHALK_VALUE_TYPE_FRACTION)
        mpfr_set_q(&interval.realApprox->interval.right, referenceValueNumberGmpValue->fraction, MPFR_RNDU);
      else if (referenceValueNumberGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT)
        mpfr_set(&interval.realApprox->interval.right, referenceValueNumberGmpValue->realExact, MPFR_RNDU);
      else if (referenceValueNumberGmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX)
        mpfr_set(&interval.realApprox->interval.right, &referenceValueNumberGmpValue->realApprox->interval.right, MPFR_RNDU);
      if (delta.type == CHALK_VALUE_TYPE_INTEGER)
        mpfr_sub_z(&interval.realApprox->interval.left, &interval.realApprox->interval.right, delta.integer, MPFR_RNDD);
      else if (delta.type == CHALK_VALUE_TYPE_FRACTION)
        mpfr_sub_q(&interval.realApprox->interval.left, &interval.realApprox->interval.right, delta.fraction, MPFR_RNDD);
      else if (delta.type == CHALK_VALUE_TYPE_REAL_EXACT)
        mpfr_sub(&interval.realApprox->interval.left, &interval.realApprox->interval.right, delta.realExact, MPFR_RNDD);
      else if (delta.type == CHALK_VALUE_TYPE_REAL_APPROX)
        mpfr_sub(&interval.realApprox->interval.left, &interval.realApprox->interval.right, &delta.realApprox->interval.right, MPFR_RNDD);
    }//end if (direction<0)
    else if (direction>0)
    {
      if (referenceValueNumberGmpValue->type == CHALK_VALUE_TYPE_INTEGER)
        mpfr_set_z(&interval.realApprox->interval.left, referenceValueNumberGmpValue->integer, MPFR_RNDD);
      else if (referenceValueNumberGmpValue->type == CHALK_VALUE_TYPE_FRACTION)
        mpfr_set_q(&interval.realApprox->interval.left, referenceValueNumberGmpValue->fraction, MPFR_RNDD);
      else if (referenceValueNumberGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT)
        mpfr_set(&interval.realApprox->interval.left, referenceValueNumberGmpValue->realExact, MPFR_RNDD);
      else if (referenceValueNumberGmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX)
        mpfr_set(&interval.realApprox->interval.left, &referenceValueNumberGmpValue->realApprox->interval.left, MPFR_RNDD);
      if (delta.type == CHALK_VALUE_TYPE_INTEGER)
        mpfr_add_z(&interval.realApprox->interval.right, &interval.realApprox->interval.left, delta.integer, MPFR_RNDU);
      else if (delta.type == CHALK_VALUE_TYPE_FRACTION)
        mpfr_add_q(&interval.realApprox->interval.right, &interval.realApprox->interval.left, delta.fraction, MPFR_RNDU);
      else if (delta.type == CHALK_VALUE_TYPE_REAL_EXACT)
        mpfr_add(&interval.realApprox->interval.right, &interval.realApprox->interval.left, delta.realExact, MPFR_RNDU);
      else if (delta.type == CHALK_VALUE_TYPE_REAL_APPROX)
        mpfr_add(&interval.realApprox->interval.right, &interval.realApprox->interval.left, &delta.realApprox->interval.right, MPFR_RNDU);
    }//end if (direction>0)
    else if (!direction)
    {
      chalk_gmp_value_t mid = {0};
      chalkGmpValueSet(&mid, referenceValueNumberGmpValue, context.gmpPool);
      if (referenceValueNumberGmpValue->type == CHALK_VALUE_TYPE_INTEGER)
      {
        mpfr_set_z(&interval.realApprox->interval.left, mid.integer, MPFR_RNDD);
        mpfr_set_z(&interval.realApprox->interval.right, mid.integer, MPFR_RNDU);
      }//end if (referenceValueNumberGmpValue->type == CHALK_VALUE_TYPE_INTEGER)
      else if (referenceValueNumberGmpValue->type == CHALK_VALUE_TYPE_FRACTION)
      {
        mpfr_set_q(&interval.realApprox->interval.left, mid.fraction, MPFR_RNDD);
        mpfr_set_q(&interval.realApprox->interval.right, mid.fraction, MPFR_RNDU);
      }//end if (referenceValueNumberGmpValue->type == CHALK_VALUE_TYPE_FRACTION)
      else if (referenceValueNumberGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT)
      {
        mpfr_set(&interval.realApprox->interval.left, mid.realExact, MPFR_RNDD);
        mpfr_set(&interval.realApprox->interval.right, mid.realExact, MPFR_RNDU);
      }//end if (referenceValueNumberGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT)
      else if (referenceValueNumberGmpValue->type == CHALK_VALUE_TYPE_REAL_APPROX)
        mpfir_set(interval.realApprox, mid.realApprox);

      if (delta.type == CHALK_VALUE_TYPE_INTEGER)
      {
        mpfr_sub_z(&interval.realApprox->interval.left, &interval.realApprox->interval.left, delta.integer, MPFR_RNDD);
        mpfr_add_z(&interval.realApprox->interval.right, &interval.realApprox->interval.right, delta.integer, MPFR_RNDU);
      }//end if (delta.type == CHALK_VALUE_TYPE_INTEGER)
      else if (delta.type == CHALK_VALUE_TYPE_FRACTION)
      {
        mpfr_sub_q(&interval.realApprox->interval.left, &interval.realApprox->interval.left, delta.fraction, MPFR_RNDD);
        mpfr_add_q(&interval.realApprox->interval.right, &interval.realApprox->interval.right, delta.fraction, MPFR_RNDU);
      }//end if (delta.type == CHALK_VALUE_TYPE_FRACTION)
      else if (delta.type == CHALK_VALUE_TYPE_REAL_EXACT)
      {
        mpfr_sub(&interval.realApprox->interval.left, &interval.realApprox->interval.left, delta.realExact, MPFR_RNDD);
        mpfr_add(&interval.realApprox->interval.right, &interval.realApprox->interval.right, delta.realExact, MPFR_RNDU);
      }//end if (delta.type == CHALK_VALUE_TYPE_REAL_EXACT)
      else if (delta.type == CHALK_VALUE_TYPE_REAL_APPROX)
      {
        mpfr_sub(&interval.realApprox->interval.left, &interval.realApprox->interval.left, &delta.realApprox->interval.right, MPFR_RNDD);
        mpfr_add(&interval.realApprox->interval.right, &interval.realApprox->interval.right, &delta.realApprox->interval.right, MPFR_RNDU);
      }//end if (delta.type == CHALK_VALUE_TYPE_REAL_APPROX)
      chalkGmpValueClear(&mid, YES, context.gmpPool);
    }//end if (!direction)
    
    mpfir_estimation_update(interval.realApprox);
    result = [[[CHChalkValueNumberGmp alloc] initWithToken:token value:&interval naturalBase:referenceValue.naturalBase context:context] autorelease];
    if (!result)
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                             replace:NO];
    chalkGmpValueClear(&interval, YES, context.gmpPool);
    chalkGmpValueClear(&delta, YES, context.gmpPool);
    result.evaluationComputeFlags |=
      referenceValue.evaluationComputeFlags |
      deltaValue.evaluationComputeFlags |
      chalkGmpFlagsMake();
   }//end if (referenceValueNumber && deltaValueNumber && (!directionValue || directionValueNumber))
  return result;
}
//end combineInterval:token:context:

+(CHChalkValue*) combineAbs:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    @autoreleasepool {
      CHChalkValue* operandValue = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueScalar* operandScalar = [operandValue dynamicCastToClass:[CHChalkValueScalar class]];
      CHChalkValueNumberGmp* operandGmp = [operandScalar dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueFormal* operandFormal = [operandValue dynamicCastToClass:[CHChalkValueFormal class]];
      operandGmp = !operandFormal ? operandGmp : operandFormal.value;
      CHChalkValueQuaternion* operandQuaternion = [operandScalar dynamicCastToClass:[CHChalkValueQuaternion class]];
      CHChalkValueMatrix* operandMatrix = [operandValue dynamicCastToClass:[CHChalkValueMatrix class]];
      CHChalkValueList* operandList = [operandValue dynamicCastToClass:[CHChalkValueList class]];
      if (operandList)
        result = [[self combineSEL:_cmd arguments:operands list:operandList index:0 token:token context:context] retain];
      else if (operandMatrix)
      {
        CHChalkValueMatrix* newMatrix = [[self combineMatrixSEL:_cmd operand:operandMatrix token:token context:context] retain];
        if (context.errorContext.hasError)
        {
          [newMatrix release];
          newMatrix = nil;
        }//end if (context.errorContext.hasError)
        result = newMatrix;
      }//end if (operandMatrix)
      else if (operandQuaternion)
      {
        CHChalkValueNumber* partR = operandQuaternion.partReal;
        CHChalkValueNumber* partI = operandQuaternion.partI;
        CHChalkValueNumber* partJ = operandQuaternion.partJ;
        CHChalkValueNumber* partK = operandQuaternion.partK;
        CHChalkValue* partR2 = !partR ? nil : [CHParserFunctionNode combineSqr:@[partR] token:token context:context];
        CHChalkValue* partI2 = !partI ? nil : [CHParserFunctionNode combineSqr:@[partI] token:token context:context];
        CHChalkValue* partJ2 = !partJ ? nil : [CHParserFunctionNode combineSqr:@[partJ] token:token context:context];
        CHChalkValue* partK2 = !partK ? nil : [CHParserFunctionNode combineSqr:@[partK] token:token context:context];
        CHChalkValue* square = !partR2 || !partI2 || !partJ2 || !partK2 ? nil :
          [CHParserOperatorNode combineAdd:@[partR2, partI2, partJ2, partK2] operatorToken:token context:context];
        CHChalkValue* value = !square ? nil :
          [self combineSqrt:@[square] token:token context:context];
        if (!value)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                 replace:NO];
        result = [value retain];
      }//end if (operandQuaternion)
      else if (operandGmp)
      {
        mpfr_clear_flags();
        const chalk_gmp_value_t* operand = operandGmp.valueConstReference;
        chalk_gmp_value_t currentValue = {0};
        chalkGmpValueSet(&currentValue, operand, context.gmpPool);
        BOOL done = NO;
        if (!done)
        {
          if (currentValue.type == CHALK_VALUE_TYPE_INTEGER)
          {
            mpz_abs(currentValue.integer, currentValue.integer);
            done = YES;
          }//end if (currentValue.type == CHALK_VALUE_TYPE_INTEGER)
          else if (currentValue.type == CHALK_VALUE_TYPE_FRACTION)
          {
            mpq_abs(currentValue.fraction, currentValue.fraction);
            done = YES;
          }//end if (currentValue.type == CHALK_VALUE_TYPE_INTEGER)
          else if (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT)
          {
            mpfr_abs(currentValue.realExact, currentValue.realExact, MPFR_RNDN);
            done = YES;
          }//end if (currentValue.type == CHALK_VALUE_TYPE_INTEGER)
          else if (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX)
          {
            mpfir_abs(currentValue.realApprox, currentValue.realApprox);
            done = YES;
          }//end if (currentValue.type == CHALK_VALUE_TYPE_INTEGER)
        }//end if (!done)
        if (!done)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                 replace:NO];
        else//if (done)
        {
          chalkGmpValueSimplify(&currentValue, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
          CHChalkValueNumberGmp* value =
            [[[CHChalkValueNumberGmp alloc] initWithToken:token value:&currentValue naturalBase:operandGmp.naturalBase context:context] autorelease];
          if (!value)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                   replace:NO];
          value.evaluationComputeFlags |= chalkGmpFlagsMake();
          result = [value retain];
        }//end if (done)
        chalkGmpValueClear(&currentValue, YES, context.gmpPool);
      }//end if (operandValueGmp)
      else
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorOperationNonImplemented range:token.range]
                               replace:NO];
      result.evaluationComputeFlags |=
        operandValue.evaluationComputeFlags |
        chalkGmpFlagsMake();
    }//end @autoreleasepool
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineAbs:token:context:

+(CHChalkValue*) combineAbs2:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    @autoreleasepool {
      CHChalkValue* operandValue = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueScalar* operandScalar = [operandValue dynamicCastToClass:[CHChalkValueScalar class]];
      CHChalkValueNumberGmp* operandGmp = [operandScalar dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueFormal* operandFormal = [operandValue dynamicCastToClass:[CHChalkValueFormal class]];
      operandGmp = !operandFormal ? operandGmp : operandFormal.value;
      CHChalkValueQuaternion* operandQuaternion = [operandScalar dynamicCastToClass:[CHChalkValueQuaternion class]];
      CHChalkValueMatrix* operandMatrix = [operandValue dynamicCastToClass:[CHChalkValueMatrix class]];
      CHChalkValueList* operandList = [operandValue dynamicCastToClass:[CHChalkValueList class]];
      if (operandList)
        result = [[self combineSEL:_cmd arguments:operands list:operandList index:0 token:token context:context] retain];
      else if (operandMatrix)
      {
        CHChalkValueMatrix* newMatrix = [[self combineMatrixSEL:_cmd operand:operandMatrix token:token context:context] retain];
        if (context.errorContext.hasError)
        {
          [newMatrix release];
          newMatrix = nil;
        }//end if (context.errorContext.hasError)
        result = newMatrix;
      }//end if (operandMatrix)
      else if (operandQuaternion)
      {
        CHChalkValueNumber* partR = operandQuaternion.partReal;
        CHChalkValueNumber* partI = operandQuaternion.partI;
        CHChalkValueNumber* partJ = operandQuaternion.partJ;
        CHChalkValueNumber* partK = operandQuaternion.partK;
        CHChalkValue* partR2 = !partR ? nil : [CHParserFunctionNode combineSqr:@[partR] token:token context:context];
        CHChalkValue* partI2 = !partI ? nil : [CHParserFunctionNode combineSqr:@[partI] token:token context:context];
        CHChalkValue* partJ2 = !partJ ? nil : [CHParserFunctionNode combineSqr:@[partJ] token:token context:context];
        CHChalkValue* partK2 = !partK ? nil : [CHParserFunctionNode combineSqr:@[partK] token:token context:context];
        CHChalkValue* value = !partR2 || !partI2 || !partJ2 || !partK2 ? nil :
          [CHParserOperatorNode combineAdd:@[partR2, partI2, partJ2, partK2] operatorToken:token context:context];
        if (!value)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                 replace:NO];
        result = [value retain];
      }//end if (operandQuaternion)
      else if (operandGmp)
      {
        mpfr_clear_flags();
        const chalk_gmp_value_t* operand = operandGmp.valueConstReference;
        chalk_gmp_value_t currentValue = {0};
        chalkGmpValueSet(&currentValue, operand, context.gmpPool);
        BOOL done = NO;
        if (!done)
        {
          if (currentValue.type == CHALK_VALUE_TYPE_INTEGER)
          {
            mpz_mul(currentValue.integer, operand->integer, operand->integer);
            done = YES;
          }//end if (currentValue.type == CHALK_VALUE_TYPE_INTEGER)
          else if (currentValue.type == CHALK_VALUE_TYPE_FRACTION)
          {
            mpq_mul(currentValue.fraction, operand->fraction, operand->fraction);
            done = YES;
          }//end if (currentValue.type == CHALK_VALUE_TYPE_FRACTION)
          else if (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT)
          {
            mpfr_mul(currentValue.realExact, operand->realExact, operand->realExact, MPFR_RNDN);
            done = YES;
          }//end if (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT)
          else if (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX)
          {
            mpfir_mul(currentValue.realApprox, operand->realApprox, operand->realApprox);
            done = YES;
          }//end if (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX)
        }//end if (!done)
        if (!done)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                 replace:NO];
        else//if (done)
        {
          chalkGmpValueSimplify(&currentValue, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
          CHChalkValueNumberGmp* value =
            [[[CHChalkValueNumberGmp alloc] initWithToken:token value:&currentValue naturalBase:operandGmp.naturalBase context:context] autorelease];
          if (!value)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                   replace:NO];
          value.evaluationComputeFlags |= chalkGmpFlagsMake();
          result = [value retain];
        }//end if (done)
        chalkGmpValueClear(&currentValue, YES, context.gmpPool);
      }//end if (operandValueGmp)
      else
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorOperationNonImplemented range:token.range]
                               replace:NO];
      result.evaluationComputeFlags |=
        operandValue.evaluationComputeFlags |
        chalkGmpFlagsMake();
    }//end @autoreleasepool
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineAbs2:token:context:

+(CHChalkValue*) combineAngle:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    @autoreleasepool {
      CHChalkValue* operandValue = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueList* operandList = [operandValue dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValueQuaternion* operandQuaternion = [operandValue dynamicCastToClass:[CHChalkValueQuaternion class]];
      CHChalkValueNumberGmp* operandGmp = [operandValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueFormal* operandFormal = [operandValue dynamicCastToClass:[CHChalkValueFormal class]];
      operandGmp = !operandFormal ? operandGmp : operandFormal.value;
      if (operandQuaternion.isReal)
      {
        operandGmp = [operandQuaternion.partReal dynamicCastToClass:[CHChalkValueNumberGmp class]];
        if (operandGmp)
          operandQuaternion = nil;
      }//end if (operandQuaternion.isReal)
      BOOL done = NO;
      if (operandList)
        result = [[self combineSEL:_cmd arguments:operands list:operandList index:0 token:token context:context] retain];
      else if (operandQuaternion)
      {
        if (!operandQuaternion.isComplex)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericInvalid range:token.range]
                                 replace:NO];
        else//if (operandQuaternion.isComplex)
        {
          CHChalkValueNumber* x = operandQuaternion.partReal;
          CHChalkValueNumber* y = operandQuaternion.partI;
          if (!x || !y)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                   replace:NO];
          else//if (x && y)
          {
            CHChalkValue* value = [self combineATan2:@[y,x] token:token context:context];
            result = [value retain];
          }//end if (x && y)
        }//end if (operandQuaternion.isComplex)
      }//end if (operandQuaternion)
      else if (operandGmp)
      {
        mpfr_clear_flags();
        const chalk_gmp_value_t* operand = operandGmp.valueConstReference;
        chalk_gmp_value_t currentValue = {0};
        chalkGmpValueSetZero(&currentValue, NO, context.gmpPool);
        NSInteger sign = chalkGmpValueSign(operand);
        if (sign<0)
        {
          mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
          chalkGmpValueMakeRealApprox(&currentValue, prec, context.gmpPool);
          mpfir_const_pi(currentValue.realApprox);
          done = YES;
        }
        else if ((sign>0) || operandGmp.isZero)
        {
          chalkGmpValueSetZero(&currentValue, NO, context.gmpPool);
          done = YES;
        }//end if (sign>0)
        else//if ((sign == 0) && !operandGmp.isZero)
        {
          chalkGmpValueSetNan(&currentValue, YES, context.gmpPool);
          done = YES;
        }//end if ((sign == 0) && !operandGmp.isZero)
        if (!done)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                 replace:NO];
        else//if (done)
        {
          chalkGmpValueSimplify(&currentValue, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
          CHChalkValueNumberGmp* value =
            [[[CHChalkValueNumberGmp alloc] initWithToken:token value:&currentValue naturalBase:operandGmp.naturalBase context:context] autorelease];
          if (!value)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                   replace:NO];
          value.evaluationComputeFlags |= chalkGmpFlagsMake();
          result = [value retain];
        }//end if (done)
        chalkGmpValueClear(&currentValue, YES, context.gmpPool);
      }//if (operandQuaternion || operandGmp)
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
//end combineAngle:token:context:

+(CHChalkValue*) combineAngles:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    @autoreleasepool {
      CHChalkValue* operandValue = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueList* operandList = [operandValue dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValueQuaternion* operandQuaternion = [operandValue dynamicCastToClass:[CHChalkValueQuaternion class]];
      CHChalkValueNumberGmp* operandGmp = [operandValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueFormal* operandFormal = [operandValue dynamicCastToClass:[CHChalkValueFormal class]];
      operandGmp = !operandFormal ? operandGmp : operandFormal.value;
      if (operandQuaternion.isReal)
      {
        operandGmp = [operandQuaternion.partReal dynamicCastToClass:[CHChalkValueNumberGmp class]];
        if (operandGmp)
          operandQuaternion = nil;
      }//end if (operandQuaternion.isReal)
      if (operandList)
        result = [[self combineSEL:_cmd arguments:operands list:operandList index:0 token:token context:context] retain];
      else if (operandQuaternion)
      {
        CHChalkToken* emptyToken = [CHChalkToken chalkTokenEmpty];
        CHChalkValueQuaternion* conj = operandQuaternion.conjugated;
        CHChalkValue* n2 = !conj ? nil :
          [CHParserOperatorNode combineMul:@[operandQuaternion,conj] operatorToken:emptyToken context:context];
        CHChalkValue* n = !n2 ? nil :
          [CHParserFunctionNode combineSqrt:@[n2] token:emptyToken context:context];
        CHChalkValueQuaternion* u = !n ? nil :
          [[CHParserOperatorNode combineDiv:@[operandQuaternion,n] operatorToken:emptyToken context:context]
            dynamicCastToClass:[CHChalkValueQuaternion class]];
        CHChalkValueNumber* q0 = !u ? nil : u.partReal;
        CHChalkValueNumber* q1 = !u ? nil : u.partI;
        CHChalkValueNumber* q2 = !u ? nil : u.partJ;
        CHChalkValueNumber* q3 = !u ? nil : u.partK;
        if (!q0 || !q1 || !q2 || !q3)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                 replace:NO];
        else//if (q0 && q1 && q2 && q3)
        {
          CHChalkValue* one = [[[CHChalkValueNumberGmp alloc] initWithToken:emptyToken integer:1 naturalBase:context.computationConfiguration.baseDefault context:context] autorelease];
          CHChalkValue* two = [[[CHChalkValueNumberGmp alloc] initWithToken:emptyToken integer:2 naturalBase:context.computationConfiguration.baseDefault context:context] autorelease];
          CHChalkValue* q0q1 = [CHParserOperatorNode combineMul:@[q0,q1] operatorToken:emptyToken context:context];
          CHChalkValue* q2q3 = [CHParserOperatorNode combineMul:@[q2,q3] operatorToken:emptyToken context:context];
          CHChalkValue* q1q1 = [CHParserFunctionNode combineSqr:@[q1]            token:emptyToken context:context];
          CHChalkValue* q2q2 = [CHParserFunctionNode combineSqr:@[q2]            token:emptyToken context:context];
          CHChalkValue* q0q2 = [CHParserOperatorNode combineMul:@[q0,q2] operatorToken:emptyToken context:context];
          CHChalkValue* q3q1 = [CHParserOperatorNode combineMul:@[q3,q1] operatorToken:emptyToken context:context];
          CHChalkValue* q0q3 = [CHParserOperatorNode combineMul:@[q0,q3] operatorToken:emptyToken context:context];
          CHChalkValue* q1q2 = [CHParserOperatorNode combineMul:@[q1,q2] operatorToken:emptyToken context:context];
          CHChalkValue* q3q3 = [CHParserFunctionNode combineSqr:@[q3]            token:emptyToken context:context];
          CHChalkValue* phi_num_sum = !q0q1 || !q2q3 ? nil :
            [CHParserOperatorNode combineAdd:@[q0q1, q2q3] operatorToken:emptyToken context:context];
          CHChalkValue* phi_num = !two || !phi_num_sum ? nil :
            [CHParserOperatorNode combineMul:@[two, phi_num_sum] operatorToken:emptyToken context:context];
          CHChalkValue* phi_denom_sum = !q1q1 || !q2q2 ? nil :
            [CHParserOperatorNode combineAdd:@[q1q1, q2q2] operatorToken:emptyToken context:context];
          CHChalkValue* phi_denom_2sum = !two || !phi_denom_sum ? nil :
            [CHParserOperatorNode combineMul:@[two, phi_denom_sum] operatorToken:emptyToken context:context];
          CHChalkValue* phi_denom = !one || !phi_denom_2sum ? nil :
            [CHParserOperatorNode combineSub:@[one, phi_denom_2sum] operatorToken:emptyToken context:context];
          CHChalkValue* phi = !phi_num || !phi_denom ? nil :
            [self combineATan2:@[phi_num, phi_denom] token:emptyToken context:context];
          CHChalkValue* theta_sum = !q0q2 || !q3q1 ? nil :
            [CHParserOperatorNode combineSub:@[q0q2, q3q1] operatorToken:emptyToken context:context];
          CHChalkValue* theta_2sum = !two || !theta_sum ? nil :
            [CHParserOperatorNode combineMul:@[two, theta_sum] operatorToken:emptyToken context:context];
          CHChalkValue* theta = !two || !theta_sum ? nil :
            [self combineASin:@[theta_2sum] token:emptyToken context:context];
          CHChalkValue* psi_num_sum = !q0q3 || !q1q2 ? nil :
            [CHParserOperatorNode combineAdd:@[q0q3, q1q2] operatorToken:emptyToken context:context];
          CHChalkValue* psi_num = !two || !psi_num_sum ? nil :
            [CHParserOperatorNode combineMul:@[two, psi_num_sum] operatorToken:emptyToken context:context];
          CHChalkValue* psi_denom_sum = !q2q2 || !q3q3 ? nil :
            [CHParserOperatorNode combineAdd:@[q2q2, q3q3] operatorToken:emptyToken context:context];
          CHChalkValue* psi_denom_2sum = !two || !psi_denom_sum ? nil :
            [CHParserOperatorNode combineMul:@[two, psi_denom_sum] operatorToken:emptyToken context:context];
          CHChalkValue* psi_denom = !one || !psi_denom_2sum ? nil :
            [CHParserOperatorNode combineSub:@[one, psi_denom_2sum] operatorToken:emptyToken context:context];
          CHChalkValue* psi = !psi_num || !psi_denom ? nil :
            [self combineATan2:@[psi_num, psi_denom] token:emptyToken context:context];
          result = !phi || !theta || !psi ? nil :
            [[CHChalkValueMatrix alloc] initWithToken:token rowsCount:3 colsCount:1 values:@[phi,theta,psi] context:context];
          if (!result)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                   replace:NO];
        }//end if (q0 && q1 && q2 && q3)
      }//end if (operandQuaternion)
      else if (operandGmp)
      {
        result = [[CHChalkValueMatrix alloc] initWithToken:token rowsCount:3 colsCount:1 value:[CHChalkValueNumberGmp zeroWithToken:[CHChalkToken chalkTokenEmpty] context:context] context:context];
        if (!result)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                 replace:NO];
      }//end if (operandGmp)
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
//end combineAngles:token:context:

+(CHChalkValue*) combineFloor:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    @autoreleasepool {
      CHChalkValue* operandValue = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueNumberGmp* operandGmp = [operandValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueFormal* operandFormal = [operandValue dynamicCastToClass:[CHChalkValueFormal class]];
      operandGmp = !operandFormal ? operandGmp : operandFormal.value;
      CHChalkValueList* operandList = [operandValue dynamicCastToClass:[CHChalkValueList class]];
      if (operandList)
        result = [[self combineSEL:_cmd arguments:operands list:operandList index:0 token:token context:context] retain];
      else if (operandGmp)
      {
        mpfr_clear_flags();
        mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
        const chalk_gmp_value_t* operand = operandGmp.valueConstReference;
        chalk_compute_flags_t computeFlags = 0;
        chalk_gmp_value_t currentValue = {0};
        chalkGmpValueSet(&currentValue, operand, context.gmpPool);
        BOOL done = NO;
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_INTEGER))
          done = YES;
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_FRACTION))
        {
          chalkGmpValueMakeInteger(&currentValue, context.gmpPool);
          mpz_fdiv_q(currentValue.integer, mpq_numref(operand->fraction), mpq_denref(operand->fraction));
          done = YES;
        }//end if (!done && (currentValue.type == CHALK_VALUE_TYPE_FRACTION))
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT))
        {
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
          mpfr_floor(currentValue.realExact, currentValue.realExact);
          done = !mpfr_inexflag_p();
          if (done)
            computeFlags |= chalkGmpFlagsMake();
          else//if (!done)
          {
            chalkGmpValueSet(&currentValue, operand, context.gmpPool);
            chalkGmpValueMakeRealApprox(&currentValue, prec, context.gmpPool);
          }//end if (!done)
          chalkGmpFlagsRestore(oldFlags);
        }//end if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT))
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX))
        {
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
          mpfir_floor(currentValue.realApprox, currentValue.realApprox);
          computeFlags |= chalkGmpFlagsMake();
          done = YES;
          chalkGmpFlagsRestore(oldFlags);
        }//end if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX))
        if (!done)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                 replace:NO];
        else
        {
          chalkGmpValueSimplify(&currentValue, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
          CHChalkValue* value = !done ? nil :
            [[CHChalkValueNumberGmp alloc] initWithToken:token value:&currentValue naturalBase:operandGmp.naturalBase context:context];
          if (!value)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                   replace:NO];
          value.evaluationComputeFlags |= computeFlags | chalkGmpFlagsMake();
          result = value;
        }//end
        chalkGmpValueClear(&currentValue, YES, context.gmpPool);
      }//if (operandGmp)
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
//end combineFloor:token:context:

+(CHChalkValue*) combineCeil:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    @autoreleasepool {
      CHChalkValue* operandValue = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueNumberGmp* operandGmp = [operandValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueFormal* operandFormal = [operandValue dynamicCastToClass:[CHChalkValueFormal class]];
      operandGmp = !operandFormal ? operandGmp : operandFormal.value;
      CHChalkValueList* operandList = [operandValue dynamicCastToClass:[CHChalkValueList class]];
      if (operandList)
        result = [[self combineSEL:_cmd arguments:operands list:operandList index:0 token:token context:context] retain];
      else if (operandGmp)
      {
        mpfr_clear_flags();
        mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
        const chalk_gmp_value_t* operand = operandGmp.valueConstReference;
        chalk_compute_flags_t computeFlags = 0;
        chalk_gmp_value_t currentValue = {0};
        chalkGmpValueSet(&currentValue, operand, context.gmpPool);
        BOOL done = NO;
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_INTEGER))
          done = YES;
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_FRACTION))
        {
          chalkGmpValueMakeInteger(&currentValue, context.gmpPool);
          mpz_cdiv_q(currentValue.integer, mpq_numref(operand->fraction), mpq_denref(operand->fraction));
          done = YES;
        }//end if (!done && (currentValue.type == CHALK_VALUE_TYPE_FRACTION))
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT))
        {
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
          mpfr_ceil(currentValue.realExact, currentValue.realExact);
          done = !mpfr_inexflag_p();
          if (done)
            computeFlags |= chalkGmpFlagsMake();
          else//if (!done)
          {
            chalkGmpValueSet(&currentValue, operand, context.gmpPool);
            chalkGmpValueMakeRealApprox(&currentValue, prec, context.gmpPool);
          }//end if (!done)
          chalkGmpFlagsRestore(oldFlags);
        }//end if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT))
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX))
        {
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
          mpfir_ceil(currentValue.realApprox, currentValue.realApprox);
          computeFlags |= chalkGmpFlagsMake();
          done = YES;
          chalkGmpFlagsRestore(oldFlags);
        }//end if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX))
        if (!done)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                 replace:NO];
        else
        {
          chalkGmpValueSimplify(&currentValue, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
          CHChalkValue* value = !done ? nil :
            [[CHChalkValueNumberGmp alloc] initWithToken:token value:&currentValue naturalBase:operandGmp.naturalBase context:context];
          if (!value)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                   replace:NO];
          value.evaluationComputeFlags |= computeFlags | chalkGmpFlagsMake();
          result = value;
        }//end
        chalkGmpValueClear(&currentValue, YES, context.gmpPool);
      }//if (operandGmp)
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
//end combineCeil:token:context:

+(CHChalkValue*) combineInv:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if ((operands.count != 1) && (operands.count != 2))
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else if (operands.count == 2)
  {
    CHChalkValue* operand1Value = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
    CHChalkValue* operand2Value = [[operands objectAtIndex:1] dynamicCastToClass:[CHChalkValue class]];
    CHChalkValueNumberGmp* operand1Number = [operand1Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
    CHChalkValueNumberGmp* operand2Number = [operand2Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
    CHChalkValueList* operand1List = [operand1Value dynamicCastToClass:[CHChalkValueList class]];
    CHChalkValueList* operand2List = [operand2Value dynamicCastToClass:[CHChalkValueList class]];
    if (operand1List)
      result = [[self combineSEL:_cmd arguments:operands list:operand1List index:0 token:token context:context] retain];
    else if (operand2List)
      result = [[self combineSEL:_cmd arguments:operands list:operand2List index:1 token:token context:context] retain];
    else if ((operand1Number.valueType != CHALK_VALUE_TYPE_INTEGER) || (operand2Number.valueType != CHALK_VALUE_TYPE_INTEGER))
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                             replace:NO];
    else//if ((operand1Number.valueType == CHALK_VALUE_TYPE_INTEGER) && (operand2Number.valueType == CHALK_VALUE_TYPE_INTEGER))
    {
      chalk_gmp_value_t currentValue = {0};
      if (chalkGmpValueMakeInteger(&currentValue, context.gmpPool))
      {
        if (chalkGmpValueIsZero(&currentValue, 0) || !mpz_invert(currentValue.integer, operand1Number.valueConstReference->integer, operand2Number.valueConstReference->integer))
        {
          mpfr_set_divby0();
          chalkGmpValueSetNan(&currentValue, YES, context.gmpPool);
        }
      }//end if (chalkGmpValueMakeInteger(&currentValue, context.gmpPool))
      CHChalkValueNumberGmp* value =
        [[[CHChalkValueNumberGmp alloc] initWithToken:token value:&currentValue naturalBase:operand1Number.naturalBase context:context] autorelease];
      if (!value)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      value.evaluationComputeFlags |= chalkGmpFlagsMake();
      result = [value retain];
      chalkGmpValueClear(&currentValue, YES, context.gmpPool);
      result.evaluationComputeFlags |=
        operand1Number.evaluationComputeFlags |
        operand2Number.evaluationComputeFlags;
    }//end if (operand1 && operand2)
  }//end if (operands.count == 2)
  else//if (operands.count == 1)
  {
    @autoreleasepool {
      CHChalkValue* operandValue = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueMatrix* operandMatrix = [operandValue dynamicCastToClass:[CHChalkValueMatrix class]];
      CHChalkValueQuaternion* operandQuaternion = [operandValue dynamicCastToClass:[CHChalkValueQuaternion class]];
      CHChalkValueNumberGmp* operandGmp = [operandValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueFormal* operandFormal = [operandValue dynamicCastToClass:[CHChalkValueFormal class]];
      operandGmp = !operandFormal ? operandGmp : operandFormal.value;
      CHChalkValueList* operandList = [operandValue dynamicCastToClass:[CHChalkValueList class]];
      if (operandList)
        result = [[self combineSEL:_cmd arguments:operands list:operandList index:0 token:token context:context] retain];
      else if (operandMatrix)
        result = [[operandMatrix invertedWithContext:context] retain];
      else if (operandValue.isZero)
      {
        if (!context.computationConfiguration.propagateNaN)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericInvalid range:token.range]
                                 replace:NO];
        CHChalkValueNumberGmp* nan = [CHChalkValueNumberGmp nanWithContext:context];
        if (nan)
          result = [nan retain];
        else//if (nan)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorAllocation range:token.range]
                                 replace:NO];
      }//end if (operandValue.isZero)
      else if (operandQuaternion)
      {
        CHChalkValue* numerator = [operandQuaternion conjugated];
        CHChalkValue* denominator = [self combineAbs2:@[operandQuaternion] token:token context:context];
        CHChalkValue* value = !numerator || !denominator ? nil :
          [CHParserOperatorNode combineDiv:@[numerator, denominator] operatorToken:token context:context];
        result = [value retain];
      }//end if (operandQuaternion)
      else if (operandGmp)
      {
        mpfr_clear_flags();
        const chalk_gmp_value_t* operand = operandGmp.valueConstReference;
        chalk_gmp_value_t currentValue = {0};
        chalkGmpValueSet(&currentValue, operand, context.gmpPool);
        BOOL done = chalkGmpValueInvert(&currentValue, context.gmpPool);
        if (!done)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                 replace:NO];
        else//if (done)
        {
          chalkGmpValueSimplify(&currentValue, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
          CHChalkValueNumberGmp* value =
            [[[CHChalkValueNumberGmp alloc] initWithToken:token value:&currentValue naturalBase:operandGmp.naturalBase context:context] autorelease];
          if (!value)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                   replace:NO];
          value.evaluationComputeFlags |= chalkGmpFlagsMake();
          result = [value retain];
        }//end if (done)
        chalkGmpValueClear(&currentValue, YES, context.gmpPool);
      }//if (operandGmp)
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
//end combineInv:token:context:

+(CHChalkValue*) combineSqrt:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    @autoreleasepool {
      CHChalkValue* operandValue = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueNumberGmp* operandGmp = [operandValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueFormal* operandFormal = [operandValue dynamicCastToClass:[CHChalkValueFormal class]];
      operandGmp = !operandFormal ? operandGmp : operandFormal.value;
      CHChalkValueList* operandList = [operandValue dynamicCastToClass:[CHChalkValueList class]];
      if (operandList)
        result = [[self combineSEL:_cmd arguments:operands list:operandList index:0 token:token context:context] retain];
      else if (operandGmp)
      {
        mpfr_clear_flags();
        mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
        const chalk_gmp_value_t* operand = operandGmp.valueConstReference;
        chalk_compute_flags_t computeFlags = 0;
        chalk_gmp_value_t currentValue = {0};
        chalkGmpValueSet(&currentValue, operand, context.gmpPool);
        BOOL done = NO;
        BOOL allowFormal = NO;
        BOOL formalDone = NO;
        if (!done && chalkGmpValueSign(&currentValue)<0)
        {
          chalkGmpValueSetNan(&currentValue, YES, context.gmpPool);
          if (!context.computationConfiguration.propagateNaN)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericInvalid range:token.range]
                                   replace:NO];
          done = YES;
        }//end if (!done && chalkGmpValueSign(&currentValue)<0)
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_INTEGER))
        {
          if (!mpz_perfect_square_p(currentValue.integer))
            chalkGmpValueMakeReal(&currentValue, prec, context.gmpPool);
          else//if (mpz_perfect_square_p(currentValue.integer))
          {
            mpz_sqrt(currentValue.integer, currentValue.integer);
            done = YES;
          }//end if (mpz_perfect_square_p(currentValue.integer))
        }//end if (!done && (currentValue.type == CHALK_VALUE_TYPE_INTEGER))
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_FRACTION))
        {
          if (!mpz_perfect_square_p(mpq_numref(currentValue.fraction)) || !mpz_perfect_square_p(mpq_denref(currentValue.fraction)))
            chalkGmpValueMakeReal(&currentValue, prec, context.gmpPool);
          else//if (mpz_perfect_square_p(mpq_numref(currentValue.fraction)) && mpz_perfect_square_p(mpq_denref(currentValue.fraction)))
          {
            mpz_sqrt(mpq_numref(currentValue.fraction), mpq_numref(currentValue.fraction));
            mpz_sqrt(mpq_denref(currentValue.fraction), mpq_denref(currentValue.fraction));
            done = YES;
          }//end if (mpz_perfect_square_p(mpq_numref(currentValue.fraction)) && mpz_perfect_square_p(mpq_denref(currentValue.fraction)))
        }//end if (!done && (currentValue.type == CHALK_VALUE_TYPE_FRACTION))
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT))
        {
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
          mpfr_sqrt(currentValue.realExact, currentValue.realExact, MPFR_RNDN);
          done = !mpfr_inexflag_p();
          if (done)
            computeFlags |= chalkGmpFlagsMake();
          else//if (!done)
          {
            if (allowFormal && (context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_EXACT))
            {
              CHChalkValueFormalSimple* value = [[CHChalkValueFormalSimple alloc] initWithToken:token context:context];
              if (!value)
                [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                       replace:NO];
              chalk_gmp_value_t power = {0};
              chalkGmpValueMakeFraction(&power, context.gmpPool);
              mpq_set_ui(power.fraction, 1, 2);
              value.power = [[[CHChalkValueNumberGmp alloc] initWithToken:token value:&power naturalBase:operandGmp.naturalBase context:context] autorelease];
              chalkGmpValueClear(&power, YES, context.gmpPool);
              value.baseValue = operandGmp;
              result = value;
              done = !context.errorContext.hasError;
              formalDone = !context.errorContext.hasError;
            }//end if (allowFormal && (context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_EXACT))
            else//if (!allowFormal || !context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_EXACT)
            {
              chalkGmpValueSet(&currentValue, operand, context.gmpPool);
              chalkGmpValueMakeRealApprox(&currentValue, prec, context.gmpPool);
            }//end if (!allowFormal || !context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_EXACT)
          }//end if (!done)
          chalkGmpFlagsRestore(oldFlags);
        }//end if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT))
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX))
        {
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
          mpfir_sqrt(currentValue.realApprox, currentValue.realApprox);
          computeFlags |= chalkGmpFlagsMake();
          done = YES;
          chalkGmpFlagsRestore(oldFlags);
        }//end if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX))
        if (!done)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                 replace:NO];
        else if (!formalDone)
        {
          chalkGmpValueSimplify(&currentValue, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
          CHChalkValue* value = !done ? nil :
            [[CHChalkValueNumberGmp alloc] initWithToken:token value:&currentValue naturalBase:operandGmp.naturalBase context:context];
          if (!value)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                   replace:NO];
          value.evaluationComputeFlags |= computeFlags | chalkGmpFlagsMake();
          result = value;
        }//end if (!formalDone)
        chalkGmpValueClear(&currentValue, YES, context.gmpPool);
      }//if (operandGmp)
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
//end combineSqrt:token:context:

+(CHChalkValue*) combineCbrt:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    @autoreleasepool {
      CHChalkValue* operandValue = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueNumberGmp* operandGmp = [operandValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueFormal* operandFormal = [operandValue dynamicCastToClass:[CHChalkValueFormal class]];
      operandGmp = !operandFormal ? operandGmp : operandFormal.value;
      CHChalkValueList* operandList = [operandValue dynamicCastToClass:[CHChalkValueList class]];
      if (operandList)
        result = [[self combineSEL:_cmd arguments:operands list:operandList index:0 token:token context:context] retain];
      else if (operandGmp)
      {
        mpfr_clear_flags();
        mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
        const chalk_gmp_value_t* operand = operandGmp.valueConstReference;
        chalk_compute_flags_t computeFlags = 0;
        chalk_gmp_value_t currentValue = {0};
        chalkGmpValueSet(&currentValue, operand, context.gmpPool);
        BOOL done = NO;
        if (!done && chalkGmpValueSign(&currentValue)<0)
        {
          chalkGmpValueSetNan(&currentValue, YES, context.gmpPool);
          if (!context.computationConfiguration.propagateNaN)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericInvalid range:token.range]
                                   replace:NO];
          done = YES;
        }//end if (!done && chalkGmpValueSign(&currentValue)<0)
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_INTEGER))
        {
          done = (mpz_root(currentValue.integer, currentValue.integer, 3) != 0);
          if (!done)
          {
            chalkGmpValueSet(&currentValue, operand, context.gmpPool);
            chalkGmpValueMakeReal(&currentValue, prec, context.gmpPool);
          }//end if (!done)
        }//end if (!done && (currentValue.type == CHALK_VALUE_TYPE_INTEGER))
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_FRACTION))
        {
          done = (mpz_root(mpq_numref(currentValue.fraction), mpq_numref(currentValue.fraction), 3) != 0) &&
                 (mpz_root(mpq_denref(currentValue.fraction), mpq_denref(currentValue.fraction), 3) != 0);
          if (!done)
          {
            chalkGmpValueSet(&currentValue, operand, context.gmpPool);
            chalkGmpValueMakeReal(&currentValue, prec, context.gmpPool);
          }//end if (!done)
        }//end if (!done && (currentValue.type == CHALK_VALUE_TYPE_FRACTION))
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT))
        {
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
          mpfr_cbrt(currentValue.realExact, currentValue.realExact, MPFR_RNDN);
          done = !mpfr_inexflag_p();
          if (done)
            computeFlags |= chalkGmpFlagsMake();
          else//if (!done)
          {
            chalkGmpValueSet(&currentValue, operand, context.gmpPool);
            chalkGmpValueMakeRealApprox(&currentValue, prec, context.gmpPool);
          }//end if (!done)
          chalkGmpFlagsRestore(oldFlags);
        }//end if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT))
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX))
        {
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
          mpfir_cbrt(currentValue.realApprox, currentValue.realApprox);
          computeFlags |= chalkGmpFlagsMake();
          done = YES;
          chalkGmpFlagsRestore(oldFlags);
        }//end if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX))
        if (!done)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                 replace:NO];
        else//if (done)
        {
          chalkGmpValueSimplify(&currentValue, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
          CHChalkValue* value = !done ? nil :
            [[CHChalkValueNumberGmp alloc] initWithToken:token value:&currentValue naturalBase:operandGmp.naturalBase context:context];
          if (!value)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                   replace:NO];
          value.evaluationComputeFlags |= computeFlags | chalkGmpFlagsMake();
          result = value;
        }//end if (done)
        chalkGmpValueClear(&currentValue, YES, context.gmpPool);
      }//if (operandGmp)
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
//end combineCbrt:token:context:

+(CHChalkValue*) combineRoot:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
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
      CHChalkValueList* operand1List = [operand1Value dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValue* operand2Value = [[operands objectAtIndex:1] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueNumberGmp* operand2Gmp = [operand2Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueList* operand2List = [operand2Value dynamicCastToClass:[CHChalkValueList class]];
      if (operand1List)
        result = [[self combineSEL:_cmd arguments:operands list:operand1List index:0 token:token context:context] retain];
      else if (operand2List)
        result = [[self combineSEL:_cmd arguments:operands list:operand2List index:1 token:token context:context] retain];
      else if (operand1Gmp && operand2Gmp && (operand2Gmp.valueType == CHALK_VALUE_TYPE_INTEGER))
      {
        if (!mpz_fits_ulong_p(operand2Gmp.valueConstReference->integer))
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainGmp reason:CHChalkErrorGmpOverflow range:token.range]
                                 replace:NO];
        else//if (!mpz_fits_ulong_p(operand2Gmp.valueConstReference->integer))
        {
          unsigned long rootPower = mpz_get_ui(operand2Gmp.valueConstReference->integer);
          if (rootPower == 0)
          {
            result = [[CHChalkValueNumberGmp alloc] initWithToken:token uinteger:1 naturalBase:operand1Gmp.naturalBase context:context];
            if (!result)
              [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                     replace:NO];
          }//end if (rootPower == 0)
          else if (rootPower == 1)
          {
            result = [operand1Value copy];
            //[operand1Value.token unionWithToken:token];//experimental
            if (!result)
              [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                     replace:NO];
          }//end if (rootPower == 1)
          else//if (rootPower > 1)
          {
            mpfr_clear_flags();
            mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
            const chalk_gmp_value_t* operand = operand1Gmp.valueConstReference;
            chalk_compute_flags_t computeFlags = 0;
            chalk_gmp_value_t currentValue = {0};
            chalkGmpValueSet(&currentValue, operand, context.gmpPool);
            BOOL done = NO;
            if (!done && chalkGmpValueSign(&currentValue)<0)
            {
              chalkGmpValueSetNan(&currentValue, YES, context.gmpPool);
              if (!context.computationConfiguration.propagateNaN)
                [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericInvalid range:token.range]
                                       replace:NO];
              done = YES;
            }//end if (!done && chalkGmpValueSign(&currentValue)<0)
            if (!done && (currentValue.type == CHALK_VALUE_TYPE_INTEGER))
            {
              if (!mpz_perfect_power_p(currentValue.integer))
                chalkGmpValueMakeReal(&currentValue, prec, context.gmpPool);
              else//if (mpz_perfect_power_p(currentValue.integer))
              {
                done = (mpz_root(currentValue.integer, currentValue.integer, rootPower) != 0);
                if (!done)
                {
                  chalkGmpValueSet(&currentValue, operand, context.gmpPool);
                  chalkGmpValueMakeReal(&currentValue, prec, context.gmpPool);
                }//end if (!done)
              }//end if (mpz_perfect_square_p(currentValue.integer))
            }//end if (!done && (currentValue.type == CHALK_VALUE_TYPE_INTEGER))
            if (!done && (currentValue.type == CHALK_VALUE_TYPE_FRACTION))
            {
              if (!mpz_perfect_square_p(mpq_numref(currentValue.fraction)) || !mpz_perfect_square_p(mpq_denref(currentValue.fraction)))
                chalkGmpValueMakeReal(&currentValue, prec, context.gmpPool);
              else//if (mpz_perfect_square_p(mpq_numref(currentValue.fraction)) && mpz_perfect_square_p(mpq_denref(currentValue.fraction)))
              {
                BOOL done1 = (mpz_root(mpq_numref(currentValue.fraction), mpq_numref(currentValue.fraction), rootPower) != 0);
                BOOL done2 = (mpz_root(mpq_denref(currentValue.fraction), mpq_denref(currentValue.fraction), rootPower) != 0);
                done = done1 && done2;
                if (!done)
                {
                  chalkGmpValueSet(&currentValue, operand, context.gmpPool);
                  chalkGmpValueMakeReal(&currentValue, prec, context.gmpPool);
                }//end if (!done)
              }//end if (mpz_perfect_square_p(mpq_numref(currentValue.fraction)) && mpz_perfect_square_p(mpq_denref(currentValue.fraction)))
            }//end if (!done && (currentValue.type == CHALK_VALUE_TYPE_FRACTION))
            if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT))
            {
              chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
              if (rootPower == 2)
                mpfr_sqrt(currentValue.realExact, currentValue.realExact, MPFR_RNDN);
              else if (rootPower == 3)
                mpfr_cbrt(currentValue.realExact, currentValue.realExact, MPFR_RNDN);
              else
                mpfr_rootn_ui(currentValue.realExact, currentValue.realExact, rootPower, MPFR_RNDN);
              done = !mpfr_inexflag_p();
              if (done)
                computeFlags |= chalkGmpFlagsMake();
              else//if (!done)
              {
                chalkGmpValueSet(&currentValue, operand, context.gmpPool);
                chalkGmpValueMakeRealApprox(&currentValue, prec, context.gmpPool);
              }//end if (!done)
              chalkGmpFlagsRestore(oldFlags);
            }//end if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT))
            if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX))
            {
              chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
              if (rootPower == 2)
              {
                mpfir_sqrt(currentValue.realApprox, currentValue.realApprox);
                done = YES;
              }//end if (rootPower == 2)
              else if (rootPower == 3)
              {
                mpfir_cbrt(currentValue.realApprox, currentValue.realApprox);
                done = YES;
              }//end if (rootPower == 3)
              else//if (rootPower > 3)
              {
                CHChalkValueNumberGmp* power = [operand2Gmp copy];
                //[power.token unionWithToken:token];//experimental
                if (!power)
                  [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                         replace:NO];
                chalkGmpValueInvert(power.valueReference, context.gmpPool);
                CHChalkValue* value = !operand1Value || !power ? nil :
                  [[self combinePow:@[operand1Value,power] token:token context:context] retain];
                [power release];
                if (!value)
                  [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                         replace:NO];
                chalkGmpValueMove(&currentValue, ((CHChalkValueNumberGmp*)[value dynamicCastToClass:[CHChalkValueNumberGmp class]]).valueReference, context.gmpPool);
                [value release];
                computeFlags |= chalkGmpFlagsMake();
                chalkGmpFlagsRestore(oldFlags);
                done = YES;
              }//end if (rootPower > 3)
            }//end if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX))
            if (!done)
              [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                     replace:NO];
            else//if (done)
            {
              chalkGmpValueSimplify(&currentValue, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
              CHChalkValue* value = !done ? nil :
                [[CHChalkValueNumberGmp alloc] initWithToken:token value:&currentValue naturalBase:operand1Gmp.naturalBase context:context];
              if (!value)
                [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                       replace:NO];
              value.evaluationComputeFlags |= computeFlags | chalkGmpFlagsMake();
              result = value;
            }//end if (done)
            chalkGmpValueClear(&currentValue, YES, context.gmpPool);
          }//end if (rootPower > 1)
        }//end if (!mpz_fits_ulong_p(operand2Gmp.valueConstReference->integer))
      }//if (operand1Gmp && operand2Gmp && (operand2Gmp.valueType == CHALK_VALUE_TYPE_INTEGER))
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
//end combineRoot:token:context:

+(CHChalkValue*) combineExp:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    @autoreleasepool {
      CHChalkValue* operandValue = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueQuaternion* operandQuaternion = [operandValue dynamicCastToClass:[CHChalkValueQuaternion class]];
      CHChalkValueNumberGmp* operandGmp = [operandValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueFormal* operandFormal = [operandValue dynamicCastToClass:[CHChalkValueFormal class]];
      operandGmp = !operandFormal ? operandGmp : operandFormal.value;
      CHChalkValueList* operandList = [operandValue dynamicCastToClass:[CHChalkValueList class]];
      if (operandList)
        result = [[self combineSEL:_cmd arguments:operands list:operandList index:0 token:token context:context] retain];
      else if (operandQuaternion)
      {
        CHChalkValueNumber* partReal = operandQuaternion.partReal;
        CHChalkValue* expReal = !partReal ? nil :
          [self combineExp:@[partReal] token:token context:context];
        if (!expReal)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                 replace:NO];
        CHChalkValueQuaternion* imaginary = [[operandQuaternion copy] autorelease];
        //[imaginary.token unionWithToken:token];//experimental
        [imaginary setPartReal:[CHChalkValueNumberGmp zeroWithToken:[CHChalkToken chalkTokenEmpty] context:context] wrapped:YES];
        CHChalkValue* imaginaryNorm = !imaginary ? nil :
          [self combineAbs:@[imaginary] token:token context:context];
        if (imaginaryNorm.isZero)
          result = [expReal retain];
        else//if (!imaginaryNorm.isZero)
        {
          CHChalkValue* cosPart = !imaginaryNorm ? nil :
            [self combineCos:@[imaginaryNorm] token:token context:context];
          CHChalkValue* sinPart = !imaginaryNorm ? nil :
            [self combineSin:@[imaginaryNorm] token:token context:context];
          CHChalkValue* unitaryImaginary = !imaginaryNorm ? nil :
            [CHParserOperatorNode combineDiv:@[imaginary,imaginaryNorm] operatorToken:token context:context];
          CHChalkValue* sinPart2 = !unitaryImaginary || !sinPart ? nil :
            [CHParserOperatorNode combineMul:@[unitaryImaginary,sinPart] operatorToken:token context:context];
          CHChalkValue* imag = !cosPart || !sinPart2 ? nil :
            [CHParserOperatorNode combineAdd:@[cosPart,sinPart2] operatorToken:token context:context];
          CHChalkValue* product = !expReal || !imag ? nil :
            [CHParserOperatorNode combineMul:@[expReal, imag] operatorToken:token context:context];
          if (!product)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                   replace:NO];
          result = [product retain];
        }//end if (!imaginaryNorm.isZero)
      }//end if (operandQuaternion)
      else if (operandGmp)
      {
        mpfr_clear_flags();
        mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
        const chalk_gmp_value_t* operand = operandGmp.valueConstReference;
        chalk_compute_flags_t computeFlags = 0;
        chalk_gmp_value_t currentValue = {0};
        chalkGmpValueSet(&currentValue, operand, context.gmpPool);
        chalkGmpValueMakeReal(&currentValue, prec, context.gmpPool);
        BOOL done = NO;
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT))
        {
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
          mpfr_exp(currentValue.realExact, currentValue.realExact, MPFR_RNDN);
          done = !mpfr_inexflag_p();
          if (done)
            computeFlags |= chalkGmpFlagsMake();
          else//if (!done)
          {
            chalkGmpValueSet(&currentValue, operand, context.gmpPool);
            chalkGmpValueMakeRealApprox(&currentValue, prec, context.gmpPool);
          }//end //if (!done)
          chalkGmpFlagsRestore(oldFlags);
        }//end if (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT)
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX))
        {
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
          mpfir_exp(currentValue.realApprox, currentValue.realApprox);
          computeFlags |= chalkGmpFlagsMake();
          done = YES;
          chalkGmpFlagsRestore(oldFlags);
        }//end if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX))
        if (!done)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                 replace:NO];
        else//if (done)
        {
          chalkGmpValueSimplify(&currentValue, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
          CHChalkValueNumberGmp* value =
            [[[CHChalkValueNumberGmp alloc] initWithToken:token value:&currentValue naturalBase:operandGmp.naturalBase context:context] autorelease];
          if (!value)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                   replace:NO];
          value.evaluationComputeFlags |= computeFlags | chalkGmpFlagsMake();
          result = [value retain];
        }//end if (done)
        chalkGmpValueClear(&currentValue, YES, context.gmpPool);
      }//if (operandGmp)
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
//end combineExp:token:context:

+(CHChalkValue*) combineLn:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    @autoreleasepool {
      CHChalkValue* operandValue = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueQuaternion* operandQuaternion = [operandValue dynamicCastToClass:[CHChalkValueQuaternion class]];
      CHChalkValueNumberGmp* operandGmp = [operandValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueFormal* operandFormal = [operandValue dynamicCastToClass:[CHChalkValueFormal class]];
      operandGmp = !operandFormal ? operandGmp : operandFormal.value;
      CHChalkValueList* operandList = [operandValue dynamicCastToClass:[CHChalkValueList class]];
      if (operandList)
        result = [[self combineSEL:_cmd arguments:operands list:operandList index:0 token:token context:context] retain];
      else if (operandQuaternion)
      {
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericInvalid range:token.range]
                               replace:NO];
        CHChalkValue* norm = [self combineAbs:@[operandQuaternion] token:token context:context];
        if (norm.isZero)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericInvalid range:token.range]
                                 replace:NO];
        else//if (!norm.isZero)
        {
          CHChalkValueNumber* partReal = operandQuaternion.partReal;
          CHChalkValueQuaternion* imaginary = [[operandQuaternion copy] autorelease];
          //[imaginary.token unionWithToken:token];//experimental
          [imaginary setPartReal:[CHChalkValueNumberGmp zeroWithToken:[CHChalkToken chalkTokenEmpty] context:context] wrapped:YES];
          CHChalkValue* lnPart = !norm ? nil :
            [self combineLn:@[norm] token:token context:context];
          if (!lnPart)
           [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason: CHChalkErrorNumericInvalid range:token.range]
                                  replace:NO];
          CHChalkValue* imaginaryNorm = [self combineAbs:@[imaginary] token:token context:context];
          if (!imaginaryNorm)
           [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericInvalid range:token.range]
                                 replace:NO];
          else if (imaginaryNorm.isZero)
            result = [lnPart retain];
          else//if (!imaginaryNorm.isZero)
          {
            CHChalkValue* unitaryImaginary = !imaginaryNorm ? nil :
              [CHParserOperatorNode combineDiv:@[imaginary, imaginaryNorm] operatorToken:token context:context];
            CHChalkValue* arccosArg = !partReal || !norm ? nil :
              [CHParserOperatorNode combineDiv:@[partReal,norm] operatorToken:token context:context];
            CHChalkValue* factor = !arccosArg ? nil :
              [self combineACos:@[arccosArg] token:token context:context];
            CHChalkValue* product = !unitaryImaginary || !factor ? nil :
              [CHParserOperatorNode combineMul:@[unitaryImaginary, factor] operatorToken:token context:context];
            CHChalkValue* sum = !lnPart || !product ? nil :
              [self combineLn:@[lnPart, product] token:token context:context];
            if (!sum)
              [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                     replace:NO];
            result = [sum retain];
          }//end if (!imaginaryNorm.isZero)
        }//end if (!norm.isZero)
      }//end if (operandQuaternion)
      else if (operandGmp)
      {
        mpfr_clear_flags();
        mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
        const chalk_gmp_value_t* operand = operandGmp.valueConstReference;
        BOOL isOperandStrictlyNegative = (chalkGmpValueSign(operand) < 0);
        if (isOperandStrictlyNegative)
        {
          if (!context.computationConfiguration.propagateNaN)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericInvalid range:token.range]
                                   replace:NO];
          CHChalkValueNumberGmp* nan = [CHChalkValueNumberGmp nanWithContext:context];
          if (!nan)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorAllocation range:token.range]
                                   replace:NO];
          result = [nan retain];
        }//end if (isOperandStrictlyNegative)
        else//if (!isOperandStrictlyNegative)
        {
          chalk_gmp_value_t currentValue = {0};
          chalk_compute_flags_t computeFlags = 0;
          chalkGmpValueSet(&currentValue, operand, context.gmpPool);
          BOOL done = NO;
          if (chalkGmpValueIsOne(&currentValue, 0, operandGmp.evaluationComputeFlags))
          {
            chalkGmpValueSetZero(&currentValue, NO, context.gmpPool);
            done = YES;
          }
          
          if (!done)
            chalkGmpValueMakeReal(&currentValue, prec, context.gmpPool);

          if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT))
          {
            chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
            mpfr_log(currentValue.realExact, currentValue.realExact, MPFR_RNDN);
            done = !mpfr_inexflag_p();
            if (done)
              computeFlags |= chalkGmpFlagsMake();
            else//if (done)
            {
              chalkGmpValueSet(&currentValue, operand, context.gmpPool);
              chalkGmpValueMakeRealApprox(&currentValue, prec, context.gmpPool);
            }//end if (!done)
            chalkGmpFlagsRestore(oldFlags);
          }//end if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT))
          if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX))
          {
            chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
            mpfir_log(currentValue.realApprox, currentValue.realApprox);
            computeFlags |= chalkGmpFlagsMake();
            done = YES;
            chalkGmpFlagsRestore(oldFlags);
          }//end if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX))
          if (!done)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                   replace:NO];
          else//if (done)
          {
            chalkGmpValueSimplify(&currentValue, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
            CHChalkValueNumberGmp* value =
              [[[CHChalkValueNumberGmp alloc] initWithToken:token value:&currentValue naturalBase:operandGmp.naturalBase context:context] autorelease];
            if (!value)
              [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                     replace:NO];
            value.evaluationComputeFlags |= computeFlags | chalkGmpFlagsMake();
            result = [value retain];
          }//end if (done)
          chalkGmpValueClear(&currentValue, YES, context.gmpPool);
        }//end if (!isOperandStrictlyNegative)
      }//if (operandGmp)
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
//end combineLn:token:context:

+(CHChalkValue*) combineLog10:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    @autoreleasepool {
      CHChalkValue* operandValue = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueQuaternion* operandQuaternion = [operandValue dynamicCastToClass:[CHChalkValueQuaternion class]];
      CHChalkValueNumberGmp* operandGmp = [operandValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueFormal* operandFormal = [operandValue dynamicCastToClass:[CHChalkValueFormal class]];
      operandGmp = !operandFormal ? operandGmp : operandFormal.value;
      CHChalkValueList* operandList = [operandValue dynamicCastToClass:[CHChalkValueList class]];
      if (operandList)
        result = [[self combineSEL:_cmd arguments:operands list:operandList index:0 token:token context:context] retain];
      else if (operandQuaternion)
      {
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericInvalid range:token.range]
                               replace:NO];
        CHChalkValue* norm = [self combineAbs:@[operandQuaternion] token:token context:context];
        if (norm.isZero)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericInvalid range:token.range]
                                 replace:NO];
        else//if (!norm.isZero)
        {
          CHChalkValueNumber* partReal = operandQuaternion.partReal;
          CHChalkValueQuaternion* imaginary = [[operandQuaternion copy] autorelease];
          //[imaginary.token unionWithToken:token];//experimental
          [imaginary setPartReal:[CHChalkValueNumberGmp zeroWithToken:[CHChalkToken chalkTokenEmpty] context:context] wrapped:YES];
          CHChalkValue* log10Part = !norm ? nil :
            [self combineLog10:@[norm] token:token context:context];
          if (!log10Part)
           [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason: CHChalkErrorNumericInvalid range:token.range]
                                  replace:NO];
          CHChalkValue* imaginaryNorm = [self combineAbs:@[imaginary] token:token context:context];
          if (!imaginaryNorm)
           [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericInvalid range:token.range]
                                 replace:NO];
          else if (imaginaryNorm.isZero)
            result = [log10Part retain];
          else//if (!imaginaryNorm.isZero)
          {
            CHChalkValue* unitaryImaginary = !imaginaryNorm ? nil :
              [CHParserOperatorNode combineDiv:@[imaginary, imaginaryNorm] operatorToken:token context:context];
            CHChalkValue* arccosArg = !partReal || !norm ? nil :
              [CHParserOperatorNode combineDiv:@[partReal,norm] operatorToken:token context:context];
            CHChalkValue* factor = !arccosArg ? nil :
              [self combineACos:@[arccosArg] token:token context:context];
            CHChalkValue* product = !unitaryImaginary || !factor ? nil :
              [CHParserOperatorNode combineMul:@[unitaryImaginary, factor] operatorToken:token context:context];
            CHChalkValue* sum = !log10Part || !product ? nil :
              [self combineLog10:@[log10Part, product] token:token context:context];
            if (!sum)
              [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                     replace:NO];
            result = [sum retain];
          }//end if (!imaginaryNorm.isZero)
        }//end if (!norm.isZero)
      }//end if (operandQuaternion)
      else if (operandGmp)
      {
        mpfr_clear_flags();
        mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
        const chalk_gmp_value_t* operand = operandGmp.valueConstReference;
        const BOOL isOperandNaN = chalkGmpValueIsNan(operand);
        const BOOL isOperandStrictlyNegative = !isOperandNaN && (chalkGmpValueSign(operand) < 0);
        if (isOperandNaN || isOperandStrictlyNegative)
        {
          if (!context.computationConfiguration.propagateNaN)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericInvalid range:token.range]
                                   replace:NO];
          CHChalkValueNumberGmp* nan = [CHChalkValueNumberGmp nanWithContext:context];
          if (!nan)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorAllocation range:token.range]
                                   replace:NO];
          result = [nan retain];
        }//end if (isOperandNaN || isOperandStrictlyNegative)
        else//if (!isOperandNaN && !isOperandStrictlyNegative)
        {
          chalk_gmp_value_t currentValue = {0};
          chalk_compute_flags_t computeFlags = 0;
          chalkGmpValueSet(&currentValue, operand, context.gmpPool);
          BOOL done = NO;
          if (chalkGmpValueIsOne(&currentValue, 0, operandGmp.evaluationComputeFlags))
          {
            chalkGmpValueSetZero(&currentValue, NO, context.gmpPool);
            done = YES;
          }
          else if ((currentValue.type == CHALK_VALUE_TYPE_INTEGER) && !mpz_cmp_ui(currentValue.integer, 10))
          {
            mpz_set_si(currentValue.integer, 1);
            done = YES;
          }
          else if ((currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT) && !mpfr_cmp_ui(currentValue.realExact, 10))
          {
            chalkGmpValueMakeInteger(&currentValue, context.gmpPool);
            mpz_set_si(currentValue.integer, 1);
            done = YES;
          }

          if (!done)
            chalkGmpValueMakeRealApprox(&currentValue, prec, context.gmpPool);
          if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX))
          {
            chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
            mpfir_log10(currentValue.realApprox, currentValue.realApprox);
            computeFlags |= chalkGmpFlagsMake();
            done = YES;
            chalkGmpFlagsRestore(oldFlags);
          }//end if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX))
          if (!done)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                   replace:NO];
          else//if (done)
          {
            chalkGmpValueSimplify(&currentValue, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
            CHChalkValueNumberGmp* value =
              [[[CHChalkValueNumberGmp alloc] initWithToken:token value:&currentValue naturalBase:operandGmp.naturalBase context:context] autorelease];
            if (!value)
              [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                     replace:NO];
            value.evaluationComputeFlags |= computeFlags | chalkGmpFlagsMake();
            result = [value retain];
          }//end if (done)
          chalkGmpValueClear(&currentValue, YES, context.gmpPool);
        }//end if (!isOperandNaN && !isOperandStrictlyNegative)
      }//if (operandGmp)
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
//end combineLog10:token:context:

+(CHChalkValue*) combineSin:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    @autoreleasepool {
      CHChalkValue* operandValue = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueList* operandList = [operandValue dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValueMatrix* operandMatrix = [operandValue dynamicCastToClass:[CHChalkValueMatrix class]];
      CHChalkValueQuaternion* operandQuaternion = [operandValue dynamicCastToClass:[CHChalkValueQuaternion class]];
      CHChalkValueNumberGmp* operandGmp = [operandValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueFormal* operandFormal = [operandValue dynamicCastToClass:[CHChalkValueFormal class]];
      operandGmp = !operandFormal ? operandGmp : operandFormal.value;
      if (operandList)
        result = [[self combineSEL:_cmd arguments:operands list:operandList index:0 token:token context:context] retain];
      else if (operandMatrix)
      {
        CHChalkValueMatrix* newMatrix = [[self combineMatrixSEL:_cmd operand:operandMatrix token:token context:context] retain];
        if (context.errorContext.hasError)
        {
          [newMatrix release];
          newMatrix = nil;
        }//end if (context.errorContext.hasError)
        result = newMatrix;
      }//end if (operandMatrix)
      else if (operandQuaternion)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericInvalid range:token.range]
                               replace:NO];
      else if (operandGmp)
      {
        mpfr_clear_flags();
        mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
        const chalk_gmp_value_t* operand = operandGmp.valueConstReference;
        chalk_compute_flags_t computeFlags = 0;
        chalk_gmp_value_t currentValue = {0};
        chalkGmpValueSet(&currentValue, operand, context.gmpPool);
        chalkGmpValueMakeReal(&currentValue, prec, context.gmpPool);
        BOOL done = NO;
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT))
        {
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
          mpfr_sin(currentValue.realExact, currentValue.realExact, MPFR_RNDN);
          done = !mpfr_inexflag_p();
          if (done)
            computeFlags |= chalkGmpFlagsMake();
          else//if (!done)
          {
            chalkGmpValueSet(&currentValue, operand, context.gmpPool);
            chalkGmpValueMakeRealApprox(&currentValue, prec, context.gmpPool);
          }//end if (!done)
          chalkGmpFlagsRestore(oldFlags);
        }//end (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT))
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX))
        {
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
          mpfir_sin(currentValue.realApprox, currentValue.realApprox);
          computeFlags |= chalkGmpFlagsMake();
          done = YES;
          chalkGmpFlagsRestore(oldFlags);
        }//end (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX))
        if (!done)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                 replace:NO];
        else//if (done)
        {
          chalkGmpValueSimplify(&currentValue, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
          CHChalkValueNumberGmp* value =
            [[[CHChalkValueNumberGmp alloc] initWithToken:token value:&currentValue naturalBase:operandGmp.naturalBase context:context] autorelease];
          if (!value)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                   replace:NO];
          value.evaluationComputeFlags |= computeFlags | chalkGmpFlagsMake();
          result = [value retain];
        }//end if (done)
        chalkGmpValueClear(&currentValue, YES, context.gmpPool);
      }//if (operandGmp)
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
//end combineSin:token:context:

+(CHChalkValue*) combineSinDeg:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    @autoreleasepool {
      CHChalkValue* operandValue = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueList* operandList = [operandValue dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValueMatrix* operandMatrix = [operandValue dynamicCastToClass:[CHChalkValueMatrix class]];
      CHChalkValueQuaternion* operandQuaternion = [operandValue dynamicCastToClass:[CHChalkValueQuaternion class]];
      CHChalkValueNumberGmp* operandGmp = [operandValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueFormal* operandFormal = [operandValue dynamicCastToClass:[CHChalkValueFormal class]];
      operandGmp = !operandFormal ? operandGmp : operandFormal.value;
      if (operandList)
        result = [[self combineSEL:_cmd arguments:operands list:operandList index:0 token:token context:context] retain];
      else if (operandMatrix)
      {
        CHChalkValueMatrix* newMatrix = [[self combineMatrixSEL:_cmd operand:operandMatrix token:token context:context] retain];
        if (context.errorContext.hasError)
        {
          [newMatrix release];
          newMatrix = nil;
        }//end if (context.errorContext.hasError)
        result = newMatrix;
      }//end if (operandMatrix)
      else if (operandQuaternion)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericInvalid range:token.range]
                               replace:NO];
      else if (operandGmp)
      {
        mpfr_clear_flags();
        chalk_compute_flags_t computeFlags = 0;
        chalk_gmp_value_t currentValue = {0};
        mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
        const chalk_gmp_value_t* operand = operandGmp.valueConstReference;
        BOOL done = NO;
        if (operand->type == CHALK_VALUE_TYPE_INTEGER)
        {
          mpz_t d;
          mpz_t q;
          mpz_t r;
          mpzDepool(d, context.gmpPool);
          mpzDepool(q, context.gmpPool);
          mpzDepool(r, context.gmpPool);
          mpz_set_si(d, 15);
          mpz_tdiv_qr(q, r, operand->integer, d);
          if (!mpz_sgn(r))//divisible
          {
            int factor1 = mpz_sgn(q);
            mpz_abs(q, q);
            unsigned long i = mpz_mod_ui(r, q, 24);
            int factor2 = (i > 12) ? -1 : 1;
            int factor = factor1*factor2;
            if ((i == 0) || (i == 12))
            {
              chalkGmpValueMakeInteger(&currentValue, context.gmpPool);
              mpz_set_si(currentValue.integer, 0);
            }//end if ((i == 0) || (i == 12))
            else if ((i == 1) || (i == 11) || (i == 13) || (i == 23))
            {
              mpfir_t tmp1;
              mpfir_t tmp2;
              mpfirDepool(tmp1, prec, context.gmpPool);
              mpfirDepool(tmp2, prec, context.gmpPool);
              mpfir_set_si(tmp1, 6);
              mpfir_set_si(tmp2, 2);
              mpfir_sqrt(tmp1, tmp1);
              mpfir_sqrt(tmp2, tmp2);
              chalkGmpValueMakeRealApprox(&currentValue, prec, context.gmpPool);
              mpfir_sub(currentValue.realApprox, tmp1, tmp2);
              mpfir_div_si(currentValue.realApprox, currentValue.realApprox, factor*4);
              mpfirRepool(tmp1, context.gmpPool);
              mpfirRepool(tmp2, context.gmpPool);
            }//end if ((i == 1) || (i == 11) || (i == 13) || (i == 14))
            else if ((i == 2) || (i == 10) || (i == 14) || (i == 22))
            {
              chalkGmpValueMakeFraction(&currentValue, context.gmpPool);
              mpq_set_si(currentValue.fraction, factor, 2);
            }//end if ((i == 2) || (i == 10) || (i == 14) || (i == 22))
            else if ((i == 3) || (i == 9) || (i == 15) || (i == 21))
            {
              chalkGmpValueMakeRealApprox(&currentValue, prec, context.gmpPool);
              mpfir_set_si(currentValue.realApprox, 2);
              mpfir_sqrt(currentValue.realApprox, currentValue.realApprox);
              mpfir_div_si(currentValue.realApprox, currentValue.realApprox, 2*factor);
            }//end if ((i == 3) || (i == 9) || (i == 15) || (i == 21))
            else if ((i == 4) || (i == 8) || (i == 16) || (i == 20))
            {
              chalkGmpValueMakeRealApprox(&currentValue, prec, context.gmpPool);
              mpfir_set_si(currentValue.realApprox, 3);
              mpfir_sqrt(currentValue.realApprox, currentValue.realApprox);
              mpfir_div_si(currentValue.realApprox, currentValue.realApprox, 2*factor);
            }//end if ((i == 4) || (i == 8) || (i == 16) || (i == 20))
            else if ((i == 5) || (i == 7) || (i == 17) || (i == 19))
            {
              mpfir_t tmp1;
              mpfir_t tmp2;
              mpfirDepool(tmp1, prec, context.gmpPool);
              mpfirDepool(tmp2, prec, context.gmpPool);
              mpfir_set_si(tmp1, 6);
              mpfir_set_si(tmp2, 2);
              mpfir_sqrt(tmp1, tmp1);
              mpfir_sqrt(tmp2, tmp2);
              chalkGmpValueMakeRealApprox(&currentValue, prec, context.gmpPool);
              mpfir_add(currentValue.realApprox, tmp1, tmp2);
              mpfir_div_si(currentValue.realApprox, currentValue.realApprox, factor*4);
              mpfirRepool(tmp1, context.gmpPool);
              mpfirRepool(tmp2, context.gmpPool);
            }//end if ((i == 5) || (i == 7) || (i == 17) || (i == 29))
            else if ((i == 6) || (i == 18))
            {
              chalkGmpValueMakeInteger(&currentValue, context.gmpPool);
              mpz_set_si(currentValue.integer, factor);
            }//end if ((i == 6) || (i == 18))
            done = YES;
          }//end if (!mpz_sgn(r))//divisible
          mpzRepool(r, context.gmpPool);
          mpzRepool(q, context.gmpPool);
          mpzRepool(d, context.gmpPool);
        }//end if (operand->type == CHALK_VALUE_TYPE_INTEGER)
        if (!done)
        {
          chalkGmpValueSet(&currentValue, operand, context.gmpPool);
          chalkGmpValueMakeRealApprox(&currentValue, prec, context.gmpPool);
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
          mpfr_t pi;
          mpfrDepool(pi, prec, context.gmpPool);
          mpfr_const_pi(pi, MPFR_RNDN);
          mpfir_div_si(currentValue.realApprox, currentValue.realApprox, 180);
          mpfir_mul_fr(currentValue.realApprox, currentValue.realApprox, pi);
          mpfir_sin(currentValue.realApprox, currentValue.realApprox);
          mpfrRepool(pi, context.gmpPool);
          computeFlags |= chalkGmpFlagsMake();
          chalkGmpFlagsRestore(oldFlags);
        }//end if (!done)
        chalkGmpValueSimplify(&currentValue, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
        CHChalkValueNumberGmp* value =
          [[[CHChalkValueNumberGmp alloc] initWithToken:token value:&currentValue naturalBase:operandGmp.naturalBase context:context] autorelease];
        if (!value)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                 replace:NO];
        value.evaluationComputeFlags |= computeFlags | chalkGmpFlagsMake();
        result = [value retain];
        chalkGmpValueClear(&currentValue, YES, context.gmpPool);
      }//if (operandGmp)
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
//end combineSinDeg:token:context:

+(CHChalkValue*) combineCos:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    @autoreleasepool {
      CHChalkValue* operandValue = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueList* operandList = [operandValue dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValueMatrix* operandMatrix = [operandValue dynamicCastToClass:[CHChalkValueMatrix class]];
      CHChalkValueQuaternion* operandQuaternion = [operandValue dynamicCastToClass:[CHChalkValueQuaternion class]];
      CHChalkValueNumberGmp* operandGmp = [operandValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueFormal* operandFormal = [operandValue dynamicCastToClass:[CHChalkValueFormal class]];
      operandGmp = !operandFormal ? operandGmp : operandFormal.value;
      if (operandList)
        result = [[self combineSEL:_cmd arguments:operands list:operandList index:0 token:token context:context] retain];
      else if (operandMatrix)
      {
        CHChalkValueMatrix* newMatrix = [[self combineMatrixSEL:_cmd operand:operandMatrix token:token context:context] retain];
        if (context.errorContext.hasError)
        {
          [newMatrix release];
          newMatrix = nil;
        }//end if (context.errorContext.hasError)
        result = newMatrix;
      }//end if (operandMatrix)
      else if (operandQuaternion)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericInvalid range:token.range]
                               replace:NO];
      else if (operandGmp)
      {
        mpfr_clear_flags();
        mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
        const chalk_gmp_value_t* operand = operandGmp.valueConstReference;
        chalk_compute_flags_t computeFlags = 0;
        chalk_gmp_value_t currentValue = {0};
        chalkGmpValueSet(&currentValue, operand, context.gmpPool);
        chalkGmpValueMakeReal(&currentValue, prec, context.gmpPool);
        BOOL done = NO;
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT))
        {
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
          mpfr_cos(currentValue.realExact, currentValue.realExact, MPFR_RNDN);
          done = !mpfr_inexflag_p();
          if (done)
            computeFlags |= chalkGmpFlagsMake();
          else//if (!done)
          {
            chalkGmpValueSet(&currentValue, operand, context.gmpPool);
            chalkGmpValueMakeRealApprox(&currentValue, prec, context.gmpPool);
          }//end if (!done)
          chalkGmpFlagsRestore(oldFlags);
        }//end (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT))
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX))
        {
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
          mpfir_cos(currentValue.realApprox, currentValue.realApprox);
          computeFlags |= chalkGmpFlagsMake();
          done = YES;
          chalkGmpFlagsRestore(oldFlags);
        }//end (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX))
        if (!done)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                 replace:NO];
        else//if (done)
        {
          chalkGmpValueSimplify(&currentValue, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
          CHChalkValueNumberGmp* value =
            [[[CHChalkValueNumberGmp alloc] initWithToken:token value:&currentValue naturalBase:operandGmp.naturalBase context:context] autorelease];
          if (!value)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                   replace:NO];
          value.evaluationComputeFlags |= computeFlags | chalkGmpFlagsMake();
          result = [value retain];
        }//end if (done)
        chalkGmpValueClear(&currentValue, YES, context.gmpPool);
      }//if (operandGmp)
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
//end combineCos:token:context:

+(CHChalkValue*) combineCosDeg:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    @autoreleasepool {
      CHChalkValue* operandValue = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueList* operandList = [operandValue dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValueMatrix* operandMatrix = [operandValue dynamicCastToClass:[CHChalkValueMatrix class]];
      CHChalkValueQuaternion* operandQuaternion = [operandValue dynamicCastToClass:[CHChalkValueQuaternion class]];
      CHChalkValueNumberGmp* operandGmp = [operandValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueFormal* operandFormal = [operandValue dynamicCastToClass:[CHChalkValueFormal class]];
      operandGmp = !operandFormal ? operandGmp : operandFormal.value;
      if (operandList)
        result = [[self combineSEL:_cmd arguments:operands list:operandList index:0 token:token context:context] retain];
      else if (operandMatrix)
      {
        CHChalkValueMatrix* newMatrix = [[self combineMatrixSEL:_cmd operand:operandMatrix token:token context:context] retain];
        if (context.errorContext.hasError)
        {
          [newMatrix release];
          newMatrix = nil;
        }//end if (context.errorContext.hasError)
        result = newMatrix;
      }//end if (operandMatrix)
      else if (operandQuaternion)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericInvalid range:token.range]
                               replace:NO];
      else if (operandGmp)
      {
        mpfr_clear_flags();
        chalk_compute_flags_t computeFlags = 0;
        chalk_gmp_value_t currentValue = {0};
        mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
        const chalk_gmp_value_t* operand = operandGmp.valueConstReference;
        BOOL done = NO;
        if (operand->type == CHALK_VALUE_TYPE_INTEGER)
        {
          mpz_t d;
          mpz_t q;
          mpz_t r;
          mpzDepool(d, context.gmpPool);
          mpzDepool(q, context.gmpPool);
          mpzDepool(r, context.gmpPool);
          mpz_set_si(d, 15);
          mpz_tdiv_qr(q, r, operand->integer, d);
          mpz_abs(q, q);
          if (!mpz_sgn(r))//divisible
          {
            unsigned long i = mpz_mod_ui(r, q, 24);
            int factor = (i >= 7) && (i<= 17) ? -1 : 1;
            if ((i == 0) || (i == 12))
            {
              chalkGmpValueMakeInteger(&currentValue, context.gmpPool);
              mpz_set_si(currentValue.integer, factor);
            }//end if ((i == 0) || (i == 12))
            else if ((i == 1) || (i == 11) || (i == 13) || (i == 23))
            {
              mpfir_t tmp1;
              mpfir_t tmp2;
              mpfirDepool(tmp1, prec, context.gmpPool);
              mpfirDepool(tmp2, prec, context.gmpPool);
              mpfir_set_si(tmp1, 6);
              mpfir_set_si(tmp2, 2);
              mpfir_sqrt(tmp1, tmp1);
              mpfir_sqrt(tmp2, tmp2);
              chalkGmpValueMakeRealApprox(&currentValue, prec, context.gmpPool);
              mpfir_add(currentValue.realApprox, tmp1, tmp2);
              mpfir_div_si(currentValue.realApprox, currentValue.realApprox, factor*4);
              mpfirRepool(tmp1, context.gmpPool);
              mpfirRepool(tmp2, context.gmpPool);
            }//end if ((i == 1) || (i == 11) || (i == 13) || (i == 14))
            else if ((i == 2) || (i == 10) || (i == 14) || (i == 22))
            {
              chalkGmpValueMakeRealApprox(&currentValue, prec, context.gmpPool);
              mpfir_set_si(currentValue.realApprox, 3);
              mpfir_sqrt(currentValue.realApprox, currentValue.realApprox);
              mpfir_div_si(currentValue.realApprox, currentValue.realApprox, 2*factor);
            }//end if ((i == 2) || (i == 10) || (i == 14) || (i == 22))
            else if ((i == 3) || (i == 9) || (i == 15) || (i == 21))
            {
              chalkGmpValueMakeRealApprox(&currentValue, prec, context.gmpPool);
              mpfir_set_si(currentValue.realApprox, 2);
              mpfir_sqrt(currentValue.realApprox, currentValue.realApprox);
              mpfir_div_si(currentValue.realApprox, currentValue.realApprox, 2*factor);
            }//end if ((i == 3) || (i == 9) || (i == 15) || (i == 21))
            else if ((i == 4) || (i == 8) || (i == 16) || (i == 20))
            {
              chalkGmpValueMakeFraction(&currentValue, context.gmpPool);
              mpq_set_si(currentValue.fraction, factor, 2);
            }//end if ((i == 4) || (i == 8) || (i == 16) || (i == 20))
            else if ((i == 5) || (i == 7) || (i == 17) || (i == 19))
            {
              mpfir_t tmp1;
              mpfir_t tmp2;
              mpfirDepool(tmp1, prec, context.gmpPool);
              mpfirDepool(tmp2, prec, context.gmpPool);
              mpfir_set_si(tmp1, 6);
              mpfir_set_si(tmp2, 2);
              mpfir_sqrt(tmp1, tmp1);
              mpfir_sqrt(tmp2, tmp2);
              chalkGmpValueMakeRealApprox(&currentValue, prec, context.gmpPool);
              mpfir_sub(currentValue.realApprox, tmp1, tmp2);
              mpfir_div_si(currentValue.realApprox, currentValue.realApprox, factor*4);
              mpfirRepool(tmp1, context.gmpPool);
              mpfirRepool(tmp2, context.gmpPool);
            }//end if ((i == 5) || (i == 7) || (i == 17) || (i == 29))
            else if ((i == 6) || (i == 18))
            {
              chalkGmpValueMakeInteger(&currentValue, context.gmpPool);
              mpz_set_si(currentValue.integer, 0);
            }//end if ((i == 6) || (i == 18))
            done = YES;
          }//end if (!mpz_sgn(r))//divisible
          mpzRepool(r, context.gmpPool);
          mpzRepool(q, context.gmpPool);
          mpzRepool(d, context.gmpPool);
        }//end if (operand->type == CHALK_VALUE_TYPE_INTEGER)
        if (!done)
        {
          chalkGmpValueSet(&currentValue, operand, context.gmpPool);
          chalkGmpValueMakeRealApprox(&currentValue, prec, context.gmpPool);
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
          mpfr_t pi;
          mpfrDepool(pi, prec, context.gmpPool);
          mpfr_const_pi(pi, MPFR_RNDN);
          mpfir_div_si(currentValue.realApprox, currentValue.realApprox, 180);
          mpfir_mul_fr(currentValue.realApprox, currentValue.realApprox, pi);
          mpfir_cos(currentValue.realApprox, currentValue.realApprox);
          mpfrRepool(pi, context.gmpPool);
          computeFlags |= chalkGmpFlagsMake();
          chalkGmpFlagsRestore(oldFlags);
        }//end if (!done)
        chalkGmpValueSimplify(&currentValue, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
        CHChalkValueNumberGmp* value =
          [[[CHChalkValueNumberGmp alloc] initWithToken:token value:&currentValue naturalBase:operandGmp.naturalBase context:context] autorelease];
        if (!value)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                 replace:NO];
        value.evaluationComputeFlags |= computeFlags | chalkGmpFlagsMake();
        result = [value retain];
        chalkGmpValueClear(&currentValue, YES, context.gmpPool);
      }//if (operandGmp)
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
//end combineCosDeg:token:context:

+(CHChalkValue*) combineTan:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    @autoreleasepool {
      CHChalkValue* operandValue = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueList* operandList = [operandValue dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValueMatrix* operandMatrix = [operandValue dynamicCastToClass:[CHChalkValueMatrix class]];
      CHChalkValueQuaternion* operandQuaternion = [operandValue dynamicCastToClass:[CHChalkValueQuaternion class]];
      CHChalkValueNumberGmp* operandGmp = [operandValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueFormal* operandFormal = [operandValue dynamicCastToClass:[CHChalkValueFormal class]];
      operandGmp = !operandFormal ? operandGmp : operandFormal.value;
      if (operandList)
        result = [[self combineSEL:_cmd arguments:operands list:operandList index:0 token:token context:context] retain];
      else if (operandMatrix)
      {
        CHChalkValueMatrix* newMatrix = [[self combineMatrixSEL:_cmd operand:operandMatrix token:token context:context] retain];
        if (context.errorContext.hasError)
        {
          [newMatrix release];
          newMatrix = nil;
        }//end if (context.errorContext.hasError)
        result = newMatrix;
      }//end if (operandMatrix)
      else if (operandQuaternion)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericInvalid range:token.range]
                               replace:NO];
      else if (operandGmp)
      {
        mpfr_clear_flags();
        mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
        const chalk_gmp_value_t* operand = operandGmp.valueConstReference;
        chalk_compute_flags_t computeFlags = 0;
        chalk_gmp_value_t currentValue = {0};
        chalkGmpValueSet(&currentValue, operand, context.gmpPool);
        chalkGmpValueMakeReal(&currentValue, prec, context.gmpPool);
        BOOL done = NO;
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT))
        {
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
          mpfr_tan(currentValue.realExact, currentValue.realExact, MPFR_RNDN);
          done = !mpfr_inexflag_p();
          if (done)
            computeFlags |= chalkGmpFlagsMake();
          else//if (!done)
          {
            chalkGmpValueSet(&currentValue, operand, context.gmpPool);
            chalkGmpValueMakeRealApprox(&currentValue, prec, context.gmpPool);
          }//end if (!done)
          chalkGmpFlagsRestore(oldFlags);
        }//end (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT))
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX))
        {
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
          mpfir_tan(currentValue.realApprox, currentValue.realApprox);
          computeFlags |= chalkGmpFlagsMake();
          done = YES;
          chalkGmpFlagsRestore(oldFlags);
        }//end (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX))
        if (!done)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                 replace:NO];
        else//if (done)
        {
          chalkGmpValueSimplify(&currentValue, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
          CHChalkValueNumberGmp* value =
            [[[CHChalkValueNumberGmp alloc] initWithToken:token value:&currentValue naturalBase:operandGmp.naturalBase context:context] autorelease];
          if (!value)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                   replace:NO];
          value.evaluationComputeFlags |= computeFlags | chalkGmpFlagsMake();
          result = [value retain];
        }//end if (done)
        chalkGmpValueClear(&currentValue, YES, context.gmpPool);
      }//if (operandGmp)
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
//end combineTan:token:context:

+(CHChalkValue*) combineTanDeg:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    @autoreleasepool {
      CHChalkValue* operandValue = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueList* operandList = [operandValue dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValueMatrix* operandMatrix = [operandValue dynamicCastToClass:[CHChalkValueMatrix class]];
      CHChalkValueQuaternion* operandQuaternion = [operandValue dynamicCastToClass:[CHChalkValueQuaternion class]];
      CHChalkValueNumberGmp* operandGmp = [operandValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueFormal* operandFormal = [operandValue dynamicCastToClass:[CHChalkValueFormal class]];
      operandGmp = !operandFormal ? operandGmp : operandFormal.value;
      if (operandList)
        result = [[self combineSEL:_cmd arguments:operands list:operandList index:0 token:token context:context] retain];
      else if (operandMatrix)
      {
        CHChalkValueMatrix* newMatrix = [[self combineMatrixSEL:_cmd operand:operandMatrix token:token context:context] retain];
        if (context.errorContext.hasError)
        {
          [newMatrix release];
          newMatrix = nil;
        }//end if (context.errorContext.hasError)
        result = newMatrix;
      }//end if (operandMatrix)
      else if (operandQuaternion)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericInvalid range:token.range]
                               replace:NO];
      else if (operandGmp)
      {
        mpfr_clear_flags();
        mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
        chalk_compute_flags_t computeFlags = 0;
        chalk_gmp_value_t currentValue = {0};
        const chalk_gmp_value_t* operand = operandGmp.valueConstReference;
        BOOL done = NO;
        if (operand->type == CHALK_VALUE_TYPE_INTEGER)
        {
          mpz_t d;
          mpz_t q;
          mpz_t r;
          mpzDepool(d, context.gmpPool);
          mpzDepool(q, context.gmpPool);
          mpzDepool(r, context.gmpPool);
          mpz_set_si(d, 45);
          mpz_tdiv_qr(q, r, operand->integer, d);
          if (!mpz_sgn(r))//divisible
          {
            chalkGmpValueMakeInteger(&currentValue, context.gmpPool);
            int factor1 = mpz_sgn(q);
            mpz_abs(q, q);
            unsigned long i = mpz_mod_ui(r, q, 8);
            int factor2 = (i <= 4) ? 1 : -1;
            int factor3 = (i >= 3) && (i <= 5) ? -1 : 1;
            int factor = factor1*factor2*factor3;
            if ((i == 0) || (i == 4))
              mpz_set_si(currentValue.integer, 0);
            else if ((i == 1) || (i == 3) || (i == 5) || (i == 7))
              mpz_set_si(currentValue.integer, factor);
            else if ((i == 2) || (i == 6))
              chalkGmpValueSetInfinity(&currentValue, factor, YES, context.gmpPool);
            done = YES;
          }//end if (!mpz_sgn(r))//divisible
          mpzRepool(r, context.gmpPool);
          mpzRepool(q, context.gmpPool);
          mpzRepool(d, context.gmpPool);
        }//end if (operand->type == CHALK_VALUE_TYPE_INTEGER)
        if (!done)
        {
          chalkGmpValueSet(&currentValue, operand, context.gmpPool);
          chalkGmpValueMakeRealApprox(&currentValue, prec, context.gmpPool);
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
          mpfr_t pi;
          mpfrDepool(pi, prec, context.gmpPool);
          mpfr_const_pi(pi, MPFR_RNDN);
          mpfir_div_si(currentValue.realApprox, currentValue.realApprox, 180);
          mpfir_mul_fr(currentValue.realApprox, currentValue.realApprox, pi);
          mpfir_tan(currentValue.realApprox, currentValue.realApprox);
          mpfrRepool(pi, context.gmpPool);
          computeFlags |= chalkGmpFlagsMake();
          chalkGmpFlagsRestore(oldFlags);
        }//end if (!done)
        chalkGmpValueSimplify(&currentValue, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
        CHChalkValueNumberGmp* value =
          [[[CHChalkValueNumberGmp alloc] initWithToken:token value:&currentValue naturalBase:operandGmp.naturalBase context:context] autorelease];
        if (!value)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                 replace:NO];
        value.evaluationComputeFlags |= computeFlags | chalkGmpFlagsMake();
        result = [value retain];
        chalkGmpValueClear(&currentValue, YES, context.gmpPool);
      }//if (operandGmp)
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
//end combineTanDeg:token:context:

+(CHChalkValue*) combineASin:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    @autoreleasepool {
      CHChalkValue* operandValue = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueList* operandList = [operandValue dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValueMatrix* operandMatrix = [operandValue dynamicCastToClass:[CHChalkValueMatrix class]];
      CHChalkValueQuaternion* operandQuaternion = [operandValue dynamicCastToClass:[CHChalkValueQuaternion class]];
      CHChalkValueNumberGmp* operandGmp = [operandValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueFormal* operandFormal = [operandValue dynamicCastToClass:[CHChalkValueFormal class]];
      operandGmp = !operandFormal ? operandGmp : operandFormal.value;
      if (operandList)
        result = [[self combineSEL:_cmd arguments:operands list:operandList index:0 token:token context:context] retain];
      else if (operandMatrix)
      {
        CHChalkValueMatrix* newMatrix = [[self combineMatrixSEL:_cmd operand:operandMatrix token:token context:context] retain];
        if (context.errorContext.hasError)
        {
          [newMatrix release];
          newMatrix = nil;
        }//end if (context.errorContext.hasError)
        result = newMatrix;
      }//end if (operandMatrix)
      else if (operandQuaternion)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericInvalid range:token.range]
                               replace:NO];
      else if (operandGmp)
      {
        mpfr_clear_flags();
        mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
        const chalk_gmp_value_t* operand = operandGmp.valueConstReference;
        chalk_compute_flags_t computeFlags = 0;
        chalk_gmp_value_t currentValue = {0};
        chalkGmpValueSet(&currentValue, operand, context.gmpPool);
        chalkGmpValueMakeReal(&currentValue, prec, context.gmpPool);
        BOOL done = NO;
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT))
        {
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
          mpfr_asin(currentValue.realExact, currentValue.realExact, MPFR_RNDN);
          done = !mpfr_inexflag_p();
          if (done)
            computeFlags |= chalkGmpFlagsMake();
          else//if (!done)
          {
            chalkGmpValueSet(&currentValue, operand, context.gmpPool);
            chalkGmpValueMakeRealApprox(&currentValue, prec, context.gmpPool);
          }//end if (!done)
          chalkGmpFlagsRestore(oldFlags);
        }//end (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT))
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX))
        {
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
          mpfir_asin(currentValue.realApprox, currentValue.realApprox);
          computeFlags |= chalkGmpFlagsMake();
          done = YES;
          chalkGmpFlagsRestore(oldFlags);
        }//end (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX))
        if (!done)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                 replace:NO];
        else//if (done)
        {
          chalkGmpValueSimplify(&currentValue, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
          CHChalkValueNumberGmp* value =
            [[[CHChalkValueNumberGmp alloc] initWithToken:token value:&currentValue naturalBase:operandGmp.naturalBase context:context] autorelease];
          if (!value)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                   replace:NO];
          value.evaluationComputeFlags |= computeFlags | chalkGmpFlagsMake();
          result = [value retain];
        }//end if (done)
        chalkGmpValueClear(&currentValue, YES, context.gmpPool);
      }//if (operandGmp)
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
//end combineASin:token:context:

+(CHChalkValue*) combineACos:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    @autoreleasepool {
      CHChalkValue* operandValue = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueList* operandList = [operandValue dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValueMatrix* operandMatrix = [operandValue dynamicCastToClass:[CHChalkValueMatrix class]];
      CHChalkValueQuaternion* operandQuaternion = [operandValue dynamicCastToClass:[CHChalkValueQuaternion class]];
      CHChalkValueNumberGmp* operandGmp = [operandValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueFormal* operandFormal = [operandValue dynamicCastToClass:[CHChalkValueFormal class]];
      operandGmp = !operandFormal ? operandGmp : operandFormal.value;
      if (operandList)
        result = [[self combineSEL:_cmd arguments:operands list:operandList index:0 token:token context:context] retain];
      else if (operandMatrix)
      {
        CHChalkValueMatrix* newMatrix = [[self combineMatrixSEL:_cmd operand:operandMatrix token:token context:context] retain];
        if (context.errorContext.hasError)
        {
          [newMatrix release];
          newMatrix = nil;
        }//end if (context.errorContext.hasError)
        result = newMatrix;
      }//end if (operandMatrix)
      else if (operandQuaternion)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericInvalid range:token.range]
                               replace:NO];
      else if (operandGmp)
      {
        mpfr_clear_flags();
        mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
        const chalk_gmp_value_t* operand = operandGmp.valueConstReference;
        chalk_compute_flags_t computeFlags = 0;
        chalk_gmp_value_t currentValue = {0};
        chalkGmpValueSet(&currentValue, operand, context.gmpPool);
        chalkGmpValueMakeReal(&currentValue, prec, context.gmpPool);
        BOOL done = NO;
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT))
        {
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
          mpfr_acos(currentValue.realExact, currentValue.realExact, MPFR_RNDN);
          done = !mpfr_inexflag_p();
          if (done)
            computeFlags |= chalkGmpFlagsMake();
          else//if (!done)
          {
            chalkGmpValueSet(&currentValue, operand, context.gmpPool);
            chalkGmpValueMakeRealApprox(&currentValue, prec, context.gmpPool);
          }//end if (!done)
          chalkGmpFlagsRestore(oldFlags);
        }//end (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT))
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX))
        {
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
          mpfir_acos(currentValue.realApprox, currentValue.realApprox);
          computeFlags |= chalkGmpFlagsMake();
          done = YES;
          chalkGmpFlagsRestore(oldFlags);
        }//end (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX))
        if (!done)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                 replace:NO];
        else//if (done)
        {
          chalkGmpValueSimplify(&currentValue, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
          CHChalkValueNumberGmp* value =
            [[[CHChalkValueNumberGmp alloc] initWithToken:token value:&currentValue naturalBase:operandGmp.naturalBase context:context] autorelease];
          if (!value)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                   replace:NO];
          value.evaluationComputeFlags |= computeFlags | chalkGmpFlagsMake();
          result = [value retain];
        }//end if (done)
        chalkGmpValueClear(&currentValue, YES, context.gmpPool);
      }//if (operandGmp)
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
//end combineACos:token:context:

+(CHChalkValue*) combineATan:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    @autoreleasepool {
      CHChalkValue* operandValue = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueList* operandList = [operandValue dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValueMatrix* operandMatrix = [operandValue dynamicCastToClass:[CHChalkValueMatrix class]];
      CHChalkValueQuaternion* operandQuaternion = [operandValue dynamicCastToClass:[CHChalkValueQuaternion class]];
      CHChalkValueNumberGmp* operandGmp = [operandValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueFormal* operandFormal = [operandValue dynamicCastToClass:[CHChalkValueFormal class]];
      operandGmp = !operandFormal ? operandGmp : operandFormal.value;
      if (operandList)
        result = [[self combineSEL:_cmd arguments:operands list:operandList index:0 token:token context:context] retain];
      else if (operandMatrix)
      {
        CHChalkValueMatrix* newMatrix = [[self combineMatrixSEL:_cmd operand:operandMatrix token:token context:context] retain];
        if (context.errorContext.hasError)
        {
          [newMatrix release];
          newMatrix = nil;
        }//end if (context.errorContext.hasError)
        result = newMatrix;
      }//end if (operandMatrix)
      else if (operandQuaternion)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericInvalid range:token.range]
                               replace:NO];
      else if (operandGmp)
      {
        mpfr_clear_flags();
        mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
        const chalk_gmp_value_t* operand = operandGmp.valueConstReference;
        chalk_compute_flags_t computeFlags = 0;
        chalk_gmp_value_t currentValue = {0};
        chalkGmpValueSet(&currentValue, operand, context.gmpPool);
        chalkGmpValueMakeReal(&currentValue, prec, context.gmpPool);
        BOOL done = NO;
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT))
        {
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
          mpfr_atan(currentValue.realExact, currentValue.realExact, MPFR_RNDN);
          done = !mpfr_inexflag_p();
          if (done)
            computeFlags |= chalkGmpFlagsMake();
          else//if (!done)
          {
            chalkGmpValueSet(&currentValue, operand, context.gmpPool);
            chalkGmpValueMakeRealApprox(&currentValue, prec, context.gmpPool);
          }//end if (!done)
          chalkGmpFlagsRestore(oldFlags);
        }//end (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT))
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX))
        {
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
          mpfir_atan(currentValue.realApprox, currentValue.realApprox);
          computeFlags |= chalkGmpFlagsMake();
          done = YES;
          chalkGmpFlagsRestore(oldFlags);
        }//end (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX))
        if (!done)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                 replace:NO];
        else//if (done)
        {
          chalkGmpValueSimplify(&currentValue, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
          CHChalkValueNumberGmp* value =
            [[[CHChalkValueNumberGmp alloc] initWithToken:token value:&currentValue naturalBase:operandGmp.naturalBase context:context] autorelease];
          if (!value)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                   replace:NO];
          value.evaluationComputeFlags |= computeFlags | chalkGmpFlagsMake();
          result = [value retain];
        }//end if (done)
        chalkGmpValueClear(&currentValue, YES, context.gmpPool);
      }//if (operandGmp)
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
//end combineATan:token:context:

+(CHChalkValue*) combineATan2:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 2)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 2)
  {
    @autoreleasepool {
      CHChalkValue* operand1Value = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueQuaternion* operand1Quaternion = [operand1Value dynamicCastToClass:[CHChalkValueQuaternion class]];
      CHChalkValueNumberGmp* operand1Gmp = [operand1Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueList* operand1List = [operand1Value dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValue* operand2Value = [[operands objectAtIndex:1] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueQuaternion* operand2Quaternion = [operand2Value dynamicCastToClass:[CHChalkValueQuaternion class]];
      CHChalkValueNumberGmp* operand2Gmp = [operand2Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueList* operand2List = [operand2Value dynamicCastToClass:[CHChalkValueList class]];
      if (!operand1Value || !operand2Value)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                               replace:NO];
      else if (operand2List)
        result = [[self combineSEL:_cmd arguments:operands list:operand2List index:1 token:token context:context] retain];
      else if (operand1List)
        result = [[self combineSEL:_cmd arguments:operands list:operand1List index:0 token:token context:context] retain];
      else if (operand1Quaternion)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericInvalid range:operand1Quaternion.token.range]
                               replace:NO];
      else if (operand2Quaternion)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericInvalid range:operand2Quaternion.token.range]
                               replace:NO];
      else if (operand1Gmp && operand2Gmp)
      {
        mpfr_clear_flags();
        mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
        chalk_compute_flags_t computeFlags = 0;
        chalk_gmp_value_t currentValue = {0};
        chalk_gmp_value_t operand1 = {0};
        chalk_gmp_value_t operand2 = {0};
        chalkGmpValueSet(&operand1, operand1Gmp.valueConstReference, context.gmpPool);
        chalkGmpValueSet(&operand2, operand2Gmp.valueConstReference, context.gmpPool);
        chalkGmpValueSetZero(&currentValue, NO, context.gmpPool);
        chalkGmpValueMakeReal(&operand1, prec, context.gmpPool);
        chalkGmpValueMakeReal(&operand2, prec, context.gmpPool);
        BOOL done = NO;
        if (!done && (operand1.type == CHALK_VALUE_TYPE_REAL_EXACT) && (operand2.type == CHALK_VALUE_TYPE_REAL_EXACT))
        {
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
          chalkGmpValueMakeRealExact(&currentValue, prec, context.gmpPool);
          mpfr_atan2(currentValue.realExact, operand1.realExact, operand2.realExact, MPFR_RNDN);
          done = !mpfr_inexflag_p();
          if (done)
            computeFlags |= chalkGmpFlagsMake();
          else//if (!done)
          {
            chalkGmpValueSetZero(&currentValue, NO, context.gmpPool);
            chalkGmpValueMakeRealApprox(&operand1, prec, context.gmpPool);
            chalkGmpValueMakeRealApprox(&operand2, prec, context.gmpPool);
          }//end if (!done)
          chalkGmpFlagsRestore(oldFlags);
        }//end (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT))
        if (!done)
        {
          chalkGmpValueMakeRealApprox(&operand1, prec, context.gmpPool);
          chalkGmpValueMakeRealApprox(&operand2, prec, context.gmpPool);
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
          chalkGmpValueMakeRealApprox(&currentValue, prec, context.gmpPool);
          mpfir_atan2(currentValue.realApprox, operand1.realApprox, operand2.realApprox);
          computeFlags |= chalkGmpFlagsMake();
          done = YES;
          chalkGmpFlagsRestore(oldFlags);
        }//end (!done)
        if (!done)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                 replace:NO];
        else//if (done)
        {
          chalkGmpValueSimplify(&currentValue, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
          CHChalkValueNumberGmp* value =
            [[[CHChalkValueNumberGmp alloc] initWithToken:token value:&currentValue naturalBase:operand1Gmp.naturalBase context:context] autorelease];
          if (!value)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                   replace:NO];
          value.evaluationComputeFlags |= computeFlags | chalkGmpFlagsMake();
          result = [value retain];
        }//end if (done)
        chalkGmpValueClear(&currentValue, YES, context.gmpPool);
      }//if (operandGmp)
      else
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                               replace:NO];
      result.evaluationComputeFlags |=
        operand1Value.evaluationComputeFlags |
        operand2Value.evaluationComputeFlags |
        chalkGmpFlagsMake();
    }//end if (operands.count == 2)
  }//end if (operands.count == 2)
  return [result autorelease];
}
//end combineATan2:token:context:

+(CHChalkValue*) combineSinh:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    @autoreleasepool {
      CHChalkValue* operandValue = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueList* operandList = [operandValue dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValueMatrix* operandMatrix = [operandValue dynamicCastToClass:[CHChalkValueMatrix class]];
      CHChalkValueQuaternion* operandQuaternion = [operandValue dynamicCastToClass:[CHChalkValueQuaternion class]];
      CHChalkValueNumberGmp* operandGmp = [operandValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueFormal* operandFormal = [operandValue dynamicCastToClass:[CHChalkValueFormal class]];
      operandGmp = !operandFormal ? operandGmp : operandFormal.value;
      if (operandList)
        result = [[self combineSEL:_cmd arguments:operands list:operandList index:0 token:token context:context] retain];
      else if (operandMatrix)
      {
        CHChalkValueMatrix* newMatrix = [[self combineMatrixSEL:_cmd operand:operandMatrix token:token context:context] retain];
        if (context.errorContext.hasError)
        {
          [newMatrix release];
          newMatrix = nil;
        }//end if (context.errorContext.hasError)
        result = newMatrix;
      }//end if (operandMatrix)
      else if (operandQuaternion)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericInvalid range:token.range]
                               replace:NO];
      else if (operandGmp)
      {
        mpfr_clear_flags();
        mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
        const chalk_gmp_value_t* operand = operandGmp.valueConstReference;
        chalk_compute_flags_t computeFlags = 0;
        chalk_gmp_value_t currentValue = {0};
        chalkGmpValueSet(&currentValue, operand, context.gmpPool);
        chalkGmpValueMakeReal(&currentValue, prec, context.gmpPool);
        BOOL done = NO;
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT))
        {
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
          mpfr_sinh(currentValue.realExact, currentValue.realExact, MPFR_RNDN);
          done = !mpfr_inexflag_p();
          if (done)
            computeFlags |= chalkGmpFlagsMake();
          else//if (!done)
          {
            chalkGmpValueSet(&currentValue, operand, context.gmpPool);
            chalkGmpValueMakeRealApprox(&currentValue, prec, context.gmpPool);
          }//end if (!done)
          chalkGmpFlagsRestore(oldFlags);
        }//end (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT))
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX))
        {
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
          mpfir_sinh(currentValue.realApprox, currentValue.realApprox);
          computeFlags |= chalkGmpFlagsMake();
          done = YES;
          chalkGmpFlagsRestore(oldFlags);
        }//end (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX))
        if (!done)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                 replace:NO];
        else//if (done)
        {
          chalkGmpValueSimplify(&currentValue, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
          CHChalkValueNumberGmp* value =
            [[[CHChalkValueNumberGmp alloc] initWithToken:token value:&currentValue naturalBase:operandGmp.naturalBase context:context] autorelease];
          if (!value)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                   replace:NO];
          value.evaluationComputeFlags |= computeFlags | chalkGmpFlagsMake();
          result = [value retain];
        }//end if (done)
        chalkGmpValueClear(&currentValue, YES, context.gmpPool);
      }//if (operandGmp)
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
//end combineSinh:token:context:

+(CHChalkValue*) combineCosh:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    @autoreleasepool {
      CHChalkValue* operandValue = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueList* operandList = [operandValue dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValueMatrix* operandMatrix = [operandValue dynamicCastToClass:[CHChalkValueMatrix class]];
      CHChalkValueQuaternion* operandQuaternion = [operandValue dynamicCastToClass:[CHChalkValueQuaternion class]];
      CHChalkValueNumberGmp* operandGmp = [operandValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueFormal* operandFormal = [operandValue dynamicCastToClass:[CHChalkValueFormal class]];
      operandGmp = !operandFormal ? operandGmp : operandFormal.value;
      if (operandList)
        result = [[self combineSEL:_cmd arguments:operands list:operandList index:0 token:token context:context] retain];
      else if (operandMatrix)
      {
        CHChalkValueMatrix* newMatrix = [[self combineMatrixSEL:_cmd operand:operandMatrix token:token context:context] retain];
        if (context.errorContext.hasError)
        {
          [newMatrix release];
          newMatrix = nil;
        }//end if (context.errorContext.hasError)
        result = newMatrix;
      }//end if (operandMatrix)
      else if (operandQuaternion)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericInvalid range:token.range]
                               replace:NO];
      else if (operandGmp)
      {
        mpfr_clear_flags();
        mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
        const chalk_gmp_value_t* operand = operandGmp.valueConstReference;
        chalk_compute_flags_t computeFlags = 0;
        chalk_gmp_value_t currentValue = {0};
        chalkGmpValueSet(&currentValue, operand, context.gmpPool);
        chalkGmpValueMakeReal(&currentValue, prec, context.gmpPool);
        BOOL done = NO;
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT))
        {
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
          mpfr_cosh(currentValue.realExact, currentValue.realExact, MPFR_RNDN);
          done = !mpfr_inexflag_p();
          if (done)
            computeFlags |= chalkGmpFlagsMake();
          else//if (!done)
          {
            chalkGmpValueSet(&currentValue, operand, context.gmpPool);
            chalkGmpValueMakeRealApprox(&currentValue, prec, context.gmpPool);
          }//end if (!done)
          chalkGmpFlagsRestore(oldFlags);
        }//end (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT))
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX))
        {
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
          mpfir_cosh(currentValue.realApprox, currentValue.realApprox);
          computeFlags |= chalkGmpFlagsMake();
          done = YES;
          chalkGmpFlagsRestore(oldFlags);
        }//end (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX))
        if (!done)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                 replace:NO];
        else//if (done)
        {
          chalkGmpValueSimplify(&currentValue, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
          CHChalkValueNumberGmp* value =
            [[[CHChalkValueNumberGmp alloc] initWithToken:token value:&currentValue naturalBase:operandGmp.naturalBase context:context] autorelease];
          if (!value)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                   replace:NO];
          value.evaluationComputeFlags |= computeFlags | chalkGmpFlagsMake();
          result = [value retain];
        }//end if (done)
        chalkGmpValueClear(&currentValue, YES, context.gmpPool);
      }//if (operandGmp)
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
//end combineCosh:token:context:

+(CHChalkValue*) combineTanh:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    @autoreleasepool {
      CHChalkValue* operandValue = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueList* operandList = [operandValue dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValueMatrix* operandMatrix = [operandValue dynamicCastToClass:[CHChalkValueMatrix class]];
      CHChalkValueQuaternion* operandQuaternion = [operandValue dynamicCastToClass:[CHChalkValueQuaternion class]];
      CHChalkValueNumberGmp* operandGmp = [operandValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueFormal* operandFormal = [operandValue dynamicCastToClass:[CHChalkValueFormal class]];
      operandGmp = !operandFormal ? operandGmp : operandFormal.value;
      if (operandList)
        result = [[self combineSEL:_cmd arguments:operands list:operandList index:0 token:token context:context] retain];
      else if (operandMatrix)
      {
        CHChalkValueMatrix* newMatrix = [[self combineMatrixSEL:_cmd operand:operandMatrix token:token context:context] retain];
        if (context.errorContext.hasError)
        {
          [newMatrix release];
          newMatrix = nil;
        }//end if (context.errorContext.hasError)
        result = newMatrix;
      }//end if (operandMatrix)
      else if (operandQuaternion)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericInvalid range:token.range]
                               replace:NO];
      else if (operandGmp)
      {
        mpfr_clear_flags();
        mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
        const chalk_gmp_value_t* operand = operandGmp.valueConstReference;
        chalk_compute_flags_t computeFlags = 0;
        chalk_gmp_value_t currentValue = {0};
        chalkGmpValueSet(&currentValue, operand, context.gmpPool);
        chalkGmpValueMakeReal(&currentValue, prec, context.gmpPool);
        BOOL done = NO;
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT))
        {
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
          mpfr_tanh(currentValue.realExact, currentValue.realExact, MPFR_RNDN);
          done = !mpfr_inexflag_p();
          if (done)
            computeFlags |= chalkGmpFlagsMake();
          else//if (!done)
          {
            chalkGmpValueSet(&currentValue, operand, context.gmpPool);
            chalkGmpValueMakeRealApprox(&currentValue, prec, context.gmpPool);
          }//end if (!done)
          chalkGmpFlagsRestore(oldFlags);
        }//end (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT))
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX))
        {
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
          mpfir_tanh(currentValue.realApprox, currentValue.realApprox);
          computeFlags |= chalkGmpFlagsMake();
          done = YES;
          chalkGmpFlagsRestore(oldFlags);
        }//end (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX))
        if (!done)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                 replace:NO];
        else//if (done)
        {
          chalkGmpValueSimplify(&currentValue, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
          CHChalkValueNumberGmp* value =
            [[[CHChalkValueNumberGmp alloc] initWithToken:token value:&currentValue naturalBase:operandGmp.naturalBase context:context] autorelease];
          if (!value)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                   replace:NO];
          value.evaluationComputeFlags |= computeFlags | chalkGmpFlagsMake();
          result = [value retain];
        }//end if (done)
        chalkGmpValueClear(&currentValue, YES, context.gmpPool);
      }//if (operandGmp)
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
//end combineTanh:token:context:

+(CHChalkValue*) combineASinh:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    @autoreleasepool {
      CHChalkValue* operandValue = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueList* operandList = [operandValue dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValueMatrix* operandMatrix = [operandValue dynamicCastToClass:[CHChalkValueMatrix class]];
      CHChalkValueQuaternion* operandQuaternion = [operandValue dynamicCastToClass:[CHChalkValueQuaternion class]];
      CHChalkValueNumberGmp* operandGmp = [operandValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueFormal* operandFormal = [operandValue dynamicCastToClass:[CHChalkValueFormal class]];
      operandGmp = !operandFormal ? operandGmp : operandFormal.value;
      if (operandList)
        result = [[self combineSEL:_cmd arguments:operands list:operandList index:0 token:token context:context] retain];
      else if (operandMatrix)
      {
        CHChalkValueMatrix* newMatrix = [[self combineMatrixSEL:_cmd operand:operandMatrix token:token context:context] retain];
        if (context.errorContext.hasError)
        {
          [newMatrix release];
          newMatrix = nil;
        }//end if (context.errorContext.hasError)
        result = newMatrix;
      }//end if (operandMatrix)
      else if (operandQuaternion)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericInvalid range:token.range]
                               replace:NO];
      else if (operandGmp)
      {
        mpfr_clear_flags();
        mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
        const chalk_gmp_value_t* operand = operandGmp.valueConstReference;
        chalk_compute_flags_t computeFlags = 0;
        chalk_gmp_value_t currentValue = {0};
        chalkGmpValueSet(&currentValue, operand, context.gmpPool);
        chalkGmpValueMakeReal(&currentValue, prec, context.gmpPool);
        BOOL done = NO;
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT))
        {
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
          mpfr_asinh(currentValue.realExact, currentValue.realExact, MPFR_RNDN);
          done = !mpfr_inexflag_p();
          if (done)
            computeFlags |= chalkGmpFlagsMake();
          else//if (!done)
          {
            chalkGmpValueSet(&currentValue, operand, context.gmpPool);
            chalkGmpValueMakeRealApprox(&currentValue, prec, context.gmpPool);
          }//end if (!done)
          chalkGmpFlagsRestore(oldFlags);
        }//end (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT))
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX))
        {
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
          mpfir_asinh(currentValue.realApprox, currentValue.realApprox);
          computeFlags |= chalkGmpFlagsMake();
          done = YES;
          chalkGmpFlagsRestore(oldFlags);
        }//end (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX))
        if (!done)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                 replace:NO];
        else//if (done)
        {
          chalkGmpValueSimplify(&currentValue, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
          CHChalkValueNumberGmp* value =
            [[[CHChalkValueNumberGmp alloc] initWithToken:token value:&currentValue naturalBase:operandGmp.naturalBase context:context] autorelease];
          if (!value)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                   replace:NO];
          value.evaluationComputeFlags |= computeFlags | chalkGmpFlagsMake();
          result = [value retain];
        }//end if (done)
        chalkGmpValueClear(&currentValue, YES, context.gmpPool);
      }//if (operandGmp)
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
//end combineASinh:token:context:

+(CHChalkValue*) combineACosh:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    @autoreleasepool {
      CHChalkValue* operandValue = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueList* operandList = [operandValue dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValueMatrix* operandMatrix = [operandValue dynamicCastToClass:[CHChalkValueMatrix class]];
      CHChalkValueQuaternion* operandQuaternion = [operandValue dynamicCastToClass:[CHChalkValueQuaternion class]];
      CHChalkValueNumberGmp* operandGmp = [operandValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueFormal* operandFormal = [operandValue dynamicCastToClass:[CHChalkValueFormal class]];
      operandGmp = !operandFormal ? operandGmp : operandFormal.value;
      if (operandList)
        result = [[self combineSEL:_cmd arguments:operands list:operandList index:0 token:token context:context] retain];
      else if (operandMatrix)
      {
        CHChalkValueMatrix* newMatrix = [[self combineMatrixSEL:_cmd operand:operandMatrix token:token context:context] retain];
        if (context.errorContext.hasError)
        {
          [newMatrix release];
          newMatrix = nil;
        }//end if (context.errorContext.hasError)
        result = newMatrix;
      }//end if (operandMatrix)
      else if (operandQuaternion)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericInvalid range:token.range]
                               replace:NO];
      else if (operandGmp)
      {
        mpfr_clear_flags();
        mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
        const chalk_gmp_value_t* operand = operandGmp.valueConstReference;
        chalk_compute_flags_t computeFlags = 0;
        chalk_gmp_value_t currentValue = {0};
        chalkGmpValueSet(&currentValue, operand, context.gmpPool);
        chalkGmpValueMakeReal(&currentValue, prec, context.gmpPool);
        BOOL done = NO;
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT))
        {
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
          mpfr_acosh(currentValue.realExact, currentValue.realExact, MPFR_RNDN);
          done = !mpfr_inexflag_p();
          if (done)
            computeFlags |= chalkGmpFlagsMake();
          else//if (!done)
          {
            chalkGmpValueSet(&currentValue, operand, context.gmpPool);
            chalkGmpValueMakeRealApprox(&currentValue, prec, context.gmpPool);
          }//end if (!done)
          chalkGmpFlagsRestore(oldFlags);
        }//end (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT))
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX))
        {
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
          mpfir_acosh(currentValue.realApprox, currentValue.realApprox);
          computeFlags |= chalkGmpFlagsMake();
          done = YES;
          chalkGmpFlagsRestore(oldFlags);
        }//end (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX))
        if (!done)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                 replace:NO];
        else//if (done)
        {
          chalkGmpValueSimplify(&currentValue, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
          CHChalkValueNumberGmp* value =
            [[[CHChalkValueNumberGmp alloc] initWithToken:token value:&currentValue naturalBase:operandGmp.naturalBase context:context] autorelease];
          if (!value)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                   replace:NO];
          value.evaluationComputeFlags |= computeFlags | chalkGmpFlagsMake();
          result = [value retain];
        }//end if (done)
        chalkGmpValueClear(&currentValue, YES, context.gmpPool);
      }//if (operandGmp)
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
//end combineACosh:token:context:

+(CHChalkValue*) combineATanh:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    @autoreleasepool {
      CHChalkValue* operandValue = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueList* operandList = [operandValue dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValueMatrix* operandMatrix = [operandValue dynamicCastToClass:[CHChalkValueMatrix class]];
      CHChalkValueQuaternion* operandQuaternion = [operandValue dynamicCastToClass:[CHChalkValueQuaternion class]];
      CHChalkValueNumberGmp* operandGmp = [operandValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueFormal* operandFormal = [operandValue dynamicCastToClass:[CHChalkValueFormal class]];
      operandGmp = !operandFormal ? operandGmp : operandFormal.value;
      if (operandList)
        result = [[self combineSEL:_cmd arguments:operands list:operandList index:0 token:token context:context] retain];
      else if (operandMatrix)
      {
        CHChalkValueMatrix* newMatrix = [[self combineMatrixSEL:_cmd operand:operandMatrix token:token context:context] retain];
        if (context.errorContext.hasError)
        {
          [newMatrix release];
          newMatrix = nil;
        }//end if (context.errorContext.hasError)
        result = newMatrix;
      }//end if (operandMatrix)
      else if (operandQuaternion)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericInvalid range:token.range]
                               replace:NO];
      else if (operandGmp)
      {
        mpfr_clear_flags();
        mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
        const chalk_gmp_value_t* operand = operandGmp.valueConstReference;
        chalk_compute_flags_t computeFlags = 0;
        chalk_gmp_value_t currentValue = {0};
        chalkGmpValueSet(&currentValue, operand, context.gmpPool);
        chalkGmpValueMakeReal(&currentValue, prec, context.gmpPool);
        BOOL done = NO;
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT))
        {
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
          mpfr_atanh(currentValue.realExact, currentValue.realExact, MPFR_RNDN);
          done = !mpfr_inexflag_p();
          if (done)
            computeFlags |= chalkGmpFlagsMake();
          else//if (!done)
          {
            chalkGmpValueSet(&currentValue, operand, context.gmpPool);
            chalkGmpValueMakeRealApprox(&currentValue, prec, context.gmpPool);
          }//end if (!done)
          chalkGmpFlagsRestore(oldFlags);
        }//end (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT))
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX))
        {
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
          mpfir_atanh(currentValue.realApprox, currentValue.realApprox);
          computeFlags |= chalkGmpFlagsMake();
          done = YES;
          chalkGmpFlagsRestore(oldFlags);
        }//end (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX))
        if (!done)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                 replace:NO];
        else//if (done)
        {
          chalkGmpValueSimplify(&currentValue, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
          CHChalkValueNumberGmp* value =
            [[[CHChalkValueNumberGmp alloc] initWithToken:token value:&currentValue naturalBase:operandGmp.naturalBase context:context] autorelease];
          if (!value)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                   replace:NO];
          value.evaluationComputeFlags |= computeFlags | chalkGmpFlagsMake();
          result = [value retain];
        }//end if (done)
        chalkGmpValueClear(&currentValue, YES, context.gmpPool);
      }//if (operandGmp)
      else
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                               replace:NO];
      result.evaluationComputeFlags |=
        operandValue.evaluationComputeFlags |
        chalkGmpFlagsMake();
    }//end @autoreleasepool
  }//end if (operands.count == 2)
  return [result autorelease];
}
//end combineATanh:token:context:

+(CHChalkValue*) combineGamma:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    @autoreleasepool {
      CHChalkValue* operandValue = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueList* operandList = [operandValue dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValueMatrix* operandMatrix = [operandValue dynamicCastToClass:[CHChalkValueMatrix class]];
      CHChalkValueNumberGmp* operandGmp = [operandValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueFormal* operandFormal = [operandValue dynamicCastToClass:[CHChalkValueFormal class]];
      operandGmp = !operandFormal ? operandGmp : operandFormal.value;
      if (operandList)
        result = [[self combineSEL:_cmd arguments:operands list:operandList index:0 token:token context:context] retain];
      else if (operandMatrix)
      {
        CHChalkValueMatrix* newMatrix = [[self combineMatrixSEL:_cmd operand:operandMatrix token:token context:context] retain];
        if (context.errorContext.hasError)
        {
          [newMatrix release];
          newMatrix = nil;
        }//end if (context.errorContext.hasError)
        result = newMatrix;
      }//end if (operandMatrix)
      else if (operandGmp)
      {
        BOOL done = NO;
        const chalk_gmp_value_t* operand = operandGmp.valueConstReference;
        if (!operand)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                 replace:NO];
        else if (operand->type == CHALK_VALUE_TYPE_INTEGER)
        {
          chalk_gmp_value_t operandMinusOneValue = {0};
          chalkGmpValueSet(&operandMinusOneValue, operand, context.gmpPool);
          mpz_sub_ui(operandMinusOneValue.integer, operand->integer, 1);
          CHChalkValueNumberGmp* numberMinusOne = [[[CHChalkValueNumberGmp alloc] initWithToken:token value:&operandMinusOneValue naturalBase:(!context ? 10 : context.computationConfiguration.baseDefault) context:context] autorelease];
          chalkGmpValueClear(&operandMinusOneValue, YES, context.gmpPool);
          const chalk_gmp_value_t* operandMinusOne = numberMinusOne.valueConstReference;
          if (!operandMinusOne)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                   replace:NO];
          else if (mpz_sgn(operandMinusOne->integer) > 0)
            result = [[CHParserOperatorNode combineFactorial:@[numberMinusOne] operatorToken:token context:context] retain];
          else if (mpz_sgn(operandMinusOne->integer) == 0)
            result = [[CHChalkValueNumberGmp alloc] initWithToken:token integer:1 naturalBase:(!context ? 10 : context.computationConfiguration.baseDefault) context:context];
          else
          {
            mpfr_set_nanflag();
            result = [[CHChalkValueNumberGmp nanWithContext:context] retain];
          }
        }//end if (operand->type == CHALK_VALUE_TYPE_INTEGER)
        else
        {
          mpfr_clear_flags();
          mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;

          chalk_compute_flags_t computeFlags = 0;
          chalk_gmp_value_t currentValue = {0};
          chalkGmpValueSet(&currentValue, operand, context.gmpPool);
          chalkGmpValueMakeRealApprox(&currentValue, prec, context.gmpPool);
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);

          arb_t arbValue;
          arbDepool(arbValue, context.gmpPool);
          arb_set_interval_mpfr(arbValue, &currentValue.realApprox->interval.left, &currentValue.realApprox->interval.right, prec);
          arb_gamma(arbValue, arbValue, prec);
          arb_get_interval_mpfr(&currentValue.realApprox->interval.left, &currentValue.realApprox->interval.right, arbValue);
          mpfir_estimation_update(currentValue.realApprox);
          mpfr_set_inexflag();
          if (mpfir_nan_p(currentValue.realApprox))
            mpfr_set_nanflag();
          if (mpfir_inf_p(currentValue.realApprox))
            mpfr_set_erangeflag();
          arbRepool(arbValue, context.gmpPool);

          computeFlags |= chalkGmpFlagsMake();
          done = YES;
          chalkGmpFlagsRestore(oldFlags);

          if (!done)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                   replace:NO];
          else//if (done)
          {
            chalkGmpValueSimplify(&currentValue, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
            CHChalkValueNumberGmp* value =
              [[[CHChalkValueNumberGmp alloc] initWithToken:token value:&currentValue naturalBase:operandGmp.naturalBase context:context] autorelease];
            if (!value)
              [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                     replace:NO];
            value.evaluationComputeFlags |= computeFlags | chalkGmpFlagsMake();
            result = [value retain];
          }//end if (done)
          chalkGmpValueClear(&currentValue, YES, context.gmpPool);
        }//end if approx
      }//end if (operandGmp)
      else
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                               replace:NO];
      result.evaluationComputeFlags |=
        operandValue.evaluationComputeFlags |
        chalkGmpFlagsMake();
    }//end @autoreleasepool
  }//end if (operands.count == 2)
  return [result autorelease];
}
//end combineGamma:token:context:

+(CHChalkValue*) combineZeta:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    @autoreleasepool {
      CHChalkValue* operandValue = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueList* operandList = [operandValue dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValueMatrix* operandMatrix = [operandValue dynamicCastToClass:[CHChalkValueMatrix class]];
      CHChalkValueNumberGmp* operandGmp = [operandValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueFormal* operandFormal = [operandValue dynamicCastToClass:[CHChalkValueFormal class]];
      operandGmp = !operandFormal ? operandGmp : operandFormal.value;
      if (operandList)
        result = [[self combineSEL:_cmd arguments:operands list:operandList index:0 token:token context:context] retain];
      else if (operandMatrix)
      {
        CHChalkValueMatrix* newMatrix = [[self combineMatrixSEL:_cmd operand:operandMatrix token:token context:context] retain];
        if (context.errorContext.hasError)
        {
          [newMatrix release];
          newMatrix = nil;
        }//end if (context.errorContext.hasError)
        result = newMatrix;
      }//end if (operandMatrix)
      else if (operandGmp)
      {
        BOOL done = NO;
        const chalk_gmp_value_t* operand = operandGmp.valueConstReference;
        if (!operand)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                 replace:NO];
        else
        {
          mpfr_clear_flags();
          mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;

          chalk_compute_flags_t computeFlags = 0;
          chalk_gmp_value_t currentValue = {0};
          chalkGmpValueSet(&currentValue, operand, context.gmpPool);
          chalkGmpValueMakeRealApprox(&currentValue, prec, context.gmpPool);
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);

          arb_t arbValue;
          arbDepool(arbValue, context.gmpPool);
          arb_set_interval_mpfr(arbValue, &currentValue.realApprox->interval.left, &currentValue.realApprox->interval.right, prec);
          arb_zeta(arbValue, arbValue, prec);
          arb_get_interval_mpfr(&currentValue.realApprox->interval.left, &currentValue.realApprox->interval.right, arbValue);
          mpfir_estimation_update(currentValue.realApprox);
          mpfr_set_inexflag();
          if (mpfir_nan_p(currentValue.realApprox))
            mpfr_set_nanflag();
          if (mpfir_inf_p(currentValue.realApprox))
            mpfr_set_erangeflag();
          arbRepool(arbValue, context.gmpPool);

          computeFlags |= chalkGmpFlagsMake();
          done = YES;
          chalkGmpFlagsRestore(oldFlags);

          if (!done)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                   replace:NO];
          else//if (done)
          {
            chalkGmpValueSimplify(&currentValue, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
            CHChalkValueNumberGmp* value =
              [[[CHChalkValueNumberGmp alloc] initWithToken:token value:&currentValue naturalBase:operandGmp.naturalBase context:context] autorelease];
            if (!value)
              [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                     replace:NO];
            value.evaluationComputeFlags |= computeFlags | chalkGmpFlagsMake();
            result = [value retain];
          }//end if (done)
          chalkGmpValueClear(&currentValue, YES, context.gmpPool);
        }//end if approx
      }//end if (operandGmp)
      else
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                               replace:NO];
      result.evaluationComputeFlags |=
        operandValue.evaluationComputeFlags |
        chalkGmpFlagsMake();
    }//end @autoreleasepool
  }//end if (operands.count == 2)
  return [result autorelease];
}
//end combineZeta:token:context:

+(CHChalkValue*) combineConj:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    @autoreleasepool {
      CHChalkValue* operandValue = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueList* operandList = [operandValue dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValueMatrix* operandMatrix = [operandValue dynamicCastToClass:[CHChalkValueMatrix class]];
      CHChalkValueQuaternion* operandQuaternion = [operandValue dynamicCastToClass:[CHChalkValueQuaternion class]];
      CHChalkValueNumberGmp* operandGmp = [operandValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueFormal* operandFormal = [operandValue dynamicCastToClass:[CHChalkValueFormal class]];
      operandGmp = !operandFormal ? operandGmp : operandFormal.value;
      if (operandList)
        result = [[self combineSEL:_cmd arguments:operands list:operandList index:0 token:token context:context] retain];
      else if (operandMatrix)
      {
        CHChalkValueMatrix* newMatrix = [[self combineMatrixSEL:_cmd operand:operandMatrix token:token context:context] retain];
        if (context.errorContext.hasError)
        {
          [newMatrix release];
          newMatrix = nil;
        }//end if (context.errorContext.hasError)
        result = newMatrix;
      }//end if (operandMatrix)
      else if (operandQuaternion)
      {
        mpfr_clear_flags();
        CHChalkValueQuaternion* value = [operandQuaternion copy];
        //[value.token unionWithToken:token];//experimental
        if (!value)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                 replace:NO];
        [value conjugate];
        value.evaluationComputeFlags |= chalkGmpFlagsMake();
        result = value;
      }//end if (operandQuaternion)
      else if (operandGmp)
      {
        mpfr_clear_flags();
        CHChalkValueNumberGmp* value = [operandGmp copy];
        //[value.token unionWithToken:token];//experimental
        if (!value)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                 replace:NO];
        value.evaluationComputeFlags |= chalkGmpFlagsMake();
        result = value;
      }//if (operandGmp)
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
//end combineConj:token:context:

+(CHChalkValue*) combineSqr:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    @autoreleasepool {
      CHChalkValue* operandValue = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueNumberGmp* operandGmp = [operandValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueFormal* operandFormal = [operandValue dynamicCastToClass:[CHChalkValueFormal class]];
      operandGmp = !operandFormal ? operandGmp : operandFormal.value;
      CHChalkValueList* operandList = [operandValue dynamicCastToClass:[CHChalkValueList class]];
      if (operandList)
        result = [[self combineSEL:_cmd arguments:operands list:operandList index:0 token:token context:context] retain];
      else if (operandGmp)
      {
        mpfr_clear_flags();
        mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
        const chalk_gmp_value_t* operand = operandGmp.valueConstReference;
        chalk_compute_flags_t computeFlags = 0;
        chalk_gmp_value_t currentValue = {0};
        chalkGmpValueSet(&currentValue, operand, context.gmpPool);
        BOOL done = NO;
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_INTEGER))
        {
          mpz_t tmpInteger;
          mpzDepool(tmpInteger, context.gmpPool);
          mpz_mul(tmpInteger, currentValue.integer, currentValue.integer);
          mpz_swap(tmpInteger, currentValue.integer);
          mpzRepool(tmpInteger, context.gmpPool);
          done = YES;
        }//end if (!done && (currentValue.type == CHALK_VALUE_TYPE_INTEGER))
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_FRACTION))
        {
          mpz_t tmpInteger;
          mpzDepool(tmpInteger, context.gmpPool);
          mpz_mul(tmpInteger, mpq_numref(currentValue.fraction), mpq_numref(currentValue.fraction));
          mpz_swap(tmpInteger, mpq_numref(currentValue.fraction));
          mpz_mul(tmpInteger, mpq_denref(currentValue.fraction), mpq_denref(currentValue.fraction));
          mpz_swap(tmpInteger, mpq_denref(currentValue.fraction));
          mpzRepool(tmpInteger, context.gmpPool);
          done = YES;
        }//end if (!done && (currentValue.type == CHALK_VALUE_TYPE_FRACTION))
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT))
        {
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
          mpfr_sqr(currentValue.realExact, currentValue.realExact, MPFR_RNDN);
          done = !mpfr_inexflag_p();
          if (done)
            computeFlags |= chalkGmpFlagsMake();
          else//if (!done)
          {
            chalkGmpValueSet(&currentValue, operand, context.gmpPool);
            chalkGmpValueMakeRealApprox(&currentValue, prec, context.gmpPool);
          }//end if (!done)
          chalkGmpFlagsRestore(oldFlags);
        }//end if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT))
        if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX))
        {
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
          mpfir_sqr(currentValue.realApprox, currentValue.realApprox);
          computeFlags |= chalkGmpFlagsMake();
          done = YES;
          chalkGmpFlagsRestore(oldFlags);
        }//end if (!done && (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX))
        if (!done)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                 replace:NO];
        else//if (done)
        {
          chalkGmpValueSimplify(&currentValue, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
          CHChalkValue* value = !done ? nil :
            [[CHChalkValueNumberGmp alloc] initWithToken:token value:&currentValue naturalBase:operandGmp.naturalBase context:context];
          if (!value)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                   replace:NO];
          value.evaluationComputeFlags |= computeFlags | chalkGmpFlagsMake();
          result = value;
        }//end if (done)
        chalkGmpValueClear(&currentValue, YES, context.gmpPool);
      }//if (operandGmp)
      else if (operandValue)
        result = [[CHParserOperatorNode combineMul:@[operandValue, operandValue] operatorToken:token context:context] retain];
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
//end combineSqr:token:context:

+(CHChalkValue*) combinePow:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 2)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 2)
  {
    @autoreleasepool {
      CHChalkValue* operand1Value = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueQuaternion* operand1Quaternion = [operand1Value dynamicCastToClass:[CHChalkValueQuaternion class]];
      CHChalkValueNumberGmp* operand1Gmp = [operand1Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueMatrix* operand1Matrix = [operand1Value dynamicCastToClass:[CHChalkValueMatrix class]];
      CHChalkValueList* operand1List = [operand1Value dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValue* operand2Value = [[operands objectAtIndex:1] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueQuaternion* operand2Quaternion = [operand2Value dynamicCastToClass:[CHChalkValueQuaternion class]];
      CHChalkValueNumberGmp* operand2Gmp = [operand2Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueList* operand2List = [operand2Value dynamicCastToClass:[CHChalkValueList class]];
      if (!operand1Value || !operand2Value)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                               replace:NO];
      else if (operand2List)
        result = [[self combineSEL:_cmd arguments:operands list:operand2List index:1 token:token context:context] retain];
      else if (operand1List)
        result = [[self combineSEL:_cmd arguments:operands list:operand1List index:0 token:token context:context] retain];
      else if (operand1Matrix && operand2Gmp && (operand2Gmp.valueType == CHALK_VALUE_TYPE_INTEGER))
      {
        CHChalkValue* newValue = [[CHParserFunctionNode pow:operand1Matrix integerPower:operand2Gmp.valueConstReference->integer operatorToken:token context:context] retain];
        if (!newValue)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                 replace:NO];
        result = newValue;
      }//end if (operand1Matrix && operand2Gmp && (operand2Gmp.valueType == CHALK_VALUE_TYPE_INTEGER))
      else if (operand1Quaternion && operand2Gmp)
      {
        const chalk_gmp_value_t* operand2GmpValue = operand2Gmp.valueConstReference;
        if (!operand2GmpValue || (operand2GmpValue->type != CHALK_VALUE_TYPE_INTEGER))
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorOperationNonImplemented range:token.range]
                                 replace:NO];
        else//if (operand2GmpValue && (operand2GmpValue->type == CHALK_VALUE_TYPE_INTEGER))
        {
          BOOL ignoringSign = NO;
          if ([operand2Gmp isZero])
          {
            CHChalkValueNumberGmp* newValue =
              [[CHChalkValueNumberGmp alloc] initWithToken:token integer:1 naturalBase:operand1Value.naturalBase context:context];
            result = newValue;
          }//end if ([operand2Gmp isZero])
          else if ([operand2Gmp isOne:&ignoringSign] || ignoringSign)//^1 or ^(-1)
          {
            if (!ignoringSign){//^1
            }
            else//^(-1)
            {
              CHChalkValue* newValue = [[CHParserFunctionNode combineInv:@[operand1Value] token:token context:context] retain];
              if (!newValue)
                [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                       replace:NO];
              result = newValue;
            }//end ^(-1)
          }//end if ([operand2Gmp isOne:&ignoringSign] || ignoringSign)//^1 or ^(-1)
          else//if (!0 && !1 && !-1)
          {
            CHChalkValue* newValue = [[CHParserFunctionNode pow:operand1Value integerPower:operand2GmpValue->integer operatorToken:token context:context] retain];
            if (!newValue)
              [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                     replace:NO];
            result = newValue;
          }//end if (![operand2Gmp isZero] && ![operand2Gmp isOne:&ignoringSign])
        }//end if (operandGmpValue && (operand2GmpValue->type == CHALK_VALUE_TYPE_INTEGER))
        if (!result)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorOperationNonImplemented range:token.range]
                                 replace:NO];
      }//end if (operand1Quaternion && operand2Gmp)
      else if (operand1Gmp && operand2Quaternion)
      {
        CHChalkValue* log = [CHParserFunctionNode combineLn:@[operand1Value] token:token context:context];
        CHChalkValue* product = !log ? nil :
          [CHParserOperatorNode combineMul:@[operand2Quaternion, log] operatorToken:token context:context];
        CHChalkValue* newValue = !product ? nil :
          [[CHParserFunctionNode combineExp:@[product] token:token context:context] retain];
        if (!newValue)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                 replace:NO];
        result = newValue;
      }//end if (operand1Gmp && operand2Quaternion)
      else if (operand1Quaternion && operand2Quaternion)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorOperationNonImplemented range:token.range]
                               replace:NO];
      else if (operand1Gmp && operand1Gmp.valueConstReference && operand2Gmp && operand2Gmp.valueConstReference)
      {
        mpfr_clear_flags();
        mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
        chalk_compute_flags_t computeFlags = 0;
        chalk_gmp_value_t currentValue = {0};
        chalkGmpValueSet(&currentValue, operand1Gmp.valueConstReference, context.gmpPool);
        const chalk_gmp_value_t* operand2GmpValue = operand2Gmp.valueConstReference;
        BOOL done = NO;
        BOOL ignoringSign = NO;
        if (operand2Gmp.isZero)
        {
          if (chalkGmpValueIsZero(&currentValue, computeFlags))
          {
            chalkGmpValueSetNan(&currentValue, YES, context.gmpPool);
            if (!context.computationConfiguration.propagateNaN)
              [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericInvalid range:token.range]
                                     replace:NO];
          }//end if (chalkGmpValueIsZero(&currentValue, computeFlags))
          else//if (!chalkGmpValueIsZero(&currentValue, computeFlags))
          {
            chalkGmpValueClear(&currentValue, YES, context.gmpPool);
            mpzDepool(currentValue.integer, context.gmpPool);
            mpz_set_si(currentValue.integer, 1);
            currentValue.type = CHALK_VALUE_TYPE_INTEGER;
          }//end if (!chalkGmpValueIsZero(&currentValue, computeFlags))
          done = YES;
        }//end if (operand2GmpValue.isZero)
        else if ([operand2Gmp isOne:&ignoringSign] || ignoringSign)//^1 or ^(-1)
        {
          if (!ignoringSign){//^1
            done = YES;
          }
          else//^(-1)
          {
            chalkGmpValueInvert(&currentValue, context.gmpPool);
            done = YES;
          }//end ^(-1)
        }//end if (^1 || ^-1)
        else if (chalkGmpValueIsZero(&currentValue, operand1Gmp.evaluationComputeFlags)){
          if (chalkGmpValueSign(operand2GmpValue) > 0)
            done = YES;
        }//end if (chalkGmpValueIsZero(&currentValue, operand1Gmp.evaluationComputeFlags)){
        else if (chalkGmpValueIsOne(&currentValue, &ignoringSign, operand1Gmp.evaluationComputeFlags) || ignoringSign)//(1)^(...) or (-1)^(...)
        {
          if (!ignoringSign){//^1
            done = YES;
          }
          else//(-1)^(...)
          {
            if (operand2GmpValue->type == CHALK_VALUE_TYPE_INTEGER)
            {
              BOOL isEvenPower = mpz_even_p(operand2GmpValue->integer);
              if (isEvenPower)
                chalkGmpValueNeg(&currentValue);
              done = YES;
            }//end if (operand2GmpValue->type == CHALK_VALUE_TYPE_INTEGER)
          }//end (-1)^(...)
        }//end (1)^(...) or (-1)^(...)
        if (!done && !context.errorContext.hasError)
        {
          if (!done && !context.errorContext.hasError && (currentValue.type == CHALK_VALUE_TYPE_INTEGER) && (operand2GmpValue->type == CHALK_VALUE_TYPE_INTEGER))
          {
            if (mpz_sgn(operand2GmpValue->integer) >= 0)
              done = [CHParserFunctionNode powIntegers:currentValue.integer op1:currentValue.integer op2:operand2GmpValue->integer operatorToken:token context:context];
            else//if (mpz_sgn(operand2GmpValue->integer) < 0)
            {
              if (chalkGmpValueIsZero(&currentValue, computeFlags))
                [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericDivideByZero range:token.range]
                                       replace:NO];
              else//if (!chalkGmpValueIsZero(&currentValue, computeFlags))
              {
                chalkGmpValueMakeFraction(&currentValue, context.gmpPool);
                mpz_swap(mpq_numref(currentValue.fraction), mpq_denref(currentValue.fraction));
                chalk_gmp_value_t currentPowAbs = {0};
                chalkGmpValueSet(&currentPowAbs, operand2GmpValue, context.gmpPool);
                mpz_abs(currentPowAbs.integer, currentPowAbs.integer);
                done = [CHParserFunctionNode powIntegers:mpq_denref(currentValue.fraction) op1:mpq_denref(currentValue.fraction) op2:currentPowAbs.integer operatorToken:token context:context];
                if (!done)
                  mpz_swap(mpq_numref(currentValue.fraction), mpq_denref(currentValue.fraction));
                chalkGmpValueClear(&currentPowAbs, YES, context.gmpPool);
              }//end if (!chalkGmpValueIsZero(&currentValue, computeFlags))
            }//end if (mpz_sgn(operand2GmpValue->integer) < 0)
          }//end if (!done && !context.errorContext.hasError && (currentValue.type == CHALK_VALUE_TYPE_INTEGER) && (operand2GmpValue->type == CHALK_VALUE_TYPE_INTEGER))
          if (!done && !context.errorContext.hasError && (currentValue.type == CHALK_VALUE_TYPE_FRACTION) && (operand2GmpValue->type == CHALK_VALUE_TYPE_INTEGER))
          {
            BOOL didSwapFraction = NO;
            mpz_srcptr currentPower = operand2GmpValue->integer;
            chalk_gmp_value_t currentPowAbs = {0};
            if (mpz_sgn(operand2GmpValue->integer) < 0)
            {
              if (chalkGmpValueIsZero(&currentValue, computeFlags))
                [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericDivideByZero range:token.range]
                                       replace:NO];
              else//if (!chalkGmpValueIsZero(&currentValue, computeFlags))
              {
                mpz_swap(mpq_numref(currentValue.fraction), mpq_denref(currentValue.fraction));
                didSwapFraction = YES;
                chalkGmpValueSet(&currentPowAbs, operand2GmpValue, context.gmpPool);
                mpz_abs(currentPowAbs.integer, currentPowAbs.integer);
                currentPower = currentPowAbs.integer;
              }//end if (!chalkGmpValueIsZero(&currentValue, computeFlags))
            }//end if (mpz_sgn(operand2GmpValue->integer) < 0)
            if (context.errorContext.hasError){
            }
            else if (mpz_fits_ulong_p(currentPower))
            {
              mpz_t num, den;
              mpzDepool(num, context.gmpPool);
              mpzDepool(den, context.gmpPool);
              BOOL ok =
                [CHParserFunctionNode powIntegers:num op1:mpq_numref(currentValue.fraction) op2:currentPower operatorToken:token context:context] &&
                [CHParserFunctionNode powIntegers:den op1:mpq_denref(currentValue.fraction) op2:currentPower operatorToken:token context:context];
              if (ok)
              {
                mpq_t numq, denq;
                mpqDepool(numq, context.gmpPool);
                mpqDepool(denq, context.gmpPool);
                mpq_set_z(numq, num);
                mpq_set_z(denq, den);
                mpq_div(currentValue.fraction, numq, denq);
                mpqRepool(numq, context.gmpPool);
                mpqRepool(denq, context.gmpPool);
                done = YES;
              }//end if (ok)
              else if (didSwapFraction)
                mpz_swap(mpq_numref(currentValue.fraction), mpq_denref(currentValue.fraction));
              mpzRepool(num, context.gmpPool);
              mpzRepool(den, context.gmpPool);
              chalkGmpValueSimplify(&currentValue, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
            }//end if (mpz_fits_ulong_p(currentPower))
            chalkGmpValueClear(&currentPowAbs, YES, context.gmpPool);
          }//end if (!done && !context.errorContext.hasError && (currentValueGmpValue->type == CHALK_VALUE_TYPE_FRACTION) && (operandGmpValue->type == CHALK_VALUE_TYPE_INTEGER))
          if (!done && !context.errorContext.hasError && (operand2GmpValue->type == CHALK_VALUE_TYPE_INTEGER))
          {
            chalkGmpValueMakeReal(&currentValue, prec, context.gmpPool);
            if (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT)
            {
              chalk_gmp_value_t nextValue = {0};
              mpfrDepool(nextValue.realExact, prec, context.gmpPool);
              nextValue.type = CHALK_VALUE_TYPE_REAL_EXACT;
              mpfr_set_zero(nextValue.realExact, 0);
              chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
              if (mpz_fits_sint_p(operand2GmpValue->integer))
              {
                mpfr_pow_si(nextValue.realExact, currentValue.realExact, mpz_get_si(operand2GmpValue->integer), MPFR_RNDN);
                done = !mpfr_inexflag_p();
              }//end if (mpz_fits_sint_p(operandGmpValue->integer))
              else if (mpz_fits_uint_p(operand2GmpValue->integer))
              {
                mpfr_pow_ui(nextValue.realExact, currentValue.realExact, mpz_get_ui(operand2GmpValue->integer), MPFR_RNDN);
                done = !mpfr_inexflag_p();
              }//end if (mpz_fits_uint_p(operandGmpValue->integer))
              else//if operand is large
              {
                mpfr_pow_z(nextValue.realExact, currentValue.realExact, operand2GmpValue->integer, MPFR_RNDN);
                done = !mpfr_inexflag_p();
              }//end if operand is large
              chalkGmpFlagsRestore(oldFlags);
              if (done)
                chalkGmpValueMove(&currentValue, &nextValue, context.gmpPool);
              chalkGmpValueClear(&nextValue, YES, context.gmpPool);
            }//end if (currentValue.type == CHALK_VALUE_TYPE_REAL_EXACT)
            else if (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX)
            {
              chalk_gmp_value_t nextValue = {0};
              mpfirDepool(nextValue.realApprox, prec, context.gmpPool);
              nextValue.type = CHALK_VALUE_TYPE_REAL_APPROX;
              mpfir_pow_z(nextValue.realApprox, currentValue.realApprox, operand2GmpValue->integer);
              done = YES;
              if (done)
                chalkGmpValueMove(&currentValue, &nextValue, context.gmpPool);
              chalkGmpValueClear(&nextValue, YES, context.gmpPool);
            }//end if (currentValue.type == CHALK_VALUE_TYPE_REAL_APPROX)
          }//end if (!done && !context.errorContext.hasError && (operandGmpValue->type == CHALK_VALUE_TYPE_INTEGER))
          if (!done && !context.errorContext.hasError && (currentValue.type != CHALK_VALUE_TYPE_REAL_APPROX) && (chalkGmpValueSign(&currentValue) < 0))
          {
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainGmp reason:CHChalkErrorGmpUnsupported range:token.range]
                                   replace:NO];
            done = YES;
          }//end if (!done && && !context.errorContext.hasError (currentValue.type != CHALK_VALUE_TYPE_REAL_APPROX) && (chalkGmpValueSign(&currentValue) < 0))
          if (!done && !context.errorContext.hasError)
          {
            chalkGmpValueMakeRealApprox(&currentValue, prec, context.gmpPool);
            chalk_gmp_value_t power = {0};
            chalkGmpValueSet(&power, operand2GmpValue, context.gmpPool);
            chalkGmpValueMakeRealApprox(&power, prec, context.gmpPool);
            chalk_gmp_value_t nextValue = {0};
            chalkGmpValueMakeRealApprox(&nextValue, prec, context.gmpPool);
            mpfir_log(nextValue.realApprox, currentValue.realApprox);
            mpfir_mul(nextValue.realApprox, power.realApprox, nextValue.realApprox);
            mpfir_exp(nextValue.realApprox, nextValue.realApprox);
            mpfir_swap(currentValue.realApprox, nextValue.realApprox);
            chalkGmpValueClear(&nextValue, YES, context.gmpPool);
            done = YES;
          }//end if ((currentValueGmpValue->type == CHALK_VALUE_TYPE_FRACTION) && (operandGmpValue->type == CHALK_VALUE_TYPE_REAL_EXACT))
        }//end if (!done && !context.errorContext.hasError)
        if (!done)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                 replace:NO];
        else//if (done)
        {
          chalkGmpValueSimplify(&currentValue, context.computationConfiguration.softIntegerMaxBits, context.gmpPool);
          CHChalkValueNumberGmp* value =
            [[[CHChalkValueNumberGmp alloc] initWithToken:token value:&currentValue naturalBase:operand1Gmp.naturalBase context:context] autorelease];
          if (!value)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                   replace:NO];
          value.evaluationComputeFlags |= computeFlags | chalkGmpFlagsMake();
          result = [value retain];
        }//end if (done)
        chalkGmpValueClear(&currentValue, YES, context.gmpPool);
      }//if (operand1Gmp && operand1Gmp.valueConstReference && operand2Gmp && operand2Gmp.valueConstReference)
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
//end combinePow:token:context:

+(CHChalkValue*) combineMatrix:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  @autoreleasepool {
    id parameter1 = (operands.count < 1) ? nil : [operands objectAtIndex:0];
    id parameter2 = (operands.count < 2) ? nil : [operands objectAtIndex:1];
    id parameter3 = (operands.count < 3) ? nil : [operands objectAtIndex:2];
    CHChalkValueNumberGmp* nbRowsGmp = [parameter1 dynamicCastToClass:[CHChalkValueNumberGmp class]];
    CHChalkValueNumberGmp* nbColsGmp = [parameter2 dynamicCastToClass:[CHChalkValueNumberGmp class]];
    const chalk_gmp_value_t* nbRowsGmpValue = nbRowsGmp.valueConstReference;
    const chalk_gmp_value_t* nbColsGmpValue = nbColsGmp.valueConstReference;
    NSUInteger nbRows = !nbRowsGmpValue || (nbRowsGmpValue->type != CHALK_VALUE_TYPE_INTEGER) || !mpz_fits_nsui_p(nbRowsGmpValue->integer) ? 0 :
      mpz_get_nsui(nbRowsGmpValue->integer);
    NSUInteger nbCols = !nbColsGmpValue || (nbColsGmpValue->type != CHALK_VALUE_TYPE_INTEGER) || !mpz_fits_nsui_p(nbColsGmpValue->integer) ? 0 :
      mpz_get_nsui(nbColsGmpValue->integer);
    CHChalkValueScalar* fillValue = [parameter3 dynamicCastToClass:[CHChalkValueScalar class]];
    if (!parameter1 || !parameter2)
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                             replace:NO];
    else if (!nbRows || !nbCols || (parameter3 && !fillValue))
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                             replace:NO];
    else//if arguments ok
    {
      CHChalkValueMatrix* matrix = [[CHChalkValueMatrix alloc] initWithToken:token rowsCount:nbRows colsCount:nbCols value:fillValue context:context];
      if (!matrix)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      result = matrix;
    }//end if arguments ok
    result.evaluationComputeFlags |=
      fillValue.evaluationComputeFlags |
      chalkGmpFlagsMake();
  }//end @autoreleasepool
  return [result autorelease];
}
//end combineMatrix:token:context:

+(CHChalkValue*) combineIdentity:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  id parameter1 = (operands.count < 1) ? nil : [operands objectAtIndex:0];
  CHChalkValueNumberGmp* dimensionGmp = [parameter1 dynamicCastToClass:[CHChalkValueNumberGmp class]];
  const chalk_gmp_value_t* dimensionGmpValue = dimensionGmp.valueConstReference;
  NSUInteger dimension = !dimensionGmpValue || (dimensionGmpValue->type != CHALK_VALUE_TYPE_INTEGER) || (chalkGmpValueSign(dimensionGmpValue)<0) ? 0 :
    mpz_get_nsui(dimensionGmpValue->integer);
  if (!parameter1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else if (!dimension)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                           replace:NO];
  /*else if (dimension == 1)//do not simplify the matrix as a number, to keep nature of objects
  {
    CHChalkValueNumberGmp* value =
      [[[CHChalkValueNumberGmp alloc] initWithToken:token uinteger:1 naturalBase:dimensionGmp.naturalBase context:context] autorelease];
    if (value)
      [result addObject:value];
    else
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                             replace:NO];
  }//end if (dimension == 1)*/
  else//if (dimension > 1)
  {
    @autoreleasepool {
      CHChalkValueMatrix* matrix = [CHChalkValueMatrix identity:dimension context:context];
      if (!matrix)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      else
        result = [matrix retain];
    }//end @autoreleasepool
    [result autorelease];
    result.evaluationComputeFlags |=
      chalkGmpFlagsMake();
  }//end if arguments ok
  return result;
}
//end combineIdentity:token:context:

+(CHChalkValue*) combineTranspose:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    @autoreleasepool {
      CHChalkValue* operandValue = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueScalar* operandScalar = [operandValue dynamicCastToClass:[CHChalkValueScalar class]];
      CHChalkValueMatrix* operandMatrix = [operandValue dynamicCastToClass:[CHChalkValueMatrix class]];
      CHChalkValueList* operandList = [operandValue dynamicCastToClass:[CHChalkValueList class]];
      if (operandList)
        result = [[self combineSEL:_cmd arguments:operands list:operandList index:0 token:token context:context] retain];
      else if (operandScalar)
        result = [operandScalar copy];
      else if (operandMatrix)
        result = [[operandMatrix transposedWithContext:context] retain];
      else
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                               replace:NO];
      //[result.token unionWithToken:token];//experimental
    }//end @autoreleasepool
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineTranspose:token:context:

+(CHChalkValue*) combineTrace:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    @autoreleasepool {
      CHChalkValue* operandValue = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueScalar* operandScalar = [operandValue dynamicCastToClass:[CHChalkValueScalar class]];
      CHChalkValueMatrix* operandMatrix = [operandValue dynamicCastToClass:[CHChalkValueMatrix class]];
      CHChalkValueList* operandList = [operandValue dynamicCastToClass:[CHChalkValueList class]];
      if (operandList)
        result = [[self combineSEL:_cmd arguments:operands list:operandList index:0 token:token context:context] retain];
      else if (operandScalar)
        result = [operandScalar copy];
      else if (operandMatrix)
      {
        if (operandMatrix.rowsCount != operandMatrix.colsCount)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorDimensionsMismatch range:token.range]
                                 replace:NO];
        else
          result = [[operandMatrix traceWithContext:context] retain];
      }//end if (operandMatrix)
      else
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                               replace:NO];
      //[result.token unionWithToken:token];//experimental
    }//end @autoreleasepool
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineTrace:token:context:

+(CHChalkValue*) combineDet:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    @autoreleasepool {
      CHChalkValue* operandValue = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueScalar* operandScalar = [operandValue dynamicCastToClass:[CHChalkValueScalar class]];
      CHChalkValueMatrix* operandMatrix = [operandValue dynamicCastToClass:[CHChalkValueMatrix class]];
      CHChalkValueList* operandList = [operandValue dynamicCastToClass:[CHChalkValueList class]];
      if (operandList)
        result = [[self combineSEL:_cmd arguments:operands list:operandList index:0 token:token context:context] retain];
      else if (operandScalar)
        result = [operandScalar copy];
      else if (operandMatrix)
        result = [[operandMatrix determinantWithContext:context] retain];
      else
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                               replace:NO];
      //[result.token unionWithToken:token];//experimental
    }//end @autoreleasepool
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineDet:token:context:

+(CHChalkValue*) combineIsPrime:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if ((operands.count != 1) && (operands.count != 2))
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if ((operands.count == 1) || (operands.count == 2))
  {
    @autoreleasepool {
      CHChalkValue* operand1Value = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueNumberGmp* operand1Number = [operand1Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueList* operand1List = [operand1Value dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValue* operand2Value = (operands.count<2) ? nil : [[operands objectAtIndex:1] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueNumberGmp* operand2Number = [operand2Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueList* operand2List = [operand2Value dynamicCastToClass:[CHChalkValueList class]];
      if (operand1List)
        result = [[self combineSEL:_cmd arguments:operands list:operand1List index:0 token:token context:context] retain];
      else if (operand2List)
        result = [[self combineSEL:_cmd arguments:operands list:operand2List index:1 token:token context:context] retain];
      else if (operand1Number)
      {
        if (operand1Number.valueType != CHALK_VALUE_TYPE_INTEGER)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                                 replace:NO];
        else if (operand2Number && (operand2Number.valueType != CHALK_VALUE_TYPE_INTEGER))
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                                 replace:NO];
        else//if (operandNumber.valueType == CHALK_VALUE_TYPE_INTEGER)
        {
          const chalk_gmp_value_t* operand2NumberGmp = operand2Number.valueConstReference;
          BOOL algorithmError = operand2NumberGmp && !mpz_fits_nsui_p(operand2NumberGmp->integer);
          prime_algorithm_flag_t algorithm = !operand2NumberGmp || algorithmError ? PRIMES_ALGORITHM_DEFAULT :
            convertToPrimeAlgorithmFlag(mpz_get_nsui(operand2NumberGmp->integer), &algorithmError);
          if (algorithmError)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                                   replace:NO];
          else//if (!algorithmError)
          {
            chalk_bool_t probaBool = [[CHPrimesManager sharedManager] isPrime:operand1Number.valueConstReference->integer withAlgorithms:algorithm context:context];
            result = [[CHChalkValueBoolean alloc] initWithToken:token chalkBoolValue:probaBool context:context];
            if (!result)
              [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                     replace:NO];
          }//end if (!algorithmError)
        }//end if (operandNumber.valueType == CHALK_VALUE_TYPE_INTEGER)
      }//end if (operandNumber)
      result.evaluationComputeFlags |=
        operand1Value.evaluationComputeFlags |
        chalkGmpFlagsMake();
    }//end @autoreleasepool
  }//end if ((operands.count == 1) || (operands.count == 2))
  return [result autorelease];
}
//end combineIsPrime:token:context:

+(CHChalkValue*) combineNextPrime:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if ((operands.count != 1) && (operands.count != 2))
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if ((operands.count == 1) || (operands.count == 2))
  {
    @autoreleasepool {
      CHChalkValue* operand1Value = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueNumberGmp* operand1Number = [operand1Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueList* operand1List = [operand1Value dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValue* operand2Value = (operands.count<2) ? nil : [[operands objectAtIndex:1] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueNumberGmp* operand2Number = [operand2Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueList* operand2List = [operand2Value dynamicCastToClass:[CHChalkValueList class]];
      if (operand1List)
        result = [[self combineSEL:_cmd arguments:operands list:operand1List index:0 token:token context:context] retain];
      else if (operand2List)
        result = [[self combineSEL:_cmd arguments:operands list:operand2List index:1 token:token context:context] retain];
      else if (operand1Number)
      {
        if (operand1Number.valueType != CHALK_VALUE_TYPE_INTEGER)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                                 replace:NO];
        else if (operand2Number && (operand2Number.valueType != CHALK_VALUE_TYPE_INTEGER))
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                                 replace:NO];
        else//if (operandNumber.valueType == CHALK_VALUE_TYPE_INTEGER)
        {
          const chalk_gmp_value_t* operand2NumberGmp = operand2Number.valueConstReference;
          BOOL algorithmError = operand2NumberGmp && !mpz_fits_nsui_p(operand2NumberGmp->integer);
          prime_algorithm_flag_t algorithm = !operand2NumberGmp || algorithmError ? PRIMES_ALGORITHM_DEFAULT :
            convertToPrimeAlgorithmFlag(mpz_get_nsui(operand2NumberGmp->integer), &algorithmError);
          if (algorithmError)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                                   replace:NO];
          else//if (!algorithmError)
          {
            chalk_gmp_value_t value = {0};
            chalkGmpValueMakeInteger(&value, context.gmpPool);
            chalk_bool_t confidence = [[CHPrimesManager sharedManager] nextPrime:value.integer op:operand1Number.valueConstReference->integer withAlgorithms:algorithm context:context];
            if (confidence != CHALK_BOOL_YES)
              mpfr_set_inexflag();
            result = [[CHChalkValueNumberGmp alloc] initWithToken:token value:&value naturalBase:operand1Number.naturalBase context:context];
            if (!result)
              [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                     replace:NO];
            chalkGmpValueClear(&value, YES, context.gmpPool);
          }//end if (!algorithmError)
        }//end if (operandNumber.valueType == CHALK_VALUE_TYPE_INTEGER)
      }//end if (operandNumber)
      result.evaluationComputeFlags |=
        operand1Value.evaluationComputeFlags |
        chalkGmpFlagsMake();
    }//end @autoreleasepool
  }//end if ((operands.count == 1) || (operands.count == 2))
  return [result autorelease];
}
//end combineNextPrime:token:context:

+(CHChalkValue*) combineNthPrime:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if ((operands.count != 1) && (operands.count != 2))
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if ((operands.count == 1) || (operands.count == 2))
  {
    @autoreleasepool {
      CHChalkValue* operand1Value = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueNumberGmp* operand1Number = [operand1Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueList* operand1List = [operand1Value dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValue* operand2Value = (operands.count<2) ? nil : [[operands objectAtIndex:1] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueNumberGmp* operand2Number = [operand2Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueList* operand2List = [operand2Value dynamicCastToClass:[CHChalkValueList class]];
      if (operand1List)
        result = [[self combineSEL:_cmd arguments:operands list:operand1List index:0 token:token context:context] retain];
      else if (operand2List)
        result = [[self combineSEL:_cmd arguments:operands list:operand2List index:1 token:token context:context] retain];
      else if (operand1Number)
      {
        if (operand1Number.valueType != CHALK_VALUE_TYPE_INTEGER)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                                 replace:NO];
        else if (operand2Number && (operand2Number.valueType != CHALK_VALUE_TYPE_INTEGER))
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                                 replace:NO];
        else//if (operandNumber.valueType == CHALK_VALUE_TYPE_INTEGER)
        {
          const chalk_gmp_value_t* operand2NumberGmp = operand2Number.valueConstReference;
          BOOL algorithmError = operand2NumberGmp && !mpz_fits_nsui_p(operand2NumberGmp->integer);
          prime_algorithm_flag_t algorithm = !operand2NumberGmp || algorithmError ? PRIMES_ALGORITHM_DEFAULT :
            convertToPrimeAlgorithmFlag(mpz_get_nsui(operand2NumberGmp->integer), &algorithmError);
          if (algorithmError)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                                   replace:NO];
          else//if (!algorithmError)
          {
            chalk_gmp_value_t value = {0};
            chalkGmpValueMakeInteger(&value, context.gmpPool);
            chalk_bool_t confidence = [[CHPrimesManager sharedManager] nthPrime:value.integer op:operand1Number.valueConstReference->integer withAlgorithms:algorithm context:context];
            if (confidence != CHALK_BOOL_YES)
              mpfr_set_inexflag();
            result = [[CHChalkValueNumberGmp alloc] initWithToken:token value:&value naturalBase:operand1Number.naturalBase context:context];
            if (!result)
              [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                     replace:NO];
            chalkGmpValueClear(&value, YES, context.gmpPool);
          }//end if (!algorithmError)
        }//end if (operandNumber.valueType == CHALK_VALUE_TYPE_INTEGER)
      }//end if (operandNumber)
      result.evaluationComputeFlags |=
        operand1Value.evaluationComputeFlags |
        chalkGmpFlagsMake();
    }//end @autoreleasepool
  }//end if ((operands.count == 1) || (operands.count == 2))
  return [result autorelease];
}
//end combineNthPrime:token:context:

+(CHChalkValue*) combinePrimes:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if ((operands.count != 1) && (operands.count != 2))
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if ((operands.count == 1) || (operands.count == 2))
  {
    @autoreleasepool {
      CHChalkValue* operand1Value = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueNumberGmp* operand1Number = [operand1Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueList* operand1List = [operand1Value dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValue* operand2Value = (operands.count<2) ? nil : [[operands objectAtIndex:1] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueNumberGmp* operand2Number = [operand2Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueList* operand2List = [operand2Value dynamicCastToClass:[CHChalkValueList class]];
      if (operand1List)
        result = [[self combineSEL:_cmd arguments:operands list:operand1List index:0 token:token context:context] retain];
      else if (operand2List)
        result = [[self combineSEL:_cmd arguments:operands list:operand2List index:1 token:token context:context] retain];
      else if (operand1Number)
      {
        if (operand1Number.valueType != CHALK_VALUE_TYPE_INTEGER)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                                 replace:NO];
        else if (operand2Number && (operand2Number.valueType != CHALK_VALUE_TYPE_INTEGER))
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                                 replace:NO];
        else//if (operandNumber.valueType == CHALK_VALUE_TYPE_INTEGER)
        {
          const chalk_gmp_value_t* operand2NumberGmp = operand2Number.valueConstReference;
          BOOL algorithmError = operand2NumberGmp && !mpz_fits_nsui_p(operand2NumberGmp->integer);
          prime_algorithm_flag_t algorithm = !operand2NumberGmp || algorithmError ? PRIMES_ALGORITHM_DEFAULT :
            convertToPrimeAlgorithmFlag(mpz_get_nsui(operand2NumberGmp->integer), &algorithmError);
          if (algorithmError)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                                   replace:NO];
          else//if (!algorithmError)
          {
            NSMutableArray* valuesAndPowers = [[NSMutableArray alloc] init];
            const chalk_gmp_value_t* operand1ValueGmpValue = operand1Number.valueConstReference;
            int sgn = mpz_sgn(operand1ValueGmpValue->integer);
            BOOL isZero = !sgn;
            BOOL isOneIgnoringSign = NO;
            BOOL isOne = chalkGmpValueIsOne(operand1ValueGmpValue, &isOneIgnoringSign, 0);
            if (!isZero && !isOne && !isOneIgnoringSign)
            {
              mpz_t remainingValue;
              mpz_t q;
              mpz_t r;
              mpz_t maxTestValue;
              mpz_t nextPrimes[2];
              mpz_t currentPrimePower;
              mpzDepool(remainingValue, context.gmpPool);
              mpz_set(remainingValue, operand1ValueGmpValue->integer);
              mpzDepool(q, context.gmpPool);
              mpzDepool(r, context.gmpPool);
              mpzDepool(nextPrimes[0], context.gmpPool);
              mpzDepool(nextPrimes[1], context.gmpPool);
              mpzDepool(currentPrimePower, context.gmpPool);
              mpz_set_ui(nextPrimes[0], 2);
              mpz_set_ui(nextPrimes[1], 3);
              mpz_set_ui(currentPrimePower, 0);
              
              if (mpz_sgn(remainingValue) < 0)
                mpz_abs(remainingValue, remainingValue);
              mpzDepool(maxTestValue, context.gmpPool);
              mpz_sqrt(maxTestValue, remainingValue);
              
              CHPrimesManager* primesManager = [CHPrimesManager sharedManager];
              unsigned int currentPrimeIndex = 0;
              dispatch_semaphore_t nextPrimeSemaphore = dispatch_semaphore_create(0);//simulates that async nextPrime as already run
              dispatch_semaphore_signal(nextPrimeSemaphore);
              __block chalk_bool_t nextConfidence = CHALK_BOOL_YES;
              dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
              BOOL stop = NO;
              while(!stop)
              {
                mpz_tdiv_qr(q,r,remainingValue,nextPrimes[currentPrimeIndex]);
                if (mpz_sgn(r) == 0)//divexact
                //if (mpz_divisible_p(remainingValue, currentPrime))
                {
                  mpz_add_ui(currentPrimePower, currentPrimePower, 1);
                  //mpz_divexact(remainingValue, remainingValue, currentPrime);
                  mpz_set(remainingValue,q);
                }//end if (mpz_divisible_p(remainingValue, currentPrime))
                else//if (!mpz_divisible_p(remainingValue, currentPrime))
                {
                  BOOL shouldStop = !mpz_cmp_ui(nextPrimes[currentPrimeIndex], 1);
                  if (shouldStop || (mpz_sgn(currentPrimePower) > 0))
                  {
                    chalk_gmp_value_t prime = {0};
                    if (!chalkGmpValueMakeInteger(&prime, context.gmpPool))
                    {
                      stop  = YES;
                      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                             replace:NO];
                    }//end if (!chalkGmpValueMakeInteger(&prime))
                    else if (!mpz_fits_nsui_p(currentPrimePower))
                    {
                      stop  = YES;
                      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorIntegerOverflow range:token.range]
                                             replace:NO];
                    }//end if (!mpz_fits_nsui_p(currentPrimePower))
                    else//if (...)
                    {
                      mpz_set(prime.integer, nextPrimes[currentPrimeIndex]);
                      NSUInteger power = mpz_get_nsui(currentPrimePower);
                      CHChalkValueNumberGmp* value = [[CHChalkValueNumberGmp alloc] initWithToken:token value:&prime naturalBase:operand1Number.naturalBase context:context];
                      if (!value)
                      {
                        stop  = YES;
                        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                               replace:NO];
                      }//end if (!value)
                      else
                        [valuesAndPowers addObject:@[value, @(power)]];
                      [value release];
                    }//end if (...)
                    chalkGmpValueClear(&prime, YES, context.gmpPool);
                    mpz_set_ui(currentPrimePower, 0);
                  }//end if (shouldStop || mpz_sgn(currentPrimePower) > 0)
                  stop |= shouldStop;
                  if (!stop)
                  {
                    dispatch_semaphore_wait(nextPrimeSemaphore, DISPATCH_TIME_FOREVER);
                    currentPrimeIndex = (currentPrimeIndex+1)%2;
                    chalk_bool_t confidence = nextConfidence;
                    stop |= (mpz_cmp(nextPrimes[currentPrimeIndex], maxTestValue)>0);
                    if (stop)
                      dispatch_semaphore_signal(nextPrimeSemaphore);
                    if ((confidence == CHALK_BOOL_UNLIKELY) || (confidence == CHALK_BOOL_MAYBE) || (confidence == CHALK_BOOL_CERTAINLY))
                      mpfr_set_inexflag();
                    if (!stop)
                    {
                      __block mpz_srcptr currentPrimePtr = nextPrimes[currentPrimeIndex];
                      __block mpz_ptr nextPrimePtr = nextPrimes[(currentPrimeIndex+1)%2];
                      dispatch_async_gmp(queue, ^{
                        nextConfidence = [primesManager nextPrime:nextPrimePtr op:currentPrimePtr withAlgorithms:algorithm context:context];
                        dispatch_semaphore_signal(nextPrimeSemaphore);
                      });
                    }//end if (!stop)
                  }//end if (!stop)
                }//end if (!mpz_divisible_p(remainingValue, currentPrime))
                stop |= context.errorContext.hasError;
              }//end while(!stop)
              dispatch_semaphore_wait(nextPrimeSemaphore, DISPATCH_TIME_FOREVER);
              dispatch_release(nextPrimeSemaphore);
              nextPrimeSemaphore = 0;
              
              if (mpz_cmp_ui(remainingValue, 1)>0)
              {
                chalk_gmp_value_t prime = {0};
                if (!chalkGmpValueMakeInteger(&prime, context.gmpPool))
                {
                  stop  = YES;
                  [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                         replace:NO];
                }//end if (!chalkGmpValueMakeInteger(&prime))
                else//if (chalkGmpValueMakeInteger(&prime))
                {
                  mpz_set(prime.integer, remainingValue);
                  CHChalkValueNumberGmp* value = [[CHChalkValueNumberGmp alloc] initWithToken:token value:&prime naturalBase:operand1Number.naturalBase context:context];
                  if (!value)
                  {
                    stop  = YES;
                    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                           replace:NO];
                  }//end if (!value)
                  else
                    [valuesAndPowers addObject:@[value, @(1)]];
                  [value release];
                }//end if (chalkGmpValueMakeInteger(&prime))
              }//end if (mpz_cmp_ui(remainingValue, 1)>0)
              mpzRepool(remainingValue, context.gmpPool);
              mpzRepool(nextPrimes[0], context.gmpPool);
              mpzRepool(nextPrimes[1], context.gmpPool);
              mpzRepool(currentPrimePower, context.gmpPool);
              mpzRepool(maxTestValue, context.gmpPool);
              mpzRepool(q, context.gmpPool);
              mpzRepool(r, context.gmpPool);
            }//end if (!isZero && !isOne && !isOneIgnoringSign)
            
            NSMutableArray* valuesAndPowersAsListValues = [[NSMutableArray alloc] init];
            if (!valuesAndPowersAsListValues)
              [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                     replace:NO];
            else//if (valuesAndPowersAsListValues)
            {
              if (isZero)
              {
                CHChalkValueNumberGmp* value = [[[CHChalkValueNumberGmp alloc] initWithToken:[CHChalkToken chalkTokenEmpty] uinteger:0 naturalBase:operand1Value.naturalBase context:context] autorelease];
                CHChalkValueNumberGmp* power = [[[CHChalkValueNumberGmp alloc] initWithToken:[CHChalkToken chalkTokenEmpty] uinteger:1 naturalBase:operand1Value.naturalBase context:context] autorelease];
                CHChalkValueList* valueAndPowerList = !value || !power ? nil :
                  [[CHChalkValueList alloc] initWithToken:token values:@[value,power] context:context];
                if (!valueAndPowerList)
                  [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                         replace:NO];
                else
                  [valuesAndPowersAsListValues addObject:valueAndPowerList];
                [valueAndPowerList release];
              }//end if (isZero)
              else if (isOne || isOneIgnoringSign)
              {
                CHChalkValueNumberGmp* value = [[[CHChalkValueNumberGmp alloc] initWithToken:[CHChalkToken chalkTokenEmpty] integer:isOneIgnoringSign ? -1 : 1 naturalBase:operand1Value.naturalBase context:context] autorelease];
                CHChalkValueNumberGmp* power = [[[CHChalkValueNumberGmp alloc] initWithToken:[CHChalkToken chalkTokenEmpty] integer:1 naturalBase:operand1Value.naturalBase context:context] autorelease];
                CHChalkValueList* valueAndPowerList = !value || !power ? nil :
                  [[CHChalkValueList alloc] initWithToken:token values:@[value,power] context:context];
                if (!valueAndPowerList)
                  [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                         replace:NO];
                else
                  [valuesAndPowersAsListValues addObject:valueAndPowerList];
                [valueAndPowerList release];
              }//end if (isOne || isOneIgnoringSign)
              else if (sgn<0)
              {
                CHChalkValueNumberGmp* value = [[[CHChalkValueNumberGmp alloc] initWithToken:[CHChalkToken chalkTokenEmpty] integer:-1 naturalBase:operand1Value.naturalBase context:context] autorelease];
                CHChalkValueNumberGmp* power = [[[CHChalkValueNumberGmp alloc] initWithToken:[CHChalkToken chalkTokenEmpty] integer:1 naturalBase:operand1Value.naturalBase context:context] autorelease];
                CHChalkValueList* valueAndPowerList = !value || !power ? nil :
                  [[CHChalkValueList alloc] initWithToken:token values:@[value,power] context:context];
                if (!valueAndPowerList)
                  [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                         replace:NO];
                else
                  [valuesAndPowersAsListValues addObject:valueAndPowerList];
                [valueAndPowerList release];
              }//end if (sgn<0)
              [valuesAndPowers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSArray* valueAndPower = [obj dynamicCastToClass:[NSArray class]];
                id value = (valueAndPower.count < 1) ? nil : [valueAndPower objectAtIndex:0];
                id power = (valueAndPower.count < 2) ? nil : [valueAndPower objectAtIndex:1];
                NSNumber* valueNumber = [value dynamicCastToClass:[NSNumber class]];
                CHChalkValueNumber* valueChalkNumber = [value dynamicCastToClass:[CHChalkValueNumber class]];
                NSNumber* powerNumber = [power dynamicCastToClass:[NSNumber class]];
                CHChalkValueNumber* powerChalkNumber = [power dynamicCastToClass:[CHChalkValueNumber class]];
                if (valueNumber && !valueChalkNumber)
                {
                  valueChalkNumber = [[[CHChalkValueNumberGmp alloc] initWithToken:token uinteger:valueNumber.unsignedIntegerValue naturalBase:operand1Number.naturalBase context:context] autorelease];
                  if (!valueChalkNumber)
                  {
                    *stop = YES;
                    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                           replace:NO];
                  }//end if (!valueChalkNumber)
                }//end if (valueNumber && !valueChalkNumber)
                if (powerNumber && !powerChalkNumber)
                {
                  powerChalkNumber = [[[CHChalkValueNumberGmp alloc] initWithToken:token uinteger:powerNumber.unsignedIntegerValue naturalBase:operand1Number.naturalBase context:context] autorelease];
                  if (!powerChalkNumber)
                  {
                    *stop = YES;
                    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                           replace:NO];
                  }//end if (!powerChalkNumber)
                }//end if (powerNumber && !powerChalkNumber)
                if (!valueChalkNumber || !powerChalkNumber)
                {
                  *stop = YES;
                  [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                         replace:NO];
                }//end if (!valueChalkNumber || !powerChalkNumber)
                else//if (valueChalkNumber && powerChalkNumber)
                {
                  CHChalkValueList* valueAndPowerList = [[CHChalkValueList alloc] initWithToken:token values:@[valueChalkNumber,powerChalkNumber] context:context];
                  if (!valueAndPowerList)
                  {
                    *stop = YES;
                    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                           replace:NO];
                  }//end if (!valueAndPowerList)
                  else
                    [valuesAndPowersAsListValues addObject:valueAndPowerList];
                  valueAndPowerList.evaluationComputeFlags |=
                    valueChalkNumber.evaluationComputeFlags |
                    powerChalkNumber.evaluationComputeFlags;
                  [valueAndPowerList release];
                }//end if (valueChalkNumber && powerChalkNumber)
              }];//end for each valuesAndPowers
              result = [[CHChalkValueList alloc] initWithToken:token values:valuesAndPowersAsListValues context:context];
              if (!result)
                [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                       replace:NO];
              [valuesAndPowersAsListValues enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                result.evaluationComputeFlags |=
                  ((CHChalkValue*)[obj dynamicCastToClass:[CHChalkValue class]]).evaluationComputeFlags |
                  chalkGmpFlagsMake();
              }];
            }//end if (valuesAndPowersAsListValues)
            [valuesAndPowersAsListValues release];
            [valuesAndPowers release];
          }//end if (!algorithmError)
        }//end if (operandNumber.valueType == CHALK_VALUE_TYPE_INTEGER)
      }//end if (operandNumber)
      result.evaluationComputeFlags |=
        operand1Value.evaluationComputeFlags |
        chalkGmpFlagsMake();
    }//end @autoreleasepool
  }//end if ((operands.count == 1) || (operands.count == 2))
  return [result autorelease];
}
//end combinePrimes:token:context:

+(CHChalkValue*) combineGcd:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 2)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 2)
  {
    @autoreleasepool {
      CHChalkValue* operand1Value = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValue* operand2Value = [[operands objectAtIndex:1] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueNumberGmp* operand1Number = [operand1Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueNumberGmp* operand2Number = [operand2Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueList* operand1List = [operand1Value dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValueList* operand2List = [operand2Value dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValueMatrix* operand1Matrix = [operand1Value dynamicCastToClass:[CHChalkValueMatrix class]];
      if (operand1List)
        result = [[self combineSEL:_cmd arguments:operands list:operand1List index:0 token:token context:context] retain];
      else if (operand2List)
        result = [[self combineSEL:_cmd arguments:operands list:operand2List index:1 token:token context:context] retain];
      else if (operand1Matrix)
      {
        CHChalkValueMatrix* newMatrix = [[self combineMatrixSEL:_cmd operand:operand1Matrix otherOperands:[operands subarrayWithRange:NSMakeRange(1, operands.count-1)] token:token context:context] retain];
        if (context.errorContext.hasError)
        {
          [newMatrix release];
          newMatrix = nil;
        }//end if (context.errorContext.hasError)
        result = newMatrix;
      }//end if (operand1Matrix)
      else if ((operand1Number.valueType != CHALK_VALUE_TYPE_INTEGER) || (operand2Number.valueType != CHALK_VALUE_TYPE_INTEGER))
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                               replace:NO];
      else//if ((operand1Number.valueType == CHALK_VALUE_TYPE_INTEGER) && (operand2Number.valueType == CHALK_VALUE_TYPE_INTEGER))
      {
        chalk_gmp_value_t currentValue = {0};
        if (chalkGmpValueMakeInteger(&currentValue, context.gmpPool))
          mpz_gcd(currentValue.integer, operand1Number.valueConstReference->integer, operand2Number.valueConstReference->integer);
        result = [[CHChalkValueNumberGmp alloc] initWithToken:token value:&currentValue naturalBase:operand1Number.naturalBase context:context];
        if (!result)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                 replace:NO];
        chalkGmpValueClear(&currentValue, YES, context.gmpPool);
      }//end if ((operand1Number.valueType == CHALK_VALUE_TYPE_INTEGER) && (operand2Number.valueType == CHALK_VALUE_TYPE_INTEGER))
      result.evaluationComputeFlags |=
        operand1Value.evaluationComputeFlags |
        operand2Value.evaluationComputeFlags |
        chalkGmpFlagsMake();
    }//end @autoreleasepool
  }//end if (operands.count == 2)
  return [result autorelease];
}
//end combineGcd:token:context:

+(CHChalkValue*) combineLcm:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 2)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 2)
  {
    @autoreleasepool {
      CHChalkValue* operand1Value = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValue* operand2Value = [[operands objectAtIndex:1] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueNumberGmp* operand1Number = [operand1Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueNumberGmp* operand2Number = [operand2Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueList* operand1List = [operand1Value dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValueList* operand2List = [operand2Value dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValueMatrix* operand1Matrix = [operand1Value dynamicCastToClass:[CHChalkValueMatrix class]];
      if (operand1List)
        result = [[self combineSEL:_cmd arguments:operands list:operand1List index:0 token:token context:context] retain];
      else if (operand2List)
        result = [[self combineSEL:_cmd arguments:operands list:operand2List index:1 token:token context:context] retain];
      else if (operand1Matrix)
      {
        CHChalkValueMatrix* newMatrix = [[self combineMatrixSEL:_cmd operand:operand1Matrix otherOperands:[operands subarrayWithRange:NSMakeRange(1, operands.count-1)] token:token context:context] retain];
        if (context.errorContext.hasError)
        {
          [newMatrix release];
          newMatrix = nil;
        }//end if (context.errorContext.hasError)
        result = newMatrix;
      }//end if (operand1Matrix)
      else if ((operand1Number.valueType != CHALK_VALUE_TYPE_INTEGER) || (operand2Number.valueType != CHALK_VALUE_TYPE_INTEGER))
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                               replace:NO];
      else//if ((operand1Number.valueType == CHALK_VALUE_TYPE_INTEGER) && (operand2Number.valueType == CHALK_VALUE_TYPE_INTEGER))
      {
        chalk_gmp_value_t currentValue = {0};
        if (chalkGmpValueMakeInteger(&currentValue, context.gmpPool))
          mpz_lcm(currentValue.integer, operand1Number.valueConstReference->integer, operand2Number.valueConstReference->integer);
        result = [[CHChalkValueNumberGmp alloc] initWithToken:token value:&currentValue naturalBase:operand1Number.naturalBase context:context];
        if (!result)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                 replace:NO];
        chalkGmpValueClear(&currentValue, YES, context.gmpPool);
      }//end if ((operand1Number.valueType == CHALK_VALUE_TYPE_INTEGER) && (operand2Number.valueType == CHALK_VALUE_TYPE_INTEGER))
      result.evaluationComputeFlags |=
        operand1Value.evaluationComputeFlags |
        operand2Value.evaluationComputeFlags |
        chalkGmpFlagsMake();
    }//end @autoreleasepool
  }//end if (operands.count == 2)
  return [result autorelease];
}
//end combineLcm:token:context:

+(CHChalkValue*) combineMod:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 2)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 2)
  {
    @autoreleasepool {
      CHChalkValue* operand1Value = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValue* operand2Value = [[operands objectAtIndex:1] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueNumberGmp* operand1Number = [operand1Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueNumberGmp* operand2Number = [operand2Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueList* operand1List = [operand1Value dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValueList* operand2List = [operand2Value dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValueMatrix* operand1Matrix = [operand1Value dynamicCastToClass:[CHChalkValueMatrix class]];
      if (operand1List)
        result = [[self combineSEL:_cmd arguments:operands list:operand1List index:0 token:token context:context] retain];
      else if (operand2List)
        result = [[self combineSEL:_cmd arguments:operands list:operand2List index:1 token:token context:context] retain];
      else if (operand1Matrix)
      {
        CHChalkValueMatrix* newMatrix = [[self combineMatrixSEL:_cmd operand:operand1Matrix otherOperands:[operands subarrayWithRange:NSMakeRange(1, operands.count-1)] token:token context:context] retain];
        if (context.errorContext.hasError)
        {
          [newMatrix release];
          newMatrix = nil;
        }//end if (context.errorContext.hasError)
        result = newMatrix;
      }//end if (operand1Matrix)
      else if (operand2Value.isZero)
      {
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericDivideByZero range:token.range]
                               replace:NO];
      }//end if (operand2Value.isZero)
      else if (operand1Number && operand2Number)
      {
        BOOL done = NO;
        chalk_gmp_value_t currentValue = {0};
        const chalk_gmp_value_t* gmpValue1 = operand1Number.valueConstReference;
        const chalk_gmp_value_t* gmpValue2 = operand2Number.valueConstReference;
        if (!gmpValue1 || !gmpValue2)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                 replace:NO];
        else if (gmpValue1->type == CHALK_VALUE_TYPE_INTEGER)
        {
          if (gmpValue2->type == CHALK_VALUE_TYPE_INTEGER)
          {
            if (chalkGmpValueMakeInteger(&currentValue, context.gmpPool))
            {
              mpz_mod(currentValue.integer, gmpValue1->integer, gmpValue2->integer);
              done = YES;
            }//end if (chalkGmpValueMakeInteger(&currentValue, context.gmpPool))
          }//end if (gmpValue2->type == CHALK_VALUE_TYPE_INTEGER)
          else if (gmpValue2->type == CHALK_VALUE_TYPE_FRACTION)
          {
            if (chalkGmpValueMakeFraction(&currentValue, context.gmpPool))
            {
              mpz_t d2n1;
              mpz_t rd2;
              mpzDepool(d2n1, context.gmpPool);
              mpzDepool(rd2, context.gmpPool);
              mpz_mul(d2n1, mpq_denref(gmpValue2->fraction), gmpValue1->integer);
              mpz_mod(rd2, d2n1, mpq_numref(gmpValue2->fraction));
              mpq_set_num(currentValue.fraction, rd2);
              mpq_set_den(currentValue.fraction, mpq_denref(gmpValue2->fraction));
              mpq_canonicalize(currentValue.fraction);
              mpzRepool(d2n1, context.gmpPool);
              mpzRepool(rd2, context.gmpPool);
              done = YES;
            }//end if (chalkGmpValueMakeFraction(&currentValue, context.gmpPool))
          }//end if (gmpValue2->type == CHALK_VALUE_TYPE_FRACTION)
          else if (gmpValue2->type == CHALK_VALUE_TYPE_REAL_EXACT)
          {
            if (chalkGmpValueMakeRealApprox(&currentValue, context.computationConfiguration.softFloatSignificandBits, context.gmpPool))
            {
              mpfir_set_z(currentValue.realApprox, gmpValue1->integer);
              if (mpfr_sgn(&currentValue.realApprox->interval.left)>=0)
              {
                mpfr_fmod(&currentValue.realApprox->interval.left, &currentValue.realApprox->interval.left, gmpValue2->realExact, MPFR_RNDD);
                mpfr_fmod(&currentValue.realApprox->interval.right, &currentValue.realApprox->interval.right, gmpValue2->realExact, MPFR_RNDU);
                mpfir_estimation_update(currentValue.realApprox);
                done = YES;
              }//end if (mpfr_sgn(&currentValue.realApprox->interval.left)>=0)
              else if (mpfr_sgn(&currentValue.realApprox->interval.right)<=0)
              {
                mpfr_fmod(&currentValue.realApprox->interval.left, &currentValue.realApprox->interval.left, gmpValue2->realExact, MPFR_RNDD);
                mpfr_fmod(&currentValue.realApprox->interval.right, &currentValue.realApprox->interval.right, gmpValue2->realExact, MPFR_RNDU);
                mpfir_add_fr(currentValue.realApprox, currentValue.realApprox, gmpValue2->realExact);
                mpfir_estimation_update(currentValue.realApprox);
                done = YES;
              }//end if (mpfr_sgn(&currentValue.realApprox->interval.right)<=0)
            }//end if (chalkGmpValueMakeRealApprox(&currentValue, context.computationConfiguration.softFloatSignificandBits, context.gmpPool))
          }//end if (gmpValue2->type == CHALK_VALUE_TYPE_REAL_EXACT)
        }//end if (gmpValue1->type == CHALK_VALUE_TYPE_INTEGER)
        else if (gmpValue1->type == CHALK_VALUE_TYPE_FRACTION)
        {
          if (gmpValue2->type == CHALK_VALUE_TYPE_INTEGER)
          {
            if (chalkGmpValueMakeFraction(&currentValue, context.gmpPool))
            {
              mpz_t n2d1;
              mpz_t rd1;
              mpzDepool(n2d1, context.gmpPool);
              mpzDepool(rd1, context.gmpPool);
              mpz_mul(n2d1, gmpValue2->integer, mpq_denref(gmpValue1->fraction));
              mpz_mod(rd1, mpq_numref(gmpValue1->fraction), n2d1);
              mpq_set_num(currentValue.fraction, rd1);
              mpq_set_den(currentValue.fraction, mpq_denref(gmpValue1->fraction));
              mpq_canonicalize(currentValue.fraction);
              mpzRepool(n2d1, context.gmpPool);
              mpzRepool(rd1, context.gmpPool);
              done = YES;
            }//end if (chalkGmpValueMakeFraction(&currentValue, context.gmpPool))
          }//end if (gmpValue2->type == CHALK_VALUE_TYPE_INTEGER)
          else if (gmpValue2->type == CHALK_VALUE_TYPE_FRACTION)
          {
            if (chalkGmpValueMakeFraction(&currentValue, context.gmpPool))
            {
              mpz_t d2n1;
              mpz_t n2d1;
              mpz_t rd2d1;
              mpzDepool(d2n1, context.gmpPool);
              mpzDepool(n2d1, context.gmpPool);
              mpzDepool(rd2d1, context.gmpPool);
              mpz_mul(d2n1, mpq_denref(gmpValue2->fraction), mpq_numref(gmpValue1->fraction));
              mpz_mul(n2d1, mpq_numref(gmpValue2->fraction), mpq_denref(gmpValue1->fraction));
              mpz_mod(rd2d1, d2n1, n2d1);
              mpq_set_num(currentValue.fraction, rd2d1);
              mpz_mul(mpq_denref(currentValue.fraction), mpq_denref(gmpValue1->fraction), mpq_denref(gmpValue2->fraction));
              mpq_canonicalize(currentValue.fraction);
              mpzRepool(d2n1, context.gmpPool);
              mpzRepool(n2d1, context.gmpPool);
              mpzRepool(rd2d1, context.gmpPool);
              done = YES;
            }//end if (chalkGmpValueMakeFraction(&currentValue, context.gmpPool))
          }//end if (gmpValue2->type == CHALK_VALUE_TYPE_FRACTION)
          else if (gmpValue2->type == CHALK_VALUE_TYPE_REAL_EXACT)
          {
            if (chalkGmpValueMakeRealApprox(&currentValue, context.computationConfiguration.softFloatSignificandBits, context.gmpPool))
            {
              mpfir_set_q(currentValue.realApprox, gmpValue1->fraction);
              chalk_gmp_value_t tmpRealApprox = {0};
              chalkGmpValueSet(&tmpRealApprox, &currentValue, context.gmpPool);
              if (mpfr_sgn(&currentValue.realApprox->interval.left)>=0)
              {
                mpfr_fmod(&currentValue.realApprox->interval.left, &tmpRealApprox.realApprox->interval.left, gmpValue2->realExact, MPFR_RNDD);
                mpfr_fmod(&currentValue.realApprox->interval.right, &tmpRealApprox.realApprox->interval.right, gmpValue2->realExact, MPFR_RNDU);
                mpfir_estimation_update(currentValue.realApprox);
                done = YES;
              }//end if (mpfr_sgn(&currentValue.realApprox->interval.left)>=0)
              else if (mpfr_sgn(&currentValue.realApprox->interval.right)<=0)
              {
                mpfr_fmod(&currentValue.realApprox->interval.left, &tmpRealApprox.realApprox->interval.left, gmpValue2->realExact, MPFR_RNDD);
                mpfr_fmod(&currentValue.realApprox->interval.right, &tmpRealApprox.realApprox->interval.right, gmpValue2->realExact, MPFR_RNDU);
                mpfir_add_fr(currentValue.realApprox, currentValue.realApprox, gmpValue2->realExact);
                mpfir_estimation_update(currentValue.realApprox);
                done = YES;
              }//end if (mpfr_sgn(&currentValue.realApprox->interval.right)<=0)
              chalkGmpValueClear(&tmpRealApprox, YES, context.gmpPool);
            }//end if (chalkGmpValueMakeRealApprox(&currentValue, context.computationConfiguration.softFloatSignificandBits, context.gmpPool))
          }//end if (gmpValue2->type == CHALK_VALUE_TYPE_REAL_EXACT)
        }//end if (gmpValue1->type == CHALK_VALUE_TYPE_FRACTION)
        else if (gmpValue1->type == CHALK_VALUE_TYPE_REAL_EXACT)
        {
          chalk_gmp_value_t value2RealExact = {0};
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
          chalkGmpValueSet(&value2RealExact, gmpValue2, context.gmpPool);
          chalkGmpValueMakeReal(&value2RealExact, context.computationConfiguration.softFloatSignificandBits, context.gmpPool);
          chalkGmpFlagsRestore(oldFlags);
          if (value2RealExact.type == CHALK_VALUE_TYPE_REAL_EXACT)
          {
            if (chalkGmpValueMakeRealApprox(&currentValue, context.computationConfiguration.softFloatSignificandBits, context.gmpPool))
            {
              mpfir_set_fr(currentValue.realApprox, gmpValue1->realExact);
              chalk_gmp_value_t tmpRealApprox = {0};
              chalkGmpValueSet(&tmpRealApprox, &currentValue, context.gmpPool);
              if (mpfr_sgn(&currentValue.realApprox->interval.left)>=0)
              {
                mpfr_fmod(&currentValue.realApprox->interval.left, &tmpRealApprox.realApprox->interval.left, value2RealExact.realExact, MPFR_RNDD);
                mpfr_fmod(&currentValue.realApprox->interval.right, &tmpRealApprox.realApprox->interval.right, value2RealExact.realExact, MPFR_RNDU);
                mpfir_estimation_update(currentValue.realApprox);
                done = YES;
              }//end if (mpfr_sgn(&currentValue.realApprox->interval.left)>=0)
              else if (mpfr_sgn(&currentValue.realApprox->interval.right)<=0)
              {
                mpfr_fmod(&currentValue.realApprox->interval.left, &tmpRealApprox.realApprox->interval.left, value2RealExact.realExact, MPFR_RNDD);
                mpfr_fmod(&currentValue.realApprox->interval.right, &tmpRealApprox.realApprox->interval.right, value2RealExact.realExact, MPFR_RNDU);
                mpfir_add_fr(currentValue.realApprox, currentValue.realApprox, value2RealExact.realExact);
                mpfir_estimation_update(currentValue.realApprox);
                done = YES;
              }//end if (mpfr_sgn(&currentValue.realApprox->interval.right)<=0)
              chalkGmpValueClear(&tmpRealApprox, YES, context.gmpPool);
            }//end if (chalkGmpValueMakeRealApprox(&currentValue, context.computationConfiguration.softFloatSignificandBits, context.gmpPool))
          }//end if (value2RealExact.type == CHALK_VALUE_TYPE_REAL_EXACT)
          chalkGmpValueClear(&value2RealExact, YES, context.gmpPool);
        }//end if (gmpValue1->type == CHALK_VALUE_TYPE_REAL_EXACT)
        else if (gmpValue1->type == CHALK_VALUE_TYPE_REAL_APPROX)
        {
          chalk_gmp_value_t value2RealExact = {0};
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
          chalkGmpValueSet(&value2RealExact, gmpValue2, context.gmpPool);
          chalkGmpValueMakeReal(&value2RealExact, context.computationConfiguration.softFloatSignificandBits, context.gmpPool);
          chalkGmpFlagsRestore(oldFlags);
          if (value2RealExact.type == CHALK_VALUE_TYPE_REAL_EXACT)
          {
            if (chalkGmpValueMakeRealApprox(&currentValue, context.computationConfiguration.softFloatSignificandBits, context.gmpPool))
            {
              mpfir_set(currentValue.realApprox, gmpValue1->realApprox);
              chalk_gmp_value_t tmpRealApprox = {0};
              chalkGmpValueSet(&tmpRealApprox, &currentValue, context.gmpPool);
              if (mpfr_sgn(&currentValue.realApprox->interval.left)>=0)
              {
                mpfr_fmod(&currentValue.realApprox->interval.left, &tmpRealApprox.realApprox->interval.left, value2RealExact.realExact, MPFR_RNDD);
                mpfr_fmod(&currentValue.realApprox->interval.right, &tmpRealApprox.realApprox->interval.right, value2RealExact.realExact, MPFR_RNDU);
                mpfir_estimation_update(currentValue.realApprox);
                done = YES;
              }//end if (mpfr_sgn(&currentValue.realApprox->interval.left)>=0)
              else if (mpfr_sgn(&currentValue.realApprox->interval.right)<=0)
              {
                mpfr_fmod(&currentValue.realApprox->interval.left, &tmpRealApprox.realApprox->interval.left, value2RealExact.realExact, MPFR_RNDD);
                mpfr_fmod(&currentValue.realApprox->interval.right, &tmpRealApprox.realApprox->interval.right, value2RealExact.realExact, MPFR_RNDU);
                mpfir_add_fr(currentValue.realApprox, currentValue.realApprox, value2RealExact.realExact);
                mpfir_estimation_update(currentValue.realApprox);
                done = YES;
              }//end if (mpfr_sgn(&currentValue.realApprox->interval.right)<=0)
              chalkGmpValueClear(&tmpRealApprox, YES, context.gmpPool);
            }//end if (chalkGmpValueMakeRealApprox(&currentValue, context.computationConfiguration.softFloatSignificandBits, context.gmpPool))
          }//end if (value2RealExact.type == CHALK_VALUE_TYPE_REAL_EXACT)
          chalkGmpValueClear(&value2RealExact, YES, context.gmpPool);
        }//end if (gmpValue1->type == CHALK_VALUE_TYPE_REAL_APPROX)
        if (!done)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnimplemented range:token.range]
                                    replace:NO];
        else
          result = [[CHChalkValueNumberGmp alloc] initWithToken:token value:&currentValue naturalBase:operand1Number.naturalBase context:context];
        if (!result)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                 replace:NO];
        chalkGmpValueClear(&currentValue, YES, context.gmpPool);
      }//end if (operand1Number && operand2Number)
      else
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnimplemented range:token.range]
                               replace:NO];
      result.evaluationComputeFlags |=
        operand1Value.evaluationComputeFlags |
        operand2Value.evaluationComputeFlags |
        chalkGmpFlagsMake();
    }//end @autoreleasepool
  }//end if (operands.count == 2)
  return [result autorelease];
}
//end combineMod:token:context:

+(CHChalkValue*) combineBinomial:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 2)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 2)
  {
    @autoreleasepool {
      CHChalkValue* operand1Value = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValue* operand2Value = [[operands objectAtIndex:1] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueNumberGmp* operand1Number = [operand1Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueNumberGmp* operand2Number = [operand2Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueList* operand1List = [operand1Value dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValueList* operand2List = [operand2Value dynamicCastToClass:[CHChalkValueList class]];
      if (operand1List)
        result = [[self combineSEL:_cmd arguments:operands list:operand1List index:0 token:token context:context] retain];
      else if (operand2List)
        result = [[self combineSEL:_cmd arguments:operands list:operand2List index:1 token:token context:context] retain];
      else if ((operand1Number.valueType != CHALK_VALUE_TYPE_INTEGER) || (operand2Number.valueType != CHALK_VALUE_TYPE_INTEGER))
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                               replace:NO];
      else//if ((operand1Number.valueType == CHALK_VALUE_TYPE_INTEGER) && (operand2Number.valueType == CHALK_VALUE_TYPE_INTEGER))
      {
        chalk_gmp_value_t currentValue = {0};
        if (chalkGmpValueMakeInteger(&currentValue, context.gmpPool))
        {
          if (chalkGmpValueSign(operand2Number.valueConstReference) < 0)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericInvalid range:token.range]
                                   replace:NO];
          else if (!mpz_fits_uint_p(operand2Number.valueConstReference->integer))
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainGmp reason:CHChalkErrorIntegerOverflow range:token.range]
                                   replace:NO];
          else
            mpz_bin_ui(currentValue.integer, operand1Number.valueConstReference->integer, mpz_get_ui(operand2Number.valueConstReference->integer));
        }//end if (chalkGmpValueMakeInteger(&currentValue, context.gmpPool))
        result = [[CHChalkValueNumberGmp alloc] initWithToken:token value:&currentValue naturalBase:operand1Number.naturalBase context:context];
        if (!result)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                 replace:NO];
        chalkGmpValueClear(&currentValue, YES, context.gmpPool);
      }//end if ((operand1Number.valueType == CHALK_VALUE_TYPE_INTEGER) && (operand2Number.valueType == CHALK_VALUE_TYPE_INTEGER))
      result.evaluationComputeFlags |=
        operand1Value.evaluationComputeFlags |
        operand2Value.evaluationComputeFlags |
        chalkGmpFlagsMake();
    }//end @autoreleasepool
  }//end if (operands.count == 2)
  return [result autorelease];
}
//end combineBinomial:token:context:

+(CHChalkValue*) combinePrimorial:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    @autoreleasepool {
      CHChalkValue* operandValue = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueNumberGmp* operandNumber = [operandValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueList* operandList = [operandValue dynamicCastToClass:[CHChalkValueList class]];
      if (operandList)
        result = [[self combineSEL:_cmd arguments:operands list:operandList index:0 token:token context:context] retain];
      else if (operandNumber)
      {
        if (operandNumber.valueType != CHALK_VALUE_TYPE_INTEGER)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                                 replace:NO];
        else//if (operandNumber.valueType == CHALK_VALUE_TYPE_INTEGER)
        {
          const chalk_gmp_value_t* operandValue = operandNumber.valueConstReference;
          if (chalkGmpValueSign(operandValue)<0)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericInvalid range:token.range]
                                   replace:NO];
          else if (!mpz_fits_uint_p(operandValue->integer))
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainGmp reason:CHChalkErrorIntegerOverflow range:token.range]
                                   replace:NO];
          else//if (chalkGmpValueSign(operandValue)>=0)
          {
            CHPrimesManager* primesManager = [CHPrimesManager sharedManager];
            mpz_srcptr maxCachedPrime = primesManager.maxCachedPrime;
            if (!maxCachedPrime || (mpz_cmp(maxCachedPrime, operandValue->integer) < 0))
              mpfr_set_inexflag();
            chalk_gmp_value_t currentValue = {0};
            if (chalkGmpValueMakeInteger(&currentValue, context.gmpPool))
              mpz_primorial_ui(currentValue.integer, mpz_get_ui(operandValue->integer));
            result = [[CHChalkValueNumberGmp alloc] initWithToken:token value:&currentValue naturalBase:operandNumber.naturalBase context:context];
            if (!result)
              [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                     replace:NO];
            chalkGmpValueClear(&currentValue, YES, context.gmpPool);
          }//end if (chalkGmpValueSign(operandValue)>=0)
        }//end if (operandNumber.valueType == CHALK_VALUE_TYPE_INTEGER)
      }//end if (operandNumber)
      result.evaluationComputeFlags |=
        operandValue.evaluationComputeFlags |
        chalkGmpFlagsMake();
    }//end @autoreleasepool
  }//end if ((operands.count == 1) || (operands.count == 2))
  return [result autorelease];
}
//end combinePrimorial:token:context:

+(CHChalkValue*) combineFibonacci:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    @autoreleasepool {
      CHChalkValue* operandValue = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueNumberGmp* operandNumber = [operandValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueList* operandList = [operandValue dynamicCastToClass:[CHChalkValueList class]];
      if (operandList)
        result = [[self combineSEL:_cmd arguments:operands list:operandList index:0 token:token context:context] retain];
      else if (operandNumber)
      {
        if (operandNumber.valueType != CHALK_VALUE_TYPE_INTEGER)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                                 replace:NO];
        else//if (operandNumber.valueType == CHALK_VALUE_TYPE_INTEGER)
        {
          const chalk_gmp_value_t* operandValue = operandNumber.valueConstReference;
          if (chalkGmpValueSign(operandValue)<0)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericInvalid range:token.range]
                                   replace:NO];
          else if (!mpz_fits_uint_p(operandValue->integer))
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainGmp reason:CHChalkErrorIntegerOverflow range:token.range]
                                   replace:NO];
          else//if (chalkGmpValueSign(operandValue)>=0)
          {
            chalk_gmp_value_t currentValue = {0};
            if (chalkGmpValueMakeInteger(&currentValue, context.gmpPool))
              mpz_fib_ui(currentValue.integer, mpz_get_ui(operandValue->integer));
            result = [[CHChalkValueNumberGmp alloc] initWithToken:token value:&currentValue naturalBase:operandNumber.naturalBase context:context];
            if (!result)
              [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                     replace:NO];
            chalkGmpValueClear(&currentValue, YES, context.gmpPool);
          }//end if (chalkGmpValueSign(operandValue)>=0)
        }//end if (operandNumber.valueType == CHALK_VALUE_TYPE_INTEGER)
      }//end if (operandNumber)
      result.evaluationComputeFlags |=
        operandValue.evaluationComputeFlags |
        chalkGmpFlagsMake();
    }//end @autoreleasepool
  }//end if ((operands.count == 1) || (operands.count == 2))
  return [result autorelease];
}
//end combineFibonacci:token:context:

+(CHChalkValue*) combineJacobi:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 2)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 2)
  {
    @autoreleasepool {
      CHChalkValue* operand1Value = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValue* operand2Value = [[operands objectAtIndex:1] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueNumberGmp* operand1Number = [operand1Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueNumberGmp* operand2Number = [operand2Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueList* operand1List = [operand1Value dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValueList* operand2List = [operand2Value dynamicCastToClass:[CHChalkValueList class]];
      if (operand1List)
        result = [[self combineSEL:_cmd arguments:operands list:operand1List index:0 token:token context:context] retain];
      else if (operand2List)
        result = [[self combineSEL:_cmd arguments:operands list:operand2List index:1 token:token context:context] retain];
      else if ((operand1Number.valueType != CHALK_VALUE_TYPE_INTEGER) || (operand2Number.valueType != CHALK_VALUE_TYPE_INTEGER))
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                               replace:NO];
      else//if ((operand1Number.valueType == CHALK_VALUE_TYPE_INTEGER) && (operand2Number.valueType == CHALK_VALUE_TYPE_INTEGER))
      {
        chalk_gmp_value_t currentValue = {0};
        if (chalkGmpValueMakeInteger(&currentValue, context.gmpPool))
        {
          const chalk_gmp_value_t* operand1GmpValue = operand1Number.valueConstReference;
          const chalk_gmp_value_t* operand2GmpValue = operand2Number.valueConstReference;
          if ((mpz_cmp_ui(operand2GmpValue->integer, 2)<0) || !mpz_odd_p(operand2GmpValue->integer))
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorNumericInvalid range:token.range]
                                   replace:NO];
          else
            mpz_set_si(currentValue.integer, mpz_jacobi(operand1GmpValue->integer, operand2GmpValue->integer));
        }//end if (chalkGmpValueMakeInteger(&currentValue, context.gmpPool))
        result = [[CHChalkValueNumberGmp alloc] initWithToken:token value:&currentValue naturalBase:operand1Number.naturalBase context:context];
        if (!result)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                 replace:NO];
        chalkGmpValueClear(&currentValue, YES, context.gmpPool);
      }//end if ((operand1Number.valueType == CHALK_VALUE_TYPE_INTEGER) && (operand2Number.valueType == CHALK_VALUE_TYPE_INTEGER))
      result.evaluationComputeFlags |=
        operand1Value.evaluationComputeFlags |
        operand2Value.evaluationComputeFlags |
        chalkGmpFlagsMake();
    }//end @autoreleasepool
  }//end if (operands.count == 2)
  return [result autorelease];
}
//end combineJacobi:token:context:

+(CHChalkValue*) combineInput:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    @autoreleasepool {
      CHChalkValue* operandValue = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueNumberGmp* operandGmp = [operandValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueFormal* operandFormal = [operandValue dynamicCastToClass:[CHChalkValueFormal class]];
      operandGmp = !operandFormal ? operandGmp : operandFormal.value;
      CHChalkValueList* operandList = [operandValue dynamicCastToClass:[CHChalkValueList class]];
      if (operandList)
        result = [[self combineSEL:_cmd arguments:operands list:operandList index:0 token:token context:context] retain];
      else if (!operandGmp || (operandGmp.valueType != CHALK_VALUE_TYPE_INTEGER))
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                               replace:NO];
      else//if (operandGmp && (operandGmp.valueType == CHALK_VALUE_TYPE_INTEGER))
      {
        const chalk_gmp_value_t* operandGmpValue = operandGmp.valueConstReference;
        NSNumber* operandGmpValueNumber = !operandGmpValue || !mpz_fits_nssi_p(operandGmpValue->integer) ? nil :
          [NSNumber numberWithInteger:mpz_get_nssi(operandGmpValue->integer)];
        if (!operandGmpValueNumber)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                                 replace:NO];
        else//if (operandGmpValueNumber)
        {
          NSInteger index = [operandGmpValueNumber integerValue];
          CHComputationEntryEntity* computationEntry = [context computationEntryForAge:(index<0) ? -index : index];
          result = [computationEntry.chalkValue1 copy];
          //[result.token unionWithToken:token];//experimental
        }//end if (operandGmpValueNumber)
      }//if (operandGmp && (operandGmp.valueType == CHALK_VALUE_TYPE_INTEGER))
    }//end @autoreleasepool
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineInput:token:context:

+(CHChalkValue*) combineOutput:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    @autoreleasepool {
      CHChalkValue* operandValue = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueNumberGmp* operandGmp = [operandValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueFormal* operandFormal = [operandValue dynamicCastToClass:[CHChalkValueFormal class]];
      operandGmp = !operandFormal ? operandGmp : operandFormal.value;
      CHChalkValueList* operandList = [operandValue dynamicCastToClass:[CHChalkValueList class]];
      if (operandList)
        result = [[self combineSEL:_cmd arguments:operands list:operandList index:0 token:token context:context] retain];
      else if (!operandGmp || (operandGmp.valueType != CHALK_VALUE_TYPE_INTEGER))
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                               replace:NO];
      else//if (operandGmp && (operandGmp.valueType == CHALK_VALUE_TYPE_INTEGER))
      {
        const chalk_gmp_value_t* operandGmpValue = operandGmp.valueConstReference;
        NSNumber* operandGmpValueNumber = !operandGmpValue || !mpz_fits_nssi_p(operandGmpValue->integer) ? nil :
          [NSNumber numberWithInteger:mpz_get_nssi(operandGmpValue->integer)];
        if (!operandGmpValueNumber)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                                 replace:NO];
        else//if (operandGmpValueNumber)
        {
          NSInteger index = [operandGmpValueNumber integerValue];
          CHComputationEntryEntity* computationEntry = [context computationEntryForAge:(index<0) ? -index : index];
          result = [computationEntry.chalkValue1 copy];
          //[result.token unionWithToken:token];//experimental
        }//end if (operandGmpValueNumber)
      }//if (operandGmp && (operandGmp.valueType == CHALK_VALUE_TYPE_INTEGER))
    }//end @autoreleasepool
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineOutput:token:context:

+(CHChalkValue*) combineOutput2:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    @autoreleasepool {
      CHChalkValue* operandValue = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueNumberGmp* operandGmp = [operandValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueFormal* operandFormal = [operandValue dynamicCastToClass:[CHChalkValueFormal class]];
      operandGmp = !operandFormal ? operandGmp : operandFormal.value;
      CHChalkValueList* operandList = [operandValue dynamicCastToClass:[CHChalkValueList class]];
      if (operandList)
        result = [[self combineSEL:_cmd arguments:operands list:operandList index:0 token:token context:context] retain];
      else if (!operandGmp || (operandGmp.valueType != CHALK_VALUE_TYPE_INTEGER))
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                               replace:NO];
      else//if (operandGmp && (operandGmp.valueType == CHALK_VALUE_TYPE_INTEGER))
      {
        const chalk_gmp_value_t* operandGmpValue = operandGmp.valueConstReference;
        NSNumber* operandGmpValueNumber = !operandGmpValue || !mpz_fits_nssi_p(operandGmpValue->integer) ? nil :
          [NSNumber numberWithInteger:mpz_get_nssi(operandGmpValue->integer)];
        if (!operandGmpValueNumber)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                                 replace:NO];
        else//if (operandGmpValueNumber)
        {
          NSInteger index = [operandGmpValueNumber integerValue];
          CHComputationEntryEntity* computationEntry = [context computationEntryForAge:(index<0) ? -index : index];
          result = [computationEntry.chalkValue2 copy];
          //[result.token unionWithToken:token];//experimental
        }//end if (operandGmpValueNumber)
      }//if (operandGmp && (operandGmp.valueType == CHALK_VALUE_TYPE_INTEGER))
    }//end @autoreleasepool
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineOutput2:token:context:

+(CHChalkValue*) combineFromBase:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 2)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 2)
  {
    @autoreleasepool {
      CHChalkValue* operand1Value = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValue* operand2Value = [[operands objectAtIndex:1] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueNumber* operand1Number = [operand1Value dynamicCastToClass:[CHChalkValueNumber class]];
      CHChalkValueNumberGmp* operand2Number = [operand2Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueList* operand1List = [operand1Value dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValueList* operand2List = [operand2Value dynamicCastToClass:[CHChalkValueList class]];
      if (operand1List)
        result = [[self combineSEL:_cmd arguments:operands list:operand1List index:0 token:token context:context] retain];
      else if (operand2List)
        result = [[self combineSEL:_cmd arguments:operands list:operand2List index:1 token:token context:context] retain];
      else if (!operand1Number)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:operand1Value.token.range]
                               replace:NO];
      else if (!operand2Number.valueConstReference || (operand2Number.valueType != CHALK_VALUE_TYPE_INTEGER))
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:operand2Value.token.range]
                               replace:NO];
      else if (!mpz_fits_sint_p(operand2Number.valueConstReference->integer) ||
               !chalkGmpBaseIsValid((int)mpz_get_si(operand2Number.valueConstReference->integer)))
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorGmpBaseInvalid reason:CHChalkErrorOperatorArgumentsError range:operand2Value.token.range]
                               replace:NO];
      else
      {
        CHChalkContext* localContext = [[context copy] autorelease];
        localContext.computationConfiguration.baseDefault = (int)mpz_get_si(operand2Number.valueConstReference->integer);
        CHChalkValueParser* valueParser = [[[CHChalkValueParser alloc] initWithToken:operand1Value.token context:localContext] autorelease];
        result = [[valueParser chalkValueWithContext:context] retain];
        if (!result)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                 replace:NO];
      }//end else
      result.evaluationComputeFlags |=
        operand1Value.evaluationComputeFlags |
        operand2Value.evaluationComputeFlags |
        chalkGmpFlagsMake();
    }//end @autoreleasepool
  }//end if (operands.count == 2)
  return [result autorelease];
}
//end combineFromBase:token:context:

+(CHChalkValue*) combineInFile:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    @autoreleasepool {
      CHChalkValue* operand1Value = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueString* operand1String = [operand1Value dynamicCastToClass:[CHChalkValueString class]];
      CHChalkValueList* operand1List = [operand1Value dynamicCastToClass:[CHChalkValueList class]];
      if (operand1List)
        result = [[self combineSEL:_cmd arguments:operands list:operand1List index:0 token:token context:context] retain];
      else if (operand1String)
      {
        NSString* path = operand1String.stringValue;
        NSURL* url = !path ? nil : [NSURL URLAutoWithPath:path];
        CHChalkValueURLInput* valueUrlInput = [[CHChalkValueURLInput alloc] initWithToken:token url:url context:context];
        if (!valueUrlInput)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range] replace:NO];
        [valueUrlInput performEvaluationWithContext:context];
        result = [valueUrlInput.urlValue retain];
        [valueUrlInput release];
        result.evaluationComputeFlags |=
          operand1Value.evaluationComputeFlags |
          chalkGmpFlagsMake();
      }//end if (operand1String)
    }//end @autoreleasepool
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineInFile:token:context:

+(CHChalkValue*) combineOutFile:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    @autoreleasepool {
      CHChalkValue* operand1Value = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueString* operand1String = [operand1Value dynamicCastToClass:[CHChalkValueString class]];
      CHChalkValueList* operand1List = [operand1Value dynamicCastToClass:[CHChalkValueList class]];
      if (operand1List)
        result = [[self combineSEL:_cmd arguments:operands list:operand1List index:0 token:token context:context] retain];
      else if (operand1String)
      {
        NSString* path = operand1String.stringValue;
        NSURL* url = !path ? nil : [NSURL URLAutoWithPath:path];
        CHChalkValueURLOutput* valueUrlOutput = [[CHChalkValueURLOutput alloc] initWithToken:token url:url context:context];
        if (!valueUrlOutput)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range] replace:NO];
        else
          result = valueUrlOutput;
        result.evaluationComputeFlags |=
          operand1Value.evaluationComputeFlags |
          chalkGmpFlagsMake();
      }//end else if (operand1String)
    }//end @autoreleasepool
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineOutFile:token:context:

+(CHChalkValue*) combineToU8:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    chalk_bit_interpretation_t inputBitInterpretation = {0};
    inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
    inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_INTEGER_STANDARD;
    inputBitInterpretation.numberEncoding.encodingVariant.integerStandardVariantEncoding = CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_8U;
    inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.significandCustomBitsCount = getSignificandBitsCountForEncoding(inputBitInterpretation.numberEncoding, NO);
    @autoreleasepool {
      NSValue* inputBitInterpretationValue = [NSValue valueWithBytes:&inputBitInterpretation objCType:@encode(chalk_bit_interpretation_t)];
      NSArray* newOperands = !inputBitInterpretationValue ? nil : [operands arrayByAddingObject:inputBitInterpretationValue];
      if (!newOperands)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      else
        result = [[self combineToRawValue:newOperands token:token context:context] retain];
    }
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineToU8:token:context:

+(CHChalkValue*) combineToS8:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    chalk_bit_interpretation_t inputBitInterpretation = {0};
    inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
    inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_INTEGER_STANDARD;
    inputBitInterpretation.numberEncoding.encodingVariant.integerStandardVariantEncoding = CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_8S;
    inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.significandCustomBitsCount = getSignificandBitsCountForEncoding(inputBitInterpretation.numberEncoding, NO);
    @autoreleasepool {
      NSValue* inputBitInterpretationValue = [NSValue valueWithBytes:&inputBitInterpretation objCType:@encode(chalk_bit_interpretation_t)];
      NSArray* newOperands = !inputBitInterpretationValue ? nil : [operands arrayByAddingObject:inputBitInterpretationValue];
      if (!newOperands)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      else
        result = [[self combineToRawValue:newOperands token:token context:context] retain];
    }
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineToS8:token:context:

+(CHChalkValue*) combineToU16:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    chalk_bit_interpretation_t inputBitInterpretation = {0};
    inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
    inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_INTEGER_STANDARD;
    inputBitInterpretation.numberEncoding.encodingVariant.integerStandardVariantEncoding = CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_16U;
    inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.significandCustomBitsCount = getSignificandBitsCountForEncoding(inputBitInterpretation.numberEncoding, NO);
    @autoreleasepool {
      NSValue* inputBitInterpretationValue = [NSValue valueWithBytes:&inputBitInterpretation objCType:@encode(chalk_bit_interpretation_t)];
      NSArray* newOperands = !inputBitInterpretationValue ? nil : [operands arrayByAddingObject:inputBitInterpretationValue];
      if (!newOperands)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      else
        result = [[self combineToRawValue:newOperands token:token context:context] retain];
    }
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineToU16:token:context:

+(CHChalkValue*) combineToS16:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    chalk_bit_interpretation_t inputBitInterpretation = {0};
    inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
    inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_INTEGER_STANDARD;
    inputBitInterpretation.numberEncoding.encodingVariant.integerStandardVariantEncoding = CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_16S;
    inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.significandCustomBitsCount = getSignificandBitsCountForEncoding(inputBitInterpretation.numberEncoding, NO);
    @autoreleasepool {
      NSValue* inputBitInterpretationValue = [NSValue valueWithBytes:&inputBitInterpretation objCType:@encode(chalk_bit_interpretation_t)];
      NSArray* newOperands = !inputBitInterpretationValue ? nil : [operands arrayByAddingObject:inputBitInterpretationValue];
      if (!newOperands)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      else
        result = [[self combineToRawValue:newOperands token:token context:context] retain];
    }
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineToS16:token:context:

+(CHChalkValue*) combineToU32:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    chalk_bit_interpretation_t inputBitInterpretation = {0};
    inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
    inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_INTEGER_STANDARD;
    inputBitInterpretation.numberEncoding.encodingVariant.integerStandardVariantEncoding = CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_32U;
    inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.significandCustomBitsCount = getSignificandBitsCountForEncoding(inputBitInterpretation.numberEncoding, NO);
    @autoreleasepool {
      NSValue* inputBitInterpretationValue = [NSValue valueWithBytes:&inputBitInterpretation objCType:@encode(chalk_bit_interpretation_t)];
      NSArray* newOperands = !inputBitInterpretationValue ? nil : [operands arrayByAddingObject:inputBitInterpretationValue];
      if (!newOperands)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      else
        result = [[self combineToRawValue:newOperands token:token context:context] retain];
    }
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineToU32:token:context:

+(CHChalkValue*) combineToS32:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    chalk_bit_interpretation_t inputBitInterpretation = {0};
    inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
    inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_INTEGER_STANDARD;
    inputBitInterpretation.numberEncoding.encodingVariant.integerStandardVariantEncoding = CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_32S;
    inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.significandCustomBitsCount = getSignificandBitsCountForEncoding(inputBitInterpretation.numberEncoding, NO);
    @autoreleasepool {
      NSValue* inputBitInterpretationValue = [NSValue valueWithBytes:&inputBitInterpretation objCType:@encode(chalk_bit_interpretation_t)];
      NSArray* newOperands = !inputBitInterpretationValue ? nil : [operands arrayByAddingObject:inputBitInterpretationValue];
      if (!newOperands)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      else
        result = [[self combineToRawValue:newOperands token:token context:context] retain];
    }
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineToS32:token:context:

+(CHChalkValue*) combineToU64:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    chalk_bit_interpretation_t inputBitInterpretation = {0};
    inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
    inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_INTEGER_STANDARD;
    inputBitInterpretation.numberEncoding.encodingVariant.integerStandardVariantEncoding = CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_64U;
    inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.significandCustomBitsCount = getSignificandBitsCountForEncoding(inputBitInterpretation.numberEncoding, NO);
    @autoreleasepool {
      NSValue* inputBitInterpretationValue = [NSValue valueWithBytes:&inputBitInterpretation objCType:@encode(chalk_bit_interpretation_t)];
      NSArray* newOperands = !inputBitInterpretationValue ? nil : [operands arrayByAddingObject:inputBitInterpretationValue];
      if (!newOperands)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      else
        result = [[self combineToRawValue:newOperands token:token context:context] retain];
    }
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineToU64:token:context:

+(CHChalkValue*) combineToS64:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    chalk_bit_interpretation_t inputBitInterpretation = {0};
    inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
    inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_INTEGER_STANDARD;
    inputBitInterpretation.numberEncoding.encodingVariant.integerStandardVariantEncoding = CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_64S;
    inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.significandCustomBitsCount = getSignificandBitsCountForEncoding(inputBitInterpretation.numberEncoding, NO);
    @autoreleasepool {
      NSValue* inputBitInterpretationValue = [NSValue valueWithBytes:&inputBitInterpretation objCType:@encode(chalk_bit_interpretation_t)];
      NSArray* newOperands = !inputBitInterpretationValue ? nil : [operands arrayByAddingObject:inputBitInterpretationValue];
      if (!newOperands)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      else
        result = [[self combineToRawValue:newOperands token:token context:context] retain];
    }
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineToS64:token:context:

+(CHChalkValue*) combineToU128:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    chalk_bit_interpretation_t inputBitInterpretation = {0};
    inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
    inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_INTEGER_STANDARD;
    inputBitInterpretation.numberEncoding.encodingVariant.integerStandardVariantEncoding = CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_128U;
    inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.significandCustomBitsCount = getSignificandBitsCountForEncoding(inputBitInterpretation.numberEncoding, NO);
    @autoreleasepool {
      NSValue* inputBitInterpretationValue = [NSValue valueWithBytes:&inputBitInterpretation objCType:@encode(chalk_bit_interpretation_t)];
      NSArray* newOperands = !inputBitInterpretationValue ? nil : [operands arrayByAddingObject:inputBitInterpretationValue];
      if (!newOperands)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      else
        result = [[self combineToRawValue:newOperands token:token context:context] retain];
    }
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineToU128:token:context:

+(CHChalkValue*) combineToS128:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    chalk_bit_interpretation_t inputBitInterpretation = {0};
    inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
    inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_INTEGER_STANDARD;
    inputBitInterpretation.numberEncoding.encodingVariant.integerStandardVariantEncoding = CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_128S;
    inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.significandCustomBitsCount = getSignificandBitsCountForEncoding(inputBitInterpretation.numberEncoding, NO);
    @autoreleasepool {
      NSValue* inputBitInterpretationValue = [NSValue valueWithBytes:&inputBitInterpretation objCType:@encode(chalk_bit_interpretation_t)];
      NSArray* newOperands = !inputBitInterpretationValue ? nil : [operands arrayByAddingObject:inputBitInterpretationValue];
      if (!newOperands)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      else
        result = [[self combineToRawValue:newOperands token:token context:context] retain];
    }
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineToS128:token:context:

+(CHChalkValue*) combineToU256:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    chalk_bit_interpretation_t inputBitInterpretation = {0};
    inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
    inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_INTEGER_STANDARD;
    inputBitInterpretation.numberEncoding.encodingVariant.integerStandardVariantEncoding = CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_256U;
    inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.significandCustomBitsCount = getSignificandBitsCountForEncoding(inputBitInterpretation.numberEncoding, NO);
    @autoreleasepool {
      NSValue* inputBitInterpretationValue = [NSValue valueWithBytes:&inputBitInterpretation objCType:@encode(chalk_bit_interpretation_t)];
      NSArray* newOperands = !inputBitInterpretationValue ? nil : [operands arrayByAddingObject:inputBitInterpretationValue];
      if (!newOperands)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      else
        result = [[self combineToRawValue:newOperands token:token context:context] retain];
    }
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineToU256:token:context:

+(CHChalkValue*) combineToS256:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    chalk_bit_interpretation_t inputBitInterpretation = {0};
    inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
    inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_INTEGER_STANDARD;
    inputBitInterpretation.numberEncoding.encodingVariant.integerStandardVariantEncoding = CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_256S;
    inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.significandCustomBitsCount = getSignificandBitsCountForEncoding(inputBitInterpretation.numberEncoding, NO);
    @autoreleasepool {
      NSValue* inputBitInterpretationValue = [NSValue valueWithBytes:&inputBitInterpretation objCType:@encode(chalk_bit_interpretation_t)];
      NSArray* newOperands = !inputBitInterpretationValue ? nil : [operands arrayByAddingObject:inputBitInterpretationValue];
      if (!newOperands)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      else
        result = [[self combineToRawValue:newOperands token:token context:context] retain];
    }
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineToS256:token:context:

+(CHChalkValue*) combineToUCustom:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 2)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 2)
  {
    id operand1 = [operands objectAtIndex:0];
    CHChalkValue* operand2Value = [[operands objectAtIndex:1] dynamicCastToClass:[CHChalkValue class]];
    CHChalkValueNumberGmp* operand2GmpValue = [operand2Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
    const chalk_gmp_value_t* operand2Gmp = operand2GmpValue.valueConstReference;
    NSUInteger operand2UInteger = !operand2Gmp || (operand2Gmp->type != CHALK_VALUE_TYPE_INTEGER) || !mpz_fits_nsui_p(operand2Gmp->integer) ? 0 : mpz_get_nssi(operand2Gmp->integer);
    chalk_bit_interpretation_t inputBitInterpretation = {0};
    inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
    inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_INTEGER_CUSTOM;
    inputBitInterpretation.numberEncoding.encodingVariant.integerCustomVariantEncoding = CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_SIGNED;
    inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    NSUInteger minimumBitsRequired = inputBitInterpretation.signCustomBitsCount+inputBitInterpretation.exponentCustomBitsCount+1;
    if (operand2UInteger < minimumBitsRequired)
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                             replace:NO];
    else//if (operand2UInteger >= minimumBitsRequired)
    {
      chalk_bit_interpretation_t inputBitInterpretation = {0};
      inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
      inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_INTEGER_CUSTOM;
      inputBitInterpretation.numberEncoding.encodingVariant.integerCustomVariantEncoding = CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_UNSIGNED;
      inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
      inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
      inputBitInterpretation.significandCustomBitsCount = operand2UInteger-inputBitInterpretation.signCustomBitsCount-inputBitInterpretation.exponentCustomBitsCount;
      @autoreleasepool {
        NSValue* inputBitInterpretationValue = [NSValue valueWithBytes:&inputBitInterpretation objCType:@encode(chalk_bit_interpretation_t)];
        NSArray* newOperands = !inputBitInterpretationValue ? nil : @[operand1, inputBitInterpretationValue];
        if (!newOperands)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                 replace:NO];
        else
          result = [[self combineToRawValue:newOperands token:token context:context] retain];
      }//end @autoreleasepool
    }//end if (operand2UInteger >= minimumBitsRequired)
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineToUCustom:token:context:

+(CHChalkValue*) combineToSCustom:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 2)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 2)
  {
    id operand1 = [operands objectAtIndex:0];
    CHChalkValue* operand2Value = [[operands objectAtIndex:1] dynamicCastToClass:[CHChalkValue class]];
    CHChalkValueNumberGmp* operand2GmpValue = [operand2Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
    const chalk_gmp_value_t* operand2Gmp = operand2GmpValue.valueConstReference;
    NSUInteger operand2UInteger = !operand2Gmp || (operand2Gmp->type != CHALK_VALUE_TYPE_INTEGER) || !mpz_fits_nsui_p(operand2Gmp->integer) ? 0 : mpz_get_nssi(operand2Gmp->integer);
    chalk_bit_interpretation_t inputBitInterpretation = {0};
    inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
    inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_INTEGER_CUSTOM;
    inputBitInterpretation.numberEncoding.encodingVariant.integerCustomVariantEncoding = CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_SIGNED;
    inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    NSUInteger minimumBitsRequired = inputBitInterpretation.signCustomBitsCount+inputBitInterpretation.exponentCustomBitsCount+1;
    if (operand2UInteger < minimumBitsRequired)
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                             replace:NO];
    else//if (operand2UInteger >= minimumBitsRequired)
    {
      chalk_bit_interpretation_t inputBitInterpretation = {0};
      inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
      inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_INTEGER_CUSTOM;
      inputBitInterpretation.numberEncoding.encodingVariant.integerCustomVariantEncoding = CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_SIGNED;
      inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
      inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
      inputBitInterpretation.significandCustomBitsCount = operand2UInteger-inputBitInterpretation.signCustomBitsCount-inputBitInterpretation.exponentCustomBitsCount;
      @autoreleasepool {
        NSValue* inputBitInterpretationValue = [NSValue valueWithBytes:&inputBitInterpretation objCType:@encode(chalk_bit_interpretation_t)];
        NSArray* newOperands = !inputBitInterpretationValue ? nil : @[operand1, inputBitInterpretationValue];
        if (!newOperands)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                 replace:NO];
        else
          result = [[self combineToRawValue:newOperands token:token context:context] retain];
      }//end @autoreleasepool
    }//end if (operand2UInteger >= minimumBitsRequired)
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineToSCustom:token:context:

+(CHChalkValue*) combineToChalkInteger:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    chalk_bit_interpretation_t inputBitInterpretation = {0};
    inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
    inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_GMP_CUSTOM;
    inputBitInterpretation.numberEncoding.encodingVariant.gmpCustomVariantEncoding = CHALK_NUMBER_ENCODING_GMP_CUSTOM_VARIANT_Z;
    inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.significandCustomBitsCount = context.computationConfiguration.softIntegerMaxBits;
    @autoreleasepool {
      NSValue* inputBitInterpretationValue = [NSValue valueWithBytes:&inputBitInterpretation objCType:@encode(chalk_bit_interpretation_t)];
      NSArray* newOperands = !inputBitInterpretationValue ? nil : [operands arrayByAddingObject:inputBitInterpretationValue];
      if (!newOperands)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      else
        result = [[self combineToRawValue:newOperands token:token context:context] retain];
    }
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineToChalkInteger:token:context:

+(CHChalkValue*) combineToF16:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    chalk_bit_interpretation_t inputBitInterpretation = {0};
    inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
    inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_IEEE754_STANDARD;
    inputBitInterpretation.numberEncoding.encodingVariant.ieee754StandardVariantEncoding = CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_HALF;
    inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.significandCustomBitsCount = getSignificandBitsCountForEncoding(inputBitInterpretation.numberEncoding, NO);
    @autoreleasepool {
      NSValue* inputBitInterpretationValue = [NSValue valueWithBytes:&inputBitInterpretation objCType:@encode(chalk_bit_interpretation_t)];
      NSArray* newOperands = !inputBitInterpretationValue ? nil : [operands arrayByAddingObject:inputBitInterpretationValue];
      if (!newOperands)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      else
        result = [[self combineToRawValue:newOperands token:token context:context] retain];
    }
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineToF16:token:context:

+(CHChalkValue*) combineToF32:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    chalk_bit_interpretation_t inputBitInterpretation = {0};
    inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
    inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_IEEE754_STANDARD;
    inputBitInterpretation.numberEncoding.encodingVariant.ieee754StandardVariantEncoding = CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_SINGLE;
    inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.significandCustomBitsCount = getSignificandBitsCountForEncoding(inputBitInterpretation.numberEncoding, NO);
    @autoreleasepool {
      NSValue* inputBitInterpretationValue = [NSValue valueWithBytes:&inputBitInterpretation objCType:@encode(chalk_bit_interpretation_t)];
      NSArray* newOperands = !inputBitInterpretationValue ? nil : [operands arrayByAddingObject:inputBitInterpretationValue];
      if (!newOperands)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      else
        result = [[self combineToRawValue:newOperands token:token context:context] retain];
    }
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineToF32:token:context:

+(CHChalkValue*) combineToF64:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    chalk_bit_interpretation_t inputBitInterpretation = {0};
    inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
    inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_IEEE754_STANDARD;
    inputBitInterpretation.numberEncoding.encodingVariant.ieee754StandardVariantEncoding = CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_DOUBLE;
    inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.significandCustomBitsCount = getSignificandBitsCountForEncoding(inputBitInterpretation.numberEncoding, NO);
    @autoreleasepool {
      NSValue* inputBitInterpretationValue = [NSValue valueWithBytes:&inputBitInterpretation objCType:@encode(chalk_bit_interpretation_t)];
      NSArray* newOperands = !inputBitInterpretationValue ? nil : [operands arrayByAddingObject:inputBitInterpretationValue];
      if (!newOperands)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      else
        result = [[self combineToRawValue:newOperands token:token context:context] retain];
    }
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineToF64:token:context:

+(CHChalkValue*) combineToF128:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    chalk_bit_interpretation_t inputBitInterpretation = {0};
    inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
    inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_IEEE754_STANDARD;
    inputBitInterpretation.numberEncoding.encodingVariant.ieee754StandardVariantEncoding = CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_QUADRUPLE;
    inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.significandCustomBitsCount = getSignificandBitsCountForEncoding(inputBitInterpretation.numberEncoding, NO);
    @autoreleasepool {
      NSValue* inputBitInterpretationValue = [NSValue valueWithBytes:&inputBitInterpretation objCType:@encode(chalk_bit_interpretation_t)];
      NSArray* newOperands = !inputBitInterpretationValue ? nil : [operands arrayByAddingObject:inputBitInterpretationValue];
      if (!newOperands)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      else
        result = [[self combineToRawValue:newOperands token:token context:context] retain];
    }
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineToF128:token:context:

+(CHChalkValue*) combineToF256:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    chalk_bit_interpretation_t inputBitInterpretation = {0};
    inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
    inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_IEEE754_STANDARD;
    inputBitInterpretation.numberEncoding.encodingVariant.ieee754StandardVariantEncoding = CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_OCTUPLE;
    inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.significandCustomBitsCount = getSignificandBitsCountForEncoding(inputBitInterpretation.numberEncoding, NO);
    @autoreleasepool {
      NSValue* inputBitInterpretationValue = [NSValue valueWithBytes:&inputBitInterpretation objCType:@encode(chalk_bit_interpretation_t)];
      NSArray* newOperands = !inputBitInterpretationValue ? nil : [operands arrayByAddingObject:inputBitInterpretationValue];
      if (!newOperands)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      else
        result = [[self combineToRawValue:newOperands token:token context:context] retain];
    }
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineToF256:token:context:

+(CHChalkValue*) combineToChalkFloat:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    chalk_bit_interpretation_t inputBitInterpretation = {0};
    inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
    inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_GMP_CUSTOM;
    inputBitInterpretation.numberEncoding.encodingVariant.gmpCustomVariantEncoding = CHALK_NUMBER_ENCODING_GMP_CUSTOM_VARIANT_FR;
    inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.significandCustomBitsCount = context.computationConfiguration.softFloatSignificandBits;
    @autoreleasepool {
      NSValue* inputBitInterpretationValue = [NSValue valueWithBytes:&inputBitInterpretation objCType:@encode(chalk_bit_interpretation_t)];
      NSArray* newOperands = !inputBitInterpretationValue ? nil : [operands arrayByAddingObject:inputBitInterpretationValue];
      if (!newOperands)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      else
        result = [[self combineToRawValue:newOperands token:token context:context] retain];
    }
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineToChalkFloat:token:context:

+(CHChalkValue*) combineToRawValue:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
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
      CHChalkValueList* operand1List = [operand1Value dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValueMatrix* operand1Matrix = [operand1Value dynamicCastToClass:[CHChalkValueMatrix class]];
      NSValue* operand2Value = [[operands objectAtIndex:1] dynamicCastToClass:[NSValue class]];
      if (operand1List)
        result = [[self combineSEL:_cmd arguments:operands list:operand1List index:0 token:token context:context] retain];
      else if (operand1Matrix)
      {
        CHChalkValueMatrix* newMatrix = [[self combineMatrixSEL:_cmd operand:operand1Matrix token:token context:context] retain];
        if (context.errorContext.hasError)
        {
          [newMatrix release];
          newMatrix = nil;
        }//end if (context.errorContext.hasError)
        result = newMatrix;
      }//end if (operand1Matrix)
      else if (operand1Gmp && operand1Gmp.valueConstReference && operand2Value)
      {
        chalk_bit_interpretation_t inputBitInterpretation = {0};
        [operand2Value getValue:&inputBitInterpretation];
        chalk_raw_value_t rawValue = {0};
        BOOL done = NO;
        BOOL rawValueCreated = chalkRawValueCreate(&rawValue, context.gmpPool);
        if (rawValueCreated)
        {
          chalk_conversion_result_t conversionResult = convertFromValueToRaw(&rawValue, operand1Gmp.valueConstReference, context.computationConfiguration.computeMode, &inputBitInterpretation, context);
          rawValue.bitInterpretation = inputBitInterpretation;
          if (conversionResult.error != CHALK_CONVERSION_ERROR_NOERROR)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:[CHChalkError convertFromConversionError:conversionResult.error] range:token.range]
                                   replace:NO];
          else//if (conversionResult.error == CHALK_CONVERSION_ERROR_NOERROR)
          {
            result = [[CHChalkValueNumberRaw alloc] initWithToken:token value:&rawValue naturalBase:context.computationConfiguration.baseDefault context:context];
            result.evaluationComputeFlags |= conversionResult.computeFlags;
            done |= (result != nil);
            if (!result)
              [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                     replace:NO];
          }//end if (conversionResult.error == CHALK_CONVERSION_ERROR_NOERROR)
          if (!done)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                   replace:NO];
          if (!result)//value has been moved when result is OK
            chalkRawValueClear(&rawValue, YES, context.gmpPool);
        }//end if (rawValueCreated)
      }//if (operand1Gmp && operand1Gmp.valueConstReference && operand2Value)
      else
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                               replace:NO];
      result.evaluationComputeFlags |=
        operand1Value.evaluationComputeFlags |
        chalkGmpFlagsMake();
    }//end @autoreleasepool
  }//end if (operands.count == 2)
  return [result autorelease];
}
//end combineToRawValue:token:context:

+(CHChalkValue*) combineFromU8:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    chalk_bit_interpretation_t inputBitInterpretation = {0};
    inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
    inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_INTEGER_STANDARD;
    inputBitInterpretation.numberEncoding.encodingVariant.integerStandardVariantEncoding = CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_8U;
    inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.significandCustomBitsCount = getSignificandBitsCountForEncoding(inputBitInterpretation.numberEncoding, NO);
    @autoreleasepool {
      NSValue* inputBitInterpretationValue = [NSValue valueWithBytes:&inputBitInterpretation objCType:@encode(chalk_bit_interpretation_t)];
      NSArray* newOperands = !inputBitInterpretationValue ? nil : [operands arrayByAddingObject:inputBitInterpretationValue];
      if (!newOperands)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      else
        result = [[self combineFromRawValue:newOperands token:token context:context] retain];
    }
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineFromU8:token:context:

+(CHChalkValue*) combineFromS8:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    chalk_bit_interpretation_t inputBitInterpretation = {0};
    inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
    inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_INTEGER_STANDARD;
    inputBitInterpretation.numberEncoding.encodingVariant.integerStandardVariantEncoding = CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_8S;
    inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.significandCustomBitsCount = getSignificandBitsCountForEncoding(inputBitInterpretation.numberEncoding, NO);
    @autoreleasepool {
      NSValue* inputBitInterpretationValue = [NSValue valueWithBytes:&inputBitInterpretation objCType:@encode(chalk_bit_interpretation_t)];
      NSArray* newOperands = !inputBitInterpretationValue ? nil : [operands arrayByAddingObject:inputBitInterpretationValue];
      if (!newOperands)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      else
        result = [[self combineFromRawValue:newOperands token:token context:context] retain];
    }
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineFromS8:token:context:

+(CHChalkValue*) combineFromU16:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    chalk_bit_interpretation_t inputBitInterpretation = {0};
    inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
    inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_INTEGER_STANDARD;
    inputBitInterpretation.numberEncoding.encodingVariant.integerStandardVariantEncoding = CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_16U;
    inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.significandCustomBitsCount = getSignificandBitsCountForEncoding(inputBitInterpretation.numberEncoding, NO);
    @autoreleasepool {
      NSValue* inputBitInterpretationValue = [NSValue valueWithBytes:&inputBitInterpretation objCType:@encode(chalk_bit_interpretation_t)];
      NSArray* newOperands = !inputBitInterpretationValue ? nil : [operands arrayByAddingObject:inputBitInterpretationValue];
      if (!newOperands)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      else
        result = [[self combineFromRawValue:newOperands token:token context:context] retain];
    }
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineFromU16:token:context:

+(CHChalkValue*) combineFromS16:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    chalk_bit_interpretation_t inputBitInterpretation = {0};
    inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
    inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_INTEGER_STANDARD;
    inputBitInterpretation.numberEncoding.encodingVariant.integerStandardVariantEncoding = CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_16S;
    inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.significandCustomBitsCount = getSignificandBitsCountForEncoding(inputBitInterpretation.numberEncoding, NO);
    @autoreleasepool {
      NSValue* inputBitInterpretationValue = [NSValue valueWithBytes:&inputBitInterpretation objCType:@encode(chalk_bit_interpretation_t)];
      NSArray* newOperands = !inputBitInterpretationValue ? nil : [operands arrayByAddingObject:inputBitInterpretationValue];
      if (!newOperands)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      else
        result = [[self combineFromRawValue:newOperands token:token context:context] retain];
    }
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineFromS16:token:context:

+(CHChalkValue*) combineFromU32:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    chalk_bit_interpretation_t inputBitInterpretation = {0};
    inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
    inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_INTEGER_STANDARD;
    inputBitInterpretation.numberEncoding.encodingVariant.integerStandardVariantEncoding = CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_32U;
    inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.significandCustomBitsCount = getSignificandBitsCountForEncoding(inputBitInterpretation.numberEncoding, NO);
    @autoreleasepool {
      NSValue* inputBitInterpretationValue = [NSValue valueWithBytes:&inputBitInterpretation objCType:@encode(chalk_bit_interpretation_t)];
      NSArray* newOperands = !inputBitInterpretationValue ? nil : [operands arrayByAddingObject:inputBitInterpretationValue];
      if (!newOperands)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      else
        result = [[self combineFromRawValue:newOperands token:token context:context] retain];
    }
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineFromU32:token:context:

+(CHChalkValue*) combineFromS32:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    chalk_bit_interpretation_t inputBitInterpretation = {0};
    inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
    inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_INTEGER_STANDARD;
    inputBitInterpretation.numberEncoding.encodingVariant.integerStandardVariantEncoding = CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_32S;
    inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.significandCustomBitsCount = getSignificandBitsCountForEncoding(inputBitInterpretation.numberEncoding, NO);
    @autoreleasepool {
      NSValue* inputBitInterpretationValue = [NSValue valueWithBytes:&inputBitInterpretation objCType:@encode(chalk_bit_interpretation_t)];
      NSArray* newOperands = !inputBitInterpretationValue ? nil : [operands arrayByAddingObject:inputBitInterpretationValue];
      if (!newOperands)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      else
        result = [[self combineFromRawValue:newOperands token:token context:context] retain];
    }
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineFromS32:token:context:

+(CHChalkValue*) combineFromU64:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    chalk_bit_interpretation_t inputBitInterpretation = {0};
    inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
    inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_INTEGER_STANDARD;
    inputBitInterpretation.numberEncoding.encodingVariant.integerStandardVariantEncoding = CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_64U;
    inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.significandCustomBitsCount = getSignificandBitsCountForEncoding(inputBitInterpretation.numberEncoding, NO);
    @autoreleasepool {
      NSValue* inputBitInterpretationValue = [NSValue valueWithBytes:&inputBitInterpretation objCType:@encode(chalk_bit_interpretation_t)];
      NSArray* newOperands = !inputBitInterpretationValue ? nil : [operands arrayByAddingObject:inputBitInterpretationValue];
      if (!newOperands)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      else
        result = [[self combineFromRawValue:newOperands token:token context:context] retain];
    }
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineFromU64:token:context:

+(CHChalkValue*) combineFromS64:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    chalk_bit_interpretation_t inputBitInterpretation = {0};
    inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
    inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_INTEGER_STANDARD;
    inputBitInterpretation.numberEncoding.encodingVariant.integerStandardVariantEncoding = CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_64S;
    inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.significandCustomBitsCount = getSignificandBitsCountForEncoding(inputBitInterpretation.numberEncoding, NO);
    @autoreleasepool {
      NSValue* inputBitInterpretationValue = [NSValue valueWithBytes:&inputBitInterpretation objCType:@encode(chalk_bit_interpretation_t)];
      NSArray* newOperands = !inputBitInterpretationValue ? nil : [operands arrayByAddingObject:inputBitInterpretationValue];
      if (!newOperands)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      else
        result = [[self combineFromRawValue:newOperands token:token context:context] retain];
    }
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineFromS64:token:context:

+(CHChalkValue*) combineFromU128:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    chalk_bit_interpretation_t inputBitInterpretation = {0};
    inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
    inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_INTEGER_STANDARD;
    inputBitInterpretation.numberEncoding.encodingVariant.integerStandardVariantEncoding = CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_128U;
    inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.significandCustomBitsCount = getSignificandBitsCountForEncoding(inputBitInterpretation.numberEncoding, NO);
    @autoreleasepool {
      NSValue* inputBitInterpretationValue = [NSValue valueWithBytes:&inputBitInterpretation objCType:@encode(chalk_bit_interpretation_t)];
      NSArray* newOperands = !inputBitInterpretationValue ? nil : [operands arrayByAddingObject:inputBitInterpretationValue];
      if (!newOperands)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      else
        result = [[self combineFromRawValue:newOperands token:token context:context] retain];
    }
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineFromU128:token:context:

+(CHChalkValue*) combineFromS128:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    chalk_bit_interpretation_t inputBitInterpretation = {0};
    inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
    inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_INTEGER_STANDARD;
    inputBitInterpretation.numberEncoding.encodingVariant.integerStandardVariantEncoding = CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_128S;
    inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.significandCustomBitsCount = getSignificandBitsCountForEncoding(inputBitInterpretation.numberEncoding, NO);
    @autoreleasepool {
      NSValue* inputBitInterpretationValue = [NSValue valueWithBytes:&inputBitInterpretation objCType:@encode(chalk_bit_interpretation_t)];
      NSArray* newOperands = !inputBitInterpretationValue ? nil : [operands arrayByAddingObject:inputBitInterpretationValue];
      if (!newOperands)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      else
        result = [[self combineFromRawValue:newOperands token:token context:context] retain];
    }
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineFromS128:token:context:

+(CHChalkValue*) combineFromU256:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    chalk_bit_interpretation_t inputBitInterpretation = {0};
    inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
    inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_INTEGER_STANDARD;
    inputBitInterpretation.numberEncoding.encodingVariant.integerStandardVariantEncoding = CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_256U;
    inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.significandCustomBitsCount = getSignificandBitsCountForEncoding(inputBitInterpretation.numberEncoding, NO);
    @autoreleasepool {
      NSValue* inputBitInterpretationValue = [NSValue valueWithBytes:&inputBitInterpretation objCType:@encode(chalk_bit_interpretation_t)];
      NSArray* newOperands = !inputBitInterpretationValue ? nil : [operands arrayByAddingObject:inputBitInterpretationValue];
      if (!newOperands)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      else
        result = [[self combineFromRawValue:newOperands token:token context:context] retain];
    }
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineFromU256:token:context:

+(CHChalkValue*) combineFromS256:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    chalk_bit_interpretation_t inputBitInterpretation = {0};
    inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
    inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_INTEGER_STANDARD;
    inputBitInterpretation.numberEncoding.encodingVariant.integerStandardVariantEncoding = CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_256S;
    inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.significandCustomBitsCount = getSignificandBitsCountForEncoding(inputBitInterpretation.numberEncoding, NO);
    @autoreleasepool {
      NSValue* inputBitInterpretationValue = [NSValue valueWithBytes:&inputBitInterpretation objCType:@encode(chalk_bit_interpretation_t)];
      NSArray* newOperands = !inputBitInterpretationValue ? nil : [operands arrayByAddingObject:inputBitInterpretationValue];
      if (!newOperands)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      else
        result = [[self combineFromRawValue:newOperands token:token context:context] retain];
    }
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineFromS256:token:context:

+(CHChalkValue*) combineFromUCustom:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 2)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 2)
  {
    id operand1 = [operands objectAtIndex:0];
    CHChalkValue* operand2Value = [[operands objectAtIndex:1] dynamicCastToClass:[CHChalkValue class]];
    CHChalkValueNumberGmp* operand2GmpValue = [operand2Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
    const chalk_gmp_value_t* operand2Gmp = operand2GmpValue.valueConstReference;
    NSUInteger operand2UInteger = !operand2Gmp || (operand2Gmp->type != CHALK_VALUE_TYPE_INTEGER) || !mpz_fits_nsui_p(operand2Gmp->integer) ? 0 : mpz_get_nssi(operand2Gmp->integer);
    chalk_bit_interpretation_t inputBitInterpretation = {0};
    inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
    inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_INTEGER_CUSTOM;
    inputBitInterpretation.numberEncoding.encodingVariant.integerCustomVariantEncoding = CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_SIGNED;
    inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    NSUInteger minimumBitsRequired = inputBitInterpretation.signCustomBitsCount+inputBitInterpretation.exponentCustomBitsCount+1;
    if (operand2UInteger < minimumBitsRequired)
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                             replace:NO];
    else//if (operand2UInteger >= minimumBitsRequired)
    {
      chalk_bit_interpretation_t inputBitInterpretation = {0};
      inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
      inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_INTEGER_CUSTOM;
      inputBitInterpretation.numberEncoding.encodingVariant.integerCustomVariantEncoding = CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_UNSIGNED;
      inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
      inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
      inputBitInterpretation.significandCustomBitsCount = operand2UInteger-inputBitInterpretation.signCustomBitsCount-inputBitInterpretation.exponentCustomBitsCount;
      @autoreleasepool {
        NSValue* inputBitInterpretationValue = [NSValue valueWithBytes:&inputBitInterpretation objCType:@encode(chalk_bit_interpretation_t)];
        NSArray* newOperands = !inputBitInterpretationValue ? nil : @[operand1, inputBitInterpretationValue];
        if (!newOperands)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                 replace:NO];
        else
          result = [[self combineFromRawValue:newOperands token:token context:context] retain];
      }//end @autoreleasepool
    }//end if (operand2UInteger >= minimumBitsRequired)
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineFromUCustom:token:context:

+(CHChalkValue*) combineFromSCustom:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 2)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 2)
  {
    id operand1 = [operands objectAtIndex:0];
    CHChalkValue* operand2Value = [[operands objectAtIndex:1] dynamicCastToClass:[CHChalkValue class]];
    CHChalkValueNumberGmp* operand2GmpValue = [operand2Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
    const chalk_gmp_value_t* operand2Gmp = operand2GmpValue.valueConstReference;
    NSUInteger operand2UInteger = !operand2Gmp || (operand2Gmp->type != CHALK_VALUE_TYPE_INTEGER) || !mpz_fits_nsui_p(operand2Gmp->integer) ? 0 : mpz_get_nssi(operand2Gmp->integer);
    chalk_bit_interpretation_t inputBitInterpretation = {0};
    inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
    inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_INTEGER_CUSTOM;
    inputBitInterpretation.numberEncoding.encodingVariant.integerCustomVariantEncoding = CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_SIGNED;
    inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    NSUInteger minimumBitsRequired = inputBitInterpretation.signCustomBitsCount+inputBitInterpretation.exponentCustomBitsCount+1;
    if (operand2UInteger < minimumBitsRequired)
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                             replace:NO];
    else//if (operand2UInteger >= minimumBitsRequired)
    {
      chalk_bit_interpretation_t inputBitInterpretation = {0};
      inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
      inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_INTEGER_CUSTOM;
      inputBitInterpretation.numberEncoding.encodingVariant.integerCustomVariantEncoding = CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_SIGNED;
      inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
      inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
      inputBitInterpretation.significandCustomBitsCount = operand2UInteger-inputBitInterpretation.signCustomBitsCount-inputBitInterpretation.exponentCustomBitsCount;
      @autoreleasepool {
        NSValue* inputBitInterpretationValue = [NSValue valueWithBytes:&inputBitInterpretation objCType:@encode(chalk_bit_interpretation_t)];
        NSArray* newOperands = !inputBitInterpretationValue ? nil : @[operand1, inputBitInterpretationValue];
        if (!newOperands)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                 replace:NO];
        else
          result = [[self combineFromRawValue:newOperands token:token context:context] retain];
      }//end @autoreleasepool
    }//end if (operand2UInteger >= minimumBitsRequired)
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineFromSCustom:token:context:

+(CHChalkValue*) combineFromChalkInteger:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    chalk_bit_interpretation_t inputBitInterpretation = {0};
    inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
    inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_GMP_CUSTOM;
    inputBitInterpretation.numberEncoding.encodingVariant.gmpCustomVariantEncoding = CHALK_NUMBER_ENCODING_GMP_CUSTOM_VARIANT_Z;
    inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.significandCustomBitsCount = context.computationConfiguration.softIntegerMaxBits;
    @autoreleasepool {
      NSValue* inputBitInterpretationValue = [NSValue valueWithBytes:&inputBitInterpretation objCType:@encode(chalk_bit_interpretation_t)];
      NSArray* newOperands = !inputBitInterpretationValue ? nil : [operands arrayByAddingObject:inputBitInterpretationValue];
      if (!newOperands)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      else
        result = [[self combineFromRawValue:newOperands token:token context:context] retain];
    }
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineFromChalkInteger:token:context:

+(CHChalkValue*) combineFromF16:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    chalk_bit_interpretation_t inputBitInterpretation = {0};
    inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
    inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_IEEE754_STANDARD;
    inputBitInterpretation.numberEncoding.encodingVariant.ieee754StandardVariantEncoding = CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_HALF;
    inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.significandCustomBitsCount = getSignificandBitsCountForEncoding(inputBitInterpretation.numberEncoding, NO);
    @autoreleasepool {
      NSValue* inputBitInterpretationValue = [NSValue valueWithBytes:&inputBitInterpretation objCType:@encode(chalk_bit_interpretation_t)];
      NSArray* newOperands = !inputBitInterpretationValue ? nil : [operands arrayByAddingObject:inputBitInterpretationValue];
      if (!newOperands)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      else
        result = [[self combineFromRawValue:newOperands token:token context:context] retain];
    }
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineFromF16:token:context:

+(CHChalkValue*) combineFromF32:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    chalk_bit_interpretation_t inputBitInterpretation = {0};
    inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
    inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_IEEE754_STANDARD;
    inputBitInterpretation.numberEncoding.encodingVariant.ieee754StandardVariantEncoding = CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_SINGLE;
    inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.significandCustomBitsCount = getSignificandBitsCountForEncoding(inputBitInterpretation.numberEncoding, NO);
    @autoreleasepool {
      NSValue* inputBitInterpretationValue = [NSValue valueWithBytes:&inputBitInterpretation objCType:@encode(chalk_bit_interpretation_t)];
      NSArray* newOperands = !inputBitInterpretationValue ? nil : [operands arrayByAddingObject:inputBitInterpretationValue];
      if (!newOperands)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      else
        result = [[self combineFromRawValue:newOperands token:token context:context] retain];
    }
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineFromF32:token:context:

+(CHChalkValue*) combineFromF64:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    chalk_bit_interpretation_t inputBitInterpretation = {0};
    inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
    inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_IEEE754_STANDARD;
    inputBitInterpretation.numberEncoding.encodingVariant.ieee754StandardVariantEncoding = CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_DOUBLE;
    inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.significandCustomBitsCount = getSignificandBitsCountForEncoding(inputBitInterpretation.numberEncoding, NO);
    @autoreleasepool {
      NSValue* inputBitInterpretationValue = [NSValue valueWithBytes:&inputBitInterpretation objCType:@encode(chalk_bit_interpretation_t)];
      NSArray* newOperands = !inputBitInterpretationValue ? nil : [operands arrayByAddingObject:inputBitInterpretationValue];
      if (!newOperands)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      else
        result = [[self combineFromRawValue:newOperands token:token context:context] retain];
    }
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineFromF64:token:context:

+(CHChalkValue*) combineFromF128:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    chalk_bit_interpretation_t inputBitInterpretation = {0};
    inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
    inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_IEEE754_STANDARD;
    inputBitInterpretation.numberEncoding.encodingVariant.ieee754StandardVariantEncoding = CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_QUADRUPLE;
    inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.significandCustomBitsCount = getSignificandBitsCountForEncoding(inputBitInterpretation.numberEncoding, NO);
    @autoreleasepool {
      NSValue* inputBitInterpretationValue = [NSValue valueWithBytes:&inputBitInterpretation objCType:@encode(chalk_bit_interpretation_t)];
      NSArray* newOperands = !inputBitInterpretationValue ? nil : [operands arrayByAddingObject:inputBitInterpretationValue];
      if (!newOperands)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      else
        result = [[self combineFromRawValue:newOperands token:token context:context] retain];
    }
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineFromF128:token:context:

+(CHChalkValue*) combineFromF256:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    chalk_bit_interpretation_t inputBitInterpretation = {0};
    inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
    inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_IEEE754_STANDARD;
    inputBitInterpretation.numberEncoding.encodingVariant.ieee754StandardVariantEncoding = CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_OCTUPLE;
    inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.significandCustomBitsCount = getSignificandBitsCountForEncoding(inputBitInterpretation.numberEncoding, NO);
    @autoreleasepool {
      NSValue* inputBitInterpretationValue = [NSValue valueWithBytes:&inputBitInterpretation objCType:@encode(chalk_bit_interpretation_t)];
      NSArray* newOperands = !inputBitInterpretationValue ? nil : [operands arrayByAddingObject:inputBitInterpretationValue];
      if (!newOperands)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      else
        result = [[self combineFromRawValue:newOperands token:token context:context] retain];
    }
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineFromF256:token:context:

+(CHChalkValue*) combineFromChalkFloat:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    chalk_bit_interpretation_t inputBitInterpretation = {0};
    inputBitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
    inputBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_GMP_CUSTOM;
    inputBitInterpretation.numberEncoding.encodingVariant.gmpCustomVariantEncoding = CHALK_NUMBER_ENCODING_GMP_CUSTOM_VARIANT_FR;
    inputBitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(inputBitInterpretation.numberEncoding);
    inputBitInterpretation.significandCustomBitsCount = context.computationConfiguration.softFloatSignificandBits;
    @autoreleasepool {
      NSValue* inputBitInterpretationValue = [NSValue valueWithBytes:&inputBitInterpretation objCType:@encode(chalk_bit_interpretation_t)];
      NSArray* newOperands = !inputBitInterpretationValue ? nil : [operands arrayByAddingObject:inputBitInterpretationValue];
      if (!newOperands)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                               replace:NO];
      else
        result = [[self combineFromRawValue:newOperands token:token context:context] retain];
    }
  }//end if (operands.count == 1)
  return [result autorelease];
}
//end combineFromChalkFloat:token:context:

+(CHChalkValue*) combineFromRawValue:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 2)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 2)
  {
    @autoreleasepool {
      CHChalkValue* operand1Value = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueNumberRaw* operand1Raw = [operand1Value dynamicCastToClass:[CHChalkValueNumberRaw class]];
      CHChalkValueList* operand1List = [operand1Value dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValueMatrix* operand1Matrix = [operand1Value dynamicCastToClass:[CHChalkValueMatrix class]];
      NSValue* operand2Value = [[operands objectAtIndex:1] dynamicCastToClass:[NSValue class]];
      if (operand1List)
        result = [[self combineSEL:_cmd arguments:operands list:operand1List index:0 token:token context:context] retain];
      else if (operand1Matrix)
      {
        CHChalkValueMatrix* newMatrix = [[self combineMatrixSEL:_cmd operand:operand1Matrix token:token context:context] retain];
        if (context.errorContext.hasError)
        {
          [newMatrix release];
          newMatrix = nil;
        }//end if (context.errorContext.hasError)
        result = newMatrix;
      }//end if (operand1Matrix)
      else if (operand1Raw && operand1Raw.valueConstReference && operand2Value)
      {
        chalk_bit_interpretation_t outputBitInterpretation = {0};
        [operand2Value getValue:&outputBitInterpretation];
        chalk_gmp_value_t gmpValue = {0};
        BOOL done = NO;
        BOOL gmpValueCreated = NO;
        if (getEncodingIsInteger(outputBitInterpretation.numberEncoding))
          gmpValueCreated = chalkGmpValueMakeInteger(&gmpValue, context.gmpPool);
        else
          gmpValueCreated = chalkGmpValueMakeRealApprox(&gmpValue, context.computationConfiguration.softFloatSignificandBits, context.gmpPool);
        if (gmpValueCreated)
        {
          chalk_conversion_result_t conversionResult = interpretFromRawToValue(&gmpValue, operand1Raw.valueConstReference, context.computationConfiguration.computeMode, &outputBitInterpretation, context);
          if (conversionResult.error != CHALK_CONVERSION_ERROR_NOERROR)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:[CHChalkError convertFromConversionError:conversionResult.error] range:token.range]
                                   replace:NO];
          else//if (conversionResult.error == CHALK_CONVERSION_ERROR_NOERROR)
          {
            result = [[CHChalkValueNumberGmp alloc] initWithToken:token value:&gmpValue naturalBase:context.computationConfiguration.baseDefault context:context];
            result.evaluationComputeFlags |= conversionResult.computeFlags;
            done |= (result != nil);
            if (!result)
              [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                     replace:NO];
          }//end if (conversionResult.error == CHALK_CONVERSION_ERROR_NOERROR)
          if (!done)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                   replace:NO];
          if (!result)//value has been moved when result is OK
            chalkGmpValueClear(&gmpValue, YES, context.gmpPool);
        }//end if (gmpValueCreated)
      }//if (operand1Raw && operand1Raw.valueConstReference && operand2Value)
      else
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                               replace:NO];
      result.evaluationComputeFlags |=
        operand1Value.evaluationComputeFlags |
        chalkGmpFlagsMake();
    }//end @autoreleasepool
  }//end if (operands.count == 2)
  return [result autorelease];
}
//end combineFromRawValue:token:context:

+(CHChalkValue*) combineShift:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 2)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 2)
  {
    @autoreleasepool {
      CHChalkValue* operand1Value = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueList* operand1List = [operand1Value dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValue* operand2Value = [[operands objectAtIndex:1] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueList* operand2List = [operand2Value dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValueNumberGmp* operand2Gmp = [[operands objectAtIndex:1] dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueNumberRaw* operand2Raw = [[operands objectAtIndex:1] dynamicCastToClass:[CHChalkValueNumberRaw class]];
      if (operand1List)
        result = [[self combineSEL:_cmd arguments:operands list:operand1List index:0 token:token context:context] retain];
      else if (operand2List)
        result = [[self combineSEL:_cmd arguments:operands list:operand2List index:1 token:token context:context] retain];
      else if (operand2Gmp || operand2Raw)
      {
        if (operand2Raw)
          operand2Gmp = [operand2Raw convertToGmpValueWithContext:context];
        const chalk_gmp_value_t* operand2GmpValue = operand2Gmp.valueConstReference;
        int sgn = chalkGmpValueSign(operand2GmpValue);
        if (sgn >= 0)
          result = [[CHParserOperatorNode combineShl:@[operand1Value, operand2Gmp] operatorToken:token context:context] retain];
        else//if (sgn < 0)
          result = [[CHParserOperatorNode combineShr:@[operand1Value, operand2Gmp] operatorToken:token context:context] retain];
      }//end if (operand2Gmp || operand2Raw)
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
//end combineShift:token:context:

+(CHChalkValue*) combineRoll:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 2)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 2)
  {
    @autoreleasepool {
      CHChalkValue* operand1Value = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueList* operand1List = [operand1Value dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValue* operand2Value = [[operands objectAtIndex:1] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueList* operand2List = [operand2Value dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValueNumberRaw* operand1Raw = [operand1Value dynamicCastToClass:[CHChalkValueNumberRaw class]];
      CHChalkValueNumberGmp* operand2Gmp = [operand2Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueNumberRaw* operand2Raw = [operand2Value dynamicCastToClass:[CHChalkValueNumberRaw class]];
      if (operand1List)
        result = [[self combineSEL:_cmd arguments:operands list:operand1List index:0 token:token context:context] retain];
      else if (operand2List)
        result = [[self combineSEL:_cmd arguments:operands list:operand2List index:1 token:token context:context] retain];
      else if (operand1Raw && (operand2Gmp || operand2Raw))
      {
        if (operand2Raw)
          operand2Gmp = [operand2Raw convertToGmpValueWithContext:context];
        const chalk_gmp_value_t* operand2GmpValue = operand2Gmp.valueConstReference;
        if (operand2GmpValue)
        {
          if (operand2GmpValue->type != CHALK_VALUE_TYPE_INTEGER)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                                   replace:NO];
          else//if (operand2GmpValue->type == CHALK_VALUE_TYPE_INTEGER)
          {
            if (!mpz_fits_nssi_p(operand2GmpValue->integer))
              [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorIntegerOverflow range:token.range]
                                     replace:NO];
            else//if (mpz_fits_nssi_p(operand2GmpValue->integer))
            {
              NSInteger shiftValue = mpz_get_nssi(operand2GmpValue->integer);
              result = [operand1Raw copy];
              //[result.token unionWithToken:token];//experimental
              CHChalkValueNumberRaw* resultRaw = [result dynamicCastToClass:[CHChalkValueNumberRaw class]];
              chalk_raw_value_t* resultRawValue = resultRaw.valueReference;
              NSUInteger bitsCount = !resultRawValue ? 0 :
                getTotalBitsCountForBitInterpretation(&resultRawValue->bitInterpretation);
              shiftValue = !bitsCount ? shiftValue : (shiftValue%bitsCount);
              if (!result)
                [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                       replace:NO];
              else if (!resultRawValue)
                [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                       replace:NO];
              else if (shiftValue>=0)
                mpz_roll_left(resultRawValue->bits, shiftValue, getTotalBitsRangeForBitInterpretation(&resultRawValue->bitInterpretation));
              else if (shiftValue<0)
                mpz_roll_right(resultRawValue->bits, -shiftValue, getTotalBitsRangeForBitInterpretation(&resultRawValue->bitInterpretation));
              else
                [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                                       replace:NO];
            }//end if (mpz_fits_nssi_p(operand2GmpValue->integer))
          }//end if (operand2GmpValue->type == CHALK_VALUE_TYPE_INTEGER)
        }//end if (operand2GmpValue)
        else//if (!operand2GmpValue)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                                 replace:NO];
      }//end if (operand1Raw && (operand2Gmp || operand2Raw))
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
//end combineRoll:token:context:

+(CHChalkValue*) combineBitsSwap:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 2)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 2)
  {
    @autoreleasepool {
      CHChalkValue* operand1Value = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueList* operand1List = [operand1Value dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValue* operand2Value = [[operands objectAtIndex:1] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueList* operand2List = [operand2Value dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValueNumberRaw* operand1Raw = [operand1Value dynamicCastToClass:[CHChalkValueNumberRaw class]];
      CHChalkValueNumberGmp* operand2Gmp = [operand2Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValueNumberRaw* operand2Raw = [operand2Value dynamicCastToClass:[CHChalkValueNumberRaw class]];
      if (operand1List)
        result = [[self combineSEL:_cmd arguments:operands list:operand1List index:0 token:token context:context] retain];
      else if (operand2List)
        result = [[self combineSEL:_cmd arguments:operands list:operand2List index:1 token:token context:context] retain];
      else if (operand1Raw && (operand2Gmp || operand2Raw))
      {
        if (operand2Raw)
          operand2Gmp = [operand2Raw convertToGmpValueWithContext:context];
        const chalk_gmp_value_t* operand2GmpValue = operand2Gmp.valueConstReference;
        if (operand2GmpValue)
        {
          if (operand2GmpValue->type != CHALK_VALUE_TYPE_INTEGER)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                                   replace:NO];
          else//if (operand2GmpValue->type == CHALK_VALUE_TYPE_INTEGER)
          {
            if (!mpz_fits_nssi_p(operand2GmpValue->integer))
              [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorIntegerOverflow range:token.range]
                                     replace:NO];
            else//if (mpz_fits_nssi_p(operand2GmpValue->integer))
            {
              NSInteger packetBitSize = mpz_get_nssi(operand2GmpValue->integer);
              result = [operand1Raw copy];
              //[result.token unionWithToken:token];//experimental
              CHChalkValueNumberRaw* resultRaw = [result dynamicCastToClass:[CHChalkValueNumberRaw class]];
              chalk_raw_value_t* resultRawValue = resultRaw.valueReference;
              if (!result)
                [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                       replace:NO];
              else if (!resultRawValue)
                [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                                       replace:NO];
              else if (packetBitSize>=0)
                mpz_swap_packets_pairs(resultRawValue->bits, packetBitSize, getTotalBitsRangeForBitInterpretation(&resultRawValue->bitInterpretation));
              else if (packetBitSize<0)
                [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                                       replace:NO];
              else
                [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                                       replace:NO];
            }//end if (mpz_fits_nssi_p(operand2GmpValue->integer))
          }//end if (operand2GmpValue->type == CHALK_VALUE_TYPE_INTEGER)
        }//end if (operand2GmpValue)
        else//if (!operand2GmpValue)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:token.range]
                                 replace:NO];
      }//end if (operand1Raw && (operand2Gmp || operand2Raw))
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
//end combineBitsSwap:token:context:

+(CHChalkValue*) combineBitsReverse:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (operands.count != 1)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if (operands.count == 1)
  {
    @autoreleasepool {
      CHChalkValue* operand1Value = [[operands objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueList* operand1List = [operand1Value dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValueNumberRaw* operand1Raw = [operand1Value dynamicCastToClass:[CHChalkValueNumberRaw class]];
      if (operand1List)
        result = [[self combineSEL:_cmd arguments:operands list:operand1List index:0 token:token context:context] retain];
      else if (operand1Raw)
      {
        CHChalkValueNumberRaw* clone = [operand1Raw copy];
        //[clone.token unionWithToken:token];//experimental
        if (!clone)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation] replace:NO];
        chalk_raw_value_t* rawValue = clone.valueReference;
        if (rawValue)
          chalkRawValueReverseBits(rawValue, getTotalBitsRangeForBitInterpretation(&rawValue->bitInterpretation));
        result = clone;
        result.evaluationComputeFlags |=
          operand1Value.evaluationComputeFlags |
          chalkGmpFlagsMake();
      }//end if (operand1Raw)
    }//end @autoreleasepool
  }//end if (operands.count == 2)
  return [result autorelease];
}
//end combineBitsReverse:token:context:

+(CHChalkValue*) combineBitsConcatLE:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  NSUInteger bitsCount = 0;
  NSMutableArray* stack = [NSMutableArray arrayWithArray:operands];
  NSMutableArray* operandsRaw = [NSMutableArray arrayWithCapacity:operands.count];
  while(!context.errorContext.hasError && (stack.count > 0))
  {
    id operand = [stack objectAtIndex:0];
    [stack removeObjectAtIndex:0];
    CHChalkValue* operandValue = [operand dynamicCastToClass:[CHChalkValue class]];
    CHChalkValueEnumeration* operandEnumeration = [operand dynamicCastToClass:[CHChalkValueEnumeration class]];
    CHChalkValueNumberRaw* operandRaw = [operand dynamicCastToClass:[CHChalkValueNumberRaw class]];
    if (operandEnumeration)
      [stack addObjectsFromArray:operandEnumeration.values];
    else if (operandRaw)
    {
      const chalk_raw_value_t* rawValue = operandRaw.valueConstReference;
      NSUInteger operandBitsCount = getTotalBitsCountForBitInterpretation(&rawValue->bitInterpretation);
      bitsCount += operandBitsCount;
      //bitsCount = [operandsRaw.r
      [operandsRaw addObject:operandRaw];
    }//end if (operandRaw)
    else
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:!operandValue ? token.range : operandValue.token.range] replace:NO];
  }//end for each operand
  if (!context.errorContext.hasError)
  {
    chalk_raw_value_t rawValue = {0};
    BOOL ok = chalkRawValueCreate(&rawValue, context.gmpPool);
    if (!ok)
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation] replace:NO];
    else//if (ok)
    {
      rawValue.bitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
      rawValue.bitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_INTEGER_CUSTOM;
      rawValue.bitInterpretation.numberEncoding.encodingVariant.integerCustomVariantEncoding = CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_UNSIGNED;
      rawValue.bitInterpretation.signCustomBitsCount = 0;
      rawValue.bitInterpretation.exponentCustomBitsCount = 0;
      rawValue.bitInterpretation.significandCustomBitsCount = bitsCount;
      mp_bitcnt_t dstIndex = 0;
      NSUInteger naturalBase = NSNotFound;
      chalk_compute_flags_t computeFlags = CHALK_COMPUTE_FLAG_NONE;
      for(CHChalkValueNumberRaw* operandRaw in operandsRaw)
      {
        naturalBase = MIN(naturalBase, operandRaw.naturalBase);
        const chalk_raw_value_t* operandRawValue = operandRaw.valueConstReference;
        const mp_limb_t* src = !operandRawValue ? 0 : mpz_limbs_read(operandRawValue->bits);
        NSRange srcBitRange = NSMakeRange(0, getTotalBitsCountForBitInterpretation(&operandRawValue->bitInterpretation));
        BOOL error = NO;
        if (src && operandRawValue)
          mpz_copyBits(rawValue.bits, dstIndex, src, mpz_size(operandRawValue->bits), srcBitRange, &error);
        dstIndex += srcBitRange.length;
        if (error)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown] replace:NO];
        computeFlags |= operandRaw.evaluationComputeFlags;
        if (context.errorContext.hasError)
          break;
      }//end for each operandRaw
      if (naturalBase == NSNotFound)
        naturalBase = 2;
      result = [[CHChalkValueNumberRaw alloc] initWithToken:token value:&rawValue naturalBase:(int)naturalBase context:context];
      if (!result)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation] replace:NO];
      if (!result)
        chalkRawValueClear(&rawValue, YES, context.gmpPool);
      result.evaluationComputeFlags |=
        computeFlags |
        chalkGmpFlagsMake();
    }//end if (ok)
  }//end if (!context.errorContext.hasError)
  return [result autorelease];
}
//end combineBitsConcatLE:token:context:

+(CHChalkValue*) combineBitsConcatBE:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  NSUInteger bitsCount = 0;
  NSMutableArray* stack = [NSMutableArray arrayWithArray:operands];
  NSMutableArray* operandsRaw = [NSMutableArray arrayWithCapacity:operands.count];
  while(!context.errorContext.hasError && (stack.count > 0))
  {
    id operand = [stack objectAtIndex:0];
    [stack removeObjectAtIndex:0];
    CHChalkValue* operandValue = [operand dynamicCastToClass:[CHChalkValue class]];
    CHChalkValueEnumeration* operandEnumeration = [operand dynamicCastToClass:[CHChalkValueEnumeration class]];
    CHChalkValueNumberRaw* operandRaw = [operand dynamicCastToClass:[CHChalkValueNumberRaw class]];
    if (operandEnumeration)
      [stack addObjectsFromArray:operandEnumeration.values];
    else if (operandRaw)
    {
      const chalk_raw_value_t* rawValue = operandRaw.valueConstReference;
      NSUInteger operandBitsCount = getTotalBitsCountForBitInterpretation(&rawValue->bitInterpretation);
      bitsCount += operandBitsCount;
      //bitsCount = [operandsRaw.r
      [operandsRaw addObject:operandRaw];
    }//end if (operandRaw)
    else
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:!operandValue ? token.range : operandValue.token.range] replace:NO];
  }//end for each operand
  if (!context.errorContext.hasError)
  {
    chalk_raw_value_t rawValue = {0};
    BOOL ok = chalkRawValueCreate(&rawValue, context.gmpPool);
    if (!ok)
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation] replace:NO];
    else//if (ok)
    {
      rawValue.bitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
      rawValue.bitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_INTEGER_CUSTOM;
      rawValue.bitInterpretation.numberEncoding.encodingVariant.integerCustomVariantEncoding = CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_UNSIGNED;
      rawValue.bitInterpretation.signCustomBitsCount = 0;
      rawValue.bitInterpretation.exponentCustomBitsCount = 0;
      rawValue.bitInterpretation.significandCustomBitsCount = bitsCount;
      chalk_raw_value_t* pRawValue = &rawValue;
      __block mp_bitcnt_t dstIndex = 0;
      __block NSUInteger naturalBase = NSNotFound;
      __block chalk_compute_flags_t computeFlags = CHALK_COMPUTE_FLAG_NONE;
      [operandsRaw enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CHChalkValueNumberRaw* operandRaw = [obj dynamicCastToClass:[CHChalkValueNumberRaw class]];
        naturalBase = MIN(naturalBase, operandRaw.naturalBase);
        const chalk_raw_value_t* operandRawValue = operandRaw.valueConstReference;
        const mp_limb_t* src = !operandRawValue ? 0 : mpz_limbs_read(operandRawValue->bits);
        NSRange srcBitRange = NSMakeRange(0, getTotalBitsCountForBitInterpretation(&operandRawValue->bitInterpretation));
        BOOL error = NO;
        if (src && operandRawValue)
          mpz_copyBits(pRawValue->bits, dstIndex, src, mpz_size(operandRawValue->bits), srcBitRange, &error);
        dstIndex += srcBitRange.length;
        if (error)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown] replace:NO];
        computeFlags |= operandRaw.evaluationComputeFlags;
        *stop |= (context.errorContext.hasError);
      }];
      if (naturalBase == NSNotFound)
        naturalBase = 2;
      result = [[CHChalkValueNumberRaw alloc] initWithToken:token value:&rawValue naturalBase:(int)naturalBase context:context];
      if (!result)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation] replace:NO];
      if (!result)
        chalkRawValueClear(&rawValue, YES, context.gmpPool);
      result.evaluationComputeFlags |=
        computeFlags;
        chalkGmpFlagsMake();
    }//end if (ok)
  }//end if (!context.errorContext.hasError)
  return [result autorelease];
}
//end combineBitsConcatBE:token:context:

+(CHChalkValue*) combineGolombRiceDecode:(NSArray *)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if ((operands.count < 1) || (operands.count > 2))
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if ((operands.count >= 1) && (operands.count <= 2))
  {
    @autoreleasepool {
      chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(NO);
      BOOL missingBits = NO;
      id operand1 = (operands.count <= 0) ? nil : [operands objectAtIndex:0];
      id operand2 = (operands.count <= 1) ? nil : [operands objectAtIndex:1];
      CHChalkValue* operand1Value = [operand1 dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueList* operand1List = [operand1Value dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValueNumberRaw* operand1Raw = [operand1Value dynamicCastToClass:[CHChalkValueNumberRaw class]];
      const chalk_raw_value_t* operand1RawValue = operand1Raw.valueConstReference;
      CHChalkValue* operand2Value = [operand2 dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueList* operand2List = [operand2Value dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValueNumberGmp* operand2Gmp = [operand2Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
      const chalk_gmp_value_t* operand2GmpValue = operand2Gmp.valueConstReference;
      if (operand1List)
        result = [[self combineSEL:_cmd arguments:operands list:operand1List index:0 token:token context:context] retain];
      else if (operand2List)
        result = [[self combineSEL:_cmd arguments:operands list:operand2List index:1 token:token context:context] retain];
      else if (operand2 && (!operand2GmpValue || (operand2GmpValue->type != CHALK_VALUE_TYPE_INTEGER) ||
               (mpz_sgn(operand2GmpValue->integer) < 0) || !mpz_fits_nsui_p(operand2GmpValue->integer)))
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:operand2Value.token.range]
                               replace:NO];
      else if (!operand1RawValue)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:operand1Value.token.range]
                               replace:NO];
      else//if (operand1RawValue)
      {
        CHChalkValueList* valueList = [[[CHChalkValueList alloc] initWithToken:[CHChalkToken chalkTokenEmpty] context:context] autorelease];
        if (!valueList)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                 replace:NO];
        NSUInteger rice = !operand2GmpValue ? 0 : mpz_get_nsui(operand2GmpValue->integer);
        NSUInteger maxRice = ((NSUInteger)1)<<(8U*sizeof(NSUInteger)-1U);
        if (rice > maxRice)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:operand2Value.token.range]
                                 replace:NO];
        else//if (rice <= maxRice)
        {
          BOOL       isRicePowerOfTwo = isPowerOfTwo(rice);
          NSUInteger riceInf = prevPowerOfTwo(rice, NO);
          NSUInteger riceSup = nextPowerOfTwo(rice, NO);
          NSUInteger k = getPowerOfTwo(riceInf);
          NSUInteger u = riceSup-rice;
        
          mp_bitcnt_t endBitIndex = context.errorContext.hasError ? 0 : mpz_sizeinbase(operand1RawValue->bits, 2);
          NSUInteger cumul = 0;
          mpz_t riceZ;
          mpz_t riceOffsetZ;
          mpz_t riceValueZ;
          mpz_t riceFactorZ;
          mpzDepool(riceZ, context.gmpPool);
          mpzDepool(riceOffsetZ, context.gmpPool);
          mpzDepool(riceValueZ, context.gmpPool);
          mpzDepool(riceFactorZ, context.gmpPool);
          mpz_set_ui(riceZ, 0);
          mpz_set_ui(riceOffsetZ, 0);
          mpz_set_ui(riceValueZ, 0);
          mpz_set_nsui(riceFactorZ, rice);
          while(endBitIndex--)
          {
            BOOL bit = mpz_tstbit(operand1RawValue->bits, endBitIndex);
            if (bit)
              ++cumul;
            else//if (!bit)
            {
              if (!rice)
              {
                CHChalkValueNumberGmp* number = [[CHChalkValueNumberGmp alloc] initWithToken:valueList.token uinteger:cumul naturalBase:valueList.naturalBase context:context];
                [valueList addValue:number];
                if (!number)
                  [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                         replace:NO];
                [number release];
              }//end if (!rice)
              else//if (rice)
              {
                mpz_set_ui(riceZ, 0);
                NSUInteger riceToRead = k;
                missingBits |= (endBitIndex<k);
                while(riceToRead--)
                {
                  mpz_mul_2exp(riceZ, riceZ, 1);
                  mpz_changeBit(riceZ, 0, !endBitIndex ? NO : mpz_tstbit(operand1RawValue->bits, --endBitIndex));
                }//end while(riceToRead--)
                if (!isRicePowerOfTwo && (mpz_cmp_ui(riceZ, u)>=0))
                {
                  mpz_set_nsui(riceOffsetZ, u);
                  riceToRead = 1;
                  missingBits |= (endBitIndex<1);
                  while(riceToRead--)
                  {
                    mpz_mul_2exp(riceZ, riceZ, 1);
                    mpz_changeBit(riceZ, 0, !endBitIndex ? NO : mpz_tstbit(operand1RawValue->bits, --endBitIndex));
                  }//end while(riceToRead--)
                }//end if (!isRicePowerOfTwo && (mpz_cmp_ui(riceZ, u)>=0))
                chalk_gmp_value_t riceValue = {0};
                if (chalkGmpValueMakeInteger(&riceValue, context.gmpPool))
                  mpz_sub(riceValueZ, riceZ, riceOffsetZ);

                chalk_gmp_value_t value = {0};
                BOOL ok = chalkGmpValueMakeInteger(&value, context.gmpPool);
                if (ok)
                {
                  mpz_set_nsui(value.integer, cumul);
                  if (rice)
                  {
                    mpz_mul(value.integer, value.integer, riceFactorZ);
                    mpz_add(value.integer, value.integer, riceValueZ);
                  }//end if (rice)
                  CHChalkValueNumberGmp* number = [[CHChalkValueNumberGmp alloc] initWithToken:valueList.token value:&value naturalBase:valueList.naturalBase context:context];
                  if (!number)
                    chalkGmpValueClear(&value, YES, context.gmpPool);
                  ok &= [valueList addValue:number];
                  [number release];
                }//end if (ok)
                if (!ok)
                  [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                         replace:NO];
              }//end if (rice)
              cumul = 0;
              if (context.errorContext.hasError)
                break;
            }//end if (!bit)
          }//end while(endBitIndex--)
          if (cumul && !context.errorContext.hasError)
          {
            CHChalkValueNumberGmp* number = [[CHChalkValueNumberGmp alloc] initWithToken:valueList.token uinteger:cumul naturalBase:valueList.naturalBase context:context];
            [valueList addValue:number];
            if (!number)
              [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                     replace:NO];
            [number release];
          }//end if (cumul && !context.errorContext.hasError)
          mpzRepool(riceZ, context.gmpPool);
          mpzRepool(riceOffsetZ, context.gmpPool);
          mpzRepool(riceValueZ, context.gmpPool);
          mpzRepool(riceFactorZ, context.gmpPool);
          result = [valueList retain];
        }//end if (rice <= maxRice)
        result.evaluationComputeFlags |=
          (missingBits ? CHALK_COMPUTE_FLAG_INEXACT : CHALK_COMPUTE_FLAG_NONE) |
          operand1Value.evaluationComputeFlags |
          operand2Value.evaluationComputeFlags |
          chalkGmpFlagsMake();
      }//end if (operand1Raw)
      chalkGmpFlagsRestore(oldFlags);
    }//end @autoreleasepool
  }//end if (operands.count == 2)
  return [result autorelease];
}
//end combineGolombRiceDecode:token:context:

+(CHChalkValue*) combineGolombRiceEncode:(NSArray *)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if ((operands.count < 1) || (operands.count > 2))
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:token.range]
                           replace:NO];
  else//if ((operands.count >= 1) && (operands.count <= 2))
  {
    @autoreleasepool {
      chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(NO);
      BOOL missingBits = NO;
      id operand1 = (operands.count <= 0) ? nil : [operands objectAtIndex:0];
      id operand2 = (operands.count <= 1) ? nil : [operands objectAtIndex:1];
      CHChalkValue* operand1Value = [operand1 dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueList* operand1List = [operand1Value dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValueNumberRaw* operand1Raw = [operand1Value dynamicCastToClass:[CHChalkValueNumberRaw class]];
      CHChalkValueNumberGmp* operand1Gmp = [operand1Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
      CHChalkValue* operand2Value = [operand2 dynamicCastToClass:[CHChalkValue class]];
      CHChalkValueList* operand2List = [operand2Value dynamicCastToClass:[CHChalkValueList class]];
      CHChalkValueNumberGmp* operand2Gmp = [operand2Value dynamicCastToClass:[CHChalkValueNumberGmp class]];
      const chalk_gmp_value_t* operand2GmpValue = operand2Gmp.valueConstReference;
      if (operand2List)
        result = [[self combineSEL:_cmd arguments:operands list:operand2List index:1 token:token context:context] retain];
      else if (operand2 && (!operand2GmpValue || (operand2GmpValue->type != CHALK_VALUE_TYPE_INTEGER) ||
               (mpz_sgn(operand2GmpValue->integer) < 0) || !mpz_fits_nsui_p(operand2GmpValue->integer)))
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:operand2Value.token.range]
                               replace:NO];
      else if (!operand1List && !operand1Raw && !operand1Gmp)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:operand1Value.token.range]
                               replace:NO];
      else//if (operand1List || operand1Raw || operand1Gmp)
      {
        BOOL overflow = NO;
        BOOL error = NO;

        chalk_raw_value_t outputValue = {0};
        BOOL outputValueInitialized = chalkRawValueCreate(&outputValue, context.gmpPool);
        if (!outputValueInitialized)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                 replace:NO];
        else
          mpz_set_ui(outputValue.bits, 0);
        NSUInteger rice = !operand2GmpValue ? 0 : mpz_get_nsui(operand2GmpValue->integer);
        NSUInteger maxRice = ((NSUInteger)1)<<(8U*sizeof(NSUInteger)-1U);
        if (context.errorContext.hasError){
        }
        else if (rice > maxRice)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:operand2Value.token.range]
                                 replace:NO];
        else//if (rice <= maxRice)
        {
          BOOL       isRicePowerOfTwo = isPowerOfTwo(rice);
          NSUInteger riceInf = prevPowerOfTwo(rice, NO);
          NSUInteger riceSup = nextPowerOfTwo(rice, NO);
          NSUInteger k = getPowerOfTwo(riceInf);
          NSUInteger b = getPowerOfTwo(riceSup);
          //NSUInteger u = riceSup-rice;

          mpz_t divisorZ;
          mpz_t q;
          mpz_t r;
          mpz_t rThreshold;
          mpz_t tmp;
          mpzDepool(divisorZ, context.gmpPool);
          mpzDepool(q, context.gmpPool);
          mpzDepool(r, context.gmpPool);
          mpzDepool(rThreshold, context.gmpPool);
          mpzDepool(tmp, context.gmpPool);
          mpz_set_nsui(divisorZ, rice);
          mpz_set_ui(rThreshold, 1);
          mpz_mul_2exp(rThreshold, rThreshold, b);
          mpz_sub(rThreshold, rThreshold, divisorZ);

          NSArray* valuesToEnumerate =
            operand1Raw ? @[operand1Raw] :
            operand1Gmp ? @[operand1Gmp] :
            operand1List ? operand1List.values :
            nil;
          for(id operand in valuesToEnumerate)
          {
            CHChalkValueNumberGmp* operandGmp = [operand dynamicCastToClass:[CHChalkValueNumberGmp class]];
            CHChalkValueFormal* operandFormal = [operand dynamicCastToClass:[CHChalkValueFormal class]];
            operandGmp = !operandFormal ? operandGmp : operandFormal.value;
            const chalk_gmp_value_t* operandGmpValue = operandGmp.valueConstReference;
            CHChalkValueNumberRaw* operandRaw = [operand dynamicCastToClass:[CHChalkValueNumberRaw class]];
            const chalk_raw_value_t* operandRawValue = operandRaw.valueConstReference;
            mpz_srcptr operandZ =
              operandRawValue ? operandRawValue->bits :
              (operandGmpValue && (operandGmpValue->type == CHALK_VALUE_TYPE_INTEGER)) ? operandGmpValue->integer :
              0;
            if (!operandZ || (mpz_sgn(operandZ)<0))
            {
              [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:operand2Value.token.range]
                                     replace:NO];
               break;
            }//end if (!operandZ || (mpz(sgnoperandZ)<0))
            else//if (!operandZ || (mpz_sgn(operandZ)<0))
            {
              if (mpz_sgn(divisorZ))
                mpz_fdiv_qr(q, r, operandZ, divisorZ);
              else//if (!mpz_sgn(divisorZ))
              {
                mpz_set(q, operandZ);
                mpz_set_si(r, 0);
              }//end if (!mpz_sgn(divisorZ))
              BOOL isRBelowTheshold = (mpz_cmp(r, rThreshold)<0);

              overflow |= !mpz_fits_nsui_p(q);
              NSUInteger shift = mpz_get_nsui(q);
              if (!mpz_sgn(q))
                mpz_set_ui(tmp, 0);
              else//if (mpz_sgn(q))
              {
                mpz_set_ui(tmp, 1);
                mpz_mul_2exp(tmp, tmp, shift);
                mpz_sub_ui(tmp, tmp, 1);
                mpz_mul_2exp(tmp, tmp, 1);//add a 0 to the right
              }//end if (mpz_sgn(q))
              
              size_t currentValueShift = !mpz_sgn(tmp) ? 1 : mpz_sizeinbase(tmp, 2);
              mpz_mul_2exp(outputValue.bits, outputValue.bits, currentValueShift);//add a 0 to the right
              mpz_add(outputValue.bits, outputValue.bits, tmp);
              
              if (rice)
              {
                if (isRicePowerOfTwo || isRBelowTheshold)
                {
                  mpz_mul_2exp(outputValue.bits, outputValue.bits, k);
                  mpz_add(outputValue.bits, outputValue.bits, r);
                }//end if (isRicePowerOfTwo || isRBelowTheshold)
                else//if (!isRBelowTheshold)
                {
                  mpz_mul_2exp(outputValue.bits, outputValue.bits, b);
                  mpz_add(outputValue.bits, outputValue.bits, r);
                  mpz_add(outputValue.bits, outputValue.bits, rThreshold);
                }//end if (!isRBelowTheshold)
              }//end if (rice)
            }//end if (!operandZ || (mpz_sgn(operandZ)<0))
          }//end for each operand
          
          mpzRepool(divisorZ, context.gmpPool);
          mpzRepool(q, context.gmpPool);
          mpzRepool(r, context.gmpPool);
          mpzRepool(rThreshold, context.gmpPool);
          mpzRepool(tmp, context.gmpPool);
          
          outputValue.bitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
          outputValue.bitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_INTEGER_CUSTOM;
          outputValue.bitInterpretation.numberEncoding.encodingVariant.integerCustomVariantEncoding = CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_UNSIGNED;
          outputValue.bitInterpretation.signCustomBitsCount = 0;
          outputValue.bitInterpretation.exponentCustomBitsCount = 0;
          outputValue.bitInterpretation.significandCustomBitsCount = mpz_sizeinbase(outputValue.bits, 2);
          if (!context.errorContext.hasError)
            result = [[CHChalkValueNumberRaw alloc] initWithToken:token value:&outputValue naturalBase:2 context:context];
          if (!result)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range]
                                   replace:NO];
          outputValueInitialized &= !result;
          if (outputValueInitialized)
            chalkRawValueClear(&outputValue, YES, context.gmpPool);
        }//end if (rice <= maxRice)
        if (error)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                              replace:NO];
        result.evaluationComputeFlags |=
          (missingBits ? CHALK_COMPUTE_FLAG_INEXACT : CHALK_COMPUTE_FLAG_NONE) |
          (overflow ? CHALK_COMPUTE_FLAG_OVERFLOW : CHALK_COMPUTE_FLAG_NONE) |
          operand1Value.evaluationComputeFlags |
          operand2Value.evaluationComputeFlags |
          chalkGmpFlagsMake();
      }//end if (operand1List || operand1Raw || operand1Gmp)
      chalkGmpFlagsRestore(oldFlags);
    }//end @autoreleasepool
  }//end if ((operands.count >= 1) && (operands.count <= 2))
  return [result autorelease];
}
//end combineGolombRiceEncode:token:context:

+(CHChalkValue*) combineHConcat:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  BOOL rowsCountInitialized = false;
  NSUInteger rowsCount = 0;
  NSUInteger colsCount = 0;
  BOOL invalidRowsCount = NO;
  NSMutableArray* stack = [NSMutableArray arrayWithArray:operands];
  NSMutableArray* operandsMatrices = [NSMutableArray arrayWithCapacity:operands.count];
  while(!context.errorContext.hasError && (stack.count > 0))
  {
    id operand = [stack objectAtIndex:0];
    [stack removeObjectAtIndex:0];
    CHChalkValue* operandValue = [operand dynamicCastToClass:[CHChalkValue class]];
    CHChalkValueEnumeration* operandEnumeration = [operand dynamicCastToClass:[CHChalkValueEnumeration class]];
    CHChalkValueMatrix* operandMatrix = [operand dynamicCastToClass:[CHChalkValueMatrix class]];
    if (operandEnumeration)
      [stack addObjectsFromArray:operandEnumeration.values];
    else if (operandMatrix)
    {
      invalidRowsCount |= rowsCountInitialized && (rowsCount != operandMatrix.rowsCount);
      rowsCount = MAX(rowsCount, operandMatrix.rowsCount);
      colsCount += operandMatrix.colsCount;
      rowsCountInitialized = YES;
      [operandsMatrices addObject:operandMatrix];
      if (invalidRowsCount)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorDimensionsMismatch range:!operandValue ? token.range : operandValue.token.range] replace:NO];
    }//end if (operandMatrix)
    else
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:!operandValue ? token.range : operandValue.token.range] replace:NO];
  }//end for each operand
  if (!context.errorContext.hasError)
  {
    CHChalkValueMatrix* outputMatrix = [[CHChalkValueMatrix alloc] initWithToken:token rowsCount:rowsCount colsCount:colsCount values:nil context:context];
    if (!outputMatrix)
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range] replace:NO];
    result = outputMatrix;
    NSUInteger colShift = 0;
    if (!context.errorContext.hasError)
    for(CHChalkValueMatrix* operandMatrix in operandsMatrices)
    {
      for(NSUInteger row = 0, operandRowCount = operandMatrix.rowsCount ; !context.errorContext.hasError && (row<operandRowCount) ; ++row)
      {
        for(NSUInteger col = 0, operandColCount = operandMatrix.colsCount ; !context.errorContext.hasError && (col<operandColCount) ; ++col)
        {
          CHChalkValue* clone = [[operandMatrix valueAtRow:row col:col] copy];
          //[clone.token unionWithToken:token];//experimental
          if (!clone)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:operandMatrix.token.range] replace:NO];
          else
            [outputMatrix setValue:clone atRow:row col:col+colShift];
          [clone release];
        }//end for each col
      }//end for each row
      colShift += operandMatrix.colsCount;
      result.evaluationComputeFlags |=
        operandMatrix.evaluationComputeFlags |
        chalkGmpFlagsMake();
    }//end for each operandMatrix
    result.evaluationComputeFlags |=
      chalkGmpFlagsMake();
  }//end if (!context.errorContext.hasError)
  return [result autorelease];
}
//end combineHConcat:token:context:

+(CHChalkValue*) combineVConcat:(NSArray*)operands token:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  BOOL colsCountInitialized = false;
  NSUInteger rowsCount = 0;
  NSUInteger colsCount = 0;
  BOOL invalidColsCount = NO;
  NSMutableArray* stack = [NSMutableArray arrayWithArray:operands];
  NSMutableArray* operandsMatrices = [NSMutableArray arrayWithCapacity:operands.count];
  while(!context.errorContext.hasError && (stack.count > 0))
  {
    id operand = [stack objectAtIndex:0];
    [stack removeObjectAtIndex:0];
    CHChalkValue* operandValue = [operand dynamicCastToClass:[CHChalkValue class]];
    CHChalkValueEnumeration* operandEnumeration = [operand dynamicCastToClass:[CHChalkValueEnumeration class]];
    CHChalkValueMatrix* operandMatrix = [operand dynamicCastToClass:[CHChalkValueMatrix class]];
    if (operandEnumeration)
      [stack addObjectsFromArray:operandEnumeration.values];
    else if (operandMatrix)
    {
      invalidColsCount |= colsCountInitialized && (colsCount != operandMatrix.colsCount);
      colsCount = MAX(colsCount, operandMatrix.colsCount);
      rowsCount += operandMatrix.rowsCount;
      colsCountInitialized = YES;
      [operandsMatrices addObject:operandMatrix];
      if (invalidColsCount)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorDimensionsMismatch range:!operandValue ? token.range : operandValue.token.range] replace:NO];
    }//end if (operandMatrix)
    else
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:!operandValue ? token.range : operandValue.token.range] replace:NO];
  }//end for each operand
  if (!context.errorContext.hasError)
  {
    CHChalkValueMatrix* outputMatrix = [[CHChalkValueMatrix alloc] initWithToken:token rowsCount:rowsCount colsCount:colsCount values:nil context:context];
    if (!outputMatrix)
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range] replace:NO];
    result = outputMatrix;
    NSUInteger rowShift = 0;
    if (!context.errorContext.hasError)
    for(CHChalkValueMatrix* operandMatrix in operandsMatrices)
    {
      for(NSUInteger row = 0, operandRowCount = operandMatrix.rowsCount ; !context.errorContext.hasError && (row<operandRowCount) ; ++row)
      {
        for(NSUInteger col = 0, operandColCount = operandMatrix.colsCount ; !context.errorContext.hasError && (col<operandColCount) ; ++col)
        {
          CHChalkValue* clone = [[operandMatrix valueAtRow:row col:col] copy];
          //[clone.token unionWithToken:token];//experimental
          if (!clone)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:operandMatrix.token.range] replace:NO];
          else
            [outputMatrix setValue:clone atRow:row+rowShift col:col];
          [clone release];
        }//end for each col
      }//end for each row
      rowShift += operandMatrix.rowsCount;
      result.evaluationComputeFlags |=
        operandMatrix.evaluationComputeFlags |
        chalkGmpFlagsMake();
    }//end for each operandMatrix
    result.evaluationComputeFlags |=
      chalkGmpFlagsMake();
  }//end if (!context.errorContext.hasError)
  return [result autorelease];
}
//end combineVConcat:token:context:

+(BOOL) powIntegers:(mpz_ptr)rop op1:(mpz_srcptr)op1 op2:(mpz_srcptr)op2 operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  BOOL result = NO;
  int sign1 = mpz_sgn(op1);
  int sign2 = mpz_sgn(op2);
  if (!sign1 && !sign2)
  {
    mpz_set_ui(rop, 1);
    result = YES;
  }//end if (!sign1 || !sign2)
  else if (!sign1)
  {
    mpz_set_ui(rop, 0);
    result = YES;
  }//end if (!sign1)
  else if (!sign2)
  {
    mpz_set_ui(rop, 1);
    result = YES;
  }//end if (!sign2)
  else if (sign1 && sign2)
  {
    if (!mpz_cmpabs_ui(op1, 1))
    {
      if (sign1 > 0)
        mpz_set_ui(rop, 1);
      else//if (sign1 < 0)
        mpz_set_si(rop, mpz_even_p(op2) ? 1 : -1);
      result = YES;
    }//end if (!mpz_cmpabs_ui(op1, 1))
    else if (!mpz_cmp_ui(op2, 1))
    {
      mpz_set(rop, op1);
      result = YES;
    }//end if (!mpz_cmp_ui(op2, 1))
    else//if (op1 and op2 are not 1)
    {
      BOOL quickResult = [CHChalkValueNumberGmp checkInteger:op1 token:token setError:YES context:context] &&
                         [CHChalkValueNumberGmp checkInteger:op2 token:token setError:YES context:context];
      if (!quickResult)
        result = NO;
      else//if (quickResult)
      {
        BOOL overflowCertain = NO;
        NSUInteger nbBitsMax = context.computationConfiguration.softIntegerMaxBits;
        NSUInteger nbBits1 = overflowCertain ? 0 : mpz_sizeinbase(op1, 2);
        overflowCertain |= !mpz_fits_nsui_p(op2);
        NSUInteger op2ui = overflowCertain ? 0 : mpz_get_nsui(op2);
        if (!overflowCertain)
        {
          //maximum number of result bits is op2ui*nbBits1
          //minimum number of result bits is op2ui*(nbBits1-1)+1
          overflowCertain = (op2ui > NSUIntegerMax/(nbBits1-1)) || ((nbBits1-1) > NSUIntegerMax/op2ui) ||
                            (nbBits1 && nbBitsMax && (op2ui*(nbBits1-1) > nbBitsMax-1));
        }//end if (!overflowCertain)
        if (!overflowCertain)
        {
          TRY_SAFE(mpz_pow_ui(rop, op1, op2ui));
          if (gmp_errno != 0)
          {
            gmp_errno = 0;
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainGmp reason:CHChalkErrorGmpOverflow range:token.range]
                                   replace:NO];
          }//end if (gmp_errno != 0)
          else
            result = [CHChalkValueNumberGmp checkInteger:rop token:token setError:YES context:context];
        }//end if (!overflowCertain)
        else if (context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_EXACT)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorIntegerOverflow range:token.range]
                                 replace:NO];
      }//end if (quickResult)
    }//end if (op1 and op2 are not 1)
  }//end if (sign1 && sign2)
  return result;
}
//end powIntegers:op1:op2:operatorToken:context:

+(CHChalkValue*) pow:(CHChalkValue*)value integerPower:(mpz_srcptr)integerPower operatorToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (value)
  {
    mpz_t remainingPower;
    mpzDepool(remainingPower, context.gmpPool);
    mpz_set(remainingPower, integerPower);
    mpz_abs(remainingPower, remainingPower);
    CHChalkValue* currentValue = [value retain];
    CHChalkValue* cumul = nil;
    if (mpz_odd_p(remainingPower))
    {
      cumul = [value copy];
      //[cumul.token unionWithToken:token];//experimental
      if (!cumul)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:token.range] replace:NO];
    }//end if (mpz_odd_p(remainingPower))
    if (!context.errorContext.hasError)
    {
      mpz_fdiv_q_2exp(remainingPower, remainingPower, 1);
      BOOL stop = !mpz_sgn(remainingPower);
      while(!stop)
      {
        @autoreleasepool {
          BOOL isPowerToKeep = (mpz_tstbit(remainingPower, 0) != 0);
          CHChalkValue* currentValueSqr = [[CHParserFunctionNode combineSqr:@[currentValue] token:token context:context] retain];
          if (!currentValueSqr)
          {
            [cumul release];
            cumul = nil;
            stop = YES;
          }//end if (!currentValueSqr)
          else//if (currentValueSqr)
          {
            if (isPowerToKeep)
            {
              CHChalkValue* newCumul = !cumul ? [currentValueSqr copy] :
                [[CHParserOperatorNode combineMul:@[cumul, currentValueSqr] operatorToken:token context:context] retain];
              [cumul release];
              cumul = newCumul;
              //[cumul.token unionWithToken:token];//experimental
            }//end if (isPowerToKeep)
            [currentValue release];
            currentValue = currentValueSqr;
            mpz_fdiv_q_2exp(remainingPower, remainingPower, 1);
            stop |= !mpz_sgn(remainingPower);
          }//end if (currentValueSqr)
        }//end @autoreleasepool
      }//end while(!stop)
    }//end if (!context.errorContext.hasError)
    mpzRepool(remainingPower, context.gmpPool);
    [currentValue release];
    currentValue = cumul;
    if (mpz_sgn(integerPower)<0)
    {
      CHChalkValue* newValue = !currentValue ? nil :
        [[CHParserFunctionNode combineInv:@[currentValue] token:token context:context] retain];
      [currentValue release];
      currentValue = newValue;
    }//end if (mpz_sgn(operandGmpValue->integer)<0)
    if (!currentValue)
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:token.range]
                             replace:NO];
    result = [currentValue autorelease];
    result.evaluationComputeFlags |=
      value.evaluationComputeFlags |
      chalkGmpFlagsMake();
  }//end if (value)
  return result;
}
//end pow:integerPower:context:

@end
