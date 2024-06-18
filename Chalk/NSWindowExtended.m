//
//  NSWindowExtended.m
//  Chalk
//
//  Created by Pierre Chatelier on 20/05/2017.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "NSWindowExtended.h"

@implementation NSWindow (Extended)

-(CGFloat) toolbarHeight
{
  CGFloat result = 0;
  NSToolbar* toolbar = self.toolbar;
  if (toolbar.isVisible)
  {
    NSRect frameRect = self.frame;
    //NSRect contentRect = [self contentRectForFrameRect:frameRect];
    NSRect contentRect2 = [NSWindow contentRectForFrameRect:frameRect styleMask:self.styleMask&(~(NSUnifiedTitleAndToolbarWindowMask))];
    NSRect contentRect3 = [NSWindow contentRectForFrameRect:frameRect styleMask:self.styleMask&(~(NSTitledWindowMask))];
    result = MAX(0, NSHeight(contentRect3) - NSHeight(contentRect2));
  }//end if (toolbar.isVisible)
  return result;
}
//end toolbarHeight

@end
