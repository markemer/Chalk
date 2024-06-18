//
//  CHDragFilterView.m
//  Chalk
//
//  Created by Pierre Chatelier on 10/12/2015.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHDragFilterView.h"

#import "CHCGUtils.h"

@implementation CHDragFilterView

-(BOOL) isOpaque
{
  return NO;
}
//end isOpaque

-(void)drawRect:(NSRect)dirtyRect
{
  CGContextRef cgContext = [[NSGraphicsContext currentContext] graphicsPort];
  CGRect roundedRect = NSRectToCGRect(self.bounds);
  roundedRect.size.width -= 20;
  roundedRect.origin.x += 10;
  roundedRect.size.height -= 10;
  roundedRect.origin.y += 10;
  
  roundedRect.size.height -= 2;
  roundedRect.origin.y += 1;
  
  CGContextSaveGState(cgContext);
  CGContextAddRoundedRect(cgContext, roundedRect, 5, 5);
  CGContextSetRGBFillColor(cgContext, .0, .0, .0, .33);
  CGContextSetShadow(cgContext, CGSizeMake(0, -5), 10);
  CGContextFillPath(cgContext);
  CGContextAddRoundedRect(cgContext, roundedRect, 5, 5);
  CGContextSetShouldAntialias(cgContext, YES);
  CGContextSetRGBStrokeColor(cgContext, .8, .8, .8, 1.);
  CGContextSetLineWidth(cgContext, 3);
  CGContextStrokePath(cgContext);
  CGContextRestoreGState(cgContext);
  [super drawRect:dirtyRect];
}
//end drawRect:

@end
