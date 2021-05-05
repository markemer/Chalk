//
//  CHChalkErrorContext.m
//  Chalk
//
//  Created by Pierre Chatelier on 18/03/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHChalkErrorContext.h"

#import "CHChalkError.h"

@implementation CHChalkErrorContext

@dynamic hasError;
@synthesize input;
@synthesize error;
@dynamic warnings;

-(instancetype) initWithString:(NSString*)string
{
  if (!(self = [super init]))
    return nil;
  self->input = [string copy];
  self->warnings = [[NSMutableArray alloc] init];
  return self;
}
//end init

-(void) dealloc
{
  [self->input release];
  [self->error release];
  [self->warnings release];
  [super dealloc];
}
//end dealloc

-(void) reset:(NSString*)value
{
  @synchronized(self)
  {
    if (value != self->input)
    {
      [self->input release];
      self->input = [value copy];
    }//end if (value != self->input)
    [self setError:nil replace:YES];
    [self->warnings removeAllObjects];
  }//end @synchronized(self)
}
//end reset:

-(BOOL) hasError
{
  return (self->error != nil);
}
//end hasError

-(BOOL) setError:(CHChalkError*)value replace:(BOOL)replace
{
  BOOL result = NO;
  @synchronized(self)
  {
    if (!self->error || replace)
    {
      if (value != self->error)
        [self->error release];
      self->error = [value retain];
      result = YES;
    }//end if (|self->error || overwrite)
  }//end @synchronized(self)
  return result;
}
//end setError:overwrite:

-(void) addWarning:(CHChalkError*)warning
{
  if (warning)
  {
    @synchronized(self)
    {
      [self->warnings addObject:warning];
    }//end @synchronized(self)
  }//end if (warning)
}
//end addWarning:

-(NSArray*) warnings
{
  NSArray* result = nil;
  @synchronized(self)
  {
    result = [[self->warnings copy] autorelease];
  }//end @synchronized(self)
  return result;
}
//end warnings
   
@end
