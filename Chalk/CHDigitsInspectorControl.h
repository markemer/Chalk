//
//  @interface CHDigitsInspectorControl.h
//  Chalk
//
//  Created by Pierre Chatelier on 19/12/2015.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CHChalkUtils.h"

@class CHBitInterpretationControl;
@class CHDigitsInspectorControl;
@class CHDigitsGroupNavigatorView;
@class CHChalkContext;
@class CHChalkError;
@class CHComputationConfiguration;
@class CHViewCentering;

@protocol CHDigitsInspectorControlDelegate
-(void) digitsInspector:(CHDigitsInspectorControl*)digitsInspector didUpdateRawValue:(const chalk_raw_value_t*)rawValue gmpValue:(const chalk_gmp_value_t*)gmpValue;
@end

@interface CHDigitsInspectorControl : NSViewController <CHDigitsInspectorControlDelegate> {
  chalk_bitInterpretation_action_t inputAction;
  chalk_bitInterpretation_action_t outputAction;
  CHComputationConfiguration* inputComputationConfiguration;
  BOOL                 isInputRawValue;
  chalk_gmp_value_t    inputGmpValue;
  chalk_raw_value_t    inputRawValue;
  chalk_raw_value_t    outputRawValue;
  chalk_gmp_value_t    outputGmpValue;
  chalk_number_part_minor_type_t minorPartsDisplay;
  chalk_number_part_minor_type_t minorPartsApply;
  NSUInteger leftShiftCount;
  NSUInteger rightShiftCount;
  NSUInteger leftRollCount;
  NSUInteger rightRollCount;
  NSUInteger swapBitsCount;
  chalk_conversion_result_t inputConversionResult;
  chalk_conversion_result_t outputConversionResult;
  CHBitInterpretationControl* localInputBitInterpretationControl;
  CHBitInterpretationControl* localOutputBitInterpretationControl;
}

@property(assign) IBOutlet NSView* rootView;
@property(assign) IBOutlet NSPopUpButton* inputNumberPartMajorPopUpButton;
@property(assign) IBOutlet NSPopUpButton* inputActionPopUpButton;
@property(assign) IBOutlet NSPopUpButton* outputActionPopUpButton;
@property(assign) IBOutlet NSView* inputBitInterpretationControlWrapper;
@property(assign) IBOutlet NSView* outputBitInterpretationControlWrapper;
@property(assign) IBOutlet CHBitInterpretationControl* inputBitInterpretationControl;
@property(assign) IBOutlet CHBitInterpretationControl* outputBitInterpretationControl;
@property(assign) IBOutlet CHViewCentering* navigationView;
@property(assign) IBOutlet NSTextField* minorPartsDisplayLabel;
@property(assign) IBOutlet NSTextField* minorPartsApplyLabel;
@property(assign) IBOutlet NSPopUpButton* minorPartsDisplayPopUpButton;
@property(assign) IBOutlet NSPopUpButton* minorPartsApplyPopUpButton;
@property(assign) IBOutlet CHDigitsGroupNavigatorView* digitsGroupNavigatorView;
@property(assign) IBOutlet NSSegmentedControl* digitsOrderSegmentedControl;
@property(assign) IBOutlet NSPopUpButton* bitsPerDigitPopUpButton;
@property(assign) IBOutlet NSButton* resetButton;
@property(assign) IBOutlet NSButton* reverseButton;
@property(assign) IBOutlet NSButton* setToZeroButton;
@property(assign) IBOutlet NSButton* setToOneButton;
@property(assign) IBOutlet NSButton* complement1Button;
@property(assign) IBOutlet NSButton* complement2Button;
@property(assign) IBOutlet NSButton* leftShiftButton;
@property(assign) IBOutlet NSTextField* leftShiftTextField;
@property(assign) IBOutlet NSStepper* leftShiftStepper;
@property(assign) IBOutlet NSButton* rightShiftButton;
@property(assign) IBOutlet NSTextField* rightShiftTextField;
@property(assign) IBOutlet NSStepper* rightShiftStepper;
@property(assign) IBOutlet NSButton* leftRollButton;
@property(assign) IBOutlet NSTextField* leftRollTextField;
@property(assign) IBOutlet NSStepper* leftRollStepper;
@property(assign) IBOutlet NSButton* rightRollButton;
@property(assign) IBOutlet NSTextField* rightRollTextField;
@property(assign) IBOutlet NSStepper* rightRollStepper;
@property(assign) IBOutlet NSButton* swapBitsButton;
@property(assign) IBOutlet NSTextField* swapBitsTextField;
@property(assign) IBOutlet NSStepper* swapBitsStepper;
@property(assign) IBOutlet NSButton* addOneButton;
@property(assign) IBOutlet NSButton* subOneButton;

@property(nonatomic,copy)          CHChalkContext*             chalkContext;
@property(nonatomic,copy,readonly) CHComputationConfiguration* inputComputationConfiguration;
@property(nonatomic,readonly)      const chalk_gmp_value_t*    inputGmpValue;
@property(nonatomic,readonly)      const chalk_gmp_value_t*    outputGmpValue;
@property(nonatomic,readonly)      chalk_conversion_result_t   inputConversionResult;
@property(nonatomic,readonly)      chalk_conversion_result_t   outputConversionResult;
@property(nonatomic,readonly,copy) CHChalkError*               inputConversionError;
@property(nonatomic,readonly,copy) CHChalkError*               outputConversionError;

@property(nonatomic,assign) id<CHDigitsInspectorControlDelegate> delegate;

-(void) setGmpValue:(const chalk_gmp_value_t*)numberValue computationConfiguration:(CHComputationConfiguration*)computationConfiguration;
-(void) setRawValue:(const chalk_raw_value_t*)numberValue computationConfiguration:(CHComputationConfiguration*)computationConfiguration;

-(IBAction) changeParameter:(id)sender;

@end
