//
//  CHNumberFormatter.m
//  Chalk
//
//  Created by Pierre Chatelier on 05/12/2015.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHNumberFormatter.h"

#import "CHChalkUtils.h"
#import "NSNumberExtended.h"
#import "NSObjectExtended.h"
#import "NSStringExtended.h"

@implementation CHNumberFormatter

-(BOOL) getObjectValue:(out id *)obj forString:(NSString *)string range:(inout NSRange *)rangep error:(out NSError **)error
{
  BOOL result = NO;
  NSString* substring = !rangep ? string : [string substringWithRange:*rangep];
  if ([substring isMatchedByRegex:@"^([0-9]|[:space:])*$"])
  {
    NSString* trimmedString = [substring stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([trimmedString isEqualToString:@""])
    {
      if (obj)
        *obj = self.minimum;
      result = YES;
    }//end if ([trimmedString isEqualToString:@""])
    else//if (![trimmedString isEqualToString:@""])
    {
      mpz_t mp;
      mpz_init_set_si(mp, 0);
      BOOL ok = !mpz_set_str(mp, [trimmedString UTF8String], 10);
      if (ok && mpz_fits_nsui_p(mp))
      {
        result = ok;
        if (obj)
          *obj = [NSNumber numberWithUnsignedInteger:mpz_get_nsui(mp)];
      }//end if (ok && mpz_fits_nsui_p(mp))
      mpz_clear(mp);
    }//end if (![trimmedString isEqualToString:@""])
  }//end if ([substring isMatchedByRegex:@"^([0-9][[:space:]])+$"])
  if (!result)
  {
    result = [super getObjectValue:obj forString:string range:rangep error:error];
  }
  return result;
}
//end getObjectValue:forString:range:error:

-(NSString*) stringForObjectValue:(id)obj
{
  NSString* result = nil;
  NSNumber* number = [obj dynamicCastToClass:[NSNumber class]];
  if (!number || [number fitsInteger] || ![number fitsUnsignedInteger])
    result = [super stringForObjectValue:obj];
  else//if (!number || [number fitsInteger] || ![number fitsUnsignedInteger])
  {
    NSString* stringValue = [number stringValue];
    NSUInteger length = stringValue.length;
    BOOL usesGroupingSeparator = self.usesGroupingSeparator;
    NSString* groupingSeparator = self.groupingSeparator;
    NSUInteger groupingSize = self.groupingSize;
    NSUInteger secondaryGroupingSize = self.secondaryGroupingSize;
    NSUInteger estimatedPrimaryGroups = !usesGroupingSeparator || !groupingSize ? 0 :
      secondaryGroupingSize ? 1 : (length / groupingSize);
    NSUInteger estimatedSecondaryGroups = !usesGroupingSeparator || (length<=groupingSize) || !secondaryGroupingSize ? 0 : ((length-groupingSize) / secondaryGroupingSize);
    NSUInteger estimatedNewLength = length+(estimatedPrimaryGroups+estimatedSecondaryGroups)*groupingSeparator.length;
    NSMutableString* ms = [[NSMutableString alloc] initWithCapacity:estimatedNewLength];
    const char* chars = [stringValue UTF8String];
    NSUInteger charsCount = [stringValue lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    NSUInteger currentGroupCharsCount = 0;
    NSUInteger currentGroupIndex = 0;
    NSUInteger emittedDigits = 0;
    while(charsCount--)
    {
      char c = chars[charsCount];
      [ms appendFormat:@"%c", c];
      ++emittedDigits;
      ++currentGroupCharsCount;
      if (usesGroupingSeparator && (currentGroupCharsCount == ((!currentGroupIndex || !secondaryGroupingSize) ? groupingSize : secondaryGroupingSize)))
      {
        [ms appendString:groupingSeparator];
        currentGroupCharsCount = 0;
        ++currentGroupIndex;
      }//end if (currentGroupCharsCount == groupingSize)
      if (emittedDigits >= self.maximumIntegerDigits)
        charsCount = 0;
    }//while(charsCount--)
    result = [[[ms reversedString] copy] autorelease];
    [ms release];
    result = [result stringByAppendingString:self.positiveSuffix];
  }//if (!number || [number fitsInteger] || ![number fitsUnsignedInteger])
  return result;
}
//end stringForObjectValue:

@end
