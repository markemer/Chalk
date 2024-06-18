//
//  CHWindow.m
//  Chalk
//
//  Created by Pierre Chatelier on 10/05/2017.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHWindow.h"

#import "CHAppDelegate.h"
#import "NSObjectExtended.h"

@implementation CHWindow

-(BOOL) validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item
{
  BOOL result = [super validateUserInterfaceItem:item];
  NSMenuItem* menuItem = [(id)item dynamicCastToClass:[NSMenuItem class]];
  if (item.action == @selector(toggleToolbarShown:))
  {
    if (self.toolbar.isVisible)
      menuItem.title = NSLocalizedString(@"Hide Toolbar", @"");
    else
      menuItem.title = NSLocalizedString(@"Show Toolbar", @"");
  }//end if (item.action == @selector(toggleToolbarShown:))
  return result;
}
//end validateUserInterfaceItem:

@end
