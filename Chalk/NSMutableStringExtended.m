//
//  NSMutableStringExtended.m
//  Chalk
//
//  Created by Pierre Chatelier on 23/10/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "NSMutableStringExtended.h"

@implementation NSMutableString (Extended)

-(NSString*) string
{
  return [[self copy] autorelease];
}
//end string

-(BOOL) appendCharacter:(char)character count:(NSUInteger)count
{
  BOOL result = NO;
  NSUInteger allocationSize = count*sizeof(character);
  char* buffer = (count <= 1) ? 0 : malloc(allocationSize);
  while(!buffer && (allocationSize>1))
  {
    allocationSize /= 2;
    buffer = malloc(allocationSize);
  }//end while(!buffer && (allocationSize>1))
  if (!buffer)
  {
    NSString* string = [[NSString alloc] initWithBytes:&character length:sizeof(character) encoding:NSUTF8StringEncoding];
    result = (string != nil);
    if (string)
    for(NSUInteger i = 0 ; i<count ; ++i)
      [self appendString:string];
    [string release];
  }//end if (!buffer)
  else//if (buffer)
  {
    memset(buffer, character, allocationSize);
    NSString* string = [[NSString alloc] initWithBytesNoCopy:buffer length:allocationSize encoding:NSUTF8StringEncoding freeWhenDone:NO];
    result = (string != nil);
    NSUInteger nbFullBuffers = count/allocationSize;
    if (string)
    for(NSUInteger i = 0 ; i<nbFullBuffers ; ++i)
      [self appendString:string];
    NSUInteger remainingPart = count%allocationSize;
    if (remainingPart)
      [self appendString:[string substringToIndex:remainingPart]];
    [string release];
    free(buffer);
  }//end if (buffer)
  return result;
}
//end appendCharacter:count:

@end

#if defined(USE_REGEXKITLITE) && USE_REGEXKITLITE
#else

@implementation NSMutableString (RegexKitLiteExtension)

-(NSInteger) replaceOccurrencesOfRegex:(NSString*)pattern withString:(NSString*)replacement
{
  NSInteger result = [self replaceOccurrencesOfRegex:pattern withString:replacement options:0 range:self.range error:nil];
  return result;
}
//end replaceOccurrencesOfRegex:withString:options:range:error:

-(NSInteger) replaceOccurrencesOfRegex:(NSString*)pattern withString:(NSString*)replacement options:(RKLRegexOptions)options range:(NSRange)searchRange error:(NSError **)error
{
  NSInteger result = 0;
  NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:pattern options:convertRKLOptions(options) error:error];
  [self setString:[regex stringByReplacingMatchesInString:self options:0 range:self.range withTemplate:replacement]];
  return result;
}
//end replaceOccurrencesOfRegex:withString:options:range:error:

@end

#endif
