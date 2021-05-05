//
//  NSStringExtended.h
//  Chalk
//
//  Created by Pierre Chatelier on 21/07/05.
//  Copyright 2005-2014 Pierre Chatelier. All rights reserved.

//this file is an extension of the NSWorkspace class

#import <Cocoa/Cocoa.h>

#define USE_REGEXKITLITE 0

#if defined(USE_REGEXKITLITE) && USE_REGEXKITLITE
#import "RegexKitLite.h"
#else
enum {
  RKLNoOptions             = 0,
  RKLCaseless              = 2,
  RKLComments              = 4,
  RKLDotAll                = 32,
  RKLMultiline             = 8,
  RKLUnicodeWordBoundaries = 256
};
typedef uint32_t RKLRegexOptions;

FOUNDATION_EXTERN NSRegularExpressionOptions convertRKLOptions(RKLRegexOptions options);

@interface NSString (RegexKitLiteExtension)
-(BOOL) isMatchedByRegex:(NSString*)pattern;
-(BOOL) isMatchedByRegex:(NSString*)pattern options:(RKLRegexOptions)options inRange:(NSRange)range error:(NSError**)error;
-(NSRange) rangeOfRegex:(NSString*)pattern options:(RKLRegexOptions)options inRange:(NSRange)range capture:(NSInteger)capture error:(NSError**)error;
-(NSString*) stringByReplacingOccurrencesOfRegex:(NSString*)pattern withString:(NSString*)replacement;
-(NSString*) stringByReplacingOccurrencesOfRegex:(NSString*)pattern withString:(NSString*)replacement options:(RKLRegexOptions)options range:(NSRange)searchRange error:(NSError**)error;
-(NSString*) stringByMatching:(NSString*)pattern capture:(NSInteger)capture;
-(NSString*) stringByMatching:(NSString*)pattern options:(RKLRegexOptions)options inRange:(NSRange)range capture:(NSInteger)capture error:(NSError**)error;
-(NSArray*) componentsMatchedByRegex:(NSString*)pattern;
-(NSArray*) componentsMatchedByRegex:(NSString*)pattern options:(RKLRegexOptions)options range:(NSRange)searchRange capture:(NSInteger)capture error:(NSError**)error;
-(NSArray*) captureComponentsMatchedByRegex:(NSString*)pattern;
-(NSArray*) captureComponentsMatchedByRegex:(NSString*)pattern options:(RKLRegexOptions)options range:(NSRange)range error:(NSError**)error;
-(NSArray*) componentsSeparatedByRegex:(NSString*)pattern;
-(NSArray*) componentsSeparatedByRegex:(NSString*)pattern options:(RKLRegexOptions)options range:(NSRange)searchRange capture:(NSInteger)capture error:(NSError**)error;
@end

#endif

@interface NSString (Extended)

+(BOOL) isNilOrEmpty:(NSString*)string;
+(BOOL) string:(NSString*)s1 equals:(NSString*)s2;
+(BOOL) string:(NSString*)s1 equals:(NSString*)s2 options:(NSStringCompareOptions)options;

-(NSRange) range;
-(BOOL) startsWith:(NSString*)substring options:(unsigned)mask;
-(BOOL) endsWith:(NSString*)substring options:(unsigned)mask;
-(NSString*) reversedString;
-(NSArray*) componentsSeparatedByString:(NSString*)separator allowEmpty:(BOOL)allowEmpty;
-(NSString*) substringWithRanges:(NSIndexSet*)range;
-(NSComparisonResult) compareNumerical:(NSString*)other;

@end
