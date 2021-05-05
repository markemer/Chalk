//  NSMutableSetExtended.m
//  Chalk
//
//  Created by Pierre Chatelier on 3/05/05.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.

//this file is an extension of the NSMutableArray class

#import "NSMutableSetExtended.h"

@implementation NSMutableSet (Extended)

-(void) safeAddObject:(id)object
{
  if (object)
    [self addObject:object];
}
//end safeAddObject:

@end
