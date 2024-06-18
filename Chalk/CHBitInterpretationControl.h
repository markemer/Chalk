//
//  CHBitInterpretationControl.h
//  Chalk
//
//  Created by Pierre Chatelier on 28/04/2016.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "CHChalkUtils.h"
#import "CHColorWellButton.h"

extern NSString* CHBitInterpretationBinding;
extern NSString* CHBitInterpretationSignColorBinding;
extern NSString* CHBitInterpretationExponentColorBinding;
extern NSString* CHBitInterpretationSignificandColorBinding;

@class CHComputationConfiguration;
@class CHNumberFormatter;

@interface CHBitInterpretationControl : NSViewController <CHColorWellButtonDelegate> {
  chalk_value_gmp_type_t valueType;
  chalk_bit_interpretation_t fixedInterpretation;
  CHComputationConfiguration* computationConfiguration;
  chalk_bit_interpretation_t bitInterpretation;
  NSColor* signColor;
  NSColor* exponentColor;
  NSColor* significandColor;
}

@property(assign) IBOutlet NSPopUpButton* bitsEncodingPopUpButton;
@property(assign) IBOutlet NSPopUpButton* bitsMinorPartPopUpButton;
@property(assign) IBOutlet CHNumberFormatter* bitsCountFormatter;
@property(assign) IBOutlet NSTextField*   bitsCountTextField;
@property(assign) IBOutlet NSStepper*     bitsCountStepper;
@property(assign) IBOutlet CHColorWellButton* minorPartColorWellButton;
@property(assign) IBOutlet NSColorWell*       minorPartColorWell;

@property(nonatomic,copy,readonly) CHComputationConfiguration* computationConfiguration;
@property(nonatomic)      const chalk_bit_interpretation_t* bitInterpretation;
@property(nonatomic,copy) NSColor*                   signColor;
@property(nonatomic,copy) NSColor*                   exponentColor;
@property(nonatomic,copy) NSColor*                   significandColor;

@property(nonatomic,readonly) BOOL isFixedBitInterpretation;

-(IBAction) changeParameter:(id)sender;
-(IBAction) changeColor:(id)sender;

-(void) setValueType:(chalk_value_gmp_type_t)valueType computationConfiguration:(CHComputationConfiguration*)computationConfiguration;
-(void) setFixedBitInterpretation:(const chalk_bit_interpretation_t*)aFixedInterpretation;

@end
