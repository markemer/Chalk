//
//  CHCGUtils.m
//  Chalk
//
//  Created by Pierre Chatelier on 31/10/2016.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHCGUtils.h"
#import <Foundation/Foundation.h>

#include <sys/time.h>

void CGDrawProgressIndicator(CGContextRef cgContext, CGRect bounds)
{
  CGPoint center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
  CGFloat thickness = 6;
  CGFloat length = 2*thickness;
  struct timeval tv = {0};
  gettimeofday(&tv, 0);
  const NSUInteger divisions = 12;
  const NSUInteger timeStep = 1000000U/divisions;
  const NSUInteger timeIndex = tv.tv_usec / timeStep;
  for(NSUInteger i = 0 ; i<divisions ; ++i)
  {
    CGRect bar = CGRectMake(center.x-thickness, thickness, thickness, length);
    CGFloat factor = (i+divisions-timeIndex)%divisions;
    CGContextSaveGState(cgContext);
    CGContextRotateCTM(cgContext, i*(2*M_PI/divisions));
    CGContextSetRGBFillColor(cgContext, .75, .75, .75, factor);
    CGContextFillRect(cgContext, bar);
    CGContextRestoreGState(cgContext);
  }//end for each i
}
//end CGDrawProgressIndicator()

CGRect adaptRectangle(CGRect rectangle, CGRect containerRectangle, BOOL allowScaleDown, BOOL allowScaleUp, BOOL integerScale)
{
  CGRect result = rectangle;
  if (allowScaleDown && ((result.size.width>containerRectangle.size.width) ||
                         (result.size.height>containerRectangle.size.height)))
  {
    CGFloat divisor = MAX(!containerRectangle.size.width  ? 0.f : result.size.width/containerRectangle.size.width,
                          !containerRectangle.size.height ? 0.f : result.size.height/containerRectangle.size.height);
    if (integerScale)
      divisor = ceil(divisor);
    result.size.width /= divisor;
    result.size.height /= divisor;
  }
  if (allowScaleUp && ((rectangle.size.width<containerRectangle.size.width) ||
                       (rectangle.size.height<containerRectangle.size.height)))
  {
    CGFloat factor = MIN(!result.size.width  ? 0.f : containerRectangle.size.width/result.size.width,
                         !result.size.height ? 0.f : containerRectangle.size.height/result.size.height);
    if (factor)
      factor = floor(factor);
    result.size.width *= factor;
    result.size.height *= factor;
  }
  result.origin.x = (containerRectangle.origin.x+(containerRectangle.size.width-result.size.width)/2);
  result.origin.y = (containerRectangle.origin.y+(containerRectangle.size.height-result.size.height)/2);
  return result;
}
//end adaptRectangle()

void CGContextAddRoundedRect(CGContextRef context, CGRect rect, CGFloat ovalWidth, CGFloat ovalHeight)
{
	if ((ovalWidth == 0.) || (ovalHeight == 0.))
		CGContextAddRect(context, rect);
  else
  {
  	CGContextSaveGState(context);
    CGContextTranslateCTM(context, CGRectGetMinX(rect), CGRectGetMinY(rect));
    CGContextScaleCTM(context, ovalWidth, ovalHeight);
    CGFloat fw = CGRectGetWidth(rect) / ovalWidth;
    CGFloat fh = CGRectGetHeight(rect) / ovalHeight;
    CGContextMoveToPoint(context, fw, fh/2);  // Start at lower right corner
    CGContextAddArcToPoint(context, fw, fh, fw/2, fh, 1);  // Top right corner
    CGContextAddArcToPoint(context, 0, fh, 0, fh/2, 1); // Top left corner
    CGContextAddArcToPoint(context, 0, 0, fw/2, 0, 1); // Lower left corner
    CGContextAddArcToPoint(context, fw, 0, fw, fh/2, 1); // Back to lower right
    CGContextClosePath(context);
    CGContextRestoreGState(context);
  }//end if (ovalWidth || ovalHeight)
}
//end CGContextAddRoundedRect()
