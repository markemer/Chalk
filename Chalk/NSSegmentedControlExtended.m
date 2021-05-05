//
//  NSSegmentedControlExtended.m
//  Chalk
//
//  Created by Pierre Chatelier on 18/04/09.
//  Copyright 2005-2015 Pierre Chatelier. All rights reserved.
//

#import "NSSegmentedControlExtended.h"

@implementation NSSegmentedControl (Extended)

-(NSInteger) selectedSegmentTag
{
  NSInteger result = -1;
  NSInteger selectedSegment = [self selectedSegment];
  result = [[self cell] tagForSegment:selectedSegment];
  return result;
}
//end selectedSegmentTag

-(NSInteger) segmentForTag:(NSInteger)tag
{
  NSInteger result = 0;
  NSSegmentedCell* cell = self.cell;
  for(NSUInteger i = 0, count = self.segmentCount ; i<count ; ++i)
  {
    if ([cell tagForSegment:i] == tag)
    {
      result = i;
      break;
    }//end if ([cell tagForSegment:i] == tag)
  }//end for each sgement
  return result;
}
//end segmentForTag:

-(void) sizeToFitWithSegmentWidth:(CGFloat)segmentWidth useSameSize:(BOOL)useSameSize
{
  NSInteger nbSegments = [self segmentCount];
  NSInteger i = 0;
  CGFloat maxSize = 0;
  for(i = 0 ; i<nbSegments ; ++i)
  {
    [self setWidth:segmentWidth forSegment:i];
    CGFloat width = [self widthForSegment:i];
    maxSize = MAX(maxSize, width);
  }
  if (useSameSize)
  for(i = 0 ; i<nbSegments ; ++i)
    [self setWidth:maxSize forSegment:i];
}
//end sizeToFitWithSegmentWidth:useSameSize:

@end
