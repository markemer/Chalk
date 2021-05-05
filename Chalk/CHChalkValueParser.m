//
//  CHChalkValueParser.m
//  Chalk
//
//  Created by Pierre Chatelier on 23/02/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHChalkValueParser.h"

#import "CHChalkContext.h"
#import "CHChalkError.h"
#import "CHChalkErrorContext.h"
#import "CHChalkToken.h"
#import "CHChalkUtils.h"
#import "CHChalkValue.h"
#import "CHChalkValueNumberGmp.h"
#import "CHComputationConfiguration.h"
#import "CHPreferencesController.h"
#import "CHUtils.h"
#import "NSArrayExtended.h"
#import "NSObjectExtended.h"
#import "NSStringExtended.h"

static inline NSRange rangeAvoidNSNotFound(NSRange range)
{
  NSRange result = (range.location == NSNotFound) ? NSMakeRange(0, 0) : range;
  return result;
}
//end rangeAvoidNSNotFound()

static NSString* adaptString(NSString* string, NSRange range, NSRange* outTrimmedRange)
{
  NSString* result = nil;
  NSRange trimmedRange = range;
  NSString* input = [string substringWithRange:range];
  result = input;
  NSString* trimmedInput = [input stringByReplacingOccurrencesOfRegex:@"\\s" withString:@""];
  if (trimmedInput.length != input.length)
  {
    result = trimmedInput;
    trimmedRange = trimmedInput.range;
  }//end if (trimmedInput.length != input.length)
  if (outTrimmedRange)
    *outTrimmedRange = trimmedRange;
  return result;
}
//end rangeAvoidNSNotFound()

@implementation CHChalkValueParser

@synthesize token;

-(id) initWithToken:(CHChalkToken*)aToken context:(CHChalkContext*)context
{
  if (!((self = [super init])))
    return nil;
  self->token = [aToken copy];
  BOOL done = [self analyzeWithContext:context];
  CHChalkErrorContext* errorContext = context.errorContext;
  if (!context || (!done && !errorContext.hasError))
  {
    [errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown
                     range:aToken.range] replace:NO];
     [self release];
     return nil;
  }//end if (!context || (!done && !errorContext.hasError))
  return self;
}
//end initWithToken:context:

-(void) dealloc
{
  [self->token release];
  [super dealloc];
}
//end dealloc

-(void) setToken:(CHChalkToken*)value
{
  if (value != self->token)
  {
    [self->token release];
    self->token = [value copy];
    [self resetAnalysis];
  }//end if (value != self->token)
}
//end setToken:

-(void) resetAnalysis
{
  self->significandSignRange = NSRangeZero;
  self->significandBasePrefixRange = NSRangeZero;
  self->significandIntegerHeadRange = NSRangeZero;
  self->significandIntegerTailZerosRange = NSRangeZero;
  self->significandIntegerDigitsRange = NSRangeZero;
  self->significandDecimalSeparatorRange = NSRangeZero;
  self->significandFractHeadZerosRange = NSRangeZero;
  self->significandFractTailRange = NSRangeZero;
  self->significandFractDigitsRange = NSRangeZero;
  self->significandBaseSuffixRange = NSRangeZero;
  self->exponentSymbolRange = NSRangeZero;
  self->exponentSignRange = NSRangeZero;
  self->exponentDigitsBasePrefixRange = NSRangeZero;
  self->exponentDigitsRange = NSRangeZero;
  self->exponentDigitsBaseSuffixRange = NSRangeZero;
  self->significandSign = 0;
  self->exponentSign = 0;
  self->significandBase = 0;
  self->exponentDigitsBase = 0;
  self->exponentBaseToPow = 0;
}
//end resetAnalysis

-(BOOL) analyzeWithContext:(CHChalkContext*)context
{
  BOOL result = NO;
  //the string is supposed to be a VALID parsed integer or float number, so that regex should not result in unexpected results
  CHChalkErrorContext* errorContext = context.errorContext;
  NSString* tokenString = self->token.value;

  NSString* integerRegexpPattern = nil;
  NSString* decimalRegexpPattern = nil;
  NSString* realRegexpPattern = nil;
  
  BOOL done = NO;
  if ([NSString isNilOrEmpty:tokenString])
    [errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown] replace:NO];
  else//if (![NSString isNilOrEmpty:tokenString])
  {
    NSRegularExpression* integerRegexp = nil;
    NSRegularExpression* decimalRegexp = nil;
    NSRegularExpression* realRegexp = nil;
    NSMutableArray* basePrefixes = [NSMutableArray array];
    NSMutableArray* baseSuffixes = [NSMutableArray array];
    NSMutableArray* basePrefixesEscaped = [NSMutableArray array];
    NSMutableArray* baseSuffixesEscaped = [NSMutableArray array];
    if (!errorContext.hasError)
    {
      NSError* error = nil;
      for(NSDictionary* basePrefixesSuffixes in context.basePrefixesSuffixes)
      {
        NSArray* separatedBasePrefixes = [[basePrefixesSuffixes objectForKey:CHBasePrefixesKey] dynamicCastToClass:[NSArray class]];
        NSArray* separatedBaseSuffixes = [[basePrefixesSuffixes objectForKey:CHBaseSuffixesKey] dynamicCastToClass:[NSArray class]];
        for(NSString* basePrefix in separatedBasePrefixes)
        {
          if (![NSString isNilOrEmpty:basePrefix])
            [basePrefixes addObject:basePrefix];
          NSString* basePrefixEscaped = [NSRegularExpression escapedPatternForString:basePrefix];
          if (![NSString isNilOrEmpty:basePrefixEscaped])
            [basePrefixesEscaped addObject:basePrefixEscaped];
        }//end for(NSString* basePrefix in separatedBasePrefixes)
        for(NSString* baseSuffix in separatedBaseSuffixes)
        {
          if (![NSString isNilOrEmpty:baseSuffix])
            [baseSuffixes addObject:baseSuffix];
          NSString* baseSuffixEscaped = [NSRegularExpression escapedPatternForString:baseSuffix];
          if (![NSString isNilOrEmpty:baseSuffixEscaped])
            [baseSuffixesEscaped addObject:baseSuffixEscaped];
        }//end for(NSString* baseSuffix in separatedBaseSuffixes)
      }//end for each basePrefixesSuffixes
      NSSet* basePrefixesEscapedSet = [NSSet setWithArray:basePrefixesEscaped];
      NSSet* baseSuffixesEscapedSet = [NSSet setWithArray:baseSuffixesEscaped];
      BOOL prefixAmbiguity = (basePrefixesEscaped.count != basePrefixesEscapedSet.count);
      BOOL suffixAmbiguity = (baseSuffixesEscaped.count != baseSuffixesEscapedSet.count);
      if (prefixAmbiguity || suffixAmbiguity)
        [errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorBaseDecorationAmbiguity] replace:NO];

      NSString* basePrefixesRegex = [basePrefixesEscaped componentsJoinedByString:@"|" allowEmpty:NO];
      NSString* baseSuffixesRegex = [baseSuffixesEscaped componentsJoinedByString:@"|" allowEmpty:NO];
      integerRegexpPattern = [NSString stringWithFormat:
        @"^([\\+\\-])?(%@)?[0\\s]*([0-9a-zA-Z\\s]*[0-9a-zA-Z]+)?\\s*(%@|\\.\\.\\.)?(%@)?$",
        basePrefixesRegex, NSSTRING_ELLIPSIS, baseSuffixesRegex];
      integerRegexp = [NSRegularExpression
        regularExpressionWithPattern:integerRegexpPattern
                             options:NSRegularExpressionCaseInsensitive
                               error:&error];
      decimalRegexpPattern = [NSString stringWithFormat:
        @"^([\\+\\-])?(%@)?[0\\s]*([0-9a-zA-Z\\s]*[0-9a-zA-Z]+)?\\s*(\\.)([0-9a-zA-Z\\s]*[1-9a-zA-Z]+)?(?:[0\\s]*)(%@|\\.\\.\\.)?(%@)?$",
        basePrefixesRegex, NSSTRING_ELLIPSIS, baseSuffixesRegex];
      decimalRegexp = [NSRegularExpression
        regularExpressionWithPattern:decimalRegexpPattern
                             options:NSRegularExpressionCaseInsensitive
                               error:&error];
      realRegexpPattern = [NSString stringWithFormat:
        @"^([\\+\\-])?(%@)?[0\\s]*([0-9a-zA-Z\\s]*[1-9a-zA-Z]+)?([0\\s]*)(\\.)?([0\\s]*)([0-9a-zA-Z\\s]*[1-9a-zA-Z]+)?(?:[0\\s]*)(%@|\\.\\.\\.)?(%@)?(#?[eEpP])([\\+\\-]?)(%@)?(?:[0\\s]*)([0-9a-zA-Z\\s]*[0-9a-zA-Z]+)\\s*(%@)?$",
          basePrefixesRegex, NSSTRING_ELLIPSIS, baseSuffixesRegex, basePrefixesRegex, baseSuffixesRegex];
      realRegexp = [NSRegularExpression
        regularExpressionWithPattern:realRegexpPattern
                             options:NSRegularExpressionCaseInsensitive
                               error:&error];
    }//end if (!errorContext.hasError)
    
    if (!integerRegexp || !decimalRegexp || !realRegexp)
      [errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown] replace:NO];

    CHChalkError* integerNumberError = nil;
    CHChalkError* decimalNumberError = nil;
    CHChalkError* realNumberError = nil;
    if (!done && !errorContext.hasError)
    {
      [self resetAnalysis];
      NSArray* matches = [integerRegexp matchesInString:tokenString options:0 range:tokenString.range];
      NSTextCheckingResult* lastMatch = [matches lastObject];
      BOOL isMatching = (matches.count == 1) && (lastMatch.numberOfRanges == (1+5));
      if (isMatching)
      {
        NSRange range = NSRangeZero;
        NSString* rangeString = nil;
        
        range = [lastMatch rangeAtIndex:1];
        rangeString = ((range.location == NSNotFound) || !range.length) ? @"" : [tokenString substringWithRange:range];
        self->significandSignRange = rangeAvoidNSNotFound(range);
        self->significandSign =
          [rangeString isEqualToString:@"+"] ? 1 :
          [rangeString isEqualToString:@"-"] ? -1 :
          1;//may be set to 0 later if significand digits are zero

        range = [lastMatch rangeAtIndex:2];
        rangeString = ((range.location == NSNotFound) || !range.length) ? @"" : [tokenString substringWithRange:range];
        self->significandBasePrefixRange = rangeAvoidNSNotFound(range);
        NSString* basePrefix = rangeString;

        range = [lastMatch rangeAtIndex:3];
        rangeString = ((range.location == NSNotFound) || !range.length) ? @"" : [tokenString substringWithRange:range];
        self->significandIntegerDigitsRange = rangeAvoidNSNotFound(range);
        if (!self->significandIntegerDigitsRange.length)
          self->significandSign = 0;

        range = [lastMatch rangeAtIndex:4];
        NSRange ellipsisRange = rangeAvoidNSNotFound(range);
        rangeString = ((range.location == NSNotFound) || !range.length) ? @"" : [tokenString substringWithRange:range];
        self->hasEllipsis = ![NSString isNilOrEmpty:rangeString];

        range = [lastMatch rangeAtIndex:5];
        rangeString = ((range.location == NSNotFound) || !range.length) ? @"" : [tokenString substringWithRange:range];
        self->significandBaseSuffixRange = rangeAvoidNSNotFound(range);
        
        if ((self->significandIntegerDigitsRange.length != 0) && !ellipsisRange.length && !self->significandBaseSuffixRange.length)
        {
          NSString* significandIntegerDigits = [tokenString substringWithRange:self->significandIntegerDigitsRange];
          __block NSString* suffixFound = nil;
          [baseSuffixes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString* suffix = [obj dynamicCastToClass:[NSString class]];
            if ([significandIntegerDigits endsWith:suffix options:NSCaseInsensitiveSearch])
              suffixFound = suffix;
            *stop |= (suffixFound != nil);
          }];
          if (suffixFound)
          {
            NSUInteger suffixLength = suffixFound.length;
            self->significandBaseSuffixRange = NSMakeRange(NSMaxRange(self->significandIntegerDigitsRange)-suffixLength, suffixLength);
            self->significandIntegerDigitsRange.length -= suffixLength;
          }//end if (suffixFound)
        }//end if ((self->significandIntegerDigitsRange.length != 0) && !ellipsisRange.length && !self->significandBaseSuffixRange.length)

        NSString* baseSuffix = !self->significandBaseSuffixRange.length ? nil :
          [tokenString substringWithRange:self->significandBaseSuffixRange];
        
        BOOL hasBasePrefix = ![NSString isNilOrEmpty:basePrefix];
        BOOL hasBaseSuffix = ![NSString isNilOrEmpty:baseSuffix];
        int baseFromPrefix = !hasBasePrefix ? 0 : [context baseFromPrefix:basePrefix];
        int baseFromSuffix = !hasBaseSuffix ? 0 : [context baseFromSuffix:baseSuffix];
        if (hasBasePrefix && hasBaseSuffix && (baseFromPrefix != baseFromSuffix))
          [errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorBaseDecorationConflict
                                                              range:self->token.range] replace:NO];
        else if (hasBasePrefix && !baseFromPrefix)
          [errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorBaseDecorationInvalid
                           range:self->significandBasePrefixRange] replace:NO];
        else if (hasBaseSuffix && !baseFromSuffix)
          [errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorBaseDecorationInvalid
                           range:self->significandBaseSuffixRange] replace:NO];
        else//if no conflict for base
        {
          self->significandBase =
            baseFromPrefix ? baseFromPrefix :
            baseFromSuffix ? baseFromSuffix :
            context.computationConfiguration.baseDefault;
          self->exponentDigitsBase = self->significandBase;
          self->exponentBaseToPow = 10;
          NSIndexSet* significandIntegerDigitsFailures = nil;
          BOOL digitsMatchBase = chalkDigitsMatchBase(tokenString, self->significandIntegerDigitsRange, self->significandBase, YES, &significandIntegerDigitsFailures);
          if (!digitsMatchBase)
          {
            BOOL maybeScientificNotation = [tokenString isMatchedByRegex:realRegexpPattern];
            if (!maybeScientificNotation)
            {
              integerNumberError = (significandIntegerDigitsFailures != nil) ?
                [CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorBaseDigitsInvalid ranges:significandIntegerDigitsFailures] :
                [CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorBaseDigitsInvalid range:self->significandIntegerDigitsRange];
              integerNumberError.reasonExtraInformation = @(self->significandBase);
            }//end if (!maybeScientificNotation)
          }//end if (!digitsMatchBase)
          done = digitsMatchBase;
        }//end if no conflict for base
      }//end if (isMatching)
    }//end if (!done && !errorContext.hasError)
    if (!done && !errorContext.hasError)
    {
      [self resetAnalysis];
      NSArray* matches = [decimalRegexp matchesInString:tokenString options:0 range:tokenString.range];
      NSTextCheckingResult* lastMatch = [matches lastObject];
      BOOL isMatching = (matches.count == 1) && (lastMatch.numberOfRanges == (1+7));
      if (isMatching)
      {
        NSRange range = NSRangeZero;
        NSString* rangeString = nil;
        
        range = [lastMatch rangeAtIndex:1];
        rangeString = ((range.location == NSNotFound) || !range.length) ? @"" : [tokenString substringWithRange:range];
        self->significandSignRange = rangeAvoidNSNotFound(range);
        self->significandSign =
          [rangeString isEqualToString:@"+"] ? 1 :
          [rangeString isEqualToString:@"-"] ? -1 :
          1;//may be set to 0 later if significand digits are zero

        range = [lastMatch rangeAtIndex:2];
        rangeString = ((range.location == NSNotFound) || !range.length) ? @"" : [tokenString substringWithRange:range];
        self->significandBasePrefixRange = rangeAvoidNSNotFound(range);
        NSString* basePrefix = rangeString;

        range = [lastMatch rangeAtIndex:3];
        rangeString = ((range.location == NSNotFound) || !range.length) ? @"" : [tokenString substringWithRange:range];
        self->significandIntegerDigitsRange = rangeAvoidNSNotFound(range);

        range = [lastMatch rangeAtIndex:4];
        rangeString = ((range.location == NSNotFound) || !range.length) ? @"" : [tokenString substringWithRange:range];
        self->significandDecimalSeparatorRange = rangeAvoidNSNotFound(range);

        range = [lastMatch rangeAtIndex:5];
        rangeString = ((range.location == NSNotFound) || !range.length) ? @"" : [tokenString substringWithRange:range];
        self->significandFractDigitsRange = rangeAvoidNSNotFound(range);
        
        if (!self->significandIntegerDigitsRange.length && !self->significandFractDigitsRange.length)
          self->significandSign = 0;
        
        range = [lastMatch rangeAtIndex:6];
        NSRange ellipsisRange = rangeAvoidNSNotFound(range);
        rangeString = ((range.location == NSNotFound) || !range.length) ? @"" : [tokenString substringWithRange:range];
        self->hasEllipsis = ![NSString isNilOrEmpty:rangeString];

        range = [lastMatch rangeAtIndex:7];
        rangeString = ((range.location == NSNotFound) || !range.length) ? @"" : [tokenString substringWithRange:range];
        self->significandBaseSuffixRange = rangeAvoidNSNotFound(range);
        
        if ((self->significandFractDigitsRange.length != 0) && !ellipsisRange.length && !self->significandBaseSuffixRange.length)
        {
          NSString* significandFractDigits = [tokenString substringWithRange:self->significandFractDigitsRange];
          __block NSString* suffixFound = nil;
          [baseSuffixes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString* suffix = [obj dynamicCastToClass:[NSString class]];
            if ([significandFractDigits endsWith:suffix options:NSCaseInsensitiveSearch])
              suffixFound = suffix;
            *stop |= (suffixFound != nil);
          }];
          if (suffixFound)
          {
            NSUInteger suffixLength = suffixFound.length;
            self->significandBaseSuffixRange = NSMakeRange(NSMaxRange(self->significandFractDigitsRange)-suffixLength, suffixLength);
            self->significandFractDigitsRange.length -= suffixLength;
          }//end if (suffixFound)
        }//end if ((self->significandFractDigitsRange.length != 0) && !ellipsisRange.length && !self->significandBaseSuffixRange.length)

        NSString* baseSuffix = !self->significandBaseSuffixRange.length ? nil :
          [tokenString substringWithRange:self->significandBaseSuffixRange];
        
        BOOL hasBasePrefix = ![NSString isNilOrEmpty:basePrefix];
        BOOL hasBaseSuffix = ![NSString isNilOrEmpty:baseSuffix];
        int baseFromPrefix = !hasBasePrefix ? 0 : [context baseFromPrefix:basePrefix];
        int baseFromSuffix = !hasBaseSuffix ? 0 : [context baseFromSuffix:baseSuffix];
        if (hasBasePrefix && hasBaseSuffix && (baseFromPrefix != baseFromSuffix))
          [errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorBaseDecorationConflict
                                                              range:self->token.range] replace:NO];
        else if (hasBasePrefix && !baseFromPrefix)
          [errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorBaseDecorationInvalid
                           range:self->significandBasePrefixRange] replace:NO];
        else if (hasBaseSuffix && !baseFromSuffix)
          [errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorBaseDecorationInvalid
                           range:self->significandBaseSuffixRange] replace:NO];
        else//if no conflict for base
        {
          self->significandBase =
            baseFromPrefix ? baseFromPrefix :
            baseFromSuffix ? baseFromSuffix :
            context.computationConfiguration.baseDefault;
          self->exponentDigitsBase = self->significandBase;
          self->exponentBaseToPow = 10;
          NSIndexSet* significandIntegerDigitsFailures = nil;
          BOOL significandIntegerDigitsMatchBase = chalkDigitsMatchBase(tokenString, self->significandIntegerDigitsRange, self->significandBase, YES, &significandIntegerDigitsFailures);
          NSIndexSet* significandFractDigitsFailures = nil;
          BOOL siginificandFractDigitsMatchBase = chalkDigitsMatchBase(tokenString, self->significandFractDigitsRange, self->significandBase, YES, &significandFractDigitsFailures);
          if (!significandIntegerDigitsMatchBase || !siginificandFractDigitsMatchBase)
          {
            BOOL maybeScientificNotation = [tokenString isMatchedByRegex:realRegexpPattern];
            if (!maybeScientificNotation)
            {
              decimalNumberError =
                !significandIntegerDigitsMatchBase && (significandIntegerDigitsFailures != nil) ?
                  [CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorBaseDigitsInvalid ranges:significandIntegerDigitsFailures] :
                !significandIntegerDigitsMatchBase ?
                  [CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorBaseDigitsInvalid range:self->significandIntegerDigitsRange] :
                !siginificandFractDigitsMatchBase && (significandFractDigitsFailures != nil) ?
                  [CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorBaseDigitsInvalid ranges:significandFractDigitsFailures] :
                !siginificandFractDigitsMatchBase ?
                  [CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorBaseDigitsInvalid range:self->significandFractDigitsRange] :
                [CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorBaseDigitsInvalid range:tokenString.range];
              decimalNumberError.reasonExtraInformation = @(self->significandBase);
            }//end if (!maybeScientificNotation)
          }//end if (!integerDigitsMatchBase || !siginificandFractDigitsMatchBase)
          done = significandIntegerDigitsMatchBase && siginificandFractDigitsMatchBase;
        }//end if no conflict for base
      }//end if (isMatching)
    }//end if (!done && !errorContext.hasError)
    if (!done && !errorContext.hasError)
    {
      [self resetAnalysis];
      NSArray* matches =
        [realRegexp matchesInString:tokenString options:0 range:NSMakeRange(0, [tokenString length])];
      NSTextCheckingResult* lastMatch = [matches lastObject];
      BOOL isMatching = (matches.count == 1) && (lastMatch.numberOfRanges == (1+14));
      if (isMatching)
      {
        NSRange range = NSRangeZero;
        NSString* rangeString = nil;
        
        range = [lastMatch rangeAtIndex:1];
        rangeString = ((range.location == NSNotFound) || !range.length) ? @"" : [tokenString substringWithRange:range];
        self->significandSignRange = rangeAvoidNSNotFound(range);
        self->significandSign =
          [rangeString isEqualToString:@"+"] ? 1 :
          [rangeString isEqualToString:@"-"] ? -1 :
          1;//may be set to 0 later if significand digits are zero

        range = [lastMatch rangeAtIndex:2];
        rangeString = ((range.location == NSNotFound) || !range.length) ? @"" : [tokenString substringWithRange:range];
        self->significandBasePrefixRange = rangeAvoidNSNotFound(range);
        NSString* significandBasePrefix = rangeString;

        range = [lastMatch rangeAtIndex:3];
        rangeString = ((range.location == NSNotFound) || !range.length) ? @"" : [tokenString substringWithRange:range];
        self->significandIntegerHeadRange = rangeAvoidNSNotFound(range);

        range = [lastMatch rangeAtIndex:4];
        rangeString = ((range.location == NSNotFound) || !range.length) ? @"" : [tokenString substringWithRange:range];
        self->significandIntegerTailZerosRange = rangeAvoidNSNotFound(range);
        
        self->significandIntegerDigitsRange = rangeAvoidNSNotFound(NSRangeUnion(self->significandIntegerHeadRange, self->significandIntegerTailZerosRange));

        range = [lastMatch rangeAtIndex:5];
        rangeString = ((range.location == NSNotFound) || !range.length) ? @"" : [tokenString substringWithRange:range];
        self->significandDecimalSeparatorRange = rangeAvoidNSNotFound(range);

        range = [lastMatch rangeAtIndex:6];
        rangeString = ((range.location == NSNotFound) || !range.length) ? @"" : [tokenString substringWithRange:range];
        self->significandFractHeadZerosRange = rangeAvoidNSNotFound(range);

        range = [lastMatch rangeAtIndex:7];
        rangeString = ((range.location == NSNotFound) || !range.length) ? @"" : [tokenString substringWithRange:range];
        self->significandFractTailRange = rangeAvoidNSNotFound(range);

        self->significandFractDigitsRange = rangeAvoidNSNotFound(NSRangeUnion(self->significandFractHeadZerosRange, self->significandFractTailRange));

        if (!self->significandIntegerDigitsRange.length && !self->significandFractDigitsRange.length)
          self->significandSign = 0;

        range = [lastMatch rangeAtIndex:8];
        NSRange ellipsisRange = rangeAvoidNSNotFound(range);
        rangeString = ((range.location == NSNotFound) || !range.length) ? @"" : [tokenString substringWithRange:range];
        self->hasEllipsis = ![NSString isNilOrEmpty:rangeString];

        range = [lastMatch rangeAtIndex:9];
        rangeString = ((range.location == NSNotFound) || !range.length) ? @"" : [tokenString substringWithRange:range];
        self->significandBaseSuffixRange = rangeAvoidNSNotFound(range);
        
        if (((self->significandIntegerDigitsRange.length !=0 ) || (self->significandFractDigitsRange.length != 0)) &&
            !ellipsisRange.length && !self->significandBaseSuffixRange.length)
        {
          NSRange* digitsRange =
            (self->significandFractDigitsRange.length != 0) ? &self->significandFractDigitsRange :
            (self->significandIntegerDigitsRange.length != 0) ? &self->significandIntegerDigitsRange :
            0;
          NSString* digits = !digitsRange ? nil : [tokenString substringWithRange:*digitsRange];
          __block NSString* suffixFound = nil;
          [baseSuffixes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString* suffix = [obj dynamicCastToClass:[NSString class]];
            if ([digits endsWith:suffix options:NSCaseInsensitiveSearch])
              suffixFound = suffix;
            *stop |= (suffixFound != nil);
          }];
          if (suffixFound && digitsRange)
          {
            NSUInteger suffixLength = suffixFound.length;
            self->significandBaseSuffixRange = NSMakeRange(NSMaxRange(*digitsRange)-suffixLength, suffixLength);
            digitsRange->length -= suffixLength;
          }//end if (suffixFound && digitsRange)
        }//end if ((self->significandFractDigitsRange.length != 0) && !ellipsisRange.length && !self->significandBaseSuffixRange.length)

        NSString* significandBaseSuffix = !self->significandBaseSuffixRange.length ? nil :
          [tokenString substringWithRange:self->significandBaseSuffixRange];

        range = [lastMatch rangeAtIndex:10];
        rangeString = ((range.location == NSNotFound) || !range.length) ? @"" : [tokenString substringWithRange:range];
        self->exponentSymbolRange = rangeAvoidNSNotFound(range);
        NSString* exponentTrimmedSymbolLowercase = !self->exponentSymbolRange.length ? @"" :
          [[[tokenString substringWithRange:self->exponentSymbolRange] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"#"]] lowercaseString];

        range = [lastMatch rangeAtIndex:11];
        rangeString = ((range.location == NSNotFound) || !range.length) ? @"" : [tokenString substringWithRange:range];
        self->exponentSignRange = rangeAvoidNSNotFound(range);
        self->exponentSign =
          [rangeString isEqualToString:@"+"] ? 1 :
          [rangeString isEqualToString:@"-"] ? -1 :
          1;//may be set to 0 later if exponent digits are zero
        
        range = [lastMatch rangeAtIndex:12];
        rangeString = ((range.location == NSNotFound) || !range.length) ? @"" : [tokenString substringWithRange:range];
        self->exponentDigitsBasePrefixRange = rangeAvoidNSNotFound(range);
        NSString* exponentBasePrefix = rangeString;

        range = [lastMatch rangeAtIndex:13];
        rangeString = ((range.location == NSNotFound) || !range.length) ? @"" : [tokenString substringWithRange:range];
        self->exponentDigitsRange = rangeAvoidNSNotFound(range);

        if (!self->exponentDigitsRange.length)
          self->exponentSign = 0;

        range = [lastMatch rangeAtIndex:14];
        rangeString = ((range.location == NSNotFound) || !range.length) ? @"" : [tokenString substringWithRange:range];
        self->exponentDigitsBaseSuffixRange = rangeAvoidNSNotFound(range);
        
        if ((self->exponentDigitsRange.length != 0) && !self->exponentDigitsBaseSuffixRange.length)
        {
          NSString* exponentDigits = [tokenString substringWithRange:self->exponentDigitsRange];
          __block NSString* suffixFound = nil;
          [baseSuffixes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString* suffix = [obj dynamicCastToClass:[NSString class]];
            if ([exponentDigits endsWith:suffix options:NSCaseInsensitiveSearch])
              suffixFound = suffix;
            *stop |= (suffixFound != nil);
          }];
          if (suffixFound)
          {
            NSUInteger suffixLength = suffixFound.length;
            self->exponentDigitsBaseSuffixRange = NSMakeRange(NSMaxRange(self->exponentDigitsRange)-suffixLength, suffixLength);
            self->exponentDigitsRange.length -= suffixLength;
          }//end if (suffixFound)
        }//end if ((self->exponentDigitsRange.length != 0) && !self->exponentDigitsBaseSuffixRange.length)
        NSString* exponentBaseSuffix = !self->exponentDigitsBaseSuffixRange.length ? nil :
          [tokenString substringWithRange:self->exponentDigitsBaseSuffixRange];

        BOOL hasSignificandBasePrefix = ![NSString isNilOrEmpty:significandBasePrefix];
        BOOL hasSignificandBaseSuffix = ![NSString isNilOrEmpty:significandBaseSuffix];
        BOOL hasExponentBasePrefix = ![NSString isNilOrEmpty:exponentBasePrefix];
        BOOL hasExponentBaseSuffix = ![NSString isNilOrEmpty:exponentBaseSuffix];
        int significandBaseFromPrefix = !hasSignificandBasePrefix ? 0 : [context baseFromPrefix:significandBasePrefix];
        int significandBaseFromSuffix = !hasSignificandBaseSuffix ? 0 : [context baseFromSuffix:significandBaseSuffix];
        int exponentBaseFromPrefix = !hasExponentBasePrefix ? 0 : [context baseFromPrefix:exponentBasePrefix];
        int exponentBaseFromSuffix = !hasExponentBaseSuffix ? 0 : [context baseFromSuffix:exponentBaseSuffix];
        if (hasSignificandBasePrefix && hasSignificandBaseSuffix && (significandBaseFromPrefix != significandBaseFromSuffix))
          [errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorBaseDecorationConflict
                                                              range:self->token.range] replace:NO];
        else if (hasSignificandBasePrefix && !significandBasePrefix)
          [errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorBaseDecorationInvalid
                           range:self->significandBasePrefixRange] replace:NO];
        else if (hasSignificandBaseSuffix && !significandBaseFromSuffix)
          [errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorBaseDecorationInvalid
                           range:self->significandBaseSuffixRange] replace:NO];
        else if (hasExponentBasePrefix && hasExponentBaseSuffix && (exponentBaseFromPrefix != exponentBaseFromSuffix))
          [errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorBaseDecorationConflict
                                                              range:self->token.range] replace:NO];
        else if (hasExponentBasePrefix && !exponentBaseFromPrefix)
          [errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorBaseDecorationInvalid
                           range:self->exponentDigitsBasePrefixRange] replace:NO];
        else if (hasExponentBaseSuffix && !exponentBaseFromSuffix)
          [errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorBaseDecorationInvalid
                           range:self->exponentDigitsBaseSuffixRange] replace:NO];
        else//if no conflict for bases
        {
          self->significandBase =
            significandBaseFromPrefix ? significandBaseFromPrefix :
            significandBaseFromSuffix ? significandBaseFromSuffix :
            context.computationConfiguration.baseDefault;
          self->exponentDigitsBase =
            exponentBaseFromPrefix ? exponentBaseFromPrefix :
            exponentBaseFromSuffix ? exponentBaseFromSuffix :
            self->significandBase;
          self->exponentBaseToPow = [exponentTrimmedSymbolLowercase isEqualToString:@"p"] ? 2 : 10;
          NSIndexSet* significandIntegerDigitsFailures = nil;
          NSIndexSet* significandFractDigitsFailures = nil;
          NSIndexSet* exponentsDigitsFailures = nil;
          BOOL significandIntegerDigitsMatchBase = chalkDigitsMatchBase(tokenString, self->significandIntegerDigitsRange, self->significandBase, YES, &significandIntegerDigitsFailures);
          BOOL significandFractDigitsMatchBase = chalkDigitsMatchBase(tokenString, self->significandFractDigitsRange, self->significandBase, YES, &significandFractDigitsFailures);
          BOOL exponentDigitsMatchBase = chalkDigitsMatchBase(tokenString, self->exponentDigitsRange, self->exponentDigitsBase, YES, &exponentsDigitsFailures);
          if (!significandIntegerDigitsMatchBase || !significandFractDigitsMatchBase || !exponentDigitsMatchBase)
          {
            realNumberError =
              !significandIntegerDigitsMatchBase && (significandIntegerDigitsFailures != nil) ?
                [CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorBaseDigitsInvalid ranges:significandIntegerDigitsFailures] :
              !significandIntegerDigitsMatchBase ?
                [CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorBaseDigitsInvalid range:self->significandIntegerDigitsRange] :
              !significandFractDigitsMatchBase && (significandFractDigitsFailures != nil) ?
                [CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorBaseDigitsInvalid ranges:significandFractDigitsFailures] :
              !significandFractDigitsMatchBase ?
                [CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorBaseDigitsInvalid range:self->significandFractDigitsRange] :
              !exponentDigitsMatchBase && (exponentsDigitsFailures != nil) ?
                [CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorBaseDigitsInvalid ranges:exponentsDigitsFailures] :
              !exponentDigitsMatchBase ?
                [CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorBaseDigitsInvalid range:self->exponentDigitsRange] :
              [CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorBaseDigitsInvalid range:tokenString.range];
            realNumberError.reasonExtraInformation =
              !significandIntegerDigitsMatchBase ? @(self->significandBase) :
              !significandFractDigitsMatchBase ? @(self->significandBase) :
              !exponentDigitsMatchBase ? @(self->exponentDigitsBase) :
              nil;
          }//end if (!significandIntegerDigitsMatchBase || !significandFractDigitsMatchBase || !exponentDigitsMatchBase)
          done = significandIntegerDigitsMatchBase && significandFractDigitsMatchBase && exponentDigitsMatchBase;
        }//end if no conflict for base
      }//end if (isMatching)
    }//end if (!done && !errorContext.hasError)

    if (!done && !errorContext.hasError)
    {
      if (integerNumberError)
        [errorContext setError:integerNumberError replace:YES];
      else if (decimalNumberError)
        [errorContext setError:decimalNumberError replace:YES];
      else if (realNumberError)
        [errorContext setError:realNumberError replace:YES];
    }//end if (!done && !errorContext.hasError)

  }//end if (![NSString isNilOrEmpty:tokenString])
  
  result = done;
  return result;
}
//end analyzeWithContext:

-(NSString*) description
{
  NSString* result = nil;
  NSString* tokenString = self->token.value;
  result = [NSString stringWithFormat:
    @"\n[%@][%@][%@][%@][%@][%@][%@][%@][%@]"
     "\n[%@][%@][%@][%@][%@][%@]",
    !self->significandSignRange.length ? @"" : [tokenString substringWithRange:self->significandSignRange],
    !self->significandBasePrefixRange.length ? @"" : [tokenString substringWithRange:self->significandBasePrefixRange],
    !self->significandIntegerHeadRange.length ? @"" : [tokenString substringWithRange:self->significandIntegerHeadRange],
    !self->significandIntegerTailZerosRange.length ? @"" : [tokenString substringWithRange:self->significandIntegerTailZerosRange],
    !self->significandIntegerDigitsRange.length ? @"" : [tokenString substringWithRange:self->significandIntegerDigitsRange],
    !self->significandDecimalSeparatorRange.length ? @"" : [tokenString substringWithRange:self->significandDecimalSeparatorRange],
    !self->significandFractHeadZerosRange.length ? @"" : [tokenString substringWithRange:self->significandFractHeadZerosRange],
    !self->significandFractTailRange.length ? @"" : [tokenString substringWithRange:self->significandFractTailRange],
    !self->significandFractDigitsRange.length ? @"" : [tokenString substringWithRange:self->significandFractDigitsRange],
    !self->significandBaseSuffixRange.length ? @"" : [tokenString substringWithRange:self->significandBaseSuffixRange],
    !self->exponentSymbolRange.length ? @"" : [tokenString substringWithRange:self->exponentSymbolRange],
    !self->exponentSignRange.length ? @"" : [tokenString substringWithRange:self->exponentSignRange],
    !self->exponentDigitsBasePrefixRange.length ? @"" : [tokenString substringWithRange:self->exponentDigitsBasePrefixRange],
    !self->exponentDigitsRange.length ? @"" : [tokenString substringWithRange:self->exponentDigitsRange],
    !self->exponentDigitsBaseSuffixRange.length ? @"" : [tokenString substringWithRange:self->exponentDigitsBaseSuffixRange]
  ];
  return result;
}
//end description

-(CHChalkValue*) chalkValueWithContext:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  NSString* tokenString = self->token.value;
  
  CHChalkErrorContext* errorContext = context.errorContext;
  if ([NSString isNilOrEmpty:tokenString])
    [errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown] replace:NO];
  
  NSRange significandIntegerDigitsRangeAdapted = self->significandIntegerDigitsRange;
  NSString* significandIntegerDigitsAdapted = adaptString(tokenString, self->significandIntegerDigitsRange, &significandIntegerDigitsRangeAdapted);
  NSRange significandIntegerTailZerosRangeAdapted = self->significandIntegerTailZerosRange;
  NSString* significandIntegerTailZerosAdapted = adaptString(tokenString, self->significandIntegerTailZerosRange, &significandIntegerTailZerosRangeAdapted);
  NSRange significandFractDigitsRangeAdapted = self->significandFractDigitsRange;
  NSString* significandFractDigitsAdapted = adaptString(tokenString, self->significandFractDigitsRange, &significandFractDigitsRangeAdapted);
  NSRange significandFractTailRangeAdapted = self->significandFractTailRange;
  NSString* significandFractTailAdapted = adaptString(tokenString, self->significandFractTailRange, &significandFractTailRangeAdapted);
  NSRange exponentDigitsRangeAdapted = self->exponentDigitsRange;
  NSString* exponentDigitsAdapted = adaptString(tokenString, self->exponentDigitsRange, &exponentDigitsRangeAdapted);
  if (!result && !errorContext.hasError)
  {
    BOOL isSimpleZero =
      (!significandIntegerDigitsRangeAdapted.length && !significandFractDigitsRangeAdapted.length &&
      (!self->exponentSymbolRange.length || !exponentDigitsRangeAdapted.length));
    if (isSimpleZero)
    {
      chalk_gmp_value_t value = {CHALK_VALUE_TYPE_UNDEFINED, 0};
      chalkGmpValueMakeInteger(&value, context.gmpPool);
      mpz_set_si(value.integer, 0);
      result = [[[CHChalkValueNumberGmp alloc] initWithToken:self->token value:&value naturalBase:self->significandBase context:context] autorelease];
      if (!result)
        [errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:self->token.range] replace:NO];
      chalkGmpValueClear(&value, YES, context.gmpPool);
    }//end if (isSimpleZero)
  }//end if (!result && !errorContext.hasError)
  
  if (!result && !errorContext.hasError)
  {
    BOOL isSimpleInteger =
      !significandFractDigitsRangeAdapted.length &&
      (!self->exponentSymbolRange.length || !exponentDigitsRangeAdapted.length);
    BOOL isAllowedInteger = (chalkGmpMaxDigitsInBase(significandIntegerDigitsRangeAdapted.length, self->significandBase, 2, context.gmpPool) <= context.computationConfiguration.softIntegerMaxBits);
    if (isSimpleInteger && isAllowedInteger)
    {
      chalk_gmp_value_t value = {CHALK_VALUE_TYPE_UNDEFINED, 0};
      chalkGmpValueMakeInteger(&value, context.gmpPool);
      mpz_set_str(value.integer, [significandIntegerDigitsAdapted UTF8String], self->significandBase);
      if (self->significandSign<0)
        mpz_neg(value.integer, value.integer);
      result = [[[CHChalkValueNumberGmp alloc] initWithToken:self->token value:&value naturalBase:self->significandBase context:context] autorelease];
      if (!result)
        [errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:self->token.range] replace:NO];
      chalkGmpValueClear(&value, YES, context.gmpPool);
    }//end if (isSimpleInteger && isAllowedInteger)
  }//end if (!result && !errorContext.hasError)

  if (!result && !errorContext.hasError)
  {
    BOOL isSimpleDecimal = (!self->exponentSymbolRange.length || !exponentDigitsRangeAdapted.length);
    NSUInteger numeratorDigitsCount = significandIntegerDigitsRangeAdapted.length+significandFractDigitsRangeAdapted.length;
    NSUInteger denominatorDigitsCount = significandFractDigitsRangeAdapted.length+1;
    BOOL overflow = (numeratorDigitsCount<significandIntegerDigitsRangeAdapted.length) ||
                    (numeratorDigitsCount<significandFractDigitsRangeAdapted.length);
    BOOL isAllowedNumerator = !overflow &&
      (chalkGmpMaxDigitsInBase(numeratorDigitsCount, self->significandBase, 2, context.gmpPool) <= context.computationConfiguration.softIntegerMaxBits);
    BOOL isAllowedDenumerator = //first check softIntegerMaxBits, softIntegerMaxDenomintatorBits will be check in checkFraction after simplification
      (chalkGmpMaxDigitsInBase(denominatorDigitsCount, self->significandBase, 2, context.gmpPool) <= context.computationConfiguration.softIntegerMaxBits);
    if (isSimpleDecimal && isAllowedNumerator && isAllowedDenumerator && !self->hasEllipsis)
    {
      NSMutableString* buffer = [[NSMutableString alloc] initWithCapacity:significandIntegerDigitsRangeAdapted.length+significandFractDigitsRangeAdapted.length];
      if (buffer)
      {
        chalk_gmp_value_t value = {CHALK_VALUE_TYPE_UNDEFINED, 0};
        chalkGmpValueMakeFraction(&value, context.gmpPool);
        [buffer appendString:significandIntegerDigitsAdapted];
        [buffer appendString:significandFractDigitsAdapted];
        mpz_set_str(mpq_numref(value.fraction), [buffer UTF8String], self->significandBase);
        [buffer release];
        mpz_set_ui(mpq_denref(value.fraction), self->significandBase);
        mpz_pow_ui(mpq_denref(value.fraction), mpq_denref(value.fraction), significandFractDigitsRangeAdapted.length);
        mpq_canonicalize(value.fraction);
        if (self->significandSign<0)
          mpq_neg(value.fraction, value.fraction);
        if ([CHChalkValueNumberGmp checkFraction:value.fraction token:self->token setError:NO context:context])
        {
          result = [[[CHChalkValueNumberGmp alloc] initWithToken:self->token value:&value naturalBase:self->significandBase context:context] autorelease];
          if (!result)
            [errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:self->token.range] replace:NO];
        }//end if ([CHChalkValueNumberGmp checkFraction:value.fraction token:self->token setError:NO context:context])
        chalkGmpValueClear(&value, YES, context.gmpPool);
      }//end if (buffer)
    }//end if (isSimpleDecimal && isAllowedNumerator && isAllowedDenumerator && !self->hasEllipsis)
  }//end if (!result && !errorContext.hasError)

  if (!result && !errorContext.hasError)
  {
    if (self->exponentSign>0)
    {
      NSUInteger significandDigitsCount = significandIntegerDigitsRangeAdapted.length+significandFractDigitsRangeAdapted.length;
      BOOL overflow = (significandDigitsCount<significandIntegerDigitsRangeAdapted.length) ||
                      (significandDigitsCount<significandFractDigitsRangeAdapted.length);
      BOOL isAllowedInteger = !overflow &&
        (chalkGmpMaxDigitsInBase(significandDigitsCount, self->significandBase, 2, context.gmpPool) <= context.computationConfiguration.softIntegerMaxBits) &&
        (chalkGmpMaxDigitsInBase(exponentDigitsRangeAdapted.length, self->exponentDigitsBase, 2, context.gmpPool) <= context.computationConfiguration.softIntegerMaxBits);
      if (isAllowedInteger)
      {
        int localExponentBaseToPow = self->exponentBaseToPow;
        mpz_t e;
        mpz_t tmp1;
        mpz_t tmp2;
        mpzDepool(e, context.gmpPool);
        mpzDepool(tmp1, context.gmpPool);
        mpzDepool(tmp2, context.gmpPool);
        mpz_set_str(e, [exponentDigitsAdapted UTF8String], self->exponentDigitsBase);
        mpz_set_nsui(tmp1, significandIntegerDigitsRangeAdapted.length);
        mpz_set_nsui(tmp2, significandFractDigitsRangeAdapted.length);
        isAllowedInteger &= mpz_fits_exponent_p(e, localExponentBaseToPow, context.gmpPool);
        if (!isAllowedInteger){
        }
        else if (!significandFractDigitsRangeAdapted.length){
        }
        else if (self->significandBase == self->exponentBaseToPow)
          isAllowedInteger &= (mpz_cmp(e, tmp2)>=0);
        else//if (self->significandBase != self->exponentBaseToPow)
        {
          NSUInteger equivalentPower = chalkGmpGetEquivalentBasePower(self->exponentBaseToPow, mpz_get_nsui(e), self->significandBase);
          isAllowedInteger &= equivalentPower && (equivalentPower >= significandFractDigitsRangeAdapted.length);
          if (isAllowedInteger)
          {
            localExponentBaseToPow = self->significandBase;
            mpz_set_nsui(e, equivalentPower);
          }//end if (isAllowedInteger)
        }//end if (self->significandBase != self->exponentBaseToPow)

        if (isAllowedInteger)
        {
          mpz_sub(tmp1, tmp1, tmp2);
          mpz_add(tmp1, tmp1, e);
        }//end if (isAllowedInteger)

        if (!isAllowedInteger){
        }
        else if (!mpz_fits_nsui_p(tmp1))
          isAllowedInteger = NO;
        else
          isAllowedInteger &= (chalkGmpMaxDigitsInBase(mpz_get_nsui(tmp1), self->significandBase, 2, context.gmpPool) <= context.computationConfiguration.softIntegerMaxBits);

        if (isAllowedInteger)
        {
          NSMutableString* digitsString =
            [[NSMutableString alloc] initWithCapacity:significandIntegerDigitsRangeAdapted.length+significandFractDigitsRangeAdapted.length];
          if (!digitsString)
            [errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:self->token.range] replace:NO];
          else//if (digitsString)
          {
            [digitsString appendString:significandIntegerDigitsAdapted];
            [digitsString appendString:significandFractDigitsAdapted];
            mpz_set_str(tmp1, [digitsString UTF8String], self->significandBase);
            [digitsString release];
            if (self->significandSign<0)
              mpz_neg(tmp1, tmp1);
            mpz_sub(e, e, tmp2);//tmp2 still hold number of fract digits
            NSUInteger eui = mpz_get_nsui(e);
            mpz_ui_pow_ui(e, localExponentBaseToPow, eui);
            mpz_mul(tmp2, tmp1, e);
            chalk_gmp_value_t value = {0};
            chalkGmpValueMakeInteger(&value, context.gmpPool);
            mpz_swap(value.integer, tmp2);
            result = [[[CHChalkValueNumberGmp alloc] initWithToken:self->token value:&value naturalBase:self->significandBase context:context] autorelease];
            if (!result)
              [errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:self->token.range] replace:NO];
            chalkGmpValueClear(&value, YES, context.gmpPool);
          }//end if (digitsString)
        }//end if (isAllowedInteger)
        mpzRepool(e, context.gmpPool);
        mpzRepool(tmp1, context.gmpPool);
        mpzRepool(tmp2, context.gmpPool);
      }//end if (willBeAllowedInteger)
    }//end if (self->exponentSign>0)
    else if (self->exponentSign<0)
    {
      if (!significandFractTailRangeAdapted.length)
      {
        BOOL isAllowedExponent =
          (chalkGmpMaxDigitsInBase(exponentDigitsRangeAdapted.length, self->exponentDigitsBase, 2, context.gmpPool) <= context.computationConfiguration.softIntegerMaxBits);
        if (isAllowedExponent)
        {
          mpz_t e;
          mpz_t tmp;
          mpzDepool(e, context.gmpPool);
          mpzDepool(tmp, context.gmpPool);
          mpz_set_str(e, [exponentDigitsAdapted UTF8String], self->exponentDigitsBase);
          isAllowedExponent &= mpz_fits_exponent_p(e, self->exponentBaseToPow, context.gmpPool);
          if (isAllowedExponent)
          {
            BOOL isInteger = NO;
            mpz_set_nsui(tmp, significandIntegerTailZerosRangeAdapted.length);
            if (self->significandBase == self->exponentBaseToPow)
              isInteger = (mpz_cmp(tmp, e)>=0);
            else//if (self->significandBase != self->exponentBaseToPow)
            {
              NSUInteger equivalentPow = chalkGmpGetEquivalentBasePower(self->exponentBaseToPow, mpz_get_nsui(e), self->significandBase);
              if (equivalentPow)
              {
                mpz_set_nsui(e, equivalentPow);
                isInteger = equivalentPow && (mpz_cmp(tmp, e)>=0);
              }//end if (equivalentPow)
            }//end if (self->significandBase != self->exponentBaseToPow)
            if (isInteger)
            {
              chalk_gmp_value_t value = {0};
              chalkGmpValueMakeInteger(&value, context.gmpPool);
              mpz_set_str(value.integer,
                [[significandIntegerDigitsAdapted substringWithRange:NSMakeRange(
                  0,
                  significandIntegerDigitsRangeAdapted.length-mpz_get_nsui(e))] UTF8String],
                self->significandBase);
              if (self->significandSign<0)
                mpz_neg(value.integer, value.integer);
              result = [[[CHChalkValueNumberGmp alloc] initWithToken:self->token value:&value naturalBase:self->significandBase context:context] autorelease];
              if (!result)
                [errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:self->token.range] replace:NO];
              chalkGmpValueClear(&value, YES, context.gmpPool);
            }//end if (isInteger)
          }//end if (isAllowedExponent)
          mpzRepool(e, context.gmpPool);
          mpzRepool(tmp, context.gmpPool);
        }//end if (isAllowedExponent)
      }//end if (!significandFractTailRangeAdapted.length)
    }//end if (self->exponentSign<0)
  }//end if (!result && !errorContext.hasError)
  
  //let's try a fraction instead of an integer
  if (!result && !errorContext.hasError)
  {
    NSUInteger significandDigitsCount = significandIntegerDigitsRangeAdapted.length+significandFractDigitsRangeAdapted.length;
    BOOL overflow = (significandDigitsCount<significandIntegerDigitsRangeAdapted.length) ||
                    (significandDigitsCount<significandFractDigitsRangeAdapted.length);
    BOOL isAllowedNumerator = !overflow &&
      (chalkGmpMaxDigitsInBase(significandDigitsCount, self->significandBase, 2, context.gmpPool) <= context.computationConfiguration.softIntegerMaxBits);
    if (!isAllowedNumerator){
    }
    else if (self->significandBase == self->exponentBaseToPow)
    {
      mpz_t e;
      mpz_t tmp;
      mpzDepool(e, context.gmpPool);
      mpzDepool(tmp, context.gmpPool);
      mpz_set_str(e, [exponentDigitsAdapted UTF8String], self->exponentDigitsBase);
      if (self->exponentSign<0)
        mpz_neg(e, e);
      mpz_set_nsui(tmp, significandFractDigitsRangeAdapted.length);
      mpz_sub(e, e, tmp);
      if (mpz_sgn(e)<0)//other cases should have been handled in the integer case
      {
        mpz_abs(e, e);
        BOOL isAllowedExponent = mpz_fits_exponent_p(e, self->exponentBaseToPow, context.gmpPool);
        if (isAllowedExponent)
        {
          NSUInteger denominatorDigitsCount = mpz_get_nsui(e)+1;
          BOOL isAllowedDenominator = (chalkGmpMaxDigitsInBase(denominatorDigitsCount, self->exponentBaseToPow, 2, context.gmpPool) <= context.computationConfiguration.softIntegerMaxBits);
          if (isAllowedDenominator)
          {
            NSMutableString* buffer = [[NSMutableString alloc] initWithCapacity:significandIntegerDigitsRangeAdapted.length+significandFractDigitsRangeAdapted.length];
            if (buffer)
            {
              chalk_gmp_value_t value = {CHALK_VALUE_TYPE_UNDEFINED, 0};
              chalkGmpValueMakeFraction(&value, context.gmpPool);
              [buffer appendString:significandIntegerDigitsAdapted];
              [buffer appendString:significandFractDigitsAdapted];
              mpz_set_str(mpq_numref(value.fraction), [buffer UTF8String], self->significandBase);
              [buffer release];
              mpz_set_si(tmp, self->exponentBaseToPow);
              mpz_pow_ui(mpq_denref(value.fraction), tmp, mpz_get_ui(e));
              mpq_canonicalize(value.fraction);
              if (self->significandSign<0)
                mpq_neg(value.fraction, value.fraction);
              if ([CHChalkValueNumberGmp checkFraction:value.fraction token:self->token setError:NO context:context])
              {
                result = [[[CHChalkValueNumberGmp alloc] initWithToken:self->token value:&value naturalBase:self->significandBase context:context] autorelease];
                if (!result)
                  [errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:self->token.range] replace:NO];
              }//end if ([CHChalkValueNumberGmp checkFraction:value.fraction token:self->token setError:NO context:context])
              chalkGmpValueClear(&value, YES, context.gmpPool);
            }//end if (buffer)
          }//end if (isAllowedDenominator)
        }//end if (isAllowedExponent)
      }//end if (mpz_sgn(e)<0)
      mpzRepool(e, context.gmpPool);
      mpzRepool(tmp, context.gmpPool);
    }//end if (self->significandBase == self->exponentBaseToPow)
    else if (self->significandBase != self->exponentBaseToPow)
    {
      NSUInteger fromSignificandDigitsCount = significandFractDigitsRangeAdapted.length+1;
      NSUInteger fromSignificandBitsCount =
        chalkGmpMaxDigitsInBase(fromSignificandDigitsCount, self->significandBase, 2, context.gmpPool);
      NSUInteger fromBaseToPowDigitsCount = exponentDigitsRangeAdapted.length;
      NSUInteger fromBaseToPowBitsCount =
        chalkGmpMaxDigitsInBase(fromBaseToPowDigitsCount, self->exponentDigitsBase, 2, context.gmpPool);
      BOOL trivialOverflow = (MAX(fromSignificandBitsCount, fromBaseToPowBitsCount)>context.computationConfiguration.softIntegerMaxBits);
      if (!trivialOverflow)
      {
        mpz_t e1;
        mpz_t e2;
        mpzDepool(e1, context.gmpPool);
        mpzDepool(e2, context.gmpPool);
        mpz_set_nssi(e1, significandFractDigitsRangeAdapted.length);
        BOOL fitsExponents = mpz_fits_exponent_p(e1, self->significandBase, context.gmpPool);
        if (fitsExponents)
        {
          mpz_set_str(e2, [exponentDigitsAdapted UTF8String], self->exponentDigitsBase);
          fitsExponents &= mpz_fits_exponent_p(e2, self->exponentBaseToPow, context.gmpPool);
        }//end if (fitsExponents)
        NSMutableString* buffer = !fitsExponents ? nil :
          [[NSMutableString alloc] initWithCapacity:significandIntegerDigitsRangeAdapted.length+significandFractDigitsRangeAdapted.length];
        if (buffer)
        {
          chalk_gmp_value_t value = {CHALK_VALUE_TYPE_UNDEFINED, 0};
          chalkGmpValueMakeFraction(&value, context.gmpPool);
          [buffer appendString:significandIntegerDigitsAdapted];
          [buffer appendString:significandFractDigitsAdapted];
          mpz_set_str(mpq_numref(value.fraction), [buffer UTF8String], self->significandBase);
          mpz_set_si(mpq_denref(value.fraction), 1);
          [buffer release];
          mpz_t tmp1;
          mpz_t tmp2;
          mpzDepool(tmp1, context.gmpPool);
          mpzDepool(tmp2, context.gmpPool);
          mpz_set_si(tmp1, self->significandBase);
          mpz_pow_ui(mpq_denref(value.fraction), tmp1, mpz_get_ui(e1));
          mpz_set_si(tmp1, self->exponentBaseToPow);
          mpz_pow_ui(tmp2, tmp1, mpz_get_ui(e2));
          if (self->exponentSign>=0)
          {
            mpz_mul(tmp1, mpq_numref(value.fraction), tmp2);
            mpz_swap(tmp1, mpq_numref(value.fraction));
          }//end if (self->exponentSign>=0)
          else//if (self->exponentSign<0)
          {
            mpz_mul(tmp1, mpq_denref(value.fraction), tmp2);
            mpz_swap(tmp1, mpq_denref(value.fraction));
          }//end if (self->exponentSign<0)
          mpzRepool(tmp1, context.gmpPool);
          mpzRepool(tmp2, context.gmpPool);
          if (self->significandSign<0)
            mpq_neg(value.fraction, value.fraction);
          mpq_canonicalize(value.fraction);
          if ([CHChalkValueNumberGmp checkFraction:value.fraction token:self->token setError:NO context:context])
          {
            result = [[[CHChalkValueNumberGmp alloc] initWithToken:self->token value:&value naturalBase:self->significandBase context:context] autorelease];
            if (!result)
              [errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:self->token.range] replace:NO];
          }//end if ([CHChalkValueNumberGmp checkFraction:value.fraction token:self->token setError:NO context:context])
          chalkGmpValueClear(&value, YES, context.gmpPool);
        }//end if (buffer)
        mpzRepool(e1, context.gmpPool);
        mpzRepool(e2, context.gmpPool);
      }//end if (!trivialOverflow)
    }//end if (self->significandBase != self->exponentBaseToPow)
  }//end if (!result && !errorContext.hasError)
  
  if (!result && !errorContext.hasError)
  {//all tried to make exact data failed. We now rely on parsing a float.
    NSString* stringToParse = nil;
    NSString* exponentTrimmedSymbolLowercase = !self->exponentSymbolRange.length ? @"" :
      [[[tokenString substringWithRange:self->exponentSymbolRange] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"#"]] lowercaseString];
    BOOL trivialCase = !self->significandBasePrefixRange.length && !self->significandBaseSuffixRange.length &&
                       (!self->exponentSymbolRange.length || [exponentTrimmedSymbolLowercase isEqualToString:@"e"]) &&
                       (self->exponentBaseToPow == self->significandBase) && (self->exponentDigitsBase == 10) &&
                       !self->exponentDigitsBasePrefixRange.length;
		BOOL customPowerOfBase = NO;
    NSMutableIndexSet* ranges = [NSMutableIndexSet indexSet];
    [ranges addIndexesInRange:self->significandSignRange];
    [ranges addIndexesInRange:self->significandIntegerDigitsRange];
    [ranges addIndexesInRange:self->significandDecimalSeparatorRange];
    [ranges addIndexesInRange:self->significandFractDigitsRange];
    [ranges addIndexesInRange:self->exponentSymbolRange];
    [ranges addIndexesInRange:self->exponentSignRange];
    [ranges addIndexesInRange:self->exponentDigitsRange];
    __block NSRange globalRange = NSRangeZero;
    __block NSUInteger rangesCount = 0;
    [ranges enumerateRangesUsingBlock:^(NSRange range, BOOL *stop) {
      ++rangesCount;
      globalRange = NSRangeUnion(globalRange, range);
    }];
    if (!rangesCount || !globalRange.length){
    }
    else if (trivialCase && (rangesCount == 1))
      stringToParse = [[tokenString substringWithRange:globalRange] retain];
    else//if (!trivialCase)
    {
      __block NSMutableString* stringBuilder = [[NSMutableString alloc] initWithCapacity:globalRange.length];
      if (self->exponentBaseToPow == self->significandBase)
      {
				[stringBuilder appendString:[tokenString substringWithRange:self->significandSignRange]];
				[stringBuilder appendString:significandIntegerDigitsAdapted];
				[stringBuilder appendString:[tokenString substringWithRange:self->significandDecimalSeparatorRange]];
        [stringBuilder appendString:significandFractDigitsAdapted];
				[stringBuilder appendString:(self->significandBase<=10) ? @"e" : @"#e"];
				[stringBuilder appendString:[tokenString substringWithRange:self->exponentSignRange]];
				if (self->exponentDigitsBase == 10)
  				[stringBuilder appendString:exponentDigitsAdapted];
				else//if (self->exponentDigitsBase != 10)
				{
					mpz_t e;
					mpzDepool(e, context.gmpPool);
					mpz_set_str(e, [exponentDigitsAdapted UTF8String], self->exponentDigitsBase);
					char* e10 = [context depoolMemoryForMpzGetStr:e base:10];
					if (e10)
					{
						mpz_get_str(e10, 10, e);
						[stringBuilder appendFormat:@"%s", e10];
						[context repoolMemory:e10];
					}//end if (e10)
				}//end if (self->exponentDigitsBase != 10)
			}//end if (self->exponentBaseToPow == self->significandBase)
			else if ((self->exponentBaseToPow == 2) && ((self->significandBase == 2) || (self->significandBase == 16)))
			{
				[stringBuilder appendString:[tokenString substringWithRange:self->significandSignRange]];
				[stringBuilder appendString:significandIntegerDigitsAdapted];
				[stringBuilder appendString:[tokenString substringWithRange:self->significandDecimalSeparatorRange]];
				[stringBuilder appendString:significandFractDigitsAdapted];
				[stringBuilder appendString:(self->significandBase<=10) ? @"p" : @"#p"];
				[stringBuilder appendString:[tokenString substringWithRange:self->exponentSignRange]];
				if (self->exponentDigitsBase == 10)
  				[stringBuilder appendString:exponentDigitsAdapted];
				else//if (self->exponentDigitsBase != 10)
				{
					mpz_t e;
					mpzDepool(e, context.gmpPool);
					mpz_set_str(e, [exponentDigitsAdapted UTF8String], self->exponentDigitsBase);
					char* e10 = [context depoolMemoryForMpzGetStr:e base:10];
					if (e10)
					{
						mpz_get_str(e10, 10, e);
						[stringBuilder appendFormat:@"%s", e10];
						[context repoolMemory:e10];
					}//end if (e10)
				}//end if (self->exponentDigitsBase != 10)
			}//end if ((self->exponentBaseToPow == 2) && ((self->significandBase == 2) || (self->significandBase == 16)))
			else//if (self->exponentBaseToPow != self->significandBase)
			{
				[stringBuilder appendString:[tokenString substringWithRange:self->significandSignRange]];
				[stringBuilder appendString:significandIntegerDigitsAdapted];
				[stringBuilder appendString:[tokenString substringWithRange:self->significandDecimalSeparatorRange]];
				[stringBuilder appendString:significandFractDigitsAdapted];
				customPowerOfBase = YES;
			}//end if (self->exponentBaseToPow != self->significandBase)
			stringToParse = [stringBuilder copy];
      [stringBuilder release];
    }//end if (!trivialCase)
    if (![NSString isNilOrEmpty:stringToParse])
    {
			chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
      chalk_gmp_value_t value = {CHALK_VALUE_TYPE_UNDEFINED, 0};
      mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
      chalkGmpValueMakeRealApprox(&value, prec, context.gmpPool);
      mpfir_set_str(value.realApprox, [stringToParse UTF8String], self->significandBase);
			if (customPowerOfBase)
			{
				BOOL isAllowedExponent =
				  (chalkGmpMaxDigitsInBase(exponentDigitsRangeAdapted.length, self->exponentDigitsBase, 2, context.gmpPool) <= context.computationConfiguration.softIntegerMaxBits);
				if (!isAllowedExponent)
					[errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorIntegerOverflow range:self->token.range] replace:NO];
				if (!errorContext.hasError)
				{
					mpz_t e;
					mpzDepool(e, context.gmpPool);
					mpz_set_str(e, [exponentDigitsAdapted UTF8String], self->exponentDigitsBase);
					if (!mpz_fits_exponent_p(e, self->exponentBaseToPow, context.gmpPool))
						[errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorIntegerOverflow range:self->token.range] replace:NO];
					if (!errorContext.hasError)
					{
            mpfir_t tmp;
            mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
            mpfirDepool(tmp, prec, context.gmpPool);
            mpfir_set_si(tmp, self->exponentBaseToPow);
            mpfir_pow_z(tmp, tmp, e);
            if (self->exponentSign>=0)
              mpfir_mul(value.realApprox, value.realApprox, tmp);
            else//if (self->exponentSign<0)
              mpfir_div(value.realApprox, value.realApprox, tmp);
            mpfirRepool(tmp, context.gmpPool);
					}//end if (!errorContext.hasError)
					mpzRepool(e, context.gmpPool);
				}//end if (!errorContext.hasError)
			}//if (customPowerOfBase)
			if (!errorContext.hasError)
				result = [[[CHChalkValueNumberGmp alloc] initWithToken:self->token value:&value naturalBase:self->significandBase context:context] autorelease];
      if (!result)
        [errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:self->token.range] replace:NO];
		  if (result)
				result.evaluationComputeFlags = chalkGmpFlagsMake();
      chalkGmpValueClear(&value, YES, context.gmpPool);
			chalkGmpFlagsRestore(oldFlags);
    }//end if (![NSString isNilOrEmpty:stringToParse])
    [stringToParse release];
  }//end if (!result && !errorContext.hasError)
	
	if (!result && !errorContext.hasError)
		[errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:self->token.range] replace:NO];

  return result;
}
//end chalkValueWithContext:

@end
