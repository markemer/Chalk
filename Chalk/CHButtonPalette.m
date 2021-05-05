//
//  CHButtonPalette.m
//  Chalk
//
//  Created by Pierre Chatelier on 10/12/2015.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHButtonPalette.h"

#import "NSObjectExtended.h"

@implementation CHButtonPalette

@dynamic selectedTag;

-(id) init
{
  if (!(self = [super init]))
    return nil;
  self->buttons = [[NSMutableArray alloc] init];
  return self;
}
//end init

-(BOOL) isExclusive
{
  return self->isExclusive;
}
//end isExclusive

-(void) setExclusive:(BOOL)value
{
  self->isExclusive = value;
}
//end setExclusive:

-(void) add:(NSButton*)button
{
  [self->buttons addObject:button];
  [button addObserver:self forKeyPath:@"state" options:0 context:nil];
}
//end add:

-(void) remove:(NSButton*)button;
{
  [self->buttons removeObject:button];
  [button removeObserver:self forKeyPath:@"state"];
}
//end remove:

-(id) delegate
{
  return self->delegate;
}
//end delegate;

-(void) setDelegate:(id)value
{
  self->delegate = value;
}
//end setDelegate:

-(NSButton*) buttonWithTag:(int)tag
{
  NSButton* result = nil;
  NSEnumerator* enumerator = [self->buttons objectEnumerator];
  NSButton* button = nil;
  while(!result && ((button = [enumerator nextObject])))
  {
    if ([button tag] == tag)
      result = button;
  }
  //end for each button
  return result;
}
//end buttonWithTag:

-(NSButton*) buttonWithState:(int)state
{
  NSButton* result = nil;
  NSEnumerator* enumerator = [self->buttons objectEnumerator];
  NSButton* button = nil;
  while(!result && ((button = [enumerator nextObject])))
  {
    if ([button state] == state)
      result = button;
  }
  //end for each button
  return result;
}
//end buttonWithState:

-(NSInteger) selectedTag
{
  __block NSInteger result = 0;
  [self->buttons enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    NSButton* button = [obj dynamicCastToClass:[NSButton class]];
    if (button.state == NSOnState)
    {
      result = button.tag;
      *stop = YES;
    }//end if (button.state == NSOnState)
  }];
  return result;
}
//end selectedTag

-(void) setSelectedTag:(NSInteger)tag
{
  [self->buttons enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    NSButton* button = [obj dynamicCastToClass:[NSButton class]];
    button.state = (button.tag == tag) ? NSOnState : NSOffState;
  }];
}
//end setSelectedTag

-(void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  if ([keyPath isEqualToString:@"state"] && [self->buttons containsObject:object])
  {
    if (self->isExclusive && ([object state] == NSOnState))
    {
      NSUInteger count = [self->buttons count];
      while(count--)
      {
        NSButton* button = [self->buttons objectAtIndex:count];
        if (button != object)
          [button setState:NSOffState];
      }//end for each button
    }//end if (self->isExclusive && ([object state] == NSOnState))
    if ([self->delegate respondsToSelector:@selector(buttonPalette:buttonStateChanged:)])
      [self->delegate buttonPalette:self buttonStateChanged:object];
  }//end if ([keyPath isEqualToString:@"state"] && [self->buttons containsObject:object])
}
//end observeValueForKeyPath:ofObject:change:context:

-(void) buttonPalette:(CHButtonPalette*)buttonPalette buttonStateChanged:(NSButton*)button
{
}
//end buttonPalette:buttonStateChanged:

@end
