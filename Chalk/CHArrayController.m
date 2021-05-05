//
//  CHArrayController.m
//  Chalk
//
//  Created by Pierre Chatelier on 09/12/2015.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHArrayController.h"

@implementation CHArrayController

@synthesize objectCreator;

-(void) dealloc
{
  self.objectCreator = nil;
  [super dealloc];
}
//end dealloc

-(id) newObject
{
  id result = !self->objectCreator ? [super newObject] : [self->objectCreator() retain];
  return result;
}
//end newObject

@end
