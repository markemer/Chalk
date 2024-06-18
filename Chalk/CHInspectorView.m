//
//  CHInspectorView.m
//  Chalk
//
//  Created by Pierre Chatelier on 19/11/2016.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHInspectorView.h"

#import "NSObjectExtended.h"

@implementation CHInspectorView

@synthesize anchor;
@synthesize visible;
@synthesize delegate;

NSString* CHInspectorVisibleBinding = @"visible";
NSString* CHInspectorVisibilityDidChangeNotification = @"CHInspectorVisibilityDidChangeNotification";

+(void) initialize
{
  [self exposeBinding:CHInspectorVisibleBinding];
}
//end initialize

-(instancetype) initWithCoder:(NSCoder*)coder
{
  self = [super initWithCoder:coder];
  if (self)
    self->visible = !self.hidden;
  return self;
}
//end initWithCoder:

-(instancetype) initWithFrame:(NSRect)rect
{
  self = [super initWithFrame:rect];
  if (self)
    self->visible = !self.hidden;
  return self;
}
//end initWithCoder:

-(void) setVisible:(BOOL)value
{
  if (value != self->visible)
  {
    [self willChangeValueForKey:CHInspectorVisibleBinding];
    self->visible = value;
    [self didChangeValueForKey:CHInspectorVisibleBinding];
    [self propagateValue:@(self->visible) forBinding:CHInspectorVisibleBinding];
    [self inspectorVisibilityDidChange:[NSNotification notificationWithName:CHInspectorVisibilityDidChangeNotification object:self]];
  }//end if (value != self->visible)
}
//end setVisible:

-(void) inspectorVisibilityDidChange:(NSNotification*)notification
{
  if ([self.delegate respondsToSelector:@selector(inspectorVisibilityDidChange:)])
    [self.delegate inspectorVisibilityDidChange:notification];
}
//end inspectorVisibilityDidChange

@end
