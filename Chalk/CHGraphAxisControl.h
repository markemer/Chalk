//
//  CHGraphAxisControl.h
//  Chalk
//
//  Created by Pierre Chatelier on 19/12/2015.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CHColorWellButton.h"

extern NSString* CHAxisColorBinding;

@class CHColorWell;
@class CHStepper;

@interface CHGraphAxisControl : NSViewController <CHColorWellButtonDelegate>

@property(readonly,assign) IBOutlet NSTextField*   titleLabel;
@property(readonly,assign) IBOutlet CHColorWell*   colorWell;
@property(readonly,assign) IBOutlet CHColorWellButton* colorWellButton;
@property(readonly,assign) IBOutlet NSTextField*   minLabel;
@property(readonly,assign) IBOutlet NSTextField*   minTextField;
@property(readonly,assign) IBOutlet CHStepper*     minStepper;
@property(readonly,assign) IBOutlet NSTextField*   maxLabel;
@property(readonly,assign) IBOutlet NSTextField*   maxTextField;
@property(readonly,assign) IBOutlet CHStepper*     maxStepper;
@property(readonly,assign) IBOutlet NSButton*      centerButton;
@property(readonly,assign) IBOutlet NSPopUpButton* scaleTypeButton;
@property(readonly,assign) IBOutlet NSTextField*   scaleTypeBaseLabel;
@property(readonly,assign) IBOutlet NSTextField*   scaleTypeBaseTextField;
@property(readonly,assign) IBOutlet CHStepper*     scaleTypeBaseStepper;
@property(readonly,assign) IBOutlet NSBox*         gridBox;
@property(readonly,assign) IBOutlet NSButton*      gridMajorAutoCheckBox;
@property(readonly,assign) IBOutlet NSTextField*   gridMajorTextField;
@property(readonly,assign) IBOutlet CHStepper*     gridMajorStepper;
@property(readonly,assign) IBOutlet NSTextField*   gridMinorTextField;
@property(readonly,assign) IBOutlet CHStepper*     gridMinorStepper;

@property(nonatomic,copy) NSString* axisTitle;
@property(nonatomic,copy) NSColor*  axisColor;

-(IBAction) changeColor:(id)sender;

@end
