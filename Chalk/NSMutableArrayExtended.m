//  NSMutableArrayExtended.m
//  Chalk
//
//  Created by Pierre Chatelier on 3/05/05.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.

//this file is an extension of the NSMutableArray class

#import "NSMutableArrayExtended.h"

@implementation NSMutableArray (Extended)

-(void) safeAddObject:(id)object
{
  if (object)
    [self addObject:object];
}
//end safeAddObject:

-(void) insertObjectsFromArray:(NSArray *)array atIndex:(int)index
{
  NSEnumerator* enumerator = [array objectEnumerator];
  NSObject* entry = nil;
  while ((entry = [enumerator nextObject]))
    [self insertObject:entry atIndex:index++];
}
//end insertObjectsFromArray:atIndex:

-(void) reverse
{
  for(NSUInteger idx = 0, count = self.count, middle = count/2 ; idx<middle ; ++idx)
    [self exchangeObjectAtIndex:idx withObjectAtIndex:count-1-idx];
}
//end reverse

@end
