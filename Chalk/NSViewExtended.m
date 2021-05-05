//
//  NSViewExtended.m
// Chalk
//
//  Created by Pierre Chatelier on 22/12/12.
//  Copyright (c) 2012 Pierre Chatelier. All rights reserved.
//

#import "NSViewExtended.h"

NSString* NSTagBinding = @"tag";

@implementation NSView (Extended)

-(void) centerInParentHorizontally:(BOOL)horizontally vertically:(BOOL)vertically
{
  [[self superview] centerChild:self horizontally:horizontally vertically:vertically];
}
//end centerInParentHorizontally:vertically:

-(void) centerChild:(NSView*)child horizontally:(BOOL)horizontally vertically:(BOOL)vertically
{
  NSRect bounds = [self bounds];
  NSRect childFrame = [child frame];
  if (horizontally)
    childFrame.origin.x = (bounds.size.width-childFrame.size.width)/2;
  if (vertically)
    childFrame.origin.y = (bounds.size.height-childFrame.size.height)/2;
  [child setFrame:childFrame];
}
//end centerChild:horizontally:vertically:

-(void) centerChildren:(NSArray*)children horizontally:(BOOL)horizontally vertically:(BOOL)vertically
{
  NSRect bounds = [self bounds];
  NSRect unionFrame = NSZeroRect;
  for(NSView* child in children)
    unionFrame = NSUnionRect(unionFrame, [child frame]);
  NSPoint centeredOrigin = unionFrame.origin;
  if (horizontally)
    centeredOrigin.x = (bounds.size.width-unionFrame.size.width)/2;
  if (vertically)
    centeredOrigin.y = (bounds.size.height-unionFrame.size.height)/2;
  for(NSView* child in children)
  {
    NSRect childFrame = [child frame];
    childFrame.origin.x += (centeredOrigin.x-unionFrame.origin.x);
    childFrame.origin.y += (centeredOrigin.y-unionFrame.origin.y);
    [child setFrame:childFrame];
  }//end for each child
}
//end centerChildren:horizontally:vertically:

-(void) centerRelativelyTo:(NSView*)other horizontally:(BOOL)horizontally vertically:(BOOL)vertically
{
  NSRect selfFrame = self.frame;
  NSRect otherFrame = other.frame;
  if (horizontally)
    selfFrame.origin.x = otherFrame.origin.x+(otherFrame.size.width-selfFrame.size.width)/2;
  if (vertically)
    selfFrame.origin.y = otherFrame.origin.y+(otherFrame.size.height-selfFrame.size.height)/2;
  self.frame = selfFrame;
}
//end centerRelativelyTo:horizontally:vertically:

-(NSView*) findSubviewOfClass:(Class)class
{
  NSView* result = nil;
  NSMutableArray* queue = [[NSMutableArray alloc] initWithObjects:self, nil];
  while(!result && (queue.count>0))
  {
    NSView* view = [queue firstObject];
    [queue removeObjectAtIndex:0];
    if ([view isKindOfClass:class])
      result = view;
    else
      [queue addObjectsFromArray:view.subviews];
  }//end for each subview
  [queue release];
  return result;
}
//end findSubviewOfClass:

-(NSView*) findSubviewOfClass:(Class)class andTag:(NSInteger)tag
{
  NSView* result = nil;
  NSMutableArray* queue = [[NSMutableArray alloc] initWithObjects:self, nil];
  while(!result && (queue.count>0))
  {
    NSView* view = [queue firstObject];
    [queue removeObjectAtIndex:0];
    if ([view isKindOfClass:class] && (view.tag == tag))
      result = view;
    else
      [queue addObjectsFromArray:view.subviews];
  }//end for each subview
  [queue release];
  return result;
}
//end findSubviewOfClass:andTag:

@end
