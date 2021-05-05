//
//  CHTooltipWindow.h
//  Chalk
//
//  Created by Pierre Chatelier on 10/12/2015.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CHTooltipWindow : NSWindow
{
  id tooltipObject;
}
+(id) tipWithString:(NSString*)tip frame:(NSRect)frame display:(BOOL)display;
+(id) tipWithAttributedString:(NSAttributedString*)tip frame:(NSRect)frame display:(BOOL)display;

// returns the approximate window size needed to display the tooltip string.
+(NSSize) suggestedSizeForTooltip:(id)tooltip;

// setting and getting the default duration..
+(void) setDefaultDuration:(NSTimeInterval)inSeconds;
+(NSTimeInterval) defaultDuration;

// setting and getting the default bgColor
+(void) setDefaultBackgroundColor:(NSColor*)bgColor;
+(NSColor*) defaultBackgroundColor;

-(id) init;

-(id) tooltip;
-(void) setTooltip:(id)tip;

-(void) orderFrontWithDuration:(NSTimeInterval)seconds;

@end
