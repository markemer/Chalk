//
//  CHPreferencesController.h
//  Chalk
//
//  Created by Pierre Chatelier on 15/07/13.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "CHChalkTypes.h"

extern NSString* CHSoftIntegerMaxBitsKey;
extern NSString* CHSoftIntegerDenominatorMaxBitsKey;
extern NSString* CHSoftIntegerMaxBitsDigitsBaseKey;
extern NSString* CHSoftIntegerDenominatorMaxBitsDigitsBaseKey;
extern NSString* CHSoftFloatSignificandBitsKey;
extern NSString* CHSoftFloatSignificandBitsDigitsBaseKey;
extern NSString* CHSoftFloatDisplayBitsKey;
extern NSString* CHSoftFloatDisplayBitsDigitsBaseKey;
extern NSString* CHSoftMaxExponentKey;
extern NSString* CHSoftMaxPrettyPrintNegativeExponentKey;
extern NSString* CHSoftMaxPrettyPrintPositiveExponentKey;
extern NSString* CHComputeModeKey;
extern NSString* CHComputeBaseKey;
extern NSString* CHPropagateNaNKey;
extern NSString* CHBaseUseLowercaseKey;
extern NSString* CHBaseUseDecimalExponentKey;
extern NSString* CHBaseBaseKey;
extern NSString* CHBasePrefixesKey;
extern NSString* CHBaseSuffixesKey;
extern NSString* CHBasePrefixesSuffixesKey;
extern NSString* CHIntegerGroupSizeKey;
extern NSString* CHParseModeKey;
extern NSString* CHBitInterpretationSignColorKey;
extern NSString* CHBitInterpretationExponentColorKey;
extern NSString* CHBitInterpretationSignificandColorKey;
extern NSString* CHExportInputColorKey;
extern NSString* CHExportOutputColorKey;
extern NSString* CHNextInputModeKey;

@class CHComputationConfiguration;
@class CHPresentationConfiguration;

@interface CHPreferencesController : NSObject {
  NSArrayController* basePrefixesSuffixesController;
  chalk_export_format_t exportFormatCurrentSession;
}

+(CHPreferencesController*) sharedPreferencesController;
+(NSDictionary*) defaults;
-(NSDictionary*) defaults;

@property chalk_export_format_t exportFormatCurrentSession;

@property(nonatomic,readonly,copy) CHComputationConfiguration* computationConfigurationDefault;
@property(nonatomic,copy)          CHComputationConfiguration* computationConfigurationCurrent;
@property(nonatomic,readonly,copy) CHPresentationConfiguration* presentationConfigurationDefault;
@property(nonatomic,copy)          CHPresentationConfiguration* presentationConfigurationCurrent;
@property(nonatomic) NSUInteger softIntegerMaxBits;
@property(nonatomic) int        softIntegerMaxBitsDigitsBase;
@property(nonatomic) NSUInteger softIntegerDenominatorMaxBits;
@property(nonatomic) int        softIntegerDenominatorMaxBitsDigitsBase;
@property(nonatomic) NSUInteger softFloatSignificandBits;
@property(nonatomic) int        softFloatSignificandBitsDigitsBase;
@property(nonatomic) NSUInteger softFloatDisplayBits;
@property(nonatomic) int        softFloatDisplayBitsDigitsBase;
@property(nonatomic) NSUInteger softMaxExponent;
@property(nonatomic) NSUInteger softMaxPrettyPrintNegativeExponent;
@property(nonatomic) NSUInteger softMaxPrettyPrintPositiveExponent;
@property(nonatomic) chalk_compute_mode_t computeMode;
@property(nonatomic) int        computeBase;
@property(nonatomic) BOOL       propagateNaN;
@property(nonatomic) BOOL       baseUseLowercase;
@property(nonatomic) BOOL       baseUseDecimalExponent;
@property(nonatomic,copy) NSArray* basePrefixesSuffixes;
@property(nonatomic,readonly,assign) NSArrayController* basePrefixesSuffixesController;
@property(nonatomic) NSInteger integerGroupSize;
@property(nonatomic) chalk_parse_mode_t parseMode;
@property(nonatomic,copy) NSColor* bitInterpretationSignColor;
@property(nonatomic,copy) NSColor* bitInterpretationExponentColor;
@property(nonatomic,copy) NSColor* bitInterpretationSignificandColor;
@property(nonatomic,copy) NSColor* exportInputColor;
@property(nonatomic,copy) NSColor* exportOutputColor;
@property(nonatomic) chalk_nextinput_mode_t nextInputMode;

@property(nonatomic,readonly) BOOL shouldEasterEgg;

@end
