//
//  DragFilterWindowController.m
//  Chalk
//
//  Created by Pierre Chatelier on 10/12/2015.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHDragFilterWindowController.h"

#import "CHAppDelegate.h"
#import "CHButtonPalette.h"
#import "CHDragThroughButton.h"
#import "CHPreferencesController.h"

@interface CHDragFilterWindowController (PrivateAPI)
-(void) updateAnimation:(NSTimer*)timer;
-(void) notified:(NSNotification*)notification;
@end

@implementation CHDragFilterWindowController

@dynamic exportFormat;

-(id) init
{
  if ((!(self = [super initWithWindowNibName:@"CHDragFilterWindowController"])))
    return nil;
  self->animationDurationIn  = .33;
  self->animationDurationOut = .10;
  return self;
}
//end init

-(void) dealloc
{
  [self->animationTimer invalidate];
  [self->animationTimer release];
  [self->animationStartDate release];
  [self->buttonPalette release];
  [super dealloc]; 
}
//end dealloc

-(void) awakeFromNib
{
  [self->dragFilterViewLabel setStringValue:NSLocalizedString(@"Drag through areas to change export type", @"Drag through areas to change export type")];
  self->buttonPalette = [[CHButtonPalette alloc] init];
  [self->buttonPalette setExclusive:YES];
  NSEnumerator* enumerator = [[self->dragFilterButtonsView subviews] objectEnumerator];
  NSView* view = nil;
  while((view = [enumerator nextObject]))
  {
    if ([view isKindOfClass:[NSButton class]])
      [self->buttonPalette add:(NSButton*)view];
  }//end while((view = [enumerator nextObject]))
  [self->closeButton setShouldBlink:NO];
  [self->closeButton setDelay:.05];
  
  self.exportFormat = [[CHPreferencesController sharedPreferencesController] exportFormatCurrentSession];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notified:) name:CHDragThroughButtonStateChangedNotification object:nil];
}
//end awakeFromNib

-(void) setWindowVisible:(BOOL)visible withAnimation:(BOOL)animate
{
  NSPoint mouseLocation = [NSEvent mouseLocation];
  [self setWindowVisible:visible withAnimation:animate atPoint:mouseLocation];
}
//end setWindowVisible:withAnimation:

-(void) setWindowVisible:(BOOL)visible withAnimation:(BOOL)animate atPoint:(NSPoint)point
{
  [self setWindowVisible:visible withAnimation:animate atPoint:point isHintOnly:YES];
}
//end setWindowVisible:withAnimation:atPoint:

-(void) setWindowVisible:(BOOL)visible withAnimation:(BOOL)animate atPoint:(NSPoint)point isHintOnly:(BOOL)isHintOnly
{
  if (visible)
  {
    self.exportFormat = [[CHPreferencesController sharedPreferencesController] exportFormatCurrentSession];
    NSWindow* screenWindow = [NSApp keyWindow];
    screenWindow = screenWindow ? screenWindow: [NSApp mainWindow];
    NSRect screenVisibleFrame = [(!screenWindow ? [NSScreen mainScreen] : [screenWindow screen]) visibleFrame];
    NSWindow* window = [self window];
    NSRect windowFrame = [window frame];
    NSPoint newFrameOrigin = !isHintOnly ? point : NSMakePoint(point.x-windowFrame.size.width/2, point.y+32);
    if (isHintOnly)
    {
      newFrameOrigin.x = MAX(0, newFrameOrigin.x);
      newFrameOrigin.x = MIN(screenVisibleFrame.size.width-windowFrame.size.width, newFrameOrigin.x);
      newFrameOrigin.y = MAX(0, newFrameOrigin.y);
      newFrameOrigin.y = MIN(screenVisibleFrame.size.height-windowFrame.size.height, newFrameOrigin.y);
    }//end if (isHintOnly)
    self->fromFrameOrigin = [[self window] isVisible] ? [window frame].origin : newFrameOrigin;
    self->toFrameOrigin = newFrameOrigin;
    [[self window] setFrameOrigin:self->fromFrameOrigin];
    [self->animationStartDate release];
    self->animationStartDate = [[NSDate alloc] init];
    [self->animationTimer invalidate];
    [self->animationTimer release];
    self->animationTimer = nil;
    self->animationStartAlphaValue = ![[self window] isVisible] ? 0 : [[self window] alphaValue];
    [[self window] setAlphaValue:self->animationStartAlphaValue];
    [self showWindow:self];
    if (animate)
      self->animationTimer = [[NSTimer scheduledTimerWithTimeInterval:1./25. target:self selector:@selector(updateAnimation:) userInfo:[NSNumber numberWithBool:visible] repeats:YES] retain];
    else
      [[self window] setAlphaValue:1];
  }
  else// if (!visible)
  {
    [self->animationStartDate release];
    self->animationStartDate = [[NSDate alloc] init];
    [self->animationTimer invalidate];
    [self->animationTimer release];
    self->animationTimer = nil;
    if (animate)
      self->animationTimer = [[NSTimer scheduledTimerWithTimeInterval:1./25. target:self selector:@selector(updateAnimation:) userInfo:[NSNumber numberWithBool:visible] repeats:YES] retain];
    else
      [[self window] close];
  }
}
//end setVisible:withAnimation:atPoint:isHintOnly:

-(void) updateAnimation:(NSTimer*)timer
{
  NSTimeInterval timeElapsed = !self->animationStartDate ? 0. :
    [[NSDate date] timeIntervalSinceDate:self->animationStartDate];
  BOOL toVisible = [[timer userInfo] boolValue];
  NSTimeInterval animationDuration = toVisible ? self->animationDurationIn : self->animationDurationOut;
  timeElapsed = MIN(MAX(0., timeElapsed), animationDuration);
  double evolution = !animationDuration ? 1. : MIN(MAX(0., timeElapsed/animationDuration), 1.);
  if (toVisible)
    [[self window] setAlphaValue:(1-evolution)*self->animationStartAlphaValue+evolution*1.];
  else
    [[self window] setAlphaValue:(1-evolution)*self->animationStartAlphaValue+evolution*0.];
  NSPoint currentFrameOrigin = NSMakePoint((1-evolution)*fromFrameOrigin.x+evolution*toFrameOrigin.x,
                                           (1-evolution)*fromFrameOrigin.y+evolution*toFrameOrigin.y);
  [[self window] setFrameOrigin:currentFrameOrigin];
  if (evolution >= 1)
  {
    self->fromFrameOrigin = [[self window] frame].origin;
    if (!toVisible)
      [[self window] close];
  }//end if (evolution >=1)
}
//end updateAnimation:

-(void) notified:(NSNotification*)notification
{
  if ([notification.name isEqualToString:CHDragThroughButtonStateChangedNotification])
  {
    CHDragThroughButton* dragThroughButton = notification.object;
    if (dragThroughButton.state == NSOnState)
    {
      NSInteger tag = dragThroughButton.tag;
      if (tag < 0)
        [self setWindowVisible:NO withAnimation:YES];
      else//if (tag >= 0)
      {
        CHPreferencesController* preferencesController = [CHPreferencesController sharedPreferencesController];
        preferencesController.exportFormatCurrentSession = (chalk_export_format_t)tag;
        [self dragFilterWindowController:self exportFormatDidChange:preferencesController.exportFormatCurrentSession];
      }//end if (tag >= 0)
    }//end if (dragThroughButton.state == NSOnState)
  }//end if ([notification.name isEqualToString:CHDragThroughButtonStateChangedNotification])
}
//end notified:

-(id) delegate
{
  return self->delegate;
}
//end delegate

-(void) setDelegate:(id)value
{
  self->delegate = value;
}
//end setDelegate:

-(chalk_export_format_t) exportFormat
{
  chalk_export_format_t result = (chalk_export_format_t)self->buttonPalette.selectedTag;
  return result;
}
//end exportFormat

-(void) setExportFormat:(chalk_export_format_t)value
{
  self->buttonPalette.selectedTag = (NSInteger)value;
}
//end setExportFormat:

-(void) dragFilterWindowController:(CHDragFilterWindowController*)dragFilterWindowController exportFormatDidChange:(chalk_export_format_t)exportFormat
{
  if (self->delegate && [self->delegate respondsToSelector:@selector(dragFilterWindowController:exportFormatDidChange:)])
    [self->delegate dragFilterWindowController:self exportFormatDidChange:exportFormat];
}
//end dragFilterWindowController:exportFormatDidChange:

@end
