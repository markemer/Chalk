//
//  CHDragThroughButton.h
//  Chalk
//
//  Created by Pierre Chatelier on 10/12/2015.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString* CHDragThroughButtonStateChangedNotification;

@class CHTooltipWindow;

@interface CHDragThroughButton : NSButton {
  NSDate* lastMoveDate;
  NSUInteger remainingSetStateWrapped;
  BOOL shouldBlink;
  CGFloat delay;
  CHTooltipWindow* tooltipWindow;
}

@property BOOL shouldBlink;
@property CGFloat delay;
@property(readonly) BOOL isBlinking;

@end
