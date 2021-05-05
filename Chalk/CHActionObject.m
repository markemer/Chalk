//
//  CHActionObject.m
//  Chalk
//
//  Created by Pierre Chatelier on 10/12/2015.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHActionObject.h"

@implementation CHActionObject

@synthesize actionBlock;

+(instancetype) actionObjectWithActionBlock:(void(^)(id))block
{
  return [[[[self class] alloc] initWithActionBlock:block] autorelease];
}

-(instancetype) initWithActionBlock:(void(^)(id))block
{
  if (!((self = [super init])))
    return nil;
  self->actionBlock = [block copy];
  return self;
}
//end initWithActionBlock:

-(void) dealloc
{
  [self->actionBlock release];
  [super dealloc];
}
//end dealloc

-(IBAction) action:(id)sender
{
  if (self->actionBlock)
    self->actionBlock(sender);
}

@end
