//  NSArrayExtended.m
//  Chalk
//  Created by Pierre Chatelier on 4/05/05.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.

// This file is an extension of the NSArray class

#import "NSArrayExtended.h"
#import "NSMutableArrayExtended.h"
#import "NSObjectExtended.h"
#import "NSStringExtended.h"

@implementation NSArray (Extended)

-(id) firstObject
{
  id result = [self count] ? [self objectAtIndex:0] : nil;
  return result;
}
//end firstObject

-(BOOL) containsObjectIdenticalTo:(id)object
{ 
  BOOL result = ([self indexOfObjectIdenticalTo:object] != NSNotFound);
  return result;
}
//end containsObjectIdenticalTo:

-(NSArray*) reversedArray
{
  NSMutableArray* result = [NSMutableArray arrayWithCapacity:[self count]];
  NSEnumerator* enumerator = [self reverseObjectEnumerator];
  id object = [enumerator nextObject];
  while(object)
  {
    [result addObject:object];
    object = [enumerator nextObject];
  }
  return result;
}
//end reversedArray

-(NSString*) componentsJoinedByString:(NSString*)separator allowEmpty:(BOOL)allowEmpty
{
  NSString* result = nil;
  if (allowEmpty)
    result = [self componentsJoinedByString:separator];
  else//if (!allowEmpty)
  {
    __block NSMutableString* stringBuilder = [[NSMutableString alloc] init];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      NSString* s = [obj dynamicCastToClass:[NSString class]];
      if (![NSString isNilOrEmpty:s])
      {
        if ([stringBuilder length])
          [stringBuilder appendString:separator];
        [stringBuilder appendString:s];
      }//end if (![NSString isNilOrEmpty:s])
    }];
    result = [[stringBuilder copy] autorelease];
    [stringBuilder release];
  }//if (!allowEmpty)
  return result;
}
//end componentsJoinedByString:allowEmpty:

-(NSArray*) arrayByRemovingDuplicates
{
  NSArray* result = nil;
  NSMutableArray* array = [[NSMutableArray alloc] initWithCapacity:self.count];
  NSMutableSet* set = [NSMutableSet setWithCapacity:self.count];
  [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    if (![set containsObject:obj])
    {
      [array addObject:obj];
      [set addObject:obj];
    }//end if (![set containsObject:obj])
  }];
  result = [[array copy] autorelease];
  [array release];
  return result;
}
//end arrayByRemovingDuplicates:

@end
