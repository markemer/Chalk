//
//  CHDigitsGroupNavigatorView.h
//  Chalk
//
//  Created by Pierre Chatelier on 25/03/2016.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "CHChalkUtils.h"

@class CHDigitsGroupView;

@interface CHDigitsGroupNavigatorView : NSView <NSAnimationDelegate>{
  CHDigitsGroupView* nextDigitsGroupView;
  volatile BOOL isAnimating;
  NSColor* signColor1;
  NSColor* exponentColor1;
  NSColor* significandColor1;
  NSColor* signColor2;
  NSColor* exponentColor2;
  NSColor* significandColor2;
  BOOL isDirtyUpdate;
  NSUInteger updateCount;
  chalk_bit_interpretation_t inputBitInterpretation;
  chalk_bit_interpretation_t outputBitInterpretation;
  NSUInteger animationNextDigitsGroupIndex;
}

@property BOOL enabled;

@property(assign) IBOutlet NSTextField* rangeLabel;
@property(assign) IBOutlet NSButton* leftMostButton;
@property(assign) IBOutlet NSButton* leftBestButton;
@property(assign) IBOutlet NSButton* leftButton;
@property(assign) IBOutlet NSButton* rightButton;
@property(assign) IBOutlet NSButton* rightBestButton;
@property(assign) IBOutlet NSButton* rightMostButton;
@property(assign) IBOutlet CHDigitsGroupView* currentDigitsGroupView;
@property(nonatomic) chalk_compute_mode_t inputComputeMode;
@property(nonatomic) const chalk_gmp_value_t* inputNumberValue;
@property(nonatomic) const chalk_bit_interpretation_t* inputBitInterpretation;
@property(nonatomic) const chalk_raw_value_t* inputRawValue;
@property(nonatomic) chalk_number_part_minor_type_t minorPartsVisible;
@property(nonatomic) chalk_raw_value_t* outputRawValue;
@property(nonatomic) const chalk_bit_interpretation_t* outputBitInterpretation;
@property(nonatomic) chalk_gmp_value_t* outputNumberValue;

@property(nonatomic) NSInteger  digitsOrder;
@property(nonatomic) NSUInteger bitsPerDigit;
@property(nonatomic) NSRange    digitsRangeNavigatable;
@property(nonatomic) NSRange    digitsRangeModifiable;
@property(nonatomic) NSRange    digitsRangeNatural;
@property(nonatomic) NSUInteger digitsGroupSize;
@property(nonatomic) NSUInteger digitsGroupIndex;
@property(nonatomic,readonly) NSUInteger digitsGroupIndexNavigatableMax;
@property(nonatomic,readonly) NSUInteger digitsGroupIndexModifiableMax;
@property(nonatomic,readonly) NSUInteger digitsGroupIndexNaturalMax;

@property(nonatomic,copy) NSColor* signColor1;
@property(nonatomic,copy) NSColor* exponentColor1;
@property(nonatomic,copy) NSColor* significandColor1;
@property(nonatomic,copy) NSColor* signColor2;
@property(nonatomic,copy) NSColor* exponentColor2;
@property(nonatomic,copy) NSColor* significandColor2;

@property(nonatomic,assign) id delegate;

-(IBAction) navigate:(id)sender;

-(void) beginUpdate;
-(void) endUpdate;

-(void) outputRawValueDidChange:(id)sender;

@end
