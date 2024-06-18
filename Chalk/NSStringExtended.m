//
//  NSStringExtended.m
//  Chalk
//
//  Created by Pierre Chatelier on 21/07/05.
//  Copyright 2005-2014 Pierre Chatelier. All rights reserved.

//this file is an extension of the NSWorkspace class

#import "NSStringExtended.h"

#import "NSObjectExtended.h"

@implementation NSString (Extended)

+(BOOL) isNilOrEmpty:(NSString*)string
{
  BOOL result = !string || [string isEqualToString:@""];
  return result;
}
//end isNilOrEmpty:

+(BOOL) string:(NSString*)s1 equals:(NSString*)s2
{
  BOOL result = [self string:s1 equals:s2 options:0];
  return result;
}
//end string:equals:options:

+(BOOL) string:(NSString*)s1 equals:(NSString*)s2 options:(NSStringCompareOptions)options
{
  BOOL result = (!s1 && !s2) || (s1 && s2 && ([s1 compare:s2 options:options] == NSOrderedSame));
  return result;
}
//end string:equals:options:

-(NSRange) range
{
  NSRange result = NSMakeRange(0, self.length);
  return result;
}
//end range

-(BOOL) startsWith:(NSString*)substring options:(unsigned)mask
{
  BOOL result = NO;
  NSUInteger selfLength = [self length];
  NSUInteger subLength = [substring length];
  if (selfLength >= subLength)
  {
    NSRange rangeOfBegin = NSMakeRange(0, subLength);
    result = ([[self substringWithRange:rangeOfBegin] compare:substring options:mask] == NSOrderedSame);
  }//end if (selfLength >= subLength)
  return result;
}
//end startsWith:options:

-(BOOL) endsWith:(NSString*)substring options:(unsigned)mask
{
  BOOL result = NO;
  NSUInteger selfLength = [self length];
  NSUInteger subLength = [substring length];
  if (selfLength >= subLength)
  {
    NSRange rangeOfEnd = NSMakeRange(selfLength-subLength, subLength);
    result = ([[self substringWithRange:rangeOfEnd] compare:substring options:mask] == NSOrderedSame);
  }//end if (selfLength >= subLength)
  return result;
}
//end endsWith:options:

-(NSString*) reversedString
{
  NSMutableString *result = [NSMutableString stringWithCapacity:self.length];
  [self enumerateSubstringsInRange:NSMakeRange(0,self.length)
                          options:(NSStringEnumerationReverse | NSStringEnumerationByComposedCharacterSequences)
                       usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                                      [result appendString:substring];
                                  }];
  return result;
}
//end reversedString

-(NSArray*) componentsSeparatedByString:(NSString*)separator allowEmpty:(BOOL)allowEmpty
{
  NSArray* result = allowEmpty ?
    [self componentsSeparatedByString:separator] :
    [[self componentsSeparatedByString:separator] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
      return ![evaluatedObject isEqualToString:@""];
    }]];
  return result;
}
//end componentsSeparatedByString:allowEmpty:

-(NSString*) substringWithRanges:(NSIndexSet*)ranges
{
  NSString* result = nil;
  NSRange stringRange = NSMakeRange(0, self.length);
  NSMutableString* stream = [[NSMutableString alloc] init];
  [ranges enumerateRangesUsingBlock:^(NSRange range, BOOL *stop) {
    [stream appendString:[self substringWithRange:NSIntersectionRange(range, stringRange)]];
  }];
  result = [[stream copy] autorelease];
  [stream release];
  return result;
}
//end substringWithRanges:

-(NSComparisonResult) compareNumerical:(NSString*)other
{
  NSComparisonResult result = NSOrderedSame;
  if (!other)
    result = NSOrderedDescending;
  else//if (other)
  {
    NSUInteger selfLength = [self lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    NSUInteger otherLength = [other lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    NSUInteger maxLength = MAX(selfLength,otherLength);
    NSUInteger selfLeftPadding = (selfLength<maxLength) ? (maxLength-selfLength) : 0;
    NSUInteger otherLeftPadding = (otherLength<maxLength) ? (maxLength-otherLength) : 0;
    const char* selfChars = [self UTF8String];
    const char* otherChars = [other UTF8String];
    for(NSUInteger i = 0 ; (result == NSOrderedSame) && (i<maxLength) ; ++i)
    {
      const char selfChar = (i<selfLeftPadding) ? '0' : selfChars[i-selfLeftPadding];
      const char otherChar = (i<otherLeftPadding) ? '0' : otherChars[i-otherLeftPadding];
      result = (selfChar < otherChar) ? NSOrderedAscending :
               (otherChar < selfChar) ? NSOrderedDescending :
               NSOrderedSame;
    }//end for each i
  }//end if (other)
  return result;
}
//end compareNumerical:

@end

#if defined(USE_REGEXKITLITE) && USE_REGEXKITLITE
#else

NSRegularExpressionOptions convertRKLOptions(RKLRegexOptions options)
{
  NSRegularExpressionOptions result = 0;
  if ((options & RKLCaseless) != 0)
    result |= NSRegularExpressionCaseInsensitive;
  if ((options & RKLComments) != 0)
    result |= NSRegularExpressionAllowCommentsAndWhitespace;
  if ((options & RKLDotAll) != 0)
    result |= NSRegularExpressionDotMatchesLineSeparators;
  if ((options & RKLMultiline) != 0)
    result |= NSRegularExpressionAnchorsMatchLines;
  if ((options & RKLUnicodeWordBoundaries) != 0)
    result |= NSRegularExpressionUseUnicodeWordBoundaries;
  return result;
}
//end convertRKLOptions()

@implementation NSString (RegexKitLiteExtension)

-(BOOL) isMatchedByRegex:(NSString*)pattern
{
  BOOL result = [self isMatchedByRegex:pattern options:0 inRange:self.range error:nil];
  return result;
}
//end isMatchedByRegex:

-(BOOL) isMatchedByRegex:(NSString*)pattern options:(RKLRegexOptions)options inRange:(NSRange)range error:(NSError**)error
{
  BOOL result = false;
  NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:pattern options:convertRKLOptions(options) error:error];
  result = ([regex numberOfMatchesInString:self options:0 range:range] > 0);
  return result;
}
//end isMatchedByRegex:options:inRange:error:

-(NSRange) rangeOfRegex:(NSString*)pattern options:(RKLRegexOptions)options inRange:(NSRange)range capture:(NSInteger)capture error:(NSError**)error
{
  NSRange result = NSMakeRange(0, 0);
  NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:pattern options:convertRKLOptions(options) error:error];
  NSTextCheckingResult* match = [regex firstMatchInString:self options:0 range:range];
  result = [match rangeAtIndex:capture];
  return result;
}
//end rangeOfRegex::options:inRange:capture:error:

-(NSString*) stringByReplacingOccurrencesOfRegex:(NSString*)pattern withString:(NSString*)replacement
{
  NSString* result = [self stringByReplacingOccurrencesOfRegex:pattern withString:replacement options:0 range:self.range error:nil];
  return result;
}
//end stringByReplacingOccurrencesOfRegex::withgString:

-(NSString*) stringByReplacingOccurrencesOfRegex:(NSString*)pattern withString:(NSString*)replacement options:(RKLRegexOptions)options range:(NSRange)searchRange error:(NSError**)error
{
  NSString* result = self;
  NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:pattern options:convertRKLOptions(options) error:error];
  result = [regex stringByReplacingMatchesInString:self options:0 range:searchRange withTemplate:replacement];
  return result;
}
//end stringByReplacingOccurrencesOfRegex:withString:options:range:error:

-(NSString*) stringByMatching:(NSString*)pattern capture:(NSInteger)capture
{
  NSString* result = [self stringByMatching:pattern options:0 inRange:self.range capture:capture error:0];
  return result;
}
//end stringByMatching:capture:

-(NSString*) stringByMatching:(NSString*)pattern options:(RKLRegexOptions)options inRange:(NSRange)range capture:(NSInteger)capture error:(NSError**)error
{
  NSString* result = self;
  NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:pattern options:convertRKLOptions(options) error:nil];
  NSTextCheckingResult* match = [regex firstMatchInString:self options:0 range:range];
  NSRange matchRange = [match rangeAtIndex:capture];
  result = (matchRange.location != NSNotFound) ? [self substringWithRange:matchRange] : @"";
  return result;
}
//end stringByMatching:options:inRange:capture:

-(NSArray*) componentsMatchedByRegex:(NSString*)pattern
{
  NSArray* result = [self componentsMatchedByRegex:pattern options:0 range:self.range capture:0 error:nil];
  return result;
}
//end componentsMatchedByRegex

-(NSArray*) componentsMatchedByRegex:(NSString*)pattern options:(RKLRegexOptions)options range:(NSRange)searchRange capture:(NSInteger)capture error:(NSError**)error
{
  NSMutableArray* result = nil;
  NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:pattern options:convertRKLOptions(options) error:error];
  NSArray* matches = [regex matchesInString:self options:0 range:searchRange];
  result = [NSMutableArray arrayWithCapacity:matches.count];
  for(NSUInteger i = 0, count = matches.count ; i<count ; ++i)
  {
    NSTextCheckingResult* match = [[matches objectAtIndex:i] dynamicCastToClass:[NSTextCheckingResult class]];
    NSRange matchRange = [match rangeAtIndex:capture];
    NSString* component = (matchRange.location != NSNotFound) ? [self substringWithRange:matchRange] : @"";
    if (component != nil)
      [result addObject:component];
  }//end for each match
  return [[result copy] autorelease];
}
//end componentsMatchedByRegex:options:range:capture:error:

-(NSArray*) captureComponentsMatchedByRegex:(NSString*)pattern
{
  NSArray* result = [self captureComponentsMatchedByRegex:pattern options:0 range:self.range error:0];
  return result;
}
//end captureComponentsMatchedByRegex:

-(NSArray*) captureComponentsMatchedByRegex:(NSString*)pattern options:(RKLRegexOptions)options range:(NSRange)range error:(NSError**)error
{
  NSMutableArray* result = nil;
  NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:pattern options:convertRKLOptions(options) error:error];
  NSTextCheckingResult* match = [regex firstMatchInString:self options:0 range:range];
  result = [NSMutableArray arrayWithCapacity:match.numberOfRanges];
  for(NSUInteger i = 0, count = match.numberOfRanges ; i<count ; ++i)
  {
    NSRange matchRange = [match rangeAtIndex:i];
    NSString* captureComponent = (matchRange.location != NSNotFound) ? [self substringWithRange:matchRange] : @"";
    if (captureComponent != nil)
      [result addObject:captureComponent];
  }//end for each match
  return [[result copy] autorelease];
}
//end componentsMatchedByRegex:options:range:error:

-(NSArray*) componentsSeparatedByRegex:(NSString*)pattern
{
  NSArray* result = [self componentsSeparatedByRegex:pattern options:0 range:self.range capture:0 error:nil];
  return result;
}
//end componentsSeparatedByRegex

-(NSArray*) componentsSeparatedByRegex:(NSString*)pattern options:(RKLRegexOptions)options range:(NSRange)searchRange capture:(NSInteger)capture error:(NSError**)error
{
  NSMutableArray* result = nil;
  NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:pattern options:convertRKLOptions(options) error:error];
  NSUInteger lastEnd = 0;
  NSArray* matches = [regex matchesInString:self options:0 range:searchRange];
  result = [NSMutableArray arrayWithCapacity:matches.count];
  for(NSUInteger i = 0, count = matches.count ; i<count ; ++i)
  {
    NSTextCheckingResult* match = [[matches objectAtIndex:i] dynamicCastToClass:[NSTextCheckingResult class]];
    NSRange matchRange = [match rangeAtIndex:capture];
    NSRange componentRange = (matchRange.location == NSNotFound) ? NSMakeRange(lastEnd, 0) : NSMakeRange(lastEnd, matchRange.location-lastEnd);
    NSString* component = (componentRange.location == NSNotFound) || !componentRange.length ? nil : [self substringWithRange:componentRange];
    if (![NSString isNilOrEmpty:component])
      [result addObject:component];
    lastEnd = NSMaxRange(matchRange);
  }//end for each match
  NSUInteger searchRangeEnd = NSMaxRange(searchRange);
  NSRange componentRange = (lastEnd < searchRangeEnd) ? NSMakeRange(lastEnd, searchRangeEnd-lastEnd) : NSMakeRange(0, 0);
  NSString* component = !componentRange.length ? nil : [self substringWithRange:componentRange];
  if (![NSString isNilOrEmpty:component])
    [result addObject:component];
  return [[result copy] autorelease];
}
//end componentsSeparatedByRegex:options:range:capture:error:
@end

#endif
