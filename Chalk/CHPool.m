//
//  CHPool.m
//  Chalk
//
//  Created by Pierre Chatelier on 21/05/2015.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHPool.h"

@implementation CHPool

-(instancetype) initWithMaxCapacity:(NSUInteger)aMaxCapacity
{
  return [self initWithMaxCapacity:aMaxCapacity defaultConstruction:0];
}
//end initWithMaxCapacity:

-(instancetype) initWithMaxCapacity:(NSUInteger)aMaxCapacity defaultConstruction:(constructionBlock_t)constructionBlock
{
  if (!((self = [super init])))
    return nil;
  self->defaultConstructionBlock = constructionBlock;
  self->maxCapacity = aMaxCapacity;
  self->pool = [[NSMutableArray alloc] init];
  return self;
}
//end initWithMaxCapacity:defaultConstruction:

-(void) dealloc
{
  [self->pool release];
  [super dealloc];
}
//end dealloc

-(void) repool:(id)object
{
  if (object)
  {
    @synchronized(self->pool)
    {
      if (self->pool.count < self->maxCapacity)
        [self->pool addObject:object];
    }//end @synchronized(self->pool)
  }//end if (object)
}
//end repool:

-(id) depool
{
  return [self depoolUsingConstruction:self->defaultConstructionBlock];
}
//end depool:

-(id) depoolUsingConstruction:(constructionBlock_t)constructionBlock
{
  id result = nil;
  @synchronized(self->pool)
  {
    result = [[self->pool lastObject] retain];
    [self->pool removeLastObject];
  }//end @synchronized(self->pool)
  if (!result)
    result = constructionBlock();
  [result autorelease];
  return result;
}
//end depoolUsingConstruction:

@end
