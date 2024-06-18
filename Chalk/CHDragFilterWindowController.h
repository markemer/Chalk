//
//  CHDragFilterWindowController.h
//  Chalk
//
//  Created by Pierre Chatelier on 10/12/2015.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "CHChalkTypes.h"

@class CHDragThroughButton;
@class CHDragFilterView;
@class CHButtonPalette;

@interface CHDragFilterWindowController : NSWindowController {
  IBOutlet CHDragThroughButton* closeButton;
  IBOutlet CHDragFilterView* dragFilterView;
  IBOutlet NSTextField* dragFilterViewLabel;
  IBOutlet NSView* dragFilterButtonsView;
  CHButtonPalette* buttonPalette;
  NSTimeInterval animationDurationIn;
  NSTimeInterval animationDurationOut;
  NSDate* animationStartDate;
  CGFloat animationStartAlphaValue;
  NSTimer* animationTimer;
  NSPoint fromFrameOrigin;
  NSPoint toFrameOrigin;
  id delegate;
}

@property(nonatomic) chalk_export_format_t exportFormat;

-(void) setWindowVisible:(BOOL)visible withAnimation:(BOOL)animate;
-(void) setWindowVisible:(BOOL)visible withAnimation:(BOOL)animate atPoint:(NSPoint)point;
-(void) setWindowVisible:(BOOL)visible withAnimation:(BOOL)animate atPoint:(NSPoint)point isHintOnly:(BOOL)isHintOnly;

-(id) delegate;
-(void) setDelegate:(id)value;

-(void) dragFilterWindowController:(CHDragFilterWindowController*)dragFilterWindowController exportFormatDidChange:(chalk_export_format_t)exportFormat;

@end
