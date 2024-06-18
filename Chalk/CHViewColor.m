//
//  CHViewColor.m
//  Chalk
//
//  Created by Pierre Chatelier on 20/05/2017.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHViewColor.h"

@implementation CHViewColor

@synthesize backgroundColor;

-(instancetype) initWithCoder:(NSCoder*)coder
{
  if (!((self = [super initWithCoder:coder])))
    return nil;
  self->backgroundColor = [[NSColor clearColor] copy];
  return self;
}
//end initWithCoder:

-(instancetype) initWithFrame:(NSRect)frameRect
{
  if (!((self = [super initWithFrame:frameRect])))
    return nil;
  self->backgroundColor = [[NSColor clearColor] copy];
  return self;
}
//end initWithFrame:

-(void) dealloc
{
  [self->backgroundColor release];
  self->backgroundColor = nil;
  [super dealloc];
}
//end dealloc

-(void) setBackgroundColor:(NSColor*)value
{
  if (![value isEqualTo:self->backgroundColor])
  {
    [self->backgroundColor release];
    self->backgroundColor = [value copy];
    [self setNeedsDisplay:YES];
  }//end if (![value isEqualTo:self->backgroundColor]))
}
//end setBackgroundColor:

-(void)drawRect:(NSRect)dirtyRect
{
  CGContextRef cgContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
  NSColor* rgbaBackgroundColor = [self->backgroundColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
  CGFloat backgroundColorRgba[4] = {0, 0, 0, 0};
  [rgbaBackgroundColor getRed:&backgroundColorRgba[0] green:&backgroundColorRgba[1] blue:&backgroundColorRgba[2] alpha:&backgroundColorRgba[3]];
  CGContextSetRGBFillColor(cgContext, backgroundColorRgba[0], backgroundColorRgba[1], backgroundColorRgba[2], backgroundColorRgba[3]);
  CGContextFillRect(cgContext, self.bounds);
}
//end drawRect:

@end
