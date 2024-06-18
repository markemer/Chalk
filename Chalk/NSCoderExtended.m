//
//  NSCoder.m
//  Chalk
//
//  Created by Pierre Chatelier on 09/02/2015.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "NSCoderExtended.h"

#import "CHUtils.h"

@implementation NSCoder (Extended)

-(NSRange) decodeRangeForKey:(NSString*)key
{
  NSRange result = NSRangeZero;
  NSString* rangeString = [self decodeObjectOfClass:[NSString class] forKey:key];
  result = !rangeString ? NSMakeRange(0, 0) : NSRangeFromString(rangeString);
  return result;
}
//end decodeRangeForKey:

-(NSUInteger) decodeUnsignedIntegerForKey:(NSString*)key
{
  NSUInteger result = 0;
  NSNumber* unsignedIntegerNumber = [self decodeObjectOfClass:[NSNumber class] forKey:key];
  result = [unsignedIntegerNumber unsignedIntegerValue];
  return result;
}
//end decodeUnsignedIntegerForKey:

-(void) encodeRange:(NSRange)range forKey:(NSString*)key
{
  NSString* rangeString = NSStringFromRange(range);
  [self encodeObject:rangeString forKey:key];
}
//end decodeRangeForKey:forKey:

-(void) encodeUnsignedInteger:(NSUInteger)value forKey:(NSString*)key
{
  NSNumber* number = [NSNumber numberWithUnsignedInteger:value];
  [self encodeObject:number forKey:key];
}
//end encodeUnsignedInteger:forKey:

@end
