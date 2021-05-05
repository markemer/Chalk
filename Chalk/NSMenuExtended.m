//
//  NSMenuExtended.m
//  Chalk
//
//  Created by Pierre Chatelier on 04/05/2017.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "NSMenuExtended.h"

@implementation NSMenu (Extended)

-(NSMenuItem*) addItemWithTitle:(NSString*)title tag:(NSInteger)tag action:(SEL)action target:(id)target
{
  NSMenuItem* result = [[[NSMenuItem alloc] init] autorelease];
  result.title = title;
  result.tag = tag;
  result.action = action;
  result.target = target;
  [self addItem:result];
  return result;
}
//end addItemWithTitle:tag:action:target:

-(NSMenuItem*) addItemWithTitle:(NSString*)aString target:(id)target action:(SEL)aSelector
                  keyEquivalent:(NSString*)keyEquivalent  keyEquivalentModifierMask:(int)keyEquivalentModifierMask
                  tag:(int)tag
{
  NSMenuItem* result = [self addItemWithTitle:aString action:aSelector keyEquivalent:keyEquivalent];
  result.target = target;
  result.keyEquivalentModifierMask = keyEquivalentModifierMask;
  result.tag = tag;
  return result;
}
//end addItemWithTitle:target:action:keyEquivalent:keyEquivalentModifierMask:

@end
