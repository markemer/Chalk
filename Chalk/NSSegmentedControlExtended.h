//
//  NSSegmentedControlExtended.h
//  Chalk
//
//  Created by Pierre Chatelier on 18/04/09.
//  Copyright 2005-2015 Pierre Chatelier. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSSegmentedControl (Extended)

-(NSInteger) selectedSegmentTag;
-(NSInteger) segmentForTag:(NSInteger)tag;
-(void) sizeToFitWithSegmentWidth:(CGFloat)segmentWidth useSameSize:(BOOL)useSameSize;

@end
