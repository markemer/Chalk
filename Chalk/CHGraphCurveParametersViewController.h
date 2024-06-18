//
//  CHGraphCurveParametersViewController.h
//  Chalk
//
//  Created by Pierre Chatelier on 17/05/2017.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CHColorWell;
@class CHGraphCurveItem;

@interface CHGraphCurveParametersViewController : NSViewController {
  IBOutlet NSNumberFormatter* thicknessFormatter;
  IBOutlet NSNumberFormatter* elementSizeFormatter;
  IBOutlet NSButton*    uncertaintyVisibleCheckBox;
  IBOutlet CHColorWell* uncertaintyColorWell;
  IBOutlet NSButton*    uncertaintyNaNVisibleCheckBox;
  IBOutlet CHColorWell* uncertaintyNaNColorWell;
  IBOutlet NSTextField* thicknessTextField;
  IBOutlet NSStepper*   thicknessStepper;
  IBOutlet NSTextField* thicknessLabel;
  IBOutlet NSTextField* elementPixelSizeTextField;
  IBOutlet NSStepper*   elementPixelSizeStepper;
  IBOutlet NSTextField* elementPixelSizeLabel;
  IBOutlet CHColorWell* color1ColorWell;
  IBOutlet NSTextField* color1Label;
  IBOutlet CHColorWell* color2ColorWell;
  IBOutlet NSTextField* color2Label;
}

@property(nonatomic,assign) IBOutlet id delegate;
@property(nonatomic,assign) id target;
@property(nonatomic,assign) SEL action;
@property(nonatomic,retain) CHGraphCurveItem* graphCurveItem;

-(IBAction) changeParameter:(id)sender;

-(void) updateControls;

@end
