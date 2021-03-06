//
//  CHPreferencesWindow.m
// Chalk
//
//  Created by Pierre Chatelier on 06/08/09.
//  Copyright 2005, 2006, 2007, 2008, 2009, 2010, 2011 Pierre Chatelier. All rights reserved.
//

#import "CHPreferencesWindow.h"

#import "CHUtils.h"

@implementation CHPreferencesWindow

-(id) initWithContentRect:(NSRect)contentRect styleMask:(NSWindowStyleMask)windowStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation
{
  if (!isMacOS10_5OrAbove())
    windowStyle = windowStyle & ~NSUnifiedTitleAndToolbarWindowMask;//fixes a Tiger bug with segmented controls
  if (!((self = [super initWithContentRect:contentRect styleMask:windowStyle backing:bufferingType defer:deferCreation])))
    return nil;
  return self;
}
//end initWithContentRect:styleMask:backing:defer:screen:

-(id) initWithContentRect:(NSRect)contentRect styleMask:(NSWindowStyleMask)windowStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation screen:(NSScreen *)screen
{
  if (!isMacOS10_5OrAbove())
    windowStyle = windowStyle & ~NSUnifiedTitleAndToolbarWindowMask;//fixes a Tiger bug with segmented controls
  if (!((self = [super initWithContentRect:contentRect styleMask:windowStyle backing:bufferingType defer:deferCreation screen:screen])))
    return nil;
  return self;
}
//end initWithContentRect:styleMask:backing:defer:screen:

@end
