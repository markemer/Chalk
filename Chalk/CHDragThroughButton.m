//
//  CHDragThroughButton.m
//  Chalk
//
//  Created by Pierre Chatelier on 10/12/2015.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHDragThroughButton.h"

#import "CHChalkTypes.h"
#import "CHTooltipWindow.h"

NSString* CHDragThroughButtonStateChangedNotification = @"CHDragThroughButtonStateChangedNotification";

@interface CHDragThroughButton (PrivateAPI)
-(void) checkLastMove:(id)object;
-(void) setStateWrapped:(NSNumber*)number;
-(void) windowWillCloseNotification:(NSNotification*)notification;
@end

@implementation CHDragThroughButton

@synthesize shouldBlink;
@synthesize delay;
@dynamic    isBlinking;

-(id) initWithCoder:(NSCoder*)coder
{
  if (!(self = [super initWithCoder:coder]))
    return nil;
  self->shouldBlink = YES;
  self->delay = .33;
  [self registerForDraggedTypes:@[CHChalkPBoardType]];
  return self;
}
//end initWithCoder:

-(void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self->tooltipWindow release];
  [self->lastMoveDate release];
  [super dealloc];
}
//end dealloc:

-(void) awakeFromNib
{
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillCloseNotification:) name:NSWindowWillCloseNotification object:[self window]];
}
//end awakeFromNib

-(BOOL) isOpaque {return YES;}

-(void) checkLastMove:(id)object
{
  if (self.toolTip)
  {
    NSPoint mouseLocation = [NSEvent mouseLocation];
    NSSize  toolTipSize = [CHTooltipWindow suggestedSizeForTooltip:self.toolTip];
    NSRect  toolTipFrame = NSMakeRect(mouseLocation.x, mouseLocation.y, toolTipSize.width, toolTipSize.height);
    if (!self->tooltipWindow)
      self->tooltipWindow = [[CHTooltipWindow tipWithString:self.toolTip frame:toolTipFrame display:YES] retain];
    [self->tooltipWindow orderFrontWithDuration:5];
  }//end if (self.toolTip)
  if (self.isEnabled)
  {
    if (!self->shouldBlink)
      self.state = NSOnState;
    else//if (self->shouldBlink)
    {
      self->remainingSetStateWrapped += 5;
      [self performSelector:@selector(setStateWrapped:) withObject:[NSNumber numberWithInt:NSOnState] afterDelay:0.05];
      [self performSelector:@selector(setStateWrapped:) withObject:[NSNumber numberWithInt:NSOffState] afterDelay:0.10];
      [self performSelector:@selector(setStateWrapped:) withObject:[NSNumber numberWithInt:NSOnState] afterDelay:0.15];
      [self performSelector:@selector(setStateWrapped:) withObject:[NSNumber numberWithInt:NSOffState] afterDelay:0.20];
      [self performSelector:@selector(setStateWrapped:) withObject:[NSNumber numberWithInt:NSOnState] afterDelay:0.25];
    }//end if (self->shouldBlink)
  }//end if (self.isEnabled)
}
//end checkLastMove:

-(void) setStateWrapped:(NSNumber*)number
{
  if ([self isEnabled])
  {
    if (self->remainingSetStateWrapped)
      --self->remainingSetStateWrapped;
    [self setState:[number intValue]];
  }//end if ([self isEnabled])
}
//end setStateWrapped:

-(void) setState:(NSInteger)value
{
  if ([self isEnabled])
  {
    [super setState:value];
    if (!self->remainingSetStateWrapped)
      [[NSNotificationCenter defaultCenter] postNotificationName:CHDragThroughButtonStateChangedNotification object:self userInfo:nil];
  }//end if ([self isEnabled])
}
//end setState:

-(BOOL) isBlinking
{
  BOOL result = (self->remainingSetStateWrapped > 0);
  return result;
}
//end isBlinking

-(BOOL) wantsPeriodicDraggingUpdates
{
  return NO;
}
//end wantsPeriodicDraggingUpdates

-(NSDragOperation) draggingEntered:(id<NSDraggingInfo>)sender
{
  [self->lastMoveDate release];
  self->lastMoveDate = [[NSDate alloc] init];
  if (self.state != NSOnState)
    [self performSelector:@selector(checkLastMove:) withObject:nil afterDelay:self->delay];
  return NSDragOperationAll;
}
//end draggingEntered:

-(NSDragOperation) draggingUpdated:(id<NSDraggingInfo>)sender
{
  [NSRunLoop cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkLastMove:) object:nil];
  [self->lastMoveDate release];
  self->lastMoveDate = [[NSDate alloc] init];
  if (self.state != NSOnState)
    [self performSelector:@selector(checkLastMove:) withObject:nil afterDelay:self->delay];
  return NSDragOperationAll;
}
//end draggingExited:

-(void) draggingExited:(id<NSDraggingInfo>)sender
{
  [self->tooltipWindow orderOut:self];
  [NSRunLoop cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkLastMove:) object:nil];
}
//end draggingExited:

-(void) windowWillCloseNotification:(NSNotification*)notification
{
  [self->tooltipWindow orderOut:self];
}
//end windowWillCloseNotification:

-(void) drawRect:(NSRect)rect
{
  if (!self.isEnabled)
  {
    [[NSColor grayColor] set];
    NSRectFill(self.bounds);
  }//end if (![self isEnabled])
  [super drawRect:rect];
}
//end drawRect:

@end
