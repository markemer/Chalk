//
//  CHProgressIndicator.m
//  Chalk
//
//  Created by Pierre Chatelier on 31/10/2016.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHProgressIndicator.h"

@implementation CHProgressIndicator

@dynamic animated;

+(void) initialize
{
  [self exposeBinding:@"animated"];
}
//end initialize

-(void) startAnimation:(id)sender
{
  if (!self->animationStarted)
  {
    [super startAnimation:sender];
    self->animationStarted = YES;
  }//end if (!self->animationStarted)
}
//end startAnimation:

-(void) stopAnimation:(id)sender
{
  if (self->animationStarted)
  {
    [super stopAnimation:sender];
    self->animationStarted = NO;
  }//end if (self->animationStarted)
}
//end stopAnimation:

-(BOOL) animated
{
  BOOL result = self->animationStarted;
  return result;
}
//end animated

-(void) setAnimated:(BOOL)value
{
  if (!self.animated)
    [self startAnimation:nil];
  else
    [self stopAnimation:nil];
}
//end setAnimated:

@end
