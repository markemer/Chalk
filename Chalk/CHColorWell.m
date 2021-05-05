//
//  CHColorWell.m
//  Chalk
//
//  Created by Pierre Chatelier on 01/11/2016.
//  Copyright (c) 2016 Pierre Chatelier. All rights reserved.
//

#import "CHColorWell.h"

@implementation CHColorWell

@synthesize allowAlpha;

-(void) activate:(BOOL)exclusive
{
  if (self.allowAlpha)
    [NSColorPanel sharedColorPanel].showsAlpha = YES;
  [super activate:exclusive];
}
//end activate:

@end
