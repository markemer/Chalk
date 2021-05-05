//
//  CHTextFieldCell.m
//  Chalk
//
//  Created by Pierre Chatelier on 25/10/2016.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHTextFieldCell.h"

@implementation CHTextFieldCell

@synthesize middleVerticalAlignment;

-(id) initWithCoder:(NSCoder*)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self)
    self->middleVerticalAlignment = YES;
  return self;
}
//end initWithCoder:

-(void) awakeFromNib
{
  self.middleVerticalAlignment = YES;
}
//end awakeFromNib

-(NSRect) drawingRectForBounds:(NSRect)theRect
{
  NSRect newRect = [super drawingRectForBounds:theRect];
  if (self.middleVerticalAlignment == YES)
  {
    NSSize textSize = [self cellSizeForBounds:theRect];
    float heightDelta = newRect.size.height - textSize.height;
    if (heightDelta > 0)
    {
      newRect.size.height -= heightDelta;
      newRect.origin.y += (heightDelta / 2);
    }//end if (heightDelta > 0)

    // For some reason right aligned text doesn't work.  This section makes it work if set in IB.
    // HACK: using _cFlags isn't a great idea, but I couldn't find another way to find the alignment.
    // TODO: replace _cFlags usage if a better solution is found.
    float widthDelta = newRect.size.width - textSize.width;
    //if (_cFlags.alignment == NSRightTextAlignment && widthDelta > 0)
    if (self.alignment == NSRightTextAlignment && widthDelta > 0)
    {
      newRect.size.width -= widthDelta;
      newRect.origin.x += widthDelta;
    }//end if (_cFlags.alignment == NSRightTextAlignment && widthDelta > 0)
  }//end if (self.middleVerticalAlignment == YES)
  return newRect;
}
//end drawingRectForBounds:

@end
