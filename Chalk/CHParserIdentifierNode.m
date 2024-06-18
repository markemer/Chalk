//
//  CHParserIdentifierNode.m
//  Chalk
//
//  Created by Pierre Chatelier on 13/02/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHParserIdentifierNode.h"

#import "CHChalkContext.h"
#import "CHChalkError.h"
#import "CHChalkErrorContext.h"
#import "CHChalkIdentifier.h"
#import "CHChalkIdentifierManager.h"
#import "CHChalkToken.h"
#import "CHChalkValue.h"
#import "CHChalkValueBoolean.h"
#import "CHChalkValueQuaternion.h"
#import "CHChalkValueNumberGmp.h"
#import "CHChalkValueNumberRaw.h"
#import "CHComputationConfiguration.h"
#import "CHPresentationConfiguration.h"
#import "CHStreamWrapper.h"
#import "CHUtils.h"
#import "NSObjectExtended.h"

@implementation CHParserIdentifierNode

-(void) dealloc
{
  [self->cachedIdentifier release];
  [super dealloc];
}
//end dealloc

-(CHChalkIdentifier*) identifierWithContext:(CHChalkContext*)context
{
  CHChalkIdentifier* result = [context.identifierManager identifierForToken:self.token.value createClass:Nil];
  return result;
}
//end identifierWithContext:

-(BOOL) resetEvaluationMatchingIdentifiers:(NSSet*)identifiers identifierManager:(CHChalkIdentifierManager*)identifierManager
{
  BOOL result = NO;
  if (!identifiers || !identifierManager)
    result = [super resetEvaluationMatchingIdentifiers:nil identifierManager:identifierManager];
  else//if (identifiers || !identifierManager)
  {
    CHChalkIdentifier* identifier =
      self->cachedIdentifier ? self->cachedIdentifier :
      [identifierManager identifierForToken:self.token.value createClass:Nil];
    if (!identifier || [identifiers containsObject:identifier])
      result = [super resetEvaluationMatchingIdentifiers:nil identifierManager:identifierManager];
    if (result)
    {
      self.evaluatedValue = nil;
      @synchronized(self->evaluationErrors)
      {
        [self->evaluationErrors removeAllObjects];
      }//end @synchronized(self->evaluationErrors)
      self->evaluationComputeFlags = CHALK_COMPUTE_FLAG_NONE;
    }//end if (result)
  }//end if (![identifiers containsObject:self])
  return result;
}
//end resetEvaluationMatchingIdentifiers:

-(BOOL) isUsingIdentifier:(CHChalkIdentifier*)identifier identifierManager:(CHChalkIdentifierManager*)identifierManager
{
  BOOL result = NO;
  if (identifier)
  {
    CHChalkIdentifier* selfIdentifier =
      self->cachedIdentifier ? self->cachedIdentifier :
      [identifierManager identifierForToken:self.token.value createClass:Nil];
    result = [selfIdentifier isEqual:identifier];
  }//end if (identifier)
  return result;
}
//end isUsingIdentifier:identifierManager:

-(void) performEvaluationWithContext:(CHChalkContext*)context lazy:(BOOL)lazy
{
  [super performEvaluationWithContext:context lazy:lazy];
  if (!lazy || !self.evaluatedValue)
  {
    NSString* identifierToken = self->token.value;
    CHChalkIdentifierManager* identifierManager = context.identifierManager;
    chalkGmpFlagsMake();
    CHChalkIdentifier* chalkIdentifier =
      self->cachedIdentifier ? self->cachedIdentifier :
      [identifierManager identifierForToken:identifierToken createClass:Nil];
    if (chalkIdentifier == [CHChalkIdentifier noIdentifier])
    {
      mpfr_clear_flags();
      self.evaluatedValue = [CHChalkValueBoolean noValue];
      self->evaluationComputeFlags = chalkGmpFlagsMake();
    }//end if (chalkIdentifier == [CHChalkIdentifier noIdentifier])
    else if (chalkIdentifier == [CHChalkIdentifier unlikelyIdentifier])
    {
      mpfr_clear_flags();
      self.evaluatedValue = [CHChalkValueBoolean unlikelyValue];
      self->evaluationComputeFlags = chalkGmpFlagsMake();
    }//end if (chalkIdentifier == [CHChalkIdentifier unlikelyIdentifier])
    else if (chalkIdentifier == [CHChalkIdentifier maybeIdentifier])
    {
      mpfr_clear_flags();
      self.evaluatedValue = [CHChalkValueBoolean maybeValue];
      self->evaluationComputeFlags = chalkGmpFlagsMake();
    }//end if (chalkIdentifier == [CHChalkIdentifier maybeIdentifier])
    else if (chalkIdentifier == [CHChalkIdentifier certainlyIdentifier])
    {
      mpfr_clear_flags();
      self.evaluatedValue = [CHChalkValueBoolean certainlyValue];
      self->evaluationComputeFlags = chalkGmpFlagsMake();
    }//end if (chalkIdentifier == [CHChalkIdentifier certainlyIdentifier])
    else if (chalkIdentifier == [CHChalkIdentifier yesIdentifier])
    {
      mpfr_clear_flags();
      self.evaluatedValue = [CHChalkValueBoolean yesValue];
      self->evaluationComputeFlags = chalkGmpFlagsMake();
    }//end if (chalkIdentifier == [CHChalkIdentifier yesIdentifier])
    else if (chalkIdentifier == [CHChalkIdentifier nanIdentifier])
    {
      mpfr_clear_flags();
      self.evaluatedValue = [CHChalkValueNumberGmp nanWithContext:context];
      mpfr_set_nanflag();
      self->evaluationComputeFlags = chalkGmpFlagsMake();
    }//end if (chalkIdentifier == [CHChalkIdentifier nanIdentifier])
    else if (chalkIdentifier == [CHChalkIdentifier infinityIdentifier])
    {
      mpfr_clear_flags();
      self.evaluatedValue = [CHChalkValueNumberGmp infinityWithContext:context];
      mpfr_set_erangeflag();
      mpfr_set_overflow();
      self->evaluationComputeFlags = chalkGmpFlagsMake();
    }//end if (chalkIdentifier == [CHChalkIdentifier infinityIdentifier])
    else if (chalkIdentifier == [CHChalkIdentifier piIdentifier])
    {
      chalk_gmp_value_t value = {0};
      mpfr_clear_flags();
      mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
      chalkGmpValueMakeRealApprox(&value, prec, context.gmpPool);
      mpfir_const_pi(value.realApprox);
      self.evaluatedValue = [[[CHChalkValueNumberGmp alloc] initWithToken:self->token value:&value naturalBase:context.computationConfiguration.baseDefault context:context] autorelease];
      self->evaluationComputeFlags = chalkGmpFlagsMake();
    }//end if (chalkIdentifier == [CHChalkIdentifier piIdentifier])
    else if (chalkIdentifier == [CHChalkIdentifier eIdentifier])
    {
      chalk_gmp_value_t value = {0};
      mpfr_clear_flags();
      mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
      if (context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_BEST)
      {
        chalkGmpValueMakeRealExact(&value, prec, context.gmpPool);
        mpfr_set_ui(value.realExact, 1, MPFR_RNDN);
        mpfr_exp(value.realExact, value.realExact, MPFR_RNDN);
      }//end if (context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_APPROX_BEST)
      else//if (context.computationConfiguration.computeMode != CHALK_COMPUTE_MODE_APPROX_BEST)
      {
        chalkGmpValueMakeRealApprox(&value, prec, context.gmpPool);
        mpfir_set_ui(value.realApprox, 1);
        mpfir_exp(value.realApprox, value.realApprox);
      }//end if (context.computationConfiguration.computeMode != CHALK_COMPUTE_MODE_APPROX_BEST)
      self.evaluatedValue = [[[CHChalkValueNumberGmp alloc] initWithToken:self->token value:&value naturalBase:context.computationConfiguration.baseDefault context:context] autorelease];
      self->evaluationComputeFlags = chalkGmpFlagsMake();
    }//end if (chalkIdentifier == [CHChalkIdentifier eIdentifier])
    else if (chalkIdentifier == [CHChalkIdentifier iIdentifier])
    {
      CHChalkValue* value = [CHChalkValueQuaternion oneIWithToken:self->token context:context];
      if (!value)
        [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:self->token.range] context:context];
      else
        self.evaluatedValue = [[value copy] autorelease];
    }//end if (chalkIdentifier == [CHChalkIdentifier iIdentifier])
    else if (chalkIdentifier == [CHChalkIdentifier jIdentifier])
    {
      CHChalkValue* value = [CHChalkValueQuaternion oneJWithToken:self->token context:context];
      if (!value)
        [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:self->token.range] context:context];
      else
        self.evaluatedValue = [[value copy] autorelease];
    }//end if (chalkIdentifier == [CHChalkIdentifier jIdentifier])
    else if (chalkIdentifier == [CHChalkIdentifier kIdentifier])
    {
      CHChalkValue* value = [CHChalkValueQuaternion oneKWithToken:self->token context:context];
      if (!value)
        [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:self->token.range] context:context];
      else
        self.evaluatedValue = [[value copy] autorelease];
    }//end if (chalkIdentifier == [CHChalkIdentifier kIdentifier])
    else//custom identifier
    {
      CHChalkValue* value = [identifierManager valueForIdentifier:chalkIdentifier];
      if (!value)
        [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorIdentifierUndefined range:self->token.range] context:context];
      else//if (value)
      {
        CHChalkValue* value2 = [[value copy] autorelease];
        [value2 replaceToken:self.token];
        self.evaluatedValue = value2;
      }//end if (value)
    }//end custom identifier
    if (!self->cachedIdentifier)
      self->cachedIdentifier = [chalkIdentifier retain];
    [context.errorContext.error setContextGenerator:self replace:NO];
  }//end if (!lazy || !self.evaluatedValue)
}
//end performEvaluationWithContext:

-(void) writeBodyToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  NSString* tokenString = self->token.value;
  CHChalkIdentifier* chalkIdentifier =
    self->cachedIdentifier ? self->cachedIdentifier :
    [context.identifierManager identifierForToken:tokenString createClass:Nil];
  if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_HTML)
  {
    NSString* symbol = !chalkIdentifier ? tokenString : chalkIdentifier.symbolAsText;
    if (self->evaluationErrors.count)
    {
      NSString* errorsString = [[[self->evaluationErrors valueForKey:@"friendlyDescription"] componentsJoinedByString:@","] stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
      NSString* string =
        [NSString stringWithFormat:@"<span class=\"errorFlag\" onmouseover=\"tooltip.show('%@');\" onmouseout=\"tooltip.hide();\">%@</span>",
          errorsString, tokenString];
      [stream writeString:string];
    }//end if (self->evaluationErrors.count)
    else if (self->evaluationComputeFlags)
    {
      CHChalkValueNumberRaw* evaluatedValueRaw = [self->evaluatedValue dynamicCastToClass:[CHChalkValueNumberRaw class]];
      const chalk_raw_value_t* rawValue = evaluatedValueRaw.valueConstReference;
      const chalk_bit_interpretation_t* bitInterpretation = !rawValue ? 0 : &rawValue->bitInterpretation;
      NSString* flagsImageString = [chalkGmpComputeFlagsGetHTML(self->evaluationComputeFlags, bitInterpretation, NO) stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
      NSString* string =
        [NSString stringWithFormat:@"<span class=\"hasTooltip\" onmouseover=\"tooltip.show('%@');\" onmouseout=\"tooltip.hide();\">%@</span>",
          flagsImageString, symbol];
      [stream writeString:string];
    }//end if (self->evaluationComputeFlags)
    else
      [stream writeString:tokenString];
  }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_HTML)
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
  {
    NSString* symbol = chalkIdentifier ? chalkIdentifier.symbolAsTeX :
      tokenString;
    NSString* adaptedSymbol = symbol;
    adaptedSymbol = [adaptedSymbol stringByReplacingOccurrencesOfString:@"#" withString:@"\\$"];
    adaptedSymbol = [adaptedSymbol stringByReplacingOccurrencesOfString:@"&" withString:@"\\&"];
    adaptedSymbol = [adaptedSymbol stringByReplacingOccurrencesOfString:@"_" withString:@"\\_"];
    adaptedSymbol = [adaptedSymbol stringByReplacingOccurrencesOfString:@"$" withString:@"\\$"];
    [stream writeString:[NSString stringWithFormat:@"%@", adaptedSymbol]];
  }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_ATTRIBUTEDSTRING)
  {
    NSString* symbol = !chalkIdentifier ? self->token.value : chalkIdentifier.symbolAsText;
    [stream writeString:symbol bold:NO italic:YES];
  }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_ATTRIBUTEDSTRING)
  else
  {
    NSString* symbol = chalkIdentifier ? chalkIdentifier.symbol :
      tokenString;
    [stream writeString:symbol];
  }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_ATTRIBUTEDSTRING)
}
//end writeBodyToStream:context:options:

@end
