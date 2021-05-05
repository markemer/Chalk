//
//  CHDisablingView.m
//  Chalk
//
//  Created by Pierre Chatelier on 02/12/2015.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHDisablingView.h"

@implementation CHDisablingView

-(BOOL) isOpaque
{
  return NO;
}
//end isOpaque

-(void) drawRect:(NSRect)dirtyRect
{
  [[NSColor colorWithRed:.9 green:.9 blue:.9 alpha:.1] set];
  NSRectFill(self.bounds);
}
//end drawRect:

@end
