//
//  CHDigitView.m
//  Chalk
//
//  Created by Pierre Chatelier on 01/04/2016.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHDigitView.h"

#import "NSObjectExtended.h"

#import <CoreText/CoreText.h>

@interface CHDigitTextFieldCell : NSTextFieldCell

@end

@implementation CHDigitTextFieldCell

-(BOOL) drawsBackground {return NO;}

-(void) drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
  CHDigitView* digitView = [controlView dynamicCastToClass:[CHDigitView class]];
  NSRect bounds = cellFrame;
  bounds = //NSInsetRect(bounds, 1, 1);
    NSMakeRect(bounds.origin.x+2, bounds.origin.y+2, bounds.size.width-2, bounds.size.height-4);
  NSArray* colors1 = digitView.backColors1;
  NSArray* colors2 = digitView.backColors2;
  CGFloat widthPerColor1 = bounds.size.width/MAX(1, colors1.count);
  CGFloat widthPerColor2 = bounds.size.width/MAX(1, colors2.count);
  for(NSUInteger i = 0, count = colors1.count ; i<count ; ++i)
  {
    NSColor* color = [[colors1 objectAtIndex:i] dynamicCastToClass:[NSColor class]];
    [color set];
    CGFloat x = bounds.origin.x+i*widthPerColor1;
    if (i+1 == count)
      widthPerColor1 = bounds.size.width-x;
    NSRectFill(NSMakeRect(x, bounds.origin.y, widthPerColor1, bounds.size.height/2));
  }//end or each color1
  for(NSUInteger i = 0, count = colors2.count ; i<count ; ++i)
  {
    NSColor* color = [[colors2 objectAtIndex:i] dynamicCastToClass:[NSColor class]];
    [color set];
    CGFloat x = bounds.origin.x+i*widthPerColor2;
    if (i+1 == count)
      widthPerColor2 = bounds.size.width-x;
    NSRectFill(NSMakeRect(x, bounds.origin.y+bounds.size.height/2, widthPerColor2, bounds.size.height/2));
  }//end for each color2
  
  CGContextRef cgContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
  CGContextSetTextMatrix(cgContext, CGAffineTransformIdentity);
  CGContextSetTextDrawingMode(cgContext, kCGTextFill);
  NSAttributedString* attributedString = self.attributedStringValue;
  CTLineRef ctLine = CTLineCreateWithAttributedString((CFAttributedStringRef)attributedString);
  CFArrayRef ctRuns = !ctLine ? 0 : CTLineGetGlyphRuns(ctLine);
  CTRunRef ctRun = !ctRuns || !CFArrayGetCount(ctRuns) ? 0 : CFArrayGetValueAtIndex(ctRuns, 0);
  CFRange range = CTRunGetStringRange(ctRun);
  CGContextSetRGBFillColor(cgContext, 0, 0, 0, 1);
  CGContextSetRGBStrokeColor(cgContext, 0, 0, 0, 1);
  CGContextSetTextMatrix(cgContext, CGAffineTransformMakeScale(1, -1));
  CGRect runBounds = CTRunGetImageBounds(ctRun, cgContext, range);
  CGContextSetTextPosition(cgContext,
    cellFrame.origin.x+floor(cellFrame.size.width-runBounds.size.width)/2,
    (runBounds.origin.y+runBounds.size.height)+cellFrame.origin.y+floor(cellFrame.size.height-runBounds.size.height)/2);
  CTRunDraw(ctRun, cgContext, range);
  if (ctLine)
    CFRelease(ctLine);
}
//end drawInteriorWithFrame:

@end

@implementation CHDigitView

@synthesize clickDelegate;
@synthesize backColors1;
@synthesize backColors2;

@synthesize digitIndexNatural;
@synthesize digitIndexVisual;
@synthesize digitMinorPart;

+(id) cellClass
{
  return [CHDigitTextFieldCell class];
}

-(instancetype) initWithFrame:(NSRect)frameRect
{
  if (!((self = [super initWithFrame:frameRect])))
    return nil;
  self.alignment = NSCenterTextAlignment;
  self.backColors1 = [self isDarkMode] ?
    @[[NSColor colorWithCalibratedRed:255/255. green:0/255. blue:0/255. alpha:1.]] :
    @[[NSColor colorWithCalibratedRed:255/255. green:196/255. blue:196/255. alpha:1.]];
  self.backColors2 = [self isDarkMode] ?
    @[[NSColor colorWithCalibratedRed:0/255. green:255/255. blue:0/255. alpha:1.]] :
    @[[NSColor colorWithCalibratedRed:196/255. green:196/255. blue:255/255. alpha:1.]];
  return self;
}
//end initWithFrame:

-(void) dealloc
{
  [self->backColors1 release];
  [self->backColors2 release];
  [super dealloc];
}
//end dealloc

-(void) setBackColors1:(NSArray*)value
{
  if (value != self->backColors1)
  {
    [self->backColors1 release];
    self->backColors1 = [value copy];
    [self setNeedsDisplay];
  }//end if (value != self->backColor1)
}
//end setBackColor1:

-(void) setBackColors2:(NSArray*)value
{
  if (value != self->backColors2)
  {
    [self->backColors2 release];
    self->backColors2 = [value copy];
    [self setNeedsDisplay];
  }//end if (value != self->backColor2)
}
//end setBackColor2:

-(void) viewDidClick:(id)sender
{
}
//end viewDidClick:

-(void) mouseDown:(NSEvent*)theEvent
{
  if ([self->clickDelegate respondsToSelector:@selector(viewDidClick:)])
    [(id)self->clickDelegate viewDidClick:self];
  else
    [self viewDidClick:self];
}
//end mouseDown:

@end
