//
//  CHChalkValueFormalSimple.m
//  Chalk
//
//  Created by Pierre Chatelier on 16/02/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHChalkValueFormalSimple.h"

#import "CHChalkContext.h"
#import "CHChalkError.h"
#import "CHChalkErrorContext.h"
#import "CHChalkIdentifier.h"
#import "CHChalkToken.h"
#import "CHChalkUtils.h"
#import "CHChalkValueNumberGmp.h"
#import "CHChalkValueNumberRaw.h"
#import "CHComputationConfiguration.h"
#import "CHPresentationConfiguration.h"
#import "CHStreamWrapper.h"
#import "NSObjectExtended.h"

@implementation CHChalkValueFormalSimple

@synthesize factor;
@synthesize power;

+(BOOL) supportsSecureCoding {return YES;}

-(instancetype) initWithCoder:(NSCoder*)aDecoder
{
  if (!((self = [super initWithCoder:aDecoder])))
    return nil;
  self->factor = [[aDecoder decodeObjectOfClass:[CHChalkValueNumberGmp class] forKey:@"factor"] retain];
  self->power = [[aDecoder decodeObjectOfClass:[CHChalkValueNumberGmp class] forKey:@"power"] retain];
  return self;
}
//end initWithCoder:

-(void) encodeWithCoder:(NSCoder*)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:self->factor forKey:@"factor"];
  [aCoder encodeObject:self->power forKey:@"power"];
}
//end encodeWithCoder:

-(void)dealloc
{
  [self->factor release];
  [self->power release];
  [super dealloc];
}
//end dealloc

-(id) copyWithZone:(NSZone*)zone
{
  id result = [super copyWithZone:zone];
  CHChalkValueFormalSimple* clone = [result dynamicCastToClass:[CHChalkValueFormalSimple class]];
  if (!clone)
    [result release];
  else//if (clone)
  {
    clone.factor = self->factor;
    clone.power = self->power;
   }//end if (clone)
  return result;
}
//end copyWithZone:

-(void) adaptToComputeMode:(chalk_compute_mode_t)computeMode context:(CHChalkContext*)context
{
}
//end adaptToComputeMode:context:

-(void) writeBodyToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  /*
  const chalk_gmp_value_t* baseValue_gmpValue = self->baseValue.valueConstReference;
  const chalk_gmp_value_t* factor_gmpValue = self->factor.valueConstReference;
  const chalk_gmp_value_t* power_gmpValue = self->power.valueConstReference;
  BOOL isBaseValueFormalCompatible =
    (baseValue_gmpValue->type == CHALK_VALUE_TYPE_INTEGER) ||
    (baseValue_gmpValue->type == CHALK_VALUE_TYPE_FRACTION);
  BOOL isFactorFormalCompatible =
    (factor_gmpValue->type == CHALK_VALUE_TYPE_INTEGER) ||
    (factor_gmpValue->type == CHALK_VALUE_TYPE_FRACTION);
  BOOL isPowerFormalCompatible =
    (power_gmpValue->type == CHALK_VALUE_TYPE_INTEGER) ||
    (power_gmpValue->type == CHALK_VALUE_TYPE_FRACTION);
  BOOL isFormalCompatible = isBaseValueFormalCompatible && isFactorFormalCompatible && isPowerFormalCompatible;
  if (!presentationConfiguration || (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_STRING))
  {
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
    NSString* symbol = self->chalkIdentifier.symbol;
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
    NSString* symbol = self->chalkIdentifier.symbol;
    NSString* selfNodeIdentifier = [NSString stringWithFormat:@"_%p", self];
    [stream writeString:[NSString stringWithFormat:@"%@ [label=\"%@\"];n", selfNodeIdentifier, symbol]];
  }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_DOT)
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_MATHML)
  {
    NSString* symbol = self->chalkIdentifier.symbol;
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
    NSString* symbol = self->chalkIdentifier.symbolAsTeX;
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
        BOOL isTerminal = YES;
        if (!isTerminal)
          [stream writeString:@"\\left("];
        [args enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
          [obj writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
        }];
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
        CHChalkValue* child = [obj dynamicCastToClass:[CHChalkValue class]];
        if (idx)
          [stream writeString:@","];
        [child writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
      }];
      [stream writeString:@"}\\right)"];
    }//end if (!placeHoldersCount)
  }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_HTML)
  {
    NSString* symbol = self->chalkIdentifier.symbol;
    NSString* iconString = nil;
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
  */
}
//end writeBodyToStream:context:options:

@end
