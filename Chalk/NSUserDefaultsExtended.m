//
//  NSUserDefaultsExtended.m
//  Chalk
//
//  Created by Pierre Chatelier on 21/10/2016.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "NSUserDefaultsExtended.h"

#import "NSObjectExtended.h"

@implementation NSUserDefaults (Extended)

-(NSUInteger) unsignedIntegerForKey:(NSString*)key
{
  NSUInteger result = [[[self valueForKey:key] dynamicCastToClass:[NSNumber class]] unsignedIntegerValue];
  return result;
}
//end unsignedIntegerForKey

-(void) setUnsignedInteger:(NSUInteger)value forKey:(NSString*)key
{
  [self setObject:@(value) forKey:key];
}
//end setUnsignedInteger:forKey:

@end
