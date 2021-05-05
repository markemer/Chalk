//
//  CHDigitsInspectorControl.m
//  Chalk
//
//  Created by Pierre Chatelier on 19/12/2015.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHDigitsInspectorControl.h"

#import "CHBitInterpretationControl.h"
#import "CHChalkContext.h"
#import "CHChalkError.h"
#import "CHChalkErrorContext.h"
#import "CHChalkToken.h"
#import "CHChalkValueNumberGmp.h"
#import "CHComputationConfiguration.h"
#import "CHDigitsGroupNavigatorView.h"
#import "CHPresentationConfiguration.h"
#import "CHStreamWrapper.h"
#import "CHUtils.h"
#import "CHViewCentering.h"
#import "NSObjectExtended.h"
#import "NSPopUpButtonExtended.h"
#import "NSSegmentedControlExtended.h"
#import "NSViewExtended.h"

@interface CHDigitsInspectorControl ()
-(void) adaptToValueType;
-(void) updateInputRawValue;
-(void) updateOutputGmpValue;
-(void) updateControls;
@end

@implementation CHDigitsInspectorControl

//@dynamic digitsGroupNavigatorView;
@synthesize chalkContext;
@dynamic inputComputationConfiguration;
@dynamic inputGmpValue;
@dynamic outputGmpValue;
@synthesize inputConversionResult;
@synthesize outputConversionResult;
@dynamic inputConversionError;
@dynamic outputConversionError;

-(void) dealloc
{
  [self->inputComputationConfiguration release];
  chalkRawValueClear(&self->inputRawValue, YES, self->chalkContext.gmpPool);
  chalkRawValueClear(&self->outputRawValue, YES, self->chalkContext.gmpPool);
  [self.inputBitInterpretationControl removeObserver:self forKeyPath:CHBitInterpretationBinding];
  [self.inputBitInterpretationControl removeObserver:self forKeyPath:CHBitInterpretationSignColorBinding];
  [self.inputBitInterpretationControl removeObserver:self forKeyPath:CHBitInterpretationExponentColorBinding];
  [self.inputBitInterpretationControl removeObserver:self forKeyPath:CHBitInterpretationSignificandColorBinding];
  [self.outputBitInterpretationControl removeObserver:self forKeyPath:CHBitInterpretationBinding];
  [self.outputBitInterpretationControl removeObserver:self forKeyPath:CHBitInterpretationSignColorBinding];
  [self.outputBitInterpretationControl removeObserver:self forKeyPath:CHBitInterpretationExponentColorBinding];
  [self.outputBitInterpretationControl removeObserver:self forKeyPath:CHBitInterpretationSignificandColorBinding];
  [self->localInputBitInterpretationControl release];
  [self->localOutputBitInterpretationControl release];
  chalkGmpValueClear(&self->inputGmpValue, YES, self->chalkContext.gmpPool);
  chalkGmpValueClear(&self->outputGmpValue, YES, self->chalkContext.gmpPool);
  [super dealloc];
}
//end dealloc

-(void) awakeFromNib
{
  self->leftShiftCount = 1;
  self->rightShiftCount = 1;
  self->leftRollCount = 1;
  self->rightRollCount = 1;
  self->swapBitsCount = 8;

  chalkRawValueCreate(&self->inputRawValue, self->chalkContext.gmpPool);
  chalkRawValueCreate(&self->outputRawValue, self->chalkContext.gmpPool);
  [[self.view dynamicCastToClass:[CHViewCentering class]] setCenterHorizontally:YES];
  
  self->_minorPartsDisplayLabel.stringValue = NSLocalizedString(@"Display", @"");
  [self->_minorPartsDisplayLabel sizeToFit];
  self->_minorPartsApplyLabel.stringValue = NSLocalizedString(@"Apply to", @"");
  [self->_minorPartsApplyLabel sizeToFit];

  [self->_inputNumberPartMajorPopUpButton removeAllItems];
  [self->_inputNumberPartMajorPopUpButton addItemWithTitle:NSLocalizedString(@"numerator", @"")];
  [self->_inputNumberPartMajorPopUpButton addItemWithTitle:NSLocalizedString(@"denominator", @"")];
  [self->_inputNumberPartMajorPopUpButton addItemWithTitle:NSLocalizedString(@"lower bound", @"")];
  [self->_inputNumberPartMajorPopUpButton addItemWithTitle:NSLocalizedString(@"upper bound", @"")];
  [self->_inputNumberPartMajorPopUpButton sizeToFit];

  NSRect tmp = NSZeroRect;
  [self->_inputActionPopUpButton removeAllItems];
  [self->_inputActionPopUpButton addItemWithTitle:NSLocalizedString(@"convert to", @"")];
  [self->_inputActionPopUpButton.itemArray.lastObject setTag:CHALK_BITINTERPRETATION_ACTION_CONVERT];
  [self->_inputActionPopUpButton addItemWithTitle:NSLocalizedString(@"interpret as", @"")];
  [self->_inputActionPopUpButton.itemArray.lastObject setTag:CHALK_BITINTERPRETATION_ACTION_INTERPRET];
  [self->_inputActionPopUpButton sizeToFit];
  tmp = self->_inputActionPopUpButton.frame;
  tmp.size.width -= 16;
  self->_inputActionPopUpButton.frame = tmp;
  self->inputAction = CHALK_BITINTERPRETATION_ACTION_CONVERT;

  [self->_outputActionPopUpButton removeAllItems];
  [self->_outputActionPopUpButton addItemWithTitle:NSLocalizedString(@"convert to", @"")];
  [self->_outputActionPopUpButton.itemArray.lastObject setTag:CHALK_BITINTERPRETATION_ACTION_CONVERT];
  [self->_outputActionPopUpButton addItemWithTitle:NSLocalizedString(@"interpret as", @"")];
  [self->_outputActionPopUpButton.itemArray.lastObject setTag:CHALK_BITINTERPRETATION_ACTION_INTERPRET];
  [self->_outputActionPopUpButton sizeToFit];
  tmp = self->_outputActionPopUpButton.frame;
  tmp.size.width -= 16;
  self->_outputActionPopUpButton.frame = tmp;
  self->outputAction = CHALK_BITINTERPRETATION_ACTION_INTERPRET;

  self->_inputActionPopUpButton.frame = NSMakeRect(
    CGRectGetMaxX(NSRectToCGRect(self->_inputNumberPartMajorPopUpButton.frame)),
    self->_inputActionPopUpButton.frame.origin.y,
    self->_inputActionPopUpButton.frame.size.width,
    self->_inputActionPopUpButton.frame.size.height);

  self->_outputActionPopUpButton.frame = NSMakeRect(
    self->_inputActionPopUpButton.frame.origin.x,
    self->_outputActionPopUpButton.frame.origin.y,
    self->_outputActionPopUpButton.frame.size.width,
    self->_outputActionPopUpButton.frame.size.height);
  
  self.inputBitInterpretationControlWrapper.frame = NSMakeRect(
    CGRectGetMaxX(NSRectToCGRect(self->_inputActionPopUpButton.frame)),
    self.inputBitInterpretationControlWrapper.frame.origin.y,
    self.view.frame.size.width-CGRectGetMaxX(NSRectToCGRect(self->_inputActionPopUpButton.frame)),
    self.inputBitInterpretationControlWrapper.frame.size.height);
  self.outputBitInterpretationControlWrapper.frame = NSMakeRect(
    CGRectGetMaxX(NSRectToCGRect(self->_outputActionPopUpButton.frame)),
    self.outputBitInterpretationControlWrapper.frame.origin.y,
    self.view.frame.size.width-CGRectGetMaxX(NSRectToCGRect(self->_outputActionPopUpButton.frame)),
    self.outputBitInterpretationControlWrapper.frame.size.height);
  
  self->localInputBitInterpretationControl = [[CHBitInterpretationControl alloc] initWithNibName:@"CHBitInterpretationControl" bundle:[NSBundle mainBundle]];
  self->localOutputBitInterpretationControl = [[CHBitInterpretationControl alloc] initWithNibName:@"CHBitInterpretationControl" bundle:[NSBundle mainBundle]];
  self.inputBitInterpretationControl = self->localInputBitInterpretationControl;
  self.outputBitInterpretationControl = self->localOutputBitInterpretationControl;
  [[self.inputBitInterpretationControl.view dynamicCastToClass:[CHViewCentering class]] setCenterHorizontally:YES];
  [[self.outputBitInterpretationControl.view dynamicCastToClass:[CHViewCentering class]] setCenterHorizontally:YES];
  [self.inputBitInterpretationControlWrapper addSubview:self.inputBitInterpretationControl.view];
  [self.outputBitInterpretationControlWrapper addSubview:self.outputBitInterpretationControl.view];
  [self.inputBitInterpretationControl.view setAutoresizingMask:NSViewNotSizable];
  [self.outputBitInterpretationControl.view setAutoresizingMask:NSViewNotSizable];
  [self.inputBitInterpretationControl addObserver:self forKeyPath:CHBitInterpretationBinding options:0 context:0];
  [self.inputBitInterpretationControl addObserver:self forKeyPath:CHBitInterpretationSignColorBinding options:0 context:0];
  [self.inputBitInterpretationControl addObserver:self forKeyPath:CHBitInterpretationExponentColorBinding options:0 context:0];
  [self.inputBitInterpretationControl addObserver:self forKeyPath:CHBitInterpretationSignificandColorBinding options:0 context:0];
  [self.outputBitInterpretationControl addObserver:self forKeyPath:CHBitInterpretationBinding options:0 context:0];
  [self.outputBitInterpretationControl addObserver:self forKeyPath:CHBitInterpretationSignColorBinding options:0 context:0];
  [self.outputBitInterpretationControl addObserver:self forKeyPath:CHBitInterpretationExponentColorBinding options:0 context:0];
  [self.outputBitInterpretationControl addObserver:self forKeyPath:CHBitInterpretationSignificandColorBinding options:0 context:0];
  self.navigationView.centerHorizontally = YES;
  
  [self->_bitsPerDigitPopUpButton addItemWithTitle:NSLocalizedString(@"base 2 (1 bit per digit)", @"")];
  [self->_bitsPerDigitPopUpButton.itemArray.lastObject setTag:1];
  [self->_bitsPerDigitPopUpButton addItemWithTitle:NSLocalizedString(@"base 4 (2 bits per digit)", @"")];
  [self->_bitsPerDigitPopUpButton.itemArray.lastObject setTag:2];
  [self->_bitsPerDigitPopUpButton addItemWithTitle:NSLocalizedString(@"base 8 (3 bits per digit)", @"")];
  [self->_bitsPerDigitPopUpButton.itemArray.lastObject setTag:3];
  [self->_bitsPerDigitPopUpButton addItemWithTitle:NSLocalizedString(@"base 16 (4 bits per digit)", @"")];
  [self->_bitsPerDigitPopUpButton.itemArray.lastObject setTag:4];
  [self->_bitsPerDigitPopUpButton addItemWithTitle:NSLocalizedString(@"base 32 (5 bits per digit)", @"")];
  [self->_bitsPerDigitPopUpButton.itemArray.lastObject setTag:5];
  self->_resetButton.toolTip = NSLocalizedString(@"reset", @"");
  self->_reverseButton.toolTip = NSLocalizedString(@"reverse bits", @"");
  
  self.setToZeroButton.toolTip = NSLocalizedString(@"set to 0", @"");
  self.setToOneButton.toolTip = NSLocalizedString(@"set to 1", @"");
  self.complement1Button.toolTip = NSLocalizedString(@"one's complement", @"");
  self.complement2Button.toolTip = NSLocalizedString(@"two's complement", @"");
  self.leftShiftButton.toolTip = NSLocalizedString(@"left shift", @"");
  self.leftShiftTextField.toolTip = NSLocalizedString(@"left shift", @"");
  self.leftShiftStepper.toolTip = NSLocalizedString(@"left shift", @"");
  self.rightShiftButton.toolTip = NSLocalizedString(@"right shift", @"");
  self.rightShiftButton.toolTip = NSLocalizedString(@"right shift", @"");
  self.rightShiftStepper.toolTip = NSLocalizedString(@"right shift", @"");
  self.leftRollButton.toolTip = NSLocalizedString(@"left roll", @"");
  self.leftRollTextField.toolTip = NSLocalizedString(@"left roll", @"");
  self.leftRollStepper.toolTip = NSLocalizedString(@"left roll", @"");
  self.rightRollButton.toolTip = NSLocalizedString(@"right roll", @"");
  self.rightRollButton.toolTip = NSLocalizedString(@"right roll", @"");
  self.rightRollStepper.toolTip = NSLocalizedString(@"right roll", @"");
  self.swapBitsButton.toolTip = NSLocalizedString(@"swap pairs of bits packets", @"");
  self.swapBitsButton.toolTip = NSLocalizedString(@"swap pairs of bits packets", @"");
  self.swapBitsStepper.toolTip = NSLocalizedString(@"swap pairs of bits packets", @"");
  self.addOneButton.toolTip = NSLocalizedString(@"increment by 1", @"");
  self.subOneButton.toolTip = NSLocalizedString(@"decrement by 1", @"");
  
  chalkGmpValueClear(&self->inputGmpValue, YES, self->chalkContext.gmpPool);
  chalkGmpValueClear(&self->outputGmpValue, YES, self->chalkContext.gmpPool);
  self.digitsGroupNavigatorView.delegate = self;
  [self updateControls];
}
//end awakeFromNib

-(const chalk_gmp_value_t*) inputGmpValue
{
  return &self->inputGmpValue;
}
//end numberValueOriginal

-(const chalk_gmp_value_t*) outputGmpValue
{
  return &self->outputGmpValue;
}
//end numberValueModified

-(void) setGmpValue:(const chalk_gmp_value_t*)gmpValue computationConfiguration:(CHComputationConfiguration*)aComputationConfiguration
{
  BOOL didUpdate = NO;
  self->isInputRawValue = NO;
  if (aComputationConfiguration != self->inputComputationConfiguration)
  {
    [self->inputComputationConfiguration release];
    self->inputComputationConfiguration = [aComputationConfiguration copy];
    didUpdate = YES;
  }//end if (aComputationConfiguration != self->inputComputeConfiguration)

  if (gmpValue != &self->inputGmpValue)
  {
    if (!gmpValue)
    {
      chalkGmpValueClear(&self->inputGmpValue, NO, self->chalkContext.gmpPool);
      chalkGmpValueClear(&self->outputGmpValue, NO, self->chalkContext.gmpPool);
      chalkRawValueClear(&self->inputRawValue, NO, self->chalkContext.gmpPool);
      chalkRawValueClear(&self->outputRawValue, NO, self->chalkContext.gmpPool);
    }//end if (!numberValue)
    else//if (numberValue)
    {
      chalkGmpValueSet(&self->inputGmpValue, gmpValue, self->chalkContext.gmpPool);
      chalkGmpValueSet(&self->outputGmpValue, gmpValue, self->chalkContext.gmpPool);
      chalkGmpValueSetZero(&self->outputGmpValue, YES, self->chalkContext.gmpPool);
      chalkRawValueSetZero(&self->inputRawValue, self->chalkContext.gmpPool);
      chalkRawValueSetZero(&self->outputRawValue, self->chalkContext.gmpPool);
    }//end if (numberValue)
    didUpdate = YES;
  }//end if (gmpValue != &self->inputGmpValue)
  if (didUpdate)
  {
    memset(&self->inputConversionResult, 0, sizeof(self->inputConversionResult));
    memset(&self->outputConversionResult, 0, sizeof(self->outputConversionResult));
    [self.inputBitInterpretationControl setValueType:self->inputGmpValue.type computationConfiguration:self->inputComputationConfiguration];
    [self.outputBitInterpretationControl setValueType:self->outputGmpValue.type computationConfiguration:self->inputComputationConfiguration];
    [self adaptToValueType];
    [self updateInputRawValue];
  }//end if (didUpdate)
}
//end setGmpValue:computeMode:

-(void) setRawValue:(const chalk_raw_value_t*)rawValue computationConfiguration:(CHComputationConfiguration*)aComputationConfiguration
{
  BOOL didUpdate = NO;
  self->isInputRawValue = YES;
  if (aComputationConfiguration != self->inputComputationConfiguration)
  {
    [self->inputComputationConfiguration release];
    self->inputComputationConfiguration = [aComputationConfiguration copy];
    didUpdate = YES;
  }//end if (aComputationConfiguration != self->inputComputeConfiguration)

  if (!rawValue)
  {
    chalkGmpValueClear(&self->inputGmpValue, NO, self->chalkContext.gmpPool);
    chalkGmpValueClear(&self->outputGmpValue, NO, self->chalkContext.gmpPool);
    chalkRawValueClear(&self->inputRawValue, NO, self->chalkContext.gmpPool);
    chalkRawValueClear(&self->outputRawValue, NO, self->chalkContext.gmpPool);
  }//end if (!rawValue)
  else//if (rawValue)
  {
    chalkGmpValueClear(&self->inputGmpValue, NO, self->chalkContext.gmpPool);
    chalkGmpValueClear(&self->outputGmpValue, NO, self->chalkContext.gmpPool);
    chalkGmpValueSetZero(&self->outputGmpValue, YES, self->chalkContext.gmpPool);
    chalkRawValueSet(&self->inputRawValue, rawValue, self->chalkContext.gmpPool);
    chalkRawValueSet(&self->outputRawValue, rawValue, self->chalkContext.gmpPool);
    if (getEncodingIsInteger(self->inputRawValue.bitInterpretation.numberEncoding))
       chalkGmpValueMakeInteger(&self->outputGmpValue, self->chalkContext.gmpPool);
    else//if (!getEncodingIsInteger(&self->inputRawValue.bitInterpretation))
       chalkGmpValueMakeRealExact(&self->outputGmpValue, self->chalkContext.computationConfiguration.softFloatSignificandBits, self->chalkContext.gmpPool);
  }//end if (rawValue)
  didUpdate = YES;

  if (didUpdate)
  {
    memset(&self->inputConversionResult, 0, sizeof(self->inputConversionResult));
    memset(&self->outputConversionResult, 0, sizeof(self->outputConversionResult));
    [self.inputBitInterpretationControl setFixedBitInterpretation:&self->inputRawValue.bitInterpretation];
    [self.outputBitInterpretationControl setValueType:self->outputGmpValue.type computationConfiguration:self->inputComputationConfiguration];
    self.outputBitInterpretationControl.bitInterpretation = &self->outputRawValue.bitInterpretation;
    [self adaptToValueType];
    [self updateInputRawValue];
  }//end if (didUpdate)
}
//end setRawValue:computeMode:

-(IBAction) changeParameter:(id)sender
{
  if (sender == self->_inputNumberPartMajorPopUpButton)
  {
    chalk_bit_interpretation_t newBitInterpretation = *self->_inputBitInterpretationControl.bitInterpretation;
    newBitInterpretation.major = self->_inputNumberPartMajorPopUpButton.selectedTag;
    self->_inputBitInterpretationControl.bitInterpretation = &newBitInterpretation;
  }//end if (sender == self->_inputNumberPartMajorPopUpButton)
  else if (sender == self->_inputActionPopUpButton)
  {
    self->inputAction = self->_inputActionPopUpButton.selectedTag;
    [self updateControls];
  }//end if (sender == self->_inputActionPopUpButton)
  else if (sender == self->_outputActionPopUpButton)
  {
    self->outputAction = self->_outputActionPopUpButton.selectedTag;
    [self updateOutputGmpValue];
    [self updateControls];
  }//end if (sender == self->_outputActionPopUpButton)
  else if (sender == self->_minorPartsDisplayPopUpButton)
  {
    self->minorPartsDisplay = self->_minorPartsDisplayPopUpButton.selectedTag;
    [self updateControls];
  }//end if (sender == self->_minorPartsDisplayPopUpButton)
  else if (sender == self->_minorPartsApplyPopUpButton)
  {
    self->minorPartsApply = self->_minorPartsApplyPopUpButton.selectedTag;
    [self updateControls];
  }//end if (sender == self->_minorPartsApplyPopUpButton)
  else if (sender == self->_digitsOrderSegmentedControl)
  {
    self.digitsGroupNavigatorView.digitsOrder = self->_digitsOrderSegmentedControl.selectedSegmentTag;
  }//end if (sender == _digitsOrderSegmentedControl)
  else if (sender == self->_bitsPerDigitPopUpButton)
  {
    self.digitsGroupNavigatorView.bitsPerDigit = self->_bitsPerDigitPopUpButton.selectedTag;
  }//end if (sender == _bitsPerDigitPopUpButton)
  else if (sender == self->_resetButton)
  {
    NSRange range = getMultipleMinorPartsBitsRangeForBitInterpretation(&self->outputRawValue.bitInterpretation, self->minorPartsApply);
    const mp_limb_t* srcLimbs = mpz_limbs_read(self->inputRawValue.bits);
    size_t srcLimbsCount = mpz_size(self->inputRawValue.bits);
    BOOL error = NO;
    mpz_copyBits(self->outputRawValue.bits, range.location, srcLimbs, srcLimbsCount, range, &error);
    [self updateOutputGmpValue];
    [self updateControls];
  }//end if (sender == self->_resetButton)
  else if (sender == self->_reverseButton)
  {
    NSRange range = getMultipleMinorPartsBitsRangeForBitInterpretation(&self->outputRawValue.bitInterpretation, self->minorPartsApply);
    chalkRawValueReverseBits(&self->outputRawValue, range);
    [self updateOutputGmpValue];
    [self updateControls];
  }//end if (sender == self->_reverseButton)
  else if (sender == self->_setToZeroButton)
  {
    NSRange range = getMultipleMinorPartsBitsRangeForBitInterpretation(&self->outputRawValue.bitInterpretation, self->minorPartsApply);
    mpz_set_zero(self->outputRawValue.bits, range);
    [self updateOutputGmpValue];
    [self updateControls];
  }//end if (sender == self->_setToZeroButton)
  else if (sender == self->_setToOneButton)
  {
    NSRange range = getMultipleMinorPartsBitsRangeForBitInterpretation(&self->outputRawValue.bitInterpretation, self->minorPartsApply);
    mpz_set_one(self->outputRawValue.bits, range);
    [self updateOutputGmpValue];
    [self updateControls];
  }//end if (sender == self->_setToOneButton)
  else if (sender == self->_complement1Button)
  {
    NSRange range = getMultipleMinorPartsBitsRangeForBitInterpretation(&self->outputRawValue.bitInterpretation, self->minorPartsApply);
    mpz_complement1(self->outputRawValue.bits, range);
    [self updateOutputGmpValue];
    [self updateControls];
  }//end if (sender == self->_complement1Button)
  else if (sender == self->_complement2Button)
  {
    NSRange range = getMultipleMinorPartsBitsRangeForBitInterpretation(&self->outputRawValue.bitInterpretation, self->minorPartsApply);
    mpz_complement1(self->outputRawValue.bits, range);
    mpz_add_one(self->outputRawValue.bits, range);
    [self updateOutputGmpValue];
    [self updateControls];
  }//end if (sender == self->_complement2Button)
  else if (sender == self->_leftShiftTextField)
  {
    self->leftShiftCount = (NSUInteger)self->_leftShiftTextField.integerValue;
    [self updateControls];
  }//end if (sender == self->_leftShiftTextField)
  else if (sender == self->_leftShiftStepper)
  {
    self->leftShiftCount = (NSUInteger)self->_leftShiftStepper.integerValue;
    [self updateControls];
  }//end if (sender == self->_leftShiftStepper)
  else if (sender == self->_leftShiftButton)
  {
    if (self->leftShiftCount)
    {
      NSRange range = getMultipleMinorPartsBitsRangeForBitInterpretation(&self->outputRawValue.bitInterpretation, self->minorPartsApply);
      mpz_shift_left(self->outputRawValue.bits, self->leftShiftCount, range);
      [self updateOutputGmpValue];
      [self updateControls];
    }//end if (self->leftShiftCount)
  }//end if (sender == self->_leftShiftButton)
  else if (sender == self->_rightShiftTextField)
  {
    self->rightShiftCount = (NSUInteger)self->_rightShiftTextField.integerValue;
    [self updateControls];
  }//end if (sender == self->_rightShiftTextField)
  else if (sender == self->_rightShiftStepper)
  {
    self->rightShiftCount = (NSUInteger)self->_rightShiftStepper.integerValue;
    [self updateControls];
  }//end if (sender == self->_rightShiftStepper)
  else if (sender == self->_rightShiftButton)
  {
    if (self->rightShiftCount)
    {
      NSRange range = getMultipleMinorPartsBitsRangeForBitInterpretation(&self->outputRawValue.bitInterpretation, self->minorPartsApply);
      mpz_shift_right(self->outputRawValue.bits, self->rightShiftCount, range);
      [self updateOutputGmpValue];
      [self updateControls];
    }//end if (self->rightShiftCount)
  }//end if (sender == self->_rightShiftButton)
  else if (sender == self->_leftRollTextField)
  {
    self->leftRollCount = (NSUInteger)self->_leftRollTextField.integerValue;
    [self updateControls];
  }//end if (sender == self->_leftRollTextField)
  else if (sender == self->_leftRollStepper)
  {
    self->leftRollCount = (NSUInteger)self->_leftRollStepper.integerValue;
    [self updateControls];
  }//end if (sender == self->_leftRollStepper)
  else if (sender == self->_leftRollButton)
  {
    if (self->leftRollCount)
    {
      NSRange range = getMultipleMinorPartsBitsRangeForBitInterpretation(&self->outputRawValue.bitInterpretation, self->minorPartsApply);
      mpz_roll_left(self->outputRawValue.bits, self->leftRollCount, range);
      [self updateOutputGmpValue];
      [self updateControls];
    }//end if (self->leftRollCount)
  }//end if (sender == self->_leftRollButton)
  else if (sender == self->_rightRollTextField)
  {
    self->rightRollCount = (NSUInteger)self->_rightRollTextField.integerValue;
    [self updateControls];
  }//end if (sender == self->_rightRollTextField)
  else if (sender == self->_rightRollStepper)
  {
    self->rightRollCount = (NSUInteger)self->_rightRollStepper.integerValue;
    [self updateControls];
  }//end if (sender == self->_rightRollStepper)
  else if (sender == self->_rightRollButton)
  {
    if (self->rightRollCount)
    {
      NSRange range = getMultipleMinorPartsBitsRangeForBitInterpretation(&self->outputRawValue.bitInterpretation, self->minorPartsApply);
      mpz_roll_right(self->outputRawValue.bits, self->rightRollCount, range);
      [self updateOutputGmpValue];
      [self updateControls];
    }//end if (self->rightRollCount)
  }//end if (sender == self->_rightRollButton)
  else if (sender == self->_swapBitsTextField)
  {
    self->swapBitsCount = (NSUInteger)self->_swapBitsTextField.integerValue;
    [self updateControls];
  }//end if (sender == self->_swapBitsTextField)
  else if (sender == self->_swapBitsStepper)
  {
    self->swapBitsCount = (NSUInteger)self->_swapBitsStepper.integerValue;
    [self updateControls];
  }//end if (sender == self->_swapBitsStepper)
  else if (sender == self->_swapBitsButton)
  {
    if (self->swapBitsCount)
    {
      NSRange range = getMultipleMinorPartsBitsRangeForBitInterpretation(&self->outputRawValue.bitInterpretation, self->minorPartsApply);
      mpz_swap_packets_pairs(self->outputRawValue.bits, self->swapBitsCount, range);
      [self updateOutputGmpValue];
      [self updateControls];
    }//end if (self->swapBitsCount)
  }//end if (sender == self->_swapBitsButton)
  else if (sender == self->_addOneButton)
  {
    NSRange range = getMultipleMinorPartsBitsRangeForBitInterpretation(&self->outputRawValue.bitInterpretation, self->minorPartsApply);
    mpz_add_one(self->outputRawValue.bits, range);
    [self updateOutputGmpValue];
    [self updateControls];
  }//end if (sender == self->_addOneButton)
  else if (sender == self->_subOneButton)
  {
    NSRange range = getMultipleMinorPartsBitsRangeForBitInterpretation(&self->outputRawValue.bitInterpretation, self->minorPartsApply);
    mpz_sub_one(self->outputRawValue.bits, range);
    [self updateOutputGmpValue];
    [self updateControls];
  }//end if (sender == self->_subOneButton)
}
//end changeParameter:

-(void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  if (object == self.inputBitInterpretationControl)
  {
    if ([keyPath isEqualToString:CHBitInterpretationBinding])
      [self updateInputRawValue];
    [self updateControls];
  }//end if (object == self.inputBitInterpretationControl)
  else if (object == self.outputBitInterpretationControl)
  {
    if ([keyPath isEqualToString:CHBitInterpretationBinding])
      [self updateOutputGmpValue];
    [self updateControls];
  }//end if (object == outputBitInterpretationControl)
}
//end observeValueForKeyPath:ofObject:change:context

-(void) adaptToValueType
{
  const chalk_bit_interpretation_t* bitInterpretation = self.inputBitInterpretationControl.bitInterpretation;
  chalk_number_part_minor_type_t allMinorParts = CHALK_NUMBER_PART_MINOR_UNDEFINED;
  NSUInteger minorPartsCount = getMinorPartOrderedCountForBitInterpretation(bitInterpretation);
  for(NSUInteger i = 0 ; i<minorPartsCount ; ++i)
    allMinorParts |= getMinorPartOrderedForBitInterpretation(bitInterpretation, i);
  if (self->minorPartsDisplay == CHALK_NUMBER_PART_MINOR_UNDEFINED)
    self->minorPartsDisplay = allMinorParts;
  else
    self->minorPartsDisplay &= allMinorParts;
  if (self->minorPartsApply == CHALK_NUMBER_PART_MINOR_UNDEFINED)
    self->minorPartsApply = allMinorParts;
  else
    self->minorPartsApply &= allMinorParts;
}
//end adaptToValueType

-(void) updateInputRawValue
{
  chalk_bit_interpretation_t bitInterpretation = *self.inputBitInterpretationControl.bitInterpretation;
  if ((bitInterpretation.numberEncoding.encodingType == CHALK_NUMBER_ENCODING_GMP_STANDARD) &&
      (bitInterpretation.numberEncoding.encodingVariant.gmpStandardVariantEncoding == CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_UNDEFINED))
    bitInterpretation.numberEncoding.encodingVariant.gmpStandardVariantEncoding =
      (self->inputGmpValue.type == CHALK_VALUE_TYPE_INTEGER) ?
        CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_Z :
      (self->inputGmpValue.type == CHALK_VALUE_TYPE_FRACTION) ?
        CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_Z :
      (self->inputGmpValue.type == CHALK_VALUE_TYPE_REAL_EXACT) ?
        CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_FR :
      (self->inputGmpValue.type == CHALK_VALUE_TYPE_REAL_APPROX) ?
        CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_FR :
      CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_UNDEFINED;
  else if ((bitInterpretation.numberEncoding.encodingType == CHALK_NUMBER_ENCODING_GMP_CUSTOM) &&
      (bitInterpretation.numberEncoding.encodingVariant.gmpStandardVariantEncoding == CHALK_NUMBER_ENCODING_GMP_CUSTOM_VARIANT_UNDEFINED))
    bitInterpretation.numberEncoding.encodingVariant.gmpCustomVariantEncoding =
      (self->inputGmpValue.type == CHALK_VALUE_TYPE_INTEGER) ?
        CHALK_NUMBER_ENCODING_GMP_CUSTOM_VARIANT_Z :
      (self->inputGmpValue.type == CHALK_VALUE_TYPE_FRACTION) ?
        CHALK_NUMBER_ENCODING_GMP_CUSTOM_VARIANT_Z :
      (self->inputGmpValue.type == CHALK_VALUE_TYPE_REAL_EXACT) ?
        CHALK_NUMBER_ENCODING_GMP_CUSTOM_VARIANT_FR :
      (self->inputGmpValue.type == CHALK_VALUE_TYPE_REAL_APPROX) ?
        CHALK_NUMBER_ENCODING_GMP_CUSTOM_VARIANT_FR :
      CHALK_NUMBER_ENCODING_GMP_CUSTOM_VARIANT_UNDEFINED;
  if (self->inputGmpValue.type != CHALK_VALUE_TYPE_UNDEFINED)
  {
    self->inputConversionResult =
      (self->inputAction == CHALK_BITINTERPRETATION_ACTION_CONVERT) ?
        convertFromValueToRaw(&self->inputRawValue, &self->inputGmpValue, self->inputComputationConfiguration.computeMode, &bitInterpretation, self->chalkContext) :
      (chalk_conversion_result_t){YES, 0};
    self->inputRawValue.bitInterpretation = bitInterpretation;
    chalkRawValueSet(&self->outputRawValue, &self->inputRawValue, self->chalkContext.gmpPool);
  }//end if (self->inputGmpValue.type != CHALK_VALUE_TYPE_UNDEFINED)
  [self updateOutputGmpValue];
  [self updateControls];
}
//end updateInputRawValue

-(void) updateOutputGmpValue
{
  const chalk_bit_interpretation_t* bitInterpretation = self.outputBitInterpretationControl.bitInterpretation;
  chalk_number_encoding_t numberEncoding =
    bitInterpretation->numberEncoding;
  chalk_number_encoding_type_t encodingType =
    (self->inputRawValue.bitInterpretation.numberEncoding.encodingType == CHALK_NUMBER_ENCODING_UNDEFINED) ? CHALK_NUMBER_ENCODING_UNDEFINED :
    numberEncoding.encodingType;
  chalk_number_encoding_variant_t encodingVariant = numberEncoding.encodingVariant;
  switch(encodingType)
  {
    case CHALK_NUMBER_ENCODING_GMP_STANDARD:
    case CHALK_NUMBER_ENCODING_GMP_CUSTOM:
      {
        switch(encodingVariant.gmpStandardVariantEncoding)
        {
          case CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_UNDEFINED:
            chalkGmpValueClear(&self->outputGmpValue, YES, self->chalkContext.gmpPool);
            break;
          case CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_Z:
            chalkGmpValueMakeInteger(&self->outputGmpValue, self->chalkContext.gmpPool);
            break;
          case CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_FR:
            chalkGmpValueMakeRealExact(&self->outputGmpValue, self->chalkContext.computationConfiguration.softFloatSignificandBits, self->chalkContext.gmpPool);
            break;
        }//end switch(encodingVariant.gmpStandardEncoding)
      }//end case CHALK_NUMBER_ENCODING_GMP_STANDARD
      break;
    case CHALK_NUMBER_ENCODING_IEEE754_STANDARD:
      {
        switch(encodingVariant.ieee754StandardVariantEncoding)
        {
          case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_HALF:
          case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_SINGLE:
          case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_DOUBLE:
          case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_QUADRUPLE:
          case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_OCTUPLE:
            chalkGmpValueMakeRealExact(&self->outputGmpValue, self->chalkContext.computationConfiguration.softFloatSignificandBits, self->chalkContext.gmpPool);
            break;
          case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_X86_EXTENDED_PRECISION:
            chalkGmpValueMakeRealExact(&self->outputGmpValue, self->chalkContext.computationConfiguration.softFloatSignificandBits, self->chalkContext.gmpPool);
            break;
          case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_UNDEFINED:
            chalkGmpValueClear(&self->outputGmpValue, YES, self->chalkContext.gmpPool);
            break;
        }//end switch(encodingVariant.gmpStandardEncoding)
      }//end case CHALK_NUMBER_ENCODING_IEEE754_STANDARD
      break;
    case CHALK_NUMBER_ENCODING_INTEGER_STANDARD:
      {
        switch(encodingVariant.integerStandardVariantEncoding)
        {
          case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_8S:
          case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_16S:
          case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_32S:
          case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_64S:
          case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_128S:
          case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_256S:
          case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_8U:
          case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_16U:
          case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_32U:
          case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_64U:
          case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_128U:
          case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_256U:
            chalkGmpValueMakeInteger(&self->outputGmpValue, self->chalkContext.gmpPool);
            break;
          case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_UNDEFINED:
            chalkGmpValueClear(&self->outputGmpValue, YES, self->chalkContext.gmpPool);
            break;
        }//end switch(encodingVariant.gmpStandardEncoding)
      }//end case CHALK_NUMBER_ENCODING_INTEGER_STANDARD
      break;
    case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM:
      {
        switch(encodingVariant.integerCustomVariantEncoding)
        {
          case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_SIGNED:
          case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_UNSIGNED:
            chalkGmpValueMakeInteger(&self->outputGmpValue, self->chalkContext.gmpPool);
            break;
          case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_UNDEFINED:
            chalkGmpValueClear(&self->outputGmpValue, YES, self->chalkContext.gmpPool);
            break;
        }//end switch(encodingVariant.integerCustomVariantEncoding)
      }//end case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM
      break;
    case CHALK_NUMBER_ENCODING_UNDEFINED:
      chalkGmpValueClear(&self->outputGmpValue, YES, self->chalkContext.gmpPool);
      break;
  }//end switch(encodingType)
  chalkGmpValueSetZero(&self->outputGmpValue, YES, self->chalkContext.gmpPool);
  if (self->outputGmpValue.type != CHALK_VALUE_TYPE_UNDEFINED)
  {
    self->outputConversionResult =
      (self->outputAction == CHALK_BITINTERPRETATION_ACTION_CONVERT) ?
        convertFromRawToValue(&self->outputGmpValue, &self->outputRawValue, self->inputComputationConfiguration.computeMode, bitInterpretation, self->chalkContext) :
      (self->outputAction == CHALK_BITINTERPRETATION_ACTION_INTERPRET) ?
        interpretFromRawToValue(&self->outputGmpValue, &self->outputRawValue, self->inputComputationConfiguration.computeMode, bitInterpretation, self->chalkContext) :
      ((chalk_conversion_result_t){YES, 0});
    self->outputRawValue.bitInterpretation = self->inputRawValue.bitInterpretation;//*bitInterpretation;
  }//end if (self->outputGmpValue != CHALK_VALUE_TYPE_UNDEFINED)
  [self digitsInspector:self didUpdateRawValue:&self->outputRawValue gmpValue:&self->outputGmpValue];
}
//end updateOutputGmpValue

-(void) outputRawValueDidChange:(id)sender
{
  [self updateOutputGmpValue];
}
//end outputRawValueDidChange

-(void) updateControls
{
  BOOL hasNumber = (self->inputGmpValue.type != CHALK_VALUE_TYPE_UNDEFINED) || (self->inputRawValue.bitInterpretation.numberEncoding.encodingType != CHALK_NUMBER_ENCODING_UNDEFINED);

  NSArray* numberPartMajorItems = nil;
  switch(self->inputGmpValue.type)
  {
    case CHALK_VALUE_TYPE_INTEGER:
      numberPartMajorItems = @[
        @{NSTitleBinding:NSLocalizedString(@"integer", @""),
          NSTagBinding:@(CHALK_NUMBER_PART_MAJOR_UNDEFINED)},
      ];
      break;
    case CHALK_VALUE_TYPE_FRACTION:
      numberPartMajorItems = @[
        @{NSTitleBinding:NSLocalizedString(@"numerator", @""), NSTagBinding:@(CHALK_NUMBER_PART_MAJOR_NUMERATOR)},
        @{NSTitleBinding:NSLocalizedString(@"estimation", @""), NSTagBinding:@(CHALK_NUMBER_PART_MAJOR_BEST_VALUE)},
        @{NSTitleBinding:NSLocalizedString(@"denominator", @""), NSTagBinding:@(CHALK_NUMBER_PART_MAJOR_DENOMINATOR)},
      ];
      break;
    case CHALK_VALUE_TYPE_REAL_APPROX:
      if (self->inputComputationConfiguration.computeMode != CHALK_COMPUTE_MODE_APPROX_BEST)
        numberPartMajorItems = @[
          @{NSTitleBinding:NSLocalizedString(@"lower bound", @""), NSTagBinding:@(CHALK_NUMBER_PART_MAJOR_LOWER_BOUND)},
          @{NSTitleBinding:NSLocalizedString(@"estimation", @""), NSTagBinding:@(CHALK_NUMBER_PART_MAJOR_BEST_VALUE)},
          @{NSTitleBinding:NSLocalizedString(@"upper bound", @""), NSTagBinding:@(CHALK_NUMBER_PART_MAJOR_UPPER_BOUND)},
        ];
      break;
    default:
      break;
  }//end switch(self->inputGmpValue.type)
  
  self->_inputNumberPartMajorPopUpButton.enabled = hasNumber && (numberPartMajorItems.count > 1);
  [self->_inputNumberPartMajorPopUpButton removeAllItems];
  for(NSDictionary* dict in numberPartMajorItems)
  {
    NSString* title = dict[NSTitleBinding];
    NSNumber* tag = dict[NSTagBinding];
    [self->_inputNumberPartMajorPopUpButton addItemWithTitle:title];
    [[[self->_inputNumberPartMajorPopUpButton itemArray] lastObject] setTag:tag.integerValue];
  }//end for each numberPartMajorItem
  [self->_inputNumberPartMajorPopUpButton selectItemWithTag:self.inputBitInterpretationControl.bitInterpretation->major];

  self->_inputActionPopUpButton.enabled = NO;
  [self->_inputActionPopUpButton selectItemWithTag:self->inputAction];
  self->_outputActionPopUpButton.enabled = hasNumber;
  [self->_outputActionPopUpButton selectItemWithTag:self->outputAction];

  NSArray* numberPartMinorItemsSSA = @[
        @{NSTitleBinding:NSLocalizedString(@"sign", @""), NSTagBinding:@(CHALK_NUMBER_PART_MINOR_SIGN)},
        @{NSTitleBinding:NSLocalizedString(@"significand", @""), NSTagBinding:@(CHALK_NUMBER_PART_MINOR_SIGNIFICAND)},
        @{NSTitleBinding:NSLocalizedString(@"all", @""), NSTagBinding:@(CHALK_NUMBER_PART_MINOR_SIGN|CHALK_NUMBER_PART_MINOR_SIGNIFICAND)}
      ];
  NSArray* numberPartMinorItemsSESA = @[
        @{NSTitleBinding:NSLocalizedString(@"sign", @""), NSTagBinding:@(CHALK_NUMBER_PART_MINOR_SIGN)},
        @{NSTitleBinding:NSLocalizedString(@"exponent", @""), NSTagBinding:@(CHALK_NUMBER_PART_MINOR_EXPONENT)},
        @{NSTitleBinding:NSLocalizedString(@"significand", @""), NSTagBinding:@(CHALK_NUMBER_PART_MINOR_SIGNIFICAND)},
        @{NSTitleBinding:NSLocalizedString(@"all", @""), NSTagBinding:@(CHALK_NUMBER_PART_MINOR_SIGN|CHALK_NUMBER_PART_MINOR_EXPONENT|CHALK_NUMBER_PART_MINOR_SIGNIFICAND)}
      ];

  NSArray* numberPartMinorItemsDisplay = nil;
  NSArray* numberPartMinorItemsApply = nil;
  const chalk_bit_interpretation_t* bitInterpretation = self.inputBitInterpretationControl.bitInterpretation;
  switch(bitInterpretation->numberEncoding.encodingType)
  {
    case CHALK_NUMBER_ENCODING_GMP_STANDARD:
    case CHALK_NUMBER_ENCODING_GMP_CUSTOM:
      numberPartMinorItemsDisplay =
        (bitInterpretation->numberEncoding.encodingVariant.gmpStandardVariantEncoding == CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_FR) ?
          numberPartMinorItemsSESA :
        (bitInterpretation->numberEncoding.encodingVariant.gmpStandardVariantEncoding == CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_Z) ?
          numberPartMinorItemsSSA :
        nil;
      numberPartMinorItemsApply =
        (bitInterpretation->numberEncoding.encodingVariant.gmpStandardVariantEncoding == CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_FR) ?
          numberPartMinorItemsSESA :
        (bitInterpretation->numberEncoding.encodingVariant.gmpStandardVariantEncoding == CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_Z) ?
          numberPartMinorItemsSSA :
        nil;
      break;
    case CHALK_NUMBER_ENCODING_IEEE754_STANDARD:
      numberPartMinorItemsDisplay = numberPartMinorItemsSESA;
      numberPartMinorItemsApply = numberPartMinorItemsSESA;
      break;
    case CHALK_NUMBER_ENCODING_INTEGER_STANDARD:
      numberPartMinorItemsDisplay = numberPartMinorItemsSSA;
      numberPartMinorItemsApply = numberPartMinorItemsSSA;
      break;
    case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM:
      numberPartMinorItemsDisplay = numberPartMinorItemsSSA;
      numberPartMinorItemsApply = numberPartMinorItemsSSA;
      break;
    case CHALK_NUMBER_ENCODING_UNDEFINED:
      break;
  }//end switch(bitInterpretation->numberEncoding.encodingType)
  
  self->_minorPartsDisplayPopUpButton.enabled = hasNumber && (numberPartMinorItemsDisplay.count != 0);
  [self->_minorPartsDisplayPopUpButton removeAllItems];
  for(NSDictionary* dict in numberPartMinorItemsDisplay)
  {
    NSString* title = dict[NSTitleBinding];
    NSNumber* tag = dict[NSTagBinding];
    [self->_minorPartsDisplayPopUpButton addItemWithTitle:title];
    [[[self->_minorPartsDisplayPopUpButton itemArray] lastObject] setTag:tag.integerValue];
  }//end for each numberPartMinorItemsDisplay
  BOOL selectedDisplay = [self->_minorPartsDisplayPopUpButton selectItemWithTag:self->minorPartsDisplay];
  if (!selectedDisplay)
  {
    self->minorPartsDisplay = [[[self->_minorPartsDisplayPopUpButton itemArray] lastObject] tag];
    [self->_minorPartsDisplayPopUpButton selectItemWithTag:self->minorPartsDisplay emptySelectionOnFailure:YES];
  }//end if (!selectedDisplay)
  
  self->_minorPartsApplyPopUpButton.enabled = hasNumber && (numberPartMinorItemsApply.count != 0);
  [self->_minorPartsApplyPopUpButton removeAllItems];
  for(NSDictionary* dict in numberPartMinorItemsApply)
  {
    NSString* title = dict[NSTitleBinding];
    NSNumber* tag = dict[NSTagBinding];
    [self->_minorPartsApplyPopUpButton addItemWithTitle:title];
    [[[self->_minorPartsApplyPopUpButton itemArray] lastObject] setTag:tag.integerValue];
  }//end for each numberPartMinorItemsApply
  BOOL selectedApply = [self->_minorPartsApplyPopUpButton selectItemWithTag:self->minorPartsApply];
  if (!selectedApply)
  {
    self->minorPartsApply = [[[self->_minorPartsApplyPopUpButton itemArray] lastObject] tag];
    [self->_minorPartsApplyPopUpButton selectItemWithTag:self->minorPartsApply emptySelectionOnFailure:YES];
  }//end if (!selectedApply)

  const chalk_bit_interpretation_t* inputBitInterpretation = self.inputBitInterpretationControl.bitInterpretation;
  NSRange digitsRange = getMultipleMinorPartsBitsRangeForBitInterpretation(inputBitInterpretation, self->minorPartsDisplay);
  NSRange digitsRangeNavigatable = digitsRange;
  NSRange digitsRangeModifiable = digitsRange;
  NSRange digitsRangeNatural = digitsRange;
  BOOL hasInfiniteSignificand =
   (inputBitInterpretation->numberEncoding.encodingType == CHALK_NUMBER_ENCODING_GMP_STANDARD) &&
   ((minorPartsDisplay & CHALK_NUMBER_PART_MINOR_SIGNIFICAND) != 0);
  if (hasInfiniteSignificand)
  {
    digitsRangeNavigatable = NSMakeRange(digitsRange.location, NSUIntegerMax-digitsRange.location);
    digitsRangeModifiable = NSMakeRange(digitsRange.location, NSUIntegerMax-digitsRange.location);
    digitsRangeNatural = digitsRange;
  }//end if (hasInfiniteSignificand)
  [self.digitsGroupNavigatorView beginUpdate];
  self.digitsGroupNavigatorView.enabled = hasNumber;
  self.digitsGroupNavigatorView.digitsGroupSize = 64;
  self.digitsGroupNavigatorView.digitsRangeNavigatable = digitsRangeNavigatable;
  self.digitsGroupNavigatorView.digitsRangeModifiable = digitsRangeModifiable;
  self.digitsGroupNavigatorView.digitsRangeNatural = digitsRangeNatural;
  self.digitsGroupNavigatorView.inputComputeMode = self->inputComputationConfiguration.computeMode;
  self.digitsGroupNavigatorView.inputNumberValue = &self->inputGmpValue;
  self.digitsGroupNavigatorView.inputBitInterpretation = self.inputBitInterpretationControl.bitInterpretation;
  self.digitsGroupNavigatorView.inputRawValue = &self->inputRawValue;
  self.digitsGroupNavigatorView.minorPartsVisible = self->minorPartsDisplay;
  self.digitsGroupNavigatorView.outputRawValue = &self->outputRawValue;
  self.digitsGroupNavigatorView.outputBitInterpretation = self.outputBitInterpretationControl.bitInterpretation;
  self.digitsGroupNavigatorView.signColor1 = self.inputBitInterpretationControl.signColor;
  self.digitsGroupNavigatorView.exponentColor1 = self.inputBitInterpretationControl.exponentColor;
  self.digitsGroupNavigatorView.significandColor1 = self.inputBitInterpretationControl.significandColor;
  self.digitsGroupNavigatorView.signColor2 = self.outputBitInterpretationControl.signColor;
  self.digitsGroupNavigatorView.exponentColor2 = self.outputBitInterpretationControl.exponentColor;
  self.digitsGroupNavigatorView.significandColor2 = self.outputBitInterpretationControl.significandColor;
  [self.digitsGroupNavigatorView endUpdate];
  
  [self.digitsOrderSegmentedControl selectSegmentWithTag:self.digitsGroupNavigatorView.digitsOrder];
  [self.bitsPerDigitPopUpButton selectItemWithTag:self.digitsGroupNavigatorView.bitsPerDigit];

  self.leftShiftTextField.enabled = hasNumber;
  self.leftShiftTextField.integerValue = @(self->leftShiftCount).integerValue;
  self.leftShiftStepper.enabled = hasNumber;
  self.leftShiftStepper.integerValue = @(self->leftShiftCount).integerValue;
  self.leftShiftButton.enabled = hasNumber && (self->leftShiftCount > 0);
  self.rightShiftTextField.enabled = hasNumber;
  self.rightShiftTextField.integerValue = @(self->rightShiftCount).integerValue;
  self.rightShiftStepper.enabled = hasNumber;
  self.rightShiftStepper.integerValue = @(self->rightShiftCount).integerValue;
  self.rightShiftButton.enabled = hasNumber && (self->rightShiftCount > 0);
  self.leftRollTextField.enabled = hasNumber;
  self.leftRollTextField.integerValue = @(self->leftRollCount).integerValue;
  self.leftRollStepper.enabled = hasNumber;
  self.leftRollStepper.integerValue = @(self->leftRollCount).integerValue;
  self.leftRollButton.enabled = hasNumber && (self->leftRollCount > 0);
  self.rightRollTextField.enabled = hasNumber;
  self.rightRollTextField.integerValue = @(self->rightRollCount).integerValue;
  self.rightRollStepper.enabled = hasNumber;
  self.rightRollStepper.integerValue = @(self->rightRollCount).integerValue;
  self.rightRollButton.enabled = hasNumber && (self->rightRollCount > 0);
  self.swapBitsTextField.enabled = hasNumber;
  self.swapBitsTextField.integerValue = @(self->swapBitsCount).integerValue;
  self.swapBitsStepper.enabled = hasNumber;
  self.swapBitsStepper.integerValue = @(self->swapBitsCount).integerValue;
  self.swapBitsButton.enabled = hasNumber && (self->swapBitsCount > 0);
  self.digitsOrderSegmentedControl.enabled = hasNumber;
  self.bitsPerDigitPopUpButton.enabled = hasNumber;
  self.complement1Button.enabled = hasNumber;
  self.complement2Button.enabled = hasNumber;
  self.addOneButton.enabled = hasNumber;
  self.subOneButton.enabled = hasNumber;
  self.setToZeroButton.enabled = hasNumber;
  self.setToOneButton.enabled = hasNumber;
  self.reverseButton.enabled = hasNumber;
  self.resetButton.enabled = hasNumber;
}
//end updateControls

-(CHChalkError*) inputConversionError
{
  CHChalkError* result = nil;
  if (self->inputConversionResult.error != CHALK_CONVERSION_ERROR_NOERROR)
    result = [CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk
      reason:[CHChalkError convertFromConversionError:self->inputConversionResult.error]];
  return result;
}
//end inputConversionError

-(CHChalkError*) outputConversionError
{
  CHChalkError* result = nil;
  if (self->outputConversionResult.error != CHALK_CONVERSION_ERROR_NOERROR)
    result = [CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk
      reason:[CHChalkError convertFromConversionError:self->outputConversionResult.error]];
  return result;
}
//end outputConversionError

-(void) digitsInspector:(CHDigitsInspectorControl*)digitsInspector didUpdateRawValue:(const chalk_raw_value_t*)rawValue gmpValue:(const chalk_gmp_value_t*)gmpValue
{
  if ([(id)self.delegate respondsToSelector:_cmd])
    [self.delegate digitsInspector:digitsInspector didUpdateRawValue:rawValue gmpValue:gmpValue];
}
//end digitsInspector:didUpdateValue:

@end
